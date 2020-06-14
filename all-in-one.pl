use v5.30;
use feature 'signatures';
no warnings 'experimental::signatures';

# 040020900000000010000006850582300700000807000009005138097100000020000000004030000
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
my $board_string = "148523900000000010000006850582300700000807000009005138097100000020000000004030000";
my $starting_board = [ split //, $board_string ]; #@board_raw ];

my $GLOBAL_MAX_CORRECT = 0;
my $GLOBAL_ITERATIONS_COUNT = 0;

my $missing_cells = () = $board_string =~ /0/g;
printf "Starting solve with %d filled in cells, meaning %d missing cells\n", 81 - $missing_cells, $missing_cells;

# print_info_for_index( $starting_board, 0 ); exit;

sub start_solve ( $board_ref, $index, $correct_count ) {
    # printf "start_solve called with index and correct_count: %d, %d\n", $index,$correct_count;
    say "${GLOBAL_ITERATIONS_COUNT} iterations checked."
        if ++$GLOBAL_ITERATIONS_COUNT % 150000 == 0;
    ($GLOBAL_MAX_CORRECT = $correct_count) and 
       say "New global max correct hit, new value: ${correct_count}"
           if $correct_count > $GLOBAL_MAX_CORRECT;

    if ( $correct_count == 81 ) {
        say "Woot, solved!";
        printf "It took %d iterations to solve.\n", $GLOBAL_ITERATIONS_COUNT;
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
        return start_solve($board_ref, get_random_empty_index($$board_ref), $correct_count + 1);
    } else {
        my %possible_values = get_possible_values($$board_ref, $index);
        # printf "Possible values for %d are: %s\n", $index, join(',', keys %possible_values);
        for my $try_value ( keys %possible_values ) {
            # printf "Attempting to fill index %d (%d correct so far) with: %d\n", $index,$correct_count,$try_value;
            # printf "\tSetting to value %d\n", $try_value;
            my $new_board = [ @{$$board_ref} ];
            $new_board->[$index] = $try_value;

            my ($new_ref,undef,$cc) = start_solve(\$new_board,get_random_empty_index($new_board),$correct_count+1);
            if ( $cc == 81 ) {
                return ($new_ref,80,$cc);
            }
        }
    }
    # This is the fucking problem, for sure.
    return ();
    # return ($board_ref, get_random_empty_index($$board_ref), $correct_count );
}

start_solve(\$starting_board, get_random_empty_index($starting_board),0);

exit;

sub get_random_empty_index ( $board ) {
    my @indexes = get_empty_indexes($board);
    my $index = int(rand() * scalar(@indexes));

    return $indexes[ $index ];
}

sub get_empty_indexes ( $board ) {
    return grep { $board->[$_] == 0 } 0..80;
}

#  IN:
#       1: reference to copy of sudoku board (flattened)
#       2: index of the cell you'd like to set
#       3: value you'd like to set into the square
# OUT:
#       1: 1 if the value was successfully set (ie there is no collision in the row/column/square)
#          0 if the value was not set due to duplicate
sub check_and_place_value_at_index ( $board_ref, $index, $value ) {
    my %possible_values = get_possible_values( $$board_ref, $index );

    if ( not exists $possible_values{$value} ) {
        return 0;
    } else {
        $$board_ref->[$index] = $value;
        return 1;
    }
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

sub testing {
    while(1) {
        print "Enter index in the flattened array: ";
        chomp( my $str = <STDIN> );

        last if $str eq '';

        print_info_for_index( $starting_board, $str );
    }
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


exit;


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