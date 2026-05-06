# Artifacts

Supported in ADKPython v0.1.0TypeScript v0.6.1Go v0.1.0Java v0.1.0

In ADK, **Artifacts** represent a crucial mechanism for managing named, versioned binary data associated either with a specific user interaction session or persistently with a user across multiple sessions. They allow your agents and tools to handle data beyond simple text strings, enabling richer interactions involving files, images, audio, and other binary formats.

Note

The specific parameters or method names for the primitives may vary slightly by SDK language (e.g., `save_artifact` in Python, `saveArtifact` in Java). Refer to the language-specific API documentation for details.

## What are Artifacts?

- **Definition:** An Artifact is essentially a piece of binary data (like the content of a file) identified by a unique `filename` string within a specific scope (session or user). Each time you save an artifact with the same filename, a new version is created.

- **Representation:** Artifacts are consistently represented using the standard `google.genai.types.Part` object. The core data is typically stored within an inline data structure of the `Part` (accessed via `inline_data`), which itself contains:

  - `data`: The raw binary content as bytes.
  - `mime_type`: A string indicating the type of the data (e.g., `"image/png"`, `"application/pdf"`). This is essential for correctly interpreting the data later.

```py
# Example of how an artifact might be represented as a types.Part
import google.genai.types as types

# Assume 'image_bytes' contains the binary data of a PNG image
image_bytes = b'\x89PNG\r\n\x1a\n...' # Placeholder for actual image bytes

image_artifact = types.Part(
    inline_data=types.Blob(
        mime_type="image/png",
        data=image_bytes
    )
)

# You can also use the convenience constructor:
# image_artifact_alt = types.Part.from_bytes(data=image_bytes, mime_type="image/png")

print(f"Artifact MIME Type: {image_artifact.inline_data.mime_type}")
print(f"Artifact Data (first 10 bytes): {image_artifact.inline_data.data[:10]}...")
```

```typescript
import {createPartFromBase64, type Part} from '@google/genai';

// Assume 'imageBytes' contains the binary data of a PNG image.
const imageBytes = new Uint8Array([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);

// Using Buffer.from(bytes).toString('base64') for Node.js environments.
const imageArtifact: Part = createPartFromBase64(
  Buffer.from(imageBytes).toString('base64'),
  'image/png',
);

console.log(`Artifact MIME Type: ${imageArtifact.inlineData?.mimeType}`);
// Note: Accessing raw bytes would require decoding from base64.
```

```go
import (
  "log"

  "google.golang.org/genai"
)

// Create a byte slice with the image data.
imageBytes, err := os.ReadFile("image.png")
if err != nil {
    log.Fatalf("Failed to read image file: %v", err)
}

// Create a new artifact with the image data.
imageArtifact := &genai.Part{
    InlineData: &genai.Blob{
        MIMEType: "image/png",
        Data:     imageBytes,
    },
}
log.Printf("Artifact MIME Type: %s", imageArtifact.InlineData.MIMEType)
log.Printf("Artifact Data (first 8 bytes): %x...", imageArtifact.InlineData.Data[:8])
```

```java
import com.google.genai.types.Part;
import java.nio.charset.StandardCharsets;

public class ArtifactExample {
    public static void main(String[] args) {
        // Assume 'imageBytes' contains the binary data of a PNG image
        byte[] imageBytes = {(byte) 0x89, (byte) 0x50, (byte) 0x4E, (byte) 0x47, (byte) 0x0D, (byte) 0x0A, (byte) 0x1A, (byte) 0x0A, (byte) 0x01, (byte) 0x02}; // Placeholder for actual image bytes

        // Create an image artifact using Part.fromBytes
        Part imageArtifact = Part.fromBytes(imageBytes, "image/png");

        System.out.println("Artifact MIME Type: " + imageArtifact.inlineData().get().mimeType().get());
        System.out.println(
            "Artifact Data (first 10 bytes): "
                + new String(imageArtifact.inlineData().get().data().get(), 0, 10, StandardCharsets.UTF_8)
                + "...");
    }
}
```

- **Persistence & Management:** Artifacts are not stored directly within the agent or session state. Their storage and retrieval are managed by a dedicated **Artifact Service** (an implementation of `BaseArtifactService`, defined in `google.adk.artifacts`. ADK provides various implementations, such as:
  - An in-memory service for testing or temporary storage (e.g., `InMemoryArtifactService` in Python, defined in `google.adk.artifacts.in_memory_artifact_service.py`).
  - A service for persistent storage using Google Cloud Storage (GCS) (e.g., `GcsArtifactService` in Python, defined in `google.adk.artifacts.gcs_artifact_service.py`). The chosen service implementation handles versioning automatically when you save data.

## Why Use Artifacts?

While session `state` is suitable for storing small pieces of configuration or conversational context (like strings, numbers, booleans, or small dictionaries/lists), Artifacts are designed for scenarios involving binary or large data:

1. **Handling Non-Textual Data:** Easily store and retrieve images, audio clips, video snippets, PDFs, spreadsheets, or any other file format relevant to your agent's function.
1. **Persisting Large Data:** Session state is generally not optimized for storing large amounts of data. Artifacts provide a dedicated mechanism for persisting larger blobs without cluttering the session state.
1. **User File Management:** Provide capabilities for users to upload files (which can be saved as artifacts) and retrieve or download files generated by the agent (loaded from artifacts).
1. **Sharing Outputs:** Enable tools or agents to generate binary outputs (like a PDF report or a generated image) that can be saved via `save_artifact` and later accessed by other parts of the application or even in subsequent sessions (if using user namespacing).
1. **Caching Binary Data:** Store the results of computationally expensive operations that produce binary data (e.g., rendering a complex chart image) as artifacts to avoid regenerating them on subsequent requests.

In essence, whenever your agent needs to work with file-like binary data that needs to be persisted, versioned, or shared, Artifacts managed by an `ArtifactService` are the appropriate mechanism within ADK.

## Common Use Cases

Artifacts provide a flexible way to handle binary data within your ADK applications.

Here are some typical scenarios where they prove valuable:

- **Generated Reports/Files:**

  - A tool or agent generates a report (e.g., a PDF analysis, a CSV data export, an image chart).

- **Handling User Uploads:**

  - A user uploads a file (e.g., an image for analysis, a document for summarization) through a front-end interface.

- **Storing Intermediate Binary Results:**

  - An agent performs a complex multi-step process where one step generates intermediate binary data (e.g., audio synthesis, simulation results).

- **Persistent User Data:**

  - Storing user-specific configuration or data that isn't a simple key-value state.

- **Caching Generated Binary Content:**

  - An agent frequently generates the same binary output based on certain inputs (e.g., a company logo image, a standard audio greeting).

## Core Concepts

Understanding artifacts involves grasping a few key components: the service that manages them, the data structure used to hold them, and how they are identified and versioned.

### Artifact Service (`BaseArtifactService`)

- **Role:** The central component responsible for the actual storage and retrieval logic for artifacts. It defines *how* and *where* artifacts are persisted.

- **Interface:** Defined by the abstract base class `BaseArtifactService`. Any concrete implementation must provide methods for:

  - `Save Artifact`: Stores the artifact data and returns its assigned version number.
  - `Load Artifact`: Retrieves a specific version (or the latest) of an artifact.
  - `List Artifact keys`: Lists the unique filenames of artifacts within a given scope.
  - `Delete Artifact`: Removes an artifact (and potentially all its versions, depending on implementation).
  - `List versions`: Lists all available version numbers for a specific artifact filename.

- **Configuration:** You provide an instance of an artifact service (e.g., `InMemoryArtifactService`, `GcsArtifactService`) when initializing the `Runner`. The `Runner` then makes this service available to agents and tools via the `InvocationContext`.

```py
from google.adk.runners import Runner
from google.adk.artifacts import InMemoryArtifactService # Or GcsArtifactService
from google.adk.agents import LlmAgent # Any agent
from google.adk.sessions import InMemorySessionService

# Example: Configuring the Runner with an Artifact Service
my_agent = LlmAgent(name="artifact_user_agent", model="gemini-flash-latest")
artifact_service = InMemoryArtifactService() # Choose an implementation
session_service = InMemorySessionService()

runner = Runner(
    agent=my_agent,
    app_name="my_artifact_app",
    session_service=session_service,
    artifact_service=artifact_service # Provide the service instance here
)
# Now, contexts within runs managed by this runner can use artifact methods
```

```typescript
import {
  InMemoryArtifactService,
  InMemorySessionService,
  LlmAgent,
  Runner,
} from '@google/adk';

// Example: Configuring the Runner with an Artifact Service
const myAgent = new LlmAgent({
  name: 'artifact_user_agent',
  model: 'gemini-flash-latest',
});
const artifactService = new InMemoryArtifactService();
const sessionService = new InMemorySessionService();

const runner = new Runner({
  agent: myAgent,
  appName: 'my_artifact_app',
  sessionService: sessionService,
  artifactService: artifactService,
});
// Now, contexts within runs managed by this runner can use artifact methods.
```

```go
import (
  "context"
  "log"

  "google.golang.org/adk/agent/llmagent"
  "google.golang.org/adk/artifactservice"
  "google.golang.org/adk/llm/gemini"
  "google.golang.org/adk/runner"
  "google.golang.org/adk/sessionservice"
  "google.golang.org/genai"
)

// Create a new context.
ctx := context.Background()
// Set the app name.
const appName = "my_artifact_app"
// Create a new Gemini model.
model, err := gemini.NewModel(ctx, "gemini-2.5-flash", &genai.ClientConfig{})
if err != nil {
    log.Fatalf("Failed to create model: %v", err)
}

// Create a new LLM agent.
myAgent, err := llmagent.New(llmagent.Config{
    Model:       model,
    Name:        "artifact_user_agent",
    Instruction: "You are an agent that describes images.",
    BeforeModelCallbacks: []llmagent.BeforeModelCallback{
        BeforeModelCallback,
    },
})
if err != nil {
    log.Fatalf("Failed to create agent: %v", err)
}

// Create a new in-memory artifact service.
artifactService := artifact.InMemoryService()
// Create a new in-memory session service.
sessionService := session.InMemoryService()

// Create a new runner.
r, err := runner.New(runner.Config{
    Agent:           myAgent,
    AppName:         appName,
    SessionService:  sessionService,
    ArtifactService: artifactService, // Provide the service instance here
})
if err != nil {
    log.Fatalf("Failed to create runner: %v", err)
}
log.Printf("Runner created successfully: %v", r)
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.runner.Runner;
import com.google.adk.sessions.InMemorySessionService;
import com.google.adk.artifacts.InMemoryArtifactService;

// Example: Configuring the Runner with an Artifact Service
LlmAgent myAgent =  LlmAgent.builder()
  .name("artifact_user_agent")
  .model("gemini-flash-latest")
  .build();
InMemoryArtifactService artifactService = new InMemoryArtifactService(); // Choose an implementation
InMemorySessionService sessionService = new InMemorySessionService();

Runner runner = new Runner(myAgent, "my_artifact_app", artifactService, sessionService); // Provide the service instance here
// Now, contexts within runs managed by this runner can use artifact methods
```

### Artifact Data

- **Standard Representation:** Artifact content is universally represented using the `google.genai.types.Part` object, the same structure used for parts of LLM messages.

- **Key Attribute (`inline_data`):** For artifacts, the most relevant attribute is `inline_data`, which is a `google.genai.types.Blob` object containing:

  - `data` (`bytes`): The raw binary content of the artifact.
  - `mime_type` (`str`): A standard MIME type string (e.g., `'application/pdf'`, `'image/png'`, `'audio/mpeg'`) describing the nature of the binary data. **This is crucial for correct interpretation when loading the artifact.**

```python
import google.genai.types as types

# Example: Creating an artifact Part from raw bytes
pdf_bytes = b'%PDF-1.4...' # Your raw PDF data
pdf_mime_type = "application/pdf"

# Using the constructor
pdf_artifact_py = types.Part(
    inline_data=types.Blob(data=pdf_bytes, mime_type=pdf_mime_type)
)

# Using the convenience class method (equivalent)
pdf_artifact_alt_py = types.Part.from_bytes(data=pdf_bytes, mime_type=pdf_mime_type)

print(f"Created Python artifact with MIME type: {pdf_artifact_py.inline_data.mime_type}")
```

```typescript
import {createPartFromBase64, type Part} from '@google/genai';

// Example: Creating an artifact Part from raw bytes.
const pdfBytes = new Uint8Array([0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x34]);
const pdfMimeType = 'application/pdf';

// Using Buffer.from(bytes).toString('base64') for Node.js environments.
const pdfArtifact: Part = createPartFromBase64(
  Buffer.from(pdfBytes).toString('base64'),
  pdfMimeType,
);
console.log(`Created TypeScript artifact with MIME Type: ${pdfArtifact.inlineData?.mimeType}`);
```

```go
import (
  "log"
  "os"

  "google.golang.org/genai"
)

// Load imageBytes from a file
imageBytes, err := os.ReadFile("image.png")
if err != nil {
    log.Fatalf("Failed to read image file: %v", err)
}

// genai.NewPartFromBytes is a convenience function that is a shorthand for
// creating a &genai.Part with the InlineData field populated.
// Create a new artifact from the image data.
imageArtifact := genai.NewPartFromBytes([]byte(imageBytes), "image/png")

log.Printf("Artifact MIME Type: %s", imageArtifact.InlineData.MIMEType)
```

```java
import com.google.genai.types.Blob;
import com.google.genai.types.Part;
import java.nio.charset.StandardCharsets;

public class ArtifactDataExample {
  public static void main(String[] args) {
    // Example: Creating an artifact Part from raw bytes
    byte[] pdfBytes = "%PDF-1.4...".getBytes(StandardCharsets.UTF_8); // Your raw PDF data
    String pdfMimeType = "application/pdf";

    // Using the Part.fromBlob() constructor with a Blob
    Blob pdfBlob = Blob.builder()
        .data(pdfBytes)
        .mimeType(pdfMimeType)
        .build();
    Part pdfArtifactJava = Part.builder().inlineData(pdfBlob).build();

    // Using the convenience static method Part.fromBytes() (equivalent)
    Part pdfArtifactAltJava = Part.fromBytes(pdfBytes, pdfMimeType);

    // Accessing mimeType, note the use of Optional
    String mimeType = pdfArtifactJava.inlineData()
        .flatMap(Blob::mimeType)
        .orElse("unknown");
    System.out.println("Created Java artifact with MIME type: " + mimeType);

    // Accessing data
    byte[] data = pdfArtifactJava.inlineData()
        .flatMap(Blob::data)
        .orElse(new byte[0]);
    System.out.println("Java artifact data (first 10 bytes): "
        + new String(data, 0, Math.min(data.length, 10), StandardCharsets.UTF_8) + "...");
  }
}
```

### Filename

- **Identifier:** A simple string used to name and retrieve an artifact within its specific namespace.
- **Uniqueness:** Filenames must be unique within their scope (either the session or the user namespace).
- **Best Practice:** Use descriptive names, potentially including file extensions (e.g., `"monthly_report.pdf"`, `"user_avatar.jpg"`), although the extension itself doesn't dictate behavior – the `mime_type` does.

### Versioning

- **Automatic Versioning:** The artifact service automatically handles versioning. When you call `save_artifact`, the service determines the next available version number (typically starting from 0 and incrementing) for that specific filename and scope.
- **Returned by `save_artifact`:** The `save_artifact` method returns the integer version number that was assigned to the newly saved artifact.
- **Retrieval:**
- `load_artifact(..., version=None)` (default): Retrieves the *latest* available version of the artifact.
- `load_artifact(..., version=N)`: Retrieves the specific version `N`.
- **Listing Versions:** The `list_versions` method (on the service, not context) can be used to find all existing version numbers for an artifact.

### Namespacing (Session vs. User)

- **Concept:** Artifacts can be scoped either to a specific session or more broadly to a user across all their sessions within the application. This scoping is determined by the `filename` format and handled internally by the `ArtifactService`.
- **Default (Session Scope):** If you use a plain filename like `"report.pdf"`, the artifact is associated with the specific `app_name`, `user_id`, *and* `session_id`. It's only accessible within that exact session context.
- **User Scope (`"user:"` prefix):** If you prefix the filename with `"user:"`, like `"user:profile.png"`, the artifact is associated only with the `app_name` and `user_id`. It can be accessed or updated from *any* session belonging to that user within the app.

```python
# Example illustrating namespace difference (conceptual)

# Session-specific artifact filename
session_report_filename = "summary.txt"

# User-specific artifact filename
user_config_filename = "user:settings.json"

# When saving 'summary.txt' via context.save_artifact,
# it's tied to the current app_name, user_id, and session_id.

# When saving 'user:settings.json' via context.save_artifact,
# the ArtifactService implementation should recognize the "user:" prefix
# and scope it to app_name and user_id, making it accessible across sessions for that user.
```

```typescript
// Example illustrating namespace difference (conceptual)

// Session-specific artifact filename
const sessionReportFilename = "summary.txt";

// User-specific artifact filename
const userConfigFilename = "user:settings.json";

// When saving 'summary.txt' via context.saveArtifact, it's tied to the current appName, userId, and sessionId.
// When saving 'user:settings.json' via context.saveArtifact, the ArtifactService implementation recognizes the "user:" prefix and scopes it to appName and userId, making it accessible across sessions for that user.
```

```go
import (
  "log"
)

// Note: Namespacing is only supported when using the GCS ArtifactService implementation.
// A session-scoped artifact is only available within the current session.
sessionReportFilename := "summary.txt"
// A user-scoped artifact is available across all sessions for the current user.
userConfigFilename := "user:settings.json"

// When saving 'summary.txt' via ctx.Artifacts().Save,
// it's tied to the current app_name, user_id, and session_id.
// ctx.Artifacts().Save(sessionReportFilename, *artifact);

// When saving 'user:settings.json' via ctx.Artifacts().Save,
// the ArtifactService implementation should recognize the "user:" prefix
// and scope it to app_name and user_id, making it accessible across sessions for that user.
// ctx.Artifacts().Save(userConfigFilename, *artifact);
```

```java
// Example illustrating namespace difference (conceptual)

// Session-specific artifact filename
String sessionReportFilename = "summary.txt";

// User-specific artifact filename
String userConfigFilename = "user:settings.json"; // The "user:" prefix is key

// When saving 'summary.txt' via context.save_artifact,
// it's tied to the current app_name, user_id, and session_id.
// artifactService.saveArtifact(appName, userId, sessionId1, sessionReportFilename, someData);

// When saving 'user:settings.json' via context.save_artifact,
// the ArtifactService implementation should recognize the "user:" prefix
// and scope it to app_name and user_id, making it accessible across sessions for that user.
// artifactService.saveArtifact(appName, userId, sessionId1, userConfigFilename, someData);
```

These core concepts work together to provide a flexible system for managing binary data within the ADK framework.

## Interacting with Artifacts (via Context Objects)

The primary way you interact with artifacts within your agent's logic (specifically within callbacks or tools) is through methods provided by the `CallbackContext` and `ToolContext` objects. These methods abstract away the underlying storage details managed by the `ArtifactService`.

*(Note: In TypeScript, `CallbackContext` and `ToolContext` are unified into a single `Context` type.)*

### Prerequisite: Configuring the `ArtifactService`

Before you can use any artifact methods via the context objects, you **must** provide an instance of a [`BaseArtifactService` implementation](#available-implementations) (like [`InMemoryArtifactService`](#inmemoryartifactservice) or [`GcsArtifactService`](#gcsartifactservice)) when initializing your `Runner`.

In Python, you provide this instance when initializing your `Runner`.

```python
from google.adk.runners import Runner
from google.adk.artifacts import InMemoryArtifactService # Or GcsArtifactService
from google.adk.agents import LlmAgent
from google.adk.sessions import InMemorySessionService

# Your agent definition
agent = LlmAgent(name="my_agent", model="gemini-flash-latest")

# Instantiate the desired artifact service
artifact_service = InMemoryArtifactService()

# Provide it to the Runner
runner = Runner(
    agent=agent,
    app_name="artifact_app",
    session_service=InMemorySessionService(),
    artifact_service=artifact_service # Service must be provided here
)
```

If no `artifact_service` is configured in the `InvocationContext` (which happens if it's not passed to the `Runner`), calling `save_artifact`, `load_artifact`, or `list_artifacts` on the context objects will raise a `ValueError`.

```typescript
import {
  InMemoryArtifactService,
  InMemorySessionService,
  LlmAgent,
  Runner,
} from '@google/adk';

// Your agent definition.
const agent = new LlmAgent({
  name: 'my_agent',
  model: 'gemini-flash-latest',
});

// Instantiate the desired artifact service.
const artifactService = new InMemoryArtifactService();

// Provide it to the Runner.
const runner = new Runner({
  agent: agent,
  appName: 'artifact_app',
  sessionService: new InMemorySessionService(),
  artifactService: artifactService,
});
// If no artifactService is configured, calling artifact methods on context objects will throw an error.
```

In Java, if an `ArtifactService` instance is not available (e.g., `null`) when artifact operations are attempted, it would typically result in a `NullPointerException` or a custom error, depending on how your application is structured. Robust applications often use dependency injection frameworks to manage service lifecycles and ensure availability.

```go
import (
  "context"
  "log"

  "google.golang.org/adk/agent/llmagent"
  "google.golang.org/adk/artifactservice"
  "google.golang.org/adk/llm/gemini"
  "google.golang.org/adk/runner"
  "google.golang.org/adk/sessionservice"
  "google.golang.org/genai"
)

// Create a new context.
ctx := context.Background()
// Set the app name.
const appName = "my_artifact_app"
// Create a new Gemini model.
model, err := gemini.NewModel(ctx, "gemini-2.5-flash", &genai.ClientConfig{})
if err != nil {
    log.Fatalf("Failed to create model: %v", err)
}

// Create a new LLM agent.
myAgent, err := llmagent.New(llmagent.Config{
    Model:       model,
    Name:        "artifact_user_agent",
    Instruction: "You are an agent that describes images.",
    BeforeModelCallbacks: []llmagent.BeforeModelCallback{
        BeforeModelCallback,
    },
})
if err != nil {
    log.Fatalf("Failed to create agent: %v", err)
}

// Create a new in-memory artifact service.
artifactService := artifact.InMemoryService()
// Create a new in-memory session service.
sessionService := session.InMemoryService()

// Create a new runner.
r, err := runner.New(runner.Config{
    Agent:           myAgent,
    AppName:         appName,
    SessionService:  sessionService,
    ArtifactService: artifactService, // Provide the service instance here
})
if err != nil {
    log.Fatalf("Failed to create runner: %v", err)
}
log.Printf("Runner created successfully: %v", r)
```

In Java, you would instantiate a `BaseArtifactService` implementation and then ensure it's accessible to the parts of your application that manage artifacts. This is often done through dependency injection or by explicitly passing the service instance.

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.artifacts.InMemoryArtifactService; // Or GcsArtifactService
import com.google.adk.runner.Runner;
import com.google.adk.sessions.InMemorySessionService;

public class SampleArtifactAgent {

  public static void main(String[] args) {

    // Your agent definition
    LlmAgent agent = LlmAgent.builder()
        .name("my_agent")
        .model("gemini-flash-latest")
        .build();

    // Instantiate the desired artifact service
    InMemoryArtifactService artifactService = new InMemoryArtifactService();

    // Provide it to the Runner
    Runner runner = new Runner(agent,
        "APP_NAME",
        artifactService, // Service must be provided here
        new InMemorySessionService());

  }
}
```

### Accessing Methods

The artifact interaction methods are available directly on instances of `CallbackContext` (passed to agent and model callbacks) and `ToolContext` (passed to tool callbacks) in Python, Go, and Java and available on the unified `Context` in TypeScript.

#### Saving Artifacts

- **Code Example:**

  ```python
  import google.genai.types as types
  from google.adk.agents.callback_context import CallbackContext # Or ToolContext

  async def save_generated_report_py(context: CallbackContext, report_bytes: bytes):
      """Saves generated PDF report bytes as an artifact."""
      report_artifact = types.Part.from_bytes(
          data=report_bytes,
          mime_type="application/pdf"
      )
      filename = "generated_report.pdf"

      try:
          version = await context.save_artifact(filename=filename, artifact=report_artifact)
          print(f"Successfully saved Python artifact '{filename}' as version {version}.")
          # The event generated after this callback will contain:
          # event.actions.artifact_delta == {"generated_report.pdf": version}
      except ValueError as e:
          print(f"Error saving Python artifact: {e}. Is ArtifactService configured in Runner?")
      except Exception as e:
          # Handle potential storage errors (e.g., GCS permissions)
          print(f"An unexpected error occurred during Python artifact save: {e}")

  # --- Example Usage Concept (Python) ---
  # async def main_py():
  #   callback_context: CallbackContext = ... # obtain context
  #   report_data = b'...' # Assume this holds the PDF bytes
  #   await save_generated_report_py(callback_context, report_data)
  ```

  ```typescript
  import {Context} from '@google/adk';
  import {createPartFromBase64, type Part} from '@google/genai';

  async function saveGeneratedReport(context: Context, reportBytes: Uint8Array): Promise<void> {
    /** Saves generated PDF report bytes as an artifact. */
    const reportArtifact: Part = createPartFromBase64(
      Buffer.from(reportBytes).toString('base64'),
      'application/pdf',
    );

    const filename = 'generated_report.pdf';

    try {
      const version = await context.saveArtifact(filename, reportArtifact);
      console.log(`Successfully saved TypeScript artifact '${filename}' as version ${version}.`);
    } catch (e: any) {
      console.error(
        `Error saving TypeScript artifact: ${e.message}. Is ArtifactService configured in Runner?`,
      );
    }
  }
  ```

  ```go
  import (
    "log"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/llm"
    "google.golang.org/genai"
  )

  // saveReportCallback is a BeforeModel callback that saves a report from session state.
  func saveReportCallback(ctx agent.CallbackContext, req *model.LLMRequest) (*model.LLMResponse, error) {
      // Get the report data from the session state.
      reportData, err := ctx.State().Get("report_bytes")
      if err != nil {
          log.Printf("No report data found in session state: %v", err)
          return nil, nil // No report to save, continue normally.
      }

      // Check if the report data is in the expected format.
      reportBytes, ok := reportData.([]byte)
      if !ok {
          log.Printf("Report data in session state was not in the expected byte format.")
          return nil, nil
      }

      // Create a new artifact with the report data.
      reportArtifact := &genai.Part{
          InlineData: &genai.Blob{
              MIMEType: "application/pdf",
              Data:     reportBytes,
          },
      }
      // Set the filename for the artifact.
      filename := "generated_report.pdf"
      // Save the artifact to the artifact service.
      _, err = ctx.Artifacts().Save(ctx, filename, reportArtifact)
      if err != nil {
          log.Printf("An unexpected error occurred during Go artifact save: %v", err)
          // Depending on requirements, you might want to return an error to the user.
          return nil, nil
      }
      log.Printf("Successfully saved Go artifact '%s'.", filename)
      // Return nil to continue to the next callback or the model.
      return nil, nil
  }
  ```

  ```java
  import com.google.adk.agents.CallbackContext;
  import com.google.adk.artifacts.BaseArtifactService;
  import com.google.adk.artifacts.InMemoryArtifactService;
  import com.google.genai.types.Part;
  import java.nio.charset.StandardCharsets;

  public class SaveArtifactExample {

  public void saveGeneratedReport(CallbackContext callbackContext, byte[] reportBytes) {
  // Saves generated PDF report bytes as an artifact.
  Part reportArtifact = Part.fromBytes(reportBytes, "application/pdf");
  String filename = "generatedReport.pdf";

      callbackContext.saveArtifact(filename, reportArtifact);
      System.out.println("Successfully saved Java artifact '" + filename);
      // The event generated after this callback will contain:
      // event().actions().artifactDelta == {"generated_report.pdf": version}
  }

  // --- Example Usage Concept (Java) ---
  public static void main(String[] args) {
      BaseArtifactService service = new InMemoryArtifactService(); // Or GcsArtifactService
      SaveArtifactExample myTool = new SaveArtifactExample();
      byte[] reportData = "...".getBytes(StandardCharsets.UTF_8); // PDF bytes
      CallbackContext callbackContext; // ... obtain callback context from your app
      myTool.saveGeneratedReport(callbackContext, reportData);
      // Due to async nature, in a real app, ensure program waits or handles completion.
    }
  }
  ```

#### Loading Artifacts

- **Code Example:**

  ```python
  import google.genai.types as types
  from google.adk.agents.callback_context import CallbackContext # Or ToolContext

  async def process_latest_report_py(context: CallbackContext):
      """Loads the latest report artifact and processes its data."""
      filename = "generated_report.pdf"
      try:
          # Load the latest version
          report_artifact = await context.load_artifact(filename=filename)

          if report_artifact and report_artifact.inline_data:
              print(f"Successfully loaded latest Python artifact '{filename}'.")
              print(f"MIME Type: {report_artifact.inline_data.mime_type}")
              # Process the report_artifact.inline_data.data (bytes)
              pdf_bytes = report_artifact.inline_data.data
              print(f"Report size: {len(pdf_bytes)} bytes.")
              # ... further processing ...
          else:
              print(f"Python artifact '{filename}' not found.")

          # Example: Load a specific version (if version 0 exists)
          # specific_version_artifact = await context.load_artifact(filename=filename, version=0)
          # if specific_version_artifact:
          #     print(f"Loaded version 0 of '{filename}'.")

      except ValueError as e:
          print(f"Error loading Python artifact: {e}. Is ArtifactService configured?")
      except Exception as e:
          # Handle potential storage errors
          print(f"An unexpected error occurred during Python artifact load: {e}")

  # --- Example Usage Concept (Python) ---
  # async def main_py():
  #   callback_context: CallbackContext = ... # obtain context
  #   await process_latest_report_py(callback_context)
  ```

  ```typescript
  import {Context} from '@google/adk';

  async function processLatestReport(context: Context): Promise<void> {
    /** Loads the latest report artifact and processes its data. */
    const filename = 'generated_report.pdf';
    try {
      // Load the latest version
      const reportArtifact = await context.loadArtifact(filename);

      if (reportArtifact?.inlineData) {
        console.log(`Successfully loaded latest TypeScript artifact '${filename}'.`);
        console.log(`MIME Type: ${reportArtifact.inlineData.mimeType}`);
        // Process the reportArtifact.inlineData.data (base64 string)
        const pdfData = Buffer.from(reportArtifact.inlineData.data || '', 'base64');
        console.log(`Report size: ${pdfData.length} bytes.`);
        // ... further processing ...
      } else {
        console.log(`TypeScript artifact '${filename}' not found.`);
      }
    } catch (e: any) {
      console.error(
        `Error loading TypeScript artifact: ${e.message}. Is ArtifactService configured?`,
      );
    }
  }
  ```

  ```go
  import (
    "log"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/llm"
  )

  // loadArtifactsCallback is a BeforeModel callback that loads a specific artifact
  // and adds its content to the LLM request.
  func loadArtifactsCallback(ctx agent.CallbackContext, req *model.LLMRequest) (*model.LLMResponse, error) {
      log.Println("[Callback] loadArtifactsCallback triggered.")
      // In a real app, you would parse the user's request to find a filename.
      // For this example, we'll hardcode a filename to demonstrate.
      const filenameToLoad = "generated_report.pdf"

      // Load the artifact from the artifact service.
      loadedPartResponse, err := ctx.Artifacts().Load(ctx, filenameToLoad)
      if err != nil {
          log.Printf("Callback could not load artifact '%s': %v", filenameToLoad, err)
          return nil, nil // File not found or error, continue to model.
      }

      loadedPart := loadedPartResponse.Part

      log.Printf("Callback successfully loaded artifact '%s'.", filenameToLoad)

      // Ensure there's at least one content in the request to append to.
      if len(req.Contents) == 0 {
          req.Contents = []*genai.Content{{Parts: []*genai.Part{
              genai.NewPartFromText("SYSTEM: The following file is provided for context:\n"),
          }}}
      }

      // Add the loaded artifact to the request for the model.
      lastContent := req.Contents[len(req.Contents)-1]
      lastContent.Parts = append(lastContent.Parts, loadedPart)
      log.Printf("Added artifact '%s' to LLM request.", filenameToLoad)

      // Return nil to continue to the next callback or the model.
      return nil, nil // Continue to next callback or LLM call
  }
  ```

  ```java
  import com.google.adk.artifacts.BaseArtifactService;
  import com.google.genai.types.Part;
  import io.reactivex.rxjava3.core.MaybeObserver;
  import io.reactivex.rxjava3.disposables.Disposable;
  import java.util.Optional;

  public class MyArtifactLoaderService {

      private final BaseArtifactService artifactService;
      private final String appName;

      public MyArtifactLoaderService(BaseArtifactService artifactService, String appName) {
          this.artifactService = artifactService;
          this.appName = appName;
      }

      public void processLatestReportJava(String userId, String sessionId, String filename) {
          // Load the latest version by passing Optional.empty() for the version
          artifactService
                  .loadArtifact(appName, userId, sessionId, filename, Optional.empty())
                  .subscribe(
                          new MaybeObserver<Part>() {
                              @Override
                              public void onSubscribe(Disposable d) {
                                  // Optional: handle subscription
                              }

                              @Override
                              public void onSuccess(Part reportArtifact) {
                                  System.out.println(
                                          "Successfully loaded latest Java artifact '" + filename + "'.");
                                  reportArtifact
                                          .inlineData()
                                          .ifPresent(
                                                  blob -> {
                                                      System.out.println(
                                                              "MIME Type: " + blob.mimeType().orElse("N/A"));
                                                      byte[] pdfBytes = blob.data().orElse(new byte[0]);
                                                      System.out.println("Report size: " + pdfBytes.length + " bytes.");
                                                      // ... further processing of pdfBytes ...
                                                  });
                              }

                              @Override
                              public void onError(Throwable e) {
                                  // Handle potential storage errors or other exceptions
                                  System.err.println(
                                          "An error occurred during Java artifact load for '"
                                                  + filename
                                                  + "': "
                                                  + e.getMessage());
                              }

                              @Override
                              public void onComplete() {
                                  // Called if the artifact (latest version) is not found
                                  System.out.println("Java artifact '" + filename + "' not found.");
                              }
                          });

          // Example: Load a specific version (e.g., version 0)
          /*
          artifactService.loadArtifact(appName, userId, sessionId, filename, Optional.of(0))
              .subscribe(part -> {
                  System.out.println("Loaded version 0 of Java artifact '" + filename + "'.");
              }, throwable -> {
                  System.err.println("Error loading version 0 of '" + filename + "': " + throwable.getMessage());
              }, () -> {
                  System.out.println("Version 0 of Java artifact '" + filename + "' not found.");
              });
          */
      }

      // --- Example Usage Concept (Java) ---
      public static void main(String[] args) {
          // BaseArtifactService service = new InMemoryArtifactService(); // Or GcsArtifactService
          // MyArtifactLoaderService loader = new MyArtifactLoaderService(service, "myJavaApp");
          // loader.processLatestReportJava("user123", "sessionABC", "java_report.pdf");
          // Due to async nature, in a real app, ensure program waits or handles completion.
      }
  }
  ```

#### Listing Artifact Filenames

- **Code Example:**

  ```python
  from google.adk.tools.tool_context import ToolContext

  def list_user_files_py(tool_context: ToolContext) -> str:
      """Tool to list available artifacts for the user."""
      try:
          available_files = await tool_context.list_artifacts()
          if not available_files:
              return "You have no saved artifacts."
          else:
              # Format the list for the user/LLM
              file_list_str = "\n".join([f"- {fname}" for fname in available_files])
              return f"Here are your available Python artifacts:\n{file_list_str}"
      except ValueError as e:
          print(f"Error listing Python artifacts: {e}. Is ArtifactService configured?")
          return "Error: Could not list Python artifacts."
      except Exception as e:
          print(f"An unexpected error occurred during Python artifact list: {e}")
          return "Error: An unexpected error occurred while listing Python artifacts."

  # This function would typically be wrapped in a FunctionTool
  # from google.adk.tools import FunctionTool
  # list_files_tool = FunctionTool(func=list_user_files_py)
  ```

  ```typescript
  import {Context} from '@google/adk';

  async function listUserFiles(context: Context): Promise<string> {
    /** Tool to list available artifacts for the user. */
    try {
      const availableFiles = await context.listArtifacts();
      if (!availableFiles || availableFiles.length === 0) {
        return 'You have no saved artifacts.';
      } else {
        // Format the list for the user/LLM
        const fileListStr = availableFiles.map((fname) => `- ${fname}`).join('\n');
        return `Here are your available TypeScript artifacts:\n${fileListStr}`;
      }
    } catch (e: any) {
      console.error(
        `Error listing TypeScript artifacts: ${e.message}. Is ArtifactService configured?`,
      );
      return 'Error: Could not list TypeScript artifacts.';
    }
  }
  ```

  ```go
  import (
    "fmt"
    "log"
    "strings"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/llm"
    "google.golang.org/genai"
  )

  // listUserFilesCallback is a BeforeModel callback that lists available artifacts
  // and adds the list as context to the LLM request.
  func listUserFilesCallback(ctx agent.CallbackContext, req *model.LLMRequest) (*model.LLMResponse, error) {
      log.Println("[Callback] listUserFilesCallback triggered.")
      // List the available artifacts from the artifact service.
      listResponse, err := ctx.Artifacts().List(ctx)
      if err != nil {
          log.Printf("An unexpected error occurred during Go artifact list: %v", err)
          return nil, nil // Continue, but log the error.
      }

      availableFiles := listResponse.FileNames

      log.Printf("Found %d available files.", len(availableFiles))

      // If there are available files, add them to the LLM request.
      if len(availableFiles) > 0 {
          var fileListStr strings.Builder
          fileListStr.WriteString("SYSTEM: The following files are available:\n")
          for _, fname := range availableFiles {
              fileListStr.WriteString(fmt.Sprintf("- %s\n", fname))
          }
          // Prepend this information to the user's request for the model.
          if len(req.Contents) > 0 {
              lastContent := req.Contents[len(req.Contents)-1]
              if len(lastContent.Parts) > 0 {
                  fileListStr.WriteString("\n") // Add a newline for separation.
                  lastContent.Parts[0] = genai.NewPartFromText(fileListStr.String() + lastContent.Parts[0].Text)
                  log.Println("Added file list to LLM request context.")
              }
          }
          log.Printf("Available files:\n%s", fileListStr.String())
      } else {
          log.Println("No available files found to list.")
      }

      // Return nil to continue to the next callback or the model.
      return nil, nil // Continue to next callback or LLM call
  }
  ```

  ```java
  import com.google.adk.artifacts.BaseArtifactService;
  import com.google.adk.artifacts.ListArtifactsResponse;
  import com.google.common.collect.ImmutableList;
  import io.reactivex.rxjava3.core.SingleObserver;
  import io.reactivex.rxjava3.disposables.Disposable;

  public class MyArtifactListerService {

      private final BaseArtifactService artifactService;
      private final String appName;

      public MyArtifactListerService(BaseArtifactService artifactService, String appName) {
          this.artifactService = artifactService;
          this.appName = appName;
      }

      // Example method that might be called by a tool or agent logic
      public void listUserFilesJava(String userId, String sessionId) {
          artifactService
                  .listArtifactKeys(appName, userId, sessionId)
                  .subscribe(
                          new SingleObserver<ListArtifactsResponse>() {
                              @Override
                              public void onSubscribe(Disposable d) {
                                  // Optional: handle subscription
                              }

                              @Override
                              public void onSuccess(ListArtifactsResponse response) {
                                  ImmutableList<String> availableFiles = response.filenames();
                                  if (availableFiles.isEmpty()) {
                                      System.out.println(
                                              "User "
                                                      + userId
                                                      + " in session "
                                                      + sessionId
                                                      + " has no saved Java artifacts.");
                                  } else {
                                      StringBuilder fileListStr =
                                              new StringBuilder(
                                                      "Here are the available Java artifacts for user "
                                                              + userId
                                                              + " in session "
                                                              + sessionId
                                                              + ":\n");
                                      for (String fname : availableFiles) {
                                          fileListStr.append("- ").append(fname).append("\n");
                                      }
                                      System.out.println(fileListStr.toString());
                                  }
                              }

                              @Override
                              public void onError(Throwable e) {
                                  System.err.println(
                                          "Error listing Java artifacts for user "
                                                  + userId
                                                  + " in session "
                                                  + sessionId
                                                  + ": "
                                                  + e.getMessage());
                                  // In a real application, you might return an error message to the user/LLM
                              }
                          });
      }

      // --- Example Usage Concept (Java) ---
      public static void main(String[] args) {
          // BaseArtifactService service = new InMemoryArtifactService(); // Or GcsArtifactService
          // MyArtifactListerService lister = new MyArtifactListerService(service, "myJavaApp");
          // lister.listUserFilesJava("user123", "sessionABC");
          // Due to async nature, in a real app, ensure program waits or handles completion.
      }
  }
  ```

These methods for saving, loading, and listing provide a convenient and consistent way to manage binary data persistence within ADK, whether using Python's context objects or directly interacting with the `BaseArtifactService` in Java, regardless of the chosen backend storage implementation.

## Available Implementations

ADK provides concrete implementations of the `BaseArtifactService` interface, offering different storage backends suitable for various development stages and deployment needs. These implementations handle the details of storing, versioning, and retrieving artifact data based on the `app_name`, `user_id`, `session_id`, and `filename` (including the `user:` namespace prefix).

### InMemoryArtifactService

- **Storage Mechanism:**

  - Python: Uses a Python dictionary (`self.artifacts`) held in the application's memory. The dictionary keys represent the artifact path, and the values are lists of `types.Part`, where each list element is a version.
  - Java: Uses nested `HashMap` instances (`private final Map<String, Map<String, Map<String, Map<String, List<Part>>>>> artifacts;`) held in memory. The keys at each level are `appName`, `userId`, `sessionId`, and `filename` respectively. The innermost `List<Part>` stores the versions of the artifact, where the list index corresponds to the version number.

- **Key Features:**

  - **Simplicity:** Requires no external setup or dependencies beyond the core ADK library.
  - **Speed:** Operations are typically very fast as they involve in-memory map/dictionary lookups and list manipulations.
  - **Ephemeral:** All stored artifacts are **lost** when the application process terminates. Data does not persist between application restarts.

- **Use Cases:**

  - Ideal for local development and testing where persistence is not required.
  - Suitable for short-lived demonstrations or scenarios where artifact data is purely temporary within a single run of the application.

- **Instantiation:**

  ```python
  from google.adk.artifacts import InMemoryArtifactService

  # Simply instantiate the class
  in_memory_service_py = InMemoryArtifactService()

  # Then pass it to the Runner
  # runner = Runner(..., artifact_service=in_memory_service_py)
  ```

  ```typescript
  import {InMemoryArtifactService} from '@google/adk';

  // Simply instantiate the class
  const inMemoryService = new InMemoryArtifactService();

  // This instance would then be provided to your Runner.
  // const runner = new Runner({
  //   /* other services */,
  //   artifactService: inMemoryService
  // });
  ```

  ```go
  import (
    "google.golang.org/adk/artifactservice"
  )

  // Simply instantiate the service
  artifactService := artifact.InMemoryService()
  log.Printf("InMemoryArtifactService (Go) instantiated: %T", artifactService)

  // Use the service in your runner
  // r, _ := runner.New(runner.Config{
  //  Agent:           agent,
  //  AppName:         "my_app",
  //  SessionService:  sessionService,
  //  ArtifactService: artifactService,
  // })
  ```

  ```java
  import com.google.adk.artifacts.BaseArtifactService;
  import com.google.adk.artifacts.InMemoryArtifactService;

  public class InMemoryServiceSetup {
      public static void main(String[] args) {
          // Simply instantiate the class
          BaseArtifactService inMemoryServiceJava = new InMemoryArtifactService();

          System.out.println("InMemoryArtifactService (Java) instantiated: " + inMemoryServiceJava.getClass().getName());

          // This instance would then be provided to your Runner.
          // Runner runner = new Runner(
          //     /* other services */,
          //     inMemoryServiceJava
          // );
      }
  }
  ```

### GcsArtifactService

- **Storage Mechanism:** Leverages Google Cloud Storage (GCS) for persistent artifact storage. Each version of an artifact is stored as a separate object (blob) within a specified GCS bucket.

- **Object Naming Convention:** It constructs GCS object names (blob names) using a hierarchical path structure.

- **Key Features:**

  - **Persistence:** Artifacts stored in GCS persist across application restarts and deployments.
  - **Scalability:** Leverages the scalability and durability of Google Cloud Storage.
  - **Versioning:** Explicitly stores each version as a distinct GCS object. The `saveArtifact` method in `GcsArtifactService`.
  - **Permissions Required:** The application environment needs appropriate credentials (e.g., Application Default Credentials) and IAM permissions to read from and write to the specified GCS bucket.

- **Use Cases:**

  - Production environments requiring persistent artifact storage.
  - Scenarios where artifacts need to be shared across different application instances or services (by accessing the same GCS bucket).
  - Applications needing long-term storage and retrieval of user or session data.

- **Instantiation:**

  ```python
  from google.adk.artifacts import GcsArtifactService

  # Specify the GCS bucket name
  gcs_bucket_name_py = "your-gcs-bucket-for-adk-artifacts" # Replace with your bucket name

  try:
      gcs_service_py = GcsArtifactService(bucket_name=gcs_bucket_name_py)
      print(f"Python GcsArtifactService initialized for bucket: {gcs_bucket_name_py}")
      # Ensure your environment has credentials to access this bucket.
      # e.g., via Application Default Credentials (ADC)

      # Then pass it to the Runner
      # runner = Runner(..., artifact_service=gcs_service_py)

  except Exception as e:
      # Catch potential errors during GCS client initialization (e.g., auth issues)
      print(f"Error initializing Python GcsArtifactService: {e}")
      # Handle the error appropriately - maybe fall back to InMemory or raise
  ```

  ```typescript
  import {GcsArtifactService} from '@google/adk';

  // Specify the GCS bucket name.
  const gcsBucketName = 'your-gcs-bucket-for-adk-artifacts';

  try {
    const gcsService = new GcsArtifactService(gcsBucketName);
    console.log(`TypeScript GcsArtifactService initialized for bucket: ${gcsBucketName}`);
    // Ensure your environment has credentials to access this bucket.
    // e.g., via Application Default Credentials (ADC).

    // Then pass it to the Runner.
    // const runner = new Runner({..., artifactService: gcsService});
  } catch (e: any) {
    // Catch potential errors during GCS client initialization (e.g., auth issues).
    console.error(`Error initializing TypeScript GcsArtifactService: ${e.message}`);
  }
  ```

  ```java
  import com.google.adk.artifacts.BaseArtifactService;
  import com.google.adk.artifacts.GcsArtifactService;
  import com.google.cloud.storage.Storage;
  import com.google.cloud.storage.StorageOptions;

  public class GcsServiceSetup {
    public static void main(String[] args) {
      // Specify the GCS bucket name
      String gcsBucketNameJava = "your-gcs-bucket-for-adk-artifacts"; // Replace with your bucket name

      try {
        // Initialize the GCS Storage client.
        // This will use Application Default Credentials by default.
        // Ensure the environment is configured correctly (e.g., GOOGLE_APPLICATION_CREDENTIALS).
        Storage storageClient = StorageOptions.getDefaultInstance().getService();

        // Instantiate the GcsArtifactService
        BaseArtifactService gcsServiceJava =
            new GcsArtifactService(gcsBucketNameJava, storageClient);

        System.out.println(
            "Java GcsArtifactService initialized for bucket: " + gcsBucketNameJava);

        // This instance would then be provided to your Runner.
        // Runner runner = new Runner(
        //     /* other services */,
        //     gcsServiceJava
        // );

      } catch (Exception e) {
        // Catch potential errors during GCS client initialization (e.g., auth, permissions)
        System.err.println("Error initializing Java GcsArtifactService: " + e.getMessage());
        e.printStackTrace();
        // Handle the error appropriately
      }
    }
  }
  ```

Choosing the appropriate `ArtifactService` implementation depends on your application's requirements for data persistence, scalability, and operational environment.

## Best Practices

To use artifacts effectively and maintainably:

- **Choose the Right Service:** Use `InMemoryArtifactService` for rapid prototyping, testing, and scenarios where persistence isn't needed. Use `GcsArtifactService` (or implement your own `BaseArtifactService` for other backends) for production environments requiring data persistence and scalability.
- **Meaningful Filenames:** Use clear, descriptive filenames. Including relevant extensions (`.pdf`, `.png`, `.wav`) helps humans understand the content, even though the `mime_type` dictates programmatic handling. Establish conventions for temporary vs. persistent artifact names.
- **Specify Correct MIME Types:** Always provide an accurate `mime_type` when creating the `types.Part` for `save_artifact`. This is critical for applications or tools that later `load_artifact` to interpret the `bytes` data correctly. Use standard IANA MIME types where possible.
- **Understand Versioning:** Remember that `load_artifact()` without a specific `version` argument retrieves the *latest* version. If your logic depends on a specific historical version of an artifact, be sure to provide the integer version number when loading.
- **Use Namespacing (`user:`) Deliberately:** Only use the `"user:"` prefix for filenames when the data truly belongs to the user and should be accessible across all their sessions. For data specific to a single conversation or session, use regular filenames without the prefix.
- **Error Handling:**
  - Always check if an `artifact_service` is actually configured before calling context methods (`save_artifact`, `load_artifact`, `list_artifacts`) – they will raise a `ValueError` if the service is `None`.
  - Check the return value of `load_artifact`, as it will be `None` if the artifact or version doesn't exist. Don't assume it always returns a `Part`.
  - Be prepared to handle exceptions from the underlying storage service, especially with `GcsArtifactService` (e.g., `google.api_core.exceptions.Forbidden` for permission issues, `NotFound` if the bucket doesn't exist, network errors).
- **Size Considerations:** Artifacts are suitable for typical file sizes, but be mindful of potential costs and performance impacts with extremely large files, especially with cloud storage. `InMemoryArtifactService` can consume significant memory if storing many large artifacts. Evaluate if very large data might be better handled through direct GCS links or other specialized storage solutions rather than passing entire byte arrays in-memory.
- **Cleanup Strategy:** For persistent storage like `GcsArtifactService`, artifacts remain until explicitly deleted. If artifacts represent temporary data or have a limited lifespan, implement a strategy for cleanup. This might involve:
  - Using GCS lifecycle policies on the bucket.
  - Building specific tools or administrative functions that utilize the `artifact_service.delete_artifact` method (note: delete is *not* exposed via context objects for safety).
  - Carefully managing filenames to allow pattern-based deletion if needed.

# Events

Supported in ADKPython v0.1.0TypeScript v0.2.0Go v0.1.0Java v0.1.0

Events are the fundamental units of information flow within the Agent Development Kit (ADK). They represent every significant occurrence during an agent's interaction lifecycle, from initial user input to the final response and all the steps in between. Understanding events is crucial because they are the primary way components communicate, state is managed, and control flow is directed.

## What Events Are and Why They Matter

An `Event` in ADK is an immutable record representing a specific point in the agent's execution. It captures user messages, agent replies, requests to use tools (function calls), tool results, state changes, control signals, and errors.

Technically, it's an instance of the `google.adk.events.Event` class, which builds upon the basic `LlmResponse` structure by adding essential ADK-specific metadata and an `actions` payload.

```python
# Conceptual Structure of an Event (Python)
# from google.adk.events import Event, EventActions
# from google.genai import types

# class Event(LlmResponse): # Simplified view
#     # --- LlmResponse fields ---
#     content: Optional[types.Content]
#     partial: Optional[bool]
#     # ... other response fields ...

#     # --- ADK specific additions ---
#     author: str          # 'user' or agent name
#     invocation_id: str   # ID for the whole interaction run
#     id: str              # Unique ID for this specific event
#     timestamp: float     # Creation time
#     actions: EventActions # Important for side-effects & control
#     branch: Optional[str] # Hierarchy path
#     # ...
```

In TypeScript, this is an interface of type `Event`.

```typescript
import {Content} from '@google/genai';

/**
 * Conceptual Structure of an Event (TypeScript)
 */
export interface Event extends LlmResponse {
  /** Unique ID for this specific event. */
  id: string;
  /** ID for the whole interaction run. */
  invocationId: string;
  /** 'user' or agent name. */
  author?: string;
  /** Important for side-effects & control. */
  actions: EventActions;
  /** Creation time. */
  timestamp: number;
  /** Is it streaming output? */
  partial?: boolean;
  /** Is the turn finished? */
  turnComplete?: boolean;
  /** Hierarchy path. */
  branch?: string;
  /** List of IDs for long-running tools. */
  longRunningToolIds?: string[];
  /** The content of the response. */
  content?: Content;
  // ... other LlmResponse fields like errorCode, errorMessage
}
```

In Go, this is a struct of type `google.golang.org/adk/session.Event`.

```go
// Conceptual Structure of an Event (Go - See session/session.go)
// Simplified view based on the session.Event struct
type Event struct {
    // --- Fields from embedded model.LLMResponse ---
    model.LLMResponse

    // --- ADK specific additions ---
    Author       string         // 'user' or agent name
    InvocationID string         // ID for the whole interaction run
    ID           string         // Unique ID for this specific event
    Timestamp    time.Time      // Creation time
    Actions      EventActions   // Important for side-effects & control
    Branch       string         // Hierarchy path
    // ... other fields
}

// model.LLMResponse contains the Content field
type LLMResponse struct {
    Content *genai.Content
    // ... other fields
}
```

In Java, this is an instance of the `com.google.adk.events.Event` class. It also builds upon a basic response structure by adding essential ADK-specific metadata and an `actions` payload.

```java
// Conceptual Structure of an Event (Java - See com.google.adk.events.Event.java)
// Simplified view based on the provided com.google.adk.events.Event.java
// public class Event extends JsonBaseModel {
//     // --- Fields analogous to LlmResponse ---
//     private Optional<Content> content;
//     private Optional<Boolean> partial;
//     // ... other response fields like errorCode, errorMessage ...

//     // --- ADK specific additions ---
//     private String author;         // 'user' or agent name
//     private String invocationId;   // ID for the whole interaction run
//     private String id;             // Unique ID for this specific event
//     private long timestamp;        // Creation time (epoch milliseconds)
//     private EventActions actions;  // Important for side-effects & control
//     private Optional<String> branch; // Hierarchy path
//     // ... other fields like turnComplete, longRunningToolIds etc.
// }
```

Events are central to ADK's operation for several key reasons:

1. **Communication:** They serve as the standard message format between the user interface, the `Runner`, agents, the LLM, and tools. Everything flows as an `Event`.
1. **Signaling State & Artifact Changes:** Events carry instructions for state modifications and track artifact updates. The `SessionService` uses these signals to ensure persistence. In Python changes are signaled via `event.actions.state_delta` and `event.actions.artifact_delta`.
1. **Control Flow:** Specific fields like `event.actions.transfer_to_agent` or `event.actions.escalate` act as signals that direct the framework, determining which agent runs next or if a loop should terminate.
1. **History & Observability:** The sequence of events recorded in `session.events` provides a complete, chronological history of an interaction, invaluable for debugging, auditing, and understanding agent behavior step-by-step.

In essence, the entire process, from a user's query to the agent's final answer, is orchestrated through the generation, interpretation, and processing of `Event` objects.

## Understanding and Using Events

As a developer, you'll primarily interact with the stream of events yielded by the `Runner`. Here's how to understand and extract information from them:

Note

The specific parameters or method names for the primitives may vary slightly by SDK language (e.g., `event.content()` in Python, `event.content().get().parts()` in Java). Refer to the language-specific API documentation for details.

### Identifying Event Origin and Type

Quickly determine what an event represents by checking:

- **Who sent it? (`event.author`)**

  - `'user'`: Indicates input directly from the end-user.
  - `'AgentName'`: Indicates output or action from a specific agent (e.g., `'WeatherAgent'`, `'SummarizerAgent'`).

- **What's the main payload? (`event.content` and `event.content.parts`)**

  - **Text:** Indicates a conversational message. For Python, check if `event.content.parts[0].text` exists. For Java, check if `event.content()` is present, its `parts()` are present and not empty, and the first part's `text()` is present.
  - **Tool Call Request:** Check `event.get_function_calls()`. If not empty, the LLM is asking to execute one or more tools. Each item in the list has `.name` and `.args`.
  - **Tool Result:** Check `event.get_function_responses()`. If not empty, this event carries the result(s) from tool execution(s). Each item has `.name` and `.response` (the dictionary returned by the tool). *Note:* For history structuring, the `role` inside the `content` is often `'user'`, but the event `author` is typically the agent that requested the tool call.

- **Is it streaming output? (`event.partial`)** Indicates whether this is an incomplete chunk of text from the LLM.

  - `True`: More text will follow.
  - `False` or `None`/`Optional.empty()`: This part of the content is complete (though the overall turn might not be finished if `turn_complete` is also false).

```python
# Pseudocode: Basic event identification (Python)
# async for event in runner.run_async(...):
#     print(f"Event from: {event.author}")
#
#     if event.content and event.content.parts:
#         if event.get_function_calls():
#             print("  Type: Tool Call Request")
#         elif event.get_function_responses():
#             print("  Type: Tool Result")
#         elif event.content.parts[0].text:
#             if event.partial:
#                 print("  Type: Streaming Text Chunk")
#             else:
#                 print("  Type: Complete Text Message")
#         else:
#             print("  Type: Other Content (e.g., code result)")
#     elif event.actions and (event.actions.state_delta or event.actions.artifact_delta):
#         print("  Type: State/Artifact Update")
#     else:
#         print("  Type: Control Signal or Other")
```

```typescript
// Pseudocode: Basic event identification (TypeScript)
import {
  Event,
  getFunctionCalls,
  getFunctionResponses
} from '@google/adk';

export async function processEvents(runnerEvents: AsyncIterable<Event>) {
  for await (const event of runnerEvents) {
    console.log(`Event from: ${event.author}`);

    if (event.content && event.content.parts && event.content.parts.length > 0) {
      if (getFunctionCalls(event).length > 0) {
        console.log('  Type: Tool Call Request');
      } else if (getFunctionResponses(event).length > 0) {
        console.log('  Type: Tool Result');
      } else if (event.content.parts[0].text) {
        if (event.partial) {
          console.log('  Type: Streaming Text Chunk');
        } else {
          console.log('  Type: Complete Text Message');
        }
      } else {
        console.log('  Type: Other Content (e.g., code result)');
      }
    } else if (
      event.actions &&
      (Object.keys(event.actions.stateDelta).length > 0 ||
        Object.keys(event.actions.artifactDelta).length > 0)
    ) {
      console.log('  Type: State/Artifact Update');
    } else {
      console.log('  Type: Control Signal or Other');
    }
  }
}
```

```go
  // Pseudocode: Basic event identification (Go)
import (
  "fmt"
  "google.golang.org/adk/session"
  "google.golang.org/genai"
)

func hasFunctionCalls(content *genai.Content) bool {
  if content == nil {
    return false
  }
  for _, part := range content.Parts {
    if part.FunctionCall != nil {
      return true
    }
  }
  return false
}

func hasFunctionResponses(content *genai.Content) bool {
  if content == nil {
    return false
  }
  for _, part := range content.Parts {
    if part.FunctionResponse != nil {
      return true
    }
  }
  return false
}

func processEvents(events <-chan *session.Event) {
  for event := range events {
    fmt.Printf("Event from: %s\n", event.Author)

    if event.LLMResponse != nil && event.LLMResponse.Content != nil {
      if hasFunctionCalls(event.LLMResponse.Content) {
        fmt.Println("  Type: Tool Call Request")
      } else if hasFunctionResponses(event.LLMResponse.Content) {
        fmt.Println("  Type: Tool Result")
      } else if len(event.LLMResponse.Content.Parts) > 0 {
        if event.LLMResponse.Content.Parts[0].Text != "" {
          if event.LLMResponse.Partial {
            fmt.Println("  Type: Streaming Text Chunk")
          } else {
            fmt.Println("  Type: Complete Text Message")
          }
        } else {
          fmt.Println("  Type: Other Content (e.g., code result)")
        }
      }
    } else if len(event.Actions.StateDelta) > 0 {
      fmt.Println("  Type: State Update")
    } else {
      fmt.Println("  Type: Control Signal or Other")
    }
  }
}
```

```java
// Pseudocode: Basic event identification (Java)
// import com.google.genai.types.Content;
// import com.google.adk.events.Event;
// import com.google.adk.events.EventActions;

// runner.runAsync(...).forEach(event -> { // Assuming a synchronous stream or reactive stream
//     System.out.println("Event from: " + event.author());
//
//     if (event.content().isPresent()) {
//         Content content = event.content().get();
//         if (!event.functionCalls().isEmpty()) {
//             System.out.println("  Type: Tool Call Request");
//         } else if (!event.functionResponses().isEmpty()) {
//             System.out.println("  Type: Tool Result");
//         } else if (content.parts().isPresent() && !content.parts().get().isEmpty() &&
//                    content.parts().get().get(0).text().isPresent()) {
//             if (event.partial().orElse(false)) {
//                 System.out.println("  Type: Streaming Text Chunk");
//             } else {
//                 System.out.println("  Type: Complete Text Message");
//             }
//         } else {
//             System.out.println("  Type: Other Content (e.g., code result)");
//         }
//     } else if (event.actions() != null &&
//                ((event.actions().stateDelta() != null && !event.actions().stateDelta().isEmpty()) ||
//                 (event.actions().artifactDelta() != null && !event.actions().artifactDelta().isEmpty()))) {
//         System.out.println("  Type: State/Artifact Update");
//     } else {
//         System.out.println("  Type: Control Signal or Other");
//     }
// });
```

### Extracting Key Information

Once you know the event type, access the relevant data:

- **Text Content:** Always check for the presence of content and parts before accessing text. In Python its `text = event.content.parts[0].text`.

- **Function Call Details:**

  ```python
  calls = event.get_function_calls()
  if calls:
      for call in calls:
          tool_name = call.name
          arguments = call.args # This is usually a dictionary
          print(f"  Tool: {tool_name}, Args: {arguments}")
          # Application might dispatch execution based on this
  ```

  ```typescript
  export function handleFunctionCalls(event: Event) {
      const calls = getFunctionCalls(event);
      if (calls.length > 0) {
          for (const call of calls) {
              const toolName = call.name;
              const argumentsDict = call.args; // This is an object
              console.log(`  Tool: ${toolName}, Args: ${JSON.stringify(argumentsDict)}`);
          }
      }
  }
  ```

  ```go
  import (
      "fmt"
      "google.golang.org/adk/session"
      "google.golang.org/genai"
  )

  func handleFunctionCalls(event *session.Event) {
      if event.LLMResponse == nil || event.LLMResponse.Content == nil {
          return
      }
      calls := event.Content.FunctionCalls()
      if len(calls) > 0 {
          for _, call := range calls {
              toolName := call.Name
              arguments := call.Args
              fmt.Printf("  Tool: %s, Args: %v\n", toolName, arguments)
              // Application might dispatch execution based on this
          }
      }
  }
  ```

  ```java
  import com.google.genai.types.FunctionCall;
  import com.google.common.collect.ImmutableList;
  import java.util.Map;

  ImmutableList<FunctionCall> calls = event.functionCalls(); // from Event.java
  if (!calls.isEmpty()) {
    for (FunctionCall call : calls) {
      String toolName = call.name().get();
      // args is Optional<Map<String, Object>>
      Map<String, Object> arguments = call.args().get();
             System.out.println("  Tool: " + toolName + ", Args: " + arguments);
      // Application might dispatch execution based on this
    }
  }
  ```

- **Function Response Details:**

  ```python
  responses = event.get_function_responses()
  if responses:
      for response in responses:
          tool_name = response.name
          result_dict = response.response # The dictionary returned by the tool
          print(f"  Tool Result: {tool_name} -> {result_dict}")
  ```

  ```typescript
  // Pseudocode: Handle function responses (TypeScript)
  export function handleFunctionResponses(event: Event) {
      const responses = getFunctionResponses(event);
      if (responses.length > 0) {
          for (const response of responses) {
              const toolName = response.name;
              const result = response.response; // The object returned by the tool
              console.log(`  Tool Result: ${toolName} -> ${JSON.stringify(result)}`);
          }
      }
  }
  ```

  ```go
  import (
      "fmt"
      "google.golang.org/adk/session"
      "google.golang.org/genai"
  )

  func handleFunctionResponses(event *session.Event) {
      if event.LLMResponse == nil || event.LLMResponse.Content == nil {
          return
      }
      responses := event.Content.FunctionResponses()
      if len(responses) > 0 {
          for _, response := range responses {
              toolName := response.Name
              result := response.Response
              fmt.Printf("  Tool Result: %s -> %v\n", toolName, result)
          }
      }
  }
  ```

  ```java
  import com.google.genai.types.FunctionResponse;
  import com.google.common.collect.ImmutableList;
  import java.util.Map;

  ImmutableList<FunctionResponse> responses = event.functionResponses(); // from Event.java
  if (!responses.isEmpty()) {
      for (FunctionResponse response : responses) {
          String toolName = response.name().get();
          Map<String, String> result= response.response().get(); // Check before getting the response
          System.out.println("  Tool Result: " + toolName + " -> " + result);
      }
  }
  ```

- **Identifiers:**

  - `event.id`: Unique ID for this specific event instance.
  - `event.invocation_id`: ID for the entire user-request-to-final-response cycle this event belongs to. Useful for logging and tracing.

### Detecting Actions and Side Effects

The `event.actions` object signals changes that occurred or should occur. Always check if `event.actions` and it's fields/ methods exists before accessing them.

- **State Changes:** Gives you a collection of key-value pairs that were modified in the session state during the step that produced this event.

  `delta = event.actions.state_delta` (a dictionary of `{key: value}` pairs).

  ```python
  if event.actions and event.actions.state_delta:
      print(f"  State changes: {event.actions.state_delta}")
      # Update local UI or application state if necessary
  ```

  `delta = event.actions.stateDelta` (an object of `{key: value}` pairs).

  ```typescript
  export function handleStateChanges(event: Event) {
      if (event.actions && Object.keys(event.actions.stateDelta).length > 0) {
          console.log(`  State changes: ${JSON.stringify(event.actions.stateDelta)}`);
          // Update local UI or application state if necessary
      }
  }
  ```

  `delta := event.Actions.StateDelta` (a `map[string]any`)

  ```go
  import (
      "fmt"
      "google.golang.org/adk/session"
  )

  func handleStateChanges(event *session.Event) {
      if len(event.Actions.StateDelta) > 0 {
          fmt.Printf("  State changes: %v\n", event.Actions.StateDelta)
          // Update local UI or application state if necessary
      }
  }
  ```

  `ConcurrentMap<String, Object> delta = event.actions().stateDelta();`

  ```java
  import java.util.concurrent.ConcurrentMap;
  import com.google.adk.events.EventActions;

  EventActions actions = event.actions(); // Assuming event.actions() is not null
  if (actions != null && actions.stateDelta() != null && !actions.stateDelta().isEmpty()) {
      ConcurrentMap<String, Object> stateChanges = actions.stateDelta();
      System.out.println("  State changes: " + stateChanges);
      // Update local UI or application state if necessary
  }
  ```

- **Artifact Saves:** Gives you a collection indicating which artifacts were saved and their new version number (or relevant `Part` information).

  `artifact_changes = event.actions.artifact_delta` (a dictionary of `{filename: version}`).

  ```python
  if event.actions and event.actions.artifact_delta:
      print(f"  Artifacts saved: {event.actions.artifact_delta}")
      # UI might refresh an artifact list
  ```

  `artifact_changes = event.actions.artifactDelta` (an object of `{filename: version}`).

  ```typescript
  export function handleArtifactChanges(event: Event) {
      if (event.actions && Object.keys(event.actions.artifactDelta).length > 0) {
          console.log(`  Artifacts saved: ${JSON.stringify(event.actions.artifactDelta)}`);
          // UI might refresh an artifact list
      }
  }
  ```

  `artifactChanges := event.Actions.ArtifactDelta` (a `map[string]artifact.Artifact`)

  ```go
  import (
      "fmt"
      "google.golang.org/adk/artifact"
      "google.golang.org/adk/session"
  )

  func handleArtifactChanges(event *session.Event) {
      if len(event.Actions.ArtifactDelta) > 0 {
          fmt.Printf("  Artifacts saved: %v\n", event.Actions.ArtifactDelta)
          // UI might refresh an artifact list
          // Iterate through event.Actions.ArtifactDelta to get filename and artifact.Artifact details
          for filename, art := range event.Actions.ArtifactDelta {
              fmt.Printf("    Filename: %s, Version: %d, MIMEType: %s\n", filename, art.Version, art.MIMEType)
          }
      }
  }
  ```

  `ConcurrentMap<String, Part> artifactChanges = event.actions().artifactDelta();`

  ```java
  import java.util.concurrent.ConcurrentMap;
  import com.google.genai.types.Part;
  import com.google.adk.events.EventActions;

  EventActions actions = event.actions(); // Assuming event.actions() is not null
  if (actions != null && actions.artifactDelta() != null && !actions.artifactDelta().isEmpty()) {
      ConcurrentMap<String, Part> artifactChanges = actions.artifactDelta();
      System.out.println("  Artifacts saved: " + artifactChanges);
      // UI might refresh an artifact list
      // Iterate through artifactChanges.entrySet() to get filename and Part details
  }
  ```

- **Control Flow Signals:** Check boolean flags or string values:

  - `event.actions.transfer_to_agent` (string): Control should pass to the named agent.

  - `event.actions.escalate` (bool): A loop should terminate.

  - `event.actions.skip_summarization` (bool): A tool result should not be summarized by the LLM.

    ```python
    if event.actions:
        if event.actions.transfer_to_agent:
            print(f"  Signal: Transfer to {event.actions.transfer_to_agent}")
        if event.actions.escalate:
            print("  Signal: Escalate (terminate loop)")
        if event.actions.skip_summarization:
            print("  Signal: Skip summarization for tool result")
    ```

  - `event.actions.transferToAgent` (string): Control should pass to the named agent.

  - `event.actions.escalate` (boolean): A loop should terminate.

  - `event.actions.skipSummarization` (boolean): A tool result should not be summarized by the LLM.

    ```typescript
    export function handleControlFlow(event: Event) {
        if (event.actions) {
            if (event.actions.transferToAgent) {
                console.log(`  Signal: Transfer to ${event.actions.transferToAgent}`);
            }
            if (event.actions.escalate) {
                console.log('  Signal: Escalate (terminate loop)');
            }
            if (event.actions.skipSummarization) {
                console.log('  Signal: Skip summarization for tool result');
            }
        }
    }
    ```

  - `event.Actions.TransferToAgent` (string): Control should pass to the named agent.

  - `event.Actions.Escalate` (bool): A loop should terminate.

  - `event.Actions.SkipSummarization` (bool): A tool result should not be summarized by the LLM.

    ```go
    import (
        "fmt"
        "google.golang.org/adk/session"
    )

    func handleControlFlow(event *session.Event) {
        if event.Actions.TransferToAgent != "" {
            fmt.Printf("  Signal: Transfer to %s\n", event.Actions.TransferToAgent)
        }
        if event.Actions.Escalate {
            fmt.Println("  Signal: Escalate (terminate loop)")
        }
        if event.Actions.SkipSummarization {
            fmt.Println("  Signal: Skip summarization for tool result")
        }
    }
    ```

  - `event.actions().transferToAgent()` (returns `Optional<String>`): Control should pass to the named agent.

  - `event.actions().escalate()` (returns `Optional<Boolean>`): A loop should terminate.

  - `event.actions().skipSummarization()` (returns `Optional<Boolean>`): A tool result should not be summarized by the LLM.

  ```java
  import com.google.adk.events.EventActions;
  import java.util.Optional;

  EventActions actions = event.actions(); // Assuming event.actions() is not null
  if (actions != null) {
      Optional<String> transferAgent = actions.transferToAgent();
      if (transferAgent.isPresent()) {
          System.out.println("  Signal: Transfer to " + transferAgent.get());
      }

      Optional<Boolean> escalate = actions.escalate();
      if (escalate.orElse(false)) { // or escalate.isPresent() && escalate.get()
          System.out.println("  Signal: Escalate (terminate loop)");
      }

      Optional<Boolean> skipSummarization = actions.skipSummarization();
      if (skipSummarization.orElse(false)) { // or skipSummarization.isPresent() && skipSummarization.get()
          System.out.println("  Signal: Skip summarization for tool result");
      }
  }
  ```

### Determining if an Event is a "Final" Response

Use the built-in helper method `event.is_final_response()` to identify events suitable for display as the agent's complete output for a turn.

- **Purpose:** Filters out intermediate steps (like tool calls, partial streaming text, internal state updates) from the final user-facing message(s).

- **When `True`?**

  1. The event contains a tool result (`function_response`) and `skip_summarization` is `True`.
  1. The event contains a tool call (`function_call`) for a tool marked as `is_long_running=True`. In Java, check if the `longRunningToolIds` list is empty:
     - `event.longRunningToolIds().isPresent() && !event.longRunningToolIds().get().isEmpty()` is `true`.
  1. OR, **all** of the following are met:
     - No function calls (`get_function_calls()` is empty).
     - No function responses (`get_function_responses()` is empty).
     - Not a partial stream chunk (`partial` is not `True`).
     - Doesn't end with a code execution result that might need further processing/display.

- **Usage:** Filter the event stream in your application logic.

  ```python
  # Pseudocode: Handling final responses in application (Python)
  # full_response_text = ""
  # async for event in runner.run_async(...):
  #     # Accumulate streaming text if needed...
  #     if event.partial and event.content and event.content.parts and event.content.parts[0].text:
  #         full_response_text += event.content.parts[0].text
  #
  #     # Check if it's a final, displayable event
  #     if event.is_final_response():
  #         print("\n--- Final Output Detected ---")
  #         if event.content and event.content.parts and event.content.parts[0].text:
  #              # If it's the final part of a stream, use accumulated text
  #              final_text = full_response_text + (event.content.parts[0].text if not event.partial else "")
  #              print(f"Display to user: {final_text.strip()}")
  #              full_response_text = "" # Reset accumulator
  #         elif event.actions and event.actions.skip_summarization and event.get_function_responses():
  #              # Handle displaying the raw tool result if needed
  #              response_data = event.get_function_responses()[0].response
  #              print(f"Display raw tool result: {response_data}")
  #         elif hasattr(event, 'long_running_tool_ids') and event.long_running_tool_ids:
  #              print("Display message: Tool is running in background...")
  #         else:
  #              # Handle other types of final responses if applicable
  #              print("Display: Final non-textual response or signal.")
  ```

  ```typescript
  // Pseudocode: Handling final responses in application (TypeScript)
  import {
      Event,
      getFunctionResponses,
      isFinalResponse,
      stringifyContent
  } from '@google/adk';

  async function handleFinalResponses(runnerEvents: AsyncIterable<Event>) {
      let fullResponseText = '';

      for await (const event of runnerEvents) {
          // Accumulate streaming text if needed...
          if (event.partial) {
              fullResponseText += stringifyContent(event);
          }

          // Check if it's a final, displayable event
          if (isFinalResponse(event)) {
              console.log('\n--- Final Output Detected ---');

              const eventText = stringifyContent(event);
              if (fullResponseText || eventText) {
                  // If it's the final part of a stream (or a single message), use accumulated text
                  const finalText = fullResponseText + (event.partial ? '' : eventText);
                  console.log(`Display to user: ${finalText.trim()}`);
                  fullResponseText = ''; // Reset accumulator
              } else if (
                  event.actions?.skipSummarization &&
                  getFunctionResponses(event).length > 0
              ) {
                  // Handle displaying the raw tool result if needed
                  const responseData = getFunctionResponses(event)[0].response;
                  console.log(`Display raw tool result: ${JSON.stringify(responseData)}`);
              } else if (event.longRunningToolIds && event.longRunningToolIds.length > 0) {
                  console.log('Display message: Tool is running in background...');
              } else {
                  // Handle other types of final responses if applicable
                  console.log('Display: Final non-textual response or signal.');
              }
          }
      }
  }
  ```

  ```go
  // Pseudocode: Handling final responses in application (Go)
  import (
      "fmt"
      "strings"
      "google.golang.org/adk/session"
      "google.golang.org/genai"
  )

  // isFinalResponse checks if an event is a final response suitable for display.
  func isFinalResponse(event *session.Event) bool {
      if event.LLMResponse != nil {
          // Condition 1: Tool result with skip summarization.
          if event.LLMResponse.Content != nil && len(event.LLMResponse.Content.FunctionResponses()) > 0 && event.Actions.SkipSummarization {
              return true
          }
          // Condition 2: Long-running tool call.
          if len(event.LongRunningToolIDs) > 0 {
              return true
          }
          // Condition 3: A complete message without tool calls or responses.
          if (event.LLMResponse.Content == nil ||
              (len(event.LLMResponse.Content.FunctionCalls()) == 0 && len(event.LLMResponse.Content.FunctionResponses()) == 0)) &&
              !event.LLMResponse.Partial {
              return true
          }
      }
      return false
  }

  func handleFinalResponses() {
      var fullResponseText strings.Builder
      // for event := range runner.Run(...) { // Example loop
      //  // Accumulate streaming text if needed...
      //  if event.LLMResponse != nil && event.LLMResponse.Partial && event.LLMResponse.Content != nil {
      //      if len(event.LLMResponse.Content.Parts) > 0 && event.LLMResponse.Content.Parts[0].Text != "" {
      //          fullResponseText.WriteString(event.LLMResponse.Content.Parts[0].Text)
      //      }
      //  }
      //
      //  // Check if it's a final, displayable event
      //  if isFinalResponse(event) {
      //      fmt.Println("\n--- Final Output Detected ---")
      //      if event.LLMResponse != nil && event.LLMResponse.Content != nil {
      //          if len(event.LLMResponse.Content.Parts) > 0 && event.LLMResponse.Content.Parts[0].Text != "" {
      //              // If it's the final part of a stream, use accumulated text
      //              finalText := fullResponseText.String()
      //              if !event.LLMResponse.Partial {
      //                  finalText += event.LLMResponse.Content.Parts[0].Text
      //              }
      //              fmt.Printf("Display to user: %s\n", strings.TrimSpace(finalText))
      //              fullResponseText.Reset() // Reset accumulator
      //          }
      //      } else if event.Actions.SkipSummarization && event.LLMResponse.Content != nil && len(event.LLMResponse.Content.FunctionResponses()) > 0 {
      //          // Handle displaying the raw tool result if needed
      //          responseData := event.LLMResponse.Content.FunctionResponses()[0].Response
      //          fmt.Printf("Display raw tool result: %v\n", responseData)
      //      } else if len(event.LongRunningToolIDs) > 0 {
      //          fmt.Println("Display message: Tool is running in background...")
      //      } else {
      //          // Handle other types of final responses if applicable
      //          fmt.Println("Display: Final non-textual response or signal.")
      //      }
      //  }
      // }
  }
  ```

  ```java
  // Pseudocode: Handling final responses in application (Java)
  import com.google.adk.events.Event;
  import com.google.genai.types.Content;
  import com.google.genai.types.FunctionResponse;
  import java.util.Map;

  StringBuilder fullResponseText = new StringBuilder();
  runner.run(...).forEach(event -> { // Assuming a stream of events
       // Accumulate streaming text if needed...
       if (event.partial().orElse(false) && event.content().isPresent()) {
           event.content().flatMap(Content::parts).ifPresent(parts -> {
               if (!parts.isEmpty() && parts.get(0).text().isPresent()) {
                   fullResponseText.append(parts.get(0).text().get());
              }
           });
       }

       // Check if it's a final, displayable event
       if (event.finalResponse()) { // Using the method from Event.java
           System.out.println("\n--- Final Output Detected ---");
           if (event.content().isPresent() &&
               event.content().flatMap(Content::parts).map(parts -> !parts.isEmpty() && parts.get(0).text().isPresent()).orElse(false)) {
               // If it's the final part of a stream, use accumulated text
               String eventText = event.content().get().parts().get().get(0).text().get();
               String finalText = fullResponseText.toString() + (event.partial().orElse(false) ? "" : eventText);
               System.out.println("Display to user: " + finalText.trim());
               fullResponseText.setLength(0); // Reset accumulator
           } else if (event.actions() != null && event.actions().skipSummarization().orElse(false)
                      && !event.functionResponses().isEmpty()) {
               // Handle displaying the raw tool result if needed,
               // especially if finalResponse() was true due to other conditions
               // or if you want to display skipped summarization results regardless of finalResponse()
               Map<String, Object> responseData = event.functionResponses().get(0).response().get();
               System.out.println("Display raw tool result: " + responseData);
           } else if (event.longRunningToolIds().isPresent() && !event.longRunningToolIds().get().isEmpty()) {
               // This case is covered by event.finalResponse()
               System.out.println("Display message: Tool is running in background...");
           } else {
               // Handle other types of final responses if applicable
               System.out.println("Display: Final non-textual response or signal.");
           }
       }
   });
  ```

By carefully examining these aspects of an event, you can build robust applications that react appropriately to the rich information flowing through the ADK system.

## How Events Flow: Generation and Processing

Events are created at different points and processed systematically by the framework. Understanding this flow helps clarify how actions and history are managed.

- **Generation Sources:**

  - **User Input:** The `Runner` typically wraps initial user messages or mid-conversation inputs into an `Event` with `author='user'`.
  - **Agent Logic:** Agents (`BaseAgent`, `LlmAgent`) explicitly `yield Event(...)` objects (setting `author=self.name`) to communicate responses or signal actions.
  - **LLM Responses:** The ADK model integration layer translates raw LLM output (text, function calls, errors) into `Event` objects, authored by the calling agent.
  - **Tool Results:** After a tool executes, the framework generates an `Event` containing the `function_response`. The `author` is typically the agent that requested the tool, while the `role` inside the `content` is set to `'user'` for the LLM history.

- **Processing Flow:**

  1. **Yield/Return:** An event is generated and yielded (Python) or returned/emitted (Java) by its source.
  1. **Runner Receives:** The main `Runner` executing the agent receives the event.
  1. **SessionService Processing:** The `Runner` sends the event to the configured `SessionService`. This is a critical step:
     - **Applies Deltas:** The service merges `event.actions.state_delta` into `session.state` and updates internal records based on `event.actions.artifact_delta`. (Note: The actual artifact *saving* usually happened earlier when `context.save_artifact` was called).
     - **Finalizes Metadata:** Assigns a unique `event.id` if not present, may update `event.timestamp`.
     - **Persists to History:** Appends the processed event to the `session.events` list.
  1. **External Yield:** The `Runner` yields (Python) or returns/emits (Java) the processed event outwards to the calling application (e.g., the code that invoked `runner.run_async`).

This flow ensures that state changes and history are consistently recorded alongside the communication content of each event.

## Common Event Examples (Illustrative Patterns)

Here are concise examples of typical events you might see in the stream:

- **User Input:**

  ```json
  {
    "author": "user",
    "invocation_id": "e-xyz...",
    "content": {"parts": [{"text": "Book a flight to London for next Tuesday"}]}
    // actions usually empty
  }
  ```

- **Agent Final Text Response:** (`is_final_response() == True`)

  ```json
  {
    "author": "TravelAgent",
    "invocation_id": "e-xyz...",
    "content": {"parts": [{"text": "Okay, I can help with that. Could you confirm the departure city?"}]},
    "partial": false,
    "turn_complete": true
    // actions might have state delta, etc.
  }
  ```

- **Agent Streaming Text Response:** (`is_final_response() == False`)

  ```json
  {
    "author": "SummaryAgent",
    "invocation_id": "e-abc...",
    "content": {"parts": [{"text": "The document discusses three main points:"}]},
    "partial": true,
    "turn_complete": false
  }
  // ... more partial=True events follow ...
  ```

- **Tool Call Request (by LLM):** (`is_final_response() == False`)

  ```json
  {
    "author": "TravelAgent",
    "invocation_id": "e-xyz...",
    "content": {"parts": [{"function_call": {"name": "find_airports", "args": {"city": "London"}}}]}
    // actions usually empty
  }
  ```

- **Tool Result Provided (to LLM):** (`is_final_response()` depends on `skip_summarization`)

  ```json
  {
    "author": "TravelAgent", // Author is agent that requested the call
    "invocation_id": "e-xyz...",
    "content": {
      "role": "user", // Role for LLM history
      "parts": [{"function_response": {"name": "find_airports", "response": {"result": ["LHR", "LGW", "STN"]}}}]
    }
    // actions might have skip_summarization=True
  }
  ```

- **State/Artifact Update Only:** (`is_final_response() == False`)

  ```json
  {
    "author": "InternalUpdater",
    "invocation_id": "e-def...",
    "content": null,
    "actions": {
      "state_delta": {"user_status": "verified"},
      "artifact_delta": {"verification_doc.pdf": 2}
    }
  }
  ```

- **Agent Transfer Signal:** (`is_final_response() == False`)

  ```json
  {
    "author": "OrchestratorAgent",
    "invocation_id": "e-789...",
    "content": {"parts": [{"function_call": {"name": "transfer_to_agent", "args": {"agent_name": "BillingAgent"}}}]},
    "actions": {"transfer_to_agent": "BillingAgent"} // Added by framework
  }
  ```

- **Loop Escalation Signal:** (`is_final_response() == False`)

  ```json
  {
    "author": "CheckerAgent",
    "invocation_id": "e-loop...",
    "content": {"parts": [{"text": "Maximum retries reached."}]}, // Optional content
    "actions": {"escalate": true}
  }
  ```

## Additional Context and Event Details

Beyond the core concepts, here are a few specific details about context and events that are important for certain use cases:

1. **`ToolContext.function_call_id` (Linking Tool Actions):**

   - When an LLM requests a tool (FunctionCall), that request has an ID. The `ToolContext` provided to your tool function includes this `function_call_id`.
   - **Importance:** This ID is crucial for linking actions like authentication back to the specific tool request that initiated them, especially if multiple tools are called in one turn. The framework uses this ID internally.

1. **How State/Artifact Changes are Recorded:**

   - When you modify state or save an artifact using `CallbackContext` or `ToolContext`, these changes aren't immediately written to persistent storage.
   - Instead, they populate the `state_delta` and `artifact_delta` fields within the `EventActions` object.
   - This `EventActions` object is attached to the *next event* generated after the change (e.g., the agent's response or a tool result event).
   - The `SessionService.append_event` method reads these deltas from the incoming event and applies them to the session's persistent state and artifact records. This ensures changes are tied chronologically to the event stream.

1. **State Scope Prefixes (`app:`, `user:`, `temp:`):**

   - When managing state via `context.state`, you can optionally use prefixes:
     - `app:my_setting`: Suggests state relevant to the entire application (requires a persistent `SessionService`).
     - `user:user_preference`: Suggests state relevant to the specific user across sessions (requires a persistent `SessionService`).
     - `temp:intermediate_result` or no prefix: Typically session-specific or temporary state for the current invocation.
   - The underlying `SessionService` determines how these prefixes are handled for persistence.

1. **Error Events:**

   - An `Event` can represent an error. Check the `event.error_code` and `event.error_message` fields (inherited from `LlmResponse`).

   - Errors might originate from the LLM (e.g., safety filters, resource limits) or potentially be packaged by the framework if a tool fails critically. Check tool `FunctionResponse` content for typical tool-specific errors.

     ```json
     // Example Error Event (conceptual)
     {
       "author": "LLMAgent",
       "invocation_id": "e-err...",
       "content": null,
       "error_code": "SAFETY_FILTER_TRIGGERED",
       "error_message": "Response blocked due to safety settings.",
       "actions": {}
     }
     ```

These details provide a more complete picture for advanced use cases involving tool authentication, state persistence scope, and error handling within the event stream.

## Best Practices for Working with Events

To use events effectively in your ADK applications:

- **Clear Authorship:** When building custom agents, ensure correct attribution for agent actions in the history. The framework generally handles authorship correctly for LLM/tool events.

  Use `yield Event(author=self.name, ...)` in `BaseAgent` subclasses.

  When constructing an `Event` in your custom agent logic, set the author, for example: `createEvent({ author: this.name, ... })`

  In custom agent `Run` methods, the framework typically handles authorship. If creating an event manually, set the author: `yield(&session.Event{Author: a.name, ...}, nil)`

  When constructing an `Event` in your custom agent logic, set the author, for example: `Event.builder().author(this.getAgentName()) // ... .build();`

- **Semantic Content & Actions:** Use `event.content` for the core message/data (text, function call/response). Use `event.actions` specifically for signaling side effects (state/artifact deltas) or control flow (`transfer`, `escalate`, `skip_summarization`).

- **Idempotency Awareness:** Understand that the `SessionService` is responsible for applying the state/artifact changes signaled in `event.actions`. While ADK services aim for consistency, consider potential downstream effects if your application logic re-processes events.

- **Use `is_final_response()`:** Rely on this helper method in your application/UI layer to identify complete, user-facing text responses. Avoid manually replicating its logic.

- **Leverage History:** The session's event list is your primary debugging tool. Examine the sequence of authors, content, and actions to trace execution and diagnose issues.

- **Use Metadata:** Use `invocation_id` to correlate all events within a single user interaction. Use `event.id` to reference specific, unique occurrences.

Treating events as structured messages with clear purposes for their content and actions is key to building, debugging, and managing complex agent behaviors in ADK.

# Apps: workflow management class

Supported in ADKPython v1.14.0Java v0.1.0

The ***App*** class is a top-level container for an entire Agent Development Kit (ADK) agent workflow. It is designed to manage the lifecycle, configuration, and state for a collection of agents grouped by a ***root agent***. The **App** class separates the concerns of an agent workflow's overall operational infrastructure from individual agents' task-oriented reasoning.

Defining an ***App*** object in your ADK workflow is optional and changes how you organize your agent code and run your agents. From a practical perspective, you use the ***App*** class to configure the following features for your agent workflow:

- [**Context caching**](/context/caching/)
- [**Context compression**](/context/compaction/)
- [**Agent resume**](/runtime/resume/)
- [**Plugins**](/plugins/)

This guide explains how to use the App class for configuring and managing your ADK agent workflows.

## Purpose of App Class

The ***App*** class addresses several architectural issues that arise when building complex agentic systems:

- **Centralized configuration:** Provides a single, centralized location for managing shared resources like API keys and database clients, avoiding the need to pass configuration down through every agent.
- **Lifecycle management:** The ***App*** class includes ***on startup*** and ***on shutdown*** hooks, which allow for reliable management of persistent resources such as database connection pools or in-memory caches that need to exist across multiple invocations.
- **State scope:** It defines an explicit boundary for application-level state with an `app:*` prefix making the scope and lifetime of this state clear to developers.
- **Unit of deployment:** The ***App*** concept establishes a formal *deployable unit*, simplifying versioning, testing, and serving of agentic applications.

## Define an App object

The ***App*** class is used as the primary container of your agent workflow and contains the root agent of the project. The ***root agent*** is the container for the primary controller agent and any additional sub-agents.

### Define app with root agent

Create a ***root agent*** for your workflow by creating a subclass from the ***Agent*** base class. Then define an ***App*** object and configure it with the ***root agent*** object and optional features, as shown in the following sample code:

agent.py

```python
from google.adk.agents.llm_agent import Agent
from google.adk.apps import App

root_agent = Agent(
    model='gemini-flash-latest',
    name='greeter_agent',
    description='An agent that provides a friendly greeting.',
    instruction='Reply with Hello, World!',
)

app = App(
    name="agents",
    root_agent=root_agent,
    # Optionally include App-level features:
    # plugins, context_cache_config, resumability_config
)
```

AgentConfiguration.java

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.apps.App;

LlmAgent rootAgent = LlmAgent.builder()
    .model("gemini-flash-latest")
    .name("greeter_agent")
    .description("An agent that provides a friendly greeting.")
    .instruction("Reply with Hello, World!")
    .build();

App app = App.builder()
    .name("agents")
    .rootAgent(rootAgent)
    // Optionally include App-level features:
    // .plugins(plugins)
    // .contextCacheConfig(contextCacheConfig)
    // .eventsCompactionConfig(eventsCompactionConfig)
    .build();
```

Recommended: Use `app` variable name

In your agent project code, set your ***App*** object to the variable name `app` so it is compatible with the ADK command line interface runner tools.

### Run your App agent

You can use the ***Runner*** class to run your agent workflow using the `app` parameter, as shown in the following code sample:

main.py

```python
import asyncio
from dotenv import load_dotenv
from google.adk.runners import InMemoryRunner
from agent import app # import code from agent.py

load_dotenv() # load API keys and settings
# Set a Runner using the imported application object
runner = InMemoryRunner(app=app)

async def main():
    try:  # run_debug() requires ADK Python 1.18 or higher:
        response = await runner.run_debug("Hello there!")

    except Exception as e:
        print(f"An error occurred during agent execution: {e}")

if __name__ == "__main__":
    asyncio.run(main())
```

AppMain.java

```java
import com.google.adk.agents.Content;
import com.google.adk.runner.Runner;

public class AppMain {

  public static void main(String[] args) throws Exception {
    // Set a Runner using the application object

    App app = ...;

    Runner runner = Runner.builder()
        .app(app) // Use the 'app' object defined previously
        .build();

    runner.runAsync("user", "session-1", Content.fromParts(Part.fromText("Hello there!")))
        .filter(event -> event.finalResponse() && event.content().isPresent())
        .blockingSubscribe(event -> System.out.println("Response: " + event.stringifyContent()));
  }
}
```

Version requirement for `Runner.run_debug()`

The `Runner.run_debug()` command requires ADK Python v1.18.0 or higher. You can also use `Runner.run()`, which requires more setup code. For more details, see the

Run your App agent with the `main.py` code using the following command:

```console
python3 main.py
```

Run your App agent with the `AppMain.java` code using your build tool (e.g. Gradle `application` plugin):

```console
./gradlew run
```

## Next steps

For a more complete sample code implementation, see the [Hello World App](https://github.com/google/adk-python/tree/main/contributing/samples/hello_world_app) code example.

# Plugins

Supported in ADKPython v1.7.0TypeScript v0.2.5Go v0.4.0Java v0.3.0

A Plugin in Agent Development Kit (ADK) is a custom code module that can be executed at various stages of an agent workflow lifecycle using callback hooks. You use Plugins for functionality that is applicable across your agent workflow. Some typical applications of Plugins are as follows:

- **Logging and tracing**: Create detailed logs of agent, tool, and generative AI model activity for debugging and performance analysis.
- **Policy enforcement**: Implement security guardrails, such as a function that checks if users are authorized to use a specific tool and prevent its execution if they do not have permission.
- **Monitoring and metrics**: Collect and export metrics on token usage, execution times, and invocation counts to monitoring systems such as Prometheus or [Google Cloud Observability](https://cloud.google.com/stackdriver/docs) (formerly Stackdriver).
- **Response caching**: Check if a request has been made before, so you can return a cached response, skipping expensive or time consuming AI model or tool calls.
- **Request or response modification**: Dynamically add information to AI model prompts or standardize tool output responses.

Tip: Use Plugins for safety features

When implementing security guardrails and policies, use ADK Plugins for better modularity and flexibility than Callbacks. For more details, see [Callbacks and Plugins for Security Guardrails](/safety/#callbacks-and-plugins-for-security-guardrails).

Tip: ADK Integrations

For a list of pre-built plugins and other integrations for ADK, see [Tools and Integrations](/integrations/).

## How do Plugins work?

An ADK Plugin extends the `BasePlugin` class and contains one or more `callback` methods, indicating where in the agent lifecycle the Plugin should be executed. You integrate Plugins into an agent by registering them in your agent's `Runner` class. For more information on how and where you can trigger Plugins in your agent application, see [Plugin callback hooks](#plugin-callback-hooks).

Plugin functionality builds on [Callbacks](https://adk.dev/callbacks/index.md), which is a key design element of the ADK's extensible architecture. While a typical Agent Callback is configured on a *single agent, a single tool* for a *specific task*, a Plugin is registered *once* on the `Runner` and its callbacks apply *globally* to every agent, tool, and LLM call managed by that runner. Plugins let you package related callback functions together to be used across a workflow. This makes Plugins an ideal solution for implementing features that cut across your entire agent application.

## Prebuilt Plugins

ADK includes several plugins that you can add to your agent workflows immediately:

- [**Reflect and Retry Tools**](/integrations/reflect-and-retry/): Tracks tool failures and intelligently retries tool requests.
- [**BigQuery Analytics**](/integrations/bigquery-agent-analytics/): Enables agent logging and analysis with BigQuery.
- [**Context Filter**](https://github.com/google/adk-python/blob/main/src/google/adk/plugins/context_filter_plugin.py): Filters the generative AI context to reduce its size.
- [**Global Instruction**](https://github.com/google/adk-python/blob/main/src/google/adk/plugins/global_instruction_plugin.py): Plugin that provides global instructions functionality at the App level.
- [**Save Files as Artifacts**](https://github.com/google/adk-python/blob/main/src/google/adk/plugins/save_files_as_artifacts_plugin.py): Saves files included in user messages as Artifacts.
- [**Logging**](https://github.com/google/adk-python/blame/main/src/google/adk/plugins/logging_plugin.py): Log important information at each agent workflow callback point.

## Define and register Plugins

This section explains how to define Plugin classes and register them as part of your agent workflow. For a complete code example, see [Plugin Basic](https://github.com/google/adk-python/tree/main/contributing/samples/plugin_basic) in the repository.

### Create Plugin class

Start by extending the `BasePlugin` class and add one or more `callback` methods, as shown in the following code example:

count_plugin.py

```py
from google.adk.agents.base_agent import BaseAgent
from google.adk.agents.callback_context import CallbackContext
from google.adk.models.llm_request import LlmRequest
from google.adk.plugins.base_plugin import BasePlugin

class CountInvocationPlugin(BasePlugin):
"""A custom plugin that counts agent and tool invocations."""

def __init__(self) -> None:
    """Initialize the plugin with counters."""
    super().__init__(name="count_invocation")
    self.agent_count: int = 0
    self.tool_count: int = 0
    self.llm_request_count: int = 0

async def before_agent_callback(
    self, *, agent: BaseAgent, callback_context: CallbackContext
) -> None:
    """Count agent runs."""
    self.agent_count += 1
    print(f"[Plugin] Agent run count: {self.agent_count}")

async def before_model_callback(
    self, *, callback_context: CallbackContext, llm_request: LlmRequest
) -> None:
    """Count LLM requests."""
    self.llm_request_count += 1
    print(f"[Plugin] LLM request count: {self.llm_request_count}")
```

count_plugin.ts

```typescript
import { BaseAgent, BasePlugin, Context } from "@google/adk";
import type { LlmRequest, LlmResponse } from "@google/adk";
import type { Content } from "@google/genai";


/**
 * A custom plugin that counts agent and tool invocations.
 */
export class CountInvocationPlugin extends BasePlugin {
    public agentCount = 0;
    public toolCount = 0;
    public llmRequestCount = 0;

    constructor() {
        super("count_invocation");
    }

    /**
     * Count agent runs.
     */
    async beforeAgentCallback(
        agent: BaseAgent,
        context: Context
    ): Promise<Content | undefined> {
        this.agentCount++;
        console.log(`[Plugin] Agent run count: ${this.agentCount}`);
        return undefined;
    }

    /**
     * Count LLM requests.
     */
    async beforeModelCallback(
        context: Context,
        llmRequest: LlmRequest
    ): Promise<LlmResponse | undefined> {
        this.llmRequestCount++;
        console.log(`[Plugin] LLM request count: ${this.llmRequestCount}`);
        return undefined;
    }
}
```

CountInvocationPlugin.java

```java
import com.google.adk.agents.BaseAgent;
import com.google.adk.agents.CallbackContext;
import com.google.adk.models.LlmRequest;
import com.google.adk.models.LlmResponse;
import com.google.adk.plugins.BasePlugin;
import com.google.genai.types.Content;
import io.reactivex.rxjava3.core.Maybe;

/** A custom plugin that counts agent and tool invocations. */
public class CountInvocationPlugin extends BasePlugin {
  public int agentCount = 0;
  public int toolCount = 0;
  public int llmRequestCount = 0;

  public CountInvocationPlugin() {
    super("count_invocation");
  }

  /** Count agent runs. */
  @Override
  public Maybe<Content> beforeAgentCallback(BaseAgent agent, CallbackContext callbackContext) {
    agentCount++;
    System.out.println("[Plugin] Agent run count: " + agentCount);
    return Maybe.empty();
  }

  /** Count LLM requests. */
  @Override
  public Maybe<LlmResponse> beforeModelCallback(
      CallbackContext callbackContext, LlmRequest.Builder llmRequest) {
    llmRequestCount++;
    System.out.println("[Plugin] LLM request count: " + llmRequestCount);
    return Maybe.empty();
  }
}
```

count_plugin.go

```go
package main

import (
    "fmt"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model"
    "google.golang.org/adk/plugin"
    "google.golang.org/genai"
)

/**
 * A custom plugin that counts agent and tool invocations.
 */
type CountInvocationPlugin struct {
    AgentCount      int
    ToolCount       int
    LlmRequestCount int
}

func NewCountInvocationPlugin() (*plugin.Plugin, error) {
    p := &CountInvocationPlugin{}
    return plugin.New(plugin.Config{
        Name:                "count_invocation",
        BeforeAgentCallback: p.BeforeAgentCallback,
        BeforeModelCallback: p.BeforeModelCallback,
    })
}

/**
 * Count agent runs.
 */
func (p *CountInvocationPlugin) BeforeAgentCallback(ctx agent.CallbackContext) (*genai.Content, error) {
    p.AgentCount++
    fmt.Printf("[Plugin] Agent run count: %d\n", p.AgentCount)
    return nil, nil
}

/**
 * Count LLM requests.
 */
func (p *CountInvocationPlugin) BeforeModelCallback(ctx agent.CallbackContext, req *model.LLMRequest) (*model.LLMResponse, error) {
    p.LlmRequestCount++
    fmt.Printf("[Plugin] LLM request count: %d\n", p.LlmRequestCount)
    return nil, nil
}
```

This example code implements callbacks for `before_agent_callback` and `before_model_callback` to count execution of these tasks during the lifecycle of the agent.

### Register Plugin class

Integrate your Plugin class by registering it during your agent initialization as part of your `Runner` class, using the `plugins` parameter. You can specify multiple Plugins with this parameter. The following code example shows how to register the `CountInvocationPlugin` plugin defined in the previous section with a simple ADK agent.

```py
from google.adk.runners import InMemoryRunner
from google.adk import Agent
from google.adk.tools.tool_context import ToolContext
from google.genai import types
import asyncio

# Import the plugin.
from .count_plugin import CountInvocationPlugin

async def hello_world(tool_context: ToolContext, query: str):
    print(f'Hello world: query is [{query}]')

    root_agent = Agent(
        model='gemini-flash-latest',
        name='hello_world',
        description='Prints hello world with user query.',
        instruction="""Use hello_world tool to print hello world and user query.
        """,
        tools=[hello_world],
    )

async def main():
    """Main entry point for the agent."""
    prompt = 'hello world'
    runner = InMemoryRunner(
        agent=root_agent,
        app_name='test_app_with_plugin',

        # Add your plugin here. You can add multiple plugins.
        plugins=[CountInvocationPlugin()],
    )

    # The rest is the same as starting a regular ADK runner.
    session = await runner.session_service.create_session(
        user_id='user',
        app_name='test_app_with_plugin',
    )

    async for event in runner.run_async(
        user_id='user',
        session_id=session.id,
        new_message=types.Content(
            role='user', parts=[types.Part.from_text(text=prompt)]
        )
    ):
        print(f'** Got event from {event.author}')

if __name__ == "__main__":
    asyncio.run(main())
```

```typescript
import { InMemoryRunner, LlmAgent, FunctionTool } from "@google/adk";
import type { Content } from "@google/genai";
import { z } from "zod";

// Import the plugin.
import { CountInvocationPlugin } from "./count_plugin.ts";

const HelloWorldInput = z.object({
    query: z.string().describe("The query string to print."),
});

async function helloWorld({ query }: z.infer<typeof HelloWorldInput>): Promise<{ result: string }> {
    const output = `Hello world: query is [${query}]`;
    console.log(output);
    // Tools should return a string or JSON-compatible object
    return { result: output };
}

const helloWorldTool = new FunctionTool({
    name: "hello_world",
    description: "Prints hello world with user query.",
    parameters: HelloWorldInput,
    execute: helloWorld,
});

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest", // Preserved from your Python code
    name: "hello_world",
    description: "Prints hello world with user query.",
    instruction: `Use hello_world tool to print hello world and user query.`,
    tools: [helloWorldTool],
});

/**
* Main entry point for the agent.
*/
async function main(): Promise<void> {
    const prompt = "hello world";
    const runner = new InMemoryRunner({
        agent: rootAgent,
        appName: "test_app_with_plugin",

        // Add your plugin here. You can add multiple plugins.
        plugins: [new CountInvocationPlugin()],
    });

    // The rest is the same as starting a regular ADK runner.
    const session = await runner.sessionService.createSession({
        userId: "user",
        appName: "test_app_with_plugin",
    });

    // runAsync returns an async iterable stream in TypeScript
    const runStream = runner.runAsync({
        userId: "user",
        sessionId: session.id,
        newMessage: {
        role: "user",
        parts: [{ text: prompt }],
        },
    });

    // Use 'for await...of' to loop through the async stream
    for await (const event of runStream) {
        console.log(`** Got event from ${event.author}`);
    }
}

main();
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.runner.InMemoryRunner;
import com.google.adk.sessions.Session;
import com.google.adk.tools.Annotations.Schema;
import com.google.adk.tools.FunctionTool;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import java.util.Collections;
import java.util.List;
import java.util.Map;

// Import the plugin.
// import com.example.CountInvocationPlugin;

public class Main {

  public static class HelloTool {
    @Schema(name = "hello_world", description = "Prints hello world with user query.")
    public static Map<String, Object> helloWorld(
        @Schema(name = "query", description = "The query string to print.") String query) {
      String output = "Hello world: query is [" + query + "]";
      System.out.println(output);
      return Map.of("result", output);
    }
  }

  public static void main(String[] args) {
    LlmAgent rootAgent = LlmAgent.builder()
        .model("gemini-flash-latest")
        .name("hello_world")
        .description("Prints hello world with user query.")
        .instruction("Use hello_world tool to print hello world and user query.")
        .tools(FunctionTool.create(HelloTool.class, "helloWorld"))
        .build();

    // Add your plugin here. You can add multiple plugins.
    InMemoryRunner runner = new InMemoryRunner(
        rootAgent,
        "test_app_with_plugin",
        Collections.singletonList(new CountInvocationPlugin())
    );

    // The rest is the same as starting a regular ADK runner.
    Session session = runner.sessionService().createSession(
        "test_app_with_plugin",
        "user"
    ).blockingGet();

    String prompt = "hello world";
    Content newContent = Content.builder()
        .role("user")
        .parts(List.of(Part.builder().text(prompt).build()))
        .build();

    runner.runAsync(
        "user",
        session.id(),
        newContent
    ).blockingForEach(event -> {
         if (event.author() != null) {
            System.out.println("** Got event from " + event.author());
        }
    });
  }
}
```

```go
package main

import (
    "context"
    "fmt"
    "log"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/plugin"
    "google.golang.org/adk/runner"
    "google.golang.org/adk/session"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/functiontool"
    "google.golang.org/genai"
)

type helloWorldArgs struct {
    Query string `json:"query"`
}

type helloWorldResult struct {
    Result string `json:"result"`
}

func helloWorld(ctx tool.Context, args helloWorldArgs) (helloWorldResult, error) {
    output := fmt.Sprintf("Hello world: query is [%s]", args.Query)
    fmt.Println(output)
    return helloWorldResult{Result: output}, nil
}

func main() {
    ctx := context.Background()
    model, err := gemini.NewModel(ctx, "gemini-flash-latest", &genai.ClientConfig{})
    if err != nil {
        log.Fatalf("failed to create model: %v", err)
    }

    helloWorldTool, err := functiontool.New(functiontool.Config{
        Name:        "hello_world",
        Description: "Prints hello world with user query.",
    }, helloWorld)
    if err != nil {
        log.Fatalf("failed to create tool: %v", err)
    }

    rootAgent, err := llmagent.New(llmagent.Config{
        Model:       model,
        Name:        "hello_world",
        Description: "Prints hello world with user query.",
        Instruction: "Use hello_world tool to print hello world and user query.",
        Tools:       []tool.Tool{helloWorldTool},
    })
    if err != nil {
        log.Fatalf("failed to create agent: %v", err)
    }

    // Create your plugin.
    countPlugin, err := NewCountInvocationPlugin()
    if err != nil {
        log.Fatalf("failed to create plugin: %v", err)
    }

    sessionService := session.InMemoryService()
    // Add your plugin here. You can add multiple plugins.
    r, err := runner.New(runner.Config{
        AppName:        "test_app_with_plugin",
        Agent:          rootAgent,
        SessionService: sessionService,
        PluginConfig: runner.PluginConfig{
            Plugins: []*plugin.Plugin{countPlugin},
        },
    })
    if err != nil {
        log.Fatalf("failed to create runner: %v", err)
    }

    // The rest is the same as starting a regular ADK runner.
    sessResp, err := sessionService.Create(ctx, &session.CreateRequest{
        AppName: "test_app_with_plugin",
        UserID:  "user",
    })
    if err != nil {
        log.Fatalf("failed to create session: %v", err)
    }
    sess := sessResp.Session

    prompt := "hello world"
    input := genai.NewContentFromText(prompt, genai.RoleUser)

    for event, err := range r.Run(ctx, "user", sess.ID(), input, agent.RunConfig{}) {
        if err != nil {
            log.Printf("AGENT_ERROR: %v", err)
            continue
        }
        if event.Author != "" {
            fmt.Printf("** Got event from %s\n", event.Author)
        }
    }
}
```

### Run the agent with the Plugin

Run the plugin as you typically would. The following shows how to run the command line:

```sh
python3 -m path.to.main.py
```

```sh
npx ts-node path.to.main.ts
```

```sh
./mvnw -q clean compile exec:java -Dexec.mainClass="com.example.Main"
```

```sh
go run path/to/main.go
```

The output of this previously described agent should look similar to the following:

```text
[Plugin] Agent run count: 1
[Plugin] LLM request count: 1
** Got event from hello_world
Hello world: query is [hello world]
** Got event from hello_world
[Plugin] LLM request count: 2
** Got event from hello_world
```

For more information on running ADK agents, see the [Agent Runtime](/runtime/#ways-to-run-agents) guides.

## Build workflows with Plugins

Plugin callback hooks are a mechanism for implementing logic that intercepts, modifies, and even controls the agent's execution lifecycle. Each hook is a specific method in your Plugin class that you can implement to run code at a key moment. You have a choice between two modes of operation based on your hook's return value:

- **To Observe:** Implement a hook with no return value (`None`). This approach is for tasks such as logging or collecting metrics, as it allows the agent's workflow to proceed to the next step without interruption. For example, you could use `after_tool_callback` in a Plugin to log every tool's result for debugging.
- **To Intervene:** Implement a hook and return a value. This approach short-circuits the workflow. The `Runner` halts processing, skips any subsequent plugins and the original intended action, like a Model call, and use a Plugin callback's return value as the result. A common use case is implementing `before_model_callback` to return a cached `LlmResponse`, preventing a redundant and costly API call.
- **To Amend:** Implement a hook and modify the Context object. This approach allows you to modify the context data for the module to be executed without otherwise interrupting the execution of that module. For example, adding additional, standardized prompt text for Model object execution.

**Caution:** Plugin callback functions have precedence over callbacks implemented at the object level. This behavior means that Any Plugin callbacks code is executed *before* any Agent, Model, or Tool objects callbacks are executed. Furthermore, if a Plugin-level agent callback returns any value, and not an empty (`None`) response, the Agent, Model, or Tool-level callback is *not executed* (skipped).

The Plugin design establishes a hierarchy of code execution and separates global concerns from local agent logic. A Plugin is the stateful *module* you build, such as `PerformanceMonitoringPlugin`, while the callback hooks are the specific *functions* within that module that get executed. This architecture differs fundamentally from standard Agent Callbacks in these critical ways:

- **Scope:** Plugin hooks are *global*. You register a Plugin once on the `Runner`, and its hooks apply universally to every Agent, Model, and Tool it manages. In contrast, Agent Callbacks are *local*, configured individually on a specific agent instance.
- **Execution Order:** Plugins have *precedence*. For any given event, the Plugin hooks always run before any corresponding Agent Callback. This system behavior makes Plugins the correct architectural choice for implementing cross-cutting features like security policies, universal caching, and consistent logging across your entire application.

### Agent Callbacks and Plugins

As mentioned in the previous section, there are some functional similarities between Plugins and Agent Callbacks. The following table compares the differences between Plugins and Agent Callbacks in more detail.

|                      | **Plugins**                                                           | **Agent Callbacks**                                                          |
| -------------------- | --------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| **Scope**            | **Global**: Apply to all agents/tools/LLMs in the `Runner`.           | **Local**: Apply only to the specific agent instance they are configured on. |
| **Primary Use Case** | **Horizontal Features**: Logging, policy, monitoring, global caching. | **Specific Agent Logic**: Modifying the behavior or state of a single agent. |
| **Configuration**    | Configure once on the `Runner`.                                       | Configure individually on each `BaseAgent` instance.                         |
| **Execution Order**  | Plugin callbacks run **before** Agent Callbacks.                      | Agent callbacks run **after** Plugin callbacks.                              |

## Plugin callback hooks

You define when a Plugin is called with the callback functions to define in your Plugin class. Callbacks are available when a user message is received, before and after an `Runner`, `Agent`, `Model`, or `Tool` is called, for `Events`, and when a `Model`, or `Tool` error occurs. These callbacks include, and take precedence over, the any callbacks defined within your Agent, Model, and Tool classes.

The following diagram illustrates callback points where you can attach and run Plugin functionality during your agents workflow:

**Figure 1.** Diagram of ADK agent workflow with Plugin callback hook locations.

The following sections describe the available callback hooks for Plugins in more detail.

- [User Message callbacks](#user-message-callbacks)
- [Runner start callbacks](#runner-start-callbacks)
- [Agent execution callbacks](#agent-execution-callbacks)
- [Model callbacks](#model-callbacks)
- [Tool callbacks](#tool-callbacks)
- [Runner end callbacks](#runner-end-callbacks)

### User Message callbacks

*A User Message c*allback (`on_user_message_callback`) happens when a user sends a message. The `on_user_message_callback` is the very first hook to run, giving you a chance to inspect or modify the initial input.\\

- **When It Runs:** This callback happens immediately after `runner.run()`, before any other processing.
- **Purpose:** The first opportunity to inspect or modify the user's raw input.
- **Flow Control:** Returns a `types.Content` object to **replace** the user's original message.

The following code example shows the basic syntax of this callback:

```py
async def on_user_message_callback(
    self,
    *,
    invocation_context: InvocationContext,
    user_message: types.Content,
) -> Optional[types.Content]:
```

```typescript
async onUserMessageCallback(
    invocationContext: InvocationContext,
    user_message: Content
): Promise<Content | undefined> {
  // Your implementation here
}
```

```java
@Override
public Maybe<Content> onUserMessageCallback(
  InvocationContext invocationContext, Content userMessage) {
  // Your implementation here
  return Maybe.empty();
}
```

```go
func (p *MyPlugin) OnUserMessageCallback(ctx agent.InvocationContext, msg *genai.Content) (*genai.Content, error) {
  // Your implementation here
  return nil, nil
}
```

### Runner start callbacks

A *Runner start* callback (`before_run_callback`) happens when the `Runner` object takes the potentially modified user message and prepares for execution. The `before_run_callback` fires here, allowing for global setup before any agent logic begins.

- **When It Runs:** Immediately after `runner.run()` is called, before any other processing.
- **Purpose:** The first opportunity to inspect or modify the user's raw input.
- **Flow Control:** Return a `types.Content` object to **replace** the user's original message.

The following code example shows the basic syntax of this callback:

```py
async def before_run_callback(
    self, *, invocation_context: InvocationContext
) -> Optional[types.Content]:
```

```typescript
async beforeRunCallback(invocationContext: InvocationContext): Promise<Content | undefined> {
  // Your implementation here
}
```

```java
@Override
public Maybe<Content> beforeRunCallback(InvocationContext invocationContext) {
  // Your implementation here
  return Maybe.empty();
}
```

```go
func (p *MyPlugin) BeforeRunCallback(ctx agent.InvocationContext) (*genai.Content, error) {
  // Your implementation here
  return nil, nil
}
```

### Agent execution callbacks

*Agent execution* callbacks (`before_agent`, `after_agent`) happen when a `Runner` object invokes an agent. The `before_agent_callback` runs immediately before the agent's main work begins. The main work encompasses the agent's entire process for handling the request, which could involve calling models or tools. After the agent has finished all its steps and prepared a result, the `after_agent_callback` runs.

**Caution:** Plugins that implement these callbacks are executed *before* the Agent-level callbacks are executed. Furthermore, if a Plugin-level agent callback returns anything other than a `None` or null response, the Agent-level callback is *not executed* (skipped).

For more information about Agent callbacks defined as part of an Agent object, see [Types of Callbacks](https://adk.dev/callbacks/types-of-callbacks/#agent-lifecycle-callbacks).

### Model callbacks

Model callbacks **(`before_model`, `after_model`, `on_model_error`)** happen before and after a Model object executes. The Plugins feature also supports a callback in the event of an error, as detailed below:

- If an agent needs to call an AI model, `before_model_callback` runs first.
- If the model call is successful, `after_model_callback` runs next.
- If the model call fails with an exception, the `on_model_error_callback` is triggered instead, allowing for graceful recovery.

**Caution:** Plugins that implement the **`before_model`** and `**after_model` **callback methods are executed* before* the Model-level callbacks are executed. Furthermore, if a Plugin-level model callback returns anything other than a `None` or null response, the Model-level callback is *not executed* (skipped).

#### Model on error callback details

The on error callback for Model objects is only supported by the Plugins feature works as follows:

- **When It Runs:** When an exception is raised during the model call.
- **Common Use Cases:** Graceful error handling, logging the specific error, or returning a fallback response, such as "The AI service is currently unavailable."
- **Flow Control:**
  - Returns an `LlmResponse` object to **suppress the exception** and provide a fallback result.
  - Returns `None` to allow the original exception to be raised.

**Note**: If the execution of the Model object returns a `LlmResponse`, the system resumes the execution flow, and `after_model_callback` will be triggered normally.\*\*\*\*

The following code example shows the basic syntax of this callback:

```py
async def on_model_error_callback(
    self,
    *,
    callback_context: CallbackContext,
    llm_request: LlmRequest,
    error: Exception,
) -> Optional[LlmResponse]:
```

```typescript
async onModelErrorCallback(
    context: Context,
    llmRequest: LlmRequest,
    error: Error
): Promise<LlmResponse | undefined> {
    // Your implementation here
}
```

```java
@Override
public Maybe<LlmResponse> onModelErrorCallback(
  CallbackContext callbackContext, LlmRequest.Builder llmRequest, Throwable error) {
  // Your implementation here
  return Maybe.empty();
}
```

```go
func (p *MyPlugin) OnModelErrorCallback(ctx agent.CallbackContext, req *model.LLMRequest, err error) (*model.LLMResponse, error) {
  // Your implementation here
  return nil, nil
}
```

### Tool callbacks

Tool callbacks **(`before_tool`, `after_tool`, `on_tool_error`)** for Plugins happen before or after the execution of a tool, or when an error occurs. The Plugins feature also supports a callback in the event of an error, as detailed below:\\

- When an agent executes a Tool, `before_tool_callback` runs first.
- If the tool executes successfully, `after_tool_callback` runs next.
- If the tool raises an exception, the `on_tool_error_callback` is triggered instead, giving you a chance to handle the failure. If `on_tool_error_callback` returns a dict, `after_tool_callback` will be triggered normally.

**Caution:** Plugins that implement these callbacks are executed *before* the Tool-level callbacks are executed. Furthermore, if a Plugin-level tool callback returns anything other than a `None` or null response, the Tool-level callback is *not executed* (skipped).

#### Tool on error callback details

The on error callback for Tool objects is only supported by the Plugins feature works as follows:

- **When It Runs:** When an exception is raised during the execution of a tool's `run` method.
- **Purpose:** Catching specific tool exceptions (like `APIError`), logging the failure, and providing a user-friendly error message back to the LLM.
- **Flow Control:** Return a `dict` to **suppress the exception**, provide a fallback result. Return `None` to allow the original exception to be raised.

**Note**: By returning a `dict`, this resumes the execution flow, and `after_tool_callback` will be triggered normally.

The following code example shows the basic syntax of this callback:

```py
async def on_tool_error_callback(
    self,
    *,
    tool: BaseTool,
    tool_args: dict[str, Any],
    tool_context: ToolContext,
    error: Exception,
) -> Optional[dict]:
```

```typescript
async onToolErrorCallback(
    tool: BaseTool,
    toolArgs: { [key: string]: any },
    context: Context,
    error: Error
): Promise<{ [key:string]: any } | undefined> {
    // Your implementation here
}
```

```java
@Override
public Maybe<Map<String, Object>> onToolErrorCallback(
  BaseTool tool, Map<String, Object> toolArgs, ToolContext toolContext, Throwable error) {
  // Your implementation here
  return Maybe.empty();
}
```

```go
func (p *MyPlugin) OnToolErrorCallback(ctx tool.Context, t tool.Tool, args map[string]any, err error) (map[string]any, error) {
  // Your implementation here
  return nil, nil
}
```

### Event callbacks

An *Event callback* (`on_event_callback`) happens when an agent produces outputs such as a text response or a tool call result, it yields them as `Event` objects. The `on_event_callback` fires for each event, allowing you to modify it before it's streamed to the client.

- **When It Runs:** After an agent yields an `Event` but before it's sent to the user. An agent's run may produce multiple events.
- **Purpose:** Useful for modifying or enriching events (e.g., adding metadata) or for triggering side effects based on specific events.
- **Flow Control:** Return an `Event` object to **replace** the original event.

The following code example shows the basic syntax of this callback:

```py
async def on_event_callback(
    self, *, invocation_context: InvocationContext, event: Event
) -> Optional[Event]:
```

```typescript
async onEventCallback(
    invocationContext: InvocationContext,
    event: Event
): Promise<Event | undefined> {
    // Your implementation here
}
```

```java
@Override
public Maybe<Event> onEventCallback(InvocationContext invocationContext, Event event) {
  // Your implementation here
  return Maybe.empty();
}
```

```go
func (p *MyPlugin) OnEventCallback(ctx agent.InvocationContext, event *session.Event) (*session.Event, error) {
  // Your implementation here
  return nil, nil
}
```

### Runner end callbacks

The *Runner end* callback **(`after_run_callback`)** happens when the agent has finished its entire process and all events have been handled, the `Runner` completes its run. The `after_run_callback` is the final hook, perfect for cleanup and final reporting.

- **When It Runs:** After the `Runner` fully completes the execution of a request.
- **Purpose:** Ideal for global cleanup tasks, such as closing connections or finalizing logs and metrics data.
- **Flow Control:** This callback is for teardown only and cannot alter the final result.

The following code example shows the basic syntax of this callback:

```py
async def after_run_callback(
    self, *, invocation_context: InvocationContext
) -> Optional[None]:
```

```typescript
async afterRunCallback(invocationContext: InvocationContext): Promise<void> {
    // Your implementation here
}
```

```java
@Override
public Completable afterRunCallback(InvocationContext invocationContext) {
  // Your implementation here
  return Completable.complete();
}
```

```go
func (p *MyPlugin) AfterRunCallback(ctx agent.InvocationContext) {
  // Your implementation here
}
```

## Next steps

Check out these resources for developing and applying Plugins to your ADK projects:

- For more ADK Plugin code examples, see the [ADK Samples repository](https://github.com/google/adk-samples).
- For information on applying Plugins for security purposes, see [Callbacks and Plugins for Security Guardrails](/safety/#callbacks-and-plugins-for-security-guardrails).




