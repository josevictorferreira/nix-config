{ lib
, pkgs
, isDarwin
, npx
, defaultBrowser
, kebabToHuman
, ...
}:
{
  name = "grafana";
  description = "Grafana MCP for searching dashboards, querying Prometheus/Loki, and managing incidents/alerts.";
  mcp = {
    grafana = {
      command = lib.getExe pkgs.mcp-grafana;
      args = [ ];
      env = {
        "GRAFANA_URL" = "{env:GRAFANA_WORK_URL}";
        "GRAFANA_SERVICE_ACCOUNT_TOKEN" = "{env:GRAFANA_WORK_SERVICE_ACCOUNT_TOKEN}";
        "GRAFANA_USERNAME" = "{env:GRAFANA_WORK_USERNAME}";
        "GRAFANA_PASSWORD" = "{env:GRAFANA_WORK_PASSWORD}";
        "GRAFANA_ORG_ID" = "1";
      };
    };
  };
  tags = [ "infrastructure" ];
  prompt = ''
    # Grafana MCP

    ## CRITICAL: `skill_mcp` Syntax

    ```
    skill_mcp(mcp_name="grafana", tool_name="<TOOL>", arguments='<JSON>')
    ```

    - `mcp_name` = MCP server (`grafana`) — NOT `"grafana-skill"`
    - `tool_name` = Tool name without prefix — NOT `grafana_search_dashboards`

    ## Tools

    | Category | Tool | Use For |
    |----------|------|---------|
    | **Search** | `search_dashboards` | Search for dashboards by query |
    | **Search** | `search_folders` | Search for folders |
    | **Dashboard** | `get_dashboard_by_uid` | Get full dashboard JSON |
    | **Dashboard** | `get_dashboard_summary` | Get dashboard metadata summary |
    | **Dashboard** | `get_dashboard_panel_queries` | Get all panel queries in a dashboard |
    | **Dashboard** | `get_dashboard_property` | Get specific dashboard property |
    | **Dashboard** | `update_dashboard` | Update dashboard JSON |
    | **Datasource** | `list_datasources` | List all configured datasources |
    | **Datasource** | `get_datasource_by_uid` | Get datasource details by UID |
    | **Datasource** | `get_datasource_by_name` | Get datasource details by name |
    | **Prometheus** | `query_prometheus` | Execute PromQL queries |
    | **Prometheus** | `list_prometheus_metric_metadata` | List metric metadata |
    | **Prometheus** | `list_prometheus_metric_names` | List metric names |
    | **Prometheus** | `list_prometheus_label_names` | List label names |
    | **Prometheus** | `list_prometheus_label_values` | List label values |
    | **Loki** | `query_loki_logs` | Query Loki logs |
    | **Loki** | `query_loki_stats` | Get Loki query statistics |
    | **Loki** | `query_loki_patterns` | Extract patterns from logs |
    | **Loki** | `list_loki_label_names` | List Loki label names |
    | **Loki** | `list_loki_label_values` | List Loki label values |
    | **Incident** | `list_incidents` | List Grafana Incidents |
    | **Incident** | `get_incident` | Get incident details |
    | **Incident** | `create_incident` | Create a new incident |
    | **Incident** | `add_activity_to_incident` | Add activity to an incident |
    | **Alerting** | `list_alert_rules` | List alert rules |
    | **Alerting** | `get_alert_rule_by_uid` | Get alert rule details |
    | **Alerting** | `list_contact_points` | List notification contact points |
    | **Alerting** | `create_alert_rule` | Create alert rule |
    | **Alerting** | `update_alert_rule` | Update alert rule |
    | **Alerting** | `delete_alert_rule` | Delete alert rule |
    | **OnCall** | `list_oncall_schedules` | List OnCall schedules |
    | **OnCall** | `get_oncall_shift` | Get current shift for schedule |
    | **OnCall** | `get_current_oncall_users` | Get current on-call users |
    | **OnCall** | `list_oncall_teams` | List OnCall teams |
    | **OnCall** | `list_oncall_users` | List OnCall users |
    | **OnCall** | `list_alert_groups` | List OnCall alert groups |
    | **OnCall** | `get_alert_group` | Get alert group details |
    | **Annotations** | `get_annotations` | Get annotations |
    | **Annotations** | `create_annotation` | Create annotation |
    | **Annotations** | `update_annotation` | Update annotation |
    | **Annotations** | `patch_annotation` | Patch annotation |
    | **Annotations** | `get_annotation_tags` | Get annotation tags |
    | **Pyroscope** | `fetch_pyroscope_profile` | Fetch profiling data |
    | **Pyroscope** | `list_pyroscope_profile_types` | List profile types |
    | **Pyroscope** | `list_pyroscope_label_names` | List label names |
    | **Pyroscope** | `list_pyroscope_label_values` | List label values |
    | **Sift** | `list_sift_investigations` | List Sift investigations |
    | **Sift** | `get_sift_investigation` | Get investigation details |
    | **Sift** | `get_sift_analysis` | Get Sift analysis |
    | **Sift** | `find_error_pattern_logs` | Find error patterns |
    | **Sift** | `find_slow_requests` | Find slow requests |
    | **Admin** | `list_teams` | Search for teams |
    | **Admin** | `list_users_by_org` | List users in organization |
    | **Admin** | `list_all_roles` | List all roles |
    | **Admin** | `get_role_details` | Get role details |
    | **Admin** | `get_role_assignments` | Get role assignments |
    | **Admin** | `list_user_roles` | List roles for users |
    | **Admin** | `list_team_roles` | List roles for teams |
    | **Admin** | `get_resource_permissions` | List resource permissions |
    | **Admin** | `get_resource_description` | Get resource type description |
    | **Rendering** | `get_panel_image` | Render panel as image |
    | **Asserts** | `get_assertions` | Get assertion summary |
    | **Navigation** | `generate_deeplink` | Generate deep link |
    | **Folder** | `create_folder` | Create folder |

    ## Examples

    **Search Dashboards**:
    ```
    skill_mcp(mcp_name="grafana", tool_name="search_dashboards", arguments='{"query": "Production Overview", "limit": 5}')
    ```

    **Query Prometheus**:
    ```
    skill_mcp(mcp_name="grafana", tool_name="query_prometheus", arguments='{"query": "rate(http_requests_total[5m])", "datasourceUID": "prom-123", "step": "1m"}')
    ```

    **Query Loki Logs**:
    ```
    skill_mcp(mcp_name="grafana", tool_name="query_loki_logs", arguments='{"query": "{app=\\"api\\"} |= \\"error\\"", "datasourceUID": "loki-123", "limit": 20}')
    ```

    **Get Panel Image**:
    ```
    skill_mcp(mcp_name="grafana", tool_name="get_panel_image", arguments='{"dashboardUID": "db-123", "panelID": 1, "width": 1200, "theme": "dark"}')
    ```

    **List Incidents**:
    ```
    skill_mcp(mcp_name="grafana", tool_name="list_incidents", arguments='{"status": ["active"], "severity": ["critical"]}')
    ```

    **Create Alert Rule**:
    ```
    skill_mcp(mcp_name="grafana", tool_name="create_alert_rule", arguments='{"title": "High CPU", "ruleGroup": "infra", "folderUID": "f-123", "condition": "A", "data": [...], "noDataState": "NoData", "execErrState": "Alerting", "for": "5m", "orgID": 1}')
    ```

    **Fetch Pyroscope Profile**:
    ```
    skill_mcp(mcp_name="grafana", tool_name="fetch_pyroscope_profile", arguments='{"datasourceUID": "pyro-123", "profileType": "process_cpu:cpu:nanoseconds:cpu:nanoseconds"}')
    ```

    **Find Slow Requests (Sift)**:
    ```
    skill_mcp(mcp_name="grafana", tool_name="find_slow_requests", arguments='{"threshold": "2s", "limit": 10}')
    ```

    **Get OnCall Shift**:
    ```
    skill_mcp(mcp_name="grafana", tool_name="get_oncall_shift", arguments='{"scheduleID": "sch-123"}')
    ```

    ## Common Mistakes

    | ❌ Wrong | ✅ Correct |
    |----------|-----------|
    | `mcp_name="grafana-skill"` | `mcp_name="grafana"` |
    | `tool_name="grafana_search_dashboards"` | `tool_name="search_dashboards"` |
    | `datasource_uid` | `datasourceUID` (Case sensitive!) |
  '';
  licence = "MIT";
  metadata = {
    triggers = "grafana, dashboard, prometheus, loki, query, metrics, logs, alert, incident, oncall, annotation, pyroscope, sift, asserts";
  };
}
