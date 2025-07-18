package main

/*
#cgo LDFLAGS: -L./lib -lhello
#include <stdlib.h>

extern char* hello_from_zig();
extern int add_numbers(int a, int b);
*/
import "C"
import (
	"fmt"
)

func main() {
	// Call Zig function that returns a string
	cStr := C.hello_from_zig()
	goStr := C.GoString(cStr)
	fmt.Println(goStr)

	// Call Zig function that adds two numbers
	result := C.add_numbers(42, 8)
	fmt.Printf("42 + 8 = %d (calculated in Zig)\n", int(result))
}

// GoHelloFromZig wraps the Zig function for easier use
func GoHelloFromZig() string {
	cStr := C.hello_from_zig()
	return C.GoString(cStr)
}

// GoAddNumbers wraps the Zig add function
func GoAddNumbers(a, b int) int {
	return int(C.add_numbers(C.int(a), C.int(b)))
}