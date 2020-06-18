use v5.30;
use feature 'signatures';
no warnings 'experimental::signatures';

use lib './lib/';
use sayf;

use Time::HiRes qw( time );

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
    ZERO()    => 0,   FIVE()    => 5,
    ONE()     => 1,   SIX()     => 6,
    TWO()     => 2,   SEVEN()   => 7,
    THREE()   => 3,   EIGHT()   => 8,
    FOUR()    => 4,   NINE()    => 9,
};

my $board_string = "040020900000000010000006850582300700000807000009005138097100000020000000004030000";

my $MISSING_CELLS   = () = $board_string =~ /0/g;
my $ITERATION_COUNT = 0;

my ($board,$rows,$columns,$squares) = convert_board_string ( $board_string );

my $START_TIME = time;
my ($last_index,$completed_board,$r,$c,$s) = solve(
    next_position($board,$rows,$columns,$squares),
    $board,     $rows,
    $columns,   $squares,
);
my $END_TIME = time;

if ( defined $last_index ) {
    sayf "I think we solved it in %d iterations, and a total of %sms", $ITERATION_COUNT, ($END_TIME - $START_TIME) * 1000;
    print_board( $completed_board );
} else {
    sayf "Failed in %d iterations, and a total of %.3fms", $ITERATION_COUNT, ($END_TIME - $START_TIME) * 1000;
}
exit;

sub solve ( $index, $board, $rows, $columns, $squares, $correct_count = 0 ) {
    ++$ITERATION_COUNT;
    if ( $correct_count == $MISSING_CELLS ) {
        return ($index,$board,$rows,$columns,$squares,$correct_count);
    }

    my @possible_values = get_possible_values($board,$index,$rows,$columns,$squares);

    # Bail out if this is the last needed cell and it only has one value.
    # Why waste the ops for the rest?
    if ( @possible_values == 1 && $correct_count + 1 == $MISSING_CELLS ) {
        $board->[$index] = shift @possible_values;
        return ($index,$board,$rows,$columns,$squares,$MISSING_CELLS);
    }

    my $row_index    = int($index/9);
    my $col_index    = $index % 9;
    my $square_index = int( int( $index / 27 ) * 3 + ( $index % 9 / 3 ) );

    while ( my ($try_value) = splice @possible_values, int(rand()*scalar(@possible_values)), 1 ) {
        my $new_board = [@$board];      my $r = [@$rows];
        my $c         = [@$columns];    my $s = [@$squares];
        my $cc        = $correct_count; my $i;
        $new_board->[$index] = $try_value;
        $r->[$row_index]    |= $try_value;
        $c->[$col_index]    |= $try_value;
        $s->[$square_index] |= $try_value;
        $i = next_position($new_board,$r,$c,$s);

        ($i,$b,$r,$c,$s,$cc) = solve($i,$new_board,$r,$c,$s,$cc + 1);

        if ( $cc == $MISSING_CELLS ) {
            return ($i,$b,$r,$c,$s,$cc);
        }
    }

    return ();
}

sub next_position ( $board, $r, $c, $s ) {
    my @empty_indexes = grep { $board->[$_] == ZERO } 0..$#{$board};
    my %indexes_by_number_of_options;
    my $lowest_count = 9;

    for my $idx ( @empty_indexes ) {
        my $possibility_count = scalar( get_possible_values($board,$idx,$r,$c,$s) );

        if ( $possibility_count < $lowest_count ) {
            $lowest_count = $possibility_count;
            push @{$indexes_by_number_of_options{$possibility_count} //= [] }, $idx;
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

sub convert_board_string ( $board_string ) {
    my @cells = split //, $board_string;
    my (@board,@rows,@columns,@squares);

    for ( 0 .. 80 ) {
        my $square = int( int( $_ / 27 ) * 3 + ( $_ % 9 / 3 ) );
        my $value = DEC_TO_BIN->{$cells[$_]};
        $board[$_] = $value;
        $rows[int($_/9)] |= $value;
        $columns[$_%9]   |= $value;
        $squares[$square]|= $value; 
    }
    return (\@board,\@rows,\@columns,\@squares);
}

sub print_board ( $board, $highlight_index = undef ) {
    for my $index ( 0..80 ) {
        printf $highlight_index && $highlight_index == $index ? '[%s] ' : '%s ', BIN_TO_DEC->{$board->[$index]};
        if ( $index > 0 && ($index + 1) % 3 == 0 ) {
            print ' ';
        }
        print "\n" if $index && ($index + 1) % 9 == 0;
        print "\n" if $index && ($index + 1) % 27 == 0;
    }
}

__END__

0 4 0   0 2 0   9 0 0
0 0 0   0 0 0   0 1 0
0 0 0   0 0 6   8 5 0

5 8 2   3 0 0   7 0 0
0 0 0   8 0 7   0 0 0
0 0 9   0 0 5   1 3 8

0 9 7   1 0 0   0 0 0
0 2 0   0 0 0   0 0 0
0 0 4   0 3 0   0 0 0

X = {1, 2, 3, 4, 5, 6, 7}
Y = {
    'A': [1, 4, 7],
    'B': [1, 4],
    'C': [4, 5, 7],
    'D': [3, 5, 6],
    'E': [2, 3, 6, 7],
    'F': [2, 7]}