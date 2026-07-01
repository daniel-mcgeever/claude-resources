# Environment & secrets — never commit
.env
.env.local
.env.*.local
.forgejo-token

# Python
__pycache__/
*.py[cod]
*$py.class
*.egg-info/
dist/
build/
.venv/
venv/
env/
.pytest_cache/
.mypy_cache/
.ruff_cache/
htmlcov/
.coverage

# Node
node_modules/
dist/
.next/
.nuxt/
out/
.cache/
*.tsbuildinfo

# Go
bin/
*.exe
*.exe~
*.dll
*.so
*.dylib
coverage.out

# Docker
.dockerignore

# OS
.DS_Store
.DS_Store?
._*
Thumbs.db
ehthumbs.db

# Editor
.vscode/settings.json
.vscode/*.code-workspace
.idea/
*.swp
*.swo
*~

# Logs
*.log
logs/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Temporary
tmp/
temp/
*.tmp
