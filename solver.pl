use v5.30;
use diagnostics;
use feature 'signatures';
no warnings 'experimental::signatures';

use Data::Dumper qw( Dumper );
use lib '.';

use sudoku;

my @board_raw = qw(
    0 4 0 0 2 0 9 0 0
    0 0 0 0 0 0 0 1 0
    0 0 0 0 0 6 8 5 0
    5 8 2 3 0 0 7 0 0
    0 0 0 8 0 7 0 0 0
    0 0 9 0 0 5 1 3 8
    0 9 7 1 0 0 0 0 0
    0 2 0 0 0 0 0 0 0
    0 0 4 0 3 0 0 0 0
);

my $board = sudoku->new(\@board_raw);
say Dumper $board;
#say "$board";

exit;