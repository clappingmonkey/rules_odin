package greetings

import "core:fmt"

greet :: proc(name: string) {
	fmt.printf("Greetings from the library, %s!\n", name)
}
