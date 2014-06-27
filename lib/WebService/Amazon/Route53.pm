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

Instance methods return a false value on failure. More detailed error
information can be obtained by calling L<"error">.

=head2 new

Creates a new instance of a WebService::Amazon::Route53 API class.

    my $r53 = WebService::Amazon::Route53->new(id => 'ROUTE53ID',
                                               key => 'SECRETKEY');

Based on the value of the C<version> parameter, the matching subclass of
WebService::Amazon::Route53::API is instantiated (e.g., for C<version> set to
C<"2013-04-01">, L<WebService::Amazon::Route53::API::20130401> is used). If the
C<version> parameter is ommitted, the latest supported version is selected
(currently C<"2013-04-01">).

Parameters:

=over 4

=item * id

B<(Required)> AWS access key ID.

=item * key

B<(Required)> Secret access key.

=item * version

Route53 API version (either C<"2013-04-01"> or C<"2011-05-05">, default:
C<"2013-04-01">).

=back

=cut

sub new {
    my ($class, %args) = @_;
    
    # Use most recent API version by default
    my $version = $versions[$#versions];

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
