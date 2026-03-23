from Jobs. Worker import get_worker_boot_id, get_worker_failed_jobs, get_worker_last_error, get_worker_last_exit_reason, get_worker_last_job_id, get_worker_last_recovery_at, get_worker_last_recovery_count, get_worker_last_recovery_job_id, get_worker_last_status, get_worker_last_tick_at, get_worker_poll_ms, get_worker_processed_jobs, get_worker_recovered_jobs, get_worker_restart_count, get_worker_started_at

fn encode_optional_string(value :: String) -> String do
  let wrapped = if String.length(value) > 0 do
    json { value : Some(value) }
  else
    json { value : None }
  end
  String.slice(wrapped, 9, String.length(wrapped) - 1)
end

fn current_unix_ms() -> Int do
  DateTime.to_unix_ms(DateTime.utc_now())
end

fn worker_tick_age_ms(last_tick_at :: String) -> Int do
  if String.length(last_tick_at) == 0 do
    -1
  else
    let parsed = DateTime.from_iso8601(last_tick_at)
    case parsed do
      Ok( dt) -> current_unix_ms() - DateTime.to_unix_ms(dt)
      Err( _) -> -1
    end
  end
end

fn worker_liveness(last_status :: String) -> String do
  if last_status == "recovering" do
    "recovering"
  else
    if last_status == "crashing" do
      "recovering"
    else
      if last_status == "failed" do
        "failed"
      else
        "healthy"
      end
    end
  end
end

fn health_status(liveness :: String) -> String do
  if liveness == "healthy" do
    "ok"
  else
    if liveness == "recovering" do
      "degraded"
    else
      "error"
    end
  end
end

fn bool_json(value :: Bool) -> String do
  if value == true do
    "true"
  else
    "false"
  end
end

fn is_recovering_status(status :: String) -> Bool do
  if status == "recovering" do
    true
  else
    false
  end
end

fn health_json() -> String do
  let worker_poll_ms = get_worker_poll_ms()
  let worker_boot_id = get_worker_boot_id()
  let worker_started_at = get_worker_started_at()
  let worker_last_tick_at = get_worker_last_tick_at()
  let worker_last_status = get_worker_last_status()
  let worker_last_job_id = get_worker_last_job_id()
  let worker_last_error = get_worker_last_error()
  let worker_processed_jobs = get_worker_processed_jobs()
  let worker_failed_jobs = get_worker_failed_jobs()
  let worker_restart_count = get_worker_restart_count()
  let worker_last_exit_reason = get_worker_last_exit_reason()
  let worker_recovered_jobs = get_worker_recovered_jobs()
  let worker_last_recovery_at = get_worker_last_recovery_at()
  let worker_last_recovery_job_id = get_worker_last_recovery_job_id()
  let worker_last_recovery_count = get_worker_last_recovery_count()
  let worker_tick_age = worker_tick_age_ms(worker_last_tick_at)
  let worker_liveness_value = worker_liveness(worker_last_status)
  let overall_status = health_status(worker_liveness_value)
  let recovery_active = is_recovering_status(worker_liveness_value)
  "{\"status\":\"" <> overall_status <> "\",\"worker\":{\"status\":\"" <> worker_last_status <> "\",\"liveness\":\"" <> worker_liveness_value <> "\",\"poll_ms\":" <> String.from(worker_poll_ms) <> ",\"tick_age_ms\":" <> String.from(worker_tick_age) <> ",\"boot_id\":" <> encode_optional_string(worker_boot_id) <> ",\"started_at\":" <> encode_optional_string(worker_started_at) <> ",\"last_tick_at\":" <> encode_optional_string(worker_last_tick_at) <> ",\"restart_count\":" <> String.from(worker_restart_count) <> ",\"last_exit_reason\":" <> encode_optional_string(worker_last_exit_reason) <> ",\"last_job_id\":" <> encode_optional_string(worker_last_job_id) <> ",\"last_error\":" <> encode_optional_string(worker_last_error) <> ",\"processed_jobs\":" <> String.from(worker_processed_jobs) <> ",\"failed_jobs\":" <> String.from(worker_failed_jobs) <> ",\"recovered_jobs\":" <> String.from(worker_recovered_jobs) <> ",\"last_recovery_at\":" <> encode_optional_string(worker_last_recovery_at) <> ",\"last_recovery_job_id\":" <> encode_optional_string(worker_last_recovery_job_id) <> ",\"last_recovery_count\":" <> String.from(worker_last_recovery_count) <> ",\"recovery_active\":" <> bool_json(recovery_active) <> "}}"
end

pub fn handle_health(request) do
  HTTP.response(200, health_json())
end
