The FK Table

This is a reference implementation of a new kerning table that stores fixed 
point 16.16 values. The idea is to get better precision for kerning of OTF 
and TTF fonts. The goal is also to create a solution that is is simple and fast.

The code is small and hopefully easy to understand. The parser needs around 200
lines of code and around 40 more lines are needed to add support for writing 
the table.

Please ask if you need help or clarifications.

All code related to the FK feature in this folder is example code. Copy and
paste of this code into any project with any license is permitted.

An OTF parser only needs fk.c and fk.h. A font editor might also use
fk-font-editor.c and fk-font-editor.h. The file fk-test.c provides an 
example of how the code could be used.

Regards
Johan Mattsson
johan.mattsson.m@gmail.com
