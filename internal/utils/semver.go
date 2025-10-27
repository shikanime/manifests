package utils

import (
	"fmt"
	"regexp"
	"strings"

	"golang.org/x/mod/semver"
)

// ParseSemver extracts and validates a semver string from tag using named groups.
// It returns the canonical semver (with leading 'v') or an error if parsing fails.
func ParseSemver(re *regexp.Regexp, tag string) (string, error) {
	m := re.FindStringSubmatch(tag)
	if m == nil {
		return "", fmt.Errorf("no semver match in tag %q", tag)
	}

	versionIdx := re.SubexpIndex("version")
	majorIdx := re.SubexpIndex("major")
	minorIdx := re.SubexpIndex("minor")
	patchIdx := re.SubexpIndex("patch")
	prereleaseIdx := re.SubexpIndex("prerelease")
	buildIdx := re.SubexpIndex("build")

	vers := ""
	if versionIdx >= 0 && versionIdx < len(m) && m[versionIdx] != "" {
		vers = m[versionIdx]
	} else if majorIdx >= 0 && minorIdx >= 0 && patchIdx >= 0 &&
		majorIdx < len(m) && minorIdx < len(m) && patchIdx < len(m) &&
		m[majorIdx] != "" && m[minorIdx] != "" && m[patchIdx] != "" {
		vers = m[majorIdx] + "." + m[minorIdx] + "." + m[patchIdx]
		if prereleaseIdx >= 0 && prereleaseIdx < len(m) && m[prereleaseIdx] != "" {
			vers += "-" + m[prereleaseIdx]
		}
		if buildIdx >= 0 && buildIdx < len(m) && m[buildIdx] != "" {
			vers += "+" + m[buildIdx]
		}
	} else {
		return "", fmt.Errorf("no version groups matched in tag %q", tag)
	}

	// Normalize to semver with leading 'v' (required by golang.org/x/mod/semver)
	if strings.HasPrefix(vers, "V") {
		vers = "v" + vers[1:]
	} else if !strings.HasPrefix(vers, "v") {
		vers = "v" + vers
	}

	semvers := semver.Canonical(vers)
	if semvers == "" {
		return "", fmt.Errorf("invalid semver %q", vers)
	}

	return semvers, nil
}
