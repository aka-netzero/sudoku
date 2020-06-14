package sudoku;
use Moose;

use v5.30;
use square;

use feature 'signatures';
no warnings 'experimental::signatures';

use Data::Dumper qw( Dumper );

sub as_string;

use overload '""' => \&as_string;

has 'board' => (
    'is' => 'rw',
    'isa' => 'ArrayRef[square]',
    'default' => sub { [] },
);

has '_board_flat' => (
    'is' => 'rw',
    'isa' => 'ArrayRef'
);

has '_current_square' => (
    'is' => 'rw',
    'isa' => 'ScalarRef',
);

sub new {
    my ($class,$board) = @_;
    my $self = {
        _board_flat => $board // []
    };

    $self = bless $self, $class;

    if ( $board ) {
        for ( 0..$#{$board} ) {
            $self->add_cell( $board->[$_] );
        }
    }

    return $self;
}

# sudoku->new->add_cell($value)
#   IN:
#       1: The value of the cell to add, can be 1..9 or undef
#   OUT:
#       Nothing
#
# Attempts to add the value to the current square.
sub add_cell ($self,$value) {
    if (  !$self->_current_square
        || ${$self->_current_square}->get_cell_count == 9
    ) {
        $self->_add_square;
        $self->_current_square->add_cell($value);
    }
}

# sudoku->new->_add_square
#   IN:
#       Nothing
#   OUT:
#       Nothing
#
# Adds a new square to the current board if less than 9 squares are present,
# also stores a reference to said square into $self->_current_square
sub _add_square ($self) {
    if ( @{$self->board} >= 9 ) {
        die 'Attempted to add more than 9 squares to the board';
    }

    push @{$self->board},
         $self->_current_square( \(square->new) );
}

sub as_string {
    my $self = shift;
    my $str = '';

    print Dumper $self;

    $str .= join(' ', @$_) . "\n" for @{$self->{board}};

    return $str;
}

1;