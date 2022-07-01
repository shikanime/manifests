.PHONY: all
all: fetch

.PHONY: fetch
fetch: vcpkg/vcpkg

vcpkg/vcpkg:
	sh vcpkg/bootstrap-vcpkg.sh --disableMetrics
