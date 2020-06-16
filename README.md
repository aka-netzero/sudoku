# sudoku

Repo containing my sudoku solver(s).

Eventually my intention is to write various solving algorithm packages and enable benchmarking between them. This is not novel
work by any stretch, but it's an excerise that I have been thinking about for some time and just never executed. 

## Algorithms

These are the currently implemented algorithms:

* **FlatArrayBacktrack** this package uses a single dimension array to represent the board and a recursive backtracking algorithm to solve. This package was not written with performance in mind, except to ensure reasonable time completion of solveable boards. To that end it recalculates available positions any time it needs to know, and uses additional functions to determine row/column/square neighbours. But it works, and that's what's important.

These are the algorithms I intend to implement:

* **FlatArrayBacktrackv2** this one will share a lot of similarities to the first one, except I will no longer restrict myself to only storing the board. Instead I'll pregenerate at least rows/columns/squares arrays for easy lookup. This will increase the amount of data we're passing down the stack in the solve function, but should also dramatically reduce the number of function calls required between iterations.
* **AlgorithmX** this algo is the reason I kept working at this project even after I kept getting demotivated and unable to complete it (burnout sucks). Conceptually I understand how it works, but I'm still not 100% sure on how to convert a Sudoku board to fit. I need to read the whitepaper yet but this is the first algorithm I will be learning about and implementing for the first time in this repo.
* **GeneticSolver** another solver that will be a first for me, I've got this genetic algorithms book on my desk and this is the project I've decided will finally get me to read it. This package will absolutely not be the fastest, but it should be an interesting journey to implement.
