package WebService::Amazon::Route53::API;

use warnings;
use strict;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(_ordered_hash);

# Amazon expects XML elements in specific order, so we'll need to pass the data
# to XML::Simple as ordered hashes
sub _ordered_hash (%) {
    tie my %hash => 'Tie::IxHash';
    %hash = @_;
    \%hash
}

1;
