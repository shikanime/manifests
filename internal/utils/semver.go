package utils

import (
	"fmt"
	"regexp"
	"strings"

	"golang.org/x/mod/semver"
)

// ParseSemver parses a tag into canonical semver (with leading 'v') or returns an error.
func ParseSemver(v string) (string, error) {
	canon := semver.Canonical(NormalizeSemverPrefix(v))
	if canon == "" {
		return "", fmt.Errorf("invalid semver %q", v)
	}
	return canon, nil
}

// Major returns the major version of a semver string.
func Major(tag string) (string, error) {
	c, err := ParseSemver(tag)
	if err != nil || c == "" {
		return "", err
	}
	return semver.Major(c), nil
}

// MajorMinor returns the major.minor version of a semver string.
func MajorMinor(tag string) (string, error) {
	c, err := ParseSemver(tag)
	if err != nil || c == "" {
		return "", err
	}
	return semver.MajorMinor(c), nil
}

// Compare compares two semver strings.
func Compare(a, b string) int {
	return semver.Compare(a, b)
}

// ParseSemverWithRegex extracts a semver from tag using named capture groups,
// then canonicalizes it by reusing ParseSemver.
func ParseSemverWithRegex(re *regexp.Regexp, v string) (string, error) {
	m := re.FindStringSubmatch(v)
	if m == nil {
		return "", fmt.Errorf("no semver match in tag %q", v)
	}

	versionIdx := re.SubexpIndex("version")
	majorIdx := re.SubexpIndex("major")
	minorIdx := re.SubexpIndex("minor")
	patchIdx := re.SubexpIndex("patch")
	prereleaseIdx := re.SubexpIndex("prerelease")
	buildIdx := re.SubexpIndex("build")

	matchedVersion := ""
	if versionIdx >= 0 && versionIdx < len(m) && m[versionIdx] != "" {
		matchedVersion = m[versionIdx]
	} else if majorIdx >= 0 && minorIdx >= 0 && patchIdx >= 0 &&
		majorIdx < len(m) && minorIdx < len(m) && patchIdx < len(m) &&
		m[majorIdx] != "" && m[minorIdx] != "" && m[patchIdx] != "" {
		matchedVersion = m[majorIdx] + "." + m[minorIdx] + "." + m[patchIdx]
		if prereleaseIdx >= 0 && prereleaseIdx < len(m) && m[prereleaseIdx] != "" {
			matchedVersion += "-" + m[prereleaseIdx]
		}
		if buildIdx >= 0 && buildIdx < len(m) && m[buildIdx] != "" {
			matchedVersion += "+" + m[buildIdx]
		}
	} else {
		return "", fmt.Errorf("no version groups matched in tag %q", v)
	}

	canon, err := ParseSemver(matchedVersion)
	if err != nil {
		return "", err
	}
	return canon, nil
}

// NormalizeSemverPrefix normalizes a tag to have a leading 'v' and no 'V' prefix.
func NormalizeSemverPrefix(tag string) string {
	if strings.HasPrefix(tag, "V") {
		return "v" + tag[1:]
	}
	if !strings.HasPrefix(tag, "v") {
		return "v" + tag
	}
	return tag
}
