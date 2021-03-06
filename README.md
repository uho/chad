# chad

Welcome to deep embedded computing, where the best hardware is no hardware.
Well, minimal hardware. How does a processor in 200 lines of Verilog sound?
Pretty awful? Try pretty awesome.

It's so simple your computer will simulate it at 150 to 200 MIPS.
At that speed, it can host itself on your computer.
No need to turn the Verilog into hardware, just run the processor model
on your desktop or laptop.
That's the ideal environment for Forth, the programming language of
deep embedded computing.

Now you can build computing platforms almost without a processor.
If you have an FPGA or ASIC, there's your computer.
`chad` is the at-speed simulation model.

## A self-hosting Forth for J1-style CPUs

James Bowman's seminal paper on the 
[J1 CPU](https://excamera.com/sphinx/fpga-j1.html "J1 CPU")
was presented in 2010.
At under 200 lines of Verilog, the J1 was a real breakthrough in simplicity.
It also happens to be a very powerful Forth processor.

The Chad CPU, like the J1, has excellent semantic density.
The application of the J1 was a UDP stack in a Xilinx FPGA.
The code was 70% smaller than the equivalent C on a MicroBlaze.
The code just wouldn't fit in memory, so the J1 was used instead.
Chad improves on the J1 to facilitate bigger apps.

`chad` protects your software investment by targeting a very simple but
very powerful (for its size) stack computer.
Modern desktop computers are fast enough to simulate the CPU on the order of at-speed.
Simulation speed on my desktop depends on the compiler:

- 145 MIPS on Code::Blocks 17.12 (GCC).
- 160 MIPS on Visual Studio 2019 Community Edition.

It's like having a real CPU running in an FPGA, but without an FPGA.
Forth should execute the code it compiles.
Cross compiling, such as targeting ARM with code running on x86,
adds a lot of complexity which is completely unnecessary with Chad.

You can add custom functions easily. Just edit `chad.c` and `chaddefs.h`.
Recompile and your simulated computer and its language have the new features.
Chad comes as C source. Once you compile it, you have a Forth that can extend
itself in such a way that the binaries can be output for inclusion in a SOC.
You can add code to Chad's simulation to mimic your SOC so that the PC is
the development environment.

Since Chad's simulation of the CPU is its specification, which is under 200
lines of C, the processor is also called Chad.
You can specify the cell size as any width between 16 and 32 bits
(in the `config.h` file) and recompile Chad with any C compiler.

Chad's way of working isn't fully ANS compatible, which is fine.
The great thing about hosting the Forth in C is that there's not much confusion
about what the Forth does. You can look at the C source.

The main source files are:

- `main.c` Inputs the command line
- `chad.c` Simulates the CPU and implements a text interpreter
- `iomap.c` Simulates the I/O of the CPU

To try it out, launch it with `chad include lib.fs`.
At the `ok>` prompt, type `0 here dasm` to disassemble everything.

- `stats` lists the cycle count and maximum stack depths.
- `words` lists words.
- `see` disassembles a word.

For example:
```
ok>include forth.fs
370 instructions used
ok>25 fib .
121393 ok>stats
2792024 cycles, MaxSP=27, MaxRP=26, 155 MHz
ok>
```

## And a documentation standard.

`chad` presents a documentation system for Forth systems.
It doesn't need the ANS Forth standard, it generates a standard from source.

Your project folder has a `html` folder that contains documentation.
`chad` generates hyperlinked HTML versions of each source file
so that you can click on any word to get an explanation of what it does
and if necessary, a link to the source code of that word.
That helps you navigate Forth source code even if you're new to Forth.
The documentation is re-built each time you build your app.

The 20th Century was great and all, with its books and PDF equivalents.
We have web browsers now.
