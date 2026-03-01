# Phase 143: Deploy Everything Including New Stuff from v14 - Research

**Researched:** 2026-03-01
**Domain:** Multi-service deployment — Fly.io (Axum registry), Cloudflare R2 (object storage), Cloudflare Pages (SvelteKit packages site), GitHub Actions (binary distribution), GitHub Pages (docs site)
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Registry infrastructure**
- Platform: Fly.io (managed cloud)
- Database: Fly Postgres (managed Fly app, same Fly network as backend)
- Storage: Cloudflare R2 bucket — needs to be created fresh as part of this deployment (does not exist yet)
- Registry API domain: `api.packages.meshlang.dev` pointing to Fly.io deployment

**meshpkg binary distribution**
- Distribution method: Bundle meshpkg into the existing meshc install script (`install.sh`) — one script installs both tools
- Target platforms: macOS arm64, macOS x86_64, Linux x86_64, Linux arm64 (same 4 targets as meshc)
- Release automation: GitHub Actions CI triggered on version tag push — extend the existing `release.yml` workflow which already handles all 4 targets for meshc
- No Windows builds for meshpkg (Windows not in the requested targets)

**Packages website**
- Framework: SvelteKit (separate app, not VitePress)
- Domain: `packages.meshlang.dev`
- Purpose: Dynamic package browsing, search, and per-package pages with live data from the registry API
- Note: Phase 140 built VitePress package pages integrated into `meshlang.dev/packages/` — this phase ships a proper SvelteKit app at the dedicated subdomain instead
- Hosting platform for SvelteKit: Claude's Discretion (Vercel/Netlify/Cloudflare Pages all viable)

**Docs site**
- Trigger a fresh GitHub Pages deploy via `deploy.yml` to ensure all v14 docs (phases 141–142 changes) are live on `meshlang.dev`
- No new content changes — this is a deployment confirmation step

**Deployment sequencing**
1. Provision Fly.io app + Fly Postgres + Cloudflare R2 bucket + DNS entries
2. Deploy registry backend to Fly.io (run migrations, verify API responds)
3. Build and deploy SvelteKit packages site to static host
4. Trigger GitHub Pages deploy for docs site
5. Update `install.sh` to bundle meshpkg + extend `release.yml` for meshpkg binaries
6. Tag a release to trigger CI and publish meshpkg + meshc binaries

**Mesher**
- Explicitly excluded from this deployment phase — mesher is a test project that validates the Mesh language, not a production service

**Success criteria**
- Services live + smoke test: registry API at `api.packages.meshlang.dev` responds, packages site at `packages.meshlang.dev` loads, `meshpkg publish` and `meshpkg install` work end-to-end against production

### Claude's Discretion
- SvelteKit hosting platform choice (Vercel, Netlify, or Cloudflare Pages)
- Specific Fly.io region selection for registry
- fly.toml configuration details
- R2 bucket naming
- SvelteKit app design/UI (fetch from registry API, no predefined design system required)

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed within phase scope
</user_constraints>

---

## Summary

Phase 143 is a pure deployment/infrastructure phase — no new compiler features, no new application logic. All code (the Axum registry backend, meshpkg CLI, VitePress docs site) was completed in phases 139–142. This phase provisions cloud infrastructure, deploys the services, and wires up distribution.

The work divides into five independent tracks that converge in step 6 (the tag-triggered release): (1) Fly.io infrastructure — provision app, Fly Postgres, set secrets, deploy registry; (2) Cloudflare R2 — create bucket, generate S3 API credentials, configure them as Fly secrets; (3) Cloudflare Pages (recommended) or alternative host — scaffold SvelteKit app, connect to registry API, deploy; (4) GitHub Pages docs trigger — a single `workflow_dispatch` call; (5) GitHub Actions + install.sh — extend `release.yml` matrix to include `meshpkg`, update `install.sh` to download and install it alongside `meshc`.

The biggest complexity is the registry environment configuration: seven secrets must be set on Fly.io before first deploy (`DATABASE_URL` is auto-set by `fly postgres attach`, but the six R2 + OAuth + session secrets must be set manually). Getting these right before the first `fly deploy` avoids a failed cold start.

**Primary recommendation:** Provision R2 bucket and generate its API credentials first (they are needed for Fly secrets), then set all Fly secrets in one batch, then deploy — this ordering avoids any partial-start failures.

---

## Standard Stack

### Core Infrastructure Tools

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| flyctl | latest | Fly.io CLI — provision, deploy, secrets | Official Fly.io CLI, required for all Fly operations |
| wrangler | 4.x | Cloudflare CLI — R2 bucket creation, Pages deploy | Official Cloudflare Workers/Pages CLI |
| gh | latest | GitHub CLI — trigger workflow_dispatch, monitor CI | Already used in project, standard GH operations |

### Registry Backend Stack (already built — Phase 140)

| Component | Tech | Notes |
|-----------|------|-------|
| Web framework | Axum 0.8 | Already in `registry/Cargo.toml` |
| Database | PostgreSQL via sqlx 0.8 | Runs on Fly Postgres |
| Object storage | Cloudflare R2 via aws-sdk-s3 1.x | S3-compatible, endpoint = `https://<ACCOUNT_ID>.r2.cloudflarestorage.com` |
| Auth | GitHub OAuth + tower-sessions | Secrets: `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET`, `GITHUB_CALLBACK_URL` |
| Session secret | Any 32+ byte random string | `SESSION_SECRET` env var |

### Packages Website Stack (to be built this phase)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| SvelteKit | 2.x | Full-stack framework (locked decision) | Framework chosen in CONTEXT.md |
| @sveltejs/adapter-cloudflare | 4.x | Cloudflare Pages adapter | Recommended for CF Pages SSR |
| Svelte | 5.x | Component framework | Ships with SvelteKit 2.x |

**Installation (new SvelteKit app):**
```bash
npm create svelte@latest packages-website
cd packages-website
npm install
npm install -D @sveltejs/adapter-cloudflare
```

### Supporting Tools

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| cargo-chef | latest | Docker layer caching for Rust builds | Used in Fly.io Dockerfile (auto-generated by fly launch) |
| softprops/action-gh-release@v2 | v2 | Upload release artifacts | Already in existing release.yml |

---

## Architecture Patterns

### Recommended Project Structure (New Files This Phase)

```
mesh/
├── registry/
│   ├── Dockerfile           # NEW — multi-stage Rust build for Fly.io
│   └── fly.toml             # NEW — Fly.io app configuration
├── packages-website/        # NEW — SvelteKit app at packages.meshlang.dev
│   ├── src/
│   │   └── routes/
│   │       ├── +page.svelte          # Home: recent packages
│   │       ├── +page.server.js       # Fetch from registry API
│   │       ├── search/
│   │       │   └── +page.svelte      # Search results
│   │       └── packages/
│   │           └── [name]/
│   │               └── +page.svelte  # Per-package page
│   ├── svelte.config.js              # adapter-cloudflare
│   └── wrangler.jsonc                # CF Pages config
├── tools/
│   └── install/
│       └── install.sh       # MODIFIED — add meshpkg installation
└── .github/
    └── workflows/
        └── release.yml      # MODIFIED — add meshpkg build matrix entries
```

### Pattern 1: Fly.io Axum Registry Deployment

**What:** Multi-stage Docker build via cargo-chef, deployed to Fly.io with Postgres attached.
**When to use:** Deploying the registry backend.

```dockerfile
# Source: https://fly.io/docs/rust/the-basics/cargo-chef/
FROM lukemathwalker/cargo-chef:latest-rust-1 AS chef
WORKDIR /app

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY . .
RUN cargo build --release --bin mesh-registry

FROM debian:bookworm-slim AS runtime
WORKDIR /app
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/mesh-registry /usr/local/bin/
EXPOSE 3000
ENTRYPOINT ["/usr/local/bin/mesh-registry"]
```

**fly.toml:**
```toml
app = "mesh-registry"
primary_region = "iad"   # US East — Claude's discretion on region

[http_service]
  internal_port = 3000
  force_https = true
  auto_stop_machines = false  # Registry should be always-on
  min_machines_running = 1

[build]
  dockerfile = "Dockerfile"
```

**Provisioning commands:**
```bash
# From the registry/ directory
fly launch --name mesh-registry --no-deploy
fly postgres create --name mesh-registry-db --region iad
fly postgres attach mesh-registry-db --app mesh-registry
# DATABASE_URL is now auto-set as a Fly secret
```

### Pattern 2: Fly.io Secret Configuration

**What:** All required env vars for the registry backend set as Fly secrets.
**When to use:** Before first `fly deploy` — missing secrets cause cold-start panics.

```bash
# Source: https://fly.io/docs/flyctl/secrets-set/
# R2 storage credentials
fly secrets set \
  STORAGE_ENDPOINT="https://<ACCOUNT_ID>.r2.cloudflarestorage.com" \
  STORAGE_BUCKET="mesh-packages" \
  STORAGE_ACCESS_KEY_ID="<r2_access_key_id>" \
  STORAGE_SECRET_ACCESS_KEY="<r2_secret_access_key>" \
  STORAGE_REGION="auto" \
  GITHUB_CLIENT_ID="<github_oauth_app_client_id>" \
  GITHUB_CLIENT_SECRET="<github_oauth_app_client_secret>" \
  GITHUB_CALLBACK_URL="https://api.packages.meshlang.dev/auth/callback" \
  SESSION_SECRET="<random_64_hex_chars>" \
  --app mesh-registry
# DATABASE_URL was set automatically by fly postgres attach
```

### Pattern 3: Cloudflare R2 Bucket Creation

**What:** Create R2 bucket via wrangler and generate S3-compatible API credentials via dashboard.
**When to use:** Before setting Fly secrets — credentials are needed first.

```bash
# Source: https://developers.cloudflare.com/r2/buckets/create-buckets/
# Step 1: Create the bucket
npx wrangler r2 bucket create mesh-packages

# Step 2: Verify
npx wrangler r2 bucket list
```

S3 endpoint format: `https://<ACCOUNT_ID>.r2.cloudflarestorage.com`
API credentials generated via: Cloudflare Dashboard → R2 Object Storage → Manage R2 API tokens

### Pattern 4: GitHub Actions — Extending release.yml for meshpkg

**What:** Add meshpkg build targets to the existing matrix. meshpkg is in the same Cargo workspace, builds without LLVM (pure Rust, no compiler dependencies), and can reuse the same runner VMs.
**Key insight:** meshpkg does NOT need LLVM since it is a CLI tool with no LLVM dependency — its build is much simpler than meshc.

```yaml
# Extend the existing matrix in release.yml
# Add these 4 entries AFTER the existing meshc entries:
- target: x86_64-apple-darwin
  os: macos-15-intel
  binary: meshpkg
  archive_ext: tar.gz
- target: aarch64-apple-darwin
  os: macos-14
  binary: meshpkg
  archive_ext: tar.gz
- target: x86_64-unknown-linux-gnu
  os: ubuntu-24.04
  binary: meshpkg
  archive_ext: tar.gz
- target: aarch64-unknown-linux-gnu
  os: ubuntu-24.04-arm
  binary: meshpkg
  archive_ext: tar.gz
```

**Simpler approach:** Keep meshpkg in its own separate job within `release.yml` — no LLVM needed, just `cargo build --release -p meshpkg --target ${{ matrix.target }}`. This avoids complicating the existing LLVM-heavy meshc matrix.

**Build step for meshpkg:**
```yaml
- name: Build meshpkg
  run: cargo build --release -p meshpkg --target ${{ matrix.target }}

- name: Package meshpkg (tar.gz)
  run: |
    tar czf "meshpkg-v${{ steps.version.outputs.version }}-${{ matrix.target }}.tar.gz" \
      -C "target/${{ matrix.target }}/release" meshpkg
```

### Pattern 5: install.sh — Adding meshpkg Installation

**What:** Extend the existing install.sh to download and install meshpkg alongside meshc.
**Current behavior:** Downloads `meshc-v{version}-{platform}.tar.gz` from GitHub releases, extracts to `~/.mesh/bin/meshc`.
**Change needed:** After installing meshc, also download `meshpkg-v{version}-{platform}.tar.gz` and install to `~/.mesh/bin/meshpkg`.

The install function already has all platform detection, download, checksum verification, and extraction logic. The simplest approach is a second install call within `main()` after meshc succeeds.

### Pattern 6: SvelteKit Packages Website

**What:** SSR SvelteKit app deployed to Cloudflare Pages, fetching live data from `https://api.packages.meshlang.dev`.
**Routes needed:**
- `/` — Homepage with recent packages (fetched via `+page.server.js` from `GET /api/v1/packages`)
- `/search?q=...` — Search results (fetched from `GET /api/v1/packages?q=...`)
- `/packages/[name]` — Per-package page (fetched from `GET /api/v1/packages/{name}`)

```javascript
// Source: https://svelte.dev/docs/kit/routing
// src/routes/+page.server.js
export async function load({ fetch }) {
  const res = await fetch('https://api.packages.meshlang.dev/api/v1/packages');
  const data = await res.json();
  return { packages: data };
}
```

```javascript
// svelte.config.js
import adapter from '@sveltejs/adapter-cloudflare';
export default {
  kit: {
    adapter: adapter()
  }
};
```

```jsonc
// wrangler.jsonc
{
  "name": "mesh-packages",
  "pages_build_output_dir": ".svelte-kit/cloudflare",
  "compatibility_flags": ["nodejs_compat"],
  "compatibility_date": "2026-01-01"
}
```

**Deploy to Cloudflare Pages:**
- Connect GitHub repo via CF Pages dashboard → Workers & Pages → Create application → Pages → Import Git repo
- Build command: `npm run build`
- Build output directory: `.svelte-kit/cloudflare`
- Set custom domain: `packages.meshlang.dev` in CF Pages settings

### Pattern 7: DNS Configuration

**What:** Two DNS records needed for the two new subdomains.

| Subdomain | Type | Target | Notes |
|-----------|------|--------|-------|
| `api.packages.meshlang.dev` | CNAME | `mesh-registry.fly.dev` | Fly.io custom domain |
| `packages.meshlang.dev` | CNAME | auto-assigned by CF Pages | Set in CF Pages custom domain |

For Fly.io custom domain, run:
```bash
fly certs add api.packages.meshlang.dev --app mesh-registry
```
Fly will provide the CNAME target to add to DNS.

### Anti-Patterns to Avoid

- **Deploying before all secrets are set:** The registry startup panics via `from_env()` if any required env var is missing. Set ALL secrets before first `fly deploy`.
- **Using `force_path_style(true)` issue:** Already set in `registry/src/storage/r2.rs` — this is correct and required for R2 compatibility.
- **Deploying registry/ with `fly launch` from workspace root:** The registry has its own `Cargo.toml` workspace root (separate from the main workspace to avoid sqlite link conflict). Run `fly launch` from inside `registry/`.
- **SvelteKit SSR calling registry API from server without CORS:** The CORS layer in the registry is `CorsLayer::permissive()` in production — this should be tightened to `meshlang.dev` and `packages.meshlang.dev` for production. The SvelteKit `+page.server.js` calls happen server-side (from Cloudflare Workers edge), not from browser, so CORS is not an issue for SSR routes, but browser-side fetch (if any CSR routes exist) requires CORS headers.
- **Packaging meshpkg in the same tar.gz as meshc:** They are separate binaries, separate tarballs, separate download URLs. install.sh downloads two tarballs.
- **Using musl/alpine for meshpkg:** meshpkg does not need a statically-linked build (it only uses ureq with TLS + dirs + common crates). Use glibc (ubuntu-24.04) for Linux builds.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Docker Rust build caching | Custom layer ordering | cargo-chef pattern (or fly launch auto-generates) | Handles Cargo.lock + Cargo.toml caching correctly |
| TLS cert provisioning | Manual cert management | `fly certs add` | Fly handles Let's Encrypt automatically |
| CF Pages build pipeline | Custom CI deploy | CF Pages Git integration | Auto-deploys on push, preview deployments free |
| R2 bucket CORS | Custom proxy | R2 dashboard CORS settings or CorsLayer in registry | Registry already has permissive CORS, tighten in fly secrets or code |
| SHA256SUMS generation | Manual | Existing `sha256sum` step in release.yml | Already in place — meshpkg artifacts just need to be added to the same SHA256SUMS step |

**Key insight:** The existing release.yml already handles artifact staging, SHA256SUMS generation, and GitHub Release creation. meshpkg needs only new build jobs that output correctly named tarballs — the release job picks them up automatically via `merge-multiple: true`.

---

## Common Pitfalls

### Pitfall 1: Registry docker build context from wrong directory

**What goes wrong:** Running `fly deploy` from the workspace root includes the entire 1GB+ target/ directory in the Docker build context, causing timeouts or enormous image sizes.
**Why it happens:** `fly deploy` uses CWD as the build context unless told otherwise.
**How to avoid:** Always run `fly launch` and `fly deploy` from inside the `registry/` subdirectory, OR add a `.dockerignore` file in `registry/` that excludes `target/`.
**Warning signs:** `fly deploy` upload step shows hundreds of MB being uploaded.

### Pitfall 2: .dockerignore is required

**What goes wrong:** `target/` directory (~hundreds of MB) gets sent to the Fly remote builder, making builds very slow.
**Why it happens:** No `.dockerignore` in `registry/` yet.
**How to avoid:** Create `registry/.dockerignore` with at minimum:
```
target/
```

### Pitfall 3: GitHub OAuth callback URL mismatch

**What goes wrong:** OAuth login fails after deploy with "redirect_uri_mismatch" from GitHub.
**Why it happens:** The GitHub OAuth App registered in GitHub settings has a specific callback URL. If `GITHUB_CALLBACK_URL` secret doesn't exactly match, GitHub rejects it.
**How to avoid:** Create (or update) the GitHub OAuth App for production with callback URL `https://api.packages.meshlang.dev/auth/callback` before deploying. Set `GITHUB_CALLBACK_URL` to this exact value.

### Pitfall 4: meshpkg build fails in release.yml on LLVM matrix

**What goes wrong:** Adding meshpkg to the existing LLVM-heavy matrix means paying the full LLVM install cost for a binary that doesn't need LLVM.
**Why it happens:** meshpkg depends on zero LLVM-using crates.
**How to avoid:** Add meshpkg as a SEPARATE parallel job in `release.yml` with its own simple 4-target matrix — no LLVM installation steps required.

### Pitfall 5: install.sh version mismatch between meshc and meshpkg

**What goes wrong:** Users install meshc v1.0 but meshpkg v0.9 (or vice versa) because releases are not co-tagged.
**Why it happens:** If meshpkg has a separate version than meshc, the install script needs to handle independent version lookup.
**How to avoid:** Tag releases as `v{semver}` for the whole monorepo — both meshc and meshpkg share the same release tag. Both are built from the same git tag. install.sh uses a single version for both.

### Pitfall 6: SvelteKit CORS on client-side fetches

**What goes wrong:** Browser-side navigations to `/packages/[name]` fail because the fetch to `api.packages.meshlang.dev` hits CORS.
**Why it happens:** `+page.svelte` client-side fetch is treated as a cross-origin browser request.
**How to avoid:** Use `+page.server.js` for all registry API calls (runs server-side on CF Workers edge, no CORS). If CSR navigation needs data, use `+page.server.js` load functions — not `onMount(() => fetch(...))`. CorsLayer in the registry should allow `packages.meshlang.dev` origin.

### Pitfall 7: R2 `STORAGE_REGION` must be "auto"

**What goes wrong:** Setting `STORAGE_REGION` to a real AWS region string causes the AWS SDK to route to the wrong endpoint.
**Why it happens:** R2 uses `"auto"` as a sentinel — not a real AWS region.
**How to avoid:** Always set `STORAGE_REGION=auto` for R2. Already defaulted to `"auto"` in `AppConfig::from_env()`.

### Pitfall 8: Fly Postgres `with_secure(false)` in session layer

**What goes wrong:** Session cookies are sent over HTTP when `with_secure(false)` is set in main.rs.
**Why it happens:** `registry/src/main.rs` has `with_secure(false)` (flagged as TODO). Production deployment on Fly.io uses HTTPS via `force_https = true` in fly.toml.
**How to avoid:** Change `with_secure(false)` to `with_secure(true)` before production deploy since Fly.io provides HTTPS termination.

---

## Code Examples

### R2 Environment Variables for Fly Secrets

```bash
# Source: https://developers.cloudflare.com/r2/api/tokens/
# Required env vars for registry/src/config.rs AppConfig::from_env()
fly secrets set \
  STORAGE_ENDPOINT="https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com" \
  STORAGE_BUCKET="mesh-packages" \
  STORAGE_ACCESS_KEY_ID="<access_key_id_from_r2_dashboard>" \
  STORAGE_SECRET_ACCESS_KEY="<secret_access_key_from_r2_dashboard>" \
  STORAGE_REGION="auto" \
  GITHUB_CLIENT_ID="<oauth_app_client_id>" \
  GITHUB_CLIENT_SECRET="<oauth_app_client_secret>" \
  GITHUB_CALLBACK_URL="https://api.packages.meshlang.dev/auth/callback" \
  SESSION_SECRET="$(openssl rand -hex 32)" \
  --app mesh-registry
```

### Verify Registry API After Deploy

```bash
# Smoke test: registry list endpoint
curl -s https://api.packages.meshlang.dev/api/v1/packages | head -c 200

# Smoke test: registry search
curl -s "https://api.packages.meshlang.dev/api/v1/packages?q=test"
```

### Trigger GitHub Pages Deploy

```bash
# Source: .github/workflows/deploy.yml has workflow_dispatch trigger
gh workflow run deploy.yml --repo mesh-lang/mesh
# Monitor
gh run list --workflow deploy.yml --repo mesh-lang/mesh --limit 3
```

### Tag Release to Trigger meshc + meshpkg CI

```bash
git tag v14.0.0
git push origin v14.0.0
# Monitor build matrix
gh run list --workflow release.yml --repo mesh-lang/mesh --limit 3
```

### meshpkg End-to-End Smoke Test

```bash
# After release is published, test install and publish flow
# Test install
sh <(curl -sSf https://meshlang.dev/install.sh)
meshpkg --version

# Test publish against production
cd /tmp && mkdir test-pkg && cd test-pkg
cat > mesh.toml <<'EOF'
[package]
name = "smoke-test-pkg"
version = "0.1.0"
description = "Deploy smoke test"
license = "MIT"
EOF
meshpkg login --token <token>
meshpkg publish  # Should succeed and echo package URL
meshpkg search smoke-test  # Should return the package
meshpkg install smoke-test-pkg  # Should download and extract
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Manual Dockerfile authoring for Rust | cargo-chef multi-stage (auto-generated by `fly launch`) | Fly.io Rust scanner added 2023+ | First build ~5min, subsequent builds ~1min with dependency caching |
| Fly Postgres as "unmanaged" with full support | Managed Postgres (`fly mpg`) available as alternative | 2024+ | Managed is better for production; unmanaged is fine for small apps, just no Fly support |
| Separate install scripts per tool | Single install.sh installs both meshc + meshpkg | This phase | Simpler user onboarding |
| VitePress package pages at meshlang.dev/packages/ | Dedicated SvelteKit app at packages.meshlang.dev | This phase (Phase 140 built the VitePress version) | Dynamic data, proper search, per-package pages |

---

## Open Questions

1. **GitHub OAuth App: new app or update existing?**
   - What we know: The registry needs a GitHub OAuth App with `api.packages.meshlang.dev/auth/callback` as the callback.
   - What's unclear: Whether a GitHub OAuth App already exists for this. If one was created during Phase 140 local dev with `localhost` callback, it needs updating or a new production OAuth App is needed.
   - Recommendation: Create a new GitHub OAuth App specifically for production named "Mesh Registry" with homepage `https://packages.meshlang.dev` and callback `https://api.packages.meshlang.dev/auth/callback`.

2. **Fly.io region selection**
   - What we know: Region is Claude's discretion.
   - What's unclear: Where the primary maintainer/user base is.
   - Recommendation: Use `iad` (Ashburn, US East) as the default — good latency for US, acceptable for EU, Fly's largest region with most VM inventory.

3. **SvelteKit packages site: how much UI to build?**
   - What we know: "No predefined design system required" — Claude's discretion.
   - What's unclear: How polished the UI needs to be for the v14.0 launch.
   - Recommendation: Minimal functional UI — homepage listing packages by recency, search page, per-package page showing name/description/versions/install command. Tailwind CSS is available via the SvelteKit skeleton setup but a plain HTML/CSS approach is also fine.

4. **meshpkg default registry URL**
   - What we know: `compiler/meshpkg/src/main.rs` line 12 has `DEFAULT_REGISTRY = "https://registry.meshlang.dev"`.
   - What's unclear: The locked domain is `api.packages.meshlang.dev`, but the meshpkg binary has `registry.meshlang.dev` hardcoded.
   - Recommendation: Before tagging the release, update `DEFAULT_REGISTRY` to `"https://api.packages.meshlang.dev"` OR ensure `registry.meshlang.dev` is also a CNAME alias. This is a critical pre-release step.

---

## Sources

### Primary (HIGH confidence)
- Fly.io Official Axum Docs — https://fly.io/docs/rust/frameworks/axum/
- Fly.io Cargo Chef Docs — https://fly.io/docs/rust/the-basics/cargo-chef/
- Fly.io Secrets Docs — https://fly.io/docs/flyctl/secrets-set/
- Fly.io Postgres Attach Docs — https://fly.io/docs/postgres/managing/attach-detach/
- Cloudflare R2 Create Buckets — https://developers.cloudflare.com/r2/buckets/create-buckets/
- Cloudflare R2 Authentication/Tokens — https://developers.cloudflare.com/r2/api/tokens/
- Cloudflare R2 S3 API Compatibility — https://developers.cloudflare.com/r2/api/s3/api/
- Cloudflare Pages SvelteKit Docs — https://developers.cloudflare.com/pages/framework-guides/deploy-a-svelte-kit-site/
- SvelteKit adapter-cloudflare Docs — https://svelte.dev/docs/kit/adapter-cloudflare
- SvelteKit Routing Docs — https://svelte.dev/docs/kit/routing
- Project source code — `registry/src/` (config.rs, main.rs, storage/r2.rs, routes/mod.rs)
- Project workflows — `.github/workflows/release.yml`, `.github/workflows/deploy.yml`
- Project install script — `tools/install/install.sh`

### Secondary (MEDIUM confidence)
- Wrangler R2 Commands — https://developers.cloudflare.com/r2/reference/wrangler-commands/
- Fly.io Managed Postgres — https://fly.io/docs/mpg/ (alternative to unmanaged Fly Postgres)

### Tertiary (LOW confidence)
- Community patterns for meshpkg in same-repo release matrix — based on general GitHub Actions multi-binary patterns, verified against existing release.yml structure

---

## Metadata

**Confidence breakdown:**
- Fly.io deployment: HIGH — official docs fetched, consistent with code in registry/
- Cloudflare R2 provisioning: HIGH — official docs fetched, matches aws-sdk-s3 usage in storage/r2.rs
- GitHub Actions release.yml extension: HIGH — existing workflow read in full, pattern is well-understood
- install.sh extension: HIGH — script read in full, structure is clear
- SvelteKit on Cloudflare Pages: HIGH — official docs fetched
- DNS/custom domain steps: MEDIUM — standard pattern, not verified against project's DNS provider

**Research date:** 2026-03-01
**Valid until:** 2026-04-01 (infrastructure CLI tools update frequently; verify Fly.io and Wrangler CLI versions before execution)
