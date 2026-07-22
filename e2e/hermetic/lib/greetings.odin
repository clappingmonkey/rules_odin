package greetings

import "core:fmt"

greet :: proc(name: string) {
	fmt.printf("Greetings from the hermetic library, %s!\n", name)
}
