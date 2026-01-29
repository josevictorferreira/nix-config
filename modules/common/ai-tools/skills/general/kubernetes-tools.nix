{
  config,
  lib,
  inputs,
  system,
  pkgs,
  ...
}:
let
  skillName = "kubernetes-tools";
  cfg = config.jvf.aiTools.skills."${skillName}";
  npx = lib.getExe' pkgs.nodejs "npx";
  skillDef = inputs.lib.aiTools.mkSkillModule {
    name = skillName;
    description = "Kubernetes MCP server for managing Kubernetes and OpenShift clusters. Interact with pods, deployments, services, namespaces, events, Helm charts, and any Kubernetes resource via direct API calls.";
    licence = "MIT";
    metadata = {
      triggers = "kubernetes, k8s, kubectl, pod, deployment, service, namespace, helm, cluster, container, kubeconfig, context, openshift, nodes, events, ingress, secret, configmap, persistentvolume, statefulset, daemonset, job, cronjob, custom-resource, crd";
    };
    mcp = {
      kubernetes = {
        command = npx;
        args = [
          "-y"
          "kubernetes-mcp-server@latest"
        ];
        # env = {
        #   "KUBECONFIG" = "{env:KUBECONFIG}";
        # };
      };
    };
    prompt = ''
      # Kubernetes Tools

      ## CRITICAL: `skill_mcp` Syntax

      ```
      skill_mcp(mcp_name="kubernetes", tool_name="<TOOL>", arguments='<JSON>')
      ```

      - `mcp_name` = MCP server (`kubernetes`) — NOT `"kubernetes-tools"`
      - `tool_name` = Tool name without prefix — NOT `kubernetes_pods_list`

      ## Tools

      | Category | Tool | Use For |
      |----------|------|---------|
      | **Config** | `configuration_contexts_list` | List all available context names and server URLs from kubeconfig |
      | **Config** | `targets_list` | List all available targets |
      | **Config** | `configuration_view` | Get current Kubernetes configuration as kubeconfig YAML |
      | **Core** | `events_list` | List Kubernetes events from all namespaces or specific namespace |
      | **Core** | `namespaces_list` | List all Kubernetes namespaces |
      | **Core** | `projects_list` | List all OpenShift projects |
      | **Core** | `nodes_log` | Get logs from a Kubernetes node (kubelet, kube-proxy) |
      | **Core** | `nodes_stats_summary` | Get detailed resource usage statistics from a node |
      | **Core** | `pods_list` | List pods in all namespaces |
      | **Core** | `pods_list_in_namespace` | List pods in specific namespace |
      | **Core** | `pods_get` | Get a specific pod |
      | **Core** | `pods_delete` | Delete a specific pod |
      | **Core** | `pods_top` | Get resource consumption (CPU/memory) for pods |
      | **Core** | `pods_exec` | Execute a command in a pod |
      | **Core** | `pods_log` | Get logs from a pod |
      | **Core** | `pods_run` | Run a container image in a pod |
      | **Generic** | `resources_list` | List any Kubernetes resources by apiVersion and kind |
      | **Generic** | `resources_get` | Get any Kubernetes resource |
      | **Generic** | `resources_create_or_update` | Create or update any Kubernetes resource |
      | **Generic** | `resources_delete` | Delete any Kubernetes resource |
      | **Helm** | `helm_install` | Install a Helm chart |
      | **Helm** | `helm_list` | List Helm releases |
      | **Helm** | `helm_uninstall` | Uninstall a Helm release |

      ## Tool Details

      ### Configuration Tools

      **configuration_contexts_list** - List all available context names
      - No parameters required

      **targets_list** - List all available targets
      - No parameters required

      **configuration_view** - Get kubeconfig YAML
      - `minified` (boolean, optional): Return minified version with only current context (default: true)

      ### Core Tools

      **events_list** - List Kubernetes events
      - `namespace` (string, optional): Namespace to retrieve events from (default: all namespaces)

      **namespaces_list** - List all namespaces
      - No parameters required

      **projects_list** - List OpenShift projects
      - No parameters required

      **nodes_log** - Get node system logs
      - `name` (string, required): Name of the node
      - `query` (string, required): Service or file (e.g., "kubelet", "/var/log/kubelet.log")
      - `tailLines` (integer, optional): Number of lines from end (default: all)

      **nodes_stats_summary** - Get node resource usage stats
      - `name` (string, required): Name of the node

      **pods_list** - List pods in all namespaces
      - `labelSelector` (string, optional): Kubernetes label selector (e.g., 'app=myapp')

      **pods_list_in_namespace** - List pods in specific namespace
      - `labelSelector` (string, optional): Kubernetes label selector
      - `namespace` (string, required): Namespace to list pods from

      **pods_get** - Get a specific pod
      - `name` (string, required): Name of the Pod
      - `namespace` (string, optional): Namespace (default: current context)

      **pods_delete** - Delete a specific pod
      - `name` (string, required): Name of the Pod to delete
      - `namespace` (string, optional): Namespace (default: current context)

      **pods_top** - Get resource consumption metrics
      - `all_namespaces` (boolean, optional): List from all namespaces (default: false)
      - `label_selector` (string, optional): Filter by labels
      - `name` (string, optional): Specific pod name
      - `namespace` (string, optional): Namespace (default: current context)

      **pods_exec** - Execute command in a pod
      - `command` (array, required): Command and arguments (e.g., ["ls", "-l", "/tmp"])
      - `container` (string, optional): Container name for multi-container pods
      - `name` (string, required): Pod name
      - `namespace` (string, optional): Namespace (default: current context)

      **pods_log** - Get pod logs
      - `container` (string, optional): Container name for multi-container pods
      - `name` (string, required): Pod name
      - `namespace` (string, optional): Namespace (default: current context)
      - `previous` (boolean, optional): Get previous terminated container logs
      - `tail` (integer, optional): Number of lines from end (default: 100)

      **pods_run** - Run a container in a pod
      - `image` (string, required): Container image to run
      - `name` (string, optional): Pod name (random if not provided)
      - `namespace` (string, optional): Namespace (default: current context)
      - `port` (number, optional): TCP port to expose

      ### Generic Resource Tools (any Kubernetes resource)

      **resources_list** - List any Kubernetes resources
      - `apiVersion` (string, required): API version (e.g., "v1", "apps/v1", "networking.k8s.io/v1")
      - `kind` (string, required): Resource kind (e.g., "Pod", "Service", "Deployment", "Ingress")
      - `labelSelector` (string, optional): Filter by labels
      - `namespace` (string, optional): Namespace (default: all namespaces)

      **resources_get** - Get any Kubernetes resource
      - `apiVersion` (string, required): API version
      - `kind` (string, required): Resource kind
      - `name` (string, required): Resource name
      - `namespace` (string, optional): Namespace (default: current context)

      **resources_create_or_update** - Create or update any resource
      - `resource` (string, required): JSON or YAML representation with apiVersion, kind, metadata, spec

      **resources_delete** - Delete any Kubernetes resource
      - `apiVersion` (string, required): API version
      - `kind` (string, required): Resource kind
      - `name` (string, required): Resource name
      - `namespace` (string, optional): Namespace (default: current context)

      ### Helm Tools

      **helm_install** - Install a Helm chart
      - `chart` (string, required): Chart reference (e.g., "stable/grafana", "oci://ghcr.io/nginxinc/charts/nginx-ingress")
      - `name` (string, optional): Release name (random if not provided)
      - `namespace` (string, optional): Namespace (default: current context)
      - `values` (object, optional): Values to pass to the chart

      **helm_list** - List Helm releases
      - `all_namespaces` (boolean, optional): List from all namespaces
      - `namespace` (string, optional): Namespace (default: all namespaces)

      **helm_uninstall** - Uninstall a Helm release
      - `name` (string, required): Release name to uninstall
      - `namespace` (string, optional): Namespace (default: current context)

      ## Multi-Cluster Support

      When multi-cluster is enabled (default) and you have access to multiple clusters, all applicable tools include an additional `context` parameter to specify the Kubernetes context (cluster):

      - `context` (string, optional): Kubernetes context name to use for the operation

      ## Configuration Options

      The MCP server can be configured with these options:
      - `--read-only`: Run in read-only mode (no create/update/delete)
      - `--disable-destructive`: Disable destructive operations
      - `--list-output`: Output format (yaml or table, default: table)
      - `--toolsets`: Comma-separated list of toolsets to enable (config, core, helm)

      ## Examples

      **List all pods in default namespace**:
      ```
      skill_mcp(mcp_name="kubernetes", tool_name="pods_list_in_namespace", arguments='{"namespace": "default"}')
      ```

      **Get pod logs with last 50 lines**:
      ```
      skill_mcp(mcp_name="kubernetes", tool_name="pods_log", arguments='{"name": "my-app-pod", "namespace": "production", "tail": 50}')
      ```

      **Execute command in pod**:
      ```
      skill_mcp(mcp_name="kubernetes", tool_name="pods_exec", arguments='{"name": "my-app-pod", "namespace": "production", "command": ["ls", "-la", "/app"]}')
      ```

      **List all Deployments**:
      ```
      skill_mcp(mcp_name="kubernetes", tool_name="resources_list", arguments='{"apiVersion": "apps/v1", "kind": "Deployment"}')
      ```

      **Create a ConfigMap**:
      ```
      skill_mcp(mcp_name="kubernetes", tool_name="resources_create_or_update", arguments='{"resource": "apiVersion: v1\\nkind: ConfigMap\\nmetadata:\\n  name: my-config\\n  namespace: default\\ndata:\\n  KEY: value"}')
      ```

      **Install Helm chart**:
      ```
      skill_mcp(mcp_name="kubernetes", tool_name="helm_install", arguments='{"chart": "nginx/nginx-ingress", "name": "my-nginx", "namespace": "ingress-nginx"}')
      ```

      **Get node resource usage**:
      ```
      skill_mcp(mcp_name="kubernetes", tool_name="nodes_stats_summary", arguments='{"name": "worker-node-1"}')
      ```

      **List events in a namespace**:
      ```
      skill_mcp(mcp_name="kubernetes", tool_name="events_list", arguments='{"namespace": "kube-system"}')
      ```

      **Switch to different cluster context**:
      ```
      skill_mcp(mcp_name="kubernetes", tool_name="pods_list", arguments='{"context": "production-cluster"}')
      ```

      **Delete a resource**:
      ```
      skill_mcp(mcp_name="kubernetes", tool_name="resources_delete", arguments='{"apiVersion": "v1", "kind": "ConfigMap", "name": "old-config", "namespace": "default"}')
      ```

      ## Common Mistakes

      | ❌ Wrong | ✅ Correct |
      |----------|-----------|
      | `mcp_name="kubernetes-tools"` | `mcp_name="kubernetes"` |
      | `tool_name="kubernetes_pods_list"` | `tool_name="pods_list"` |
      | `kind: pod` (lowercase) | `kind: "Pod"` (capitalized) |
      | `apiVersion: v1` for Deployment | `apiVersion: "apps/v1"` for Deployment |
      | Missing namespace for namespaced resources | Provide `namespace` parameter |
      | `context` parameter for single cluster | Omit `context` when using default |
    '';
  };
in
{
  options.jvf.aiTools.skills."${skillName}" = skillDef.options;
  config = lib.mkIf cfg.enable skillDef.config;
}
