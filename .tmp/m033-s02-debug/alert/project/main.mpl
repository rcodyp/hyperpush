from Storage.Queries import create_alert_rule, get_event_alert_rules, get_threshold_rules, fire_alert

fn main() do
  let pool_result = Pool.open("postgres://mesh:mesh@127.0.0.1:5432/mesher", 1, 1, 5000)
  case pool_result do
    Err( e) -> println("pool_err=#{e}")
    Ok( pool) -> do
      let event_rule = create_alert_rule(pool, "0a8f9b64-c932-4bd3-ac2e-1edd68b2cd35", "{\"name\":\"New issue pager\",\"condition\":{\"condition_type\":\"new_issue\"}}")
      case event_rule do
        Err( e) -> println("event_rule_err=#{e}")
        Ok( event_rule_id) -> do
          println("event_rule_id=#{event_rule_id}")
          let threshold_rule = create_alert_rule(pool, "0a8f9b64-c932-4bd3-ac2e-1edd68b2cd35", "{\"name\":\"Error flood\",\"condition\":{\"condition_type\":\"threshold\",\"threshold\":\"5\",\"window_minutes\":\"10\"},\"cooldown_minutes\":\"15\",\"action\":{\"type\":\"email\"}}")
          case threshold_rule do
            Err( e) -> println("threshold_rule_err=#{e}")
            Ok( threshold_rule_id) -> do
              println("threshold_rule_id=#{threshold_rule_id}")
              let event_rules = get_event_alert_rules(pool, "0a8f9b64-c932-4bd3-ac2e-1edd68b2cd35", "new_issue")
              case event_rules do
                Err( e) -> println("event_rules_err=#{e}")
                Ok( rows) -> println("event_rules_count=#{List.length(rows)}")
              end
              let threshold_rules = get_threshold_rules(pool)
              case threshold_rules do
                Err( e) -> println("threshold_rules_err=#{e}")
                Ok( rows) -> println("threshold_rules_count=#{List.length(rows)}")
              end
              let fired = fire_alert(pool, event_rule_id, "0a8f9b64-c932-4bd3-ac2e-1edd68b2cd35", "new_issue detected for issue issue-123", "new_issue", "New issue pager")
              case fired do
                Err( e) -> println("fire_err=#{e}")
                Ok( alert_id) -> println("alert_id=#{alert_id}")
              end
            end
          end
        end
      end
    end
  end
end
