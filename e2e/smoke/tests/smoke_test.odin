package tests

import "core:testing"
import greetings "greetings:lib"

@(test)
test_greet_returns :: proc(t: ^testing.T) {
	// Verify the greetings library is importable and callable.
	// greet() writes to stdout — here we just confirm no crash.
	greetings.greet("Test")
}

@(test)
test_arithmetic :: proc(t: ^testing.T) {
	testing.expect_value(t, 2 + 2, 4)
	testing.expect_value(t, 10 - 3, 7)
	testing.expect_value(t, 6 * 7, 42)
}

@(test)
test_string_length :: proc(t: ^testing.T) {
	s := "hello"
	testing.expect_value(t, len(s), 5)
}
