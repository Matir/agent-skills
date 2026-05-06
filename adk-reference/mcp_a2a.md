# Model Context Protocol Tools

Supported in ADKPython v0.1.0Typescript v0.2.0Go v0.1.0Java v0.1.0

This guide walks you through two ways of integrating Model Context Protocol (MCP) with ADK.

MCP tools for ADK

For a list of pre-built MCP tools for ADK, see [Tools and Integrations](/integrations/?topic=mcp).

## What is Model Context Protocol (MCP)?

The Model Context Protocol (MCP) is an open standard designed to standardize how Large Language Models (LLMs) like Gemini and Claude communicate with external applications, data sources, and tools. Think of it as a universal connection mechanism that simplifies how LLMs obtain context, execute actions, and interact with various systems.

MCP follows a client-server architecture, defining how **data** (resources), **interactive templates** (prompts), and **actionable functions** (tools) are exposed by an **MCP server** and consumed by an **MCP client** (which could be an LLM host application or an AI agent).

This guide covers two primary integration patterns:

1. **Using Existing MCP Servers within ADK:** An ADK agent acts as an MCP client, leveraging tools provided by external MCP servers.
1. **Exposing ADK Tools via an MCP Server:** Building an MCP server that wraps ADK tools, making them accessible to any MCP client.

## Prerequisites

Before you begin, ensure you have the following set up:

- **Set up ADK:** Follow the standard ADK [setup instructions](https://adk.dev/get-started/index.md) in the quickstart.
- **Install/update Python/Java:** MCP requires Python version of 3.9 or higher for Python or Java 17 or higher.
- **Setup Node.js and npx:** **(Python only)** Many community MCP servers are distributed as Node.js packages and run using `npx`. Install Node.js (which includes npx) if you haven't already. For details, see <https://nodejs.org/en>.
- **Verify Installations:** **(Python only)** Confirm `adk` and `npx` are in your PATH within the activated virtual environment:

```shell
# Both commands should print the path to the executables.
which adk
which npx
```

```shell
# Both commands should print the path to the executables.
Get-Command adk
Get-Command npx
```

## 1. Using MCP servers with ADK agents (ADK as an MCP client) in `adk web`

This section demonstrates how to integrate tools from external MCP (Model Context Protocol) servers into your ADK agents. This is the **most common** integration pattern when your ADK agent needs to use capabilities provided by an existing service that exposes an MCP interface. You will see how the `McpToolset` class can be directly added to your agent's `tools` list, enabling seamless connection to an MCP server, discovery of its tools, and making them available for your agent to use. These examples primarily focus on interactions within the `adk web` development environment.

### `McpToolset` class

The `McpToolset` class is ADK's primary mechanism for integrating tools from an MCP server. When you include an `McpToolset` instance in your agent's `tools` list, it automatically handles the interaction with the specified MCP server. Here's how it works:

1. **Connection Management:** On initialization, `McpToolset` establishes and manages the connection to the MCP server. This can be a local server process (using `StdioConnectionParams` for communication over standard input/output) or a remote server (using `SseConnectionParams` for Server-Sent Events). The toolset also handles the graceful shutdown of this connection when the agent or application terminates.
1. **Tool Discovery & Adaptation:** Once connected, `McpToolset` queries the MCP server for its available tools (via the `list_tools` MCP method). It then converts the schemas of these discovered MCP tools into ADK-compatible `BaseTool` instances.
1. **Exposure to Agent:** These adapted tools are then made available to your `LlmAgent` as if they were native ADK tools.
1. **Proxying Tool Calls:** When your `LlmAgent` decides to use one of these tools, `McpToolset` transparently proxies the call (using the `call_tool` MCP method) to the MCP server, sends the necessary arguments, and returns the server's response back to the agent.
1. **Filtering (Optional):** You can use the `tool_filter` parameter when creating an `McpToolset` to select a specific subset of tools from the MCP server, rather than exposing all of them to your agent.

The following examples demonstrate how to use `McpToolset` within the `adk web` development environment. For scenarios where you need more fine-grained control over the MCP connection lifecycle or are not using `adk web`, refer to the "Using MCP Tools in your own Agent out of `adk web`" section later in this page.

### Example 1: File System MCP Server

This Python example demonstrates connecting to a local MCP server that provides file system operations.

#### Step 1: Define your Agent with `McpToolset`

Create an `agent.py` file (e.g., in `./adk_agent_samples/mcp_agent/agent.py`). The `McpToolset` is instantiated directly within the `tools` list of your `LlmAgent`.

- **Important:** Replace `"/path/to/your/folder"` in the `args` list with the **absolute path** to an actual folder on your local system that the MCP server can access.
- **Important:** Place the `.env` file in the parent directory of the `./adk_agent_samples` directory.

```python
# ./adk_agent_samples/mcp_agent/agent.py
import os # Required for path operations
from google.adk.agents import LlmAgent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

# It's good practice to define paths dynamically if possible,
# or ensure the user understands the need for an ABSOLUTE path.
# For this example, we'll construct a path relative to this file,
# assuming '/path/to/your/folder' is in the same directory as agent.py.
# REPLACE THIS with an actual absolute path if needed for your setup.
TARGET_FOLDER_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "/path/to/your/folder")
# Ensure TARGET_FOLDER_PATH is an absolute path for the MCP server.
# If you created ./adk_agent_samples/mcp_agent/your_folder,

root_agent = LlmAgent(
    model='gemini-flash-latest',
    name='filesystem_assistant_agent',
    instruction='Help the user manage their files. You can list files, read files, etc.',
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params = StdioServerParameters(
                    command='npx',
                    args=[
                        "-y",  # Argument for npx to auto-confirm install
                        "@modelcontextprotocol/server-filesystem",
                        # IMPORTANT: This MUST be an ABSOLUTE path to a folder the
                        # npx process can access.
                        # Replace with a valid absolute path on your system.
                        # For example: "/Users/youruser/accessible_mcp_files"
                        # or use a dynamically constructed absolute path:
                        os.path.abspath(TARGET_FOLDER_PATH),
                    ],
                ),
            ),
            # Optional: Filter which tools from the MCP server are exposed
            # tool_filter=['list_directory', 'read_file']
        )
    ],
)
```

#### Step 2: Create an `__init__.py` file

Ensure you have an `__init__.py` in the same directory as `agent.py` to make it a discoverable Python package for ADK.

```python
# ./adk_agent_samples/mcp_agent/__init__.py
from . import agent
```

#### Step 3: Run `adk web` and Interact

Navigate to the parent directory of `mcp_agent` (e.g., `adk_agent_samples`) in your terminal and run:

```shell
cd ./adk_agent_samples # Or your equivalent parent directory
adk web
```

Note for Windows users

When hitting the `_make_subprocess_transport NotImplementedError`, consider using `adk web --no-reload` instead.

Once the ADK Web UI loads in your browser:

1. Select the `filesystem_assistant_agent` from the agent dropdown.
1. Try prompts like:
   - "List files in the current directory."
   - "Can you read the file named sample.txt?" (assuming you created it in `TARGET_FOLDER_PATH`).
   - "What is the content of `another_file.md`?"

You should see the agent interacting with the MCP file system server, and the server's responses (file listings, file content) relayed through the agent. The `adk web` console (terminal where you ran the command) might also show logs from the `npx` process if it outputs to stderr.

For Java, refer to the following sample to define an agent that initializes the `McpToolset`:

```java
package agents;

import com.google.adk.agents.LlmAgent;
import com.google.adk.runner.InMemoryRunner;
import com.google.adk.sessions.SessionKey;
import com.google.adk.tools.mcp.McpToolset;
import com.google.adk.tools.mcp.StdioServerParameters;
import com.google.genai.types.Content;
import com.google.genai.types.Part;

import java.util.List;

public class McpAgentCreator {

    /**
     * Initializes an McpToolset, retrieves tools from an MCP server using stdio,
     * creates an LlmAgent with these tools, sends a prompt to the agent,
     * and ensures the toolset is closed.
     * @param args Command line arguments (not used).
     */
    public static void main(String[] args) {
        //Note: you may have permissions issues if the folder is outside home
        String yourFolderPath = "~/path/to/folder";

        StdioServerParameters serverParams = StdioServerParameters.builder()
                .command("npx")
                .args(List.of(
                        "-y",
                        "@modelcontextprotocol/server-filesystem",
                        yourFolderPath
                ))
                .build();

        try (McpToolset toolset = new McpToolset(serverParams.toServerParameters())) {
            LlmAgent agent = LlmAgent.builder()
                    .model("gemini-flash-latest")
                    .name("enterprise_assistant")
                    .description("An agent to help users access their file systems")
                    .instruction(
                            "Help user accessing their file systems. You can list files in a directory."
                    )
                    .tools(toolset)
                    .build();

            System.out.println("Agent created: " + agent.name());

            InMemoryRunner runner = new InMemoryRunner(agent);
            String userId = "user123";
            String sessionId = "1234";
            String promptText = "Which files are in this directory - " + yourFolderPath + "?";

            // Explicitly create the session first
            SessionKey sessionKey = runner.sessionService().createSession(runner.appName(), userId, null, sessionId).blockingGet().sessionKey();
            System.out.println("Session created: " + sessionId + " for user: " + userId);

            Content promptContent = Content.fromParts(Part.fromText(promptText));

            System.out.println("\nSending prompt: \"" + promptText + "\" to agent...\n");

            runner.runAsync(sessionKey, promptContent)
                    .blockingForEach(event -> {
                        System.out.println("Event received: " + event.toJson());
                    });
        } catch (Exception e) {
            System.err.println("An error occurred: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
```

Assuming a folder containing three files named `first`, `second` and `third`, successful response will look like this:

```shell
Event received: {"id":"163a449e-691a-48a2-9e38-8cadb6d1f136","invocationId":"e-c2458c56-e57a-45b2-97de-ae7292e505ef","author":"enterprise_assistant","content":{"parts":[{"functionCall":{"id":"adk-388b4ac2-d40e-4f6a-bda6-f051110c6498","args":{"path":"~/home-test"},"name":"list_directory"}}],"role":"model"},"actions":{"stateDelta":{},"artifactDelta":{},"requestedAuthConfigs":{}},"timestamp":1747377543788}

Event received: {"id":"8728380b-bfad-4d14-8421-fa98d09364f1","invocationId":"e-c2458c56-e57a-45b2-97de-ae7292e505ef","author":"enterprise_assistant","content":{"parts":[{"functionResponse":{"id":"adk-388b4ac2-d40e-4f6a-bda6-f051110c6498","name":"list_directory","response":{"text_output":[{"text":"[FILE] first\n[FILE] second\n[FILE] third"}]}}}],"role":"user"},"actions":{"stateDelta":{},"artifactDelta":{},"requestedAuthConfigs":{}},"timestamp":1747377544679}

Event received: {"id":"8fe7e594-3e47-4254-8b57-9106ad8463cb","invocationId":"e-c2458c56-e57a-45b2-97de-ae7292e505ef","author":"enterprise_assistant","content":{"parts":[{"text":"There are three files in the directory: first, second, and third."}],"role":"model"},"actions":{"stateDelta":{},"artifactDelta":{},"requestedAuthConfigs":{}},"timestamp":1747377544689}
```

For Typescript, you can define an agent that initializes the `MCPToolset` as follows:

```typescript
import 'dotenv/config';
import {LlmAgent, MCPToolset} from "@google/adk";

// REPLACE THIS with an actual absolute path for your setup.
const TARGET_FOLDER_PATH = "/path/to/your/folder";

export const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "filesystem_assistant_agent",
    instruction: "Help the user manage their files. You can list files, read files, etc.",
    tools: [
        // To filter tools, pass a list of tool names as the second argument
        // to the MCPToolset constructor.
        // e.g., new MCPToolset(connectionParams, ['list_directory', 'read_file'])
        new MCPToolset(
            {
                type: "StdioConnectionParams",
                serverParams: {
                    command: "npx",
                    args: [
                        "-y",
                        "@modelcontextprotocol/server-filesystem",
                        // IMPORTANT: This MUST be an ABSOLUTE path to a folder the
                        // npx process can access.
                        // Replace with a valid absolute path on your system.
                        // For example: "/Users/youruser/accessible_mcp_files"
                        TARGET_FOLDER_PATH,
                    ],
                },
            }
        )
    ],
});
```

### Example 2: Google Maps Grounding Lite MCP Server

[Google Maps Platform Grounding Lite](https://developers.google.com/maps/ai/grounding-lite) is a service with Model Context Protocol (MCP) support that makes it easy to ground your AI applications with trusted geospatial data from Google Maps. The MCP server provides tools that allow LLMs to access capabilities for places, weather, and routes. You can try out Grounding Lite by enabling it in any tool that supports MCP servers.

Grounding Lite provides tools that allow LLMs to access the following Google Maps capabilities:

- **Search places:** Request information about places and get AI-generated place data summaries, as well as Place IDs, latitude and longitude coordinates, and Google Maps links for each of the places included in the summary. You can use the returned Place IDs and latitude and longitude coordinates with other Google Maps Platform APIs to show places on a map.
- **Lookup weather:** Request information about weather and return current conditions, hourly forecasts, and daily forecasts.
- **Compute routes:** Request information about driving or walking routes between two locations and return route distance and duration information.

#### Step 1: Enable the Maps Grounding Lite service on your Google Cloud project

1. [Set up your Google Cloud project](https://developers.google.com/maps/get-started#create-project) if you haven’t got one.
1. In the [Google Cloud Console](https://console.developers.google.com), choose the project you want to use for Grounding Lite.
1. Enable Grounding Lite in the [Google Cloud Console API Library](https://console.developers.google.com/apis/library/mapstools.googleapis.com).
1. [Get a Google Maps Platform API Key](https://developers.google.com/maps/get-started#api-key)

#### Step 2: Define your Agent with `McpToolset` for Google Maps Grounding Lite

Modify your `agent.py` file (e.g., in `./adk_agent_samples/mcp_agent/agent.py`). Replace `YOUR_GOOGLE_MAPS_API_KEY` with the actual API key you obtained.

```python
# ./adk_agent_samples/mcp_agent/agent.py
import os
from google.adk.agents.llm_agent import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams

# Retrieve the API key from an environment variable or directly insert it.
# Using an environment variable is generally safer.
# Ensure this environment variable is set in the terminal where you run 'adk web'.
# Example: export GOOGLE_MAPS_API_KEY="YOUR_ACTUAL_KEY"
GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY")

if not GOOGLE_MAPS_API_KEY:
    # Fallback or direct assignment for testing - NOT RECOMMENDED FOR PRODUCTION
    GOOGLE_MAPS_API_KEY = "YOUR_GOOGLE_MAPS_API_KEY_HERE" # Replace if not using env var
    if GOOGLE_MAPS_API_KEY == "YOUR_GOOGLE_MAPS_API_KEY_HERE":
        print("WARNING: GOOGLE_MAPS_API_KEY is not set. Please set it as an environment variable or in the script.")
        # You might want to raise an error or exit if the key is crucial and not found.

root_agent = Agent(
    model='gemini-flash-latest',
    name='travel_planner_agent',
    description='A helpful assistant for planning travel routes.',
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url="https://mapstools.googleapis.com/mcp",
                headers={
                    "X-Goog-Api-Key": GOOGLE_MAPS_API_KEY,
                    "Content-Type": "application/json",
                    "Accept": "application/json, text/event-stream"
                }
            )
        )
    ]
)
```

#### Step 3: Ensure `__init__.py` Exists

If you created this in Example 1, you can skip this. Otherwise, ensure you have an `__init__.py` in the `./adk_agent_samples/mcp_agent/` directory:

```python
# ./adk_agent_samples/mcp_agent/__init__.py
from . import agent
```

#### Step 4: Run `adk web` and Interact

1. **Set Environment Variable (Recommended):** Before running `adk web`, it's best to set your Google Maps API key as an environment variable in your terminal:

   ```shell
   export GOOGLE_MAPS_API_KEY="YOUR_ACTUAL_GOOGLE_MAPS_API_KEY"
   ```

   Replace `YOUR_ACTUAL_GOOGLE_MAPS_API_KEY` with your key.

1. **Run `adk web`**: Navigate to the parent directory of `mcp_agent` (e.g., `adk_agent_samples`) and run:

   ```shell
   cd ./adk_agent_samples # Or your equivalent parent directory
   adk web
   ```

1. **Interact in the UI**:

   - Select the `travel_planner_agent`.
   - Try prompts like:
     - "I will be in San Francisco tomorrow. What’s the weather like?"
     - "Find coffee shops near Golden Gate Park."
     - "Get directions from GooglePlex to SFO."

You should see the agent use the Google Maps Grounding Lite MCP tools to provide directions or location-based information.

For Java, refer to the following sample to define an agent that initializes the `McpToolset`:

```java
package agents;

import com.google.adk.agents.LlmAgent;
import com.google.adk.runner.InMemoryRunner;
import com.google.adk.sessions.SessionKey;
import com.google.adk.tools.mcp.McpToolset;
import com.google.adk.tools.mcp.StdioServerParameters;
import com.google.genai.types.Content;
import com.google.genai.types.Part;

import java.util.HashMap;
import java.util.Map;

public class MapsAgentCreator {

    /**
     * Initializes an McpToolset for Google Maps Grounding Lite,
     * creates an LlmAgent, sends a map-related prompt, and closes the toolset.
     */
    public static void main(String[] args) {
        // Read from environment variables
        String googleMapsApiKey = System.getenv("GOOGLE_MAPS_API_KEY");

        if (googleMapsApiKey == null || googleMapsApiKey.trim().isEmpty()) {
            // Fallback or direct assignment for testing - NOT RECOMMENDED FOR PRODUCTION
            googleMapsApiKey = "YOUR_GOOGLE_MAPS_API_KEY_HERE"; // Replace if not using env var
            if ("YOUR_GOOGLE_MAPS_API_KEY_HERE".equals(googleMapsApiKey)) {
                System.out.println("WARNING: GOOGLE_MAPS_API_KEY is not set. Please set it as an environment variable or in the script.");
            }
        }

        // Setup the headers for the remote MCP connection
        Map<String, String> headers = new HashMap<>();
        headers.put("X-Goog-Api-Key", googleMapsApiKey);
        headers.put("Content-Type", "application/json");
        headers.put("Accept", "application/json, text/event-stream");

        // Use StreamableHttpServerParameters for the remote HTTP MCP server connection
        StreamableHttpServerParameters serverParams = StreamableHttpServerParameters.builder("https://mapstools.googleapis.com/mcp")
                .headers(headers)
                .build();

        try (McpToolset toolset = new McpToolset(serverParams)) {
            // Build the Agent with the configured Toolset
            LlmAgent agent = LlmAgent.builder()
                    .model("gemini-flash-latest")
                    .name("travel_planner_agent")
                    .description("A helpful assistant for planning travel routes.")
                    .tools(toolset)
                    .build();

            System.out.println("Agent created: " + agent.name());

            // Set up the runner and session
            InMemoryRunner runner = new InMemoryRunner(agent);
            String userId = "maps-user-" + System.currentTimeMillis();
            String sessionId = "maps-session-" + System.currentTimeMillis();

            String promptText = "Please give me directions to the nearest pharmacy to Madison Square Garden.";

            // Explicitly create the session first
            SessionKey sessionKey = runner.sessionService().createSession(runner.appName(), userId, null, sessionId).blockingGet().sessionKey();
            System.out.println("Session created: " + sessionId + " for user: " + userId);

            Content promptContent = Content.fromParts(Part.fromText(promptText));

            System.out.println("\nSending prompt: \"" + promptText + "\" to agent...\n");

            // Execute the prompt asynchronously and print the streamed events
            runner.runAsync(sessionKey, promptContent)
                    .blockingForEach(event -> {
                        System.out.println("Event received: " + event.toJson());
                    });
        } catch (Exception e) {
            System.err.println("An error occurred: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
```

For TypeScript, refer to the following sample to define an agent that initializes the `MCPToolset`:

```typescript
import 'dotenv/config';
import {LlmAgent, MCPToolset} from "@google/adk";

// Retrieve the API key from an environment variable.
// Ensure this environment variable is set in the terminal where you run 'adk web'.
// Example: export GOOGLE_MAPS_API_KEY="YOUR_ACTUAL_KEY"
const googleMapsApiKey = process.env.GOOGLE_MAPS_API_KEY;
if (!googleMapsApiKey) {
    console.warn("WARNING: GOOGLE_MAPS_API_KEY is not set.");
    // We throw an error here to prevent the agent from booting without its crucial grounding key
    throw new Error('GOOGLE_MAPS_API_KEY is not provided, please run "export GOOGLE_MAPS_API_KEY=YOUR_ACTUAL_KEY" to add that.');
}

export const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "travel_planner_agent",
    description: "A helpful assistant for planning travel.",
    tools: [
        new MCPToolset({
            // Using SseConnectionParams to connect to the remote Grounding Lite service,
            // mirroring Python's StreamableHTTPConnectionParams.
            type: "SseConnectionParams",
            url: "https://mapstools.googleapis.com/mcp",
            headers: {
                "X-Goog-Api-Key": googleMapsApiKey,
                "Content-Type": "application/json",
                "Accept": "application/json, text/event-stream"
            }
        })
    ],
});
```

## 2. Building an MCP server with ADK tools (MCP server exposing ADK)

This pattern allows you to wrap existing ADK tools and make them available to any standard MCP client application. The example in this section exposes the ADK `load_web_page` tool through a custom-built MCP server.

### Summary of steps

You will create a standard Python MCP server application using the `mcp` library. Within this server, you will:

1. Instantiate the ADK tool(s) you want to expose (e.g., `FunctionTool(load_web_page)`).
1. Implement the MCP server's `@app.list_tools()` handler to advertise the ADK tool(s). This involves converting the ADK tool definition to the MCP schema using the `adk_to_mcp_tool_type` utility from `google.adk.tools.mcp_tool.conversion_utils`.
1. Implement the MCP server's `@app.call_tool()` handler. This handler will:
   - Receive tool call requests from MCP clients.
   - Identify if the request targets one of your wrapped ADK tools.
   - Execute the ADK tool's `.run_async()` method.
   - Format the ADK tool's result into an MCP-compliant response (e.g., `mcp.types.TextContent`).

### Prerequisites

Install the MCP server library in the same Python environment as your ADK installation:

```shell
pip install mcp
```

### Step 1: Create the MCP Server Script

Create a new Python file for your MCP server, for example, `my_adk_mcp_server.py`.

### Step 2: Implement the Server Logic

Add the following code to `my_adk_mcp_server.py`. This script sets up an MCP server that exposes the ADK `load_web_page` tool.

```python
# my_adk_mcp_server.py
import asyncio
import json
import os
from dotenv import load_dotenv

# MCP Server Imports
from mcp import types as mcp_types # Use alias to avoid conflict
from mcp.server.lowlevel import Server, NotificationOptions
from mcp.server.models import InitializationOptions
import mcp.server.stdio # For running as a stdio server

# ADK Tool Imports
from google.adk.tools.function_tool import FunctionTool
from google.adk.tools.load_web_page import load_web_page # Example ADK tool
# ADK <-> MCP Conversion Utility
from google.adk.tools.mcp_tool.conversion_utils import adk_to_mcp_tool_type

# --- Load Environment Variables (If ADK tools need them, e.g., API keys) ---
load_dotenv() # Create a .env file in the same directory if needed

# --- Prepare the ADK Tool ---
# Instantiate the ADK tool you want to expose.
# This tool will be wrapped and called by the MCP server.
print("Initializing ADK load_web_page tool...")
adk_tool_to_expose = FunctionTool(load_web_page)
print(f"ADK tool '{adk_tool_to_expose.name}' initialized and ready to be exposed via MCP.")
# --- End ADK Tool Prep ---

# --- MCP Server Setup ---
print("Creating MCP Server instance...")
# Create a named MCP Server instance using the mcp.server library
app = Server("adk-tool-exposing-mcp-server")

# Implement the MCP server's handler to list available tools
@app.list_tools()
async def list_mcp_tools() -> list[mcp_types.Tool]:
    """MCP handler to list tools this server exposes."""
    print("MCP Server: Received list_tools request.")
    # Convert the ADK tool's definition to the MCP Tool schema format
    mcp_tool_schema = adk_to_mcp_tool_type(adk_tool_to_expose)
    print(f"MCP Server: Advertising tool: {mcp_tool_schema.name}")
    return [mcp_tool_schema]

# Implement the MCP server's handler to execute a tool call
@app.call_tool()
async def call_mcp_tool(
    name: str, arguments: dict
) -> list[mcp_types.Content]: # MCP uses mcp_types.Content
    """MCP handler to execute a tool call requested by an MCP client."""
    print(f"MCP Server: Received call_tool request for '{name}' with args: {arguments}")

    # Check if the requested tool name matches our wrapped ADK tool
    if name == adk_tool_to_expose.name:
        try:
            # Execute the ADK tool's run_async method.
            # Note: tool_context is None here because this MCP server is
            # running the ADK tool outside of a full ADK Runner invocation.
            # If the ADK tool requires ToolContext features (like state or auth),
            # this direct invocation might need more sophisticated handling.
            adk_tool_response = await adk_tool_to_expose.run_async(
                args=arguments,
                tool_context=None,
            )
            print(f"MCP Server: ADK tool '{name}' executed. Response: {adk_tool_response}")

            # Format the ADK tool's response (often a dict) into an MCP-compliant format.
            # Here, we serialize the response dictionary as a JSON string within TextContent.
            # Adjust formatting based on the ADK tool's output and client needs.
            response_text = json.dumps(adk_tool_response, indent=2)
            # MCP expects a list of mcp_types.Content parts
            return [mcp_types.TextContent(type="text", text=response_text)]

        except Exception as e:
            print(f"MCP Server: Error executing ADK tool '{name}': {e}")
            # Return an error message in MCP format
            error_text = json.dumps({"error": f"Failed to execute tool '{name}': {str(e)}"})
            return [mcp_types.TextContent(type="text", text=error_text)]
    else:
        # Handle calls to unknown tools
        print(f"MCP Server: Tool '{name}' not found/exposed by this server.")
        error_text = json.dumps({"error": f"Tool '{name}' not implemented by this server."})
        return [mcp_types.TextContent(type="text", text=error_text)]

# --- MCP Server Runner ---
async def run_mcp_stdio_server():
    """Runs the MCP server, listening for connections over standard input/output."""
    # Use the stdio_server context manager from the mcp.server.stdio library
    async with mcp.server.stdio.stdio_server() as (read_stream, write_stream):
        print("MCP Stdio Server: Starting handshake with client...")
        await app.run(
            read_stream,
            write_stream,
            InitializationOptions(
                server_name=app.name, # Use the server name defined above
                server_version="0.1.0",
                capabilities=app.get_capabilities(
                    # Define server capabilities - consult MCP docs for options
                    notification_options=NotificationOptions(),
                    experimental_capabilities={},
                ),
            ),
        )
        print("MCP Stdio Server: Run loop finished or client disconnected.")

if __name__ == "__main__":
    print("Launching MCP Server to expose ADK tools via stdio...")
    try:
        asyncio.run(run_mcp_stdio_server())
    except KeyboardInterrupt:
        print("\nMCP Server (stdio) stopped by user.")
    except Exception as e:
        print(f"MCP Server (stdio) encountered an error: {e}")
    finally:
        print("MCP Server (stdio) process exiting.")
# --- End MCP Server ---
```

### Step 3: Test your Custom MCP Server with an ADK Agent

Now, create an ADK agent that will act as a client to the MCP server you just built. This ADK agent will use `McpToolset` to connect to your `my_adk_mcp_server.py` script.

Create an `agent.py` (e.g., in `./adk_agent_samples/mcp_client_agent/agent.py`):

```python
# ./adk_agent_samples/mcp_client_agent/agent.py
import os
from google.adk.agents import LlmAgent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

# IMPORTANT: Replace this with the ABSOLUTE path to your my_adk_mcp_server.py script
PATH_TO_YOUR_MCP_SERVER_SCRIPT = "/path/to/your/my_adk_mcp_server.py" # <<< REPLACE

if PATH_TO_YOUR_MCP_SERVER_SCRIPT == "/path/to/your/my_adk_mcp_server.py":
    print("WARNING: PATH_TO_YOUR_MCP_SERVER_SCRIPT is not set. Please update it in agent.py.")
    # Optionally, raise an error if the path is critical

root_agent = LlmAgent(
    model='gemini-flash-latest',
    name='web_reader_mcp_client_agent',
    instruction="Use the 'load_web_page' tool to fetch content from a URL provided by the user.",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params = StdioServerParameters(
                    command='python3', # Command to run your MCP server script
                    args=[PATH_TO_YOUR_MCP_SERVER_SCRIPT], # Argument is the path to the script
                )
            )
            # tool_filter=['load_web_page'] # Optional: ensure only specific tools are loaded
        )
    ],
)
```

And an `__init__.py` in the same directory:

```python
# ./adk_agent_samples/mcp_client_agent/__init__.py
from . import agent
```

**To run the test:**

1. **Start your custom MCP server (optional, for separate observation):** You can run your `my_adk_mcp_server.py` directly in one terminal to see its logs:

   ```shell
   python3 /path/to/your/my_adk_mcp_server.py
   ```

   It will print "Launching MCP Server..." and wait. The ADK agent (run via `adk web`) will then connect to this process if the `command` in `StdioConnectionParams` is set up to execute it. *(Alternatively, `McpToolset` will start this server script as a subprocess automatically when the agent initializes).*

1. **Run `adk web` for the client agent:** Navigate to the parent directory of `mcp_client_agent` (e.g., `adk_agent_samples`) and run:

   ```shell
   cd ./adk_agent_samples # Or your equivalent parent directory
   adk web
   ```

1. **Interact in the ADK Web UI:**

   - Select the `web_reader_mcp_client_agent`.
   - Try a prompt like: "Load the content from https://example.com"

The ADK agent (`web_reader_mcp_client_agent`) will use `McpToolset` to start and connect to your `my_adk_mcp_server.py`. Your MCP server will receive the `call_tool` request, execute the ADK `load_web_page` tool, and return the result. The ADK agent will then relay this information. You should see logs from both the ADK Web UI (and its terminal) and potentially from your `my_adk_mcp_server.py` terminal if you ran it separately.

This example demonstrates how ADK tools can be encapsulated within an MCP server, making them accessible to a broader range of MCP-compliant clients, not just ADK agents.

Refer to the [documentation](https://modelcontextprotocol.io/quickstart/server#core-mcp-concepts), to try it out with Claude Desktop.

## Using MCP Tools in your own Agent out of `adk web`

This section is relevant to you if:

- You are developing your own Agent using ADK
- And, you are **NOT** using `adk web`,
- And, you are exposing the agent via your own UI

Using MCP Tools requires a different setup than using regular tools, due to the fact that specs for MCP Tools are fetched asynchronously from the MCP Server running remotely, or in another process.

The following example is modified from the "Example 1: File System MCP Server" example above. The main differences are:

1. Your tool and agent are created asynchronously
1. You need to properly manage the exit stack, so that your agents and tools are destructed properly when the connection to MCP Server is closed.

```python
# agent.py (modify get_tools_async and other parts as needed)
# ./adk_agent_samples/mcp_agent/agent.py
import os
import asyncio
from dotenv import load_dotenv
from google.genai import types
from google.adk.agents.llm_agent import LlmAgent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.artifacts.in_memory_artifact_service import InMemoryArtifactService # Optional
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

# Load environment variables from .env file in the parent directory
# Place this near the top, before using env vars like API keys
load_dotenv('../.env')

# Ensure TARGET_FOLDER_PATH is an absolute path for the MCP server.
TARGET_FOLDER_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "/path/to/your/folder")

# --- Step 1: Agent Definition ---
async def get_agent_async():
  """Creates an ADK Agent equipped with tools from the MCP Server."""
  toolset = McpToolset(
      # Use StdioConnectionParams for local process communication
      connection_params=StdioConnectionParams(
          server_params = StdioServerParameters(
            command='npx', # Command to run the server
            args=["-y",    # Arguments for the command
                "@modelcontextprotocol/server-filesystem",
                TARGET_FOLDER_PATH],
          ),
      ),
      tool_filter=['read_file', 'list_directory'] # Optional: filter specific tools
      # For remote servers, you would use SseConnectionParams instead:
      # connection_params=SseConnectionParams(url="http://remote-server:port/path", headers={...})
  )

  # Use in an agent
  root_agent = LlmAgent(
      model='gemini-flash-latest', # Adjust model name if needed based on availability
      name='enterprise_assistant',
      instruction='Help user accessing their file systems',
      tools=[toolset], # Provide the MCP tools to the ADK agent
  )
  return root_agent, toolset

# --- Step 2: Main Execution Logic ---
async def async_main():
  session_service = InMemorySessionService()
  # Artifact service might not be needed for this example
  artifacts_service = InMemoryArtifactService()

  session = await session_service.create_session(
      state={}, app_name='mcp_filesystem_app', user_id='user_fs'
  )

  # TODO: Change the query to be relevant to YOUR specified folder.
  # e.g., "list files in the 'documents' subfolder" or "read the file 'notes.txt'"
  query = "list files in the tests folder"
  print(f"User Query: '{query}'")
  content = types.Content(role='user', parts=[types.Part(text=query)])

  root_agent, toolset = await get_agent_async()

  runner = Runner(
      app_name='mcp_filesystem_app',
      agent=root_agent,
      artifact_service=artifacts_service, # Optional
      session_service=session_service,
  )

  print("Running agent...")
  events_async = runner.run_async(
      session_id=session.id, user_id=session.user_id, new_message=content
  )

  async for event in events_async:
    print(f"Event received: {event}")

  # Cleanup is handled automatically by the agent framework
  # But you can also manually close if needed:
  print("Closing MCP server connection...")
  await toolset.close()
  print("Cleanup complete.")

if __name__ == '__main__':
  try:
    asyncio.run(async_main())
  except Exception as e:
    print(f"An error occurred: {e}")
```

## Key considerations

When working with MCP and ADK, keep these points in mind:

- **Protocol vs. Library:** MCP is a protocol specification, defining communication rules. ADK is a Python library/framework for building agents. McpToolset bridges these by implementing the client side of the MCP protocol within the ADK framework. Conversely, building an MCP server in Python requires using the model-context-protocol library.

- **ADK Tools vs. MCP Tools:**

  - ADK Tools (BaseTool, FunctionTool, AgentTool, etc.) are Python objects designed for direct use within the ADK's LlmAgent and Runner.
  - MCP Tools are capabilities exposed by an MCP Server according to the protocol's schema. McpToolset makes these look like ADK tools to an LlmAgent.

- **Asynchronous nature:** Both ADK and the MCP Python library are heavily based on the asyncio Python library. Tool implementations and server handlers should generally be async functions.

- **Stateful sessions (MCP):** MCP establishes stateful, persistent connections between a client and server instance. This differs from typical stateless REST APIs.

  - **Deployment:** This statefulness can pose challenges for scaling and deployment, especially for remote servers handling many users. The original MCP design often assumed client and server were co-located. Managing these persistent connections requires careful infrastructure considerations (e.g., load balancing, session affinity).
  - **ADK McpToolset:** Manages this connection lifecycle. The exit_stack pattern shown in the examples is crucial for ensuring the connection (and potentially the server process) is properly terminated when the ADK agent finishes.

## Deploying Agents with MCP Tools

When deploying ADK agents that use MCP tools to production environments like Cloud Run, GKE, or Agent Runtime, you need to consider how MCP connections will work in containerized and distributed environments.

### Critical Deployment Requirement: Synchronous Agent Definition

**⚠️ Important:** When deploying agents with MCP tools, the agent and its McpToolset must be defined **synchronously** in your `agent.py` file. While `adk web` allows for asynchronous agent creation, deployment environments require synchronous instantiation.

```python
# ✅ CORRECT: Synchronous agent definition for deployment
import os
from google.adk.agents.llm_agent import LlmAgent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

_allowed_path = os.path.dirname(os.path.abspath(__file__))

root_agent = LlmAgent(
    model='gemini-flash-latest',
    name='enterprise_assistant',
    instruction=f'Help user accessing their file systems. Allowed directory: {_allowed_path}',
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command='npx',
                    args=['-y', '@modelcontextprotocol/server-filesystem', _allowed_path],
                ),
                timeout=5,  # Configure appropriate timeouts
            ),
            # Filter tools for security in production
            tool_filter=[
                'read_file', 'read_multiple_files', 'list_directory',
                'directory_tree', 'search_files', 'get_file_info',
                'list_allowed_directories',
            ],
        )
    ],
)
```

```python
# ❌ WRONG: Asynchronous patterns don't work in deployment
async def get_agent():  # This won't work for deployment
    toolset = await create_mcp_toolset_async()
    return LlmAgent(tools=[toolset])
```

### Quick Deployment Commands

#### Agent Runtime

```bash
uv run adk deploy agent_engine \
  --project=<your-gcp-project-id> \
  --region=<your-gcp-region> \
  --staging_bucket="gs://<your-gcs-bucket>" \
  --display_name="My MCP Agent" \
  ./path/to/your/agent_directory
```

#### Cloud Run

```bash
uv run adk deploy cloud_run \
  --project=<your-gcp-project-id> \
  --region=<your-gcp-region> \
  --service_name=<your-service-name> \
  ./path/to/your/agent_directory
```

### Deployment Patterns

#### Pattern 1: Self-Contained Stdio MCP Servers

For MCP servers that can be packaged as npm packages or Python modules (like `@modelcontextprotocol/server-filesystem`), you can include them directly in your agent container:

**Container Requirements:**

```dockerfile
# Example for npm-based MCP servers
FROM python:3.13-slim

# Install Node.js and npm for MCP servers
RUN apt-get update && apt-get install -y nodejs npm && rm -rf /var/lib/apt/lists/*

# Install your Python dependencies
COPY requirements.txt .
RUN pip install -r requirements.txt

# Copy your agent code
COPY . .

# Your agent can now use StdioConnectionParams with 'npx' commands
CMD ["python", "main.py"]
```

**Agent Configuration:**

```python
# This works in containers because npx and the MCP server run in the same environment
McpToolset(
    connection_params=StdioConnectionParams(
        server_params=StdioServerParameters(
            command='npx',
            args=["-y", "@modelcontextprotocol/server-filesystem", "/app/data"],
        ),
    ),
)
```

#### Pattern 2: Remote MCP Servers (Streamable HTTP)

For production deployments requiring scalability, deploy MCP servers as separate services and connect via Streamable HTTP:

**MCP Server Deployment (Cloud Run):**

```python
# deploy_mcp_server.py - Separate Cloud Run service using Streamable HTTP
import contextlib
import logging
from collections.abc import AsyncIterator
from typing import Any

import anyio
import click
import mcp.types as types
from mcp.server.lowlevel import Server
from mcp.server.streamable_http_manager import StreamableHTTPSessionManager
from starlette.applications import Starlette
from starlette.routing import Mount
from starlette.types import Receive, Scope, Send

logger = logging.getLogger(__name__)

def create_mcp_server():
    """Create and configure the MCP server."""
    app = Server("adk-mcp-streamable-server")

    @app.call_tool()
    async def call_tool(name: str, arguments: dict[str, Any]) -> list[types.ContentBlock]:
        """Handle tool calls from MCP clients."""
        # Example tool implementation - replace with your actual ADK tools
        if name == "example_tool":
            result = arguments.get("input", "No input provided")
            return [
                types.TextContent(
                    type="text",
                    text=f"Processed: {result}"
                )
            ]
        else:
            raise ValueError(f"Unknown tool: {name}")

    @app.list_tools()
    async def list_tools() -> list[types.Tool]:
        """List available tools."""
        return [
            types.Tool(
                name="example_tool",
                description="Example tool for demonstration",
                inputSchema={
                    "type": "object",
                    "properties": {
                        "input": {
                            "type": "string",
                            "description": "Input text to process"
                        }
                    },
                    "required": ["input"]
                }
            )
        ]

    return app

def main(port: int = 8080, json_response: bool = False):
    """Main server function."""
    logging.basicConfig(level=logging.INFO)

    app = create_mcp_server()

    # Create session manager with stateless mode for scalability
    session_manager = StreamableHTTPSessionManager(
        app=app,
        event_store=None,
        json_response=json_response,
        stateless=True,  # Important for Cloud Run scalability
    )

    async def handle_streamable_http(scope: Scope, receive: Receive, send: Send) -> None:
        await session_manager.handle_request(scope, receive, send)

    @contextlib.asynccontextmanager
    async def lifespan(app: Starlette) -> AsyncIterator[None]:
        """Manage session manager lifecycle."""
        async with session_manager.run():
            logger.info("MCP Streamable HTTP server started!")
            try:
                yield
            finally:
                logger.info("MCP server shutting down...")

    # Create ASGI application
    starlette_app = Starlette(
        debug=False,  # Set to False for production
        routes=[
            Mount("/mcp", app=handle_streamable_http),
        ],
        lifespan=lifespan,
    )

    import uvicorn
    uvicorn.run(starlette_app, host="0.0.0.0", port=port)

if __name__ == "__main__":
    main()
```

**Agent Configuration for Remote MCP:**

```python
# Your ADK agent connects to the remote MCP service via Streamable HTTP
McpToolset(
    connection_params=StreamableHTTPConnectionParams(
        url="https://your-mcp-server-url.run.app/mcp",
        headers={"Authorization": "Bearer your-auth-token"}
    ),
)
```

```java
import java.util.Map;
import com.google.adk.tools.mcp.StreamableHttpServerParameters;
import com.google.adk.tools.mcp.McpToolset;

// Your ADK agent connects to the remote MCP service via Streamable HTTP
StreamableHttpServerParameters streamableParams = StreamableHttpServerParameters.builder()
        .url("https://your-mcp-server-url.run.app/mcp")
        .headers(Map.of("Authorization", "Bearer your-auth-token"))
        .build();

McpToolset toolset = new McpToolset(streamableParams);
```

#### Pattern 3: Sidecar MCP Servers (GKE)

In Kubernetes environments, you can deploy MCP servers as sidecar containers:

```yaml
# deployment.yaml - GKE with MCP sidecar
apiVersion: apps/v1
kind: Deployment
metadata:
  name: adk-agent-with-mcp
spec:
  template:
    spec:
      containers:
      # Main ADK agent container
      - name: adk-agent
        image: your-adk-agent:latest
        ports:
        - containerPort: 8080
        env:
        - name: MCP_SERVER_URL
          value: "http://localhost:8081"

      # MCP server sidecar
      - name: mcp-server
        image: your-mcp-server:latest
        ports:
        - containerPort: 8081
```

### Connection Management Considerations

#### Stdio Connections

- **Pros:** Simple setup, process isolation, works well in containers
- **Cons:** Process overhead, not suitable for high-scale deployments
- **Best for:** Development, single-tenant deployments, simple MCP servers

#### SSE/HTTP Connections

- **Pros:** Network-based, scalable, can handle multiple clients
- **Cons:** Requires network infrastructure, authentication complexity
- **Best for:** Production deployments, multi-tenant systems, external MCP services

### Production Deployment Checklist

When deploying agents with MCP tools to production:

**✅ Connection Lifecycle**

- Ensure proper cleanup of MCP connections using exit_stack patterns
- Configure appropriate timeouts for connection establishment and requests
- Implement retry logic for transient connection failures

**✅ Resource Management**

- Monitor memory usage for stdio MCP servers (each spawns a process)
- Configure appropriate CPU/memory limits for MCP server processes
- Consider connection pooling for remote MCP servers

**✅ Security**

- Use authentication headers for remote MCP connections
- Restrict network access between ADK agents and MCP servers
- **Filter MCP tools using `tool_filter` to limit exposed functionality**
- Validate MCP tool inputs to prevent injection attacks
- Use restrictive file paths for filesystem MCP servers (e.g., `os.path.dirname(os.path.abspath(__file__))`)
- Consider read-only tool filters for production environments

**✅ Monitoring & Observability**

- Log MCP connection establishment and teardown events
- Monitor MCP tool execution times and success rates
- Set up alerts for MCP connection failures

**✅ Scalability**

- For high-volume deployments, prefer remote MCP servers over stdio
- Configure session affinity if using stateful MCP servers
- Consider MCP server connection limits and implement circuit breakers

### Environment-Specific Configurations

#### Cloud Run

```python
# Cloud Run environment variables for MCP configuration
import os

# Detect Cloud Run environment
if os.getenv('K_SERVICE'):
    # Use remote MCP servers in Cloud Run
    mcp_connection = SseConnectionParams(
        url=os.getenv('MCP_SERVER_URL'),
        headers={'Authorization': f"Bearer {os.getenv('MCP_AUTH_TOKEN')}"}
    )
else:
    # Use stdio for local development
    mcp_connection = StdioConnectionParams(
        server_params=StdioServerParameters(
            command='npx',
            args=["-y", "@modelcontextprotocol/server-filesystem", "/tmp"]
        )
    )

McpToolset(connection_params=mcp_connection)
```

#### GKE

```python
# GKE-specific MCP configuration
# Use service discovery for MCP servers within the cluster
McpToolset(
    connection_params=SseConnectionParams(
        url="http://mcp-service.default.svc.cluster.local:8080/sse"
    ),
)
```

#### Agent Runtime

```python
# Agent Runtime managed deployment
# Prefer lightweight, self-contained MCP servers or external services
McpToolset(
    connection_params=SseConnectionParams(
        url="https://your-managed-mcp-service.googleapis.com/sse",
        headers={'Authorization': 'Bearer $(gcloud auth print-access-token)'}
    ),
)
```

### Troubleshooting Deployment Issues

**Common MCP Deployment Problems:**

1. **Stdio Process Startup Failures**

   ```python
   # Debug stdio connection issues
   McpToolset(
       connection_params=StdioConnectionParams(
           server_params=StdioServerParameters(
               command='npx',
               args=["-y", "@modelcontextprotocol/server-filesystem", "/app/data"],
               # Add environment debugging
               env={'DEBUG': '1'}
           ),
       ),
   )
   ```

1. **Network Connectivity Issues**

   ```python
   # Test remote MCP connectivity
   import aiohttp

   async def test_mcp_connection():
       async with aiohttp.ClientSession() as session:
           async with session.get('https://your-mcp-server.com/health') as resp:
               print(f"MCP Server Health: {resp.status}")
   ```

1. **Resource Exhaustion**

1. Monitor container memory usage when using stdio MCP servers

1. Set appropriate limits in Kubernetes deployments

1. Use remote MCP servers for resource-intensive operations

## Further Resources

- [Model Context Protocol Documentation](https://modelcontextprotocol.io/)
- [MCP Specification](https://modelcontextprotocol.io/specification/)
- [MCP Python SDK & Examples](https://github.com/modelcontextprotocol/)

# Integrate REST APIs with OpenAPI

Supported in ADKPython v0.1.0

ADK simplifies interacting with external REST APIs by automatically generating callable tools directly from an [OpenAPI Specification (v3.x)](https://swagger.io/specification/). This eliminates the need to manually define individual function tools for each API endpoint.

Core Benefit

Use `OpenAPIToolset` to instantly create agent tools (`RestApiTool`) from your existing API documentation (OpenAPI spec), enabling agents to seamlessly call your web services.

## Key Components

- **`OpenAPIToolset`**: This is the primary class you'll use. You initialize it with your OpenAPI specification, and it handles the parsing and generation of tools.
- **`RestApiTool`**: This class represents a single, callable API operation (like `GET /pets/{petId}` or `POST /pets`). `OpenAPIToolset` creates one `RestApiTool` instance for each operation defined in your spec.

## How it Works

The process involves these main steps when you use `OpenAPIToolset`:

1. **Initialization & Parsing**:

   - You provide the OpenAPI specification to `OpenAPIToolset` either as a Python dictionary, a JSON string, or a YAML string.
   - The toolset internally parses the spec, resolving any internal references (`$ref`) to understand the complete API structure.

1. **Operation Discovery**:

   - It identifies all valid API operations (e.g., `GET`, `POST`, `PUT`, `DELETE`) defined within the `paths` object of your specification.

1. **Tool Generation**:

   - For each discovered operation, `OpenAPIToolset` automatically creates a corresponding `RestApiTool` instance.
   - **Tool Name**: Derived from the `operationId` in the spec (converted to `snake_case`, max 60 chars). If `operationId` is missing, a name is generated from the method and path.
   - **Tool Description**: Uses the `summary` or `description` from the operation for the LLM.
   - **API Details**: Stores the required HTTP method, path, server base URL, parameters (path, query, header, cookie), and request body schema internally.

1. **`RestApiTool` Functionality**: Each generated `RestApiTool`:

   - **Schema Generation**: Dynamically creates a `FunctionDeclaration` based on the operation's parameters and request body. This schema tells the LLM how to call the tool (what arguments are expected).
   - **Execution**: When called by the LLM, it constructs the correct HTTP request (URL, headers, query params, body) using the arguments provided by the LLM and the details from the OpenAPI spec. It handles authentication (if configured) and executes the API call using the `requests` library.
   - **Response Handling**: Returns the API response (typically JSON) back to the agent flow.

1. **Authentication**: You can configure global authentication (like API keys or OAuth - see [Authentication](/tools-custom/authentication/) for details) when initializing `OpenAPIToolset`. This authentication configuration is automatically applied to all generated `RestApiTool` instances.

## Usage Workflow

Follow these steps to integrate an OpenAPI spec into your agent:

1. **Obtain Spec**: Get your OpenAPI specification document (e.g., load from a `.json` or `.yaml` file, fetch from a URL).

1. **Instantiate Toolset**: Create an `OpenAPIToolset` instance, passing the spec content and type (`spec_str`/`spec_dict`, `spec_str_type`). Provide authentication details (`auth_scheme`, `auth_credential`) if required by the API.

   ```python
   from google.adk.tools.openapi_tool.openapi_spec_parser.openapi_toolset import OpenAPIToolset

   # Example with a JSON string
   openapi_spec_json = '...' # Your OpenAPI JSON string
   toolset = OpenAPIToolset(spec_str=openapi_spec_json, spec_str_type="json")

   # Example with a dictionary
   # openapi_spec_dict = {...} # Your OpenAPI spec as a dict
   # toolset = OpenAPIToolset(spec_dict=openapi_spec_dict)
   ```

1. **Add to Agent**: Include the retrieved tools in your `LlmAgent`'s `tools` list.

   ```python
   from google.adk.agents import LlmAgent

   my_agent = LlmAgent(
       name="api_interacting_agent",
       model="gemini-flash-latest", # Or your preferred model
       tools=[toolset], # Pass the toolset
       # ... other agent config ...
   )
   ```

1. **Instruct Agent**: Update your agent's instructions to inform it about the new API capabilities and the names of the tools it can use (e.g., `list_pets`, `create_pet`). The tool descriptions generated from the spec will also help the LLM.

1. **Run Agent**: Execute your agent using the `Runner`. When the LLM determines it needs to call one of the APIs, it will generate a function call targeting the appropriate `RestApiTool`, which will then handle the HTTP request automatically.

## Example

This example demonstrates generating tools from a simple Pet Store OpenAPI spec (using `httpbin.org` for mock responses) and interacting with them via an agent.

Code: Pet Store API

openapi_example.py

```python



# Model Context Protocol (MCP)

Supported in ADKPythonTypeScriptGoJava

The [Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) is an open standard designed to standardize how Large Language Models (LLMs) like Gemini and Claude communicate with external applications, data sources, and tools. Think of it as a universal connection mechanism that simplifies how LLMs obtain context, execute actions, and interact with various systems.

MCP tools for ADK

For a list of pre-built MCP tools for ADK, see [Tools and Integrations](/integrations/?topic=mcp).

## How does MCP work?

MCP follows a client-server architecture, defining how data (resources), interactive templates (prompts), and actionable functions (tools) are exposed by an MCP server and consumed by an MCP client (which could be an LLM host application or an AI agent).

## MCP Tools in ADK

ADK helps you both use and consume MCP tools in your agents, whether you're trying to build a tool to call an MCP service, or exposing an MCP server for other developers or agents to interact with your tools.

See [Tools and Integrations](/integrations/) for pre-built MCP tools you can use in your agents. Refer to the [MCP Tools documentation](/tools-custom/mcp-tools/) for code samples and design patterns that help you use ADK together with MCP servers, including:

- **Using Existing MCP Servers within ADK**: An ADK agent can act as an MCP client and use tools provided by external MCP servers.
- **Exposing ADK Tools via an MCP Server**: How to build an MCP server that wraps ADK tools, making them accessible to any MCP client.

## ADK Agent and FastMCP server

ADK uses [FastMCP](https://github.com/jlowin/fastmcp) to handle all the complex MCP protocol details and server management, so you can focus on building great tools. It's designed to be high-level and Pythonic; in most cases, decorating a function is all you need.

Refer to the [MCP Tools](/tools-custom/mcp-tools/) documentation on how you can use ADK together with the FastMCP server running on Cloud Run.

## MCP Servers for Google Cloud Genmedia

[MCP Tools for Genmedia Services](https://github.com/GoogleCloudPlatform/vertex-ai-creative-studio/tree/main/experiments/mcp-genmedia) is a set of open-source MCP servers that enable you to integrate Google Cloud generative media services—such as Imagen, Veo, Chirp 3 HD voices, and Lyria—into your AI applications.

Agent Development Kit (ADK) and [Genkit](https://genkit.dev/) provide built-in support for these MCP tools, allowing your AI agents to effectively orchestrate generative media workflows. For implementation guidance, refer to the [ADK example agent](https://github.com/GoogleCloudPlatform/vertex-ai-creative-studio/tree/main/experiments/mcp-genmedia/sample-agents/adk) and the [Genkit example](https://github.com/GoogleCloudPlatform/vertex-ai-creative-studio/tree/main/experiments/mcp-genmedia/sample-agents/genkit).

# ADK with Agent2Agent (A2A) Protocol

Supported in ADKPythonGoJavaExperimental

With Agent Development Kit (ADK), you can build complex multi-agent systems where different agents need to collaborate and interact using [Agent2Agent (A2A) Protocol](https://a2a-protocol.org/)! This section provides a comprehensive guide to building powerful multi-agent systems where agents can communicate and collaborate securely and efficiently.

Navigate through the guides below to learn about ADK's A2A capabilities:

**[Introduction to A2A](https://adk.dev/a2a/intro/index.md)**

Start here to learn the fundamentals of A2A by building a multi-agent system with a root agent, a local sub-agent, and a remote A2A agent. The following guides cover how do I expose your agent so that other agents can use it via the A2A protocol:

- **[A2A Quickstart (Exposing) for Python](https://adk.dev/a2a/quickstart-exposing/index.md)**
- **[A2A Quickstart (Exposing) for Go](https://adk.dev/a2a/quickstart-exposing-go/index.md)**
- **[A2A Quickstart (Exposing) for Java](https://adk.dev/a2a/quickstart-exposing-java/index.md)**

These guides show you how to allow your agent to use another, remote agent using A2A protocol:

- **[A2A Quickstart (Consuming) for Python](https://adk.dev/a2a/quickstart-consuming/index.md)**
  - **[A2A Extension - V2 Implementation](https://adk.dev/a2a/a2a-extension/index.md)**
- **[A2A Quickstart (Consuming) for Go](https://adk.dev/a2a/quickstart-consuming-go/index.md)**
- **[A2A Quickstart (Consuming) for Java](https://adk.dev/a2a/quickstart-consuming-java/index.md)**

[**Official Website for Agent2Agent (A2A) Protocol**](https://a2a-protocol.org/)

The official website for A2A Protocol.

# A2A extension for improved reliability

Supported in ADKPython 1.27.0

ADK provides an extension for Agent2Agent (A2A) support to improved message and data handling as part of an updated [A2aAgentExecutor](https://github.com/google/adk-python/blob/main/src/google/adk/a2a/executor/a2a_agent_executor_impl.py) class. The updated version includes updates to architectural changes to the core agent execution logic and extensions for A2A to improve data handling, while also providing backward compatibility with existing A2A agents.

Activating the A2A extension option instructs the server to use the updated agent executor implementation. While this update offers several general advantages, it primarily resolves critical limitations found in the legacy A2A-ADK implementation when both A2A and ADK operate in streaming mode. The new implementation addresses the following issues:

- **Message duplication:** Prevents user messages from being duplicated in the task history.
- **Output misclassification:** Stops remote agent ADK outputs from being incorrectly converted into event thoughts.
- **Sub-agent data loss:** Ensures ADK outputs from remote agents are reliably preserved, eliminating data loss when multiple agents are nested within the remote agent's sub-agent tree.

## Client-side extension activation

Clients indicate their desire to use this extension by specifying it via the transport-defined [A2A extension](https://a2a-protocol.org/latest/topics/extensions/) activation mechanism. For JSON-RPC and HTTP transports, this is indicated via the X-A2A-Extensions HTTP header. For gRPC, this is indicated via the X-A2A-Extensions metadata value.

To activate the extension, the client can instantiate the `RemoteA2aAgent` with `use_legacy=False`. This will add `https://google.github.io/adk-docs/a2a/a2a-extension/` among the requested extensions of the sent request. Activating this extension implies that the server will use the new agent executor implementation.

```python
from google.adk.agents import RemoteA2aAgent

remote_agent = RemoteA2aAgent(
    name="remote_agent",
    url="http://localhost:8000/a2a/remote_agent",
    use_legacy=False,
)
```

The `A2aAgentExecutor` uses by default the new implementation, if the a2a extension is detected in the request. To opt-out the new agent executor implementation, the client can simply not send this extension (instantiating the `RemoteA2aAgent` with `use_legacy=True`) or the server's `A2aAgentExecutor` can be instantiated with `use_legacy=True`.

## How it Works

Upon receiving the request, the [A2aAgentExecutor](https://github.com/google/adk-python/blob/main/src/google/adk/a2a/executor/a2a_agent_executor.py) detects the extension. It understands that the client is requesting to use the new agent executor logic and routes the request to the new implementation accordingly. To confirm that the request was honored, it is then included in the "activated extensions" list within the response metadata sent back to the client, as well as in the metadata of the A2A Events.

## Agent Card definition

Agents advertise this extension capability in their AgentCard within the AgentCapabilities.extensions list.

Example AgentExtension block:

```json
{
  "uri": "https://google.github.io/adk-docs/a2a/a2a-extension/",
  "description": "Ability to use the new agent executor implementation",
  "required": false
}
```




# Introduction to A2A

As you build more complex agentic systems, you will find that a single agent is often not enough. You will want to create specialized agents that can collaborate to solve a problem. The [**Agent2Agent (A2A) Protocol**](https://a2a-protocol.org) is the standard that allows these agents to communicate with each other.

## When to Use A2A vs. Local Sub-Agents

- **Local Sub-Agents:** These are agents that run *within the same application process* as your main agent. They are like internal modules or libraries, used to organize your code into logical, reusable components. Communication between a main agent and its local sub-agents is very fast because it happens directly in memory, without network overhead.
- **Remote Agents (A2A):** These are independent agents that run as separate services, communicating over a network. A2A defines the standard protocol for this communication.

Consider using **A2A** when:

- The agent you need to talk to is a **separate, standalone service** (e.g., a specialized financial modeling agent).
- The agent is maintained by a **different team or organization**.
- You need to connect agents written in **different programming languages or agent frameworks**.
- You want to enforce a **strong, formal contract** (the A2A protocol) between your system's components.

### When to Use A2A: Concrete Examples

- **Integrating with a Third-Party Service:** Your main agent needs to get real-time stock prices from an external financial data provider. This provider exposes its data through an A2A-compatible agent.
- **Microservices Architecture:** You have a large system broken down into smaller, independent services (e.g., an Order Processing Agent, an Inventory Management Agent, a Shipping Agent). A2A is ideal for these services to communicate with each other across network boundaries.
- **Cross-Language Communication:** Your core business logic is in a Python agent, but you have a legacy system or a specialized component written in Java that you want to integrate as an agent. A2A provides the standardized communication layer.
- **Formal API Enforcement:** You are building a platform where different teams contribute agents, and you need a strict contract for how these agents interact to ensure compatibility and stability.

### When NOT to Use A2A: Concrete Examples (Prefer Local Sub-Agents)

- **Internal Code Organization:** You are breaking down a complex task within a single agent into smaller, manageable functions or modules (e.g., a `DataValidator` sub-agent that cleans input data before processing). These are best handled as local sub-agents for performance and simplicity.
- **Performance-Critical Internal Operations:** A sub-agent is responsible for a high-frequency, low-latency operation that is tightly coupled with the main agent's execution (e.g., a `RealTimeAnalytics` sub-agent that processes data streams within the same application).
- **Shared Memory/Context:** When sub-agents need direct access to the main agent's internal state or shared memory for efficiency, A2A's network overhead and serialization/deserialization would be counterproductive.
- **Simple Helper Functions:** For small, reusable pieces of logic that don't require independent deployment or complex state management, a simple function or class within the same agent is more appropriate than a separate A2A agent.

## The A2A Workflow in ADK: A Simplified View

Agent Development Kit (ADK) simplifies the process of building and connecting agents using the A2A protocol. Here's a straightforward breakdown of how it works:

1. **Making an Agent Accessible (Exposing):** You start with an existing ADK agent that you want other agents to be able to interact with. The ADK provides a simple way to "expose" this agent, turning it into an **A2AServer**. This server acts as a public interface, allowing other agents to send requests to your agent over a network. Think of it like setting up a web server for your agent.
1. **Connecting to an Accessible Agent (Consuming):** In a separate agent (which could be running on the same machine or a different one), you'll use a special ADK component called `RemoteA2aAgent`. This `RemoteA2aAgent` acts as a client that knows how to communicate with the **A2AServer** you exposed earlier. It handles all the complexities of network communication, authentication, and data formatting behind the scenes.

From your perspective as a developer, once you've set up this connection, interacting with the remote agent feels just like interacting with a local tool or function. The ADK abstracts away the network layer, making distributed agent systems as easy to work with as local ones.

## Visualizing the A2A Workflow

To further clarify the A2A workflow, let's look at the "before and after" for both exposing and consuming agents, and then the combined system.

### Exposing an Agent

**Before Exposing:** Your agent code runs as a standalone component, but in this scenario, you want to expose it so that other remote agents can interact with your agent.

```text
+-------------------+
| Your Agent Code   |
|   (Standalone)    |
+-------------------+
```

**After Exposing:** Your agent code is integrated with an `A2AServer` (an ADK component), making it accessible over a network to other remote agents.

```text
+-----------------+
|   A2A Server    |
| (ADK Component) |<--------+
+-----------------+         |
        |                   |
        v                   |
+-------------------+       |
| Your Agent Code   |       |
| (Now Accessible)  |       |
+-------------------+       |
                            |
                            | (Network Communication)
                            v
+-----------------------------+
|       Remote Agent(s)       |
|    (Can now communicate)    |
+-----------------------------+
```

### Consuming an Agent

**Before Consuming:** Your agent (referred to as the "Root Agent" in this context) is the application you are developing that needs to interact with a remote agent. Before consuming, it lacks the direct mechanism to do so.

```text
+----------------------+         +-------------------------------------------------------------+
|      Root Agent      |         |                        Remote Agent                         |
| (Your existing code) |         | (External Service that you want your Root Agent to talk to) |
+----------------------+         +-------------------------------------------------------------+
```

**After Consuming:** Your Root Agent uses a `RemoteA2aAgent` (an ADK component that acts as a client-side proxy for the remote agent) to establish communication with the remote agent.

```text
+----------------------+         +-----------------------------------+
|      Root Agent      |         |         RemoteA2aAgent            |
| (Your existing code) |<------->|         (ADK Client Proxy)        |
+----------------------+         |                                   |
                                 |  +-----------------------------+  |
                                 |  |         Remote Agent        |  |
                                 |  |      (External Service)     |  |
                                 |  +-----------------------------+  |
                                 +-----------------------------------+
      (Now talks to remote agent via RemoteA2aAgent)
```

### Final System (Combined View)

This diagram shows how the consuming and exposing parts connect to form a complete A2A system.

```text
Consuming Side:
+----------------------+         +-----------------------------------+
|      Root Agent      |         |         RemoteA2aAgent            |
| (Your existing code) |<------->|         (ADK Client Proxy)        |
+----------------------+         |                                   |
                                 |  +-----------------------------+  |
                                 |  |         Remote Agent        |  |
                                 |  |      (External Service)     |  |
                                 |  +-----------------------------+  |
                                 +-----------------------------------+
                                                 |
                                                 | (Network Communication)
                                                 v
Exposing Side:
                                               +-----------------+
                                               |   A2A Server    |
                                               | (ADK Component) |
                                               +-----------------+
                                                       |
                                                       v
                                               +-------------------+
                                               | Your Agent Code   |
                                               | (Exposed Service) |
                                               +-------------------+
```

## Concrete Use Case: Customer Service and Product Catalog Agents

Let's consider a practical example: a **Customer Service Agent** that needs to retrieve product information from a separate **Product Catalog Agent**.

### Before A2A

Initially, your Customer Service Agent might not have a direct, standardized way to query the Product Catalog Agent, especially if it's a separate service or managed by a different team.

```text
+-------------------------+         +--------------------------+
| Customer Service Agent  |         |  Product Catalog Agent   |
| (Needs Product Info)    |         | (Contains Product Data)  |
+-------------------------+         +--------------------------+
      (No direct, standardized communication)
```

### After A2A

By using the A2A Protocol, the Product Catalog Agent can expose its functionality as an A2A service. Your Customer Service Agent can then easily consume this service using ADK's `RemoteA2aAgent`.

```text
+-------------------------+         +-----------------------------------+
| Customer Service Agent  |         |         RemoteA2aAgent            |
| (Your Root Agent)       |<------->|         (ADK Client Proxy)        |
+-------------------------+         |                                   |
                                    |  +-----------------------------+  |
                                    |  |     Product Catalog Agent   |  |
                                    |  |      (External Service)     |  |
                                    |  +-----------------------------+  |
                                    +-----------------------------------+
                                                 |
                                                 | (Network Communication)
                                                 v
                                               +-----------------+
                                               |   A2A Server    |
                                               | (ADK Component) |
                                               +-----------------+
                                                       |
                                                       v
                                               +------------------------+
                                               | Product Catalog Agent  |
                                               | (Exposed Service)      |
                                               +------------------------+
```

In this setup, first, the Product Catalog Agent needs to be exposed via an A2A Server. Then, the Customer Service Agent can simply call methods on the `RemoteA2aAgent` as if it were a tool, and the ADK handles all the underlying communication to the Product Catalog Agent. This allows for clear separation of concerns and easy integration of specialized agents.

## Next Steps

Now that you understand the "why" of A2A, let's dive into the "how."

- **Continue to the next guide:** Quickstart: Exposing Your Agent, [in Python](https://adk.dev/a2a/quickstart-exposing/index.md), [in Go](https://adk.dev/a2a/quickstart-exposing-go/index.md), [in Java](https://adk.dev/a2a/quickstart-exposing-java/index.md)

# Quickstart: Consuming a remote agent via A2A

Supported in ADKGoExperimental

This quickstart covers the most common starting point for any developer: **"There is a remote agent, how do I let my ADK agent use it via A2A?"**. This is crucial for building complex multi-agent systems where different agents need to collaborate and interact.

## Overview

This sample demonstrates the **Agent2Agent (A2A)** architecture in the Agent Development Kit (ADK), showcasing how multiple agents can work together to handle complex tasks. The sample implements an agent that can roll dice and check if numbers are prime.

```text
┌─────────────────┐    ┌──────────────────┐    ┌────────────────────┐
│   Root Agent    │───▶│   Roll Agent     │    │   Remote Prime     │
│  (Local)        │    │   (Local)        │    │   Agent            │
│                 │    │                  │    │  (localhost:8001)  │
│                 │───▶│                  │◀───│                    │
└─────────────────┘    └──────────────────┘    └────────────────────┘
```

The A2A Basic sample consists of:

- **Root Agent** (`root_agent`): The main orchestrator that delegates tasks to specialized sub-agents
- **Roll Agent** (`roll_agent`): A local sub-agent that handles dice rolling operations
- **Prime Agent** (`prime_agent`): A remote A2A agent that checks if numbers are prime, this agent is running on a separate A2A server

## Exposing Your Agent with the ADK Server

In the `a2a_basic` example, you will first need to expose the `check_prime_agent` via an A2A server, so that the local root agent can use it.

### 1. Getting the Sample Code

First, make sure you have Go installed and your environment is set up.

You can clone and navigate to the [**`a2a_basic`** sample](https://github.com/google/adk-docs/tree/main/examples/go/a2a_basic) here:

```bash
cd examples/go/a2a_basic
```

As you'll see, the folder structure is as follows:

```text
a2a_basic/
├── remote_a2a/
│   └── check_prime_agent/
│       └── main.go
├── go.mod
├── go.sum
└── main.go # local root agent
```

#### Main Agent (`a2a_basic/main.go`)

- **`rollDieTool`**: Function tool for rolling dice
- **`newRollAgent`**: Local agent specialized in dice rolling
- **`newPrimeAgent`**: Remote A2A agent configuration
- **`newRootAgent`**: Main orchestrator with delegation logic

#### Remote Prime Agent (`a2a_basic/remote_a2a/check_prime_agent/main.go`)

- **`checkPrimeTool`**: Prime number checking algorithm
- **`main`**: Implementation of the prime checking service and A2A server.

### 2. Start the Remote Prime Agent server

To show how your ADK agent can consume a remote agent via A2A, you'll first need to start a remote agent server, which will host the prime agent (under `check_prime_agent`).

```bash
# Start the remote a2a server that serves the check_prime_agent on port 8001
go run remote_a2a/check_prime_agent/main.go
```

Once executed, you should see something like:

```shell
2025/11/06 11:00:19 Starting A2A prime checker server on port 8001
2025/11/06 11:00:19 Starting the web server: &{port:8001}
2025/11/06 11:00:19 
2025/11/06 11:00:19 Web servers starts on http://localhost:8001
2025/11/06 11:00:19        a2a:  you can access A2A using jsonrpc protocol: http://localhost:8001
```

### 3. Look out for the required agent card of the remote agent

A2A Protocol requires that each agent must have an agent card that describes what it does.

In the Go ADK, the agent card is generated dynamically when you expose an agent using the A2A launcher. You can visit `http://localhost:8001/.well-known/agent-card.json` to see the generated card.

### 4. Run the Main (Consuming) Agent

```bash
# In a separate terminal, run the main agent
go run main.go
```

#### How it works

The main agent uses `remoteagent.New` to consume the remote agent (`prime_agent` in our example). As you can see below, it requires the `Name`, `Description`, and the `AgentCardSource` URL.

a2a_basic/main.go

```go
func newPrimeAgent() (agent.Agent, error) {
    remoteAgent, err := remoteagent.NewA2A(remoteagent.A2AConfig{
        Name:            "prime_agent",
        Description:     "Agent that handles checking if numbers are prime.",
        AgentCardSource: "http://localhost:8001",
    })
    if err != nil {
        return nil, fmt.Errorf("failed to create remote prime agent: %w", err)
    }
    return remoteAgent, nil
}
```

Then, you can simply use the remote agent in your root agent. In this case, `primeAgent` is used as one of the sub-agents in the `root_agent` below:

a2a_basic/main.go

```go
func newRootAgent(ctx context.Context, rollAgent, primeAgent agent.Agent) (agent.Agent, error) {
    model, err := gemini.NewModel(ctx, "gemini-2.0-flash", &genai.ClientConfig{})
    if err != nil {
        return nil, err
    }
    return llmagent.New(llmagent.Config{
        Name:  "root_agent",
        Model: model,
        Instruction: `
      You are a helpful assistant that can roll dice and check if numbers are prime.
      You delegate rolling dice tasks to the roll_agent and prime checking tasks to the prime_agent.
      Follow these steps:
      1. If the user asks to roll a die, delegate to the roll_agent.
      2. If the user asks to check primes, delegate to the prime_agent.
      3. If the user asks to roll a die and then check if the result is prime, call roll_agent first, then pass the result to prime_agent.
      Always clarify the results before proceeding.
    `,
        SubAgents: []agent.Agent{rollAgent, primeAgent},
        Tools:     []tool.Tool{},
    })
}
```

## Example Interactions

Once both your main and remote agents are running, you can interact with the root agent to see how it calls the remote agent via A2A:

**Simple Dice Rolling:** This interaction uses a local agent, the Roll Agent:

```text
User: Roll a 6-sided die
Bot calls tool: transfer_to_agent with args: map[agent_name:roll_agent]
Bot calls tool: roll_die with args: map[sides:6]
Bot: I rolled a 6-sided die and the result is 6.
```

**Prime Number Checking:**

This interaction uses a remote agent via A2A, the Prime Agent:

```text
User: Is 7 a prime number?
Bot calls tool: transfer_to_agent with args: map[agent_name:prime_agent]
Bot calls tool: prime_checking with args: map[nums:[7]]
Bot: Yes, 7 is a prime number.
```

**Combined Operations:**

This interaction uses both the local Roll Agent and the remote Prime Agent:

```text
User: roll a die and check if it's a prime
Bot: Okay, I will first roll a die and then check if the result is a prime number.

Bot calls tool: transfer_to_agent with args: map[agent_name:roll_agent]
Bot calls tool: roll_die with args: map[sides:6]
Bot calls tool: transfer_to_agent with args: map[agent_name:prime_agent]
Bot calls tool: prime_checking with args: map[nums:[3]]
Bot: 3 is a prime number.
```

## Next Steps

Now that you have created an agent that's using a remote agent via an A2A server, the next step is to learn how to expose your own agent.

- [**A2A Quickstart (Exposing)**](https://adk.dev/a2a/quickstart-exposing-go/index.md): Learn how to expose your existing agent so that other agents can use it via the A2A Protocol.

# Quickstart: Consuming a remote agent via A2A

Supported in ADKJavaExperimental

This quickstart covers the most common starting point for any developer: **"There is a remote agent, how do I let my ADK agent use it via A2A?"**. This is crucial for building complex multi-agent systems where different agents need to collaborate and interact.

## Overview

This sample demonstrates the **Agent2Agent (A2A)** architecture in the Agent Development Kit (ADK) for Java, showcasing how multiple agents can work together to handle complex tasks.

```text
┌─────────────────┐    ┌─────────────────┐    ┌────────────────────────┐
│   Root Agent    │───▶│   Roll Agent    │    │   Remote Prime Agent   │
│   (Local)       │    │   (Local)       │    │   (localhost:8001)     │
│                 │───▶│                 │◀───│                        │
└─────────────────┘    └─────────────────┘    └────────────────────────┘
```

The A2A Basic sample consists of:

- **Root Agent** (`root_agent`): The main orchestrator that delegates tasks to specialized sub-agents
- **Roll Agent** (`roll_agent`): A local sub-agent that handles dice rolling operations
- **Prime Agent** (`prime_agent`): A remote A2A agent that checks if numbers are prime, this agent is running on a separate A2A server

## Consuming Your Agent Using the ADK Java SDK

In Java, rather than manually generating requests, ADK relies on the official A2A SDK `Client` wrapped precisely over a `RemoteA2AAgent` entity. Note that the Java SDK currently uses A2A Protocol 0.3.

### 1. Getting the Sample Code

The native sample matching this quickstart workflow in Java can be found in the `adk-java` source code under `contrib/samples/a2a_basic`.

You can navigate to the [**`a2a_basic`** sample](https://github.com/google/adk-java/tree/main/contrib/samples/a2a_basic):

```bash
cd contrib/samples/a2a_basic
```

### 2. Start the Remote Prime Agent server

To show how your ADK agent can consume a remote agent via A2A, you'll first need a remote agent server running. While you can write your own custom A2A server in any language, ADK provides the `a2a_server` sample which starts a Quarkus service hosting the agent on `:9090`.

```bash
# In adk-java root, start the pre-configured Quarkus remote service on port 9090
./mvnw -f contrib/samples/a2a_server/pom.xml quarkus:dev
```

Once running successfully, the agent will be accessible via HTTP endpoints locally.

### 3. Look out for the required agent card of the remote agent

A2A Protocol requires that each agent have an agent card that describes what it does to other nodes over the network. In an A2A server, the agent card is generated dynamically on boot and hosted statically.

For an ADK Java webservice, the agent card is generally accessible dynamically using the [`.well-known/agent-card.json`](http://localhost:9090/.well-known/agent-card.json) standard endpoint format relative to its base URL.

### 4. Run the Main (Consuming) Agent

In another terminal, you can run the client agent:

```bash
./mvnw -f contrib/samples/a2a_basic/pom.xml exec:java -Dexec.args="http://localhost:9090"
```

#### How it works

The main agent accesses the required A2A JSON-RPC transport wrapper to consume the remote agent (`prime_agent` in our example). As you can see below, it queries for the `AgentCard` from the target host and registers it locally inside an official A2A `Client`.

A2aConsumerSnippet.java

```java
String primeAgentBaseUrl = "http://localhost:9090";
String agentCardUrl = primeAgentBaseUrl + "/.well-known/agent-card.json";

// 1. Resolve the public AgentCard from the remote agent's .well-known endpoint
AgentCard publicAgentCard = new A2ACardResolver(
    new JdkA2AHttpClient(), 
    primeAgentBaseUrl, 
    agentCardUrl
).getAgentCard();

// 2. Build the official A2A SDK Client using the resolved card and transport
Client a2aClient = Client.builder(publicAgentCard)
    .withTransport(JSONRPCTransport.class, new JSONRPCTransportConfig())
    .clientConfig(
        new ClientConfig.Builder()
            .setStreaming(publicAgentCard.capabilities().streaming())
            .build()
    )
    .build();

// 3. Wrap it in the ADK's RemoteA2AAgent natively
BaseAgent remotePrimeAgent = RemoteA2AAgent.builder()
    .name(publicAgentCard.name())
    .a2aClient(a2aClient)
    .agentCard(publicAgentCard)
    .build();
```

You can then pass the remote agent instance naturally to your agent builder, simply acting as just another standard ADK sub-agent. The ADK takes over internally for all translation logic over the wire.

A2aConsumerSnippet.java

```java
BaseAgent rootAgent = LlmAgent.builder()
    .name("root_agent")
    .model("gemini-2.5-flash")
    .instruction("You are a helpful assistant that can check prime numbers by delegating to prime_agent.")
    .subAgents(remotePrimeAgent)
    .build();
```

## Next Steps

Now that you have created an agent that's using a remote agent via an A2A server, the next step is to learn how to expose your own Java agent.

- [**A2A Quickstart (Exposing) for Java**](https://adk.dev/a2a/quickstart-exposing-java/index.md): Learn how to expose your existing agent so that other agents can use it via the A2A Protocol.

# Quickstart: Consuming a remote agent via A2A

Supported in ADKPythonExperimental

This quickstart covers the most common starting point for any developer: **"There is a remote agent, how do I let my ADK agent use it via A2A?"**. This is crucial for building complex multi-agent systems where different agents need to collaborate and interact.

## Overview

This sample demonstrates the **Agent2Agent (A2A)** architecture in the Agent Development Kit (ADK), showcasing how multiple agents can work together to handle complex tasks. The sample implements an agent that can roll dice and check if numbers are prime.

```text
┌─────────────────┐    ┌──────────────────┐    ┌────────────────────┐
│   Root Agent    │───▶│   Roll Agent     │    │   Remote Prime     │
│  (Local)        │    │   (Local)        │    │   Agent            │
│                 │    │                  │    │  (localhost:8001)  │
│                 │───▶│                  │◀───│                    │
└─────────────────┘    └──────────────────┘    └────────────────────┘
```

The A2A Basic sample consists of:

- **Root Agent** (`root_agent`): The main orchestrator that delegates tasks to specialized sub-agents
- **Roll Agent** (`roll_agent`): A local sub-agent that handles dice rolling operations
- **Prime Agent** (`prime_agent`): A remote A2A agent that checks if numbers are prime, this agent is running on a separate A2A server

## Exposing Your Agent with the ADK Server

The ADK comes with a built-in CLI command, `adk api_server --a2a` to expose your agent using the A2A protocol.

In the `a2a_basic` example, you will first need to expose the `check_prime_agent` via an A2A server, so that the local root agent can use it.

### 1. Getting the Sample Code

First, make sure you have the necessary dependencies installed:

```bash
pip install google-adk[a2a]
```

You can clone and navigate to the [**`a2a_basic`** sample](https://github.com/google/adk-python/tree/main/contributing/samples/a2a_basic) here:

```bash
git clone https://github.com/google/adk-python.git
```

As you'll see, the folder structure is as follows:

```text
a2a_basic/
├── remote_a2a/
│   └── check_prime_agent/
│       ├── __init__.py
│       ├── agent.json
│       └── agent.py
├── README.md
├── __init__.py
└── agent.py # local root agent
```

#### Main Agent (`a2a_basic/agent.py`)

- **`roll_die(sides: int)`**: Function tool for rolling dice
- **`roll_agent`**: Local agent specialized in dice rolling
- **`prime_agent`**: Remote A2A agent configuration
- **`root_agent`**: Main orchestrator with delegation logic

#### Remote Prime Agent (`a2a_basic/remote_a2a/check_prime_agent/`)

- **`agent.py`**: Implementation of the prime checking service
- **`agent.json`**: Agent card of the A2A agent
- **`check_prime(nums: list[int])`**: Prime number checking algorithm

### 2. Start the Remote Prime Agent server

To show how your ADK agent can consume a remote agent via A2A, you'll first need to start a remote agent server, which will host the prime agent (under `check_prime_agent`).

```bash
# Start the remote a2a server that serves the check_prime_agent on port 8001
adk api_server --a2a --port 8001 contributing/samples/a2a_basic/remote_a2a
```

Adding logging for debugging with `--log_level debug`

To enable debug-level logging, you can add `--log_level debug` to your `adk api_server`, as in:

```bash
adk api_server --a2a --port 8001 contributing/samples/a2a_basic/remote_a2a --log_level debug
```

This will give richer logs for you to inspect when testing your agents.

Why use port 8001?

In this quickstart, when testing locally, your agents will be using localhost, so the `port` for the A2A server for the exposed agent (the remote, prime agent) must be different from the consuming agent's port. The default port for `adk web` where you will interact with the consuming agent is `8000`, which is why the A2A server is created using a separate port, `8001`.

Once executed, you should see something like:

```shell
INFO:     Started server process [56558]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://127.0.0.1:8001 (Press CTRL+C to quit)
```

### 3. Look out for the required agent card (`agent-card.json`) of the remote agent

A2A Protocol requires that each agent must have an agent card that describes what it does.

If someone else has already built the remote A2A agent that you are looking to consume in your agent, then you should confirm that they have an agent card (`agent-card.json`).

In the sample, the `check_prime_agent` already has an agent card provided:

a2a_basic/remote_a2a/check_prime_agent/agent-card.json

```json
{
  "capabilities": {},
  "defaultInputModes": ["text/plain"],
  "defaultOutputModes": ["application/json"],
  "description": "An agent specialized in checking whether numbers are prime. It can efficiently determine the primality of individual numbers or lists of numbers.",
  "name": "check_prime_agent",
  "skills": [
    {
      "id": "prime_checking",
      "name": "Prime Number Checking",
      "description": "Check if numbers in a list are prime using efficient mathematical algorithms",
      "tags": ["mathematical", "computation", "prime", "numbers"]
    }
  ],
  "url": "http://localhost:8001/a2a/check_prime_agent",
  "version": "1.0.0"
}
```

More info on agent cards in ADK

In ADK, you can use a `to_a2a(root_agent)` wrapper which automatically generates an agent card for you. If you're interested in learning more about how to expose your existing agent so others can use it, then please look at the [A2A Quickstart (Exposing)](https://adk.dev/a2a/quickstart-exposing/index.md) tutorial.

### 4. Run the Main (Consuming) Agent

```bash
# In a separate terminal, run the adk web server
adk web contributing/samples/
```

#### How it works

The main agent uses the `RemoteA2aAgent()` function to consume the remote agent (`prime_agent` in our example). As you can see below, `RemoteA2aAgent()` requires the `name`, `description`, and the URL of the `agent_card`.

a2a_basic/agent.py

```python
<...code truncated...>

from google.adk.agents.remote_a2a_agent import AGENT_CARD_WELL_KNOWN_PATH
from google.adk.agents.remote_a2a_agent import RemoteA2aAgent

prime_agent = RemoteA2aAgent(
    name="prime_agent",
    description="Agent that handles checking if numbers are prime.",
    agent_card=(
        f"http://localhost:8001/a2a/check_prime_agent{AGENT_CARD_WELL_KNOWN_PATH}"
    ),
    use_legacy=False,
)

<...code truncated>
```

Using the new A2A integration

By setting `use_legacy=False`, the agent will use the new ADK-A2A integration, as it will send the [A2A extension](https://adk.dev/a2a/a2a-extension/index.md) to the remote agent.

Then, you can simply use the `RemoteA2aAgent` in your agent. In this case, `prime_agent` is used as one of the sub-agents in the `root_agent` below:

a2a_basic/agent.py

```python
from google.adk.agents.llm_agent import Agent
from google.genai import types

root_agent = Agent(
    model="gemini-flash-latest",
    name="root_agent",
    instruction="""
      <You are a helpful assistant that can roll dice and check if numbers are prime.
      You delegate rolling dice tasks to the roll_agent and prime checking tasks to the prime_agent.
      Follow these steps:
      1. If the user asks to roll a die, delegate to the roll_agent.
      2. If the user asks to check primes, delegate to the prime_agent.
      3. If the user asks to roll a die and then check if the result is prime, call roll_agent first, then pass the result to prime_agent.
      Always clarify the results before proceeding.>
    """,
    global_instruction=(
        "You are DicePrimeBot, ready to roll dice and check prime numbers."
    ),
    sub_agents=[roll_agent, prime_agent],
    tools=[example_tool],
    generate_content_config=types.GenerateContentConfig(
        safety_settings=[
            types.SafetySetting(  # avoid false alarm about rolling dice.
                category=types.HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
                threshold=types.HarmBlockThreshold.OFF,
            ),
        ]
    ),
)
```

### Advanced Configuration: Custom Converters and Interceptors

Internally, the `RemoteA2aAgent` translates between the A2A protocol format and the ADK's native `Event` system. You can customize this behaviour by passing an [`A2aRemoteAgentConfig`](https://github.com/google/adk-python/blob/main/src/google/adk/a2a/agent/config.py) object via the `config` parameter to `RemoteA2aAgent`.

This allows you to define custom type mappings, inject request parameters, and intercept requests or responses.

#### Converters

Converters handle the translation of incoming A2A responses into native ADK objects. You can provide your own mapping functions for the following hooks:

- **`a2a_message_converter`**: Converts standard A2A Messages into ADK `Event` objects.
- **`a2a_task_converter`**: Converts an A2A Task into an ADK `Event`.
- **`a2a_status_update_converter`**: Converts A2A `TaskStatusUpdateEvent`s into ADK `Event` objects.
- **`a2a_artifact_update_converter`**: Converts A2A `TaskArtifactUpdateEvent`s into ADK `Event` objects.
- **`a2a_part_converter`**: A foundational low-level hook utilized internally by other converters to convert individual A2A Message Parts into GenAI `Part` objects.

Note

These custom client converters are used only when the response is coming from the new implementation of the [agent executor](https://github.com/google/adk-python/blob/main/src/google/adk/a2a/executor/a2a_agent_executor_impl.py). For more details, see the [A2A extension](https://adk.dev/a2a/a2a-extension/index.md).

#### Request Interceptors

You can inject a list of `request_interceptors` to add middleware logic to A2A requests:

- **`before_request`**: Executed before the agent starts processing. You can modify the `A2AMessage`, or return an ADK `Event` to immediately abort the request and return that event to the caller.
- **`after_request`**: Executed after the agent has processed the request. You can modify the resulting ADK `Event`, or return `None` to filter out and drop the event entirely.

#### Request Parameters Configuration

Through interceptors, you can also modify the `ParametersConfig` for the A2A request to inject:

- **`request_metadata`**: Pass custom metadata dictionaries into the request headers.
- **`client_call_context`**: Inject specific client call contexts for the underlying transport.

```python
<...code truncated...>

from google.adk.agents.remote_a2a_agent import AGENT_CARD_WELL_KNOWN_PATH
from google.adk.agents.remote_a2a_agent import RemoteA2aAgent

prime_agent = RemoteA2aAgent(
    name="prime_agent",
    description="Agent that handles checking if numbers are prime.",
    agent_card=(
        f"http://localhost:8001/a2a/check_prime_agent{AGENT_CARD_WELL_KNOWN_PATH}"
    ),
    use_legacy=False,
    config=A2aRemoteAgentConfig(
        a2a_message_converter=my_a2a_message_converter,
        request_interceptors=[my_request_interceptor],
    ),
)

<...code truncated>
```

## Example Interactions

Once both your main and remote agents are running, you can interact with the root agent to see how it calls the remote agent via A2A:

**Simple Dice Rolling:** This interaction uses a local agent, the Roll Agent:

```text
User: Roll a 6-sided die
Bot: I rolled a 4 for you.
```

**Prime Number Checking:**

This interaction uses a remote agent via A2A, the Prime Agent:

```text
User: Is 7 a prime number?
Bot: Yes, 7 is a prime number.
```

**Combined Operations:**

This interaction uses both the local Roll Agent and the remote Prime Agent:

```text
User: Roll a 10-sided die and check if it's prime
Bot: I rolled an 8 for you.
Bot: 8 is not a prime number.
```

## Next Steps

Now that you have created an agent that's using a remote agent via an A2A server, the next step is to learn how to connect to it from another agent.

- [**A2A Quickstart (Exposing)**](https://adk.dev/a2a/quickstart-exposing/index.md): Learn how to expose your existing agent so that other agents can use it via the A2A Protocol.

# Quickstart: Exposing a remote agent via A2A

Supported in ADKGoExperimental

This quickstart covers the most common starting point for any developer: **"I have an agent. How do I expose it so that other agents can use my agent via A2A?"**. This is crucial for building complex multi-agent systems where different agents need to collaborate and interact.

## Overview

This sample demonstrates how you can easily expose an ADK agent so that it can be then consumed by another agent using the A2A Protocol.

In Go, you expose an agent by using the A2A launcher, which dynamically generates an agent card for you.

```text
┌─────────────────┐                             ┌───────────────────────────────┐
│   Root Agent    │       A2A Protocol          │ A2A-Exposed Check Prime Agent │
│                 │────────────────────────────▶│      (localhost: 8001)        │
└─────────────────┘                             └───────────────────────────────┘
```

The sample consists of :

- **Remote Prime Agent** (`remote_a2a/check_prime_agent/main.go`): This is the agent that you want to expose so that other agents can use it via A2A. It is an agent that handles prime number checking. It becomes exposed using the A2A launcher.
- **Root Agent** (`main.go`): A simple agent that is just calling the remote prime agent.

## Exposing the Remote Agent with the A2A Launcher

You can take an existing agent built using the Go ADK and make it A2A-compatible by using the A2A launcher.

### 1. Getting the Sample Code

First, make sure you have Go installed and your environment is set up.

You can clone and navigate to the [**`a2a_basic`** sample](https://github.com/google/adk-docs/tree/main/examples/go/a2a_basic) here:

```bash
cd examples/go/a2a_basic
```

As you'll see, the folder structure is as follows:

```text
a2a_basic/
├── remote_a2a/
│   └── check_prime_agent/
│       └── main.go    # Remote Prime Agent
├── go.mod
├── go.sum
└── main.go            # Root agent
```

#### Root Agent (`a2a_basic/main.go`)

- **`newRootAgent`**: A local agent that connects to the remote A2A service.

#### Remote Prime Agent (`a2a_basic/remote_a2a/check_prime_agent/main.go`)

- **`checkPrimeTool`**: Function for prime number checking.
- **`main`**: The main function that creates the agent and starts the A2A server.

### 2. Start the Remote A2A Agent server

You can now start the remote agent server, which will host the `check_prime_agent`:

```bash
# Start the remote agent
go run remote_a2a/check_prime_agent/main.go
```

Once executed, you should see something like:

```shell
2025/11/06 11:00:19 Starting A2A prime checker server on port 8001
2025/11/06 11:00:19 Starting the web server: &{port:8001}
2025/11/06 11:00:19 
2025/11/06 11:00:19 Web servers starts on http://localhost:8001
2025/11/06 11:00:19        a2a:  you can access A2A using jsonrpc protocol: http://localhost:8001
```

### 3. Check that your remote agent is running

You can check that your agent is up and running by visiting the agent card that was auto-generated by the A2A launcher:

<http://localhost:8001/.well-known/agent-card.json>

You should see the contents of the agent card.

### 4. Run the Main (Consuming) Agent

Now that your remote agent is running, you can run the main agent.

```bash
# In a separate terminal, run the main agent
go run main.go
```

#### How it works

The remote agent is exposed using the A2A launcher in the `main` function. The launcher takes care of starting the server and generating the agent card.

remote_a2a/check_prime_agent/main.go

```go
func main() {
    ctx := context.Background()
    primeTool, err := functiontool.New(functiontool.Config{
        Name:        "prime_checking",
        Description: "Check if numbers in a list are prime using efficient mathematical algorithms",
    }, checkPrimeTool)
    if err != nil {
        log.Fatalf("Failed to create prime_checking tool: %v", err)
    }

    model, err := gemini.NewModel(ctx, "gemini-2.0-flash", &genai.ClientConfig{})
    if err != nil {
        log.Fatalf("Failed to create model: %v", err)
    }

    primeAgent, err := llmagent.New(llmagent.Config{
        Name:        "check_prime_agent",
        Description: "check prime agent that can check whether numbers are prime.",
        Instruction: `
            You check whether numbers are prime.
            When checking prime numbers, call the check_prime tool with a list of integers. Be sure to pass in a list of integers. You should never pass in a string.
            You should not rely on the previous history on prime results.
    `,
        Model: model,
        Tools: []tool.Tool{primeTool},
    })
    if err != nil {
        log.Fatalf("Failed to create agent: %v", err)
    }

    // Create launcher. The a2a.NewLauncher() will dynamically generate the agent card.
    port := 8001
    webLauncher := web.NewLauncher(a2a.NewLauncher())
    _, err = webLauncher.Parse([]string{
        "--port", strconv.Itoa(port),
        "a2a", "--a2a_agent_url", "http://localhost:" + strconv.Itoa(port),
    })
    if err != nil {
        log.Fatalf("launcher.Parse() error = %v", err)
    }

    // Create ADK config
    config := &launcher.Config{
        AgentLoader:    agent.NewSingleLoader(primeAgent),
        SessionService: session.InMemoryService(),
    }

    log.Printf("Starting A2A prime checker server on port %d\n", port)
    // Run launcher
    if err := webLauncher.Run(context.Background(), config); err != nil {
        log.Fatalf("webLauncher.Run() error = %v", err)
    }
}
```

## Example Interactions

Once both services are running, you can interact with the root agent to see how it calls the remote agent via A2A:

**Prime Number Checking:**

This interaction uses a remote agent via A2A, the Prime Agent:

```text
User: roll a die and check if it's a prime
Bot: Okay, I will first roll a die and then check if the result is a prime number.

Bot calls tool: transfer_to_agent with args: map[agent_name:roll_agent]
Bot calls tool: roll_die with args: map[sides:6]
Bot calls tool: transfer_to_agent with args: map[agent_name:prime_agent]
Bot calls tool: prime_checking with args: map[nums:[3]]
Bot: 3 is a prime number.
...
```

## Next Steps

Now that you have created an agent that's exposing a remote agent via an A2A server, the next step is to learn how to consume it from another agent.

- [**A2A Quickstart (Consuming)**](https://adk.dev/a2a/quickstart-consuming-go/index.md): Learn how your agent can use other agents using the A2A Protocol.

# Quickstart: Exposing a remote agent via A2A

Supported in ADKJavaExperimental

This quickstart covers the most common starting point for any developer: **"I have an agent. How do I expose it so that other agents can use my agent via A2A?"**. This is crucial for building complex multi-agent systems where different agents need to collaborate and interact.

## Overview

This sample demonstrates how you can expose an ADK agent using Quarkus so that it can be then consumed by another agent using the A2A Protocol.

In Java, you build an A2A server natively by relying on the ADK A2A extension. This uses the Quarkus framework, meaning you just configure your agent directly within your standard Quarkus `@ApplicationScoped` bindings.

```text
┌─────────────────┐                             ┌───────────────────────────────┐
│   Root Agent    │       A2A Protocol          │ A2A-Exposed Check Prime Agent │
│                 │────────────────────────────▶│       (localhost:9090)        │
└─────────────────┘                             └───────────────────────────────┘
```

## Exposing the Remote Agent with Quarkus

Using Quarkus, you map your agent into an A2A execution endpoint without manually wrangling incoming HTTP JSON-RPC payloads or sessions.

### 1. Getting the Sample Code

The fastest way to get started is by checking the standalone Quarkus app inside the `contrib/samples/a2a_server` folder within the [**`adk-java`** repo](https://github.com/google/adk-java).

```bash
cd contrib/samples/a2a_server
```

### 2. How it works

The core runtime uses a provided `AgentExecutor` which requires you to build a CDI `@Produces` bean configuring your native `BaseAgent`. The Quarkus A2A extension discovers this and wires the endpoints automatically.

A2aExposingSnippet.java

```java
import com.google.adk.a2a.executor.AgentExecutorConfig;
import com.google.adk.core.BaseAgent;
import com.google.adk.core.LlmAgent;
import com.google.adk.sessions.InMemorySessionService;
import io.a2a.server.agentexecution.AgentExecutor;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;

import com.google.adk.artifacts.InMemoryArtifactService;

/**
 * Exposing an agent to the A2A network using ADK's Quarkus module.
 * By defining an AgentExecutor as a CDI @Produces, the framework
 * automatically binds your agent to the A2A endpoint.
 */
@ApplicationScoped
public class A2aExposingSnippet {

    @Produces
    public AgentExecutor agentExecutor() {
        BaseAgent myRemoteAgent = LlmAgent.builder()
            .name("prime_agent")
            .model("gemini-2.5-flash")
            .instruction("You are an expert in mathematics. Check if numbers are prime.")
            .build();

        return new com.google.adk.a2a.executor.AgentExecutor.Builder()
            .agent(myRemoteAgent)
            .appName("my-adk-a2a-server")
            .sessionService(new InMemorySessionService())
            .artifactService(new InMemoryArtifactService())
            .agentExecutorConfig(AgentExecutorConfig.builder().build())
            .build();
    }
}
```

The app handles incoming JSON-RPC calls over HTTP mounted on `/a2a/remote/v1/message:send` automatically forwarding parts, history, and contexts directly into your `BaseAgent` flow.

### 3. Start the Remote A2A Agent server

Within the native ADK structure, you can run the Quarkus dev mode task:

```bash
./mvnw -f contrib/samples/a2a_server/pom.xml quarkus:dev
```

Once executed, Quarkus automatically hosts your A2A compliant REST paths. A manual `curl` allows you to immediately smoke test the payload using native A2A specifications:

```bash
curl -X POST http://localhost:9090 \
  -H "Content-Type: application/json" \
  -d '{
        "jsonrpc": "2.0",
        "id": "cli-check",
        "method": "message/send",
        "params": {
          "message": {
            "kind": "message",
            "contextId": "cli-demo-context",
            "messageId": "cli-check-id",
            "role": "user",
            "parts": [
              { "kind": "text", "text": "Is 3 prime?" }
            ]
          }
        }
      }'
```

### 4. Check that your remote agent is running

A proper agent card is exposed over a standard path representing your instance automatically: <http://localhost:9090/.well-known/agent-card.json>

You should be able to see the name dynamically mirrored from your agent configuration inside the response JSON.

## Next Steps

Now that you have exposed your agent via A2A, the next step is to learn how to consume it from another agent orchestrator natively.

- [**A2A Quickstart (Consuming) for Java**](https://adk.dev/a2a/quickstart-consuming-java/index.md): Learn how your agent orchestrator wrapper connects downstream to exposed services.

# Quickstart: Exposing a remote agent via A2A

Supported in ADKPythonExperimental

This quickstart covers the most common starting point for any developer: **"I have an agent. How do I expose it so that other agents can use my agent via A2A?"**. This is crucial for building complex multi-agent systems where different agents need to collaborate and interact.

## Overview

This sample demonstrates how you can easily expose an ADK agent so that it can be then consumed by another agent using the A2A Protocol.

There are two main ways to expose an ADK agent via A2A.

- **by using the `to_a2a(root_agent)` function**: use this function if you just want to convert an existing agent to work with A2A, and be able to expose it via a server through `uvicorn`, instead of `adk deploy api_server`. This means that you have tighter control over what you want to expose via `uvicorn` when you want to productionize your agent. Furthermore, the `to_a2a()` function auto-generates an agent card based on your agent code.
- **by creating your own agent card (`agent.json`) and hosting it using `adk api_server --a2a`**: There are two main benefits of using this approach. First, `adk api_server --a2a` works with `adk web`, making it easy to use, debug, and test your agent. Second, with `adk api_server`, you can specify a parent folder with multiple, separate agents. Those agents that have an agent card (`agent.json`), will automatically be usable via A2A by other agents through the same server. However, you will need to create your own agent cards. To create an agent card, you can follow the [A2A Python tutorial](https://a2a-protocol.org/latest/tutorials/python/1-introduction/).

This quickstart will focus on `to_a2a()`, as it is the easiest way to expose your agent and will also autogenerate the agent card behind-the-scenes. If you'd like to use the `adk api_server` approach, you can see it being used in the [A2A Quickstart (Consuming) documentation](https://adk.dev/a2a/quickstart-consuming/index.md).

```text
Before:
                                                ┌────────────────────┐
                                                │ Hello World Agent  │
                                                │  (Python Object)   │
                                                | without agent card │
                                                └────────────────────┘

                                                          │
                                                          │ to_a2a()
                                                          ▼

After:
┌────────────────┐                             ┌───────────────────────────────┐
│   Root Agent   │       A2A Protocol          │ A2A-Exposed Hello World Agent │
│(RemoteA2aAgent)│────────────────────────────▶│      (localhost: 8001)         │
│(localhost:8000)│                             └───────────────────────────────┘
└────────────────┘
```

The sample consists of :

- **Remote Hello World Agent** (`remote_a2a/hello_world/agent.py`): This is the agent that you want to expose so that other agents can use it via A2A. It is an agent that handles dice rolling and prime number checking. It becomes exposed using the `to_a2a()` function and is served using `uvicorn`.
- **Root Agent** (`agent.py`): A simple agent that is just calling the remote Hello World agent.

## Exposing the Remote Agent with the `to_a2a(root_agent)` function

You can take an existing agent built using ADK and make it A2A-compatible by simply wrapping it using the `to_a2a()` function. For example, if you have an agent like the following defined in `root_agent`:

```python
# Your agent code here
root_agent = Agent(
    model='gemini-flash-latest',
    name='hello_world_agent',

    <...your agent code...>
)
```

Then you can make it A2A-compatible simply by using `to_a2a(root_agent)`:

```python
from google.adk.a2a.utils.agent_to_a2a import to_a2a

# Make your agent A2A-compatible
a2a_app = to_a2a(root_agent, port=8001)
```

The `to_a2a()` function will even auto-generate an agent card in-memory behind-the-scenes by [extracting skills, capabilities, and metadata from the ADK agent](https://github.com/google/adk-python/blob/main/src/google/adk/a2a/utils/agent_card_builder.py), so that the well-known agent card is made available when the agent endpoint is served using `uvicorn`.

You can also provide your own agent card by using the `agent_card` parameter. The value can be an `AgentCard` object or a path to an agent card JSON file.

**Example with an `AgentCard` object:**

```python
from google.adk.a2a.utils.agent_to_a2a import to_a2a
from a2a.types import AgentCard

# Define A2A agent card
my_agent_card = AgentCard(
    name="file_agent",
    url="http://example.com",
    description="Test agent from file",
    version="1.0.0",
    capabilities={},
    skills=[],
    default_input_modes=["text/plain"],
    default_output_modes=["text/plain"],
    supports_authenticated_extended_card=False,
)
a2a_app = to_a2a(root_agent, port=8001, agent_card=my_agent_card)
```

**Example with a path to a JSON file:**

```python
from google.adk.a2a.utils.agent_to_a2a import to_a2a

# Load A2A agent card from a file
a2a_app = to_a2a(root_agent, port=8001, agent_card="/path/to/your/agent-card.json")
```

### Under the hood: to_a2a() method

When you call `to_a2a()`, the ADK automatically handles several setup steps to expose your agent:

- **`A2aAgentExecutor` setup:** An `A2aAgentExecutor` is initialized to act as the bridge between the A2A protocol and your ADK agent. If you don't provide a custom `Runner`, it automatically creates a default one backed by in-memory services (for artifacts, sessions, memory, and credentials).
- **State Management:** It creates an `InMemoryTaskStore` to track A2A tasks and an `InMemoryPushNotificationConfigStore` for handling push notifications.
- **Request Handling:** A `DefaultRequestHandler` is created to route incoming A2A HTTP requests to the `A2aAgentExecutor` and the state stores.
- **Starlette App & Agent Card:** It creates a Starlette application. During the application's startup phase, it either loads your provided Agent Card or automatically builds one from your agent's configuration using an `AgentCardBuilder`. It then mounts all the necessary A2A API routes.

Now let's dive into the sample code.

### 1. Getting the Sample Code

First, make sure you have the necessary dependencies installed:

```bash
pip install google-adk[a2a]
```

You can clone and navigate to the [**a2a_root** sample](https://github.com/google/adk-python/tree/main/contributing/samples/a2a_root) here:

```bash
git clone https://github.com/google/adk-python.git
```

As you'll see, the folder structure is as follows:

```text
a2a_root/
├── remote_a2a/
│   └── hello_world/    
│       ├── __init__.py
│       └── agent.py    # Remote Hello World Agent
├── README.md
└── agent.py            # Root agent
```

#### Root Agent (`a2a_root/agent.py`)

- **`root_agent`**: A `RemoteA2aAgent` that connects to the remote A2A service
- **Agent Card URL**: Points to the well-known agent card endpoint on the remote server

#### Remote Hello World Agent (`a2a_root/remote_a2a/hello_world/agent.py`)

- **`roll_die(sides: int)`**: Function tool for rolling dice with state management
- **`check_prime(nums: list[int])`**: Async function for prime number checking
- **`root_agent`**: The main agent with comprehensive instructions
- **`a2a_app`**: The A2A application created using `to_a2a()` utility

### 2. Start the Remote A2A Agent server

You can now start the remote agent server, which will host the `a2a_app` within the hello_world agent:

```bash
# Ensure current working directory is adk-python/
# Start the remote agent using uvicorn
uvicorn contributing.samples.a2a_root.remote_a2a.hello_world.agent:a2a_app --host localhost --port 8001
```

Why use port 8001?

In this quickstart, when testing locally, your agents will be using localhost, so the `port` for the A2A server for the exposed agent (the remote, prime agent) must be different from the consuming agent's port. The default port for `adk web` where you will interact with the consuming agent is `8000`, which is why the A2A server is created using a separate port, `8001`.

Once executed, you should see something like:

```shell
INFO:     Started server process [10615]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://localhost:8001 (Press CTRL+C to quit)
```

### 3. Check that your remote agent is running

You can check that your agent is up and running by visiting the agent card that was auto-generated earlier as part of your `to_a2a()` function in `a2a_root/remote_a2a/hello_world/agent.py`:

<http://localhost:8001/.well-known/agent-card.json>

You should see the contents of the agent card, which should look like:

```json
{"capabilities":{},"defaultInputModes":["text/plain"],"defaultOutputModes":["text/plain"],"description":"hello world agent that can roll a dice of 8 sides and check prime numbers.","name":"hello_world_agent","protocolVersion":"0.2.6","skills":[{"description":"hello world agent that can roll a dice of 8 sides and check prime numbers. \n      I roll dice and answer questions about the outcome of the dice rolls.\n      I can roll dice of different sizes.\n      I can use multiple tools in parallel by calling functions in parallel(in one request and in one round).\n      It is ok to discuss previous dice roles, and comment on the dice rolls.\n      When I are asked to roll a die, I must call the roll_die tool with the number of sides. Be sure to pass in an integer. Do not pass in a string.\n      I should never roll a die on my own.\n      When checking prime numbers, call the check_prime tool with a list of integers. Be sure to pass in a list of integers. I should never pass in a string.\n      I should not check prime numbers before calling the tool.\n      When I are asked to roll a die and check prime numbers, I should always make the following two function calls:\n      1. I should first call the roll_die tool to get a roll. Wait for the function response before calling the check_prime tool.\n      2. After I get the function response from roll_die tool, I should call the check_prime tool with the roll_die result.\n        2.1 If user asks I to check primes based on previous rolls, make sure I include the previous rolls in the list.\n      3. When I respond, I must include the roll_die result from step 1.\n      I should always perform the previous 3 steps when asking for a roll and checking prime numbers.\n      I should not rely on the previous history on prime results.\n    ","id":"hello_world_agent","name":"model","tags":["llm"]},{"description":"Roll a die and return the rolled result.\n\nArgs:\n  sides: The integer number of sides the die has.\n  tool_context: the tool context\nReturns:\n  An integer of the result of rolling the die.","id":"hello_world_agent-roll_die","name":"roll_die","tags":["llm","tools"]},{"description":"Check if a given list of numbers are prime.\n\nArgs:\n  nums: The list of numbers to check.\n\nReturns:\n  A str indicating which number is prime.","id":"hello_world_agent-check_prime","name":"check_prime","tags":["llm","tools"]}],"supportsAuthenticatedExtendedCard":false,"url":"http://localhost:8001","version":"0.0.1"}
```

### 4. Run the Main (Consuming) Agent

Now that your remote agent is running, you can launch the dev UI and select "a2a_root" as your agent.

```bash
# In a separate terminal, run the adk web server
adk web contributing/samples/
```

To open the adk web server, go to: <http://localhost:8000>.

## Example Interactions

Once both services are running, you can interact with the root agent to see how it calls the remote agent via A2A:

**Simple Dice Rolling:** This interaction uses a local agent, the Roll Agent:

```text
User: Roll a 6-sided die
Bot: I rolled a 4 for you.
```

**Prime Number Checking:**

This interaction uses a remote agent via A2A, the Prime Agent:

```text
User: Is 7 a prime number?
Bot: Yes, 7 is a prime number.
```

**Combined Operations:**

This interaction uses both the local Roll Agent and the remote Prime Agent:

```text
User: Roll a 10-sided die and check if it's prime
Bot: I rolled an 8 for you.
Bot: 8 is not a prime number.
```

## Advanced Configuration: Custom Converters and Interceptors

In scenarios where you want more granular control than what `to_a2a()` provides, you may instantiate and pass an [`A2aAgentExecutorConfig`](https://github.com/google/adk-python/blob/main/src/google/adk/a2a/executor/config.py) directly to the `A2aAgentExecutor`. This allows you to override default data converters and inject execution middleware.

### Converters

Converters handle the bidirectional translation between A2A protocol payloads and ADK's native `Event` or `Part` objects. You can provide your own mapping functions for the following hooks:

- **`a2a_part_converter`**: Converts A2A Message Parts into ADK `Part` objects.
- **`gen_ai_part_converter`**: Converts native ADK `Part` objects into A2A Message Parts.
- **`request_converter`**: Converts an incoming A2A request into an ADK `RunRequest`.
- **`event_converter`**: *(Legacy)* Converts an ADK Event into an A2A Event, used by the legacy executor implementation.
- **`adk_event_converter`**: *(New)* Converts an ADK Event into an A2A Event, used by the new, updated executor implementation.

### Execute Interceptors

You can inject a list of `execute_interceptors` to add middleware logic to the `A2aAgentExecutor` payload processing:

- **`before_agent`**: Executed before the agent starts processing the request. It allows you to inspect or modify the incoming `RequestContext`.
- **`after_event`**: Executed *after* an ADK event is converted to an A2A event. Allows you to mutate the outgoing event before it is enqueued, or return `None` to filter out and drop the event entirely.
- **`after_agent`**: Executed after the agent finishes and the final event is prepared. Use this to inspect or modify the terminal status event (e.g., `completed` or `failed`) before it is sent.

## Agent Executor V2

The new version of the [agent executor](https://github.com/google/adk-python/blob/main/src/google/adk/a2a/executor/a2a_agent_executor_impl.py) is typically enabled when a client sends the required [A2A extension](https://adk.dev/a2a/a2a-extension/index.md).

However, you can also bypass the extension and force the server to use the new executor version by setting the `force_new_version=True` flag when instantiating the `A2aAgentExecutor`. This allows you to use the new executor logic without needing to modify existing clients to send the extension.

```python
from google.adk.a2a.executor import A2aAgentExecutor

executor = A2aAgentExecutor(
            ...,
            force_new_version=True
        )
```

## Next Steps

Now that you have created an agent that's exposing a remote agent via an A2A server, the next step is to learn how to consume it from another agent.

- [**A2A Quickstart (Consuming)**](https://adk.dev/a2a/quickstart-consuming/index.md): Learn how your agent can use other agents using the A2A Protocol.




