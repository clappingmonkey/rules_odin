package hello

import "core:fmt"
import greetings "greetings:lib"

main :: proc() {
	fmt.println("Hellope, Odin from Bazel!")
	greetings.greet("Bazel")
}
