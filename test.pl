use v5.30;
use feature 'signatures';
no warnings 'experimental::signatures';

use lib './lib/';
use Sudoku::Solver;
use sayf;

use Hash::Util qw( hash_seed );
use Getopt::Long;

GetOptions(
    'n=i'       => \(my $ITERATIONS_TO_RUN = 5),
    't|type=s'  => \(my $TYPE = 'FlatArrayBacktrack'),
    'b|board=s' => \(my $BOARD_STRING = '040020900000000010000006850582300700000807000009005138097100000020000000004030000'),
    'args=s'    => \(my $ARGS = 'position_algorithm=lowest_options'),
    
    'seed=i'    => \(my $SEED),

    'per-run'   => \(my $SILENT_PER_RUN = undef),
    'd|debug'   => \(my $DEBUG = undef),
);

if ( $SEED ) {
    srand($SEED);
} else {
    $SEED = srand;
}

my $arguments = {
    map {
        my ($k,$v) = split '=', $_;
        ( $k => $v )
    } split /[|,]/, $ARGS
};

$BOARD_STRING =~ s/\./0/g;


my $solver = Sudoku::Solver->new({
    type        => $TYPE,
    board_string=> $BOARD_STRING,
    debug       => $DEBUG,
    arguments   => $arguments
});


sayf "Starting solve with srand seed %s, and PERL_HASH_KEY %s", $SEED, hash_seed();
$solver->solve_n_times($ITERATIONS_TO_RUN,$SILENT_PER_RUN);

# my $solver = Sudoku::Solver::FlatArrayBacktrack->new({
#     board_string => $board_string,
#     position_algorithm => 'lowest_options'
# });

# $solver->solve;