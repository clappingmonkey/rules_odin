package failing_test

import "core:testing"

// This test MUST fail — it validates that odin_test propagates non-zero
// exit codes to Bazel's test infrastructure.
@(test)
test_intentional_failure :: proc(t: ^testing.T) {
	testing.expect_value(t, 1 + 1, 3)
}
