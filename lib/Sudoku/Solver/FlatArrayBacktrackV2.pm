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
    ZERO()    => 0,   FIVE()    => 5,
    ONE()     => 1,   SIX()     => 6,
    TWO()     => 2,   SEVEN()   => 7,
    THREE()   => 3,   EIGHT()   => 8,
    FOUR()    => 4,   NINE()    => 9,
};

sub new ( $class, $options ) {
    my ($board,$rows,$columns,$squares) = convert_board_string ( $options->{board_string} );
    my $self = {
        _board   => $board,
        _rows    => $rows,
        _columns => $columns,
        _squares => $squares,
        
        _iterations => 0,
    };
    $self->{_cells_needed_to_win} = () = $options->{board_string} =~ /0/g;
    $self->{_originals} = {
        _board   => [ @{ $self->{_board}   } ],
        _rows    => [ @{ $self->{_rows}    } ],
        _columns => [ @{ $self->{_columns} } ],
        _squares => [ @{ $self->{_squares} } ],
    };

    return bless $self, __PACKAGE__;
}

sub solve ( $self ) {
    my @necessary_args = ($self->{_board},$self->{_rows}, $self->{_columns}, $self->{_squares});
    my $start_position = next_position(@necessary_args);
    my ($last_index,$last_board,$r,$c,$s,$filled_cells) = $self->_solve($start_position, @necessary_args);

    if ( $last_board && $filled_cells ) {
        if ( $filled_cells == $self->{_cells_needed_to_win} ) {
            return $self->{_iterations};
        } else {
            say "Well now that's odd isn't it? 'Solved' board looks like: ";
            print_board($last_board);
            printf "But the correct count does not match the expected: %s\n", $filled_cells // 'undef';
            return undef;
        }
    }
    return undef;
}

sub _solve ( $self, $index, $board, $rows, $columns, $squares, $correct_count = 0 ) {
    ++$self->{_iterations};
    if ( $correct_count == $self->{_cells_needed_to_win} ) {
        return ($index,$board,$rows,$columns,$squares,$correct_count);
    }

    my @possible_values = get_possible_values($board,$index,$rows,$columns,$squares);

    # Bail out if this is the last needed cell and it only has one value.
    # Why waste the ops for the rest?
    if ( @possible_values == 1 && $correct_count + 1 == $self->{_cells_needed_to_win} ) {
        $board->[$index] = shift @possible_values;
        return ($index,$board,$rows,$columns,$squares,$self->{_cells_needed_to_win});
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

        ($i,$b,$r,$c,$s,$cc) = $self->_solve($i,$new_board,$r,$c,$s,$cc + 1);

        if ( $cc == $self->{_cells_needed_to_win} ) {
            return ($i,$b,$r,$c,$s,$cc);
        }
    }

    return ();
}

sub reset ( $self ) {
    $self->{$_} = $self->{_originals}{$_} for keys %{ $self->{_originals} };
    $self->{_iterations} = 0;
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

1;