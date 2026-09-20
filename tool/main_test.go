package main

import "testing"

func TestResolveVersionLDFlags(t *testing.T) {
	original := version
	version = "v1.2.3"
	t.Cleanup(func() { version = original })
	if got := resolveVersion(); got != "v1.2.3" {
		t.Fatalf("resolveVersion() = %q, want v1.2.3", got)
	}
}

func TestResolveCommitLDFlags(t *testing.T) {
	original := commit
	commit = "abc1234"
	t.Cleanup(func() { commit = original })
	if got := resolveCommit(); got != "abc1234" {
		t.Fatalf("resolveCommit() = %q, want abc1234", got)
	}
}

func TestResolveCommitShortFallback(t *testing.T) {
	original := commit
	commit = ""
	t.Cleanup(func() { commit = original })
	if got := resolveCommit(); got == "" {
		t.Fatal("resolveCommit() returned empty string")
	}
}
