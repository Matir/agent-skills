# Gemini API Development Manual

## Current Models

- `gemini-3.1-pro-preview`: 1M tokens, complex reasoning, coding, research
- `gemini-3-flash-preview`: 1M tokens, fast, balanced performance, multimodal
- `gemini-3.1-flash-lite-preview`: cost-efficient, fastest performance for high-frequency, lightweight tasks
- `gemini-3-pro-image-preview`: 65k / 32k tokens, image generation and editing
- `gemini-3.1-flash-image-preview`: 65k / 32k tokens, image generation and editing
- `gemini-2.5-pro`: 1M tokens, complex reasoning, coding, research
- `gemini-2.5-flash`: 1M tokens, fast, balanced performance, multimodal

**Legacy and deprecated (NEVER use)**: `gemini-2.0-*`, `gemini-1.5-*`.

## Current SDKs

- **Python**: `google-genai` → `uv pip install google-genai`
- **JavaScript/TypeScript**: `@google/genai` → `npm install @google/genai`
- **Go**: `google.golang.org/genai` → `go get google.golang.org/genai`
- **Java**: `com.google.genai:google-genai`

**Legacy and deprecated (NEVER use)**: `google-generativeai` (Python) and `@google/generative-ai` (JS).

## Additional SDK Snippets

### JavaScript/TypeScript
```typescript
import { GoogleGenAI } from "@google/genai";

const ai = new GoogleGenAI({});
const response = await ai.models.generateContent({
  model: "gemini-3-flash-preview",
  contents: "Explain quantum computing"
});
console.log(response.text);
```

### Go
```go
import (
	"context"
	"fmt"
	"log"
	"google.golang.org/genai"
)

func main() {
	ctx := context.Background()
	client, err := genai.NewClient(ctx, nil)
	if err != nil {
		log.Fatal(err)
	}

	resp, err := client.Models.GenerateContent(ctx, "gemini-3-flash-preview", genai.Text("Explain quantum computing"), nil)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println(resp.Text)
}
```

### Java
```java
import com.google.genai.Client;
import com.google.genai.types.GenerateContentResponse;

public class GenerateTextFromTextInput {
  public static void main(String[] args) {
    Client client = new Client();
    GenerateContentResponse response =
        client.models.generateContent(
            "gemini-3-flash-preview",
            "Explain quantum computing",
            null);

    System.out.println(response.text());
  }
}
```

**Java Installation:**
- Latest version: [Maven Central](https://central.sonatype.com/artifact/com.google.genai/google-genai/versions)
- Gradle: `implementation("com.google.genai:google-genai:${LAST_VERSION}")`

## Documentation Lookup

### When MCP is Installed (Preferred)
Use the **`search_documentation`** tool (from the Google MCP server) as the **only** documentation source. **Never** fetch URLs manually when MCP is available.

### When MCP is NOT Installed (Fallback Only)
Fetch from official docs starting with `https://ai.google.dev/gemini-api/docs/llms.txt`.

**Key pages:**
- [Text generation](https://ai.google.dev/gemini-api/docs/text-generation.md.txt)
- [Function calling](https://ai.google.dev/gemini-api/docs/function-calling.md.txt)
- [Structured outputs](https://ai.google.dev/gemini-api/docs/structured-output.md.txt)
- [Image generation](https://ai.google.dev/gemini-api/docs/image-generation.md.txt)
- [SDK migration guide](https://ai.google.dev/gemini-api/docs/migrate.md.txt)
