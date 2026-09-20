package main

import (
	"flag"
	"fmt"
	"os"
	"runtime"
	"runtime/debug"
)

// Injected by GoReleaser via -ldflags "-X main.version=... -X main.commit=...".
var (
	version = "dev"
	commit  = ""
)

func main() {
	showVersion := flag.Bool("version", false, "print version and exit")
	flag.Parse()
	if *showVersion {
		printVersion()
		return
	}

	fmt.Printf("tool %s (%s/%s)\n", resolveVersion(), runtime.GOOS, runtime.GOARCH)
	fmt.Println("a minimal multi-arch release-engineering demo")
}

func printVersion() {
	v, c := resolveVersion(), resolveCommit()
	fmt.Printf("version=%s commit=%s\n", v, c)
}

func resolveVersion() string {
	if version != "" && version != "dev" {
		return version
	}
	if info, ok := debug.ReadBuildInfo(); ok && info.Main.Version != "" && info.Main.Version != "(devel)" {
		return info.Main.Version
	}
	return "dev"
}

func resolveCommit() string {
	if commit != "" {
		return commit
	}
	if info, ok := debug.ReadBuildInfo(); ok {
		for _, setting := range info.Settings {
			if setting.Key == "vcs.revision" && len(setting.Value) >= 7 {
				return setting.Value[:7]
			}
		}
	}
	return "unknown"
}

func init() {
	flag.CommandLine.SetOutput(os.Stdout)
}
