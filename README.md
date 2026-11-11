# openai

OpenAI's API client for Xo: a port of a subset of OpenAI's Go library,
`github.com/openai/openai-go/v3` v3.98.0, with its Azure OpenAI add-on.
Scope and what is deferred: docs/decisions/0001-openai-go-subset.md.

Status: in progress; nothing is released yet. Done: the client (options, Go's retry rules and errors), chat completions (streamed too, with the accumulator), embeddings, the Responses API (create, stream, delete; `response`, `response_stream`, `delete_response`), and images (`generate_images`, `edit_images` as a multipart form), checked against openai-go v3.98.0 (vectors_test.xo). The `azure` package (its own module) points the client at Azure OpenAI with an API key or any azcore TokenCredential. Next: audio and legacy completions, then the first release.

Licensed under the Apache License 2.0 (LICENSE); see NOTICE.md.
