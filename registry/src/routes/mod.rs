use std::sync::Arc;
use axum::{Router, routing::{get, post}};
use crate::state::AppState;

pub mod auth;
pub mod download;
pub mod metadata;
pub mod publish;
pub mod search;

pub fn router(state: Arc<AppState>) -> Router {
    Router::new()
        .route("/auth/github", get(auth::github_login))
        .route("/auth/callback", get(auth::github_callback))
        .route("/dashboard", get(auth::dashboard))
        .route("/dashboard/tokens", get(auth::list_tokens_handler))
        .route("/dashboard/tokens", post(auth::create_token_handler))
        .with_state(state)
}
