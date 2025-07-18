package main

import (
	"testing"
)

func TestGoHelloFromZig(t *testing.T) {
	result := GoHelloFromZig()
	expected := "Hello from Zig!"
	
	if result != expected {
		t.Errorf("Expected %q, got %q", expected, result)
	}
}

func TestGoAddNumbers(t *testing.T) {
	result := GoAddNumbers(10, 5)
	expected := 15
	
	if result != expected {
		t.Errorf("Expected %d, got %d", expected, result)
	}
	
	// Test with negative numbers
	result = GoAddNumbers(-3, 7)
	expected = 4
	
	if result != expected {
		t.Errorf("Expected %d, got %d", expected, result)
	}
}