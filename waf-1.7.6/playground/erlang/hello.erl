% what a weird language ... :-)

-module(hello).
-export([hello_world/0]).
hello_world() -> io:fwrite("hello, world\n").
