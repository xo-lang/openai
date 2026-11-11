# openai

OpenAI's API client for Xo: a port of a subset of OpenAI's Go library,
`github.com/openai/openai-go/v3` v3.98.0, with its Azure OpenAI add-on.
Two modules: `github.com/xo-lang/openai` (the client) and
`github.com/xo-lang/openai/azure` (Azure OpenAI endpoints and
authentication).

A community library for the Xo language. Not affiliated with or
endorsed by OpenAI or Microsoft. OpenAI is a trademark of OpenAI; Azure
is a trademark of the Microsoft group of companies.

```
xo get github.com/xo-lang/openai@v0.1.0 github.com/xo-lang/openai/azure@v0.1.0
```

Requires Xo 0.46.0 or later; `azure` requires `github.com/xo-lang/azure`
v0.1.0 (azcore).

## Scope of v0.1.0

The surface Azure OpenAI uses: every client call in the examples of Go's
`azopenai` v0.9.0, each checked against openai-go v3.98.0 itself (a Go
program runs openai-go against a local fake and the Xo tests replay the
same calls, request by request; vectors_test.xo).

- **The client**: base URL, API key, organization and project, extra
  headers and query values, hooks (Go's middleware), max retries,
  request timeout; Go's retry rules (`x-should-retry`, `retry-after-ms`,
  `retry-after`, 408, 409, 429, 5xx, its backoff), its headers and its
  error type.
- **Chat completions**: `chat_completion`, `chat_completion_stream` and
  the stream accumulator (content, refusals, tool calls).
- **Responses**: `response`, `response_stream`, `delete_response`.
- **Embeddings**: `embeddings`, float and base64.
- **Images**: `generate_images`, `edit_images` (a multipart form).
- **Audio**: `transcribe`, `translate`, `speech`.
- **Legacy completions**: `completion`, `completion_stream`.
- **azure**: `options(AzureOptions{endpoint, api_version, ...})`: the
  deployment path for JSON and multipart routes, `api-version`, an
  `Api-Key` or any azcore TokenCredential (azidentity's included), and
  the plain http rule.

Each call takes the common parameters as fields and any other through
`extra`; each result keeps the response's JSON in `raw`. The details and
the per slice decisions: docs/decisions/0001-openai-go-subset.md.

## Not in v0.1.0

What openai-go v3.98.0 has that this release does not:

- Files, uploads, batches, fine tuning, graders, evals.
- Assistants, threads, runs and the other beta APIs; vector stores;
  conversations; containers; skills.
- Moderations, models, safety, content provenance checks, decisions.
- Videos, image variations and streamed images, custom voices and
  voice consents, streamed transcriptions and the text, srt and vtt
  formats.
- Responses: retrieve, cancel, input items, input tokens, compaction,
  the response accumulator, the websocket transport, built in tools
  (file and web search, computer use, MCP, code interpreter) and the
  structured output helpers.
- Chat: stored completions (list, retrieve, update, delete) and logprobs
  in the accumulator.
- Realtime, live and websockets; webhooks; the admin APIs; pagination
  helpers; the Bedrock and other provider packages.
- `azopenai`'s Azure types (On Your Data, content filter results) live
  in `github.com/xo-lang/azure/ai/azopenai`, not here.

Each is a later release, by user need.

## License

Apache License 2.0 (LICENSE), as openai-go; see NOTICE.md. Each ported
file names its openai-go source and says how it was changed.
