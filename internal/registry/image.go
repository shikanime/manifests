package registry

import (
	"fmt"
	"strings"
)

// ImageRef holds parsed components of an OCI image reference.
type ImageRef struct {
	Name   string
	Tag    string
	Digest string
}

func (i ImageRef) String() string {
	if i.Digest != "" {
		if i.Tag != "" {
			return fmt.Sprintf("%s:%s@%s", i.Name, i.Tag, i.Digest)
		}
		return fmt.Sprintf("%s@%s", i.Name, i.Digest)
	}
	if i.Tag != "" {
		return fmt.Sprintf("%s:%s", i.Name, i.Tag)
	}
	return i.Name
}

// ParseImageRef parses a Docker-style image reference string into ImageRef.
func ParseImageRef(ref string) (ImageRef, error) {
	info := ImageRef{}

	if idx := strings.Index(ref, "@"); idx != -1 {
		info.Digest = ref[idx+1:]
		ref = ref[:idx]
	}

	tagIdx := strings.LastIndex(ref, ":")
	slashIdx := strings.Index(ref, "/")
	if tagIdx > slashIdx {
		info.Tag = ref[tagIdx+1:]
		ref = ref[:tagIdx]
	} else {
		info.Tag = "latest"
	}

	if slashIdx == -1 {
		info.Name = "docker.io/library/" + ref
	} else {
		info.Name = ref
	}

	return info, nil
}
