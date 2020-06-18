use v5.30;
use feature 'signatures';
no warnings 'experimental::signatures';

use lib './lib/';
use sayf;

use constant {
    ONE     => 1 << 0,  SIX     => 1 << 5,
    TWO     => 1 << 1,  SEVEN   => 1 << 6,
    THREE   => 1 << 2,  EIGHT   => 1 << 7,
    FOUR    => 1 << 3,  NINE    => 1 << 8,
    FIVE    => 1 << 4,
};

use constant DEC_TO_BIN => {
    1 => ONE,       6 => SIX,
    2 => TWO,       7 => SEVEN,
    3 => THREE,     8 => EIGHT,
    4 => FOUR,      9 => NINE,
    5 => FIVE,
};

sub sayb ( $binary ) { sayf( "%#012b %1\$3d", $binary ); }


my $board_string = "040020900000000010000006850582300700000807000009005138097100000020000000004030000";
my ($board,$rows,$columns,$squares) = convert_board_string ( $board_string );

get_possible_values(1,$rows,$columns,$squares);

exit;

# index, rows, columns, squares
sub get_possible_values ( $i,$r,$c,$s ) {
    my $possibilities = ~( $r->[ int($i/9) ] | $c->[$i%9] | $squares->[ int( int( $i / 27 ) * 3 + ( $i % 9 / 3 ) ) ] );
    for ( 1..9 ) {
        unless ( $possibilities & DEC_TO_BIN->{$_} ) {
            sayf "Number %d is available!", $_;
        }
    }
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

__END__

sub get_square_from_flat ( $idx ) {
    return int( int( $idx / 27 ) * 3 + ( $idx % 9 / 3 ) );
}

sub get_xy_from_flat ( $index ) {
    return ($index % 9, int($index / 9) );
}

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