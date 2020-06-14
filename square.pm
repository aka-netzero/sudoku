package square;
use Moose;

use v5.30;
use feature 'signatures';
no warnings 'experimental::signatures';

use overload '""' => \&as_string;

use cell;

has grid => (
    is => 'rw',
    isa => 'ArrayRef[ScalarRef]',
    default => sub { +[] },
);

sub add_cell ($value) {
    my $self = shift;

    if ( @{$self->grid} < 9 ) {
        push @{$self->grid}, cell->new($value);
    } else {
        # Move on to the next one? Who manages this?
    }

}

sub get_cell_count ($self) { scalar @{$self->grid} }

sub as_string {
    my $self = shift;
    my $str  = '';

    $str .= join( @{$self->grid})

}

1;