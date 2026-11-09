# openai

OpenAI's API client for Xo: a port of a subset of OpenAI's Go library,
`github.com/openai/openai-go/v3` v3.98.0, with its Azure OpenAI add-on.
Scope and what is deferred: docs/decisions/0001-openai-go-subset.md.

Status: in progress; nothing is released yet. Done: the client (options, Go's retry rules and errors), chat completions (streamed too, with the accumulator) and embeddings, checked against openai-go v3.98.0 (vectors_test.xo). Next: the azure package.

Licensed under the Apache License 2.0 (LICENSE); see NOTICE.md.
