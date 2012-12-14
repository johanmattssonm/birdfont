/* simple C library to exercize CGO */

#include <stdio.h>
#include "my-c-lib.h"

void my_c_hello(const char *msg)
{
  fprintf(stdout, msg);
}

void my_c_bye(const char *msg)
{
  fprintf(stdout, msg);
}

