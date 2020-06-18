package Sudoku::Solver;

use v5.30;
use feature 'signatures';
no warnings 'experimental::signatures';

use sayf;
use Time::HiRes qw(time);
use Data::Dumper;

use constant DEFAULT_TYPE => 'FlatArrayBacktrack';
use constant SUPPORTED_TYPES => {
    map { $_ => $_ }
    qw(
        FlatArrayBacktrack
        FlatArrayBacktrackV2
    )
};

# Sudoku::Solver->new({
#   board_string => ...
#           type => one of keys %{SUPPORTED_TYPES}, maps to package in Sudoku::Solver::
#                   namespace
#       arguments=> hashref of arguments to send to the solver
#           debug=> any truthy value will include additional information upon failure
# })
sub new ( $class, $options ) {
    die 'You must provide a board string in the board argument to Solver->new!' unless defined $options->{board_string};
    $options->{board_string} =~ s/\s//g;
    die 'The provided board_string should be exactly 81 characters long' unless length($options->{board_string}) == 81;

    my $solver_type     = SUPPORTED_TYPES->{ $options->{type} } // DEFAULT_TYPE;
    my $solver_package  = "${class}::${solver_type}";

    eval "require $solver_package;" or die $@;

    $options->{board_string} =~ s/\./0/g;
    $options->{arguments}{board_string} //= delete $options->{board_string};

    my $self = {
        solver => ${solver_package}->new( $options->{arguments} ),
        _debug => !!$options->{debug},
    };

    return bless $self, $class;
}

sub solver ( $self ) { return $self->{solver}; }
sub debug  ( $self ) { return $self->{_debug}; }

sub solve_n_times ( $self, $n, $print_per_run_info = 1 ) {
    # runs = ( [iterations,time_spent], ... )
    my @runs;
    my ($fastest,$slowest) = (99999999,0);
    my $extremes = {
        fastest => [],
        slowest => [],
    };

    for ( 1..$n ) {
        my $START_TIME = time;
        my $iterations = $self->solver->solve;
        my $runtime    = sprintf '%.3f', ( (time-$START_TIME) * 1000);

        if ( $iterations ) {
            if ( $runtime > $slowest ) {
                $slowest = $runtime;
                $extremes->{slowest} = [ $iterations,$runtime ];
            } elsif ( $runtime < $fastest ) {
                $fastest = $runtime;
                $extremes->{fastest} = [ $iterations,$runtime ];
            }
            if ( $print_per_run_info ) {
                say "Run $_ completed in ${runtime}ms after ${iterations} steps";
            }
        } else {
            if ( $self->debug ) {
                say Dumper($self->solver);
            }
            sayf "Run %d failed in %.3fms. Is it possible this board is unsolveable? Above you can see a Dumper of the solver object.",$_, $runtime;
            if ( $self->debug ) {
                say "I've paused execution, you can either CTRL+C or hit enter to continue.";
                <STDIN>;
            }
        }

        $self->solver->reset;

        push @runs, [ $iterations, $runtime ];
    }
    eval {
        sayf "Completed %d solves of the provided board.", $n;
        sayf "The fastest solve completed in %.3fms and %d iterations.", $extremes->{fastest}[1], $extremes->{fastest}[0];
        sayf "The slowest solve completed in %.3fms and %d iterations.", $extremes->{slowest}[1], $extremes->{slowest}[0];
        sayf "Making the fastest one %.02f%% faster than the slowest.", ($extremes->{slowest}[1] / $extremes->{fastest}[1]) * 100;
        1;
    } or do {
        say Dumper $extremes;
    };
}

1;