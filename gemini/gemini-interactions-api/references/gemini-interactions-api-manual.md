# Gemini Interactions API Manual

## Advanced Features

### Stateful Conversations
Use `previous_interaction_id` to maintain context on the server.
```python
interaction2 = client.interactions.create(
    model="gemini-3-flash-preview",
    input="What is my name?",
    previous_interaction_id=interaction1.id
)
```

### Background Execution
Essential for long-running tasks like Deep Research.
```python
interaction = client.interactions.create(
    agent="deep-research-pro-preview-12-2025",
    input="Research topic...",
    background=True
)
# Poll interaction.status until 'completed'
```

### Multimodal Input
```python
interaction = client.interactions.create(
    model="gemini-3-flash-preview",
    input=[
        "Describe this image:",
        {"mime_type": "image/jpeg", "data": image_bytes}
    ]
)
```

## Tool Orchestration

### Google Search
```python
interaction = client.interactions.create(
    model="gemini-3-flash-preview",
    input="Current stock price of GOOG",
    tools=[{"google_search": {}}]
)
```

### Code Execution
```python
interaction = client.interactions.create(
    model="gemini-3-flash-preview",
    input="Calculate the 100th Fibonacci number",
    tools=[{"code_execution": {}}]
)
```

## Data Model Reference
An `Interaction` contains `outputs` (typed blocks):
- `text`: Generated text.
- `thought`: Model reasoning (requires `signature`).
- `function_call`: Tool request.
- `function_result`: Tool result.

## Migration Guide
- **History**: `startChat()` → `previous_interaction_id`.
- **Text**: `response.text` → `interaction.outputs[-1].text`.
- **Streaming**: Use SSE chunks with `event_type == "content.delta"`.

## Documentation Fallback
- [Interactions Full Docs](https://ai.google.dev/gemini-api/docs/interactions.md.txt)
- [Deep Research Full Docs](https://ai.google.dev/gemini-api/docs/deep-research.md.txt)
