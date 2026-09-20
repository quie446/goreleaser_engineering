// Command reltool is a minimal CLI used to demonstrate reproducible,
// multi-architecture release engineering with goreleaser.
package main

import (
	"fmt"
	"os"

	"example.com/reltool/internal/version"
)

func main() {
	if len(os.Args) > 1 && (os.Args[1] == "--version" || os.Args[1] == "-v" || os.Args[1] == "version") {
		fmt.Println(version.String())
		return
	}

	fmt.Println("reltool: a tiny demo binary")
	fmt.Println("run `reltool --version` to inspect build metadata")
}
