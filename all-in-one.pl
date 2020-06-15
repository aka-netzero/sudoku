use v5.30;
use feature 'signatures';
no warnings 'experimental::signatures';

use Getopt::Long;
use Time::HiRes qw(time);

# 040020900000000010000006850582300700000807000009005138097100000020000000004030000
# One complete solution v
# 148523967256789314973416852582391746431867529769245138697154283325678491814932675
# Broken by removing                                   vvvvvv 2803 vvvvv
# 040020900000000010000006850582300700000867000009005138097150280325670001814930000
# 148523967256789314973416852582391746431867529769245138697154283325678491814932675
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
my $GLOBAL_MAX_CORRECT      = 0;
my $GLOBAL_ITERATIONS_COUNT = 0;

GetOptions(
    'pos=s'   => \(my $POSITION_ALGORITHM = 'lowest_options'),
    'board=s' => \(my $BOARD_STRING = "040020900000000010000006850582300700000807000009005138097100000020000000004030000"),
    'debug'   => \(my $DEBUG = 0),
);

my $board_string = $BOARD_STRING;
my $starting_board = [ split //, $board_string ];
my $MISSING_CELLS = () = $board_string =~ /0/g;
my $WINNING_COUNT =
    $POSITION_ALGORITHM eq 'lowest_options' || $POSITION_ALGORITHM eq 'random_empty' ? $MISSING_CELLS : 81;

printf "Starting solve with %d filled in cells, meaning %d missing cells\n", 81 - $MISSING_CELLS, $MISSING_CELLS;

my $START_TIME = time;
my ($solving_board,undef,undef) = start_solve(\$starting_board, next_position($starting_board),0);
my $FINISH_TIME = time;

say '=' x 80;
printf "It took %sms to finish, and a total of %d iterations to solve.", int( ($FINISH_TIME - $START_TIME) * 1000), $GLOBAL_ITERATIONS_COUNT;
say "The original board was:";
print_board($starting_board);
say '=' x 80;
say "The solved board is:";
print_board($$solving_board);

if ( $DEBUG ) {
    say "Oh you don't trust The Code™? Fine. Here's what the under the hood code thinks:";
    for ( 0..8 ) {
        printf "\tSquare %d is %svalid\tColumn %d is %svalid\tRow %d is %svalid\n",
            $_, (is_square_valid($$solving_board,$_) == 1 ? '' : 'not '),
            $_, (is_column_valid($$solving_board,$_) == 1 ? '' : 'not '),
            $_, (   is_row_valid($$solving_board,$_) == 1 ? '' : 'not ');
    }

    my @empty_indexes = get_empty_indexes($$solving_board);

    if ( @empty_indexes ) {
        printf "Found %d empty index(es)... lets see what if it only has one possibility ey?\n", @empty_indexes;
        printf "\tIndex: %d has possible values of: %s\n", $empty_indexes[0], get_possible_values($$solving_board,$empty_indexes[0]);
    }
}
say '=' x 80;

exit;

sub start_solve ( $board_ref, $index, $correct_count ) {
    # printf "start_solve called with index and correct_count: %d, %d\n", $index,$correct_count;
    if ( ++$GLOBAL_ITERATIONS_COUNT % 150000 == 0 ) {
        say "${GLOBAL_ITERATIONS_COUNT} iterations checked.";
    }

    if ( $GLOBAL_ITERATIONS_COUNT > 900_000 && $correct_count > $GLOBAL_MAX_CORRECT ) {
        $GLOBAL_MAX_CORRECT = $correct_count;
        say "New global max correct hit, new value: ${correct_count}";
    }

    if ( $correct_count == $WINNING_COUNT ) {
        say "Woot, solved!";
        return ( $board_ref, $index, $correct_count );
    }
    # &shrug;
    elsif ( $index > 80 ) {
        say "Index higher than 80, don't know what happened honestly.";
        return ();
    }

    # If the current index is already filled in, we assume it's correct and move on
    if ( ${ $board_ref }->[$index] != 0 ) {
        # printf "Index %d already has a non-zero value (%d). Moving onto next index.\n", $index, ${ $board_ref }->[$index];
        return start_solve($board_ref, next_position($$board_ref), $correct_count + 1);
    } else {
        my %possible_values = get_possible_values($$board_ref, $index);
        # printf "Possible values for %d are: %s\n", $index, join(',', keys %possible_values);
        for my $try_value ( keys %possible_values ) {
            # printf "Attempting to fill index %d (%d correct so far) with: %d\n", $index,$correct_count,$try_value;
            # printf "\tSetting to value %d\n", $try_value;
            my $new_board = [ @{$$board_ref} ];
            $new_board->[$index] = $try_value;

            my $next_position = $correct_count + 1 == $WINNING_COUNT ? $index : next_position($new_board);
            my ($new_ref,$idx,$cc) = start_solve(\$new_board,$next_position,$correct_count+1);
            if ( $cc == $WINNING_COUNT ) {
                return ($new_ref,$idx,$cc);
            }
        }
    }

    return ();
}

sub next_position ( $board ) {
    my $pos_algo = $POSITION_ALGORITHM;

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

sub get_random_empty_index ( $board ) {
    my @indexes = get_empty_indexes($board);
    my $index = int(rand() * scalar(@indexes));

    return $indexes[ $index ];
}

sub get_empty_indexes ( $board ) {
    return grep { $board->[$_] == 0 } 0..80;
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

sub print_board ( $board, $highlight_index = undef) {
    for my $index ( 0..80 ) {
        printf $highlight_index && $highlight_index == $index ? '[%s] ' : '%s ', $board->[$index] // 'NA';
        if ( $index > 0 && ($index + 1) % 3 == 0 ) {
            print ' ';
        }
        print "\n" if $index && ($index + 1) % 9 == 0;
        print "\n" if $index && ($index + 1) % 27 == 0;
    }
}

# Only used in debugging, because why else do I need it right now?
#  IN: index of cell within square
# OUT:
#       1: square is filled completely and accurate
#       0: square is filled completely and incorrect
#           (?) ^ Not sure this is possible
#   undef: square is incomplete
sub is_square_valid ( $board, $square_index ) {
    my @used_values = get_values_in_square($board, get_first_index_in_square($square_index));
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

#  IN:
#       1: Index of the square from 0-8
# OUT:
#       1: Index of the first cell of the square in the board
sub get_first_index_in_square ( $square_index ) {
    return ( 3 * ( $square_index % 3 ) ) + ( int($square_index / 3) * 27 );
}

sub get_values_in_square ( $board, $idx ) {
    my $square_index = get_square_from_flat($idx);
    my $start_index  = get_first_index_in_square($square_index);
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


# IN:
#       1: board arrayref
#       2: index of the cell to work from
# OUT:
#       1: hash in the form ( VALUE => 1, VALUE => 1 )
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

# IN:
#       1: board arrayref
#       2: index of the cell to work from
# OUT:
#       1: hash in the form ( VALUE => 1, VALUE => 1 )
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
# OUT:
#       1: can return either 0,1 or undef:
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

#  IN:
#       1: sudoku board
#       2: index in flattened array
# OUT:
#       1: can return either 0,1 or undef:
#           1 = the column contains 1..9 with no duplicates
#           0 = the column contains duplicates
#       undef = the column has empty slots
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

#  IN:
#       1: index in flattened array
# OUT:
#       1: list with the equivalent x,y coord
sub get_xy_from_flat ( $index ) {
    return ($index % 9, int($index / 9) );
}

#  IN:
#       1: x
#       2: y
# OUT:
#       1: index in the flattened array
sub get_flat_from_xy( $x,$y ) {
    return ( $y * 9 + $x );
}

#  IN: 
#       1: index on the flattened board
# OUT:
#       1: zero based index indicating the square
#          that point resides in
sub get_square_from_flat ( $idx ) {
    return int( int( $idx / 27 ) * 3 + ( $idx % 9 / 3 ) );
}

# Test sub
sub testing {
    while(1) {
        print "Enter index in the flattened array: ";
        chomp( my $str = <STDIN> );

        last if $str eq '';

        print_info_for_index( $starting_board, $str );
    }
}

# Also a debugging sub
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

__END__
   flat, printed as two-d                       two-d
 0  1  2   3  4  5   6  7  8    0,0 1,0 2,0  3,0 4,0 5,0  6,0 7,0 8,0 
 9 10 11  12 13 14  15 16 17    0,1 1,1 2,1  3,1 4,1 5,1  6,1 7,1 8,1
18 19 20  21 22 23  24 25 26    0,2 1,2 2,2  3,2 4,2 5,2  6,2 7,2 8,2

27 28 29  30 31 32  33 34 35    0,3 1,3 2,3  3,3 4,3 5,3  6,3 7,3 8,3
36 37 38  39 40 41  42 43 44    0,4 1,4 2,4  3,4 4,4 5,4  6,4 7,4 8,4
45 46 47  48 49 50  51 52 53    0,5 1,5 2,5  3,5 4,5 5,5  6,5 7,5 8,5

54 55 56  57 58 59  60 61 62    0,6 1,6 2,6  3,6 4,6 5,6  6,6 7,6 8,6
63 64 65  66 67 68  69 70 71    0,7 1,7 2,7  3,7 4,7 5,7  6,7 7,7 8,7
72 73 74  75 76 77  78 79 80    0,8 1,8 2,8  3,8 4,8 5,8  6,8 7,8 8,8


0 4 0   0 2 0   9 0 0
0 0 0   0 0 0   0 1 0
0 0 0   0 0 6   8 5 0

5 8 2   3 0 0   7 0 0
0 0 0   8 0 7   0 0 0
0 0 9   0 0 5   1 3 8

0 9 7   1 0 0   0 0 0
0 2 0   0 0 0   0 0 0
0 0 4   0 3 0   0 0 0