\ Core definitions

\ You can compile to either check address alignment or not.
\ Set to 0 when everything looks stable. The difference is 25 instructions.

0 equ check_alignment                   \ 2.0000 -- n
\ enable @, !, w@, and w! to check address alignment

0 torg
later cold                              \ 2.0010 -- \ boots here
later exception                         \ 2.0020 n --

: noop  nop ;                           \ 2.0100 --
: io@   _io@ nop _io@_ ;                \ 2.0110 addr -- n
: io!   _io! nop drop ;                 \ 2.0120 n addr --
: =     xor 0= ;                        \ 2.0130 n1 n2 -- flag
: <     - 0< ; macro                    \ 2.0140 n1 n2 -- flag
: >     swap < ;                        \ 2.0150 n1 n2 -- flag
: cell+ cell + ; macro                  \ 2.0160 a-addr1 -- a-addr2

cell 4 = [if]
    : cells 2* 2* ; macro               \ 2.0170 n1 -- n2
    : (x!)  ( u w-addr bitmask wordmask )
        >carry swap
        dup>r and 3 lshift dup>r lshift
        w r> lshift invert
        r@ _@ _@_ and  + r> _! drop
    ;
    : c!  ( u c-addr -- ) 3 $FF  (x!) ; \ 2.0180 c addr --
  check_alignment [if]
    : (ta)  ( a mask -- a )
          over and if  22 invert exception  then ;
    : @   3 (ta)  _@ _@_ ;              \ 2.0210 a-addr -- x
    : !   3 (ta)  _! drop ;             \ 2.0200 x a-addr --
    : w!  ( u w-addr -- )               \ 2.0190 w addr --
          1 (ta) 2 $FFFF (x!) ;
    : w@  ( w-addr -- u )               \ 2.0220 addr -- w
          1 (ta) _@ dup@ swap 2 and 3 lshift rshift $FFFF and ;
  [else]
    : @   _@ _@_ ; macro                \ 2.0210 a-addr -- x
    : !   _! drop ; macro               \ 2.0200 x a-addr --
    : w!  2 $FFFF (x!) ;                \ 2.0190 w addr --
    : w@  _@ dup@ swap 2 and 3 lshift   \ 2.0220 addr -- w
          rshift $FFFF and ;
  [then]
[else] \ 16-bit or 18-bit cells
    : cells 2* ; macro                  \ 2.0170 n1 -- n2
  check_alignment [if]
    : (ta)  over and if  22 invert exception  then ;
    : @   1 (ta)  _@ _@_ ;              \ 2.0210 a-addr -- x
    : !   1 (ta)  _! drop ;             \ 2.0200 x a-addr --
  [else]
    : @   _@ _@_ ; macro                \ 2.0210 a-addr -- x
    : !   _! drop ; macro               \ 2.0200 x a-addr --
  [then]
    : c! ( u c-addr -- )                \ 2.0180 c c-addr --
        dup>r 1 and if
            8 lshift  $00FF
        else
            255 and   $FF00
        then
        r@ _@ _@_ and  + r> _! drop
    ;
[then]

: c@    _@ dup@ swap mask rshift wand ; \ 2.0200 c-addr -- c

\ Your code can usually use + instead of OR, but if it's needed:
: or    invert swap invert and invert ; \ 2.0300 n m -- n|m
: rot   >r swap r> swap ;               \ 2.0310 x1 x2 x3 -- x2 x3 x1

: execute  2* >r ; no-tail-recursion    \ 2.0320 i*x xt -- j*x

: 2dup   over over ; macro              \ 2.0330 d -- d d
: 2drop  drop drop ;                    \ 2.0340 d --
: char+ [ ;                             \ 2.0350 c-addr1 -- c-addr2
: 1+     1 + ; ( macro )                \ 2.0360 n -- n+1
: 1-     1 - ; ( macro )                \ 2.0370 n -- n-1
: negate invert 1+ ;                    \ 2.0380 n -- -n
: tuck   swap over ; macro              \ 2.0390 n1 n2 -- n2 n1 n2
: +!     tuck @ + swap ! ;              \ 2.0400 n a-addr --

\ Math iterations are subroutines to minimize the latency of lazy interrupts.
\ These interrupts modify the RET operation to service ISRs.
\ RET ends the scope of carry and W so that ISRs may trash them.
\ Latency is the maximum time between returns.

\ Multiplication using shift-and-add, 160 to 256 cycles at 16-bit.
\ Latency = 17
: (um*)
    2* >r 2*c carry
    if  over r> + >r carry +
    then  r>
;
: um*                                   \ 2.0410 u1 u2 -- ud
    0 [ cellbits 2/ ] literal           \ cell is an even number of bits
    for (um*) (um*) next
    >r nip r> swap
;

\ Long division takes about 340 cycles at 16-bit.
\ Latency = 25
: (um/mod)
    >r  swap 2*c swap 2*c               \ 2dividend | divisor
    carry if
        r@ -   0 >carry
    else
        dup r@  - drop                  \ test subtraction
        carry 0= if  r@ -  then         \ keep it
    then
    r>  carry                           \ carry is safe on the stack
;
: um/mod                                \ 2.0420 ud u -- ur uq
    over over- drop carry
    if  drop drop dup xor
        dup invert  exit                \ overflow = 0 -1
    then
    [ cellbits 2/ ] literal
    for (um/mod) >carry
        (um/mod) >carry
    next
    drop swap 2*c invert                \ finish quotient
;

: *     um* drop ;                      \ 2.0430 n1 n2 -- n3
: dnegate                               \ 2.0440 d -- -d
        invert swap invert 1 + swap 0 +c ;
: abs   dup 0< if negate then ;         \ 2.0450 n -- u
: dabs  dup 0< if dnegate then ;        \ 2.0460 d -- ud

: m/mod
    dup 0< dup >r
    if negate  >r
       dnegate r>
    then >r dup 0<
    if r@ +
    then r> um/mod
    r> if
       swap negate swap
    then
;
: /mod   over 0< swap m/mod ;           \ 2.0470 n1 n2 -- rem quot
: mod    /mod drop ;                    \ 2.0480 n1 n2 -- rem
: /      /mod nip ;                     \ 2.0490 n1 n2 -- quot
: m*                                    \ 2.0500 n1 n2 -- d
    2dup xor 0< >r
    abs swap abs um*
    r> if dnegate then
;
: */mod  >r m* r> m/mod ;               \ 2.0510 n1 n2 n3 -- rem quot
: */     */mod swap drop ;              \ 2.0520 n1 n2 n3 -- n4

\ In order to use CREATE DOES>, we need ',' defined here.

dp cell+ dp ! \ variables shared with chad's interpreter
variable base                           \ 2.0530 -- a-addr
variable state                          \ 2.0540 -- a-addr
variable >in                          	\ 2.0541 -- a-addr
variable tibs                         	\ 2.0542 -- a-addr
align
: aligned  [ cell 1- ] literal +        \ 1.1050 addr1 -- addr2
           [ cell negate ] literal and ;
: align    dp @ aligned dp ! ;          \ 1.1060 --
: allot    dp +! ;                      \ 2.0550 n --
: here     dp @ ;                       \ 2.0560 -- addr
: ,        align here !  cell allot ;   \ 2.0570 x --
: c,       here c!  1 allot ;           \ 2.0580 c --

\ We're about at 300 instructions at this point.
\ Paul Bennett's recommended minimum word set is mostly present.
\ DO, I, J, and LOOP are not included. Use for next r@ instead.
\ CATCH and THROW are not included. They use stack.
\ DOES> needs a compilable CREATE.

: u<     - drop carry 0= 0= ;           \ 2.0700 u1 u2 -- flag
: min    over over- 0< if               \ 2.0710 n1 n2 -- n3
         swap drop exit then  drop ;
: max    over over- 0< if               \ 2.0720 n1 n2 -- n3
         drop exit then  swap drop ;

CODE depth                              \ 2.0730 -- +n
    status T->N d+1 alu   drop 31 imm   T&N d-1 RET alu
;CODE

: exec2: 2* [ ;             \ 2.0740 n -- \ for list of 2-inst literals
: exec1: 2* r> + >r ;       \ 2.0750 n -- \ for list of 1-inst literals

there . .( instructions used by core) cr
