rm test.int
./spimulator.pl test.s > test.int
spim -file simulator.s < test.int
