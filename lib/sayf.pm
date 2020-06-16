package sayf;

use v5.30;
use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 'import';
our @EXPORT = qw( sayf );

sub sayf ( $str, @args ) { say sprintf $str, @args; }

1;