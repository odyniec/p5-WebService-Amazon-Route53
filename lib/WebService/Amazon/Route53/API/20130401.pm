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

sub list_hosted_zones {
    return WebService::Amazon::Route53::API::20110505::list_hosted_zones(@_);
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
