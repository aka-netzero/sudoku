use v5.30;
use feature 'signatures';
no warnings 'experimental::signatures';

use lib './lib/';
use Sudoku::Solver::FlatArrayBacktrack;
use Sudoku::Solver;

my @board_raw = qw(
    0 4 0   0 2 0   9 0 0
    0 0 0   0 0 0   0 1 0
    0 0 0   0 0 6   8 5 0
    
    5 8 2   3 0 0   7 0 0
    0 0 0   8 0 7   0 0 0
    0 0 9   0 0 5   1 3 8
    
    0 9 7   1 0 0   0 0 0
    0 2 0   0 0 0   0 0 0
    0 0 4   0 3 0   0 0 0
);
#                   040020900000000010000006850582300700000807000009005138097100000020000000004030000
my $board_string = "040020900000000010000006850582300700000807000009005138097100000020000000004030000";

my $solver = Sudoku::Solver->new({
    type        => 'FlatArrayBacktrack',
    board_string=> $board_string,
    arguments   => { position_algorithm => 'lowest_options' }
});

$solver->solve_n_times(5);

# my $solver = Sudoku::Solver::FlatArrayBacktrack->new({
#     board_string => $board_string,
#     position_algorithm => 'lowest_options'
# });

# $solver->solve;