\ Now let's get some I/O set up. ScreenProfile points to a table of xts.

there
variable ScreenProfile
: ExecScreen  ( n -- ) ScreenProfile @ execute execute ;
: emit  0 ExecScreen ;
: cr    1 ExecScreen ;

\ stdout is the screen:

: _emit  begin 'TXbusy io@ while noop repeat 'TXbuf io! ;
: _cr    13 _emit 10 _emit ; \ --

11 |bits|
: stdout_table  exec1: [	\ The xts are less than 2048
    ' _emit | ' _cr 
] literal ; 

' stdout_table ScreenProfile !	\ assign it

there swap - . .( instructions used by I/O redirect) cr