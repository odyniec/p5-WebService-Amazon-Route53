package WebService::Amazon::Route53::API;

use warnings;
use strict;

use Carp;
use Digest::HMAC_SHA1;
use Digest::SHA qw/sha256_hex hmac_sha256 hmac_sha256_hex/;
use HTTP::Tiny;
use MIME::Base64;
use Tie::IxHash;
use XML::Simple;
use DateTime;
use URI;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(_ordered_hash);
our $ALGORITHM = 'AWS4-HMAC-SHA256';

=for Pod::Coverage new error

=cut

sub new {
    my ($class, %args) = @_;

    my $self = {};

    if (!defined $args{id}) {
        carp "Required parameter 'id' is not defined";
    }
    
    if (!defined $args{key}) {
        carp "Required parameter 'key' is not defined";
    }

    $self->{id} = $args{id};
    $self->{key} = $args{key};

    # Initialize an instance of XML::Simple
    $self->{xs} = XML::Simple->new;

    # Initialize the user agent object
    $self->{ua} = HTTP::Tiny->new(
        agent => 'WebService::Amazon::Route53/' .
            $WebService::Amazon::Route53::VERSION . ' (Perl)'
    );

    # Keep track of the last error
    $self->{error} = {};

    $self->{base_url} = 'https://route53.amazonaws.com/';

    $self->{service}       = 'route53';
    $self->{host}          = 'route53.amazonaws.com';
    $self->{region}        = 'us-east-1';
    $self->{endpoint}      = 'https://route53.amazonaws.com/';
    $self->{signed_header} = 'host;x-amz-date';

    my $dt = DateTime->now();
    $self->{amzdate}       = $dt->strftime('%Y%m%dT%H%M%SZ');
    $self->{datestamp}     = $dt->strftime('%Y%m%d');

    return bless $self, $class;
}

sub error {
    my ($self) = @_;
    
    return $self->{error};
}

# "Private" methods

sub _get_server_date {
    my ($self) = @_;
    
    my $response = $self->{ua}->get($self->{base_url} . 'date');
    my $date = $response->{headers}->{'date'};
    
    if (!$date) {
        carp "Can't get Amazon server date";
    }
    
    return $date;    
}

# sub _request {
#     my ($self, $method, $url, $options) = @_;
    
#     my $date = $self->_get_server_date;

#     my $hmac = Digest::HMAC_SHA1->new($self->{'key'});
#     $hmac->add($date);
#     my $sig = encode_base64($hmac->digest, undef);
    
#     my $auth = 'AWS3-HTTPS AWSAccessKeyId=' . $self->{'id'} . ',' .
#         'Algorithm=HmacSHA1,Signature=' . $sig;
#     # Remove trailing newlines, if any
#     $auth =~ s/\n//g;
    
#     $options = {} if !defined $options;

#     $options->{headers}->{'Content-Type'} = 'text/xml';
#     $options->{headers}->{'Date'} = $date;
#     $options->{headers}->{'X-Amzn-Authorization'} = $auth;
    
#     # my $response = $self->{ua}->request($method, $url, $options);

# #     # return $response;    
# }

sub _request {
    my ($self, $method, $url, $options) = @_;

    my $signing_key = $self->_get_signature_key;
    my $canonical_request = $self->_create_cononical( $method, $url );

    my $credential_scope  = join '/', $self->{datestamp}, $self->{region},
                           $self->{service}, 'aws4_request';

    my $string_to_sign    =  join "\n", $ALGORITHM, $self->{amzdate},
                        $credential_scope, sha256_hex( $canonical_request );

    my $signature = hmac_sha256_hex($string_to_sign, $signing_key);

    my $authorization_header =  $ALGORITHM . ' ' . 'Credential=' . $self->{'id'} . '/' .
                                $credential_scope . ', ' . 'SignedHeaders=' . $self->{signed_header} . ', ' .
                                'Signature=' . $signature;

    $options = {} if !defined $options;

    $options->{headers}->{'x-amz-date'}    = $self->{amzdate};
    $options->{headers}->{'Authorization'} = $authorization_header;
    
    my $response = $self->{ua}->request($method, $url, $options);

    return $response;    
}

sub _get_signature_key {
    my $self = shift;

    my $k_date    = hmac_sha256( $self->{datestamp}, 'AWS4' . $self->{key} );
    my $k_region  = hmac_sha256( $self->{region}, $k_date );
    my $k_service = hmac_sha256( $self->{service}, $k_region );
    my $k_signing = hmac_sha256( 'aws4_request', $k_service );

    return $k_signing; 
}

sub _create_cononical {
    my ($self, $method, $url, $query_string) = @_;
    
    my $uri = URI->new($url);

    my $dt = DateTime->now;
    my $date = $dt->strftime('%Y%m%dT%H%M%SZ');

    my $canonical_uri = $uri->path;
    my $canonical_querystring = $uri->query;
    my $canonical_header  =  'host:' . $self->{host} . "\n" .
                            'x-amz-date:' . $date . "\n";

    my $payload_hash;
    if( uc( $method ) eq 'GET' ){
        $payload_hash = sha256_hex('');
    } else {
        $payload_hash = sha256_hex( $canonical_querystring );
    }
 
    my $canonical_request = join "\n", $method, $canonical_uri,
                            $canonical_querystring,
                            $canonical_header,
                            $self->{signed_header},
                            $payload_hash;

    return $canonical_request;
    
}
sub _parse_error {
    my ($self, $xml) = @_;
    
    my $data = $self->{xs}->XMLin($xml);
    
    $self->{error} = {
        type => $data->{Error}->{Type},
        code => $data->{Error}->{Code},
        message => $data->{Error}->{Message}
    };
}

# Helpful subroutines

# Amazon expects XML elements in specific order, so we'll need to pass the data
# to XML::Simple as ordered hashes
sub _ordered_hash (%) {
    tie my %hash => 'Tie::IxHash';
    %hash = @_;
    \%hash
}

1;
