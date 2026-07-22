package hello

import "core:fmt"
import greetings "greetings:lib"

main :: proc() {
	fmt.println("Hellope, hermetic Odin from Bazel!")
	greetings.greet("Bazel")
}
