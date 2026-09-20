// Package version exposes build metadata injected at link time.
package version

import (
	"fmt"
	"runtime/debug"
)

// Values injected by goreleaser / -ldflags. They keep their defaults for a
// plain `go build`; in that case debug.ReadBuildInfo is used as a fallback.
var (
	Version    = "dev"
	Commit     = "none"
	CommitDate = "unknown"
	TreeState  = "unknown"
)

// String renders the build version string used by `reltool --version`.
func String() string {
	version := Version
	commit := Commit
	date := CommitDate
	treeState := TreeState

	if info, ok := debug.ReadBuildInfo(); ok {
		if version == "dev" || version == "" {
			version = "dev+" + shortSHA(buildSetting(info, "vcs.revision", "unknown"))
		}
		commit = prefer(commit, buildSetting(info, "vcs.revision", ""))
		date = prefer(date, buildSetting(info, "vcs.time", ""))
		if injected := buildSetting(info, "vcs.modified", ""); injected == "true" {
			treeState = prefer(treeState, "dirty")
		} else if injected == "false" {
			treeState = prefer(treeState, "clean")
		}
	}

	// goreleaser injects the full SHA; show the familiar 12-char prefix.
	commit = shortSHA(commit)

	return fmt.Sprintf("reltool version %s\ncommit: %s\ncommitDate: %s\ntreeState: %s",
		version, commit, date, treeState)
}

func prefer(current, fallback string) string {
	if current != "" && current != "none" && current != "unknown" {
		return current
	}
	return fallback
}

func buildSetting(info *debug.BuildInfo, key, def string) string {
	for _, setting := range info.Settings {
		if setting.Key == key && setting.Value != "" {
			return setting.Value
		}
	}
	return def
}

func shortSHA(sha string) string {
	if len(sha) > 12 {
		return sha[:12]
	}
	return sha
}
