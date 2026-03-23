# Knowledge

- `reference-backend` startup is stable on the non-empty `DATABASE_URL` path when env validation stays local to `main.mpl` and uses `Env.get` plus `Env.get_int`; the mechanical regression surface is `cargo test -p meshc e2e_reference_backend_runtime_starts --test e2e_reference_backend -- --ignored --nocapture`, and the missing-env check remains `env -u DATABASE_URL PORT=18080 JOB_POLL_MS=500 ./reference-backend/reference-backend 2>&1 | rg "DATABASE_URL"`.
