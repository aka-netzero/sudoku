use v5.30;
use feature 'signatures';
no warnings 'experimental::signatures';

use lib './lib/';
use sayf;

sayb( 1 << $_ - 1 ) for 1..9;


sub sayb ( $binary ) { sayf( "%#012b %1\$3d", $binary ); }

# for ( my $k = 1; $k<40; $k += 7 ) {
#     sayf "%10b %3d",$k,$k;
# }


my $board_string = "040020900000000010000006850582300700000807000009005138097100000020000000004030000";
my ($board,$rows,$columns,$squares) = convert_board_string ( $board_string );

sub get_possible_values ( $index ) {
    my $value = $board->[$index];
    my @possible_values = (

    )
}

sub convert_board_string ( $board_string ) {
    my @cells = split //, $board_string;
    my (@board,@rows,@columns,@squares);

    for ( 0 .. 80 ) {
        my $square = int( int( $_ / 27 ) * 3 + ( $_ % 9 / 3 ) );
        my $value = 1 << $cells[$_];
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


board[1]     = 0b0000010000
rows[0]     |= 0b0000010000 = (0b0000000000 | 0b0000010000) = 0b0000010000
columns[1]  |= 0b0000010000 = (0b0000000000 | 0b0000010000) = 0b0000010000
square[0]   |= 0b0000010000 = (0b0000000000 | 0b0000010000) = 0b0000010000

board[4]     = 0b0000000010
rows[0]     |= 0b0000000010 = (0b0000010000 | 0b0000000010) = 0b0000010010
columns[4]  |= 0b0000000010
square[1]   |= 0b0000000010
1 0b0000000010   2
2 0b0000000100   4
3 0b0000001000   8
4 0b0000010000  16
5 0b0000100000  32
6 0b0001000000  64
7 0b0010000000 128
8 0b0100000000 256
9 0b1000000000 512


X = {1, 2, 3, 4, 5, 6, 7}
Y = {
    'A': [1, 4, 7],
    'B': [1, 4],
    'C': [4, 5, 7],
    'D': [3, 5, 6],
    'E': [2, 3, 6, 7],
    'F': [2, 7]}