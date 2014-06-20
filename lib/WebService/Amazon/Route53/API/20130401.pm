package WebService::Amazon::Route53::API::20130401;

use warnings;
use strict;

use Carp;
use URI::Escape;

use WebService::Amazon::Route53::API;
use parent 'WebService::Amazon::Route53::API';

use WebService::Amazon::Route53::API::20110505;

sub new {
    my ($class, %args) = @_;

    my $self = $class->SUPER::new(%args);

    $self->{api_version} = '2013-04-01';
    $self->{api_url} = $self->{base_url} . $self->{api_version} . '/';

    return $self;    
}

=head2 list_hosted_zones

Gets a list of hosted zones.

    $response = $r53->list_hosted_zones(max_items => 15);
    
Parameters:

=over 4

=item * marker

Indicates where to begin the result set. This is the ID of the last hosted zone
which will not be included in the results.

=item * max_items

The maximum number of hosted zones to retrieve.

=back

Returns: A reference to a hash containing zone data, and a next marker if more
zones are available. Example:

    $response = {
        'hosted_zones' => [
            {
                'id' => '/hostedzone/123ZONEID',
                'name' => 'example.com.',
                'caller_reference' => 'ExampleZone',
                'config' => {
                    'comment' => 'This is my first hosted zone'
                },
                'resource_record_set_count' => '10'
            },
            {
                'id' => '/hostedzone/456ZONEID',
                'name' => 'example2.com.',
                'caller_reference' => 'ExampleZone2',
                'config' => {
                    'comment' => 'This is my second hosted zone'
                },
                'resource_record_set_count' => '7'
            }
        ],
        'next_marker' => '456ZONEID'
    ];
    
When called in list context, it also returns the next marker to pass to a
subsequent call to C<list_hosted_zones> to get the next set of results. If this
is the last set of results, next marker will be C<undef>.

=cut

sub list_hosted_zones {
    my ($self, %args) = @_;
    
    my $url = $self->{api_url} . 'hostedzone';
    my $separator = '?';
    
    if (defined $args{'marker'}) {
        $url .= $separator . 'marker=' . uri_escape($args{'marker'});
        $separator = '&';
    }
    
    if (defined $args{'max_items'}) {
        $url .= $separator . 'maxitems=' . uri_escape($args{'max_items'});
    }
    
    my $response = $self->_request('GET', $url);
    
    if (!$response->{success}) {
        $self->_parse_error($response->{content});
        return undef;
    }
    
    # Parse the returned XML data
    my $data = $self->{'xs'}->XMLin($response->{content},
        ForceArray => [ 'HostedZone' ]);
    my $zones = [];
    my $next_marker;
    
    foreach my $zone_data (@{$data->{HostedZones}{HostedZone}}) {
        my $zone = {
            id                          => $zone_data->{Id},
            name                        => $zone_data->{Name},
            caller_reference            => $zone_data->{CallerReference},
            resource_record_set_count   => $zone_data->{ResourceRecordSetCount},
        };
        
        if (exists $zone_data->{Config}) {
            $zone->{config} = {};
            
            if (exists $zone_data->{Config}{Comment}) {
                $zone->{config}{comment} = $zone_data->{Config}{Comment};
            }
        }
        
        push(@$zones, $zone);
    }
    
    if (exists $data->{NextMarker}) {
        $next_marker = $data->{NextMarker};
    }
    
    return {
        hosted_zones => $zones,
        (next_marker => $next_marker) x defined $next_marker
    };
}

=head2 get_hosted_zone

Gets hosted zone data.

    $response = get_hosted_zone(zone_id => '123ZONEID');
    
Parameters:

=over 4

=item * zone_id

B<(Required)> Hosted zone ID.

=back

Returns: A reference to a hash containing zone data and name servers
information. Example:

    $response = {
        'hosted_zone' => {
            'id' => '/hostedzone/123ZONEID'
            'name' => 'example.com.',
            'caller_reference' => 'ExampleZone',
            'config' => {
                'comment' => 'This is my first hosted zone'
            },
            'resource_record_set_count' => '10'
        },
        'delegation_set' => {
            'name_servers' => [
                'ns-001.awsdns-01.net',
                'ns-002.awsdns-02.net',
                'ns-003.awsdns-03.net',
                'ns-004.awsdns-04.net'
            ]
        }
    };

=cut

sub get_hosted_zone {
    my ($self, %args) = @_;
    
    if (!defined $args{'zone_id'}) {
        carp "Required parameter 'zone_id' is not defined";
    }
    
    my $zone_id = $args{'zone_id'};
    
    # Strip off the "/hostedzone/" part, if present
    $zone_id =~ s!^/hostedzone/!!;

    my $url = $self->{api_url} . 'hostedzone/' . $zone_id;
    
    my $response = $self->_request('GET', $url);
    
    if (!$response->{success}) {
        $self->_parse_error($response->{content});
        return undef;
    }
    
    my $data = $self->{'xs'}->XMLin($response->{content},
        ForceArray => [ 'NameServer' ]);
    
    my $zone = {
        id => $data->{HostedZone}{Id},
        name => $data->{HostedZone}{Name},
        caller_reference => $data->{HostedZone}{CallerReference},
        resource_record_set_count => $data->{HostedZone}{ResourceRecordSetCount}
    };
    
    if (exists $data->{HostedZone}->{Config}) {
        $zone->{config} = {};
        
        if (exists $data->{HostedZone}{Config}{Comment}) {
            $zone->{config}{comment} =
                $data->{HostedZone}{Config}{Comment};
        }
    }
    
    return {
        hosted_zone => $zone,
        delegation_set => {
            name_servers => $data->{DelegationSet}{NameServers}{NameServer}
        }
    };
}

=head2 find_hosted_zone

Finds the first hosted zone with the given name.

    $response = $r53->find_hosted_zone(name => 'example.com.');
    
Parameters:

=over 4

=item * name

B<(Required)> Hosted zone name.

=back

Returns: A reference to a hash containing zone data and name servers information
(see L<"get_hosted_zone">), or C<undef> if there is no hosted zone with the
given name.

=cut

sub find_hosted_zone {
    my ($self, %args) = @_;
    
    if (!defined $args{'name'}) {
        carp "Required parameter 'name' is not defined";
    }
    
    if ($args{'name'} !~ /\.$/) {
        $args{'name'} .= '.';
    }
    
    my $found_zone;
    my $marker;
    
    ZONES: while (1) {
        my $response = $self->list_hosted_zones(max_items => 100,
            marker => $marker);
            
        if (!defined $response) {
            # We can assume $self->{error} is already set
            return undef;
        }
        
        my $zones = $response->{hosted_zones};
        my $zone;
        
        foreach $zone (@$zones) {
            if ($zone->{name} eq $args{'name'}) {
                $found_zone = $zone;
                last ZONES;
            }
        }
        
        if (@$zones < 100) {
            # Less than 100 zones have been returned -- no more zones to get
            last ZONES;
        }
        else {
            # Get the marker from the last returned zone
            ($marker = $zones->[@$zones-1]->{'id'}) =~ s!^/hostedzone/!!;
        }
    }

    if ($found_zone) {
        return $self->get_hosted_zone(zone_id => $found_zone->{id});
    }
}

=head2 create_hosted_zone

Creates a new hosted zone.

    $response = $r53->create_hosted_zone(name => 'example.com.',
                                         caller_reference => 'example.com_01');

Parameters:

=over 4

=item * name

B<(Required)> New hosted zone name.

=item * caller_reference

B<(Required)> A unique string that identifies the request.

=back

Returns: A reference to a hash containing new zone data, change description,
and name servers information. Example:

    $response = {
        'hosted_zone' => {
            'id' => '/hostedzone/123ZONEID'
            'name' => 'example.com.',
            'caller_reference' => 'example.com_01',
            'config' => {},
            'resource_record_set_count' => '2'
        },
        'change_info' => {
            'id' => '/change/123CHANGEID'
            'submitted_at' => '2011-08-30T23:54:53.221Z',
            'status' => 'PENDING'
        },
        'delegation_set' => {
            'name_servers' => [
                'ns-001.awsdns-01.net',
                'ns-002.awsdns-02.net',
                'ns-003.awsdns-03.net',
                'ns-004.awsdns-04.net'
            ]
        },
    };

=cut

sub create_hosted_zone {
    my ($self, %args) = @_;
    
    if (!defined $args{'name'}) {
        carp "Required parameter 'name' is not defined";
    }
    
    if (!defined $args{'caller_reference'}) {
        carp "Required parameter 'caller_reference' is not defined";
    }
    
    # Make sure the domain name ends with a dot
    if ($args{'name'} !~ /\.$/) {
        $args{'name'} .= '.';
    }
    
    my $data = _ordered_hash(
        'xmlns' => $self->{base_url} . 'doc/'. $self->{api_version} . '/',
        'Name' => [ $args{'name'} ],
        'CallerReference' => [ $args{'caller_reference'} ],
        'HostedZoneConfig' => $args{'comment'} ? {
            'Comment' => [ $args{'comment'} ]
        } : undef,
    );
    
    my $xml = $self->{'xs'}->XMLout($data, SuppressEmpty => 1, NoSort => 1,
        RootName => 'CreateHostedZoneRequest');
    
    $xml = '<?xml version="1.0" encoding="UTF-8"?>' . "\n" . $xml;
    
    my $response = $self->_request('POST', $self->{api_url} . 'hostedzone',
        { content => $xml });
        
    if (!$response->{success}) {
        $self->_parse_error($response->{content});
        return undef;
    }
    
    $data = $self->{xs}->XMLin($response->{content},
        ForceArray => [ 'NameServer' ]);
    
    my $ret = {
        hosted_zone => {
            id => $data->{HostedZone}{Id},
            name => $data->{HostedZone}{Name},
            caller_reference => $data->{HostedZone}{CallerReference},
            resource_record_set_count =>
                $data->{HostedZone}{ResourceRecordSetCount},
        },
        change_info => {
            id => $data->{ChangeInfo}{Id},
            status => $data->{ChangeInfo}{Status},
            submitted_at => $data->{ChangeInfo}{SubmittedAt},
        },
        delegation_set => {
            name_servers => $data->{DelegationSet}{NameServers}{NameServer},
        }
    };
    
    if (exists $data->{HostedZone}{Config}) {
        $ret->{hosted_zone}{config} = {};
        
        if (exists $data->{HostedZone}{Config}{Comment}) {
            $ret->{hosted_zone}{config}{comment} =
                $data->{HostedZone}{Config}{Comment};
        }
    }
    
    return $ret;
}

sub delete_hosted_zone {
    return WebService::Amazon::Route53::API::20110505::delete_hosted_zone(@_);
}

sub list_resource_record_sets {
    return WebService::Amazon::Route53::API::20110505::list_resource_record_sets(@_);
}

sub change_resource_record_sets {
    return WebService::Amazon::Route53::API::20110505::change_resource_record_sets(@_);
}

1;
