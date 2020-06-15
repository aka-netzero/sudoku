package Sudoku::Solver;

use v5.30;
use feature 'signatures';
no warnings 'experimental::signatures';

use Time::HiRes qw(time);
use Data::Dumper;

use constant DEFAULT_TYPE => 'FlatArrayBacktrack';
use constant SUPPORTED_TYPES => {
    map { $_ => $_ }
    qw(
        FlatArrayBacktrack
    )
};

sub new ( $class, $options ) {
    die 'You must provide a board string in the board argument to Solver->new!' unless defined $options->{board_string};

    my $solver_type     = SUPPORTED_TYPES->{ $options->{type} } // DEFAULT_TYPE;
    my $solver_package  = "${class}::${solver_type}";

    eval "require $solver_package;" or die $@;

    $options->{arguments}{board_string} //= $options->{board_string};

    my $self = {
        solver => ${solver_package}->new( $options->{arguments} ),
    };

    return bless $self, $class;
}

sub solver ( $self ) { return $self->{solver}; }

sub solve_n_times ( $self, $n ) {
    # runs = ( [iterations,time_spent], ... )
    my @runs;

    for ( 1..$n ) {
        my $START_TIME = time;
        my $iterations = $self->solver->solve;
        my $runtime    = sprintf '%.3f', ( (time-$START_TIME) * 1000);

        if ( $iterations ) {
            say "Run $_ completed in ${runtime}ms after ${iterations} steps";
        } else {
            say "Run $_ failed for some reason.. should probably debug this one. Here's a dumper of the object:" . Dumper $self->solver;
            say "I've paused execution, you can either CTRL+C or hit enter to continue.";
            <STDIN>;
        }

        $self->solver->reset;

        push @runs, [ $iterations, $runtime ];
    }
}

1;