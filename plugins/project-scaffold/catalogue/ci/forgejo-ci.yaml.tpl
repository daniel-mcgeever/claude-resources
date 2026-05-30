# Forgejo Actions CI — {{SLUG}}
# ─────────────────────────────────────────────────────────────
# Triggered automatically on every push by the vm-160 runner
# (labels: homelab, docker). No manual configuration needed.
#
# Jobs:
#   test          — builds image, runs tests, runs on all branches
#   push-on-main  — builds and pushes to registry on main-branch push
#                   (requires REGISTRY_PASSWORD secret in repo settings)
# ─────────────────────────────────────────────────────────────

name: CI

on:
  push:
    branches: ["**"]
    tags: ["v*"]      # release tag push triggers the build → tagged registry artifact
  pull_request:
    branches: [main]

jobs:
  test:
    name: Build and test
    runs-on: homelab
    container:
      # catthehacker/ubuntu:act-latest — standard nektos/act runtime with
      # node (needed by actions/checkout), docker CLI, git, jq, etc.
      # Runner config mounts /var/run/docker.sock into this container
      # (docker_host: "automount"), so `docker build` talks to the host
      # docker daemon. Same image cache as the runner and registry pulls.
      image: catthehacker/ubuntu:act-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build CI image
        run: docker build -t {{SLUG}}-ci:${GITHUB_SHA::8} .

      - name: Run tests
        run: |
          # TODO: replace the echo with your actual test command, e.g.:
          #   docker run --rm {{SLUG}}-ci:${GITHUB_SHA::8} pytest
          #   docker run --rm {{SLUG}}-ci:${GITHUB_SHA::8} npm test
          #   docker run --rm {{SLUG}}-ci:${GITHUB_SHA::8} go test ./...
          docker run --rm {{SLUG}}-ci:${GITHUB_SHA::8} echo "⚠ replace this with your test command"

      - name: Cleanup
        if: always()
        run: docker rmi {{SLUG}}-ci:${GITHUB_SHA::8} --force || true

  push-on-main:
    name: Push image to registry
    runs-on: homelab
    needs: [test]
    if: ${{ github.ref == 'refs/heads/main' && github.event_name == 'push' }}
    container:
      # catthehacker/ubuntu:act-latest — standard nektos/act runtime with
      # node (needed by actions/checkout), docker CLI, git, jq, etc.
      # Runner config mounts /var/run/docker.sock into this container
      # (docker_host: "automount"), so `docker build` talks to the host
      # docker daemon. Same image cache as the runner and registry pulls.
      image: catthehacker/ubuntu:act-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Login to private registry
        run: |
          echo "${{ secrets.REGISTRY_PASSWORD }}" | \
            docker login registry.towneygorm.cc -u registrybot --password-stdin

      - name: Resolve release tag
        id: tag
        run: |
          TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "dev-$(git rev-parse --short HEAD)")
          echo "tag=${TAG}" >> $GITHUB_OUTPUT

      - name: Build and push
        run: |
          IMAGE=registry.towneygorm.cc/{{SLUG}}/app
          TAG=${{ steps.tag.outputs.tag }}
          docker build -t "${IMAGE}:${TAG}" .
          docker push "${IMAGE}:${TAG}"
          echo "✅ Pushed ${IMAGE}:${TAG}"

      - name: Cleanup
        if: always()
        run: docker logout registry.towneygorm.cc || true
