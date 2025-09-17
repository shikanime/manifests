#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# Check required environment variables
if [[ -z "${BUILD_CONTEXT:-}" ]] || [[ -z "${IMAGE:-}" ]]; then
    echo "Error: BUILD_CONTEXT and IMAGE environment variables are required"
    echo "Usage: BUILD_CONTEXT=<context> IMAGE=<image> [PLATFORMS=<platforms>] [PUSH_IMAGE=true] $0"
    exit 1
fi

# Configuration
PLATFORMS="${PLATFORMS:-linux/arm64}"
PUSH_IMAGE="${PUSH_IMAGE:-false}"
MANIFEST_IMAGES=""

echo "Building for platforms: $PLATFORMS"
echo "Target image: $IMAGE"
echo "Push enabled: $PUSH_IMAGE"

# Parse platforms and build images
IFS=',' read -ra PLATFORM_ARRAY <<< "$PLATFORMS"
for PLATFORM in "${PLATFORM_ARRAY[@]}"; do
    OS=${PLATFORM%/*}
    ARCH=${PLATFORM#*/}

    echo "Building for $PLATFORM..."

    # Load and tag Docker image
    docker load -i $(nix build "$BUILD_CONTEXT#syncthing-$OS-$ARCH" --print-out-paths)
    docker tag syncthing "$IMAGE-$ARCH"

    # Push if enabled
    if [[ "$PUSH_IMAGE" == "true" ]]; then
        echo "Pushing $IMAGE-$ARCH..."
        docker push "$IMAGE-$ARCH"
        MANIFEST_IMAGES="$MANIFEST_IMAGES $IMAGE-$ARCH"
    fi
done

# Create and push manifest if pushing is enabled
if [[ "$PUSH_IMAGE" == "true" ]] && [[ -n "$MANIFEST_IMAGES" ]]; then
    echo "Creating manifest for $IMAGE..."

    # Remove existing manifest to avoid conflicts
    docker manifest rm "$IMAGE" 2>/dev/null || true

    # Create and push new manifest
    docker manifest create "$IMAGE" $MANIFEST_IMAGES
    docker manifest push "$IMAGE"

    echo "Manifest pushed successfully"
fi

echo "Build completed successfully"