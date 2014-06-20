package WebService::Amazon::Route53::API::20130401;

use warnings;
use strict;

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

Called in scalar context:

    $zones = $r53->list_hosted_zones(max_items => 15);

Called in list context:

    ($zones, $next_marker) = $r53->list_hosted_zones(marker => '456ZONEID',
                                                     max_items => 15);
    
Parameters:

=over 4

=item * marker

Indicates where to begin the result set. This is the ID of the last hosted zone
which will not be included in the results.

=item * max_items

The maximum number of hosted zones to retrieve.

=back

Returns: A reference to an array of hash references, containing zone data.
Example:

    $zones = [
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
    
    foreach my $zone_data (@{$data->{HostedZones}->{HostedZone}}) {
        my $zone = {
            'id' => $zone_data->{Id},
            'name' => $zone_data->{Name},
            'caller_reference' => $zone_data->{CallerReference},
            'resource_record_set_count' => $zone_data->{ResourceRecordSetCount},
        };
        
        if (exists $zone_data->{Config}) {
            $zone->{config} = {};
            
            if (exists $zone_data->{Config}->{Comment}) {
                $zone->{config}->{comment} = $zone_data->{Config}->{Comment};
            }
        }
        
        push(@$zones, $zone);
    }
    
    if (exists $data->{NextMarker}) {
        $next_marker = $data->{NextMarker};
    }
    
    return wantarray ? ($zones, $next_marker) : $zones;
}

sub get_hosted_zone {
    return WebService::Amazon::Route53::API::20110505::get_hosted_zone(@_);
}

sub find_hosted_zone {
    return WebService::Amazon::Route53::API::20110505::find_hosted_zone(@_);
}

sub create_hosted_zone {
    return WebService::Amazon::Route53::API::20110505::create_hosted_zone(@_);
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
