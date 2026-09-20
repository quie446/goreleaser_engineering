package version

import (
	"strings"
	"testing"
)

func TestStringContainsLdflagsValues(t *testing.T) {
	old := [4]string{Version, Commit, CommitDate, TreeState}
	Version = "v9.9.9"
	Commit = "0123456789ab"
	CommitDate = "2026-09-20T08:00:00Z"
	TreeState = "clean"
	t.Cleanup(func() {
		Version, Commit, CommitDate, TreeState = old[0], old[1], old[2], old[3]
	})

	got := String()
	for _, want := range []string{"v9.9.9", "0123456789ab", "2026-09-20T08:00:00Z", "clean"} {
		if !strings.Contains(got, want) {
			t.Fatalf("String() = %q, want it to contain %q", got, want)
		}
	}
}
