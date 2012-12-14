#include "header.h"

.text
.align 2

val:
 .long SOME_VALUE

// Multiply input value by 421...
.global mult10
.type mult10, function
mult10:
	pushq    %rbp
	movq     %rsp,%rbp

	movl val,%eax
	imull %edi,%eax

	popq     %rbp
	ret

