#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "util.h"

void
die(const char *errstr, ...) {
	va_list ap;

	va_start(ap, errstr);
	vfprintf(stderr, errstr, ap);
	va_end(ap);
	exit(EXIT_FAILURE);
}

void *
xmalloc(size_t size) {
	void *p = malloc(size);

	if(!p)
		die("Out of memory: could not malloc() %d bytes\n", size);

	return p;
}

void *
xcalloc(size_t nmemb, size_t size) {
	void *p = calloc(nmemb, size);

	if(!p)
		die("Out of memory: could not calloc() %d bytes\n", nmemb*size);

	return p;
}
