# Continuous integration

This folder holds the GitHub Actions workflow for the project: [`lint.yml`](lint.yml).

It runs on every push and pull request to `main` and does three things:

1. Runs `shellcheck` on every script in `scripts/`.
2. Runs `node --check` on the JavaScript samples and `python -m py_compile` on the Python sample.
3. Validates that `config/models.json` is well-formed JSON.

## Why it lives here instead of `.github/workflows/`

GitHub refuses to accept a push that adds or edits files under `.github/workflows/` unless the
credential doing the push has the `workflow` OAuth scope. The token used to create this repository
did not have that scope, so the workflow is parked here to keep the initial push clean.

## Enable it

1. Grant the scope once:

   ```bash
   gh auth refresh -h github.com -s workflow
   ```

2. Move the workflow into place and push:

   ```bash
   mkdir -p .github/workflows
   git mv ci/lint.yml .github/workflows/lint.yml
   git commit -m "Enable CI workflow"
   git push
   ```

GitHub Actions will pick it up automatically on the next push or pull request.
