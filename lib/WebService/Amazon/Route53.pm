package WebService::Amazon::Route53;

use warnings;
use strict;

# ABSTRACT: Perl interface to Amazon Route 53 API

# VERSION

use Carp;
use Module::Load;

=head1 SYNOPSIS

WebService::Amazon::Route53 provides an interface to Amazon Route 53 DNS
service.

    use WebService::Amazon::Route53;

    my $r53 = WebService::Amazon::Route53->new(id => 'ROUTE53ID',
                                               key => 'SECRETKEY');
    
    # Create a new zone
    $r53->create_hosted_zone(name => 'example.com.',
                             caller_reference => 'example.com_migration_01');
    
    # Get zone information
    my $zone = $r53->find_hosted_zone(name => 'example.com.');
    
    # Create a new record
    $r53->change_resource_record_sets(zone_id => $zone->{id},
                                      action => 'create',
                                      name => 'www.example.com.',
                                      type => 'A',
                                      ttl => 86400,
                                      value => '12.34.56.78');

    # Modify records
    $r53->change_resource_record_sets(zone_id => $zone->{id},
        changes => [
            {
                action => 'delete',
                name => 'www.example.com.',
                type => 'A',
                ttl => 86400,
                value => '12.34.56.78'
            },
            {
                action => 'create',
                name => 'www.example.com.',
                type => 'A',
                ttl => 86400,
                records => [
                    '34.56.78.90',
                    '56.78.90.12'
                ]
            }
        ]);

=cut

my @versions = ( qw/ 20110505 20130401 / );

=head1 METHODS

Required parameters are marked as such, other parameters are optional.

Instance methods return C<undef> on failure. More detailed error information can
be obtained by calling L<"error">.

=head2 new

Creates a new instance of WebService::Amazon::Route53.

    my $r53 = WebService::Amazon::Route53->new(id => 'ROUTE53ID',
                                               key => 'SECRETKEY');

Parameters:

=over 4

=item * id

B<(Required)> AWS access key ID.

=item * key

B<(Required)> Secret access key.

=back

=cut

sub new {
    my ($class, %args) = @_;
    
    ## Use most recent API version by default
    #my $version = $versions[$#versions];

    # Use 2011-05-05 by default (until the recent one is properly implemented)
    my $version = '20110505';

    if (defined $args{'version'}) {
        ($version = $args{'version'}) =~ s/[^0-9]//g;

        if (!grep { $_ eq $version } @versions) {
            croak "Unknown API version";
        }
    }

    delete $args{version};

    load "WebService::Amazon::Route53::API::$version";

    return ('WebService::Amazon::Route53::API::' . $version)->new(%args);
}


=head1 SEE ALSO

=for :list

* L<Amazon Route 53 API Reference|http://docs.amazonwebservices.com/Route53/latest/APIReference/>

=cut

1; # End of WebService::Amazon::Route53
