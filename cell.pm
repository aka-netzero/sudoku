package cell;

use Moose;
use v5.30;
use feature 'signatures';
no warnings 'experimental::signatures';


use Data::Dumper qw( Dumper );

has value => (
    is  => 'rw',
    isa => 'Int',
    builder => '_add_value',
);

has neighbours => (
    is => 'rw',
    isa => 'ArrayRef[ScalarRef]',
);

# add_neighbour
#   IN:
#       1) scalar or scalar reference to the cell that should be added as a neighbour of this cell
#   OUT:
#       1)  1 if the operation was successful (defined as no existing neighbour shares the value being added)
#          -1 if the operation failed (another neighbour exists with this value);
sub add_neighbour ($) {
    my $self = shift;
    my $ref  = ref $_[0] eq 'SCALAR' ? $_[0] : \$_[0];

    die sprintf 'I am not sure what you passed me: %s', Dumper $ref
        unless ref $ref eq 'SCALAR';

    die sprintf 'Maximum number of neighbours is 16, something went wrong. Current cell value is "%d", attempted to add "%d".', $self->value, ${$ref}->value
        if @{$self->neighbours} >= 16;

    # Ensure none of the existing neighbours have the value being added
    if ( scalar( grep { $$ref->value == $$_->value } @{$self->neighbours} ) ) {
        return -1;
    } else {
        push @{$self->neighbours}, $ref;
        return 1;
    }
}

sub _add_value ($) {

}

1;