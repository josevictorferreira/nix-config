// Minimal OpenAI Chat Completions <-> Command Code proxy.
// Translates POST /v1/chat/completions into POST https://api.commandcode.ai/alpha/generate
// and remarshals the upstream's Vercel-AI-SDK-shaped stream into OpenAI SSE chunks.
package main

import (
	"bufio"
	"bytes"
	"crypto/rand"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"
)

const (
	ccBase      = "https://api.commandcode.ai/alpha/generate"
	ccVersion   = "0.25.7"
	cliEnv      = "cli"
	projectSlug = "commandcode-proxy"
)

// --- OpenAI input shapes ---

type oaiRequest struct {
	Model     string       `json:"model"`
	Messages  []oaiMessage `json:"messages"`
	Tools     []oaiTool    `json:"tools,omitempty"`
	Stream    bool         `json:"stream,omitempty"`
	MaxTokens int          `json:"max_tokens,omitempty"`
}

type oaiMessage struct {
	Role       string          `json:"role"`
	Content    json.RawMessage `json:"content,omitempty"`
	ToolCalls  []oaiToolCall   `json:"tool_calls,omitempty"`
	ToolCallID string          `json:"tool_call_id,omitempty"`
}

type oaiTool struct {
	Type     string `json:"type"`
	Function struct {
		Name        string          `json:"name"`
		Description string          `json:"description"`
		Parameters  json.RawMessage `json:"parameters"`
	} `json:"function"`
}

type oaiToolCall struct {
	ID       string `json:"id"`
	Type     string `json:"type"`
	Function struct {
		Name      string `json:"name"`
		Arguments string `json:"arguments"`
	} `json:"function"`
}

// --- CC envelope ---

type ccRequest struct {
	Config         ccConfig    `json:"config"`
	Memory         string      `json:"memory"`
	Taste          string      `json:"taste"`
	Skills         interface{} `json:"skills"`
	PermissionMode string      `json:"permissionMode"`
	Params         ccParams    `json:"params"`
}

type ccConfig struct {
	WorkingDir    string   `json:"workingDir"`
	Date          string   `json:"date"`
	Environment   string   `json:"environment"`
	Structure     []string `json:"structure"`
	IsGitRepo     bool     `json:"isGitRepo"`
	CurrentBranch string   `json:"currentBranch"`
	MainBranch    string   `json:"mainBranch"`
	GitStatus     string   `json:"gitStatus"`
	RecentCommits []string `json:"recentCommits"`
}

type ccParams struct {
	Model     string        `json:"model"`
	Messages  []interface{} `json:"messages"`
	Tools     []interface{} `json:"tools"`
	System    string        `json:"system"`
	MaxTokens int           `json:"max_tokens"`
	Stream    bool          `json:"stream"`
}

// --- main ---

func main() {
	port := flag.Int("port", envInt("COMMANDCODE_PROXY_PORT", 18080), "listen port")
	bind := flag.String("bind", envStr("COMMANDCODE_PROXY_BIND", "127.0.0.1"), "bind address")
	flag.Parse()

	mux := http.NewServeMux()
	mux.HandleFunc("/v1/chat/completions", handleChat)
	mux.HandleFunc("/v1/models", handleModels)
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) {
		_, _ = w.Write([]byte("ok\n"))
	})

	addr := fmt.Sprintf("%s:%d", *bind, *port)
	log.Printf("commandcode-proxy listening on %s", addr)
	srv := &http.Server{Addr: addr, Handler: mux, ReadHeaderTimeout: 10 * time.Second}
	log.Fatal(srv.ListenAndServe())
}

// --- helpers ---

func envStr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func envInt(key string, def int) int {
	if v := os.Getenv(key); v != "" {
		if n, err := strconv.Atoi(v); err == nil {
			return n
		}
	}
	return def
}

func loadAPIKey() (string, error) {
	if k := os.Getenv("COMMANDCODE_API_KEY"); k != "" {
		return k, nil
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	data, err := os.ReadFile(filepath.Join(home, ".commandcode", "auth.json"))
	if err != nil {
		return "", err
	}
	var auth struct {
		APIKey string `json:"apiKey"`
	}
	if err := json.Unmarshal(data, &auth); err != nil {
		return "", err
	}
	if auth.APIKey == "" {
		return "", errors.New("no apiKey in ~/.commandcode/auth.json")
	}
	return auth.APIKey, nil
}

func uuidV4() string {
	var b [16]byte
	_, _ = rand.Read(b[:])
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return fmt.Sprintf("%08x-%04x-%04x-%04x-%012x", b[0:4], b[4:6], b[6:8], b[8:10], b[10:16])
}

// extractText collapses OpenAI's polymorphic content field into a plain string.
func extractText(raw json.RawMessage) string {
	if len(raw) == 0 {
		return ""
	}
	var s string
	if json.Unmarshal(raw, &s) == nil {
		return s
	}
	var parts []struct {
		Type string `json:"type"`
		Text string `json:"text"`
	}
	if json.Unmarshal(raw, &parts) == nil {
		var sb strings.Builder
		for _, p := range parts {
			if p.Type == "text" || p.Type == "" {
				sb.WriteString(p.Text)
			}
		}
		return sb.String()
	}
	return ""
}

// translateMessages maps OpenAI chat messages to CC's Vercel-AI-SDK shape and
// extracts system-role content into a separate `system` string.
func translateMessages(in []oaiMessage) ([]interface{}, string) {
	var systemText strings.Builder
	// Initialized to empty slice (not nil) so JSON marshals to `[]` even
	// when all input messages were filtered out — CC's validator rejects
	// `messages: null` with HTTP 400.
	out := []interface{}{}

	// Only forward tool results whose tool_call_id matches an emitted assistant call.
	emitted := map[string]bool{}
	for _, m := range in {
		if m.Role == "assistant" {
			for _, tc := range m.ToolCalls {
				emitted[tc.ID] = true
			}
		}
	}

	for _, m := range in {
		switch m.Role {
		case "system":
			if systemText.Len() > 0 {
				systemText.WriteString("\n")
			}
			systemText.WriteString(extractText(m.Content))
		case "user":
			out = append(out, map[string]interface{}{
				"role":    "user",
				"content": extractText(m.Content),
			})
		case "assistant":
			parts := []interface{}{}
			if t := extractText(m.Content); t != "" {
				parts = append(parts, map[string]interface{}{"type": "text", "text": t})
			}
			for _, tc := range m.ToolCalls {
				var input interface{} = map[string]interface{}{}
				if tc.Function.Arguments != "" {
					_ = json.Unmarshal([]byte(tc.Function.Arguments), &input)
				}
				parts = append(parts, map[string]interface{}{
					"type":       "tool-call",
					"toolCallId": tc.ID,
					"toolName":   tc.Function.Name,
					"input":      input,
				})
			}
			if len(parts) > 0 {
				out = append(out, map[string]interface{}{"role": "assistant", "content": parts})
			}
		case "tool":
			if !emitted[m.ToolCallID] {
				continue
			}
			// CC accepts only `user`/`assistant` roles and the Anthropic
			// `tool_result` content shape (underscored, with `tool_use_id`
			// and string `content`). The Vercel `role:"tool"` /
			// `type:"tool-result"` form is rejected by CC's validator.
			out = append(out, map[string]interface{}{
				"role": "user",
				"content": []interface{}{
					map[string]interface{}{
						"type":        "tool_result",
						"tool_use_id": m.ToolCallID,
						"content":     extractText(m.Content),
					},
				},
			})
		}
	}
	return out, systemText.String()
}

func translateTools(in []oaiTool) []interface{} {
	out := []interface{}{}
	for _, t := range in {
		out = append(out, map[string]interface{}{
			"type":         "function",
			"name":         t.Function.Name,
			"description":  t.Function.Description,
			"input_schema": json.RawMessage(t.Function.Parameters),
		})
	}
	return out
}

// writeError emits an OpenAI-shaped JSON error envelope so AI-SDK clients
// surface the actual upstream message instead of wrapping it as
// "Invalid error response format".
func writeError(w http.ResponseWriter, status int, errType, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	payload, _ := json.Marshal(map[string]interface{}{
		"error": map[string]interface{}{
			"message": message,
			"type":    errType,
			"code":    status,
		},
	})
	_, _ = w.Write(payload)
}

// --- chat handler ---

func handleChat(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	if r.Method != http.MethodPost {
		writeError(w, http.StatusMethodNotAllowed, "method_not_allowed", "method not allowed")
		return
	}
	var oReq oaiRequest
	if err := json.NewDecoder(r.Body).Decode(&oReq); err != nil {
		writeError(w, http.StatusBadRequest, "invalid_request", err.Error())
		return
	}

	apiKey, err := loadAPIKey()
	if err != nil {
		writeError(w, http.StatusInternalServerError, "auth_error", err.Error())
		return
	}

	msgs, sys := translateMessages(oReq.Messages)
	maxTokens := oReq.MaxTokens
	if maxTokens == 0 {
		maxTokens = 32000
	}

	cwd, _ := os.Getwd()
	body, _ := json.Marshal(ccRequest{
		Config: ccConfig{
			WorkingDir:    cwd,
			Date:          time.Now().Format("2006-01-02"),
			Environment:   "commandcode-proxy",
			Structure:     []string{},
			RecentCommits: []string{},
		},
		PermissionMode: "standard",
		Params: ccParams{
			Model:     oReq.Model,
			Messages:  msgs,
			Tools:     translateTools(oReq.Tools),
			System:    sys,
			MaxTokens: maxTokens,
			Stream:    true,
		},
	})

	httpReq, _ := http.NewRequestWithContext(r.Context(), http.MethodPost, ccBase, bytes.NewReader(body))
	httpReq.Header.Set("Content-Type", "application/json")
	httpReq.Header.Set("Authorization", "Bearer "+apiKey)
	httpReq.Header.Set("x-command-code-version", ccVersion)
	httpReq.Header.Set("x-cli-environment", cliEnv)
	httpReq.Header.Set("x-project-slug", projectSlug)
	httpReq.Header.Set("x-taste-learning", "false")
	httpReq.Header.Set("x-co-flag", "false")
	httpReq.Header.Set("x-session-id", uuidV4())

	resp, err := http.DefaultClient.Do(httpReq)
	if err != nil {
		log.Printf("model=%q upstream dial error: %v", oReq.Model, err)
		writeError(w, http.StatusBadGateway, "upstream_error", err.Error())
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		errBody, _ := io.ReadAll(resp.Body)
		// Log full request + CC response so journalctl reveals what was rejected.
		log.Printf("model=%q upstream %d in %s\n  req: %s\n  resp: %s",
			oReq.Model, resp.StatusCode, time.Since(start), string(body), string(errBody))
		// Pull CC's own message into our JSON envelope when possible.
		msg := fmt.Sprintf("upstream %d: %s", resp.StatusCode, errBody)
		var ccErr struct {
			Error struct {
				Message string `json:"message"`
				Code    string `json:"code"`
			} `json:"error"`
		}
		if json.Unmarshal(errBody, &ccErr) == nil && ccErr.Error.Message != "" {
			msg = fmt.Sprintf("Command Code: %s", ccErr.Error.Message)
		}
		writeError(w, resp.StatusCode, "upstream_error", msg)
		return
	}

	log.Printf("model=%q upstream=200 stream=%v setup=%s", oReq.Model, oReq.Stream, time.Since(start))
	if oReq.Stream {
		streamCCToOAI(w, resp.Body, oReq.Model)
	} else {
		collectCCToOAI(w, resp.Body, oReq.Model)
	}
}

func mapFinishReason(r string) string {
	switch r {
	case "tool-calls", "tool-use", "tool_calls":
		return "tool_calls"
	case "length", "max_tokens", "max-tokens":
		return "length"
	default:
		return "stop"
	}
}

func encodeChunk(id, model string, created int64, delta map[string]interface{}, finish *string) []byte {
	choice := map[string]interface{}{
		"index":         0,
		"delta":         delta,
		"finish_reason": nil,
	}
	if finish != nil {
		choice["finish_reason"] = *finish
	}
	out, _ := json.Marshal(map[string]interface{}{
		"id":      id,
		"object":  "chat.completion.chunk",
		"created": created,
		"model":   model,
		"choices": []interface{}{choice},
	})
	return out
}

func streamCCToOAI(w http.ResponseWriter, body io.Reader, model string) {
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "streaming unsupported", http.StatusInternalServerError)
		return
	}

	id := "chatcmpl-" + uuidV4()
	created := time.Now().Unix()
	send := func(delta map[string]interface{}, finish *string) {
		fmt.Fprintf(w, "data: %s\n\n", encodeChunk(id, model, created, delta, finish))
		flusher.Flush()
	}

	send(map[string]interface{}{"role": "assistant"}, nil)

	scanner := bufio.NewScanner(body)
	scanner.Buffer(make([]byte, 1<<20), 4<<20)

	toolIdx := map[string]int{}
	finishReason := "stop"

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}
		var ev map[string]interface{}
		if err := json.Unmarshal([]byte(line), &ev); err != nil {
			continue
		}

		switch ev["type"] {
		case "text-delta":
			if t, ok := ev["text"].(string); ok && t != "" {
				send(map[string]interface{}{"content": t}, nil)
			}
		case "tool-call":
			tcID, _ := ev["toolCallId"].(string)
			tcName, _ := ev["toolName"].(string)
			var input interface{} = ev["input"]
			if input == nil {
				input = ev["args"]
			}
			if input == nil {
				input = ev["arguments"]
			}
			args, _ := json.Marshal(input)
			if _, seen := toolIdx[tcID]; !seen {
				toolIdx[tcID] = len(toolIdx)
			}
			send(map[string]interface{}{
				"tool_calls": []interface{}{
					map[string]interface{}{
						"index": toolIdx[tcID],
						"id":    tcID,
						"type":  "function",
						"function": map[string]interface{}{
							"name":      tcName,
							"arguments": string(args),
						},
					},
				},
			}, nil)
			finishReason = "tool_calls"
		case "finish":
			if r, ok := ev["finishReason"].(string); ok {
				finishReason = mapFinishReason(r)
			}
		case "error":
			msg := "stream error"
			if e, ok := ev["error"].(map[string]interface{}); ok {
				if m, ok := e["message"].(string); ok {
					msg = m
				}
			}
			data, _ := json.Marshal(map[string]interface{}{
				"error": map[string]interface{}{"message": msg, "type": "upstream_error"},
			})
			fmt.Fprintf(w, "data: %s\n\n", data)
			flusher.Flush()
		}
	}

	final := finishReason
	send(map[string]interface{}{}, &final)
	fmt.Fprint(w, "data: [DONE]\n\n")
	flusher.Flush()
}

func collectCCToOAI(w http.ResponseWriter, body io.Reader, model string) {
	scanner := bufio.NewScanner(body)
	scanner.Buffer(make([]byte, 1<<20), 4<<20)

	var content strings.Builder
	var toolCalls []map[string]interface{}
	toolIdx := map[string]int{}
	finishReason := "stop"

	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}
		var ev map[string]interface{}
		if err := json.Unmarshal([]byte(line), &ev); err != nil {
			continue
		}
		switch ev["type"] {
		case "text-delta":
			if t, ok := ev["text"].(string); ok {
				content.WriteString(t)
			}
		case "tool-call":
			tcID, _ := ev["toolCallId"].(string)
			tcName, _ := ev["toolName"].(string)
			var input interface{} = ev["input"]
			if input == nil {
				input = ev["args"]
			}
			args, _ := json.Marshal(input)
			if _, seen := toolIdx[tcID]; !seen {
				toolIdx[tcID] = len(toolIdx)
			}
			toolCalls = append(toolCalls, map[string]interface{}{
				"id":   tcID,
				"type": "function",
				"function": map[string]interface{}{
					"name":      tcName,
					"arguments": string(args),
				},
			})
			finishReason = "tool_calls"
		case "finish":
			if r, ok := ev["finishReason"].(string); ok {
				finishReason = mapFinishReason(r)
			}
		}
	}

	msg := map[string]interface{}{"role": "assistant", "content": content.String()}
	if len(toolCalls) > 0 {
		msg["tool_calls"] = toolCalls
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"id":      "chatcmpl-" + uuidV4(),
		"object":  "chat.completion",
		"created": time.Now().Unix(),
		"model":   model,
		"choices": []interface{}{
			map[string]interface{}{
				"index":         0,
				"message":       msg,
				"finish_reason": finishReason,
			},
		},
	})
}

// --- models endpoint ---

var ccModelIDs = []string{
	"claude-opus-4-7", "claude-opus-4-6", "claude-sonnet-4-6", "claude-haiku-4-5-20251001",
	"gpt-5.5", "gpt-5.4", "gpt-5.3-codex", "gpt-5.4-mini",
	"deepseek/deepseek-v4-pro", "deepseek/deepseek-v4-flash",
	"moonshotai/Kimi-K2.6", "moonshotai/Kimi-K2.5",
	"zai-org/GLM-5.1", "zai-org/GLM-5",
	"MiniMaxAI/MiniMax-M2.7", "MiniMaxAI/MiniMax-M2.5",
	"Qwen/Qwen3.6-Max-Preview", "Qwen/Qwen3.6-Plus",
}

func handleModels(w http.ResponseWriter, _ *http.Request) {
	now := time.Now().Unix()
	data := []map[string]interface{}{}
	for _, id := range ccModelIDs {
		data = append(data, map[string]interface{}{
			"id":       id,
			"object":   "model",
			"created":  now,
			"owned_by": "commandcode",
		})
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"object": "list",
		"data":   data,
	})
}
