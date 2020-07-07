package Sudoku::Solver::FlatArrayBacktrackV2;

use v5.30;
use feature 'signatures';
no warnings 'experimental::signatures';

use sayf;

use constant {
    ZERO    => 1 << 0,  FIVE    => 1 << 5,
    ONE     => 1 << 1,  SIX     => 1 << 6,
    TWO     => 1 << 2,  SEVEN   => 1 << 7,
    THREE   => 1 << 3,  EIGHT   => 1 << 8,
    FOUR    => 1 << 4,  NINE    => 1 << 9,
};

use constant DEC_TO_BIN => {
    0 => ZERO,      5 => FIVE,
    1 => ONE,       6 => SIX,
    2 => TWO,       7 => SEVEN,
    3 => THREE,     8 => EIGHT,
    4 => FOUR,      9 => NINE,
};

use constant BIN_TO_DEC => {
      ZERO() => 0,  FIVE() => 5,
       ONE() => 1,   SIX() => 6,
       TWO() => 2, SEVEN() => 7,
     THREE() => 3, EIGHT() => 8,
      FOUR() => 4,  NINE() => 9
};

sub new ( $class, $options ) {
    my $self = {
        _board   => [],
        _rows    => [],
        _columns => [],
        _squares => [],
        
        _board_string => $options->{board_string},
        _iterations => 0,
    };

    $self->{_cells_needed_to_win} = () = $options->{board_string} =~ /0/g;

    $self = bless $self, __PACKAGE__;

    $self->fill_structures;
    return $self;
}

sub fill_structures ( $self ) {
    my @cells = split //, $self->{_board_string};
    $self->{$_} = [] for qw( _board _rows _columns _squares );

    for ( 0 .. 80 ) {
        my $square = int( int( $_ / 27 ) * 3 + ( $_ % 9 / 3 ) );
        my $value = DEC_TO_BIN->{$cells[$_]};

        $self->{_board}[$_] = $value;
        $self->{_rows}[int($_/9)] |= $value;
        $self->{_columns}[$_%9]   |= $value;
        $self->{_squares}[$square]|= $value;
    }
}

sub solve ( $self ) {
    my @necessary_args = ($self->{_board},$self->{_rows}, $self->{_columns}, $self->{_squares});
    my $start_position = next_position(@necessary_args);

    my $filled_cells = $self->_solve($start_position, @necessary_args);

    if ( $filled_cells ) {
        if ( $filled_cells == $self->{_cells_needed_to_win} ) {
            return $self->{_iterations};
        } else {
            return undef;
        }
    }
    return undef;
}

sub _solve ( $self, $index, $board, $rows, $columns, $squares, $correct_count = 0 ) {
    ++$self->{_iterations};
    if ( $correct_count == $self->{_cells_needed_to_win} ) {
        return $correct_count;
    }

    my @possible_values = get_possible_values($board,$index,$rows,$columns,$squares);

    # Bail out if this is the last needed cell and it only has one value.
    # Why waste the ops for the rest?
    if ( @possible_values == 1 && $correct_count + 1 == $self->{_cells_needed_to_win} ) {
        $board->[$index] = shift @possible_values;
        return $self->{_cells_needed_to_win};
    }

    my $row_index    = int($index/9);
    my $col_index    = $index % 9;
    my $square_index = int( int( $index / 27 ) * 3 + ( $index % 9 / 3 ) );

    while ( my ($try_value) = splice @possible_values, int(rand()*scalar(@possible_values)), 1 ) {
        my $i;
        $board->[$index]           = $try_value;
        $rows->[$row_index]       |= $try_value;
        $columns->[$col_index]    |= $try_value;
        $squares->[$square_index] |= $try_value;
        $i = next_position($board,$rows,$columns,$squares);

        my $cc = $self->_solve($i,$board,$rows,$columns,$squares,$correct_count + 1);

        if ( $cc == $self->{_cells_needed_to_win} ) {
            return $cc;
        } else {
            $board->[$index] = ZERO;
            $rows->[$row_index]       ^= $try_value;
            $columns->[$col_index]    ^= $try_value;
            $squares->[$square_index] ^= $try_value;
        }
    }

    return ();
}

sub reset ( $self ) {
    $self->fill_structures;
    $self->{_iterations} = 0;
}

sub next_position ( $board, $r, $c, $s ) {
    my %indexes_by_number_of_options;
    my $lowest_count = 9;

    for my $idx ( 0..$#{$board} ) {
        if ( $board->[$idx] == ZERO ) {
            my $possibility_count = scalar( get_possible_values($board,$idx,$r,$c,$s) );

            if ( $possibility_count < $lowest_count ) {
                $lowest_count = $possibility_count;
                push @{$indexes_by_number_of_options{$possibility_count} //= [] }, $idx;
            }
        }
    }

    return $indexes_by_number_of_options{$lowest_count}->[ int( rand() * scalar(@{$indexes_by_number_of_options{$lowest_count}}) ) ];
}

sub get_possible_values ( $board, $index, $rows, $columns, $squares ) {
    my @possible_values;
    my $row_index    = int($index/9);
    my $col_index    = $index % 9;
    my $square_index = int( int( $index / 27 ) * 3 + ( $index % 9 / 3 ) );
    my $possibilities = ~( $rows->[$row_index] | $columns->[$col_index] | $squares->[$square_index] );

    for my $value ( 1..9 ) {
        if ( $possibilities & DEC_TO_BIN->{$value} ) {
            push @possible_values, DEC_TO_BIN->{$value};
        }
    }
    
    return @possible_values;
}

sub print_board ( $board, $highlight_index = undef ) {
    for my $index ( 0..80 ) {
        printf $highlight_index && $highlight_index == $index ? '[%s] ' : '%s ', BIN_TO_DEC->{$board->[$index]} // '?';
        if ( $index > 0 && ($index + 1) % 3 == 0 ) {
            print ' ';
        }
        print "\n" if $index && ($index + 1) % 9 == 0;
        print "\n" if $index && ($index + 1) % 27 == 0;
    }
}

1;