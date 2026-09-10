#include <stdio.h>

int fixture_call(void) {
	return puts("The original function should have been replaced.");
}
