---
name: build-and-push
description: "Build the {{SLUG}} Docker image and push to registry.towneygorm.cc/{{SLUG}}/app:<tag>. Use when cutting a release."
---

# Skill: build-and-push — {{SLUG}}

## When to use
Use after your code changes are committed and you're ready to cut a versioned release.

## Procedure

### 1 — Choose a release tag
```bash
RELEASE_TAG=v0.x.y         # semver — bump appropriately
GIT_SHA=$(git rev-parse --short HEAD)
```

### 2 — Login to private registry
```bash
docker login registry.towneygorm.cc -u registrybot
# Password: retrieve from Vaultwarden item homelab/registry
```

### 3 — Build the image
```bash
docker build -t registry.towneygorm.cc/{{SLUG}}/app:${RELEASE_TAG} .
```

### 4 — Tag with git SHA (traceability)
```bash
docker tag registry.towneygorm.cc/{{SLUG}}/app:${RELEASE_TAG} \
           registry.towneygorm.cc/{{SLUG}}/app:${GIT_SHA}
```

### 5 — Push both tags
```bash
docker push registry.towneygorm.cc/{{SLUG}}/app:${RELEASE_TAG}
docker push registry.towneygorm.cc/{{SLUG}}/app:${GIT_SHA}
```

### 6 — Git tag
```bash
git tag ${RELEASE_TAG}
git push origin ${RELEASE_TAG}
```

## Verify
- [ ] Both tags appear at https://registry-ui.towneygorm.cc
- [ ] `docker manifest inspect registry.towneygorm.cc/{{SLUG}}/app:${RELEASE_TAG}` succeeds

## After
Use `Skill(prod-deploy)` to deploy the new tag to the production compose stack.
