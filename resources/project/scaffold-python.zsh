project_name="myproject"
package_name="${project_name//-/_}"

mkdir -p "$project_name"/{src/$package_name,tests/{fixtures,},scripts,docs,data}
cd "$project_name" || exit

# Create placeholder files
touch README.md LICENSE .gitignore .env.example
touch pytest.ini mypy.ini .ruff.toml

# Code scaffold
touch src/$package_name/__init__.py
touch src/$package_name/core.py
mkdir -p src/$package_name/utils
touch src/$package_name/utils/{__init__.py,helpers.py}
touch src/$package_name/cli.py
touch tests/test_core.py
echo "# Documentation" > docs/index.md

# Create a uv-compatible pyproject.toml
cat <<EOF > pyproject.toml
[project]
name = "$project_name"
version = "0.1.0"
description = "Add your description here."
readme = "README.md"
requires-python = ">=3.14"
authors = [{ name = "First Last", email = "author@example.com" }]

dependencies = []

[project.scripts]
$project_name = "$package_name.cli:main"

[tool.uv]
# uv-specific settings can go here in future versions

[tool.pytest.ini_options]
testpaths = ["tests"]

[tool.ruff]
line-length = 88
target-version = "py313"

[tool.mypy]
strict = true
EOF

# Initialize uv environment
uv init --no-project 2>/dev/null || true

# Add dev tooling via uv
uv add --dev pytest ruff mypy

echo "uv-based Python project scaffold created at ./$project_name"
