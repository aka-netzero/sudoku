#include<iostream>  
#include<vector>
#include<math.h>
#include<time.h>
#include<climits>
#include<chrono>

using namespace std; 
typedef unsigned short bits;

#define DEBUG 0

#define ZERO  1<<0
#define ONE   1<<1
#define TWO   1<<2
#define THREE 1<<3
#define FOUR  1<<4
#define FIVE  1<<5
#define SIX   1<<6
#define SEVEN 1<<7
#define EIGHT 1<<8
#define NINE  1<<9

const bits DEC_TO_BIN[10] = { ZERO, ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE };

#define ROW(i) (int) floor(i/9)
#define COL(i) (int) i % 9
#define SQR(i) (int) floor( floor(i / 27) * 3 + ( (i % 9) / 3 ) )
#define CHAR_TO_INT(c) c - '0'



void get_possible_options( int index, vector<bits> *r, vector<bits> *c, vector<bits> *s, vector<int> *opts ) {
    bits options = ~( (*r)[ROW(index)] | (*c)[COL(index)] | (*s)[SQR(index)]);

    for ( int i = 1; i <= 9; i++ ) {
        if ( (options & DEC_TO_BIN[i]) == DEC_TO_BIN[i] ) {
            (*opts).push_back(i);
        }
    }
}

int next_position ( vector<bits> *b, vector<bits> *r, vector<bits> *c, vector<bits> *s ) {
    vector<int> indexes_by_options[9];
    int lowest_count = INT_MAX;
    bool at_least_one_empty = false;

    for ( int i = 0; i < 81; i++ ) {
        if ( (*b)[i] == ZERO ) {
            at_least_one_empty = true;
            vector<int> options;
            get_possible_options(i,r,c,s,&options);
            if ( options.size() != 0 && options.size() < lowest_count ) {
                lowest_count = options.size();
                indexes_by_options[lowest_count-1].push_back(i);
            }
        }
    }
    if ( !at_least_one_empty || lowest_count == INT_MAX ) {
        return -1;
    }

    int random_index = rand() / ( (RAND_MAX + 1u) / indexes_by_options[lowest_count-1].size() );
    return indexes_by_options[lowest_count-1][random_index];
}

void fill_structures ( string board, vector<bits> *b, vector<bits> *r, vector<bits> *c, vector<bits> *s, int *missing_cells) {
    *missing_cells = 0;
    for ( int i = 0; i < board.size(); i++ ) {
        bits val = DEC_TO_BIN[ CHAR_TO_INT(board[i]) ];
        if ( val == ZERO ) {
            (*missing_cells)++;
        }
        b->push_back(val);
        (*s)[ SQR(i) ] |= val;
        (*r)[ ROW(i) ] |= val;
        (*c)[ COL(i) ] |= val;
    }
}

int get_char ( bits value ) {
    for ( int i = 0; i < 10; i++ ) {
        if ( (value & DEC_TO_BIN[i]) == DEC_TO_BIN[i] ) {
            return i;
        }
    }
    return -1;
}

void print_board ( vector<bits> board ) {
    cout<<"------------------------------------------------------------\n";
    for ( int i = 0; i <= 80; i++ ) {
        cout<<get_char(board[i])<<' '
            <<( i > 0 && (i + 1) % 3 == 0  ? " " : "" )
            <<( i > 0 && (i + 1) % 9 == 0  ? "\n" : "" )
            <<( i > 0 && (i + 1) % 27 == 0 ? "\n" : "" );
    }
    cout<<"------------------------------------------------------------\n";
}


bool get_random_value( vector<int> *array, int *value ) {
    if ( array->size() > 0 ) {
        int random_index = rand() / ( (RAND_MAX + 1u) / array->size() );
        *value = (*array)[random_index];
        std::swap((*array)[random_index], array->back());
        array->pop_back();
        return true;
    }

    return false;
}

int _solve(int index, vector<bits> *b, vector<bits> *r, vector<bits> *c, vector<bits> *s, int filled_cells, int to_be_filled) {
    if ( filled_cells == to_be_filled ) {
        return filled_cells;
    }

    vector<int> possible_values;
    get_possible_options(index, r, c, s, &possible_values);

    if ( possible_values.size() == 1 && (filled_cells + 1) == to_be_filled) {
        vector<bits> new_b = *b;
        new_b[index] = DEC_TO_BIN[ possible_values[0] ];
        if ( DEBUG ) { print_board(new_b); }
        return to_be_filled;
    }

    int try_val;
    while ( get_random_value(&possible_values,&try_val) ) {
        bits try_bits = DEC_TO_BIN[try_val];
        (*b)[index] = try_bits;         (*r)[ ROW(index) ] |= try_bits;
        (*c)[ COL(index) ] |= try_bits; (*s)[ SQR(index) ] |= try_bits;
        int next_pos = next_position(b,r,c,s);
        if ( next_pos == -1 && filled_cells != to_be_filled ) {
            return filled_cells;
        }
        int retval   = _solve(next_pos,b,r,c,s,filled_cells + 1, to_be_filled);

        if ( retval == to_be_filled ){
            return retval;
        } else {
            (*b)[index] = ZERO;             (*r)[ ROW(index) ] ^= try_bits;
            (*c)[ COL(index) ] ^= try_bits; (*s)[ SQR(index) ] ^= try_bits;

        }
    }

    return 0;
}

bool solve(vector<bits> *b, vector<bits> *r, vector<bits> *c, vector<bits> *s, int missing_count) {
    int pos = next_position(b,r,c,s);
    int filled = _solve(pos,b,r,c,s,0,missing_count);

    return filled == missing_count;
}

int main() {  
    const static bits empty[9] = { ZERO, ZERO, ZERO, ZERO, ZERO, ZERO, ZERO, ZERO, ZERO };
    string s = "060700409048025070910000005000000900000204000085007000000608001000000007000050094"; //"040020900000000010000006850582300700000807000009005138097100000020000000004030000";
    int cells_needed_to_win;

    double fastest_run;
    for ( int i = 0; i < 5000; i++ ) {
        srand(time(NULL));
        vector<bits> rows (empty, empty + sizeof(empty) / sizeof(empty[0]) );
        vector<bits> cols (empty, empty + sizeof(empty) / sizeof(empty[0]) );
        vector<bits> squares (empty, empty + sizeof(empty) / sizeof(empty[0]) );
        vector<bits> board;

        std::chrono::high_resolution_clock::time_point t1 = std::chrono::high_resolution_clock::now();

        fill_structures(s,&board,&rows,&cols,&squares,&cells_needed_to_win);

        bool solved = solve(&board,&rows,&cols,&squares,cells_needed_to_win);
        std::chrono::high_resolution_clock::time_point t2 = std::chrono::high_resolution_clock::now();

        std::chrono::duration<double> time_span = std::chrono::duration_cast<std::chrono::duration<double> >(t2 - t1);

        if ( solved && ( (!fastest_run) || (time_span.count() < fastest_run) ) ) {
            fastest_run = time_span.count();
            cout<< "New fastest solve: " << time_span.count() * 1000 << "ms.\n";
        }

        if ( i % 1000 == 0 ) {
            cout<< "On run " << i << "\n";
        }
    }

    return 0;
} 
