package Sudoku::Solver::FlatArrayBacktrack;

use v5.30;
use feature 'signatures';
no warnings 'experimental::signatures';

use Time::HiRes qw(time);

use constant POSITION_ALGORITHMS => {
    map { $_ => $_ }
    qw( random random_empty lowest_options )
};

my $GLOBAL_ITERATIONS_COUNT = 0;
my $GLOBAL_MAX_CORRECT      = 0;

sub new ( $class, $options ) {
    my $position_algorithm = $options->{position_algorithm} // 'random';
    my $self = {
        _board => (
            $options->{board_string} ? [ split //, $options->{board_string} ] :
            $options->{board}        ? [ @{ $options->{board} } ] :
            undef
        ),
        _position_algorithm => POSITION_ALGORITHMS->{$position_algorithm} // 'lowest_options',
    };
    $self->{_original_board} = [ @{ $self->{_board} } ];

    return bless $self, __PACKAGE__;
}

sub cells_to_be_filled ( $self ) {
    return ($self->{_cells_needed_to_win} //= scalar(get_empty_indexes($self->{_original_board})) );
}

sub get_board_ref ( $self ) {
    return \$self->{_board};
}

sub solve ( $self ) {
    my $start_time = time;
    my ( $solved_board_ref, undef, $filled_correctly ) = $self->_actually_solve( $self->get_board_ref, $self->next_position($self->{_original_board}), 0 );
    my $finished_time = time;

    if ( $solved_board_ref && $filled_correctly ) {
        if ( $filled_correctly == $self->cells_to_be_filled ) {
            printf "Solved the board! It took %sms and %d iterations to find a solution.\n", int( ($finished_time-$start_time) * 1000), $GLOBAL_ITERATIONS_COUNT;
            say "Original board: ";
            print_board($self->{_original_board},undef);
            say "Solved board: ";
            print_board($$solved_board_ref, undef);
        } else {
            say "Well now that's odd isn't it? 'Solved' board looks like: ";
            print_board($$solved_board_ref, undef);
            printf "But the correct count is not 81: %s\n", $filled_correctly // 'undef';
        }
    }
}

sub _actually_solve ( $self, $potential_solved_board_ref, $index, $correct_count ) {
    my $NEEDED_TO_WIN = $self->cells_to_be_filled;
    # printf "start_solve called with index and correct_count: %d, %d\n", $index,$correct_count;
    if ( ++$GLOBAL_ITERATIONS_COUNT % 150000 == 0 ) {
        say "${GLOBAL_ITERATIONS_COUNT} iterations checked.";
    }

    if ( $GLOBAL_ITERATIONS_COUNT > 900_000 && $correct_count > $GLOBAL_MAX_CORRECT ) {
        $GLOBAL_MAX_CORRECT = $correct_count;
        say "New global max correct hit, new value: ${correct_count}";
    }

    if ( $correct_count == $NEEDED_TO_WIN ) {
        say "Woot, solved!";
        return ( $potential_solved_board_ref, $index, $correct_count );
    }
    # &shrug;
    elsif ( $index > 80 ) {
        say "Index higher than 80, don't know what happened honestly.";
        return ();
    }

    # If the current index is already filled in, we assume it's correct and move on
    if ( ${ $potential_solved_board_ref }->[$index] != 0 ) {
        # printf "Index %d already has a non-zero value (%d). Moving onto next index.\n", $index, ${ $potential_solved_board_ref }->[$index];
        return $self->_actually_solve($potential_solved_board_ref, $self->next_position($$potential_solved_board_ref), $correct_count + 1);
    } else {
        my %possible_values = get_possible_values($$potential_solved_board_ref, $index);
        # printf "Possible values for %d are: %s\n", $index, join(',', keys %possible_values);
        for my $try_value ( keys %possible_values ) {
            # printf "Attempting to fill index %d (%d correct so far) with: %d\n", $index,$correct_count,$try_value;
            # printf "\tSetting to value %d\n", $try_value;
            my $new_board = [ @{$$potential_solved_board_ref} ];
            $new_board->[$index] = $try_value;

            my $next_position = $correct_count + 1 == $NEEDED_TO_WIN ? $index : $self->next_position($new_board);
            my ($new_ref,$idx,$cc) = $self->_actually_solve(\$new_board,$next_position,$correct_count+1);
            if ( $cc == $NEEDED_TO_WIN ) {
                return ($new_ref,$idx,$cc);
            }
        }
    }

    return ();
}

sub next_position ( $self, $board ) {
    my $pos_algo = $self->{_position_algorithm};

    if ( $pos_algo eq 'random' ) {
        return int(rand() * 81);
    } elsif ( $pos_algo eq 'random_empty' ) {
        my @indexes = get_empty_indexes($board);
        my $index = int(rand() * scalar(@indexes));

        return $indexes[ $index ];
    } elsif ( $pos_algo eq 'lowest_options') {
        my @all_indexes_with_no_values = get_empty_indexes($board);
        my %indexes_by_number_of_options;

        for my $idx ( @all_indexes_with_no_values ) {
            my $number_of_options = scalar(get_possible_values($board,$idx));
            push @{ $indexes_by_number_of_options{$number_of_options} }, $idx;
        }

        my ($lowest_options,$number_of_indexes,$random_index);

        $lowest_options    = (sort { $b <=> $a } keys %indexes_by_number_of_options)[-1];
        $number_of_indexes = scalar(@{$indexes_by_number_of_options{$lowest_options}});
        $random_index      = int(rand() * $number_of_indexes);

        return $indexes_by_number_of_options{$lowest_options}->[$random_index];
    }
}



sub get_empty_indexes ( $board ) {
    return grep { $board->[$_] == 0 } 0..80;
}


# IN: index of cell within square
# OUT:
#       1: square is filled completely and accurate
#       0: square is filled completely and incorrect
#           (?) ^ Not sure this is possible
#   undef: square is incomplete
sub is_square_done ( $board, $idx ) {
    my @used_values = get_values_in_square($board,$idx);
    my %used_values = map {
        $_ => 1
    } @used_values;

    if ( scalar( grep { exists $used_values{$_} } 1..9 ) == 9 ) {
        return 1;
    } elsif ( @used_values == 9 ) {
        return 0;
    } else {
        return undef;
    }
}

# IN:
#       1: reference to board
#       2: index in the grid to calculate possible values for
# OUT:
#       1: list of values not used in the row/column/square associated with dix
sub get_possible_values ( $board, $index_to_check ) {
    my %seen = (
        get_values_in_column($board,$index_to_check),
        get_values_in_row($board,$index_to_check),
        get_values_in_square($board,$index_to_check)
    );

    return ( map { $_ => 1 } grep { not exists $seen{$_} } 1..9 );
}

sub print_board ( $board, $highlight_index ) {
    for my $index ( 0..80 ) {
        printf $highlight_index && $highlight_index == $index ? '[%s] ' : '%s ', $board->[$index] // 'NA';
        if ( $index > 0 && ($index + 1) % 3 == 0 ) {
            print ' ';
        }
        print "\n" if $index && ($index + 1) % 9 == 0;
        print "\n" if $index && ($index + 1) % 27 == 0;
    }
}

sub get_values_in_square ( $board, $idx ) {
    my $square_index = get_square_from_flat($idx);
    my $start_index  = ( 3 * ( $square_index % 3 ) ) + ( int($square_index / 3) * 27 );
    my @values;

    for my $i ( 0..8 ) {
        my $index = $start_index +
                    ( $i - ( int( $i / 3 ) * 3 ) ) + # decrement by row, brings value to 0-2
                    ( 9 * int($i / 3) ); # account for the difference of 9 between rows
        next if $board->[$index] == 0;
        push @values, $board->[$index];
    }

    return ( map { $_ => 1 } @values );
}

sub get_values_in_row ( $board, $idx ) {
    my (undef, $row) = get_xy_from_flat($idx);
    my @values;

    for my $col ( 0..8 ) {
        my $index = get_flat_from_xy($col,$row);
        my $value = $board->[ $index ];

        next if $value == 0;
        push @values,$value;
    }

    return ( map { $_ => 1 } @values );
}

sub get_values_in_column ( $board, $idx ) {
    my ($column,undef) = get_xy_from_flat($idx);
    my @values;
    for my $row ( 0..8 ) {
        my $index = get_flat_from_xy($column,$row);
        my $value = $board->[ $index ];

        next if $value == 0;

        push @values, $value;
    }
    return ( map { $_ => 1 } @values );
}

#  IN: 
#       1: sudoku board
#       2: index in flattened array
# OUT
#       0: can return either 0,1 or undef:
#           1 = the row contains 1..9 with no duplicates
#           0 = the row contains duplicates
#       undef = the row has empty slots
sub is_row_valid ( $board, $idx ) {
    my (undef,$row) = get_xy_from_flat($idx);
    my %seen;

    for my $x ( 0..8 ) { 
        my $value = $board->[ get_flat_from_xy($x,$row) ];
        if ( $value == 0 ) {
            return undef;
        } elsif ( exists $seen{$value} ) {
            return 0;
        } else {
            $seen{$value} = 1;
        }
    }

    return 1;

}

sub is_column_valid ( $board, $idx ) { 
    my ( $column, undef ) = get_xy_from_flat($idx);
    my %seen;

    for my $y ( 0..8 ) {
        my $value = $board->[ get_flat_from_xy($column, $y) ];
        if ( $value == 0 ) {
            return undef;
        } elsif ( exists $seen{$value} ) {
            return 0;
        } else {
            $seen{$value} = 1;
        }
    }
    
    return 1;
}


sub get_xy_from_flat ( $index ) {
    return ($index % 9, int($index / 9) );
}

sub get_flat_from_xy( $x,$y ) {
    return ( $y * 9 + $x );
}

#  IN: index on the flattened board
# OUT: 0 based index indicating the square
#      that point resides in
sub get_square_from_flat ( $idx ) {
    return int( int( $idx / 27 ) * 3 + ( $idx % 9 / 3 ) );
}

sub print_info_for_index ( $board, $index ) {
        my ($x,$y,$square);

        ($x,$y) = get_xy_from_flat($index);

        $square = get_square_from_flat($index);
        print_board( $board, $index );
        say "Value at ${index} (${x},${y}), in square ${square} is " . $board->[$index];
        my %values = get_values_in_row($board,$index);
        printf "The values in the row are: %s\n",
            join(',', sort keys %values );
        %values = get_values_in_column($board,$index);
        printf "The values in the column are: %s\n",
            join(',', sort keys %values );
        %values = get_values_in_square($board,$index);
        printf "The values in the square (%s) are: %s\n",
            get_square_from_flat($index),
            join(',',sort keys %values );
        %values = get_possible_values( $board, $index );
        printf "Making these values still available: %s\n",
            join(',', sort keys %values );
}

1;