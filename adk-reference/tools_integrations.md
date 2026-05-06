# Tools and Integrations for Agents

Check out the following pre-built tools and integrations that you can use with ADK agents. For information on building custom tools, see [Custom Tools](/tools-custom/). For information on submitting integrations to this catalog, see the [Contribution Guide for Integrations](https://github.com/google/adk-docs/blob/main/CONTRIBUTING.md#integrations).

Filter: All Code Connectors Data Google MCP Observability Resilience Search

# A2UI — Agent-to-UI for ADK

Supported in ADKPython

A2UI lets your agent generate **real UI** — cards, forms, charts, tables — not just text. Your agent outputs structured JSON, and a renderer on the client turns it into interactive components.

It's transport-agnostic: A2UI payloads work over A2A, MCP, REST, WebSockets, or any other protocol. The agent describes *what* to show; the client decides *how* to render it.

Learn more about A2UI

[a2ui.org](https://a2ui.org/) has the full specification, component gallery, catalog reference, and renderer documentation.

## Quickstart

### Install the SDK

```bash
pip install a2ui-agent-sdk
```

### 1. Set up the Schema Manager

The `A2uiSchemaManager` loads component catalogs and generates system prompts that teach the LLM how to produce valid A2UI JSON.

```python
from a2ui.core.schema.manager import A2uiSchemaManager
from a2ui.basic_catalog.provider import BasicCatalog

schema_manager = A2uiSchemaManager(
    catalogs=[
        BasicCatalog.get_config(
            examples_path="examples",
        ),
    ],
)
```

Note

The schema manager will automatically detect the A2UI version from incoming client requests. You can also set a version explicitly by passing `version=VERSION_0_9` if needed.

Tip

If you omit the `catalogs` parameter, the schema manager uses the [Basic Catalog](https://a2ui.org/concepts/catalogs/) maintained by the A2UI team, which includes common components like Text, Card, Button, Image, and more. You can also create [custom catalogs](#custom-catalogs) with domain-specific components, or mix the basic catalog with your own — see [Advanced patterns](#advanced-patterns) below.

### 2. Generate the system prompt

The `generate_system_prompt` method combines your agent's role description with the A2UI JSON schema and few-shot examples, so the LLM knows exactly how to format its output.

```python
instruction = schema_manager.generate_system_prompt(
    role_description="You are a helpful assistant that presents information with rich UI.",
    workflow_description="Analyze the user's request and return structured UI when appropriate.",
    ui_description="Use cards for summaries, tables for comparisons, and forms for user input.",
    include_schema=True,
    include_examples=True,
    allowed_components=["Heading", "Text", "Card", "Button", "Table"],
)
```

### 3. Create your ADK agent

Use the generated instruction as the agent's system prompt:

```python
from google.adk.agents.llm_agent import LlmAgent

agent = LlmAgent(
    model="gemini-flash-latest",
    name="ui_agent",
    description="An agent that generates rich UI responses.",
    instruction=instruction,
)
```

### 4. Validate and stream A2UI output

Always validate the LLM's JSON output before sending it to the client. The SDK provides parsing, fixing, and validation utilities:

```python
from a2ui.core.parser.parser import parse_response
from a2ui.a2a import parse_response_to_parts

# Get the active catalog's validator
selected_catalog = schema_manager.get_selected_catalog()

# Option A: Manual parse + validate
response_parts = parse_response(llm_output_text)
for part in response_parts:
    if part.a2ui_json:
        selected_catalog.validator.validate(part.a2ui_json)

# Option B: One-liner that returns A2A Parts
parts = parse_response_to_parts(
    llm_output_text,
    validator=selected_catalog.validator,
    fallback_text="Here's what I found.",
)
```

A2UI payloads are wrapped in A2A `DataPart` with the MIME type `application/json+a2ui` so renderers can identify them:

```python
from a2ui.a2a import create_a2ui_part

part = create_a2ui_part({"type": "Card", "props": {"title": "Hello"}})
# → DataPart(data={...}, metadata={"mimeType": "application/json+a2ui"})
```

## Advanced patterns

### Dynamic catalogs

For agents that need different UI components depending on context (e.g., charts for data queries, forms for configuration), resolve the catalog at runtime and store it in session state:

```python
async def _prepare_session(self, context, run_request, runner):
    session = await super()._prepare_session(context, run_request, runner)

    # Determine client capabilities from request metadata
    capabilities = context.message.metadata.get("a2ui_client_capabilities")

    # Select the right catalog
    a2ui_catalog = self.schema_manager.get_selected_catalog(
        client_ui_capabilities=capabilities
    )
    examples = self.schema_manager.load_examples(a2ui_catalog, validate=True)

    # Store in session state for tool access
    await runner.session_service.append_event(
        session,
        Event(
            actions=EventActions(
                state_delta={
                    "system:a2ui_enabled": True,
                    "system:a2ui_catalog": a2ui_catalog,
                    "system:a2ui_examples": examples,
                }
            ),
        ),
    )
    return session
```

### Custom catalogs

You can define your own component catalogs for domain-specific UI:

```python
from a2ui.core.schema.manager import CatalogConfig

schema_manager = A2uiSchemaManager(
    catalogs=[
        BasicCatalog.get_config(),
        CatalogConfig.from_path(
            name="my_dashboard_catalog",
            catalog_path="catalogs/dashboard.json",
            examples_path="catalogs/dashboard_examples",
        ),
    ],
)
```

### Multi-agent orchestration

Orchestrator agents can aggregate A2UI capabilities from sub-agents and advertise them in the agent card:

```python
from a2ui.a2a import get_a2ui_agent_extension

# Collect catalog IDs from sub-agents
supported_catalog_ids = set()
for subagent in subagents:
    for extension in subagent_card.capabilities.extensions:
        if extension.uri == "https://a2ui.org/a2a-extension/a2ui/v0.9":
            supported_catalog_ids.update(
                extension.params.get("supportedCatalogIds") or []
            )

# Advertise in the orchestrator's AgentCard
agent_card = AgentCard(
    capabilities=AgentCapabilities(
        extensions=[
            get_a2ui_agent_extension(
                supported_catalog_ids=list(supported_catalog_ids),
            )
        ]
    )
)
```

## Samples

The A2UI repository includes ADK sample agents you can run immediately:

| Sample                                                                                            | Description                                                                   |
| ------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------- |
| [restaurant_finder](https://github.com/google/A2UI/tree/main/samples/agent/adk/restaurant_finder) | Static schema agent for searching and displaying restaurant information       |
| [rizzcharts](https://github.com/google/A2UI/tree/main/samples/agent/adk/rizzcharts)               | Dynamic catalog agent that selects chart components based on context          |
| [orchestrator](https://github.com/google/A2UI/tree/main/samples/agent/adk/orchestrator)           | Multi-agent setup that delegates to sub-agents and aggregates UI capabilities |

## Resources

- [A2UI specification](https://a2ui.org/)
- [A2UI GitHub repository](https://github.com/google/A2UI)
- [A2UI Python SDK (`a2ui-agent-sdk`)](https://pypi.org/project/a2ui-agent-sdk/)
- [Agent development guide](https://github.com/google/A2UI/blob/main/agent_sdks/python/agent_development.md)
- [Component gallery](https://a2ui.org/reference/components/)
- [A2A protocol](https://a2a-protocol.org)

# Adspirer MCP tool for ADK

Supported in ADKPythonTypeScript

The [Adspirer MCP Server](https://github.com/amekala/ads-mcp) connects your ADK agent to [Adspirer](https://www.adspirer.com/), an AI-powered advertising platform with 100+ tools across Google Ads, Meta Ads, LinkedIn Ads, and TikTok Ads. This integration gives your agent the ability to create, manage, and optimize ad campaigns using natural language — from keyword research and audience planning to campaign launch and performance analysis.

## How it works

Adspirer is a remote MCP server that acts as a bridge between your ADK agent and advertising platforms. Your agent connects to Adspirer's MCP endpoint, authenticates via OAuth 2.1, and gains access to 100+ tools that map directly to ad platform APIs.

The typical workflow looks like this:

1. **Connect** — Your ADK agent connects to `https://mcp.adspirer.com/mcp` and authenticates via OAuth 2.1. On first run, a browser window opens for you to sign in and authorize access to your ad accounts.
1. **Discover** — The agent discovers available tools based on your connected ad platforms (Google Ads, Meta Ads, LinkedIn Ads, TikTok Ads).
1. **Execute** — The agent can now execute the full campaign lifecycle through natural language: research keywords, plan audiences, create campaigns, analyze performance, optimize budgets, and manage ads — all without touching a dashboard.

Adspirer handles OAuth token management, ad platform API calls, and safety guardrails (e.g., cannot delete campaigns or modify existing budgets) so your agent can operate autonomously with built-in protections.

## Use cases

- **Campaign Creation**: Launch complex ad campaigns across Google, Meta, LinkedIn, and TikTok through natural language. Create Search, Performance Max, YouTube, Demand Gen, image, video, and carousel campaigns without touching a dashboard.
- **Performance Analysis**: Analyze campaign metrics across all connected ad platforms. Ask questions like "Which campaigns have the best ROAS?" or "Where am I wasting spend?" and get actionable insights with optimization recommendations.
- **Keyword Research & Planning**: Research keywords using Google Keyword Planner with real CPC data, search volumes, and competition analysis. Build keyword strategies and add them directly to campaigns.
- **Budget Optimization**: Identify underperforming campaigns, detect budget inefficiencies, and get AI-driven recommendations for spend allocation across channels and campaigns.
- **Ad Management**: Add new ad groups, ad sets, and ads to existing campaigns. A/B test creatives, update ad copy, manage keywords, and pause or resume campaigns — all through your agent.

## Prerequisites

- An [Adspirer](https://www.adspirer.com/) account (free tier available)
- At least one connected ad platform (Google Ads, Meta Ads, LinkedIn Ads, or TikTok Ads) — connect via your Adspirer dashboard after signing up
- See the [Quickstart guide](https://www.adspirer.com/docs/quickstart) for step-by-step setup instructions

## Use with agent

When you run this agent for the first time, a browser window opens automatically to request access via OAuth. Approve the request in your browser to grant the agent access to your connected ad accounts.

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

root_agent = Agent(
    model="gemini-flash-latest",
    name="advertising_agent",
    instruction=(
        "You are an advertising agent that helps users create, manage, "
        "and optimize ad campaigns across Google Ads, Meta Ads, "
        "LinkedIn Ads, and TikTok Ads."
    ),
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "mcp-remote",
                        "https://mcp.adspirer.com/mcp",
                    ],
                ),
                timeout=30,
            ),
        )
    ],
)
```

If you already have an Adspirer access token, you can connect directly using Streamable HTTP without the OAuth browser flow.

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset, StreamableHTTPConnectionParams

ADSPIRER_ACCESS_TOKEN = "YOUR_ADSPIRER_ACCESS_TOKEN"

root_agent = Agent(
    model="gemini-flash-latest",
    name="advertising_agent",
    instruction=(
        "You are an advertising agent that helps users create, manage, "
        "and optimize ad campaigns across Google Ads, Meta Ads, "
        "LinkedIn Ads, and TikTok Ads."
    ),
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url="https://mcp.adspirer.com/mcp",
                headers={
                    "Authorization": f"Bearer {ADSPIRER_ACCESS_TOKEN}",
                },
            ),
        )
    ],
)
```

When you run this agent for the first time, a browser window opens automatically to request access via OAuth. Approve the request in your browser to grant the agent access to your connected ad accounts.

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "advertising_agent",
    instruction:
        "You are an advertising agent that helps users create, manage, " +
        "and optimize ad campaigns across Google Ads, Meta Ads, " +
        "LinkedIn Ads, and TikTok Ads.",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: [
                    "-y",
                    "mcp-remote",
                    "https://mcp.adspirer.com/mcp",
                ],
            },
        }),
    ],
});

export { rootAgent };
```

If you already have an Adspirer access token, you can connect directly using Streamable HTTP without the OAuth browser flow.

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const ADSPIRER_ACCESS_TOKEN = "YOUR_ADSPIRER_ACCESS_TOKEN";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "advertising_agent",
    instruction:
        "You are an advertising agent that helps users create, manage, " +
        "and optimize ad campaigns across Google Ads, Meta Ads, " +
        "LinkedIn Ads, and TikTok Ads.",
    tools: [
        new MCPToolset({
            type: "StreamableHTTPConnectionParams",
            url: "https://mcp.adspirer.com/mcp",
            transportOptions: {
                requestInit: {
                    headers: {
                        Authorization: `Bearer ${ADSPIRER_ACCESS_TOKEN}`,
                    },
                },
            },
        }),
    ],
});

export { rootAgent };
```

## Capabilities

Adspirer provides 100+ MCP tools for full-lifecycle ad campaign management across four major advertising platforms.

| Capability           | Description                                                                    |
| -------------------- | ------------------------------------------------------------------------------ |
| Campaign creation    | Launch Search, PMax, YouTube, Demand Gen, image, video, and carousel campaigns |
| Performance analysis | Analyze metrics, detect anomalies, and get optimization recommendations        |
| Keyword research     | Research keywords with real CPC, search volume, and competition data           |
| Budget optimization  | AI-driven budget allocation and wasted spend detection                         |
| Ad management        | Create and update ads, ad groups, ad sets, headlines, and descriptions         |
| Audience targeting   | Search interests, behaviors, job titles, and custom audiences                  |
| Asset management     | Validate, upload, and discover existing creative assets                        |
| Campaign controls    | Pause, resume, update bids, budgets, and targeting settings                    |

## Supported platforms

| Platform     | Tools | Capabilities                                                                                   |
| ------------ | ----- | ---------------------------------------------------------------------------------------------- |
| Google Ads   | 49    | Search, PMax, YouTube, Demand Gen campaigns, keyword research, ad extensions, audience signals |
| Meta Ads     | 30+   | Image, video, carousel, DCO campaigns, pixel tracking, lead forms, audience insights           |
| LinkedIn Ads | 28    | Sponsored content, lead gen, conversation ads, demographic targeting, engagement analysis      |
| TikTok Ads   | 4     | Campaign management and performance analysis                                                   |

## Additional resources

- [Adspirer Website](https://www.adspirer.com/)
- [Adspirer MCP Server on GitHub](https://github.com/amekala/ads-mcp)
- [Quickstart Guide](https://www.adspirer.com/docs/quickstart)
- [Tool Catalog](https://www.adspirer.com/docs/agent-skills/tools)
- [Core Workflows](https://www.adspirer.com/docs/agent-skills/workflows)
- [Ad Platform Guides](https://www.adspirer.com/docs)

# AG-UI user interface for ADK

Supported in ADKPythonTypeScriptGoJava

Turn your ADK agents into full-featured applications with rich, responsive UIs. [AG-UI](https://docs.ag-ui.com/) is an open protocol that handles streaming events, client state, and bi-directional communication between your agents and users.

[AG-UI](https://github.com/ag-ui-protocol/ag-ui) provides a consistent interface to empower rich clients across technology stacks, from mobile to the web and even the command line. There are a number of different clients that support AG-UI:

- [CopilotKit](https://copilotkit.ai) provides tooling and components to tightly integrate your agent with web applications
- Clients for [Kotlin](https://github.com/ag-ui-protocol/ag-ui/tree/main/sdks/community/kotlin), [Java](https://github.com/ag-ui-protocol/ag-ui/tree/main/sdks/community/java), [Go](https://github.com/ag-ui-protocol/ag-ui/tree/main/sdks/community/go/example/client), and [CLI implementations](https://github.com/ag-ui-protocol/ag-ui/tree/main/apps/client-cli-example/src) in TypeScript

This tutorial uses CopilotKit to create a sample app backed by an ADK agent that demonstrates some of the features supported by AG-UI.

## Quickstart

To get started, let's create a sample application with an ADK agent and a simple web client:

1. Create the app:

   ```bash
   npx copilotkit@latest create -f adk
   ```

1. Set your Google API key:

   ```bash
   export GOOGLE_API_KEY="your-api-key"
   ```

1. Install dependencies and run:

   ```bash
   npm install && npm run dev
   ```

This starts two servers:

- **http://localhost:3000** - The web UI (open this in your browser)
- **http://localhost:8000** - The ADK agent API (backend only)

Open <http://localhost:3000> in your browser to chat with your agent.

## Features

### Chat

Chat is a familiar interface for exposing your agent, and AG-UI handles streaming messages between your users and agents:

src/app/page.tsx

```tsx
<CopilotSidebar
  clickOutsideToClose={false}
  defaultOpen={true}
  labels={{
    title: "Popup Assistant",
    initial: "👋 Hi, there! You're chatting with an agent. This agent comes with a few tools to get you started..."
  }}
/>
```

Learn more about the chat UI [in the CopilotKit docs](https://docs.copilotkit.ai/adk/agentic-chat-ui).

### Generative UI

AG-UI lets you share tool information with a Generative UI so that it can be displayed to users:

src/app/page.tsx

```tsx
useRenderToolCall(
  {
    name: "get_weather",
    description: "Get the weather for a given location.",
    parameters: [{ name: "location", type: "string", required: true }],
    render: ({ args }) => {
      return <WeatherCard location={args.location} themeColor={themeColor} />;
    },
  },
  [themeColor],
);
```

Learn more about Generative UI [in the CopilotKit docs](https://docs.copilotkit.ai/adk/generative-ui).

### Shared State

ADK agents can be stateful, and synchronizing that state between your agents and your UIs enables powerful and fluid user experiences. State can be synchronized both ways so agents are automatically aware of changes made by your user or other parts of your application:

src/app/page.tsx

```tsx
const { state, setState } = useCoAgent<AgentState>({
  name: "my_agent",
  initialState: {
    proverbs: [
      "A journey of a thousand miles begins with a single step.",
    ],
  },
})
```

Learn more about shared state [in the CopilotKit docs](https://docs.copilotkit.ai/adk/shared-state).

## Resources

To see what other features you can build into your UI with AG-UI, refer to the CopilotKit docs:

- [Agentic Generative UI](https://docs.copilotkit.ai/adk/generative-ui/agentic)
- [Human in the Loop](https://docs.copilotkit.ai/adk/human-in-the-loop)
- [Frontend Actions](https://docs.copilotkit.ai/adk/frontend-actions)

Or try them out in the [AG-UI Dojo](https://dojo.ag-ui.com).

# Google Cloud Agent Registry

Supported in ADKPython v1.26.0Preview

The Agent Registry client library withins Agent Development Kit (ADK) allows developers to discover, look up, and connect to AI Agents and MCP Servers cataloged within the [Google Cloud Agent Registry](https://docs.cloud.google.com/agent-registry/overview). This enables dynamic composition of agent-based applications using governed components.

## Use cases

- **Accelerated Development**: Easily find and reuse existing agents and tools (MCP Servers) from the central catalog instead of rebuilding them.
- **Dynamic Integration**: Discover agent and MCP Server endpoints at runtime, making applications more robust to changes in the environment.
- **Enhanced Governance**: Utilize governed and verified components from the registry within your ADK applications.

## Prerequisites

- A [Google Cloud project](https://docs.cloud.google.com/resource-manager/docs/creating-managing-projects).
- The [Agent Registry API](https://docs.cloud.google.com/agent-registry/setup) enabled in your Google Cloud project.
- Authentication configured for your environment. You should log in using [Application Default Credentials](https://docs.cloud.google.com/docs/authentication/application-default-credentials) (`gcloud auth application-default login`).
- Environment variables `GOOGLE_CLOUD_PROJECT` set to your project ID and `GOOGLE_CLOUD_LOCATION` set to the appropriate region (e.g., `global`, `us-central1`).
- `google-adk` library installed.

## Installation

The [Agent Registry](https://docs.cloud.google.com/agent-registry/overview) integration is part of the core ADK library.

```bash
pip install google-adk
```

### Optional Dependencies

To use the full capabilities of the AgentRegistry integration, you may need to install additional extras depending on your use case:

**For A2A (Agent-to-Agent) Support:** If you plan to use `get_remote_a2a_agent` or interact with remote A2A-compliant agents, install the `a2a` extra:

```bash
pip install "google-adk[a2a]"
```

**For Agent Identity (GCP Auth Provider):** If you need to use the `GcpAuthProvider` (e.g., when `get_mcp_toolset` automatically resolves authentication via IAM bindings for registered MCP servers), install the `agent-identity` extra:

```bash
pip install "google-adk[agent-identity]"
```

## Use with Agent

The primary way to use the Agent Registry integration within an ADK agent is to dynamically fetch remote agents or toolsets using the AgentRegistry client.

```py
from google.adk.agents.llm_agent import LlmAgent
from google.adk.integrations.agent_registry import AgentRegistry
import os

# 1. Initialization
project_id = os.environ.get("GOOGLE_CLOUD_PROJECT")
location = os.environ.get("GOOGLE_CLOUD_LOCATION", "global")

if not project_id:
    raise ValueError("GOOGLE_CLOUD_PROJECT environment variable not set.")

registry = AgentRegistry(
    project_id=project_id,
    location=location,
)

# 2. Listing Resources
print("Listing Agents...")
agents_response = registry.list_agents()
for agent in agents_response.get("agents", []):
    print(f"  - {agent.get('name')} ({agent.get('displayName')})")

print("Listing MCP Servers...")
mcp_servers_response = registry.list_mcp_servers()
for server in mcp_servers_response.get("mcpServers", []):
    print(f"  - {server.get('name')} ({server.get('displayName')})")

# 3. Using a Remote A2A Agent
# Replace with the full resource name of your registered agent
agent_name = f"projects/{project_id}/locations/{location}/agents/YOUR_AGENT_ID"
my_remote_agent = registry.get_remote_a2a_agent(agent_name=agent_name)

# 4. Using an MCP Toolset
# Replace with the full resource name of your registered MCP server
mcp_server_name = f"projects/{project_id}/locations/{location}/mcpServers/YOUR_MCP_SERVER_ID"
my_mcp_toolset = registry.get_mcp_toolset(mcp_server_name=mcp_server_name)

# 5. Example Agent Composition
main_agent = LlmAgent(
    model="gemini-flash-latest", # Or your preferred model
    name="demo_agent",
    instruction="You can leverage registered tools and sub-agents.",
    tools=[my_mcp_toolset],
    sub_agents=[my_remote_agent],
)
```

## Authentication for Google MCP Servers and Remote A2A Agents

### Remote A2A Agents

If you are connecting to a Google A2A agent, you need to pass an `httpx.AsyncClient` configured with Google authentication headers to the `get_remote_a2a_agent` method.

Example:

```python
import httpx
import google.auth
from google.auth.transport.requests import Request

class GoogleAuth(httpx.Auth):
    def __init__(self):
        self.creds, _ = google.auth.default()
    def auth_flow(self, request):
        if not self.creds.valid:
            self.creds.refresh(Request())
        request.headers["Authorization"] = f"Bearer {self.creds.token}"
        yield request

httpx_client = httpx.AsyncClient(auth=GoogleAuth(), timeout=httpx.Timeout(60.0))
remote_agent = registry.get_remote_a2a_agent(
    f"projects/{project_id}/locations/{location}/agents/YOUR_AGENT_ID",
    httpx_client=httpx_client,
)
```

### Google MCP Servers

For Google MCP servers, authentication headers are automatically passed in. However, if automatic authentication is not working as expected, you can manually provide headers using the `header_provider` argument in the `AgentRegistry` constructor.

Example:

```python
import google.auth
from google.auth.transport.requests import Request
from google.adk.integrations.agent_registry import AgentRegistry

def google_auth_header_provider(context):
    creds, _ = google.auth.default()
    if not creds.valid:
        creds.refresh(Request())
    return {"Authorization": f"Bearer {creds.token}"}

registry = AgentRegistry(
    project_id=project_id,
    location=location,
    header_provider=google_auth_header_provider
)
```

## API Reference

The AgentRegistry class provides the following core methods:

- `list_mcp_servers(self, filter_str, page_size, page_token)`: Fetches a list of registered MCP Servers.
- `get_mcp_server(self, name)`: Retrieves detailed metadata of a specific MCP Server.
- `get_mcp_toolset(self, mcp_server_name)`: Constructs an ADK McpToolset instance from a registered MCP Server.
- `list_agents(self, filter_str, page_size, page_token)`: Fetches a list of registered A2A Agents.
- `get_agent_info(self, name)`: Retrieves detailed metadata of a specific A2A Agent.
- `get_remote_a2a_agent(self, agent_name)`: Creates an ADK RemoteA2aAgent instance for a registered A2A Agent.

## Configuration Options

The AgentRegistry constructor accepts the following arguments:

- `project_id` (str, required): The Google Cloud project ID.
- `location` (str, required): The Google Cloud location/region, such as "global", "us-central1".
- `header_provider` (Callable, optional): A callable that takes a ReadonlyContext and returns a dictionary of custom headers to be included in requests made by the [McpToolset](/tools-custom/mcp-tools/#mcptoolset-class) or [RemoteA2aAgent](/a2a/quickstart-consuming-go/#quickstart-consuming-a-remote-agent-via-a2a) to the target services. This does not affect headers used to call the Agent Registry API itself.

## Additional resources

- [Sample Agent Code](https://github.com/google/adk-python/tree/main/contributing/samples/agent_registry_agent)
- [Agent Registry Client](https://github.com/google/adk-python/blob/main/src/google/adk/integrations/agent_registry/agent_registry.py)
- [Google Auth Library](https://google-auth.readthedocs.io/en/latest/)

# Agent Search tool for ADK

Supported in ADKPython v0.1.0

The `vertex_ai_search_tool` uses Google Cloud Agent Search, enabling the agent to search across your private, configured data stores (e.g., internal documents, company policies, knowledge bases). This built-in tool requires you to provide the specific data store ID during configuration. For further details of the tool, see [Understanding Grounding with Search](/grounding/grounding_with_search/).

Warning: Single tool per agent limitation

This tool can only be used ***by itself*** within an agent instance. For more information about this limitation and workarounds, see [Limitations for ADK tools](/tools/limitations/#one-tool-one-agent).

```py
# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import asyncio

from google.adk.agents import LlmAgent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types
from google.adk.tools import VertexAiSearchTool

# Replace with your Agent Search Datastore ID, and respective region (e.g. us-central1 or global).
# Format: projects/<PROJECT_ID>/locations/<REGION>/collections/default_collection/dataStores/<DATASTORE_ID>
DATASTORE_PATH = "DATASTORE_PATH_HERE"

# Constants
APP_NAME_VSEARCH = "vertex_search_app"
USER_ID_VSEARCH = "user_vsearch_1"
SESSION_ID_VSEARCH = "session_vsearch_1"
AGENT_NAME_VSEARCH = "doc_qa_agent"
GEMINI_2_FLASH = "gemini-2.0-flash"

# Tool Instantiation
# You MUST provide your datastore ID here.
vertex_search_tool = VertexAiSearchTool(data_store_id=DATASTORE_PATH)

# Agent Definition
doc_qa_agent = LlmAgent(
    name=AGENT_NAME_VSEARCH,
    model=GEMINI_2_FLASH,  # Requires Gemini model
    tools=[vertex_search_tool],
    instruction=f"""You are a helpful assistant that answers questions based on information found in the document store: {DATASTORE_PATH}.
    Use the search tool to find relevant information before answering.
    If the answer isn't in the documents, say that you couldn't find the information.
    """,
    description="Answers questions using a specific Agent Search datastore.",
)

# Session and Runner Setup
session_service_vsearch = InMemorySessionService()
runner_vsearch = Runner(
    agent=doc_qa_agent,
    app_name=APP_NAME_VSEARCH,
    session_service=session_service_vsearch,
)
session_vsearch = session_service_vsearch.create_session(
    app_name=APP_NAME_VSEARCH, user_id=USER_ID_VSEARCH, session_id=SESSION_ID_VSEARCH
)


# Agent Interaction Function
async def call_vsearch_agent_async(query):
    print("\n--- Running Search Agent ---")
    print(f"Query: {query}")
    if "DATASTORE_PATH_HERE" in DATASTORE_PATH:
        print(
            "Skipping execution: Please replace DATASTORE_PATH_HERE with your actual datastore ID."
        )
        print("-" * 30)
        return

    content = types.Content(role="user", parts=[types.Part(text=query)])
    final_response_text = "No response received."
    try:
        async for event in runner_vsearch.run_async(
            user_id=USER_ID_VSEARCH, session_id=SESSION_ID_VSEARCH, new_message=content
        ):
            # Like Google Search, results are often embedded in the model's response.
            if event.is_final_response() and event.content and event.content.parts:
                final_response_text = event.content.parts[0].text.strip()
                print(f"Agent Response: {final_response_text}")
                # You can inspect event.grounding_metadata for source citations
                if event.grounding_metadata:
                    print(
                        f"  (Grounding metadata found with {len(event.grounding_metadata.grounding_attributions)} attributions)"
                    )

    except Exception as e:
        print(f"An error occurred: {e}")
        print(
            "Ensure your datastore ID is correct and the service account has permissions."
        )
    print("-" * 30)


# --- Run Example ---
async def run_vsearch_example():
    # Replace with a question relevant to YOUR datastore content
    await call_vsearch_agent_async(
        "Summarize the main points about the Q2 strategy document."
    )
    await call_vsearch_agent_async("What safety procedures are mentioned for lab X?")


# Execute the example
# await run_vsearch_example()

# Running locally due to potential colab asyncio issues with multiple awaits
try:
    asyncio.run(run_vsearch_example())
except RuntimeError as e:
    if "cannot be called from a running event loop" in str(e):
        print(
            "Skipping execution in running event loop (like Colab/Jupyter). Run locally."
        )
    else:
        raise e
```

# AgentMail MCP tool for ADK

Supported in ADKPythonTypeScript

The [AgentMail MCP Server](https://github.com/agentmail-to/agentmail-mcp) connects your ADK agent to [AgentMail](https://agentmail.to/), an email inbox API built for AI agents. This integration gives your agent its own email inboxes to send, receive, reply to, and forward messages using natural language.

## Use cases

- **Give Agents Their Own Inboxes**: Create dedicated email addresses for your agents so they can send and receive emails independently, just like a human team member.
- **Automate Email Workflows**: Let your agent handle email conversations end to end, including sending initial outreach, reading replies, and following up on threads.
- **Manage Conversations Across Inboxes**: List and search across threads and messages, forward emails, and retrieve attachments to keep your agent informed and responsive.

## Prerequisites

- Create an [AgentMail account](https://agentmail.to/)
- Generate an API key from the [AgentMail Dashboard](https://agentmail.to/)

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

AGENTMAIL_API_KEY = "YOUR_AGENTMAIL_API_KEY"

root_agent = Agent(
    model="gemini-flash-latest",
    name="agentmail_agent",
    instruction="Help users manage email inboxes and send messages",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "agentmail-mcp",
                    ],
                    env={
                        "AGENTMAIL_API_KEY": AGENTMAIL_API_KEY,
                    }
                ),
                timeout=30,
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const AGENTMAIL_API_KEY = "YOUR_AGENTMAIL_API_KEY";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "agentmail_agent",
    instruction: "Help users manage email inboxes and send messages",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: ["-y", "agentmail-mcp"],
                env: {
                    AGENTMAIL_API_KEY: AGENTMAIL_API_KEY,
                },
            },
        }),
    ],
});

export { rootAgent };
```

## Available tools

### Inbox management

| Tool           | Description                                   |
| -------------- | --------------------------------------------- |
| `list_inboxes` | List all inboxes                              |
| `get_inbox`    | Get details for a specific inbox              |
| `create_inbox` | Create a new inbox with a username and domain |
| `delete_inbox` | Delete an inbox                               |

### Thread management

| Tool             | Description                             |
| ---------------- | --------------------------------------- |
| `list_threads`   | List threads in an inbox                |
| `get_thread`     | Get a specific thread with its messages |
| `get_attachment` | Download an attachment from a message   |

### Message operations

| Tool               | Description                                   |
| ------------------ | --------------------------------------------- |
| `send_message`     | Send a new email from an inbox                |
| `reply_to_message` | Reply to an existing message                  |
| `forward_message`  | Forward a message to another recipient        |
| `update_message`   | Update message properties such as read status |

## Additional resources

- [AgentMail MCP Server Repository](https://github.com/agentmail-to/agentmail-mcp)
- [AgentMail Documentation](https://docs.agentmail.to/)
- [AgentMail Toolkit](https://github.com/agentmail-to/agentmail-toolkit)

# AgentOps observability for ADK

Supported in ADKPython

**With just two lines of code**, [AgentOps](https://www.agentops.ai) provides session replays, metrics, and monitoring for agents.

## Why AgentOps for ADK?

Observability is a key aspect of developing and deploying conversational AI agents. It allows developers to understand how their agents are performing, how their agents are interacting with users, and how their agents use external tools and APIs.

By integrating AgentOps, developers can gain deep insights into their ADK agent's behavior, LLM interactions, and tool usage.

Google ADK includes its own OpenTelemetry-based tracing system, primarily aimed at providing developers with a way to trace the basic flow of execution within their agents. AgentOps enhances this by offering a dedicated and more comprehensive observability platform with:

- **Unified Tracing and Replay Analytics:** Consolidate traces from ADK and other components of your AI stack.
- **Rich Visualization:** Intuitive dashboards to visualize agent execution flow, LLM calls, and tool performance.
- **Detailed Debugging:** Drill down into specific spans, view prompts, completions, token counts, and errors.
- **LLM Cost and Latency Tracking:** Track latencies, costs (via token usage), and identify bottlenecks.
- **Simplified Setup:** Get started with just a few lines of code.

*AgentOps dashboard displaying a trace from a multi-step ADK application execution. You can see the hierarchical structure of spans, including the main agent workflow, individual sub-agents, LLM calls, and tool executions. Note the clear hierarchy: the main workflow agent span contains child spans for various sub-agent operations, LLM calls, and tool executions.*

## Getting Started with AgentOps and ADK

Integrating AgentOps into your ADK application is straightforward:

1. **Install AgentOps:**

   ```bash
   pip install -U agentops
   ```

1. **Create an API Key** Create a user API key here: [Create API Key](https://app.agentops.ai/settings/projects) and configure your environment:

   Add your API key to your environment variables:

   ```text
   AGENTOPS_API_KEY=<YOUR_AGENTOPS_API_KEY>
   ```

1. **Initialize AgentOps:** Add the following lines at the beginning of your ADK application script (e.g., your main Python file running the ADK `Runner`):

   ```python
   import agentops
   agentops.init()
   ```

   This will initiate an AgentOps session as well as automatically track ADK agents.

   Detailed example:

   ```python
   import agentops
   import os
   from dotenv import load_dotenv

   # Load environment variables (optional, if you use a .env file for API keys)
   load_dotenv()

   agentops.init(
       api_key=os.getenv("AGENTOPS_API_KEY"), # Your AgentOps API Key
       trace_name="my-adk-app-trace"  # Optional: A name for your trace
       # auto_start_session=True is the default.
       # Set to False if you want to manually control session start/end.
   )
   ```

   > 🚨 🔑 You can find your AgentOps API key on your [AgentOps Dashboard](https://app.agentops.ai/) after signing up. It's recommended to set it as an environment variable (`AGENTOPS_API_KEY`).

Once initialized, AgentOps will automatically begin instrumenting your ADK agent.

**This is all you need to capture all telemetry data for your ADK agent**

## How AgentOps Instruments ADK

AgentOps employs a sophisticated strategy to provide seamless observability without conflicting with ADK's native telemetry:

1. **Neutralizing ADK's Native Telemetry:** AgentOps detects ADK and intelligently patches ADK's internal OpenTelemetry tracer (typically `trace.get_tracer('gcp.vertex.agent')`). It replaces it with a `NoOpTracer`, ensuring that ADK's own attempts to create telemetry spans are effectively silenced. This prevents duplicate traces and allows AgentOps to be the authoritative source for observability data.

1. **AgentOps-Controlled Span Creation:** AgentOps takes control by wrapping key ADK methods to create a logical hierarchy of spans:

   - **Agent Execution Spans (e.g., `adk.agent.MySequentialAgent`):** When an ADK agent (like `BaseAgent`, `SequentialAgent`, or `LlmAgent`) starts its `run_async` method, AgentOps initiates a parent span for that agent's execution.
   - **LLM Interaction Spans (e.g., `adk.llm.gemini-pro`):** For calls made by an agent to an LLM (via ADK's `BaseLlmFlow._call_llm_async`), AgentOps creates a dedicated child span, typically named after the LLM model. This span captures request details (prompts, model parameters) and, upon completion (via ADK's `_finalize_model_response_event`), records response details like completions, token usage, and finish reasons.
   - **Tool Usage Spans (e.g., `adk.tool.MyCustomTool`):** When an agent uses a tool (via ADK's `functions.__call_tool_async`), AgentOps creates a single, comprehensive child span named after the tool. This span includes the tool's input parameters and the result it returns.

1. **Rich Attribute Collection:** AgentOps reuses ADK's internal data extraction logic. It patches ADK's specific telemetry functions (e.g., `google.adk.telemetry.trace_tool_call`, `trace_call_llm`). The AgentOps wrappers for these functions take the detailed information ADK gathers and attach it as attributes to the *currently active AgentOps span*.

## Visualizing Your ADK Agent in AgentOps

When you instrument your ADK application with AgentOps, you gain a clear, hierarchical view of your agent's execution in the AgentOps dashboard.

1. **Initialization:** When `agentops.init()` is called (e.g., `agentops.init(trace_name="my_adk_application")`), an initial parent span is created if the init param `auto_start_session=True` (true by default). This span, often named similar to `my_adk_application.session`, will be the root for all operations within that trace.

1. **ADK Runner Execution:** When an ADK `Runner` executes a top-level agent (e.g., a `SequentialAgent` orchestrating a workflow), AgentOps creates a corresponding agent span under the session trace. This span will reflect the name of your top-level ADK agent (e.g., `adk.agent.YourMainWorkflowAgent`).

1. **Sub-Agent and LLM/Tool Calls:** As this main agent executes its logic, including calling sub-agents, LLMs, or tools:

   - Each **sub-agent execution** will appear as a nested child span under its parent agent.
   - Calls to **Large Language Models** will generate further nested child spans (e.g., `adk.llm.<model_name>`), capturing prompt details, responses, and token usage.
   - **Tool invocations** will also result in distinct child spans (e.g., `adk.tool.<your_tool_name>`), showing their parameters and results.

This creates a waterfall of spans, allowing you to see the sequence, duration, and details of each step in your ADK application. All relevant attributes, such as LLM prompts, completions, token counts, tool inputs/outputs, and agent names, are captured and displayed.

For a practical demonstration, you can explore a sample Jupyter Notebook that illustrates a human approval workflow using Google ADK and AgentOps: [Google ADK Human Approval Example on GitHub](https://github.com/AgentOps-AI/agentops/blob/main/examples/google_adk/human_approval.ipynb).

This example showcases how a multi-step agent process with tool usage is visualized in AgentOps.

## Benefits

- **Effortless Setup:** Minimal code changes for comprehensive ADK tracing.
- **Deep Visibility:** Understand the inner workings of complex ADK agent flows.
- **Faster Debugging:** Quickly pinpoint issues with detailed trace data.
- **Performance Optimization:** Analyze latencies and token usage.

By integrating AgentOps, ADK developers can significantly enhance their ability to build, debug, and maintain robust AI agents.

## Further Information

To get started, [create an AgentOps account](http://app.agentops.ai). For feature requests or bug reports, please reach out to the AgentOps team on the [AgentOps Repo](https://github.com/AgentOps-AI/agentops).

### Extra links

🐦 [Twitter](http://x.com/agentopsai) • 📢 [Discord](http://x.com/agentopsai) • 🖇️ [AgentOps Dashboard](http://app.agentops.ai) • 📙 [Documentation](http://docs.agentops.ai)

# AgentPhone MCP tool for ADK

Supported in ADKPythonTypeScript

The [AgentPhone MCP Server](https://github.com/AgentPhone-AI/agentphone-mcp) connects your ADK agent to [AgentPhone](https://agentphone.to/), a telephony platform built for AI agents. This integration gives your agent the ability to make and receive phone calls, send and receive SMS, manage phone numbers, and create autonomous AI voice agents using natural language.

## Use cases

- **Autonomous Phone Calls**: Have your agent call a phone number and hold a full AI-powered conversation about a specified topic, returning the complete transcript when done.
- **SMS Messaging**: Send and receive text messages, manage conversation threads across multiple phone numbers, and retrieve message history.
- **Phone Number Management**: Provision phone numbers with specific area codes, assign them to agents, and release them when no longer needed.
- **AI Voice Agents**: Create agents with configurable voices, system prompts, and model tiers (turbo, balanced, max) that autonomously handle inbound and outbound calls without requiring webhooks.
- **Call Transfer & Voicemail**: Configure agents to transfer calls to a human and set up voicemail greetings for unanswered calls.
- **Webhook Integration**: Set up project-level or per-agent webhooks to receive real-time notifications for inbound messages and call events.

## Prerequisites

- Create an [AgentPhone account](https://agentphone.to/)
- Generate an API key from the [AgentPhone Settings](https://agentphone.to/)

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

AGENTPHONE_API_KEY = "YOUR_AGENTPHONE_API_KEY"

root_agent = Agent(
    model="gemini-flash-latest",
    name="agentphone_agent",
    instruction="Help users make phone calls, send SMS, and manage phone numbers",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "agentphone-mcp",
                    ],
                    env={
                        "AGENTPHONE_API_KEY": AGENTPHONE_API_KEY,
                    }
                ),
                timeout=30,
            ),
        )
    ],
)
```

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams

AGENTPHONE_API_KEY = "YOUR_AGENTPHONE_API_KEY"

root_agent = Agent(
    model="gemini-flash-latest",
    name="agentphone_agent",
    instruction="Help users make phone calls, send SMS, and manage phone numbers",
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url="https://mcp.agentphone.to/mcp",
                headers={
                    "Authorization": f"Bearer {AGENTPHONE_API_KEY}",
                },
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const AGENTPHONE_API_KEY = "YOUR_AGENTPHONE_API_KEY";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "agentphone_agent",
    instruction: "Help users make phone calls, send SMS, and manage phone numbers",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: ["-y", "agentphone-mcp"],
                env: {
                    AGENTPHONE_API_KEY: AGENTPHONE_API_KEY,
                },
            },
        }),
    ],
});

export { rootAgent };
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const AGENTPHONE_API_KEY = "YOUR_AGENTPHONE_API_KEY";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "agentphone_agent",
    instruction: "Help users make phone calls, send SMS, and manage phone numbers",
    tools: [
        new MCPToolset({
            type: "StreamableHTTPConnectionParams",
            url: "https://mcp.agentphone.to/mcp",
            transportOptions: {
                requestInit: {
                    headers: {
                        Authorization: `Bearer ${AGENTPHONE_API_KEY}`,
                    },
                },
            },
        }),
    ],
});

export { rootAgent };
```

## Available tools

### Account

| Tool               | Description                                                             |
| ------------------ | ----------------------------------------------------------------------- |
| `account_overview` | Full snapshot of account: agents, numbers, webhook status, usage limits |
| `get_usage`        | Detailed usage stats: plan limits, number quotas, message/call volume   |

### Phone numbers

| Tool           | Description                                                     |
| -------------- | --------------------------------------------------------------- |
| `list_numbers` | List all phone numbers in account                               |
| `buy_number`   | Purchase a new phone number with optional country and area code |

### SMS / Messages

| Tool                  | Description                                                 |
| --------------------- | ----------------------------------------------------------- |
| `send_message`        | Send an SMS or iMessage from an agent's phone number        |
| `get_messages`        | Get SMS messages for a specific phone number                |
| `list_conversations`  | List SMS conversation threads, optionally filtered by agent |
| `get_conversation`    | Get a specific conversation with full message history       |
| `update_conversation` | Set or clear metadata on a conversation                     |

### Voice calls

| Tool                     | Description                                                                                  |
| ------------------------ | -------------------------------------------------------------------------------------------- |
| `list_calls`             | List recent calls with optional agent, number, status, or direction filters                  |
| `get_call`               | Get call details and transcript with optional long-polling                                   |
| `make_call`              | Place an outbound call with optional voice override, using webhook for conversation handling |
| `make_conversation_call` | Place an autonomous AI call with optional voice override that returns the full transcript    |

### Agents

| Tool            | Description                                                                            |
| --------------- | -------------------------------------------------------------------------------------- |
| `list_agents`   | List all agents with phone numbers and voice config                                    |
| `create_agent`  | Create a new agent with voice, system prompt, model tier, call transfer, and voicemail |
| `update_agent`  | Update agent configuration including voice, model tier, transfer, and voicemail        |
| `delete_agent`  | Delete an agent                                                                        |
| `get_agent`     | Get agent details including numbers and voice config                                   |
| `attach_number` | Assign a phone number to an agent                                                      |
| `detach_number` | Detach a phone number from an agent                                                    |
| `list_voices`   | List available voice options                                                           |

### Webhooks

All webhook tools accept an optional `agent_id` parameter. When provided, the operation targets that agent's webhook. When omitted, it targets the project-level default. Agent-level webhooks take priority over project-level.

| Tool                      | Description                                          |
| ------------------------- | ---------------------------------------------------- |
| `get_webhook`             | Get webhook configuration                            |
| `set_webhook`             | Set webhook URL for inbound messages and call events |
| `delete_webhook`          | Remove a webhook                                     |
| `test_webhook`            | Send a test event to verify a webhook is working     |
| `list_webhook_deliveries` | View recent webhook delivery history                 |

## Configuration

The AgentPhone MCP server can be configured using environment variables:

| Variable              | Description             | Default                     |
| --------------------- | ----------------------- | --------------------------- |
| `AGENTPHONE_API_KEY`  | Your AgentPhone API key | Required (stdio mode)       |
| `AGENTPHONE_BASE_URL` | Override API base URL   | `https://api.agentphone.to` |

For remote HTTP mode, pass the API key via the `Authorization: Bearer` header instead of an environment variable.

## Additional resources

- [AgentPhone MCP Server on GitHub](https://github.com/AgentPhone-AI/agentphone-mcp)
- [agentphone-mcp on npm](https://www.npmjs.com/package/agentphone-mcp)
- [AgentPhone Website](https://agentphone.to/)

# Google Cloud API Registry tool for ADK

Supported in ADKPython v1.20.0Preview

The Google Cloud API Registry connector tool for Agent Development Kit (ADK) lets you access a wide range of Google Cloud services for your agents as Model Context Protocol (MCP) servers through the [Google Cloud API Registry](https://docs.cloud.google.com/api-registry/docs/overview). You can configure this tool to connect your agent to your Google Cloud projects and dynamically access Cloud services enabled for that project.

Preview release

The Google Cloud API Registry feature is a Preview release. For more information, see the [launch stage descriptions](https://cloud.google.com/products#product-launch-stages).

## Prerequisites

Before using the API Registry with your agent, you need to ensure the following:

- **Google Cloud project:** Configure your agent to access AI models using an existing Google Cloud project.
- **API Registry access:** The environment where your agent runs needs Google Cloud [Application Default Credentials](https://docs.cloud.google.com/docs/authentication/provide-credentials-adc) with the `apiregistry.viewer` role to list available MCP servers.
- **Cloud APIs:** In your Google Cloud project, enable the *cloudapiregistry.googleapis.com* and *apihub.googleapis.com* Google Cloud APIs.
- **MCP Server and Tool access:** Make sure you enable the MCP Servers in the API Registry for the Google Cloud services in your Cloud Project that you want access with your agent. You can enable this in the Cloud Console or use a gcloud command such as: `gcloud beta api-registry mcp enable bigquery.googleapis.com --project={PROJECT_ID}`. The credentials used by the agent must have permissions to access the MCP server and the underlying services used by the tools. For example, to use BigQuery tools, the service account needs BigQuery IAM roles like `bigquery.dataViewer` and `bigquery.jobUser`. For more information about required permissions, see [Authentication and access](#auth).

You can check what MCP servers are enabled with API Registry using the following gcloud command:

```console
gcloud beta api-registry mcp servers list --project={PROJECT_ID}.
```

## Use with agent

When configuring the API Registry connector tool with an agent, you first initialize the ***ApiRegistry*** class to establish a connection with Cloud services, and then use the `get_toolset()` function to retrieve a toolset for a specific MCP server registered in the API Registry. The following code example demonstrates how to create an agent that uses tools from an MCP server listed in API Registry. This agent is designed to interact with BigQuery:

```python
import os
from google.adk.agents.llm_agent import LlmAgent
from google.adk.tools.api_registry import ApiRegistry

# Configure with your Google Cloud Project ID and registered MCP server name
PROJECT_ID = "your-google-cloud-project-id"
MCP_SERVER_NAME = "projects/your-google-cloud-project-id/locations/global/mcpServers/your-mcp-server-name"

# Example header provider for BigQuery, a project header is required.
def header_provider(context):
    return {"x-goog-user-project": PROJECT_ID}

# Initialize ApiRegistry
api_registry = ApiRegistry(
    api_registry_project_id=PROJECT_ID,
    header_provider=header_provider
)

# Get the toolset for the specific MCP server
registry_tools = api_registry.get_toolset(
    mcp_server_name=MCP_SERVER_NAME,
    # Optionally filter tools:
    #tool_filter=["list_datasets", "run_query"]
)

# Create an agent with the tools
root_agent = LlmAgent(
    model="gemini-flash-latest", # Or your preferred model
    name="bigquery_assistant",
    instruction="""
Help user access their BigQuery data using the available tools.
    """,
    tools=[registry_tools],
)
```

For the complete code for this example, see the [api_registry_agent](https://github.com/google/adk-python/tree/main/contributing/samples/api_registry_agent/) sample. For information on the configuration options, see [Configuration](#configuration). For information on the authentication for this tool, see [Authentication and access](#auth).

## Authentication and access

Using the API Registry with your agent requires authentication for the services the agent accesses. By default the tool uses Google Cloud [Application Default Credentials](https://docs.cloud.google.com/docs/authentication/provide-credentials-adc) for authentication. When using this tool make sure your agent has the following permissions and access:

- **API Registry access:** The `ApiRegistry` class uses Application Default Credentials (`google.auth.default()`) to authenticate requests to the Google Cloud API Registry to list the available MCP servers. Ensure the environment where the agent runs has credentials with the necessary permissions to view the API Registry resources, such as `apiregistry.viewer`.

- **MCP Server and Tool access:** The `McpToolset` returned by `get_toolset` also uses the Google Cloud Application Default Credentials by default to authenticate calls to the actual MCP server endpoint. The credentials used must have the necessary permissions for both:

  1. Accessing the MCP server itself.
  1. Utilizing the underlying services and resources that the tools interact with.

- **MCP Tool user role:** Allow the account used by your agent to call MCP tools through the API registry by granting the MCP tool user role: `gcloud projects add-iam-policy-binding {PROJECT_ID} --member={member} --role="roles/mcp.toolUser"`

For example, when using MCP server tools that interact with BigQuery, the account associated with the credentials, such as a service account, must be granted appropriate BigQuery IAM roles, such as `bigquery.dataViewer` or `bigquery.jobUser`, within your Google Cloud project to access datasets and run queries. In the case of the bigquery MCP server, a `"x-goog-user-project": PROJECT_ID` header is required to use its tools Additional headers for authentication or project context can be injected via the `header_provider` argument in the `ApiRegistry` constructor.

## Configuration

The ***APIRegistry*** object has the following configuration options:

- **`api_registry_project_id`** (str): The Google Cloud Project ID where the API Registry is located.
- **`location`** (str, optional): The location of the API Registry resources. Defaults to `"global"`.
- **`header_provider`** (Callable, optional): A function that takes the call context and returns a dictionary of additional HTTP headers to be sent with requests to the MCP server. This is often used for dynamic authentication or project-specific headers.

The `get_toolset()` function has the following configuration options:

- **`mcp_server_name`** (str): The full name of the registered MCP server from which to load tools, for example: `projects/my-project/locations/global/mcpServers/my-server`.

- **`tool_filter`** (Union\[ToolPredicate, List[str]\], optional): Specifies which tools to include in the toolset.

  - If a list of strings, only tools with names in the list are included.
  - If a `ToolPredicate` function, the function is called for each tool, and only tools for which it returns `True` are included.
  - If `None`, all tools from the MCP server are included.

- **`tool_name_prefix`** (str, optional): A prefix to add to the name of each tool in the resulting toolset.

## Additional resources

- [api_registry_agent](https://github.com/google/adk-python/tree/main/contributing/samples/api_registry_agent/) ADK code sample
- [Google Cloud API Registry](https://docs.cloud.google.com/api-registry/docs/overview) documentation

# Apigee API Hub tool for ADK

Supported in ADKPython v0.1.0

**ApiHubToolset** lets you turn any documented API from Apigee API hub into a tool with a few lines of code. This section shows you the step-by-step instructions including setting up authentication for a secure connection to your APIs.

**Prerequisites**

1. [Install ADK](/get-started/installation/)
1. Install the [Google Cloud CLI](https://cloud.google.com/sdk/docs/install?db=bigtable-docs#installation_instructions).
1. [Apigee API hub](https://cloud.google.com/apigee/docs/apihub/what-is-api-hub) instance with documented (i.e. OpenAPI spec) APIs
1. Set up your project structure and create required files

```console
project_root_folder
 |
 `-- my_agent
     |-- .env
     |-- __init__.py
     |-- agent.py
     `__ tool.py
```

## Create an API Hub Toolset

Note: This tutorial includes an agent creation. If you already have an agent, you only need to follow a subset of these steps.

1. Get your access token, so that APIHubToolset can fetch spec from API Hub API. In your terminal run the following command

   ```shell
   gcloud auth print-access-token
   # Prints your access token like 'ya29....'
   ```

1. Ensure that the account used has the required permissions. You can use the pre-defined role `roles/apihub.viewer` or assign the following permissions:

   1. **apihub.specs.get (required)**
   1. apihub.apis.get (optional)
   1. apihub.apis.list (optional)
   1. apihub.versions.get (optional)
   1. apihub.versions.list (optional)
   1. apihub.specs.list (optional)

1. Create a tool with `APIHubToolset`. Add the below to `tools.py`

   If your API requires authentication, you must configure authentication for the tool. The following code sample demonstrates how to configure an API key. ADK supports token based auth (API Key, Bearer token), service account, and OpenID Connect. We will soon add support for various OAuth2 flows.

   ```py
   from google.adk.tools.openapi_tool.auth.auth_helpers import token_to_scheme_credential
   from google.adk.tools.apihub_tool.apihub_toolset import APIHubToolset

   # Provide authentication for your APIs. Not required if your APIs don't required authentication.
   auth_scheme, auth_credential = token_to_scheme_credential(
       "apikey", "query", "apikey", apikey_credential_str
   )

   sample_toolset = APIHubToolset(
       name="apihub-sample-tool",
       description="Sample Tool",
       access_token="...",  # Copy your access token generated in step 1
       apihub_resource_name="...", # API Hub resource name
       auth_scheme=auth_scheme,
       auth_credential=auth_credential,
   )
   ```

   For production deployment we recommend using a service account instead of an access token. In the code snippet above, use `service_account_json=service_account_cred_json_str` and provide your security account credentials instead of the token.

   For apihub_resource_name, if you know the specific ID of the OpenAPI Spec being used for your API, use `` `projects/my-project-id/locations/us-west1/apis/my-api-id/versions/version-id/specs/spec-id` ``. If you would like the Toolset to automatically pull the first available spec from the API, use `` `projects/my-project-id/locations/us-west1/apis/my-api-id` ``

1. Create your agent file Agent.py and add the created tools to your agent definition:

   ```py
   from google.adk.agents.llm_agent import LlmAgent
   from .tools import sample_toolset

   root_agent = LlmAgent(
       model='gemini-flash-latest',
       name='enterprise_assistant',
       instruction='Help user, leverage the tools you have access to',
       tools=sample_toolset.get_tools(),
   )
   ```

1. Configure your `__init__.py` to expose your agent

   ```py
   from . import agent
   ```

1. Start the Google ADK Web UI and try your agent:

   ```shell
   # make sure to run `adk web` from your project_root_folder
   adk web
   ```

Then go to <http://localhost:8000> to try your agent from the Web UI.

# Google Cloud Application Integration tool for ADK

Supported in ADKPython v0.1.0Java v0.3.0

With **ApplicationIntegrationToolset**, you can seamlessly give your agents secure and governed access to enterprise applications using Integration Connectors' 100+ pre-built connectors for systems like Salesforce, ServiceNow, JIRA, SAP, and more.

It supports both on-premise and SaaS applications. In addition, you can turn your existing Application Integration process automations into agentic workflows by providing application integration workflows as tools to your ADK agents.

Federated search within Application Integration lets you use ADK agents to query multiple enterprise applications and data sources simultaneously.

[See how ADK Federated Search in Application Integration works in this video walkthrough](https://www.youtube.com/watch?v=JdlWOQe5RgU)

## Prerequisites

### 1. Install ADK

Install Agent Development Kit following the steps in the [installation guide](/get-started/installation/).

### 2. Install CLI

Install the [Google Cloud CLI](https://cloud.google.com/sdk/docs/install#installation_instructions). To use the tool with default credentials, run the following commands:

```shell
gcloud config set project <project-id>
gcloud auth application-default login
gcloud auth application-default set-quota-project <project-id>
```

Replace `<project-id>` with the unique ID of your Google Cloud project.

### 3. Provision Application Integration workflow and publish Connection Tool

Use an existing [Application Integration](https://cloud.google.com/application-integration/docs/overview) workflow or [Integrations Connector](https://cloud.google.com/integration-connectors/docs/overview) connection you want to use with your agent. You can also create a new [Application Integration workflow](https://cloud.google.com/application-integration/docs/setup-application-integration) or a [connection](https://cloud.google.com/integration-connectors/docs/connectors/neo4j/configure#configure-the-connector).

Import and publish the [Connection Tool](https://console.cloud.google.com/integrations/templates/connection-tool/locations/global) from the template library.

**Note**: To use a connector from Integration Connectors, you need to provision the Application Integration in the same region as your connection.

### 4. Create project structure

Set up your project structure and create the required files:

```console
project_root_folder
├── .env
└── my_agent
    ├── __init__.py
    ├── agent.py
    └── tools.py
```

When running the agent, make sure to run `adk web` from the `project_root_folder`.

Set up your project structure and create the required files:

```console
  project_root_folder
  └── my_agent
      ├── agent.java
      └── pom.xml
```

When running the agent, make sure to run the commands from the `project_root_folder`.

### 5. Set roles and permissions

To get the permissions that you need to set up **ApplicationIntegrationToolset**, you must have the following IAM roles on the project (common to both Integration Connectors and Application Integration Workflows):

```text
- roles/integrations.integrationEditor
- roles/connectors.invoker
- roles/secretmanager.secretAccessor
```

**Note:** When using Agent Runtime for deployment, don't use `roles/integrations.integrationInvoker`, as it can result in 403 errors. Use `roles/integrations.integrationEditor` instead.

## Use Integration Connectors

Connect your agent to enterprise applications using [Integration Connectors](https://cloud.google.com/integration-connectors/docs/overview).

### Before you begin

**Note:** The *ExecuteConnection* integration is typically created automatically when you provision Application Integration in a given region. If the *ExecuteConnection* doesn't exist in the [list of integrations](https://console.cloud.google.com/integrations/list), you must follow these steps to create it:

1. To use a connector from Integration Connectors, click **QUICK SETUP** and [provision](https://console.cloud.google.com/integrations) Application Integration in the same region as your connection.

1. Go to the [Connection Tool](https://console.cloud.google.com/integrations/templates/connection-tool/locations/us-central1) template in the template library and click **USE TEMPLATE**.

1. Enter the Integration Name as *ExecuteConnection* (it is mandatory to use this exact integration name only). Then, select the region to match your connection region and click **CREATE**.

1. Click **PUBLISH** to publish the integration in the *Application Integration* editor.

### Create an Application Integration Toolset

To create an Application Integration Toolset for Integration Connectors, follow these steps:

1. Create a tool with `ApplicationIntegrationToolset` in the `tools.py` file:

   ```py
   from google.adk.tools.application_integration_tool.application_integration_toolset import ApplicationIntegrationToolset

   connector_tool = ApplicationIntegrationToolset(
       project="test-project", # TODO: replace with GCP project of the connection
       location="us-central1", #TODO: replace with location of the connection
       connection="test-connection", #TODO: replace with connection name
       entity_operations={"Entity_One": ["LIST","CREATE"], "Entity_Two": []},#empty list for actions means all operations on the entity are supported.
       actions=["action1"], #TODO: replace with actions
       service_account_json='{...}', # optional. Stringified json for service account key
       tool_name_prefix="tool_prefix2",
       tool_instructions="..."
   )
   ```

   **Note:**

   - You can provide a service account to be used instead of default credentials by generating a [Service Account Key](https://cloud.google.com/iam/docs/keys-create-delete#creating), and providing the right [Application Integration and Integration Connector IAM roles](#prerequisites) to the service account.
   - To find the list of supported entities and actions for a connection, use the Connectors APIs: [listActions](https://cloud.google.com/integration-connectors/docs/reference/rest/v1/projects.locations.connections.connectionSchemaMetadata/listActions) or [listEntityTypes](https://cloud.google.com/integration-connectors/docs/reference/rest/v1/projects.locations.connections.connectionSchemaMetadata/listEntityTypes).

   `ApplicationIntegrationToolset` supports `auth_scheme` and `auth_credential` for **dynamic OAuth2 authentication** for Integration Connectors. To use it, create a tool similar to this in the `tools.py` file:

   ```py
   from google.adk.tools.application_integration_tool.application_integration_toolset import ApplicationIntegrationToolset
   from google.adk.tools.openapi_tool.auth.auth_helpers import dict_to_auth_scheme
   from google.adk.auth import AuthCredential
   from google.adk.auth import AuthCredentialTypes
   from google.adk.auth import OAuth2Auth

   oauth2_data_google_cloud = {
     "type": "oauth2",
     "flows": {
         "authorizationCode": {
             "authorizationUrl": "https://accounts.google.com/o/oauth2/auth",
             "tokenUrl": "https://oauth2.googleapis.com/token",
             "scopes": {
                 "https://www.googleapis.com/auth/cloud-platform": (
                     "View and manage your data across Google Cloud Platform"
                     " services"
                 ),
                 "https://www.googleapis.com/auth/calendar.readonly": "View your calendars"
             },
         }
     },
   }

   oauth_scheme = dict_to_auth_scheme(oauth2_data_google_cloud)

   auth_credential = AuthCredential(
     auth_type=AuthCredentialTypes.OAUTH2,
     oauth2=OAuth2Auth(
         client_id="...", #TODO: replace with client_id
         client_secret="...", #TODO: replace with client_secret
     ),
   )

   connector_tool = ApplicationIntegrationToolset(
       project="test-project", # TODO: replace with GCP project of the connection
       location="us-central1", #TODO: replace with location of the connection
       connection="test-connection", #TODO: replace with connection name
       entity_operations={"Entity_One": ["LIST","CREATE"], "Entity_Two": []},#empty list for actions means all operations on the entity are supported.
       actions=["GET_calendars/%7BcalendarId%7D/events"], #TODO: replace with actions. this one is for list events
       service_account_json='{...}', # optional. Stringified json for service account key
       tool_name_prefix="tool_prefix2",
       tool_instructions="...",
       auth_scheme=oauth_scheme,
       auth_credential=auth_credential
   )
   ```

1. Update the `agent.py` file and add tool to your agent:

   ```py
   from google.adk.agents.llm_agent import LlmAgent
   from .tools import connector_tool

   root_agent = LlmAgent(
       model='gemini-flash-latest',
       name='connector_agent',
       instruction="Help user, leverage the tools you have access to",
       tools=[connector_tool],
   )
   ```

1. Configure `__init__.py` to expose your agent:

   ```py
   from . import agent
   ```

1. Start the Google ADK Web UI and use your agent:

   ```shell
   # make sure to run `adk web` from your project_root_folder
   adk web
   ```

After completing the above steps, go to <http://localhost:8000>, and choose `my\_agent` agent (which is the same as the agent folder name).

## Use Application Integration Workflows

Use an existing [Application Integration](https://cloud.google.com/application-integration/docs/overview) workflow as a tool for your agent or create a new one.

### 1. Create a tool

To create a tool with `ApplicationIntegrationToolset` in the `tools.py` file, use the following code:

```py
    integration_tool = ApplicationIntegrationToolset(
        project="test-project", # TODO: replace with GCP project of the connection
        location="us-central1", #TODO: replace with location of the connection
        integration="test-integration", #TODO: replace with integration name
        triggers=["api_trigger/test_trigger"],#TODO: replace with trigger id(s). Empty list would mean all api triggers in the integration to be considered.
        service_account_json='{...}', #optional. Stringified json for service account key
        tool_name_prefix="tool_prefix1",
        tool_instructions="..."
    )
```

**Note:** You can provide a service account to be used instead of using default credentials. To do this, generate a [Service Account Key](https://cloud.google.com/iam/docs/keys-create-delete#creating) and provide the correct [Application Integration and Integration Connector IAM roles](#prerequisites) to the service account. For more details about the IAM roles, refer to the [Prerequisites](#prerequisites) section.

To create a tool with `ApplicationIntegrationToolset` in the `tools.java` file, use the following code:

```java
    import com.google.adk.tools.applicationintegrationtoolset.ApplicationIntegrationToolset;
    import com.google.common.collect.ImmutableList;
    import com.google.common.collect.ImmutableMap;

    public class Tools {
        private static ApplicationIntegrationToolset integrationTool;
        private static ApplicationIntegrationToolset connectionsTool;

        static {
            integrationTool = new ApplicationIntegrationToolset(
                    "test-project",
                    "us-central1",
                    "test-integration",
                    ImmutableList.of("api_trigger/test-api"),
                    null,
                    null,
                    null,
                    "{...}",
                    "tool_prefix1",
                    "...");

            connectionsTool = new ApplicationIntegrationToolset(
                    "test-project",
                    "us-central1",
                    null,
                    null,
                    "test-connection",
                    ImmutableMap.of("Issue", ImmutableList.of("GET")),
                    ImmutableList.of("ExecuteCustomQuery"),
                    "{...}",
                    "tool_prefix",
                    "...");
        }
    }
```

**Note:** You can provide a service account to be used instead of using default credentials. To do this, generate a [Service Account Key](https://cloud.google.com/iam/docs/keys-create-delete#creating) and provide the correct [Application Integration and Integration Connector IAM roles](#prerequisites) to the service account. For more details about the IAM roles, refer to the [Prerequisites](#prerequisites) section.

### 2. Add the tool to your agent

To update the `agent.py` file and add the tool to your agent, use the following code:

```py
    from google.adk.agents.llm_agent import LlmAgent
    from .tools import integration_tool, connector_tool

    root_agent = LlmAgent(
        model='gemini-flash-latest',
        name='integration_agent',
        instruction="Help user, leverage the tools you have access to",
        tools=[integration_tool],
    )
```

To update the `agent.java` file and add the tool to your agent, use the following code:

````java
import com.google.adk.agent.LlmAgent;
import com.google.adk.tools.BaseTool;
import com.google.common.collect.ImmutableList;

```text
    public class MyAgent {
        public static void main(String[] args) {
            // Assuming Tools class is defined as in the previous step
            ImmutableList<BaseTool> tools = ImmutableList.<BaseTool>builder()
                    .add(Tools.integrationTool)
                    .add(Tools.connectionsTool)
                    .build();

            // Finally, create your agent with the tools generated automatically.
            LlmAgent rootAgent = LlmAgent.builder()
                    .name("science-teacher")
                    .description("Science teacher agent")
                    .model("gemini-flash-latest")
                    .instruction(
                            "Help user, leverage the tools you have access to."
                    )
                    .tools(tools)
                    .build();

            // You can now use rootAgent to interact with the LLM
            // For example, you can start a conversation with the agent.
        }
    }
````

````

**Note:** To find the list of supported entities and actions for a
connection, use these Connector APIs: `listActions`, `listEntityTypes`.

### 3. Expose your agent

To configure `__init__.py` to expose your agent, use the following code:

```py
    from . import agent
````

### 4. Use your agent

To start the Google ADK Web UI and use your agent, use the following commands:

```shell
    # make sure to run `adk web` from your project_root_folder
    adk web
```

After completing the above steps, go to <http://localhost:8000>, and choose the `my_agent` agent (which is the same as the agent folder name).

To start the Google ADK Web UI and use your agent, use the following commands:

```bash
    mvn install

    mvn exec:java \
        -Dexec.mainClass="com.google.adk.web.AdkWebServer" \
        -Dexec.args="--adk.agents.source-dir=src/main/java" \
        -Dexec.classpathScope="compile"
```

After completing the above steps, go to <http://localhost:8000>, and choose the `my_agent` agent (which is the same as the agent folder name).

# Arize AX observability for ADK

[Arize AX](https://arize.com/docs/ax) is a production-grade observability platform for monitoring, debugging, and improving LLM applications and AI Agents at scale. It provides comprehensive tracing, evaluation, and monitoring capabilities for your Google ADK applications. To get started, sign up for a [free account](https://app.arize.com/auth/join).

For an open-source, self-hosted alternative, check out [Phoenix](https://arize.com/docs/phoenix).

## Overview

Arize AX can automatically collect traces from Google ADK using [OpenInference instrumentation](https://github.com/Arize-ai/openinference/tree/main/python/instrumentation/openinference-instrumentation-google-adk), allowing you to:

- **Trace agent interactions** - Automatically capture every agent run, tool call, model request, and response with context and metadata
- **Evaluate performance** - Assess agent behavior using custom or pre-built evaluators and run experiments to test agent configurations
- **Monitor in production** - Set up real-time dashboards and alerts to track performance
- **Debug issues** - Analyze detailed traces to quickly identify bottlenecks, failed tool calls, and any unexpected agent behavior

## Installation

Install the required packages:

```bash
pip install openinference-instrumentation-google-adk google-adk arize-otel
```

## Setup

### 1. Configure Environment Variables

Set your Google API key:

```bash
export GOOGLE_API_KEY=[your_key_here]
```

### 2. Connect your application to Arize AX

```python
from arize.otel import register

# Register with Arize AX
tracer_provider = register(
    space_id="your-space-id",      # Found in app space settings page
    api_key="your-api-key",        # Found in app space settings page
    project_name="your-project-name"  # Name this whatever you prefer
)

# Import and configure the automatic instrumentor from OpenInference
from openinference.instrumentation.google_adk import GoogleADKInstrumentor

# Finish automatic instrumentation
GoogleADKInstrumentor().instrument(tracer_provider=tracer_provider)
```

## Observe

Now that you have tracing setup, all Google ADK SDK requests will be streamed to Arize AX for observability and evaluation.

```python
import nest_asyncio
nest_asyncio.apply()

from google.adk.agents import Agent
from google.adk.runners import InMemoryRunner
from google.genai import types

# Define a tool function
def get_weather(city: str) -> dict:
    """Retrieves the current weather report for a specified city.

    Args:
        city (str): The name of the city for which to retrieve the weather report.

    Returns:
        dict: status and result or error msg.
    """
    if city.lower() == "new york":
        return {
            "status": "success",
            "report": (
                "The weather in New York is sunny with a temperature of 25 degrees"
                " Celsius (77 degrees Fahrenheit)."
            ),
        }
    else:
        return {
            "status": "error",
            "error_message": f"Weather information for '{city}' is not available.",
        }

# Create an agent with tools
agent = Agent(
    name="weather_agent",
    model="gemini-flash-latest",
    description="Agent to answer questions using weather tools.",
    instruction="You must use the available tools to find an answer.",
    tools=[get_weather]
)

app_name = "weather_app"
user_id = "test_user"
session_id = "test_session"
runner = InMemoryRunner(agent=agent, app_name=app_name)
session_service = runner.session_service

await session_service.create_session(
    app_name=app_name,
    user_id=user_id,
    session_id=session_id
)

# Run the agent (all interactions will be traced)
async for event in runner.run_async(
    user_id=user_id,
    session_id=session_id,
    new_message=types.Content(role="user", parts=[
        types.Part(text="What is the weather in New York?")]
    )
):
    if event.is_final_response():
        print(event.content.parts[0].text.strip())
```

## View Results in Arize AX

## Support and Resources

- [Arize AX Documentation](https://arize.com/docs/ax/integrations/python-agent-frameworks/google-adk)
- [Arize Community Slack](https://arize-ai.slack.com/join/shared_invite/zt-11t1vbu4x-xkBIHmOREQnYnYDH1GDfCg#/shared-invite/email)
- [OpenInference Package](https://github.com/Arize-ai/openinference/tree/main/python/instrumentation/openinference-instrumentation-google-adk)

# Asana MCP tool for ADK

Supported in ADKPythonTypeScript

The [Asana MCP Server](https://developers.asana.com/docs/using-asanas-mcp-server) connects your ADK agent to the [Asana](https://asana.com/) work management platform. This integration gives your agent the ability to manage projects, tasks, goals, and team collaboration using natural language.

## Use cases

- **Track Project Status**: Get real-time updates on project progress, view status reports, and retrieve information about milestones and deadlines.
- **Manage Tasks**: Create, update, and organize tasks using natural language. Let your agent handle task assignments, status changes, and priority updates.
- **Monitor Goals**: Access and update Asana Goals to track team objectives and key results across your organization.

## Prerequisites

- An [Asana](https://asana.com/) account with access to a workspace

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

root_agent = Agent(
    model="gemini-flash-latest",
    name="asana_agent",
    instruction="Help users manage projects, tasks, and goals in Asana",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "mcp-remote",
                        "https://mcp.asana.com/sse",
                    ]
                ),
                timeout=30,
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "asana_agent",
    instruction: "Help users manage projects, tasks, and goals in Asana",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: [
                    "-y",
                    "mcp-remote",
                    "https://mcp.asana.com/sse",
                ],
            },
        }),
    ],
});

export { rootAgent };
```

Note

When you run this agent for the first time, a browser window opens automatically to request access via OAuth. Alternatively, you can use the authorization URL printed in the console. You must approve this request to allow the agent to access your Asana data.

## Available tools

Asana's MCP server includes 30+ tools organized by category. Tools are automatically discovered when your agent connects. Use the [ADK Web UI](/runtime/web-interface/) to view available tools in the trace graph after running your agent.

| Category          | Description                                 |
| ----------------- | ------------------------------------------- |
| Project tracking  | Get project status updates and reports      |
| Task management   | Create, update, and organize tasks          |
| User information  | Access user details and assignments         |
| Goals             | Track and update Asana Goals                |
| Team organization | Manage team structures and membership       |
| Object search     | Quick typeahead search across Asana objects |

## Additional resources

- [Asana MCP Server Documentation](https://developers.asana.com/docs/using-asanas-mcp-server)
- [Asana MCP Integration Guide](https://developers.asana.com/docs/integrating-with-asanas-mcp-server)

# Atlassian MCP tool for ADK

Supported in ADKPythonTypeScript

The [Atlassian MCP Server](https://github.com/atlassian/atlassian-mcp-server) connects your ADK agent to the [Atlassian](https://www.atlassian.com/) ecosystem, bridging the gap between project tracking in Jira and knowledge management in Confluence. This integration gives your agent the ability to manage issues, search and update documentation pages, and streamline collaboration workflows using natural language.

## Use cases

- **Unified Knowledge Search**: Search across both Jira issues and Confluence pages simultaneously to find project specs, decisions, or historical context.
- **Automate Issue Management**: Create, edit, and transition Jira issues, or add comments to existing tickets.
- **Documentation Assistant**: Retrieve page content, generate drafts, or add inline comments to Confluence documents directly from your agent.

## Prerequisites

- Sign up for an [Atlassian account](https://id.atlassian.com/signup)
- An Atlassian Cloud site with Jira and/or Confluence

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters


root_agent = Agent(
    model="gemini-flash-latest",
    name="atlassian_agent",
    instruction="Help users work with data in Atlassian products",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "mcp-remote",
                        "https://mcp.atlassian.com/v1/mcp",
                    ]
                ),
                timeout=30,
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "atlassian_agent",
    instruction: "Help users work with data in Atlassian products",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: [
                    "-y",
                    "mcp-remote",
                    "https://mcp.atlassian.com/v1/mcp",
                ],
            },
        }),
    ],
});

export { rootAgent };
```

Note

When you run this agent for the first time, a browser window opens automatically to request access via OAuth. Alternatively, you can use the authorization URL printed in the console. You must approve this request to allow the agent to access your Atlassian data.

## Available tools

| Tool                               | Description                                                |
| ---------------------------------- | ---------------------------------------------------------- |
| `atlassianUserInfo`                | Get information about the user                             |
| `getAccessibleAtlassianResources`  | Get information about accessible Atlassian resources       |
| `getJiraIssue`                     | Get information about a Jira issue                         |
| `editJiraIssue`                    | Edit a Jira issue                                          |
| `createJiraIssue`                  | Create a new Jira issue                                    |
| `getTransitionsForJiraIssue`       | Get transitions for a Jira issue                           |
| `transitionJiraIssue`              | Transition a Jira issue                                    |
| `lookupJiraAccountId`              | Lookup a Jira account ID                                   |
| `searchJiraIssuesUsingJql`         | Search Jira issues using JQL                               |
| `addCommentToJiraIssue`            | Add a comment to a Jira issue                              |
| `getJiraIssueRemoteIssueLinks`     | Get remote issue links for a Jira issue                    |
| `getVisibleJiraProjects`           | Get visible Jira projects                                  |
| `getJiraProjectIssueTypesMetadata` | Get issue types metadata for a Jira project                |
| `getJiraIssueTypeMetaWithFields`   | Get issue type metadata with fields for a Jira issue       |
| `getConfluenceSpaces`              | Get information about Confluence spaces                    |
| `getConfluencePage`                | Get information about a Confluence page                    |
| `getPagesInConfluenceSpace`        | Get information about pages in a Confluence space          |
| `getConfluencePageFooterComments`  | Get information about footer comments in a Confluence page |
| `getConfluencePageInlineComments`  | Get information about inline comments in a Confluence page |
| `getConfluencePageDescendants`     | Get information about descendants of a Confluence page     |
| `createConfluencePage`             | Create a new Confluence page                               |
| `updateConfluencePage`             | Update an existing Confluence page                         |
| `createConfluenceFooterComment`    | Create a footer comment in a Confluence page               |
| `createConfluenceInlineComment`    | Create an inline comment in a Confluence page              |
| `searchConfluenceUsingCql`         | Search Confluence using CQL                                |
| `search`                           | Search for information                                     |
| `fetch`                            | Fetch information                                          |

## Additional resources

- [Atlassian MCP Server Repository](https://github.com/atlassian/atlassian-mcp-server)
- [Atlassian MCP Server Documentation](https://support.atlassian.com/atlassian-rovo-mcp-server/docs/getting-started-with-the-atlassian-remote-mcp-server/)

# BigQuery Agent Analytics plugin for ADK

Supported in ADKPython v1.21.0

Version Requirement

Use ADK Python version 1.26.0 or higher to make full use of the features described in this document, including auto-schema-upgrade, tool provenance tracking, and HITL event tracing.

The BigQuery Agent Analytics Plugin significantly enhances Agent Development Kit (ADK) by providing a robust solution for in-depth agent behavior analysis. Using the ADK Plugin architecture and the **BigQuery Storage Write API**, it captures and logs critical operational events directly into a Google BigQuery table, empowering you with advanced capabilities for debugging, real-time monitoring, and comprehensive offline performance evaluation.

Version 1.26.0 adds **Auto Schema Upgrade** (safely add new columns to existing tables), **Tool Provenance** tracking (LOCAL, MCP, SUB_AGENT, A2A, TRANSFER_AGENT, TRANSFER_A2A), and **HITL Event Tracing** for human-in-the-loop interactions. Version 1.27.0 adds **Automatic View Creation** (generate flat, query-friendly event views).

BigQuery Storage Write API

This feature uses **BigQuery Storage Write API**, which is a paid service. For information on costs, see the [BigQuery documentation](https://cloud.google.com/bigquery/pricing?e=48754805&hl=en#data-ingestion-pricing).

## Use cases

- **Agent workflow debugging and analysis:** Capture a wide range of *plugin lifecycle events* (LLM calls, tool usage) and *agent-yielded events* (user input, model responses), into a well-defined schema.
- **High-volume analysis and debugging:** Logging operations are performed asynchronously using the Storage Write API to allow high throughput and low latency.
- **Multimodal Analysis**: Log and analyze text, images, and other modalities. Large files are offloaded to GCS, making them accessible to BigQuery ML via Object Tables.
- **Distributed Tracing**: Built-in support for OpenTelemetry-style tracing (`trace_id`, `span_id`) to visualize agent execution flows.
- **Tool Provenance**: Track the origin of each tool call (local function, MCP server, sub-agent, A2A remote agent, or transfer agent).
- **Human-in-the-Loop (HITL) Tracing**: Dedicated event types for credential requests, confirmation prompts, and user input requests.
- **Queryable Event Views**: Automatically create flat, per-event-type BigQuery views (e.g., `v_llm_request`, `v_tool_completed`) to simplify downstream analytics by unnesting JSON payload data.

### Captured events summary

The following table lists all event types the plugin logs. For detailed payload examples, see [Event types and payloads](#event-types). The **View** column shows the BigQuery view optionally created when [`create_views`](#configuration-options) is enabled (the default).

| Event Type                            | Captured When                        | Key Payload Fields                                    | View                          |
| ------------------------------------- | ------------------------------------ | ----------------------------------------------------- | ----------------------------- |
| `USER_MESSAGE_RECEIVED`               | A user message enters the invocation | text summary / content parts                          | `v_user_message_received`     |
| `INVOCATION_STARTING`                 | An invocation begins                 | *(common columns only)*                               | `v_invocation_starting`       |
| `INVOCATION_COMPLETED`                | An invocation ends                   | *(common columns only)*                               | `v_invocation_completed`      |
| `AGENT_STARTING`                      | Agent execution begins               | instruction summary                                   | `v_agent_starting`            |
| `AGENT_COMPLETED`                     | Agent execution ends                 | latency                                               | `v_agent_completed`           |
| `LLM_REQUEST`                         | A model request is sent              | model, prompt, config, tools                          | `v_llm_request`               |
| `LLM_RESPONSE`                        | A model response is received         | response, usage tokens, cache metadata, latency, TTFT | `v_llm_response`              |
| `LLM_ERROR`                           | A model call fails                   | error message, latency                                | `v_llm_error`                 |
| `TOOL_STARTING`                       | A tool begins execution              | tool name, args, origin                               | `v_tool_starting`             |
| `TOOL_COMPLETED`                      | A tool succeeds                      | tool name, result, origin, latency                    | `v_tool_completed`            |
| `TOOL_ERROR`                          | A tool fails                         | tool name, args, origin, error, latency               | `v_tool_error`                |
| `STATE_DELTA`                         | Session state changes                | state delta                                           | `v_state_delta`               |
| `HITL_CREDENTIAL_REQUEST`             | Credential request is emitted        | synthetic tool name, args                             | `v_hitl_credential_request`   |
| `HITL_CONFIRMATION_REQUEST`           | Confirmation request is emitted      | synthetic tool name, args                             | `v_hitl_confirmation_request` |
| `HITL_INPUT_REQUEST`                  | User input request is emitted        | synthetic tool name, args                             | `v_hitl_input_request`        |
| `HITL_CREDENTIAL_REQUEST_COMPLETED`   | User provides credential response    | synthetic tool name, result                           | *(base table only)*           |
| `HITL_CONFIRMATION_REQUEST_COMPLETED` | User provides confirmation response  | synthetic tool name, result                           | *(base table only)*           |
| `HITL_INPUT_REQUEST_COMPLETED`        | User provides input response         | synthetic tool name, result                           | *(base table only)*           |
| `A2A_INTERACTION`                     | Remote A2A call completes            | response, task ID, context ID, request/response       | `v_a2a_interaction`           |

## Quickstart

Add the plugin to your agent's `App` object. For prerequisites, see [Prerequisites](#prerequisites).

agent.py

```python
import os
from google.adk.agents import Agent
from google.adk.apps import App
from google.adk.models.google_llm import Gemini
from google.adk.plugins.bigquery_agent_analytics_plugin import BigQueryAgentAnalyticsPlugin

os.environ['GOOGLE_CLOUD_PROJECT'] = 'your-gcp-project-id'
os.environ['GOOGLE_CLOUD_LOCATION'] = 'us-central1'
os.environ['GOOGLE_GENAI_USE_VERTEXAI'] = 'True'

plugin = BigQueryAgentAnalyticsPlugin(
    project_id="your-gcp-project-id",
    dataset_id="your-big-query-dataset-id",
)

root_agent = Agent(
    model=Gemini(model="gemini-flash-latest"),
    name='my_agent',
    instruction="You are a helpful assistant.",
)

app = App(
    name="my_agent",
    root_agent=root_agent,
    plugins=[plugin],
)
```

### Run and test agent

Test the plugin by running the agent and making a few requests through the chat interface, such as "tell me what you can do" or "List datasets in my cloud project ". These actions create events which are recorded in your Google Cloud project BigQuery instance. Once these events have been processed, you can view the data for them in the [BigQuery Console](https://console.cloud.google.com/bigquery), using this query:

```sql
SELECT timestamp, event_type, content
FROM `your-gcp-project-id.your-big-query-dataset-id.agent_events`
ORDER BY timestamp DESC
LIMIT 20;
```

Full example with GCS offloading, OpenTelemetry, and BigQuery tools

my_bq_agent/agent.py

```python
# my_bq_agent/agent.py
import os
import google.auth
from google.adk.apps import App
from google.adk.plugins.bigquery_agent_analytics_plugin import BigQueryAgentAnalyticsPlugin, BigQueryLoggerConfig
from google.adk.agents import Agent
from google.adk.models.google_llm import Gemini
from google.adk.tools.bigquery import BigQueryToolset, BigQueryCredentialsConfig


# --- OpenTelemetry TracerProvider Setup (Optional) ---
# ADK includes OpenTelemetry as a core dependency.
# Configuring a TracerProvider enables full distributed tracing
# (populates trace_id, span_id with standard OTel identifiers).
# If no TracerProvider is configured, the plugin falls back to internal
# UUIDs for span correlation while still preserving the parent-child hierarchy.
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
trace.set_tracer_provider(TracerProvider())

# --- Configuration ---
PROJECT_ID = os.environ.get("GOOGLE_CLOUD_PROJECT", "your-gcp-project-id")
DATASET_ID = os.environ.get("BIG_QUERY_DATASET_ID", "your-big-query-dataset-id")
# GOOGLE_CLOUD_LOCATION must be a valid Agent Platform region (e.g., "us-central1").
# BQ_LOCATION is the BigQuery dataset location, which can be a multi-region
# like "US" or "EU", or a single region like "us-central1".
VERTEX_LOCATION = os.environ.get("GOOGLE_CLOUD_LOCATION", "us-central1")
BQ_LOCATION = os.environ.get("BQ_LOCATION", "US")
GCS_BUCKET = os.environ.get("GCS_BUCKET_NAME", "your-gcs-bucket-name") # Optional

if PROJECT_ID == "your-gcp-project-id":
    raise ValueError("Please set GOOGLE_CLOUD_PROJECT or update the code.")

# --- CRITICAL: Set environment variables BEFORE Gemini instantiation ---
os.environ['GOOGLE_CLOUD_PROJECT'] = PROJECT_ID
os.environ['GOOGLE_CLOUD_LOCATION'] = VERTEX_LOCATION
os.environ['GOOGLE_GENAI_USE_VERTEXAI'] = 'True'

# --- Initialize the Plugin with Config ---
bq_config = BigQueryLoggerConfig(
    enabled=True,
    gcs_bucket_name=GCS_BUCKET, # Enable GCS offloading for multimodal content
    log_multi_modal_content=True,
    max_content_length=500 * 1024, # 500 KB limit for inline text
    batch_size=1, # Default is 1 for low latency, increase for high throughput
    shutdown_timeout=10.0
)

bq_logging_plugin = BigQueryAgentAnalyticsPlugin(
    project_id=PROJECT_ID,
    dataset_id=DATASET_ID,
    table_id="agent_events", # default table name is agent_events
    config=bq_config,
    location=BQ_LOCATION
)

# --- Initialize Tools and Model ---
credentials, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
bigquery_toolset = BigQueryToolset(
    credentials_config=BigQueryCredentialsConfig(credentials=credentials)
)

llm = Gemini(model="gemini-flash-latest")

root_agent = Agent(
    model=llm,
    name='my_bq_agent',
    instruction="You are a helpful assistant with access to BigQuery tools.",
    tools=[bigquery_toolset]
)

# --- Create the App ---
app = App(
    name="my_bq_agent",
    root_agent=root_agent,
    plugins=[bq_logging_plugin],
)
```

Deploying to Agent Runtime?

See [Deploy to Agent Runtime](#deploy-agent-runtime).

## Prerequisites

- **Google Cloud Project** with the **BigQuery API** enabled.
- **BigQuery Dataset:** Create a dataset to store logging tables before using the plugin. The plugin automatically creates the necessary events table within the dataset if the table does not exist.
- **Google Cloud Storage Bucket (Optional):** If you plan to log multimodal content (images, audio, etc.), creating a GCS bucket is recommended for offloading large files.
- **Authentication:**
  - **Local:** Run `gcloud auth application-default login`.
  - **Cloud:** Ensure your service account has the required permissions.

Note: Gemini model selector `gemini-flash-latest`

Most code examples in ADK documentation use `gemini-flash-latest` to select the [latest available](https://ai.google.dev/gemini-api/docs/models#latest) Gemini Flash version. However, if you access Gemini from a regional endpoint, such as `us-central1`, this selection string may not work. In that case, use a specific model version string from the [Gemini models](https://ai.google.dev/gemini-api/docs/models) page or Google Cloud [Gemini models](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models) list.

### IAM permissions

For the agent to work properly, the principal (e.g., service account, user account) under which the agent is running needs these Google Cloud roles:

- `roles/bigquery.jobUser` at Project Level to run BigQuery queries.
- `roles/bigquery.dataEditor` at Table Level to write log/event data.
- **If using GCS offloading:** `roles/storage.objectCreator` and `roles/storage.objectViewer` on the target bucket.

## Configuration options

### Constructor parameters

The `BigQueryAgentAnalyticsPlugin` constructor accepts these parameters. It also accepts `**kwargs`, which are forwarded directly to `BigQueryLoggerConfig` (see below).

| Parameter     | Type                                            | Default      | Use when                                                                                                                                                                |
| ------------- | ----------------------------------------------- | ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `project_id`  | `str`                                           | *(required)* | Select the Google Cloud project                                                                                                                                         |
| `dataset_id`  | `str`                                           | *(required)* | Select the BigQuery dataset                                                                                                                                             |
| `table_id`    | `Optional[str]`                                 | `None`       | Use a custom table name (overrides config `table_id`)                                                                                                                   |
| `config`      | `Optional[BigQueryLoggerConfig]`                | `None`       | Pass a config object for detailed tuning                                                                                                                                |
| `location`    | `str`                                           | `"US"`       | Match the BigQuery dataset location (e.g., `"US"`, `"EU"`, `"us-central1"`)                                                                                             |
| `credentials` | `Optional[google.auth.credentials.Credentials]` | `None`       | Use explicit service-account, impersonated, or cross-project credentials instead of [ADC](https://cloud.google.com/docs/authentication/application-default-credentials) |

```python
plugin = BigQueryAgentAnalyticsPlugin(
    project_id="my-project",
    dataset_id="my_dataset",
    batch_size=10,           # forwarded to BigQueryLoggerConfig
    shutdown_timeout=5.0,    # forwarded to BigQueryLoggerConfig
)
```

### BigQueryLoggerConfig options

All options below are optional and have sensible defaults. Pass them to `BigQueryLoggerConfig` or as `**kwargs` to the plugin constructor.

| Option                    | Type                  | Default                              | Use when                                                                                                                                                 |
| ------------------------- | --------------------- | ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `enabled`                 | `bool`                | `True`                               | Temporarily disable logging                                                                                                                              |
| `table_id`                | `str`                 | `"agent_events"`                     | Use a custom table name (constructor value takes precedence)                                                                                             |
| `clustering_fields`       | `List[str]`           | `["event_type", "agent", "user_id"]` | Customize table clustering on creation                                                                                                                   |
| `gcs_bucket_name`         | `Optional[str]`       | `None`                               | Offload large text and multimodal content to GCS                                                                                                         |
| `connection_id`           | `Optional[str]`       | `None`                               | Use BigQuery ObjectRef / object tables (e.g., `us.my-connection`)                                                                                        |
| `max_content_length`      | `int`                 | `500 * 1024`                         | Control inline payload size before offloading/truncating                                                                                                 |
| `batch_size`              | `int`                 | `1`                                  | Tune write throughput vs. latency                                                                                                                        |
| `batch_flush_interval`    | `float`               | `1.0`                                | Flush partial batches periodically (seconds)                                                                                                             |
| `shutdown_timeout`        | `float`               | `10.0`                               | Wait for final flush on shutdown (seconds)                                                                                                               |
| `event_allowlist`         | `Optional[List[str]]` | `None`                               | Log only selected [event types](#event-types)                                                                                                            |
| `event_denylist`          | `Optional[List[str]]` | `None`                               | Skip sensitive or noisy [event types](#event-types)                                                                                                      |
| `content_formatter`       | `Optional[Callable]`  | `None`                               | Apply custom masking/formatting per event (receives `(content, event_type)`)                                                                             |
| `log_multi_modal_content` | `bool`                | `True`                               | Capture `content_parts` details including GCS references                                                                                                 |
| `queue_max_size`          | `int`                 | `10000`                              | Bound the in-memory event queue                                                                                                                          |
| `retry_config`            | `RetryConfig`         | `RetryConfig()`                      | Tune retry behavior (`max_retries=3`, `initial_delay=1.0`, `multiplier=2.0`, `max_delay=10.0`)                                                           |
| `log_session_metadata`    | `bool`                | `True`                               | Add session info to `attributes` (`session_id`, `app_name`, `user_id`, `state`). Keys prefixed `temp:` or `secret:` are [redacted](#built-in-redaction). |
| `custom_tags`             | `Dict[str, Any]`      | `{}`                                 | Add static tags (e.g., `{"env": "prod"}`) to every event's `attributes`                                                                                  |
| `auto_schema_upgrade`     | `bool`                | `True`                               | Automatically add new columns to existing tables (additive only)                                                                                         |
| `create_views`            | `bool`                | `True`                               | Create per-event-type BigQuery views (1.27.0+)                                                                                                           |
| `view_prefix`             | `str`                 | `"v"`                                | Avoid view-name collisions when multiple plugins share a dataset (e.g., `"v_staging"`)                                                                   |

The following code sample shows how to define a configuration for the BigQuery Agent Analytics plugin:

```python
import json
import re

from google.adk.plugins.bigquery_agent_analytics_plugin import BigQueryLoggerConfig

def redact_dollar_amounts(event_content: Any, event_type: str) -> str:
    """
    Custom formatter to redact dollar amounts (e.g., $600, $12.50)
    and ensure JSON output if the input is a dict.

    Args:
        event_content: The raw content of the event.
        event_type: The event type string (e.g., "LLM_REQUEST", "LLM_RESPONSE").
    """
    text_content = ""
    if isinstance(event_content, dict):
        text_content = json.dumps(event_content)
    else:
        text_content = str(event_content)

    # Regex to find dollar amounts: $ followed by digits, optionally with commas or decimals.
    # Examples: $600, $1,200.50, $0.99
    redacted_content = re.sub(r'\$\d+(?:,\d{3})*(?:\.\d+)?', 'xxx', text_content)

    return redacted_content

config = BigQueryLoggerConfig(
    enabled=True,
    event_allowlist=["LLM_REQUEST", "LLM_RESPONSE"], # Only log these events
    # event_denylist=["TOOL_STARTING"], # Skip these events
    shutdown_timeout=10.0, # Wait up to 10s for logs to flush on exit
    max_content_length=500, # Truncate content to 500 chars
    content_formatter=redact_dollar_amounts, # Redact the dollar amounts in the logging content
    queue_max_size=10000, # Max events to hold in memory
    auto_schema_upgrade=True, # Automatically add new columns to existing tables
    create_views=True, # Automatically create per-event-type views
    # retry_config=RetryConfig(max_retries=3), # Optional: Configure retries
)

plugin = BigQueryAgentAnalyticsPlugin(
    project_id="my-project",
    dataset_id="my_dataset",
    config=config,
)
```

## Schema and production setup

### Schema Reference

The events table (`agent_events`) uses a flexible schema. The following table provides a comprehensive reference with example values.

| Field Name         | Type        | Mode       | Description                                                                                                                                                                                                                                                                                                                                                      | Example Value                                                                                                                                                                                                |
| ------------------ | ----------- | ---------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **timestamp**      | `TIMESTAMP` | `REQUIRED` | UTC timestamp of event creation. Acts as the primary ordering key and the daily partitioning key. Precision is microsecond.                                                                                                                                                                                                                                      | `2026-02-03 20:52:17 UTC`                                                                                                                                                                                    |
| **event_type**     | `STRING`    | `NULLABLE` | The canonical event category. Standard values include `LLM_REQUEST`, `LLM_RESPONSE`, `LLM_ERROR`, `TOOL_STARTING`, `TOOL_COMPLETED`, `TOOL_ERROR`, `AGENT_STARTING`, `AGENT_COMPLETED`, `STATE_DELTA`, `INVOCATION_STARTING`, `INVOCATION_COMPLETED`, `USER_MESSAGE_RECEIVED`, and HITL events (see [HITL events](#hitl-events)). Used for high-level filtering. | `LLM_REQUEST`                                                                                                                                                                                                |
| **agent**          | `STRING`    | `NULLABLE` | The name of the agent responsible for this event. Defined during agent initialization or via the `root_agent_name` context.                                                                                                                                                                                                                                      | `my_bq_agent`                                                                                                                                                                                                |
| **session_id**     | `STRING`    | `NULLABLE` | A persistent identifier for the entire conversation thread. Stays constant across multiple turns and sub-agent calls.                                                                                                                                                                                                                                            | `04275a01-1649-4a30-b6a7-5b443c69a7bc`                                                                                                                                                                       |
| **invocation_id**  | `STRING`    | `NULLABLE` | The unique identifier for a single execution turn or request cycle. Corresponds to `trace_id` in many contexts.                                                                                                                                                                                                                                                  | `e-b55b2000-68c6-4e8b-b3b3-ffb454a92e40`                                                                                                                                                                     |
| **user_id**        | `STRING`    | `NULLABLE` | The identifier of the user (human or system) initiating the session. Extracted from the `User` object or metadata.                                                                                                                                                                                                                                               | `test_user`                                                                                                                                                                                                  |
| **trace_id**       | `STRING`    | `NULLABLE` | The **OpenTelemetry** Trace ID (32-char hex). Links all operations within a single distributed request lifecycle.                                                                                                                                                                                                                                                | `e-b55b2000-68c6-4e8b-b3b3-ffb454a92e40`                                                                                                                                                                     |
| **span_id**        | `STRING`    | `NULLABLE` | The **OpenTelemetry** Span ID (16-char hex). Uniquely identifies this specific atomic operation.                                                                                                                                                                                                                                                                 | `69867a836cd94798be2759d8e0d70215`                                                                                                                                                                           |
| **parent_span_id** | `STRING`    | `NULLABLE` | The Span ID of the immediate caller. Used to reconstruct the parent-child execution tree (DAG).                                                                                                                                                                                                                                                                  | `ef5843fe40764b4b8afec44e78044205`                                                                                                                                                                           |
| **content**        | `JSON`      | `NULLABLE` | The primary event payload. Structure is polymorphic based on `event_type`.                                                                                                                                                                                                                                                                                       | `{"system_prompt": "You are...", "prompt": [{"role": "user", "content": "hello"}], "response": "Hi", "usage": {"total": 15}}`                                                                                |
| **attributes**     | `JSON`      | `NULLABLE` | Metadata/Enrichment (usage stats, model info, tool provenance, custom tags).                                                                                                                                                                                                                                                                                     | `{"model": "gemini-flash-latest", "usage_metadata": {"total_token_count": 15}, "session_metadata": {"session_id": "...", "app_name": "...", "user_id": "...", "state": {}}, "custom_tags": {"env": "prod"}}` |
| **latency_ms**     | `JSON`      | `NULLABLE` | Performance metrics. Standard keys are `total_ms` (wall-clock duration) and `time_to_first_token_ms` (streaming latency).                                                                                                                                                                                                                                        | `{"total_ms": 1250, "time_to_first_token_ms": 450}`                                                                                                                                                          |
| **status**         | `STRING`    | `NULLABLE` | High-level outcome. Values: `OK` (success) or `ERROR` (failure).                                                                                                                                                                                                                                                                                                 | `OK`                                                                                                                                                                                                         |
| **error_message**  | `STRING`    | `NULLABLE` | Human-readable exception message or stack trace fragment. Populated only when `status` is `ERROR`.                                                                                                                                                                                                                                                               | `Error 404: Dataset not found`                                                                                                                                                                               |
| **is_truncated**   | `BOOLEAN`   | `NULLABLE` | `true` if `content` or `attributes` exceeded the BigQuery cell size limit (default 10MB) and were partially dropped.                                                                                                                                                                                                                                             | `false`                                                                                                                                                                                                      |
| **content_parts**  | `RECORD`    | `REPEATED` | Array of multi-modal segments (Text, Image, Blob). Used when content cannot be serialized as simple JSON (e.g., large binaries or GCS refs).                                                                                                                                                                                                                     | `[{"mime_type": "text/plain", "text": "hello"}]`                                                                                                                                                             |

The plugin automatically creates the table if it does not exist. For production, you can optionally create the table manually using the DDL below.

Manual DDL for production setup

```sql
CREATE TABLE `your-gcp-project-id.adk_agent_logs.agent_events`
(
  timestamp TIMESTAMP NOT NULL OPTIONS(description="The UTC time at which the event was logged."),
  event_type STRING OPTIONS(description="Indicates the type of event being logged (e.g., 'LLM_REQUEST', 'TOOL_COMPLETED')."),
  agent STRING OPTIONS(description="The name of the ADK agent or author associated with the event."),
  session_id STRING OPTIONS(description="A unique identifier to group events within a single conversation or user session."),
  invocation_id STRING OPTIONS(description="A unique identifier for each individual agent execution or turn within a session."),
  user_id STRING OPTIONS(description="The identifier of the user associated with the current session."),
  trace_id STRING OPTIONS(description="OpenTelemetry trace ID for distributed tracing."),
  span_id STRING OPTIONS(description="OpenTelemetry span ID for this specific operation."),
  parent_span_id STRING OPTIONS(description="OpenTelemetry parent span ID to reconstruct hierarchy."),
  content JSON OPTIONS(description="The event-specific data (payload) stored as JSON."),
  content_parts ARRAY<STRUCT<
    mime_type STRING,
    uri STRING,
    object_ref STRUCT<
      uri STRING,
      version STRING,
      authorizer STRING,
      details JSON
    >,
    text STRING,
    part_index INT64,
    part_attributes STRING,
    storage_mode STRING
  >> OPTIONS(description="Detailed content parts for multi-modal data."),
  attributes JSON OPTIONS(description="Arbitrary key-value pairs for additional metadata (e.g., 'root_agent_name', 'model_version', 'usage_metadata', 'session_metadata', 'custom_tags')."),
  latency_ms JSON OPTIONS(description="Latency measurements (e.g., total_ms)."),
  status STRING OPTIONS(description="The outcome of the event, typically 'OK' or 'ERROR'."),
  error_message STRING OPTIONS(description="Populated if an error occurs."),
  is_truncated BOOLEAN OPTIONS(description="Flag indicates if content was truncated.")
)
PARTITION BY DATE(timestamp)
CLUSTER BY event_type, agent, user_id;
```

### Automatically Created Views (1.27.0+)

When `create_views=True` (the default in 1.27.0 and higher), the plugin automatically generates views for each event type that unnest common JSON structures into flat, typed columns. This significantly simplifies SQL, eliminating the need to write complex `JSON_VALUE` or `JSON_QUERY` functions explicitly.

View names follow the convention `{view_prefix}_{event_type_lowercase}` (for example, with the default prefix `"v"`, `LLM_REQUEST` becomes `v_llm_request`). Set `view_prefix` in `BigQueryLoggerConfig` to a distinct value when multiple plugin instances write to different tables in the same dataset, preventing view-name collisions:

```python
# Two plugins in the same dataset with distinct view prefixes
plugin_prod = BigQueryAgentAnalyticsPlugin(
    project_id=PROJECT_ID, dataset_id=DATASET_ID,
    table_id="agent_events_prod",
    config=BigQueryLoggerConfig(view_prefix="v_prod"),
)
# Creates views: v_prod_llm_request, v_prod_tool_completed, ...

plugin_staging = BigQueryAgentAnalyticsPlugin(
    project_id=PROJECT_ID, dataset_id=DATASET_ID,
    table_id="agent_events_staging",
    config=BigQueryLoggerConfig(view_prefix="v_staging"),
)
# Creates views: v_staging_llm_request, v_staging_tool_completed, ...
```

You can also call the public async method `await plugin.create_analytics_views()` to manually refresh views, for example after a schema upgrade.

Every view includes these **common columns**: `timestamp`, `event_type`, `agent`, `session_id`, `invocation_id`, `user_id`, `trace_id`, `span_id`, `parent_span_id`, `status`, `error_message`, `is_truncated`.

The following table lists all 16 auto-created views and their event-specific columns:

| View Name                         | Event-Specific Columns                                                                                                                                                                                                                                                                                  |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`v_user_message_received`**     | *(common columns only)*                                                                                                                                                                                                                                                                                 |
| **`v_llm_request`**               | `model` (STRING), `request_content` (JSON), `llm_config` (JSON), `tools` (JSON)                                                                                                                                                                                                                         |
| **`v_llm_response`**              | `response` (JSON), `usage_prompt_tokens` (INT64), `usage_completion_tokens` (INT64), `usage_total_tokens` (INT64), `usage_cached_tokens` (INT64), `total_ms` (INT64), `ttft_ms` (INT64), `model_version` (STRING), `usage_metadata` (JSON), `cache_metadata` (JSON), `context_cache_hit_rate` (FLOAT64) |
| **`v_llm_error`**                 | `total_ms` (INT64)                                                                                                                                                                                                                                                                                      |
| **`v_tool_starting`**             | `tool_name` (STRING), `tool_args` (JSON), `tool_origin` (STRING)                                                                                                                                                                                                                                        |
| **`v_tool_completed`**            | `tool_name` (STRING), `tool_result` (JSON), `tool_origin` (STRING), `total_ms` (INT64)                                                                                                                                                                                                                  |
| **`v_tool_error`**                | `tool_name` (STRING), `tool_args` (JSON), `tool_origin` (STRING), `total_ms` (INT64)                                                                                                                                                                                                                    |
| **`v_agent_starting`**            | `agent_instruction` (STRING)                                                                                                                                                                                                                                                                            |
| **`v_agent_completed`**           | `total_ms` (INT64)                                                                                                                                                                                                                                                                                      |
| **`v_invocation_starting`**       | *(common columns only)*                                                                                                                                                                                                                                                                                 |
| **`v_invocation_completed`**      | *(common columns only)*                                                                                                                                                                                                                                                                                 |
| **`v_state_delta`**               | `state_delta` (JSON)                                                                                                                                                                                                                                                                                    |
| **`v_hitl_credential_request`**   | `tool_name` (STRING), `tool_args` (JSON)                                                                                                                                                                                                                                                                |
| **`v_hitl_confirmation_request`** | `tool_name` (STRING), `tool_args` (JSON)                                                                                                                                                                                                                                                                |
| **`v_hitl_input_request`**        | `tool_name` (STRING), `tool_args` (JSON)                                                                                                                                                                                                                                                                |
| **`v_a2a_interaction`**           | `response_content` (JSON), `a2a_task_id` (STRING), `a2a_context_id` (STRING), `a2a_request` (JSON), `a2a_response` (JSON)                                                                                                                                                                               |

## Event types and payloads

The `content` column now contains a **JSON** object specific to the `event_type`. The `content_parts` column provides a structured view of the content, especially useful for images or offloaded data.

Content Truncation

- Variable content fields are truncated to `max_content_length` (configured in `BigQueryLoggerConfig`, default 500KB).
- If `gcs_bucket_name` is configured, large content is offloaded to GCS instead of being truncated, and a reference is stored in `content_parts.object_ref`.

### LLM interactions (plugin lifecycle)

These events track the raw requests sent to and responses received from the LLM.

**1. LLM_REQUEST**

Captures the prompt sent to the model, including conversation history and system instructions.

```json
{
  "event_type": "LLM_REQUEST",
  "content": {
    "system_prompt": "You are a helpful assistant...",
    "prompt": [
      {
        "role": "user",
        "content": "hello how are you today"
      }
    ]
  },
  "attributes": {
    "root_agent_name": "my_bq_agent",
    "model": "gemini-flash-latest",
    "tools": ["list_dataset_ids", "execute_sql"],
    "llm_config": {
      "temperature": 0.5,
      "top_p": 0.9
    }
  }
}
```

**2. LLM_RESPONSE**

Captures the model's output and token usage statistics.

```json
{
  "event_type": "LLM_RESPONSE",
  "content": {
    "response": "text: 'Hello! I'm doing well...'",
    "usage": {
      "completion": 19,
      "prompt": 10129,
      "total": 10148
    }
  },
  "attributes": {
    "root_agent_name": "my_bq_agent",
    "model_version": "gemini-flash-latest",
    "usage_metadata": {
      "prompt_token_count": 10129,
      "candidates_token_count": 19,
      "total_token_count": 10148
    }
  },
  "latency_ms": {
    "time_to_first_token_ms": 2579,
    "total_ms": 2579
  }
}
```

**3. LLM_ERROR**

Logged when an LLM call fails with an exception. The error message is captured and the span is closed.

```json
{
  "event_type": "LLM_ERROR",
  "content": null,
  "attributes": {
    "root_agent_name": "my_bq_agent"
  },
  "error_message": "Error 429: Resource exhausted",
  "latency_ms": {
    "total_ms": 350
  }
}
```

### Tool usage (plugin lifecycle)

These events track the execution of tools by the agent. Each tool event includes a `tool_origin` field that classifies the tool's provenance:

| Tool Origin      | Description                                                                                    |
| ---------------- | ---------------------------------------------------------------------------------------------- |
| `LOCAL`          | `FunctionTool` instances (local Python functions)                                              |
| `MCP`            | Model Context Protocol tools (`McpTool` instances)                                             |
| `SUB_AGENT`      | `AgentTool` instances (sub-agents)                                                             |
| `A2A`            | Remote Agent2Agent instances (`RemoteA2aAgent`)                                                |
| `TRANSFER_AGENT` | `TransferToAgentTool` instances (generic agent transfer)                                       |
| `TRANSFER_A2A`   | `TransferToAgentTool` instances that transfer to a `RemoteA2aAgent` (classified at call-level) |
| `UNKNOWN`        | Unclassified tools                                                                             |

**4. TOOL_STARTING**

Logged when an agent begins executing a tool.

```json
{
  "event_type": "TOOL_STARTING",
  "content": {
    "tool": "list_dataset_ids",
    "args": {
      "project_id": "bigquery-public-data"
    },
    "tool_origin": "LOCAL"
  }
}
```

**5. TOOL_COMPLETED**

Logged when a tool execution finishes.

```json
{
  "event_type": "TOOL_COMPLETED",
  "content": {
    "tool": "list_dataset_ids",
    "result": [
      "austin_311",
      "austin_bikeshare"
    ],
    "tool_origin": "LOCAL"
  },
  "latency_ms": {
    "total_ms": 467
  }
}
```

**6. TOOL_ERROR**

Logged when a tool execution fails with an exception. Captures the tool name, arguments, tool origin, and error message.

```json
{
  "event_type": "TOOL_ERROR",
  "content": {
    "tool": "list_dataset_ids",
    "args": {
      "project_id": "nonexistent-project"
    },
    "tool_origin": "LOCAL"
  },
  "error_message": "Error 404: Dataset not found",
  "latency_ms": {
    "total_ms": 150
  }
}
```

### State Management

These events track changes to the agent's state, typically triggered by tools.

**7. STATE_DELTA**

Tracks changes to the agent's internal state (e.g., custom application state updated by tools).

Built-in redaction

State keys prefixed with `temp:` or `secret:` are automatically redacted to `[REDACTED]` in the logged `state_delta`. See [Built-in redaction](#built-in-redaction) for details.

```json
{
  "event_type": "STATE_DELTA",
  "attributes": {
    "state_delta": {
      "customer_tier": "enterprise",
      "last_query_dataset": "bigquery-public-data.samples"
    }
  }
}
```

### Agent lifecycle & Generic Events

| Event Type              | Content (JSON) Structure                     |
| ----------------------- | -------------------------------------------- |
| `INVOCATION_STARTING`   | `{}`                                         |
| `INVOCATION_COMPLETED`  | `{}`                                         |
| `AGENT_STARTING`        | `"You are a helpful agent..."`               |
| `AGENT_COMPLETED`       | `{}`                                         |
| `USER_MESSAGE_RECEIVED` | `{"text_summary": "Help me book a flight."}` |

### Human-in-the-Loop (HITL) Events

The plugin automatically detects calls to ADK's synthetic HITL tools and emits dedicated event types for them. These events are logged **in addition to** the normal `TOOL_STARTING` / `TOOL_COMPLETED` events.

The following HITL tool names are recognized:

- `adk_request_credential`: Request for user credentials (e.g., OAuth tokens)
- `adk_request_confirmation`: Request for user confirmation before proceeding
- `adk_request_input`: Request for free-form user input

| Event Type                            | Trigger                                | Content (JSON) Structure                                |
| ------------------------------------- | -------------------------------------- | ------------------------------------------------------- |
| `HITL_CREDENTIAL_REQUEST`             | Agent calls `adk_request_credential`   | `{"tool": "adk_request_credential", "args": {...}}`     |
| `HITL_CREDENTIAL_REQUEST_COMPLETED`   | User provides credential response      | `{"tool": "adk_request_credential", "result": {...}}`   |
| `HITL_CONFIRMATION_REQUEST`           | Agent calls `adk_request_confirmation` | `{"tool": "adk_request_confirmation", "args": {...}}`   |
| `HITL_CONFIRMATION_REQUEST_COMPLETED` | User provides confirmation response    | `{"tool": "adk_request_confirmation", "result": {...}}` |
| `HITL_INPUT_REQUEST`                  | Agent calls `adk_request_input`        | `{"tool": "adk_request_input", "args": {...}}`          |
| `HITL_INPUT_REQUEST_COMPLETED`        | User provides input response           | `{"tool": "adk_request_input", "result": {...}}`        |

HITL request events are detected from `function_call` parts in `on_event_callback`. HITL completion events are detected from `function_response` parts in both `on_event_callback` and `on_user_message_callback`.

Views for HITL events

Auto-created views exist only for the three **request** event types (`v_hitl_credential_request`, `v_hitl_confirmation_request`, `v_hitl_input_request`). The three `*_COMPLETED` event types are logged to the base table but do not have dedicated views. Query them directly from the `agent_events` table using `WHERE event_type LIKE 'HITL_%_COMPLETED'`.

### A2A Interaction Events

When your agent communicates with a remote agent via the Agent2Agent (A2A) protocol, the plugin logs an `A2A_INTERACTION` event capturing the request and response details.

**A2A_INTERACTION**

Logged when an A2A remote agent call completes.

```json
{
  "event_type": "A2A_INTERACTION",
  "content": {
    "response_content": "The remote agent's response...",
    "a2a_task_id": "task-abc123",
    "a2a_context_id": "ctx-def456",
    "a2a_request": { ... },
    "a2a_response": { ... }
  }
}
```

## Storage behavior: GCS offloading

When `gcs_bucket_name` is configured in `BigQueryLoggerConfig`, the plugin automatically offloads large text and multimodal content (images, audio, etc.) to Google Cloud Storage. The `content` column will contain a summary or placeholder, while `content_parts` stores the `object_ref` pointing to the GCS URI. See also `connection_id` and `max_content_length` in [Configuration options](#configuration-options).

### Offloaded Text Example

```json
{
  "event_type": "LLM_REQUEST",
  "content_parts": [
    {
      "part_index": 1,
      "mime_type": "text/plain",
      "storage_mode": "GCS_REFERENCE",
      "text": "AAAA... [OFFLOADED]",
      "object_ref": {
        "uri": "gs://sample-bucket-name/2025-12-10/e-f9545d6d/ae5235e6_p1.txt",
        "authorizer": "us.bqml_connection",
        "details": {"gcs_metadata": {"content_type": "text/plain"}}
      }
    }
  ]
}
```

### Offloaded Image Example

```json
{
  "event_type": "LLM_REQUEST",
  "content_parts": [
    {
      "part_index": 2,
      "mime_type": "image/png",
      "storage_mode": "GCS_REFERENCE",
      "text": "[MEDIA OFFLOADED]",
      "object_ref": {
        "uri": "gs://sample-bucket-name/2025-12-10/e-f9545d6d/ae5235e6_p2.png",
        "authorizer": "us.bqml_connection",
        "details": {"gcs_metadata": {"content_type": "image/png"}}
      }
    }
  ]
}
```

### Querying Offloaded Content (Get Signed URLs)

```sql
SELECT
  timestamp,
  event_type,
  part.mime_type,
  part.storage_mode,
  part.object_ref.uri AS gcs_uri,
  -- Generate a signed URL to read the content directly (requires connection_id configuration)
  STRING(OBJ.GET_ACCESS_URL(part.object_ref, 'r').access_urls.read_url) AS signed_url
FROM `your-gcp-project-id.your-dataset-id.agent_events`,
UNNEST(content_parts) AS part
WHERE part.storage_mode = 'GCS_REFERENCE'
ORDER BY timestamp DESC
LIMIT 10;
```

## Query recipes

### Debug a run

#### Trace a specific conversation turn using trace_id

```sql
SELECT timestamp, event_type, agent, JSON_VALUE(content, '$.response') as summary
FROM `your-gcp-project-id.your-dataset-id.agent_events`
WHERE trace_id = 'your-trace-id'
ORDER BY timestamp ASC;
```

#### Span Hierarchy & Duration Analysis

```sql
SELECT
  span_id,
  parent_span_id,
  event_type,
  timestamp,
  -- Extract duration from latency_ms for completed operations
  CAST(JSON_VALUE(latency_ms, '$.total_ms') AS INT64) as duration_ms,
  -- Identify the specific tool or operation
  COALESCE(
    JSON_VALUE(content, '$.tool'),
    'LLM_CALL'
  ) as operation
FROM `your-gcp-project-id.your-dataset-id.agent_events`
WHERE trace_id = 'your-trace-id'
  AND event_type IN ('LLM_RESPONSE', 'TOOL_COMPLETED')
ORDER BY timestamp ASC;
```

#### Error Analysis (LLM & Tool Errors)

Using views (recommended):

```sql
-- Tool errors with provenance
SELECT timestamp, agent, tool_name, tool_origin, error_message, total_ms
FROM `your-gcp-project-id.your-dataset-id.v_tool_error`
ORDER BY timestamp DESC
LIMIT 20;

-- LLM errors
SELECT timestamp, agent, error_message, total_ms
FROM `your-gcp-project-id.your-dataset-id.v_llm_error`
ORDER BY timestamp DESC
LIMIT 20;
```

### Monitor cost and performance

#### Token usage analysis

Using the `v_llm_response` view (recommended):

```sql
SELECT
  AVG(usage_total_tokens) as avg_tokens,
  AVG(usage_prompt_tokens) as avg_prompt_tokens,
  AVG(usage_completion_tokens) as avg_completion_tokens
FROM `your-gcp-project-id.your-dataset-id.v_llm_response`;
```

Or using the base table with JSON extraction:

```sql
SELECT
  AVG(CAST(JSON_VALUE(content, '$.usage.total') AS INT64)) as avg_tokens
FROM `your-gcp-project-id.your-dataset-id.agent_events`
WHERE event_type = 'LLM_RESPONSE';
```

#### Latency Analysis (LLM & Tools)

Using views (recommended):

```sql
-- LLM latency
SELECT AVG(total_ms) as avg_llm_ms, AVG(ttft_ms) as avg_ttft_ms
FROM `your-gcp-project-id.your-dataset-id.v_llm_response`;

-- Tool latency by tool name
SELECT tool_name, tool_origin, AVG(total_ms) as avg_tool_ms
FROM `your-gcp-project-id.your-dataset-id.v_tool_completed`
GROUP BY tool_name, tool_origin
ORDER BY avg_tool_ms DESC;
```

Or using the base table:

```sql
SELECT
  event_type,
  AVG(CAST(JSON_VALUE(latency_ms, '$.total_ms') AS INT64)) as avg_latency_ms
FROM `your-gcp-project-id.your-dataset-id.agent_events`
WHERE event_type IN ('LLM_RESPONSE', 'TOOL_COMPLETED')
GROUP BY event_type;
```

### Inspect tools and interactions

#### Tool Provenance Analysis

Using the `v_tool_completed` view (recommended):

```sql
SELECT
  tool_origin,
  tool_name,
  COUNT(*) as call_count,
  AVG(total_ms) as avg_latency_ms
FROM `your-gcp-project-id.your-dataset-id.v_tool_completed`
GROUP BY tool_origin, tool_name
ORDER BY call_count DESC;
```

#### HITL Interaction Analysis

```sql
SELECT
  timestamp,
  event_type,
  session_id,
  JSON_VALUE(content, '$.tool') as hitl_tool,
  content
FROM `your-gcp-project-id.your-dataset-id.agent_events`
WHERE event_type LIKE 'HITL_%'
ORDER BY timestamp DESC
LIMIT 20;
```

### Analyze multimodal content

#### Querying Multimodal Content (using content_parts and ObjectRef)

```sql
SELECT
  timestamp,
  part.mime_type,
  part.object_ref.uri as gcs_uri
FROM `your-gcp-project-id.your-dataset-id.agent_events`,
UNNEST(content_parts) as part
WHERE part.mime_type LIKE 'image/%'
ORDER BY timestamp DESC;
```

#### Analyze Multimodal Content with BigQuery Remote Model (Gemini)

```sql
SELECT
  logs.session_id,
  -- Get a signed URL for the image
  STRING(OBJ.GET_ACCESS_URL(parts.object_ref, "r").access_urls.read_url) as signed_url,
  -- Analyze the image using a remote model (e.g., gemini-pro-vision)
  AI.GENERATE(
    ('Describe this image briefly. What company logo?', parts.object_ref)
  ) AS generated_result
FROM
  `your-gcp-project-id.your-dataset-id.agent_events` logs,
  UNNEST(logs.content_parts) AS parts
WHERE
  parts.mime_type LIKE 'image/%'
ORDER BY logs.timestamp DESC
LIMIT 1;
```

### AI-powered root cause analysis

Automatically analyze failed sessions to determine the root cause of errors using BigQuery ML and Gemini.

```sql
DECLARE failed_session_id STRING;
-- Find a recent failed session
SET failed_session_id = (
    SELECT session_id
    FROM `your-gcp-project-id.your-dataset-id.agent_events`
    WHERE error_message IS NOT NULL
    ORDER BY timestamp DESC
    LIMIT 1
);

-- Reconstruct the full conversation context
WITH SessionContext AS (
    SELECT
        session_id,
        STRING_AGG(CONCAT(event_type, ': ', COALESCE(TO_JSON_STRING(content), '')), '\n' ORDER BY timestamp) as full_history
    FROM `your-gcp-project-id.your-dataset-id.agent_events`
    WHERE session_id = failed_session_id
    GROUP BY session_id
)
-- Ask Gemini to diagnose the issue
SELECT
    session_id,
    AI.GENERATE(
        ('Analyze this conversation log and explain the root cause of the failure. Log: ', full_history),
        endpoint => 'gemini-flash-latest'
    ).result AS root_cause_explanation
FROM SessionContext;
```

### Conversational Analytics

You can also use [BigQuery Conversational Analytics](https://cloud.google.com/bigquery/docs/conversational-analytics) to analyze your agent logs using natural language. Create a conversational analytics agent in the [BigQuery Agents Hub](https://console.cloud.google.com/bigquery/agents_hub) connected to your `agent_events` table, then ask questions like:

- "Show me the error rate over time"
- "What are the most common tool calls?"
- "Identify sessions with high token usage"

## Deploy to Agent Runtime with the plugin

You can deploy an agent with the BigQuery Agent Analytics plugin to [Agent Runtime](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview). This section walks through the steps to deploy using the ADK CLI, and alternatively using the Agent Platform SDK programmatically.

Version Requirement

Use ADK Python version **1.24.0 or higher** to deploy with this plugin to Agent Runtime. Earlier versions had an issue where the plugin's asynchronous log writer could be terminated by the serverless runtime before flushing pending events. Starting from 1.24.0, the plugin performs a synchronous flush at the end of each invocation to ensure all events are written.

### Prerequisites

Before deploying, ensure you have completed the general [Agent Runtime setup](/deploy/agent-runtime/deploy/#setup-cloud-project), including:

1. A Google Cloud project with the **Agent Platform API** and **Cloud Resource Manager API** enabled.
1. A **BigQuery dataset** in the target project (or a cross-project dataset with the correct permissions).
1. A **Cloud Storage staging bucket** for deployment artifacts.
1. The deploying service account has the IAM roles listed in [IAM permissions](#iam-permissions).
1. Your coding environment is [authenticated](/deploy/agent-runtime/deploy/#prerequisites-coding-env) with `gcloud auth login` and `gcloud auth application-default login`.

### Step 1: Define the agent and plugin

Create your agent project folder with an `App` object that includes the plugin. The `App` object is required for Agent Runtime deployments with plugins.

```text
my_bq_agent/
├── __init__.py
├── agent.py
└── requirements.txt
```

my_bq_agent/__init__.py

```python
from . import agent
```

my_bq_agent/agent.py

```python
import os
import google.auth
from google.adk.agents import Agent
from google.adk.apps import App
from google.adk.models.google_llm import Gemini
from google.adk.plugins.bigquery_agent_analytics_plugin import (
    BigQueryAgentAnalyticsPlugin,
    BigQueryLoggerConfig,
)
from google.adk.tools.bigquery import BigQueryToolset, BigQueryCredentialsConfig

# --- Configuration ---
PROJECT_ID = os.environ.get("GOOGLE_CLOUD_PROJECT", "your-gcp-project-id")
DATASET_ID = os.environ.get("BQ_DATASET", "agent_analytics")
# BQ_LOCATION is the BigQuery dataset location (multi-region "US"/"EU" or
# a single region like "us-central1"). This is separate from the Agent Platform
# region used by GOOGLE_CLOUD_LOCATION.
BQ_LOCATION = os.environ.get("BQ_LOCATION", "US")

os.environ["GOOGLE_GENAI_USE_VERTEXAI"] = "True"

# --- Plugin ---
bq_analytics_plugin = BigQueryAgentAnalyticsPlugin(
    project_id=PROJECT_ID,
    dataset_id=DATASET_ID,
    location=BQ_LOCATION,
    config=BigQueryLoggerConfig(
        batch_size=1,
        batch_flush_interval=0.5,
        log_session_metadata=True,
    ),
)

# --- Tools ---
credentials, _ = google.auth.default(
    scopes=["https://www.googleapis.com/auth/cloud-platform"]
)
bigquery_toolset = BigQueryToolset(
    credentials_config=BigQueryCredentialsConfig(credentials=credentials)
)

# --- Agent ---
root_agent = Agent(
    model=Gemini(model="gemini-flash-latest"),
    name="my_bq_agent",
    instruction="You are a helpful assistant with access to BigQuery tools.",
    tools=[bigquery_toolset],
)

# --- App (required for Agent Runtime with plugins) ---
app = App(
    name="my_bq_agent",
    root_agent=root_agent,
    plugins=[bq_analytics_plugin],
)
```

my_bq_agent/requirements.txt

```text
google-adk[bigquery]
google-cloud-bigquery-storage
pyarrow
opentelemetry-api
opentelemetry-sdk
```

### Step 2: Deploy using ADK CLI

Use the `adk deploy agent_engine` command to deploy the agent. The `--adk_app` flag tells the CLI which `App` object to use:

```shell
PROJECT_ID=your-gcp-project-id
LOCATION=us-central1

adk deploy agent_engine \
    --project=$PROJECT_ID \
    --region=$LOCATION \
    --staging_bucket=gs://your-staging-bucket \
    --display_name="My BQ Analytics Agent" \
    --adk_app=agent.app \
    my_bq_agent
```

`--adk_app` flag

The `--adk_app` flag specifies the module path and variable name of the `App` object (in the format `module.variable`). In this example, `agent.app` refers to the `app` variable in `agent.py`. This ensures the deployment correctly picks up the plugin configuration.

Once successfully deployed, you should see output like:

```shell
AgentEngine created. Resource name: projects/123456789/locations/us-central1/reasoningEngines/751619551677906944
```

Note the **Resource name** for the next step.

### Step 3: Test the deployed agent

After deployment, you can query the agent using the Agent Platform SDK:

test_deployed_agent.py

```python
import uuid
import vertexai

PROJECT_ID = "your-gcp-project-id"
LOCATION = "us-central1"
AGENT_ID = "751619551677906944"  # from deployment output

vertexai.init(project=PROJECT_ID, location=LOCATION)
client = vertexai.Client(project=PROJECT_ID, location=LOCATION)

agent = client.agent_engines.get(
    name=f"projects/{PROJECT_ID}/locations/{LOCATION}/reasoningEngines/{AGENT_ID}"
)

user_id = f"test_user_{uuid.uuid4().hex[:8]}"
for chunk in agent.stream_query(
    message="List datasets in my project", user_id=user_id
):
    print(chunk, end="", flush=True)
```

### Step 4: Verify events in BigQuery

After sending a few queries to the deployed agent, verify that events are being logged by querying your BigQuery table:

```sql
SELECT timestamp, event_type, agent, content
FROM `your-gcp-project-id.agent_analytics.agent_events`
ORDER BY timestamp DESC
LIMIT 20;
```

You should see events such as `INVOCATION_STARTING`, `LLM_REQUEST`, `LLM_RESPONSE`, `TOOL_STARTING`, `TOOL_COMPLETED`, and `INVOCATION_COMPLETED`.

### Alternative: Deploy using the Agent Platform SDK

You can also deploy programmatically using the Agent Platform SDK directly. This is useful for CI/CD pipelines or custom deployment workflows:

deploy.py

```python
import vertexai
from my_bq_agent.agent import app

PROJECT_ID = "your-gcp-project-id"
LOCATION = "us-central1"
STAGING_BUCKET = "gs://your-staging-bucket"

vertexai.init(
    project=PROJECT_ID, location=LOCATION, staging_bucket=STAGING_BUCKET
)
client = vertexai.Client(project=PROJECT_ID, location=LOCATION)

remote_app = client.agent_engines.create(
    agent=app,
    config={
        "display_name": "My BQ Analytics Agent",
        "staging_bucket": STAGING_BUCKET,
        "requirements": [
            "google-adk[bigquery]",
            "google-cloud-aiplatform[agent_engines]",
            "google-cloud-bigquery-storage",
            "pyarrow",
            "opentelemetry-api",
            "opentelemetry-sdk",
        ],
    },
)
print(f"Deployed agent: {remote_app.api_resource.name}")
```

### Troubleshooting

If events are not appearing in your BigQuery table after deployment:

1. **Check ADK version**: Ensure `google-adk>=1.24.0` is in your requirements. Earlier versions do not flush pending events before the serverless runtime suspends the process.

1. **Enable debug logging**: Add the following to the top of your `agent.py` to surface any silent errors:

   ```python
   import logging
   logging.basicConfig(level=logging.INFO)
   logging.getLogger("google_adk").setLevel(logging.DEBUG)
   ```

1. **Check IAM permissions**: The Agent Runtime service account needs `roles/bigquery.dataEditor` on the target table and `roles/bigquery.jobUser` on the project. For **cross-project** logging, also ensure the BigQuery API is enabled in the source project and the service account has `bigquery.tables.updateData` on the destination table.

1. **Verify plugin initialization**: In Cloud Logging, filter by `resource.type="reasoning_engine"` and look for plugin startup messages or error logs.

1. **Use immediate flush for debugging**: Set `batch_size=1` and `batch_flush_interval=0.1` in `BigQueryLoggerConfig` to rule out buffering issues.

## Security: Avoid logging sensitive credentials

Do not log OAuth tokens, API keys, or client secrets

The BigQuery Agent Analytics plugin captures detailed event payloads, including tool arguments, LLM prompts, and authentication-related events (such as HITL credential requests). If your agent uses **authenticated tools** (e.g., `AuthenticatedFunctionTool` with OAuth2), the plugin may log sensitive values such as `client_secret`, `access_token`, or API keys into the `content` column of your BigQuery table.

This is a known concern ([google/adk-python#3845](https://github.com/google/adk-python/issues/3845)) and can lead to credential exposure in your analytics data.

The plugin includes **built-in redaction** that automatically protects common secrets. For additional control, you can layer custom redaction on top.

### Built-in redaction

The plugin automatically redacts values for the following well-known key names (case-insensitive) wherever they appear in `content` or `attributes` JSON:

`client_secret`, `access_token`, `refresh_token`, `id_token`, `api_key`, `password`

In addition, any state key prefixed with **`temp:`** or **`secret:`** is automatically replaced with `[REDACTED]` in the logged `state_delta`. This means ADK session state stored under the `secret:` scope (such as OAuth tokens cached by credential services) is never persisted in BigQuery.

No configuration required

Built-in redaction is always active for structured attributes and state logging, and applies recursively to nested dictionaries and JSON-encoded strings within attribute values. Custom `content_formatter` runs **first** on raw content, so use it to add masking for secrets that may appear in free-form payloads.

### Use `content_formatter` to redact additional secrets

Provide a custom `content_formatter` function in `BigQueryLoggerConfig` to strip or mask sensitive fields before they are written:

```python
import json
import re
from typing import Any

SENSITIVE_KEYS = {"client_secret", "access_token", "refresh_token", "api_key", "secret"}

def redact_credentials(event_content: Any, event_type: str) -> str:
    """Redact OAuth secrets and tokens from logged content."""
    if isinstance(event_content, dict):
        text = json.dumps(event_content)
    else:
        text = str(event_content)

    for key in SENSITIVE_KEYS:
        # Redact values in JSON-like strings: "client_secret": "GOCSPX-xxx"
        text = re.sub(
            rf'("{key}"\s*:\s*)"[^"]*"',
            rf'\1"[REDACTED]"',
            text,
            flags=re.IGNORECASE,
        )
    return text

config = BigQueryLoggerConfig(
    content_formatter=redact_credentials,
    # ... other options
)
```

### Use `event_denylist` to skip credential events

If you do not need to log authentication-related events, exclude them entirely:

```python
config = BigQueryLoggerConfig(
    event_denylist=[
        "HITL_CREDENTIAL_REQUEST",
        "HITL_CREDENTIAL_REQUEST_COMPLETED",
    ],
    # ... other options
)
```

### General best practices

- **Never hardcode secrets** in agent source code. Use environment variables or a secret manager (e.g., Google Cloud Secret Manager) for OAuth client secrets and API keys.
- **Restrict BigQuery table access** using IAM to limit who can read logged event data.
- **Audit your logs** periodically to verify no unexpected sensitive data is being captured.

## Operations

### Tracing and observability

The plugin supports **OpenTelemetry** for distributed tracing. OpenTelemetry is included as a core dependency of ADK and is always available.

- **Automatic Span Management**: The plugin automatically generates spans for Agent execution, LLM calls, and Tool executions.
- **OpenTelemetry Integration**: If a `TracerProvider` is configured (as shown in the example above), the plugin will use valid OTel spans, populating `trace_id`, `span_id`, and `parent_span_id` with standard OTel identifiers. This allows you to correlate agent logs with other services in your distributed system.
- **Fallback Mechanism**: If no `TracerProvider` is configured (i.e., only the default no-op provider is active), the plugin automatically falls back to generating internal UUIDs for spans and uses the `invocation_id` as the trace ID. This ensures that the parent-child hierarchy (Agent -> Span -> Tool/LLM) is *always* preserved in the BigQuery logs, even without a configured `TracerProvider`.

### Public methods

The plugin exposes several public methods for lifecycle management:

- **`await plugin.flush()`**: Flush all pending events to BigQuery. Call this before shutdown to avoid data loss.

- **`await plugin.shutdown(timeout=None)`**: Gracefully shut down the plugin, flushing pending events and releasing resources. The optional `timeout` parameter overrides `shutdown_timeout` from the config.

- **`await plugin.create_analytics_views()`**: Manually (re-)create all per-event-type analytics views. Useful after a schema upgrade or when views need to be refreshed.

- **Async context manager**: The plugin supports `async with` for automatic startup and shutdown:

  ```python
  async with BigQueryAgentAnalyticsPlugin(
      project_id=PROJECT_ID, dataset_id=DATASET_ID
  ) as plugin:
      # plugin is initialized and ready to use
      ...
  # plugin.shutdown() is called automatically on exit
  ```

### Multiprocessing and fork safety

The plugin is fork-aware: it sets `GRPC_ENABLE_FORK_SUPPORT=1` before loading the gRPC C-core library and registers an `os.register_at_fork` handler that resets inherited runtime state (gRPC channels, write streams, event loops) in child processes. This means the plugin can survive `os.fork()` without leaking file descriptors or sending data on a parent's connection.

However, **`spawn` is the recommended multiprocessing start method** for production deployments. `fork` copies the parent's address space, including any in-flight gRPC state, and the post-fork reset adds latency to the first write in each child. With `spawn`, each worker initializes the plugin cleanly.

For Gunicorn deployments specifically:

- Prefer `--preload` combined with lazy plugin initialization (the plugin defers setup until the first event is logged), or
- Initialize the plugin inside a `post_fork` hook so each worker gets its own client.

Note

The fork-safety mechanism resets runtime state only. It does **not** replay events that were queued but not yet flushed in the parent process at the time of fork. Call `await plugin.flush()` before forking if you need to guarantee delivery.

## Additional ways to consume logged data

### BigQuery Agent Analytics SDK

The [BigQuery Agent Analytics SDK](https://github.com/GoogleCloudPlatform/BigQuery-Agent-Analytics-SDK/tree/main) provides a programmatic way to consume and analyze the data logged by the plugin. Use the SDK for:

- **Agent evaluation**: Compare agent runs against expected outcomes
- **Golden trajectory matching**: Validate that agent execution paths match approved sequences
- **Trace visualization**: Reconstruct and visualize agent execution flows from logged spans

### Build a dashboard

The BigQuery Agent Analytics SDK includes an [example Jupyter notebook](https://github.com/GoogleCloudPlatform/BigQuery-Agent-Analytics-SDK/blob/main/examples/dashboard_v2.ipynb) that demonstrates how to query and visualize your agent's performance data. Use it as a starting point to build your own custom dashboards tailored to your BigQuery Agent Analytics dataset. You can also publish the notebook as an interactive dashboard using [Colab Data Apps](https://docs.cloud.google.com/bigquery/docs/colab-data-apps).

## Feedback

We welcome your feedback on BigQuery Agent Analytics. If you have questions, suggestions, or encounter any issues, please reach out to the team at [bqaa-feedback@google.com](mailto:bqaa-feedback@google.com).

## Additional resources

- [BigQuery Storage Write API](https://cloud.google.com/bigquery/docs/write-api)
- [Introduction to Object Tables](https://docs.cloud.google.com/bigquery/docs/object-table-introduction)
- [Interactive Demo Notebook](https://github.com/haiyuan-eng-google/demo_BQ_agent_analytics_plugin_notebook)

# BigQuery tool for ADK

Supported in ADKPython v1.1.0

These are a set of tools aimed to provide integration with BigQuery, namely:

- **`list_dataset_ids`**: Fetches BigQuery dataset ids present in a GCP project.
- **`get_dataset_info`**: Fetches metadata about a BigQuery dataset.
- **`list_table_ids`**: Fetches table ids present in a BigQuery dataset.
- **`get_table_info`**: Fetches metadata about a BigQuery table.
- **`get_job_info`**: Fetches metadata information about a BigQuery job (slot usage, configuration, statistics, status, etc.).
- **`execute_sql`**: Runs a SQL query in BigQuery and fetch the result.
- **`forecast`**: Runs a BigQuery AI time series forecast using the `AI.FORECAST` function.
- **`analyze_contribution`**: Performs BigQuery ML contribution analysis to understand what drives changes in a metric.
- **`detect_anomalies`**: Trains an ARIMA_PLUS model and detects anomalies in time series data.
- **`ask_data_insights`**: Answers questions about data in BigQuery tables using natural language.
- **`search_catalog`**: Finds BigQuery datasets and tables using natural language semantic search via Dataplex.

They are packaged in the toolset `BigQueryToolset`.

## Authentication

The `BigQueryToolset` supports several authentication mechanisms through `BigQueryCredentialsConfig`.

### Application Default Credentials

You should use this approach for local development and running on Google Cloud services, such as Cloud Run and GKE.

```python
import google.auth
from google.adk.tools.bigquery import BigQueryToolset, BigQueryCredentialsConfig

# Load Application Default Credentials
credentials, project_id = google.auth.default()

# Configure the toolset
credentials_config = BigQueryCredentialsConfig(credentials=credentials)
bigquery_toolset = BigQueryToolset(credentials_config=credentials_config)
```

### Service Account

You can explicitly provide a service account file or info.

```python
from google.oauth2 import service_account
from google.adk.tools.bigquery import BigQueryToolset, BigQueryCredentialsConfig

# Load Service Account credentials
credentials = service_account.Credentials.from_service_account_file('path/to/key.json')

# Configure the toolset
credentials_config = BigQueryCredentialsConfig(credentials=credentials)
bigquery_toolset = BigQueryToolset(credentials_config=credentials_config)
```

### External Access Token

For applications that need to act on behalf of an end-user, you can pass user credentials directly instantiated from an access token, such as from an OAuth2 flow or an external IDP.

```python
from google.oauth2.credentials import Credentials
from google.adk.tools.bigquery import BigQueryToolset, BigQueryCredentialsConfig

# Assume 'user_token' is obtained via an external OAuth flow
credentials = Credentials(token=user_token)

# Configure the toolset
credentials_config = BigQueryCredentialsConfig(credentials=credentials)
bigquery_toolset = BigQueryToolset(credentials_config=credentials_config)
```

### External Auth Providers

If you are integrating with an external authentication provider where the token is managed by the platform, such as Gemini Enterprise, use `external_access_token_key`.

```python
from google.adk.tools.bigquery import BigQueryToolset, BigQueryCredentialsConfig

# The key used to look up the access token in the session state
credentials_config = BigQueryCredentialsConfig(
    external_access_token_key="YOUR_AUTH_ID"
)
bigquery_toolset = BigQueryToolset(credentials_config=credentials_config)
```

### Interactive Auth (ADK Web)

When using the `adk web` interface for interactive sessions, you can provide OAuth 2.0 client credentials to trigger a login flow. This mechanism works for both local development and when your ADK agent is deployed to environments like Cloud Run.

```python
from google.adk.tools.bigquery import BigQueryToolset, BigQueryCredentialsConfig

# Provide OAuth 2.0 Client ID and Secret
credentials_config = BigQueryCredentialsConfig(
    client_id="YOUR_CLIENT_ID",
    client_secret="YOUR_CLIENT_SECRET"
)
bigquery_toolset = BigQueryToolset(credentials_config=credentials_config)
```

## Sample Code

The following sample code demonstrates how to use the `BigQueryToolset` in an ADK agent using Application Default Credentials (ADC).

```py
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import asyncio

from google.adk.agents import Agent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.tools.bigquery import BigQueryCredentialsConfig
from google.adk.tools.bigquery import BigQueryToolset
from google.adk.tools.bigquery.config import BigQueryToolConfig
from google.adk.tools.bigquery.config import WriteMode
from google.genai import types
import google.auth

# Define constants for this example agent
AGENT_NAME = "bigquery_agent"
APP_NAME = "bigquery_app"
USER_ID = "user1234"
SESSION_ID = "1234"
GEMINI_MODEL = "gemini-2.0-flash"

# Define a tool configuration to block any write operations
tool_config = BigQueryToolConfig(write_mode=WriteMode.BLOCKED)

# Use Application Default Credentials (ADC) for BigQuery authentication
# https://cloud.google.com/docs/authentication/provide-credentials-adc
application_default_credentials, _ = google.auth.default()
credentials_config = BigQueryCredentialsConfig(
    credentials=application_default_credentials
)

# Instantiate a BigQuery toolset
bigquery_toolset = BigQueryToolset(
    credentials_config=credentials_config, bigquery_tool_config=tool_config
)

# Agent Definition
bigquery_agent = Agent(
    model=GEMINI_MODEL,
    name=AGENT_NAME,
    description=(
        "Agent to answer questions about BigQuery data and models and execute"
        " SQL queries."
    ),
    instruction="""\
        You are a data science agent with access to several BigQuery tools.
        Make use of those tools to answer the user's questions.
    """,
    tools=[bigquery_toolset],
)

# Session and Runner
session_service = InMemorySessionService()
session = asyncio.run(
    session_service.create_session(
        app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID
    )
)
runner = Runner(
    agent=bigquery_agent, app_name=APP_NAME, session_service=session_service
)


# Agent Interaction
def call_agent(query):
    """
    Helper function to call the agent with a query.
    """
    content = types.Content(role="user", parts=[types.Part(text=query)])
    events = runner.run(user_id=USER_ID, session_id=SESSION_ID, new_message=content)

    print("USER:", query)
    for event in events:
        if event.is_final_response():
            final_response = event.content.parts[0].text
            print("AGENT:", final_response)


call_agent("Are there any ml datasets in bigquery-public-data project?")
call_agent("Tell me more about ml_datasets.")
call_agent("Which all tables does it have?")
call_agent("Tell me more about the census_adult_income table.")
call_agent("How many rows are there per income bracket?")
call_agent(
    "What is the statistical correlation between education_num, age, and the income_bracket?"
)
```

## Sample Agent

For a complete, ready-to-run sample of a BigQuery-powered agent with detailed authentication examples, see the [BigQuery Sample Agent](https://github.com/google/adk-python/tree/main/contributing/samples/bigquery) on GitHub.

Note: If you want to access a BigQuery data agent as a tool, see [Data Agents tools for ADK](https://adk.dev/integrations/data-agent/index.md).

# Bigtable tool for ADK

Supported in ADKPython v1.12.0

These are a set of tools aimed to provide integration with Bigtable, namely:

- **`list_instances`**: Fetches Bigtable instances in a Google Cloud project.
- **`get_instance_info`**: Fetches metadata instance information in a Google Cloud project.
- **`list_clusters`**: Fetches Bigtable clusters in a Bigtable instance in a Google Cloud project.
- **`get_cluster_info`**: Fetches metadata cluster information in a Bigtable instance in a Google Cloud project.
- **`list_tables`**: Fetches tables in a GCP Bigtable instance.
- **`get_table_info`**: Fetches metadata table information in a GCP Bigtable.
- **`execute_sql`**: Runs a SQL query in Bigtable table and fetch the result.

They are packaged in the toolset `BigtableToolset`.

```py
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import asyncio

from google.adk.agents import Agent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.tools.google_tool import GoogleTool
from google.adk.tools.bigtable import query_tool
from google.adk.tools.bigtable.settings import BigtableToolSettings
from google.adk.tools.bigtable.bigtable_credentials import BigtableCredentialsConfig
from google.adk.tools.bigtable.bigtable_toolset import BigtableToolset
from google.genai import types
from google.adk.tools.tool_context import ToolContext
import google.auth
from google.auth.credentials import Credentials

# Define constants for this example agent
AGENT_NAME = "bigtable_agent"
APP_NAME = "bigtable_app"
USER_ID = "user1234"
SESSION_ID = "1234"
GEMINI_MODEL = "gemini-2.5-flash"

# Define Bigtable tool config with read capability set to allowed.
tool_settings = BigtableToolSettings()

# Define a credentials config - in this example we are using application default
# credentials
# https://cloud.google.com/docs/authentication/provide-credentials-adc
application_default_credentials, _ = google.auth.default()
credentials_config = BigtableCredentialsConfig(
    credentials=application_default_credentials
)

# Instantiate a Bigtable toolset
bigtable_toolset = BigtableToolset(
    credentials_config=credentials_config, bigtable_tool_settings=tool_settings
)

# Optional
# Create a wrapped function tool for the agent on top of the built-in
# `execute_sql` tool in the bigtable toolset.
# For example, this customized tool can perform a dynamically-built query.
def count_rows_tool(
    table_name: str,
    credentials: Credentials,  # GoogleTool handles `credentials`
    settings: BigtableToolSettings,  # GoogleTool handles `settings`
    tool_context: ToolContext,  # GoogleTool handles `tool_context`
):
  """Counts the total number of rows for a specified table.

  Args:
    table_name: The name of the table for which to count rows.

  Returns:
      The total number of rows in the table.
  """

  # Replace the following settings for a specific bigtable database.
  PROJECT_ID = "<PROJECT_ID>"
  INSTANCE_ID = "<INSTANCE_ID>"

  query = f"""
  SELECT count(*) FROM {table_name}
    """

  return query_tool.execute_sql(
      project_id=PROJECT_ID,
      instance_id=INSTANCE_ID,
      query=query,
      credentials=credentials,
      settings=settings,
      tool_context=tool_context,
  )

# Agent Definition
bigtable_agent = Agent(
    model=GEMINI_MODEL,
    name=AGENT_NAME,
    description=(
        "Agent to answer questions about bigtable database and execute SQL queries."
    ),
    instruction="""\
        You are a data assistant agent with access to several bigtable tools.
        Make use of those tools to answer the user's questions.
    """,
    tools=[
        bigtable_toolset,
        # Add customized bigtable tool based on the built-in bigtable toolset.
        GoogleTool(
            func=count_rows_tool,
            credentials_config=credentials_config,
            tool_settings=tool_settings,
        ),
    ],
)


# Session and Runner
session_service = InMemorySessionService()

session = asyncio.run(
    session_service.create_session(
        app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID
    )
)
runner = Runner(
    agent=bigtable_agent, app_name=APP_NAME, session_service=session_service
)


# Agent Interaction
def call_agent(query):
    """
    Helper function to call the agent with a query.
    """
    content = types.Content(role="user", parts=[types.Part(text=query)])
    events = runner.run(user_id=USER_ID, session_id=SESSION_ID, new_message=content)

    print("USER:", query)
    for event in events:
        if event.is_final_response():
            final_response = event.content.parts[0].text
            print("AGENT:", final_response)

# Replace the bigtable instance and table names below with your own.
call_agent("List all tables in projects/<PROJECT_ID>/instances/<INSTANCE_ID>")
call_agent("List the top 5 rows in <TABLE_NAME>")
```

# Cartesia MCP tool for ADK

Supported in ADKPythonTypeScript

The [Cartesia MCP Server](https://github.com/cartesia-ai/cartesia-mcp) connects your ADK agent to the [Cartesia](https://cartesia.ai/) AI audio platform. This integration gives your agent the ability to generate speech, localize voices across languages, and create audio content using natural language.

## Use cases

- **Text-to-Speech Generation**: Convert text into natural-sounding speech using Cartesia's diverse voice library, with control over voice selection and output format.
- **Voice Localization**: Transform existing voices into different languages while preserving the original speaker's characteristics—ideal for multilingual content creation.
- **Audio Infill**: Fill gaps between audio segments to create smooth transitions, useful for podcast editing or audiobook production.
- **Voice Transformation**: Convert audio clips to sound like different voices from Cartesia's library.

## Prerequisites

- Sign up for a [Cartesia account](https://play.cartesia.ai/sign-in)
- Generate an [API key](https://play.cartesia.ai/keys) from the Cartesia playground

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

CARTESIA_API_KEY = "YOUR_CARTESIA_API_KEY"

root_agent = Agent(
    model="gemini-flash-latest",
    name="cartesia_agent",
    instruction="Help users generate speech and work with audio content",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="uvx",
                    args=["cartesia-mcp"],
                    env={
                        "CARTESIA_API_KEY": CARTESIA_API_KEY,
                        # "OUTPUT_DIRECTORY": "/path/to/output",  # Optional
                    }
                ),
                timeout=30,
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const CARTESIA_API_KEY = "YOUR_CARTESIA_API_KEY";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "cartesia_agent",
    instruction: "Help users generate speech and work with audio content",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "uvx",
                args: ["cartesia-mcp"],
                env: {
                    CARTESIA_API_KEY: CARTESIA_API_KEY,
                    // OUTPUT_DIRECTORY: "/path/to/output",  // Optional
                },
            },
        }),
    ],
});

export { rootAgent };
```

## Available tools

| Tool             | Description                                    |
| ---------------- | ---------------------------------------------- |
| `text_to_speech` | Convert text to audio using a specified voice  |
| `list_voices`    | List all available Cartesia voices             |
| `get_voice`      | Get details about a specific voice             |
| `clone_voice`    | Clone a voice from audio samples               |
| `update_voice`   | Update an existing voice                       |
| `delete_voice`   | Delete a voice from your library               |
| `localize_voice` | Transform a voice into a different language    |
| `voice_change`   | Convert an audio file to use a different voice |
| `infill`         | Fill gaps between audio segments               |

## Configuration

The Cartesia MCP server can be configured using environment variables:

| Variable           | Description                              | Required |
| ------------------ | ---------------------------------------- | -------- |
| `CARTESIA_API_KEY` | Your Cartesia API key                    | Yes      |
| `OUTPUT_DIRECTORY` | Directory to store generated audio files | No       |

## Additional resources

- [Cartesia MCP Server Repository](https://github.com/cartesia-ai/cartesia-mcp)
- [Cartesia MCP Documentation](https://docs.cartesia.ai/integrations/mcp)
- [Cartesia Playground](https://play.cartesia.ai/)

# Chroma MCP tool for ADK

Supported in ADKPythonTypeScript

The [Chroma MCP Server](https://github.com/chroma-core/chroma-mcp) connects your ADK agent to [Chroma](https://www.trychroma.com/), an open-source embedding database. This integration gives your agent the ability to create collections, store documents, and retrieve information using semantic search, full text search, and metadata filtering.

## Use cases

- **Semantic Memory for Agents**: Store conversation context, facts, or learned information that agents can retrieve later using natural language queries.
- **Knowledge Base Retrieval**: Build a retrieval-augmented generation (RAG) system by storing documents and retrieving relevant context for responses.
- **Persistent Context Across Sessions**: Maintain long-term memory across conversations, allowing agents to reference past interactions and accumulated knowledge.

## Prerequisites

- **For local storage**: A directory path to persist data
- **For Chroma Cloud**: A [Chroma Cloud](https://www.trychroma.com/) account with tenant ID, database name, and API key

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

# For local storage, use:
DATA_DIR = "/path/to/your/data/directory"

# For Chroma Cloud, use:
# CHROMA_TENANT = "your-tenant-id"
# CHROMA_DATABASE = "your-database-name"
# CHROMA_API_KEY = "your-api-key"

root_agent = Agent(
    model="gemini-flash-latest",
    name="chroma_agent",
    instruction="Help users store and retrieve information using semantic search",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="uvx",
                    args=[
                        "chroma-mcp",
                        # For local storage, use:
                        "--client-type",
                        "persistent",
                        "--data-dir",
                        DATA_DIR,
                        # For Chroma Cloud, use:
                        # "--client-type",
                        # "cloud",
                        # "--tenant",
                        # CHROMA_TENANT,
                        # "--database",
                        # CHROMA_DATABASE,
                        # "--api-key",
                        # CHROMA_API_KEY,
                    ],
                ),
                timeout=30,
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

// For local storage, use:
const DATA_DIR = "/path/to/your/data/directory";

// For Chroma Cloud, use:
// const CHROMA_TENANT = "your-tenant-id";
// const CHROMA_DATABASE = "your-database-name";
// const CHROMA_API_KEY = "your-api-key";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "chroma_agent",
    instruction: "Help users store and retrieve information using semantic search",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "uvx",
                args: [
                    "chroma-mcp",
                    // For local storage, use:
                    "--client-type",
                    "persistent",
                    "--data-dir",
                    DATA_DIR,
                    // For Chroma Cloud, use:
                    // "--client-type",
                    // "cloud",
                    // "--tenant",
                    // CHROMA_TENANT,
                    // "--database",
                    // CHROMA_DATABASE,
                    // "--api-key",
                    // CHROMA_API_KEY,
                ],
            },
        }),
    ],
});

export { rootAgent };
```

## Available tools

### Collection management

| Tool                          | Description                                              |
| ----------------------------- | -------------------------------------------------------- |
| `chroma_list_collections`     | List all collections with pagination support             |
| `chroma_create_collection`    | Create a new collection with optional HNSW configuration |
| `chroma_get_collection_info`  | Get detailed information about a collection              |
| `chroma_get_collection_count` | Get the number of documents in a collection              |
| `chroma_modify_collection`    | Update a collection's name or metadata                   |
| `chroma_delete_collection`    | Delete a collection                                      |
| `chroma_peek_collection`      | View a sample of documents in a collection               |

### Document operations

| Tool                      | Description                                                   |
| ------------------------- | ------------------------------------------------------------- |
| `chroma_add_documents`    | Add documents with optional metadata and custom IDs           |
| `chroma_query_documents`  | Query documents using semantic search with advanced filtering |
| `chroma_get_documents`    | Retrieve documents by IDs or filters with pagination          |
| `chroma_update_documents` | Update existing documents' content, metadata, or embeddings   |
| `chroma_delete_documents` | Delete specific documents from a collection                   |

## Configuration

The Chroma MCP server supports multiple client types to suit different needs:

### Client types

| Client Type  | Description                                                | Key Arguments                                            |
| ------------ | ---------------------------------------------------------- | -------------------------------------------------------- |
| `ephemeral`  | In-memory storage, cleared on restart. Useful for testing. | None (default)                                           |
| `persistent` | File-based storage on your local machine                   | `--data-dir`                                             |
| `http`       | Connect to a self-hosted Chroma server                     | `--host`, `--port`, `--ssl`, `--custom-auth-credentials` |
| `cloud`      | Connect to Chroma Cloud (api.trychroma.com)                | `--tenant`, `--database`, `--api-key`                    |

### Environment variables

You can also configure the client using environment variables. Command-line arguments take precedence over environment variables.

| Variable             | Description                                                |
| -------------------- | ---------------------------------------------------------- |
| `CHROMA_CLIENT_TYPE` | Client type: `ephemeral`, `persistent`, `http`, or `cloud` |
| `CHROMA_DATA_DIR`    | Path for persistent local storage                          |
| `CHROMA_TENANT`      | Tenant ID for Chroma Cloud                                 |
| `CHROMA_DATABASE`    | Database name for Chroma Cloud                             |
| `CHROMA_API_KEY`     | API key for Chroma Cloud                                   |
| `CHROMA_HOST`        | Host for self-hosted HTTP client                           |
| `CHROMA_PORT`        | Port for self-hosted HTTP client                           |
| `CHROMA_SSL`         | Enable SSL for HTTP client (`true` or `false`)             |
| `CHROMA_DOTENV_PATH` | Path to `.env` file (defaults to `.chroma_env`)            |

## Additional resources

- [Chroma MCP Server Repository](https://github.com/chroma-core/chroma-mcp)
- [Chroma Documentation](https://docs.trychroma.com/)
- [Chroma Cloud](https://www.trychroma.com/)

# Cisco AI Defense plugin for ADK

Supported in ADKPython

[Cisco AI Defense](https://www.cisco.com/site/us/en/products/security/ai-defense/index.html) is an enterprise AI security platform that provides runtime guardrails to protect against threats like prompt injection, data leakage, and harmful content. The [ADK plugin](https://github.com/cisco-ai-defense/ai-defense-google-adk) integrates these guardrails directly into the ADK Runner lifecycle: it inspects prompts, model responses, and tool calls, then allows or blocks them based on configurable security policies.

## Use cases

- **Runtime protection for model calls**: Inspect user prompts before model calls and model outputs after generation, then allow or block based on policy (`monitor` or `enforce`).
- **Tool and MCP call inspection**: Inspect tool call requests before execution and tool responses after execution, and block unsafe tool behavior in `enforce` mode with clear metadata.
- **Auditable decision trace and alerts**: Capture decision context (action, severity, classifications, request_id/event_id) and optionally trigger an `on_violation` callback for monitoring and incident response.

## Prerequisites

- [Cisco AI Defense](https://www.cisco.com/site/us/en/products/security/ai-defense/index.html) account and API key
- Python >= 3.10
- [ADK](https://adk.dev) >= 1.0.0

## Installation

```bash
pip install cisco-aidefense-google-adk
```

Set the `AI_DEFENSE_API_KEY` environment variable (and `AI_DEFENSE_MCP_API_KEY` for tool inspection).

## Use with agent

### Quickstart

Add Cisco AI Defense to any ADK agent with a single line:

```python
from aidefense_google_adk import defend

agent = defend(agent, mode="enforce")
```

Or get a plugin for the entire app:

```python
from aidefense_google_adk import defend

plugin = defend(mode="enforce")
app = App(name="my_app", root_agent=agent, plugins=[plugin])
```

### Global plugin

Use `CiscoAIDefensePlugin` to apply inspection globally to all agents in a Runner:

```python
from google.adk.agents import LlmAgent
from google.adk.apps import App
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService

from aidefense_google_adk import CiscoAIDefensePlugin

agent = LlmAgent(
    model="gemini-flash-latest",
    name="assistant",
    instruction="You are a helpful assistant.",
)

app = App(
    name="my_app",
    root_agent=agent,
    plugins=[
        CiscoAIDefensePlugin(mode="enforce"),
    ],
)
runner = Runner(app=app, session_service=InMemorySessionService())
```

### Per-agent callbacks

Use `make_aidefense_callbacks` to wire inspection into a specific agent:

```python
from google.adk.agents import LlmAgent
from aidefense_google_adk import make_aidefense_callbacks

cbs = make_aidefense_callbacks(mode="enforce")

agent = LlmAgent(
    model="gemini-flash-latest",
    name="assistant",
    instruction="You are a helpful assistant.",
)
cbs.apply_to(agent)  # wires all 4 callbacks
```

## Modes

The plugin supports three operating modes:

| Mode      | Behavior                                                          |
| --------- | ----------------------------------------------------------------- |
| `monitor` | Inspect all traffic, log violations, never block (default)        |
| `enforce` | Inspect all traffic, block requests/responses that violate policy |
| `off`     | Skip inspection entirely                                          |

Modes can be set globally or per-channel:

```python
CiscoAIDefensePlugin(
    mode="monitor",      # default for both
    llm_mode="enforce",  # override for LLM only
    mcp_mode="off",      # override for tools only
)
```

## Violation callback

Use the `on_violation` callback to receive notifications for every violation in both `monitor` and `enforce` modes:

```python
def handle_violation(result):
    print(f"Violation: {result.action} / {result.severity}")

CiscoAIDefensePlugin(
    mode="monitor",
    on_violation=handle_violation,
)
```

## Retry and fail-open support

For automatic retry with exponential backoff, fail-open/fail-closed semantics, and structured `Decision` objects, use the `AgentsecPlugin` variant:

```python
from aidefense_google_adk import AgentsecPlugin

app = App(
    name="my_app",
    root_agent=agent,
    plugins=[
        AgentsecPlugin(
            mode="enforce",
            fail_open=True,
            retry_total=3,
            retry_backoff=0.5,
        ),
    ],
)
```

Or at the per-agent level:

```python
from aidefense_google_adk import make_agentsec_callbacks

cbs = make_agentsec_callbacks(mode="enforce", fail_open=True)
cbs.apply_to(agent)
```

## Additional resources

- [GitHub Repository](https://github.com/cisco-ai-defense/ai-defense-google-adk)
- [PyPI Package](https://pypi.org/project/cisco-aidefense-google-adk/)
- [Cisco AI Defense](https://www.cisco.com/site/us/en/products/security/ai-defense/index.html)
- [cisco-aidefense-sdk on PyPI](https://pypi.org/project/cisco-aidefense-sdk/)

# Google Cloud Trace observability for ADK

Supported in ADKPythonTypeScriptGo

With ADK, you can already inspect and observe your agent interaction locally utilizing the powerful web development UI discussed in [here](/evaluate/#debugging-with-the-trace-view). However, for cloud deployment, you will need a centralized dashboard to observe real traffic.

Cloud Trace is a component of Google Cloud Observability. It is a powerful tool for monitoring, debugging, and improving the performance of your applications by focusing specifically on tracing capabilities. For Agent Development Kit (ADK) applications, Cloud Trace enables comprehensive tracing, helping you understand how requests flow through your agent's interactions and identify performance bottlenecks or errors within your AI agents.

## Overview

Cloud Trace is built on [OpenTelemetry](https://opentelemetry.io/), an open-source standard that supports many languages and ingestion methods for generating trace data. This aligns with observability practices for ADK applications, which also leverage OpenTelemetry-compatible instrumentation, allowing you to:

- **Trace agent interactions**: Cloud Trace continuously gathers and analyzes trace data from your project, enabling you to rapidly diagnose latency issues and errors within your ADK applications.
- **Debug issues**: Quickly diagnose latency issues and errors by analyzing detailed traces. This is crucial for understanding issues that manifest as increased communication latency across different services or during specific agent actions like tool calls.
- **In-depth Analysis and Visualization**: Trace Explorer is the primary tool for analyzing traces, offering visual aids like heatmaps for span duration and waterfall views to easily identify bottlenecks and sources of errors within your agent's execution path.

The following example will assume the following agent directory structure:

```text
working_dir/
├── weather_agent/
│   ├── agent.py
│   └── __init__.py
└── deploy_agent_engine.py
└── deploy_fast_api_app.py
└── agent_runner.py
```

```python
# weather_agent/agent.py

import os
from google.adk.agents import Agent

os.environ.setdefault("GOOGLE_CLOUD_PROJECT", "{your-project-id}")
os.environ.setdefault("GOOGLE_CLOUD_LOCATION", "global")
os.environ.setdefault("GOOGLE_GENAI_USE_VERTEXAI", "True")


# Define a tool function
def get_weather(city: str) -> dict:
    """Retrieves the current weather report for a specified city.

    Args:
        city (str): The name of the city for which to retrieve the weather report.

    Returns:
        dict: status and result or error msg.
    """
    if city.lower() == "new york":
        return {
            "status": "success",
            "report": (
                "The weather in New York is sunny with a temperature of 25 degrees"
                " Celsius (77 degrees Fahrenheit)."
            ),
        }
    else:
        return {
            "status": "error",
            "error_message": f"Weather information for '{city}' is not available.",
        }


# Create an agent with tools
root_agent = Agent(
    name="weather_agent",
    model="gemini-flash-latest",
    description="Agent to answer questions using weather tools.",
    instruction="You must use the available tools to find an answer.",
    tools=[get_weather],
)
```

## Cloud Trace Setup

### Using the ADK CLI

You can enable cloud tracing by adding a flag when deploying or running your agent using the ADK CLI.

When deploying your agent using the `adk deploy` command:

```bash
adk deploy agent_engine \
    --project=$GOOGLE_CLOUD_PROJECT \
    --region=$GOOGLE_CLOUD_LOCATION \
    --trace_to_cloud \
    $AGENT_PATH
```

When running your agent built with the ADK Go launcher:

```bash
adkgo web -otel_to_cloud
```

### Programmatic Setup

#### Using ADK App abstractions

If you are using the `AdkApp` abstraction, you can enable cloud tracing by adding `enable_tracing=True`:

```python
from google.adk.apps import AdkApp

adk_app = AdkApp(
    agent=root_agent,
    enable_tracing=True,
)
```

#### Using Telemetry modules

For fully customized agent runtimes, you can enable cloud tracing by using the built-in telemetry modules.

```python
from google.adk import telemetry
from google.adk.telemetry import google_cloud

# Get GCP exporters configuration
hooks = google_cloud.get_gcp_exporters(enable_cloud_tracing=True)

# Initialize and set global OTel providers
telemetry.maybe_set_otel_providers(otel_hooks_to_setup=[hooks])
```

```typescript
import { getGcpExporters, maybeSetOtelProviders } from '@google/adk';

// Get GCP exporters configuration
const gcpExporters = await getGcpExporters({
  enableTracing: true,
});

// Initialize and set global OTel providers
maybeSetOtelProviders([gcpExporters]);

// ... your agent code ...
```

```go
import (
    "context"
    "log"
    "time"

    "google.golang.org/adk/telemetry"
)

func main() {
    ctx := context.Background()

    // Initialize telemetry with cloud export enabled.
    // By default, the GCP project ID is read from the GOOGLE_CLOUD_PROJECT environment variable.
    // You can also specify it explicitly using telemetry.WithGcpResourceProject("my-project").
    telemetryProviders, err := telemetry.New(ctx,
        telemetry.WithOtelToCloud(true),
        // telemetry.WithGcpResourceProject("your-project-id"),
    )
    if err != nil {
        log.Fatalf("failed to initialize telemetry: %v", err)
    }
    defer func() {
        shutdownCtx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
        defer cancel()
        if err := telemetryProviders.Shutdown(shutdownCtx); err != nil {
            log.Printf("failed to shutdown telemetry: %v", err)
        }
    }()

    // Register as global OTel providers
    telemetryProviders.SetGlobalOtelProviders()

    // ... your agent code ...
}
```

## Inspect Cloud Traces

After the setup is complete, whenever you interact with the agent, it will automatically send trace data to Cloud Trace. You can inspect the traces by visiting the **Trace Explorer** in the [Google Cloud Console](https://console.cloud.google.com).

You will see all available traces produced by the ADK agent, with span names such as `invoke_agent`, `generate_content`, `call_llm`, and `execute_tool`.

If you click on one of the traces, you will see a waterfall view of the detailed process, similar to the trace view in the local ADK web UI.

## Resources

- [Google Cloud Trace Documentation](https://cloud.google.com/trace)
- [OpenTelemetry Documentation](https://opentelemetry.io/docs/)

# Agent Runtime Code Execution tool for ADK

Supported in ADKPython v1.17.0

The Agent Runtime Code Execution ADK Tool provides a low-latency, highly efficient method for running AI-generated code using the [Google Cloud Agent Runtime](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview) service. This tool is designed for fast execution, tailored for agentic workflows, and uses sandboxed environments for improved security. The Code Execution tool allows code and data to persist over multiple requests, enabling complex, multi-step coding tasks, including:

- **Code development and debugging:** Create agent tasks that test and iterate on versions of code over multiple requests.
- **Code with data analysis:** Upload data files up to 100MB, and run multiple code-based analyses without the need to reload data for each code run.

This code execution tool is part of the Agent Runtime suite, however you do not have to deploy your agent to Agent Runtime to use it. You can run your agent locally or with other services and use this tool. For more information about the Code Execution feature in Agent Runtime, see the [Agent Runtime Code Execution](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/code-execution/overview) documentation.

## Use the Tool

Using the Agent Runtime Code Execution tool requires that you create a sandbox environment with Google Cloud Agent Runtime before using the tool with an ADK agent.

To use the Code Execution tool with your ADK agent:

1. Follow the instructions in the Agent Runtime [Code Execution quickstart](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/code-execution/quickstart) to create a code execution sandbox environment.
1. Create an ADK agent with settings to access the Google Cloud project where you created the sandbox environment.
1. The following code example shows an agent configured to use the Code Executor tool. Replace `SANDBOX_RESOURCE_NAME` with the sandbox environment resource name you created.

```python
from google.adk.agents.llm_agent import Agent
from google.adk.code_executors.agent_engine_sandbox_code_executor import AgentEngineSandboxCodeExecutor

root_agent = Agent(
    model="gemini-flash-latest",
    name="agent_engine_code_execution_agent",
    instruction="You are a helpful agent that can write and execute code to answer questions and solve problems.",
    code_executor=AgentEngineSandboxCodeExecutor(
        sandbox_resource_name="SANDBOX_RESOURCE_NAME",
    ),
)
```

For details on the expected format of the `sandbox_resource_name` value, and the alternative `agent_engine_resource_name` parameter, see [Configuration parameters](#config-parameters). For a more advanced example, including recommended system instructions for the tool, see the [Advanced example](#advanced-example) or the full [agent code example](https://github.com/google/adk-python/tree/main/contributing/samples/agent_engine_code_execution).

## How it works

The `AgentEngineCodeExecutor` Tool maintains a single sandbox throughout an agent's task, meaning the sandbox's state persists across all operations within an ADK workflow session.

1. **Sandbox creation:** For multi-step tasks requiring code execution, the Agent Runtime creates a sandbox with specified language and machine configurations, isolating the code execution environment. If no sandbox is pre-created, the code execution tool will automatically create one using default settings.
1. **Code execution with persistence:** AI-generated code for a tool call is streamed to the sandbox and then executed within the isolated environment. After execution, the sandbox *remains active* for subsequent tool calls within the same session, preserving variables, imported modules, and file state for the next tool call from the same agent.
1. **Result retrieval:** The standard output, and any captured error streams are collected and passed back to the calling agent.
1. **Sandbox clean up:** Once the agent task or conversation concludes, the agent can explicitly delete the sandbox, or rely on the TTL feature of the sandbox specified when creating the sandbox.

## Key benefits

- **Persistent state:** Solve complex tasks where data manipulation or variable context must carry over between multiple tool calls.
- **Targeted Isolation:** Provides robust process-level isolation, ensuring that tool code execution is safe while remaining lightweight.
- **Agent Runtime integration:** Tightly integrated into the Agent Runtime tool-use and orchestration layer.
- **Low-latency performance:** Designed for speed, allowing agents to execute complex tool-use workflows efficiently without significant overhead.
- **Flexible compute configurations:** Create sandboxes with specific programming language, processing power, and memory configurations.

## System requirements¶

The following requirements must be met to successfully use the Agent Runtime Code Execution tool with your ADK agents:

- Google Cloud project with Agent Platform API enabled
- Agent's service account requires **roles/aiplatform.user** role, which allow it to:
  - Create, get, list and delete code execution sandboxes
  - Execute code execution sandbox

## Configuration parameters

The Agent Runtime Code Execution tool has the following parameters. You must set one of the following resource parameters:

- **`sandbox_resource_name`** : A sandbox resource path to an existing sandbox environment it uses for each tool call. The expected string format is as follows:

  ```text
  projects/{$PROJECT_ID}/locations/{$LOCATION_ID}/reasoningEngines/{$REASONING_ENGINE_ID}/sandboxEnvironments/{$SANDBOX_ENVIRONMENT_ID}

  # Example:
  projects/my-vertex-agent-project/locations/us-central1/reasoningEngines/6842888880301111172/sandboxEnvironments/6545148888889161728
  ```

- **`agent_engine_resource_name`**: Agent Runtime resource name where the tool creates a sandbox environment. The expected string format is as follows:

  ```text
  projects/{$PROJECT_ID}/locations/{$LOCATION_ID}/reasoningEngines/{$REASONING_ENGINE_ID}

  # Example:
  projects/my-vertex-agent-project/locations/us-central1/reasoningEngines/6842888880301111172
  ```

You can use Google Cloud Agent Runtime's API to configure Agent Runtime sandbox environments separately using a Google Cloud client connection, including the following settings:

- **Programming languages,** including Python and JavaScript
- **Compute environment**, including CPU and memory sizes

For more information on connecting to Google Cloud Agent Runtime and configuring sandbox environments, see the Agent Runtime [Code Execution quickstart](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/code-execution/quickstart#create_a_sandbox).

## Advanced example

The following example code shows how to implement use of the Code Executor tool in an ADK agent. This example includes a `base_system_instruction` clause to set the operating guidelines for code execution. This instruction clause is optional, but strongly recommended for getting the best results from this tool.

````python
from google.adk.agents.llm_agent import Agent
from google.adk.code_executors.agent_engine_sandbox_code_executor import AgentEngineSandboxCodeExecutor

def base_system_instruction():
  """Returns: data science agent system instruction."""

  return """
  # Guidelines

  **Objective:** Assist the user in achieving their data analysis goals, **with emphasis on avoiding assumptions and ensuring accuracy.** Reaching that goal can involve multiple steps. When you need to generate code, you **don't** need to solve the goal in one go. Only generate the next step at a time.

  **Code Execution:** All code snippets provided will be executed within the sandbox environment.

  **Statefulness:** All code snippets are executed and the variables stays in the environment. You NEVER need to re-initialize variables. You NEVER need to reload files. You NEVER need to re-import libraries.

  **Output Visibility:** Always print the output of code execution to visualize results, especially for data exploration and analysis. For example:
    - To look a the shape of a pandas.DataFrame do:
      ```tool_code
      print(df.shape)
      ```
      The output will be presented to you as:
      ```tool_outputs
      (49, 7)

      ```
    - To display the result of a numerical computation:
      ```tool_code
      x = 10 ** 9 - 12 ** 5
      print(f'{{x=}}')
      ```
      The output will be presented to you as:
      ```tool_outputs
      x=999751168

      ```
    - You **never** generate ```tool_outputs yourself.
    - You can then use this output to decide on next steps.
    - Print just variables (e.g., `print(f'{{variable=}}')`.

  **No Assumptions:** **Crucially, avoid making assumptions about the nature of the data or column names.** Base findings solely on the data itself. Always use the information obtained from `explore_df` to guide your analysis.

  **Available files:** Only use the files that are available as specified in the list of available files.

  **Data in prompt:** Some queries contain the input data directly in the prompt. You have to parse that data into a pandas DataFrame. ALWAYS parse all the data. NEVER edit the data that are given to you.

  **Answerability:** Some queries may not be answerable with the available data. In those cases, inform the user why you cannot process their query and suggest what type of data would be needed to fulfill their request.

  """

root_agent = Agent(
    model="gemini-flash-latest",
    name="agent_engine_code_execution_agent",
    instruction=base_system_instruction() + """


You need to assist the user with their queries by looking at the data and the context in the conversation.
You final answer should summarize the code and code execution relevant to the user query.

You should include all pieces of data to answer the user query, such as the table from code execution results.
If you cannot answer the question directly, you should follow the guidelines above to generate the next step.
If the question can be answered directly with writing any code, you should do that.
If you doesn't have enough data to answer the question, you should ask for clarification from the user.

You should NEVER install any package on your own like `pip install ...`.
When plotting trends, you should make sure to sort and order the data by the x-axis.


""",
    code_executor=AgentEngineSandboxCodeExecutor(
        # Replace with your sandbox resource name if you already have one.
        sandbox_resource_name="SANDBOX_RESOURCE_NAME",
        # Replace with agent engine resource name used for creating sandbox if
        # sandbox_resource_name is not set:
        # agent_engine_resource_name="AGENT_ENGINE_RESOURCE_NAME",
    ),
)
````

For a complete version of an ADK agent using this example code, see the [agent_engine_code_execution sample](https://github.com/google/adk-python/tree/main/contributing/samples/agent_engine_code_execution).

# Gemini API Code Execution tool for ADK

Supported in ADKPython v0.1.0Java v0.2.0

The `built_in_code_execution` tool enables the agent to execute code, specifically when using Gemini 2 and higher models. This allows the model to perform tasks like calculations, data manipulation, or running small scripts.

Warning: Single tool per agent limitation

This tool can only be used ***by itself*** within an agent instance. For more information about this limitation and workarounds, see [Limitations for ADK tools](/tools/limitations/#one-tool-one-agent).

````py
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import asyncio
from google.adk.agents import LlmAgent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.code_executors import BuiltInCodeExecutor
from google.genai import types

AGENT_NAME = "calculator_agent"
APP_NAME = "calculator"
USER_ID = "user1234"
SESSION_ID = "session_code_exec_async"
GEMINI_MODEL = "gemini-2.0-flash"

# Agent Definition
code_agent = LlmAgent(
    name=AGENT_NAME,
    model=GEMINI_MODEL,
    code_executor=BuiltInCodeExecutor(),
    instruction="""You are a calculator agent.
    When given a mathematical expression, write and execute Python code to calculate the result.
    Return only the final numerical result as plain text, without markdown or code blocks.
    """,
    description="Executes Python code to perform calculations.",
)

# Session and Runner
session_service = InMemorySessionService()
session = asyncio.run(session_service.create_session(
    app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID
))
runner = Runner(agent=code_agent, app_name=APP_NAME,
                session_service=session_service)

# Agent Interaction (Async)
async def call_agent_async(query):
    content = types.Content(role="user", parts=[types.Part(text=query)])
    print(f"\n--- Running Query: {query} ---")
    final_response_text = "No final text response captured."
    try:
        # Use run_async
        async for event in runner.run_async(
            user_id=USER_ID, session_id=SESSION_ID, new_message=content
        ):
            print(f"Event ID: {event.id}, Author: {event.author}")

            # --- Check for specific parts FIRST ---
            has_specific_part = False
            if event.content and event.content.parts:
                for part in event.content.parts:  # Iterate through all parts
                    if part.executable_code:
                        # Access the actual code string via .code
                        print(
                            f"  Debug: Agent generated code:\n```python\n{part.executable_code.code}\n```"
                        )
                        has_specific_part = True
                    elif part.code_execution_result:
                        # Access outcome and output correctly
                        print(
                            f"  Debug: Code Execution Result: {part.code_execution_result.outcome} - Output:\n{part.code_execution_result.output}"
                        )
                        has_specific_part = True
                    # Also print any text parts found in any event for debugging
                    elif part.text and not part.text.isspace():
                        print(f"  Text: '{part.text.strip()}'")
                        # Do not set has_specific_part=True here, as we want the final response logic below

            # --- Check for final response AFTER specific parts ---
            # Only consider it final if it doesn't have the specific code parts we just handled
            if not has_specific_part and event.is_final_response():
                if (
                    event.content
                    and event.content.parts
                    and event.content.parts[0].text
                ):
                    final_response_text = event.content.parts[0].text.strip()
                    print(f"==> Final Agent Response: {final_response_text}")
                else:
                    print(
                        "==> Final Agent Response: [No text content in final event]")

    except Exception as e:
        print(f"ERROR during agent run: {e}")
    print("-" * 30)


# Main async function to run the examples
async def main():
    await call_agent_async("Calculate the value of (5 + 7) * 3")
    await call_agent_async("What is 10 factorial?")


# Execute the main async function
try:
    asyncio.run(main())
except RuntimeError as e:
    # Handle specific error when running asyncio.run in an already running loop (like Jupyter/Colab)
    if "cannot be called from a running event loop" in str(e):
        print("\nRunning in an existing event loop (like Colab/Jupyter).")
        print("Please run `await main()` in a notebook cell instead.")
        # If in an interactive environment like a notebook, you might need to run:
        # await main()
    else:
        raise e  # Re-raise other runtime errors
````

````java
import com.google.adk.agents.BaseAgent;
import com.google.adk.agents.LlmAgent;
import com.google.adk.runner.Runner;
import com.google.adk.sessions.InMemorySessionService;
import com.google.adk.sessions.Session;
import com.google.adk.tools.BuiltInCodeExecutionTool;
import com.google.common.collect.ImmutableList;
import com.google.genai.types.Content;
import com.google.genai.types.Part;

public class CodeExecutionAgentApp {

  private static final String AGENT_NAME = "calculator_agent";
  private static final String APP_NAME = "calculator";
  private static final String USER_ID = "user1234";
  private static final String SESSION_ID = "session_code_exec_sync";
  private static final String GEMINI_MODEL = "gemini-2.0-flash";

  /**
   * Calls the agent with a query and prints the interaction events and final response.
   *
   * @param runner The runner instance for the agent.
   * @param query The query to send to the agent.
   */
  public static void callAgent(Runner runner, String query) {
    Content content =
        Content.builder().role("user").parts(ImmutableList.of(Part.fromText(query))).build();

    InMemorySessionService sessionService = (InMemorySessionService) runner.sessionService();
    Session session =
        sessionService
            .createSession(APP_NAME, USER_ID, /* state= */ null, SESSION_ID)
            .blockingGet();

    System.out.println("\n--- Running Query: " + query + " ---");
    final String[] finalResponseText = {"No final text response captured."};

    try {
      runner
          .runAsync(session.userId(), session.id(), content)
          .forEach(
              event -> {
                System.out.println("Event ID: " + event.id() + ", Author: " + event.author());

                boolean hasSpecificPart = false;
                if (event.content().isPresent() && event.content().get().parts().isPresent()) {
                  for (Part part : event.content().get().parts().get()) {
                    if (part.executableCode().isPresent()) {
                      System.out.println(
                          "  Debug: Agent generated code:\n```python\n"
                              + part.executableCode().get().code()
                              + "\n```");
                      hasSpecificPart = true;
                    } else if (part.codeExecutionResult().isPresent()) {
                      System.out.println(
                          "  Debug: Code Execution Result: "
                              + part.codeExecutionResult().get().outcome()
                              + " - Output:\n"
                              + part.codeExecutionResult().get().output());
                      hasSpecificPart = true;
                    } else if (part.text().isPresent() && !part.text().get().trim().isEmpty()) {
                      System.out.println("  Text: '" + part.text().get().trim() + "'");
                    }
                  }
                }

                if (!hasSpecificPart && event.finalResponse()) {
                  if (event.content().isPresent()
                      && event.content().get().parts().isPresent()
                      && !event.content().get().parts().get().isEmpty()
                      && event.content().get().parts().get().get(0).text().isPresent()) {
                    finalResponseText[0] =
                        event.content().get().parts().get().get(0).text().get().trim();
                    System.out.println("==> Final Agent Response: " + finalResponseText[0]);
                  } else {
                    System.out.println(
                        "==> Final Agent Response: [No text content in final event]");
                  }
                }
              });
    } catch (Exception e) {
      System.err.println("ERROR during agent run: " + e.getMessage());
      e.printStackTrace();
    }
    System.out.println("------------------------------");
  }

  public static void main(String[] args) {
    BuiltInCodeExecutionTool codeExecutionTool = new BuiltInCodeExecutionTool();

    BaseAgent codeAgent =
        LlmAgent.builder()
            .name(AGENT_NAME)
            .model(GEMINI_MODEL)
            .tools(ImmutableList.of(codeExecutionTool))
            .instruction(
                """
                                You are a calculator agent.
                                When given a mathematical expression, write and execute Python code to calculate the result.
                                Return only the final numerical result as plain text, without markdown or code blocks.
                                """)
            .description("Executes Python code to perform calculations.")
            .build();

    InMemorySessionService sessionService = new InMemorySessionService();
    Runner runner = new Runner(codeAgent, APP_NAME, null, sessionService);

    callAgent(runner, "Calculate the value of (5 + 7) * 3");
    callAgent(runner, "What is 10 factorial?");
  }
}
````

# Gemini API Computer Use tool for ADK

Supported in ADKPython v1.17.0Preview

The Computer Use Toolset allows an agent to operate a user interface of a computer, such as browsers, to complete tasks. This tool uses a specific Gemini model and the [Playwright](https://playwright.dev/) testing tool to control a Chromium browser and can interact with web pages by taking screenshots, clicking, typing, and navigating.

For more information about the computer use model, see Gemini API [Computer use](https://ai.google.dev/gemini-api/docs/computer-use) or the Agent Platform API [Computer use](https://cloud.google.com/vertex-ai/generative-ai/docs/computer-use).

Preview release

The Computer Use model and tool is a Preview release. For more information, see the [launch stage descriptions](https://cloud.google.com/products#product-launch-stages).

## Setup

You must install Playwright and its dependencies, including Chromium, to be able to use the Computer Use Toolset.

Recommended: create and activate a Python virtual environment

Create a Python virtual environment:

```shell
python3 -m venv .venv
```

Activate the Python virtual environment:

```console
.venv\Scripts\activate.bat
```

```console
.venv\Scripts\Activate.ps1
```

```bash
source .venv/bin/activate
```

To set up the required software libraries for the Computer Use Toolset:

1. Install Python dependencies:

   ```console
   pip install termcolor==3.1.0
   pip install playwright==1.52.0
   pip install browserbase==1.3.0
   pip install rich
   ```

1. Install the Playwright dependencies, including the Chromium browser:

   ```console
   playwright install-deps chromium
   playwright install chromium
   ```

## Use the tool

Use the Computer Use Toolset by adding it as a tool to your agent. When you configure the tool, you must provide a implementation of the `BaseComputer` class which defines an interface for an agent to use a computer. In the following example, the `PlaywrightComputer` class is defined for this purpose. You can find the code for this implementation in `playwright.py` file of the [computer_use](https://github.com/google/adk-python/blob/main/contributing/samples/computer_use/playwright.py) agent sample project.

```python
from google.adk import Agent
from google.adk.models.google_llm import Gemini
from google.adk.tools.computer_use.computer_use_toolset import ComputerUseToolset
from typing_extensions import override

from .playwright import PlaywrightComputer

root_agent = Agent(
    model='gemini-2.5-computer-use-preview-10-2025',
    name='hello_world_agent',
    description=(
        'computer use agent that can operate a browser on a computer to finish'
        ' user tasks'
    ),
    instruction='you are a computer use agent',
    tools=[
        ComputerUseToolset(computer=PlaywrightComputer(screen_size=(1280, 936)))
    ],
)
```

For a complete code example, see the [computer_use](https://github.com/google/adk-python/tree/main/contributing/samples/computer_use) agent sample project.

# Couchbase MCP tool for ADK

Supported in ADKPythonTypeScript

The [Couchbase MCP Server](https://github.com/Couchbase-Ecosystem/mcp-server-couchbase) connects your ADK agent to [Couchbase](https://www.couchbase.com/) clusters. This integration gives your agent the ability to explore Couchbase data using natural language, including exploring data, running queries, and analyzing performance issues.

## Use cases

- **Data Exploration**: Discover buckets, scopes, collections, and document schemas, query data using natural language queries.
- **Database Administration**: Monitor cluster health, check running services, and manage bucket, scope, and collection structures through conversational commands.
- **Query Performance Analysis**: Get index recommendations, analyze query plans, and investigate slow or non-selective queries to optimize performance.

## Prerequisites

- A running Couchbase cluster. You can:
  - Use [Couchbase Capella](https://cloud.couchbase.com/) (managed cloud service)
  - Run Couchbase Server 7.x+ locally or self-hosted
- Connection string and credentials (username/password or client certificate for mTLS) for the cluster
- [`uv`](https://docs.astral.sh/uv/) package manager installed (for the `uvx` command)

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

CB_CONNECTION_STRING = "couchbase://localhost"
CB_USERNAME = "Administrator"
CB_PASSWORD = "password"

root_agent = Agent(
    model="gemini-flash-latest",
    name="couchbase_agent",
    instruction="Help users explore and query Couchbase databases",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="uvx",
                    args=["couchbase-mcp-server"],
                    env={
                        "CB_CONNECTION_STRING": CB_CONNECTION_STRING,
                        "CB_USERNAME": CB_USERNAME,
                        "CB_PASSWORD": CB_PASSWORD,
                        "CB_MCP_READ_ONLY_MODE": "true",  # Prevents write operations
                    },
                ),
                timeout=60,
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const CB_CONNECTION_STRING = "couchbase://localhost";
const CB_USERNAME = "Administrator";
const CB_PASSWORD = "password";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "couchbase_agent",
    instruction: "Help users explore and query Couchbase databases",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "uvx",
                args: ["couchbase-mcp-server"],
                env: {
                    CB_CONNECTION_STRING: CB_CONNECTION_STRING,
                    CB_USERNAME: CB_USERNAME,
                    CB_PASSWORD: CB_PASSWORD,
                    CB_MCP_READ_ONLY_MODE: "true", // Prevents write operations
                },
            },
        })
    ],
});

export { rootAgent };
```

## Available tools

### Cluster setup and health tools

| Tool                              | Description                                                |
| --------------------------------- | ---------------------------------------------------------- |
| `get_server_configuration_status` | Get the status of the MCP server                           |
| `test_cluster_connection`         | Check the cluster credentials by connecting to the cluster |
| `get_cluster_health_and_services` | Get cluster health status and list of all running services |

### Data model and schema discovery tools

| Tool                                   | Description                                                          |
| -------------------------------------- | -------------------------------------------------------------------- |
| `get_buckets_in_cluster`               | Get a list of all the buckets in the cluster                         |
| `get_scopes_in_bucket`                 | Get a list of all the scopes in the specified bucket                 |
| `get_collections_in_scope`             | Get a list of all the collections in a specified scope and bucket    |
| `get_scopes_and_collections_in_bucket` | Get a list of all the scopes and collections in the specified bucket |
| `get_schema_for_collection`            | Get the structure for a collection                                   |

### Document KV operations tools

| Tool                     | Description                                                                                                           |
| ------------------------ | --------------------------------------------------------------------------------------------------------------------- |
| `get_document_by_id`     | Get a document by ID from a specified scope and collection                                                            |
| `upsert_document_by_id`  | Upsert a document by ID to a specified scope and collection. **Disabled when `CB_MCP_READ_ONLY_MODE=true`.**          |
| `insert_document_by_id`  | Insert a new document by ID (fails if document exists). **Disabled when `CB_MCP_READ_ONLY_MODE=true`.**               |
| `replace_document_by_id` | Replace an existing document by ID (fails if document doesn't exist). **Disabled when `CB_MCP_READ_ONLY_MODE=true`.** |
| `delete_document_by_id`  | Delete a document by ID from a specified scope and collection. **Disabled when `CB_MCP_READ_ONLY_MODE=true`.**        |

### Query and indexing tools

| Tool                                | Description                                                                                                                 |
| ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------- |
| `run_sql_plus_plus_query`           | Run a [SQL++ query](https://www.couchbase.com/sqlplusplus/) on a specified scope                                            |
| `list_indexes`                      | List all indexes in the cluster with their definitions, with optional filtering by bucket, scope, collection and index name |
| `get_index_advisor_recommendations` | Get index recommendations from Couchbase Index Advisor for a given SQL++ query to optimize query performance                |

### Query performance analysis tools

| Tool                                      | Description                                                                                   |
| ----------------------------------------- | --------------------------------------------------------------------------------------------- |
| `get_longest_running_queries`             | Get longest running queries by average service time                                           |
| `get_most_frequent_queries`               | Get most frequently executed queries                                                          |
| `get_queries_with_largest_response_sizes` | Get queries with the largest response sizes                                                   |
| `get_queries_with_large_result_count`     | Get queries with the largest result counts                                                    |
| `get_queries_using_primary_index`         | Get queries that use a primary index (potential performance concern)                          |
| `get_queries_not_using_covering_index`    | Get queries that don't use a covering index                                                   |
| `get_queries_not_selective`               | Get queries that are not selective (index scans return many more documents than final result) |

## Configuration

### Environment variables

| Variable                | Description                                                        | Default                                   |
| ----------------------- | ------------------------------------------------------------------ | ----------------------------------------- |
| `CB_CONNECTION_STRING`  | Connection string to the Couchbase cluster                         | Required                                  |
| `CB_USERNAME`           | Username for basic authentication                                  | Required (or client certificate for mTLS) |
| `CB_PASSWORD`           | Password for basic authentication                                  | Required (or client certificate for mTLS) |
| `CB_CLIENT_CERT_PATH`   | Path to the client certificate file for mTLS authentication        | None                                      |
| `CB_CLIENT_KEY_PATH`    | Path to the client key file for mTLS authentication                | None                                      |
| `CB_CA_CERT_PATH`       | Path to server root certificate for TLS (not required for Capella) | None                                      |
| `CB_MCP_READ_ONLY_MODE` | Prevent all data modifications (KV and query)                      | `true`                                    |
| `CB_MCP_DISABLED_TOOLS` | Comma-separated list of tools to disable                           | None                                      |

### Read-only mode

The `CB_MCP_READ_ONLY_MODE` setting (enabled by default) restricts the server to read-only operations. When enabled, KV write tools (`upsert_document_by_id`, `insert_document_by_id`, `replace_document_by_id`, `delete_document_by_id`) are not loaded, and SQL++ queries that modify data are blocked. This makes it safe for data exploration without risk of accidental modifications.

### Disabling tools

You can disable specific tools using `CB_MCP_DISABLED_TOOLS`:

```python
env={
    "CB_CONNECTION_STRING": "couchbase://localhost",
    "CB_USERNAME": "Administrator",
    "CB_PASSWORD": "password",
    "CB_MCP_DISABLED_TOOLS": "get_index_advisor_recommendations,get_queries_not_selective",
}
```

## Additional resources

- [Couchbase MCP Server Repository](https://github.com/Couchbase-Ecosystem/mcp-server-couchbase)
- [Couchbase Documentation](https://docs.couchbase.com/)
- [Couchbase Capella](https://cloud.couchbase.com/)

# Google Cloud Data Agents tool for ADK

Supported in ADKPython v1.23.0

These are a set of tools aimed to provide integration with Data Agents powered by [Conversational Analytics API](https://docs.cloud.google.com/gemini/docs/conversational-analytics-api/overview).

Data Agents are AI-powered agents that help you analyze your data using natural language. When configuring a Data Agent, you can choose from supported data sources, including **BigQuery**, **Looker**, and **Looker Studio**.

**Prerequisites**

Before using these tools, you must build and configure your Data Agents in Google Cloud:

- [Build a data agent using HTTP and Python](https://docs.cloud.google.com/gemini/docs/conversational-analytics-api/build-agent-http)
- [Build a data agent using the Python SDK](https://docs.cloud.google.com/gemini/docs/conversational-analytics-api/build-agent-sdk)
- [Create a data agent in BigQuery Studio](https://docs.cloud.google.com/bigquery/docs/create-data-agents#create_a_data_agent)

The `DataAgentToolset` includes the following tools:

- **`list_accessible_data_agents`**: Lists Data Agents you have permission to access in the configured GCP project.
- **`get_data_agent_info`**: Retrieves details about a specific Data Agent given its full resource name.
- **`ask_data_agent`**: Chats with a specific Data Agent using natural language.

They are packaged in the toolset `DataAgentToolset`.

```py
# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import asyncio

from google.adk.agents import Agent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.tools.data_agent.config import DataAgentToolConfig
from google.adk.tools.data_agent.credentials import DataAgentCredentialsConfig
from google.adk.tools.data_agent.data_agent_toolset import DataAgentToolset
from google.genai import types
import google.auth

# Define constants for this example agent
AGENT_NAME = "data_agent_example"
APP_NAME = "data_agent_app"
USER_ID = "user1234"
SESSION_ID = "1234"
GEMINI_MODEL = "gemini-2.5-flash"

# Define tool configuration
tool_config = DataAgentToolConfig(
    max_query_result_rows=100,
)

# Use Application Default Credentials (ADC)
# https://cloud.google.com/docs/authentication/provide-credentials-adc
application_default_credentials, _ = google.auth.default()
credentials_config = DataAgentCredentialsConfig(
    credentials=application_default_credentials
)

# Instantiate a Data Agent toolset
da_toolset = DataAgentToolset(
    credentials_config=credentials_config,
    data_agent_tool_config=tool_config,
    tool_filter=[
        "list_accessible_data_agents",
        "get_data_agent_info",
        "ask_data_agent",
    ],
)

# Agent Definition
data_agent = Agent(
    name=AGENT_NAME,
    model=GEMINI_MODEL,
    description="Agent to answer user questions using Data Agents.",
    instruction=(
        "## Persona\nYou are a helpful assistant that uses Data Agents"
        " to answer user questions about their data.\n\n"
    ),
    tools=[da_toolset],
)

# Session and Runner
session_service = InMemorySessionService()
session = asyncio.run(
    session_service.create_session(
        app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID
    )
)
runner = Runner(
    agent=data_agent, app_name=APP_NAME, session_service=session_service
)


# Agent Interaction
def call_agent(query):
    """
    Helper function to call the agent with a query.
    """
    content = types.Content(role="user", parts=[types.Part(text=query)])
    events = runner.run(user_id=USER_ID, session_id=SESSION_ID, new_message=content)

    print("USER:", query)
    for event in events:
        if event.is_final_response():
            final_response = event.content.parts[0].text
            print("AGENT:", final_response)


call_agent("List accessible data agents in project <PROJECT_ID>.")
call_agent("Get information about <DATA_AGENT_NAME>.")
# The data agent in this example is configured with the BigQuery table:
# `bigquery-public-data.san_francisco.street_trees`
call_agent("Ask <DATA_AGENT_NAME> to count the rows in the table.")
call_agent("What are the columns in the table?")
call_agent("What are the top 5 tree species?")
call_agent("For those species, what is the distribution of legal status?")
```

# Database Memory Service for ADK

Supported in ADKPython

[`adk-database-memory`](https://github.com/anmolg1997/adk-database-memory) is a drop-in persistent `BaseMemoryService` for ADK Python, backed by async SQLAlchemy. This integration provides persistent cross-session memory for ADK agents using your own database: use SQLite for development, or Postgres / MySQL for production.

## Use cases

- **Personalized assistants**: Accumulate long-term user preferences, facts, and past decisions across sessions so the agent can recall them on demand.
- **Support and task agents**: Persist conversation history across tickets and devices, so context is available whenever the user returns.
- **Self-hosted deployments**: When Vertex AI Memory Bank is not an option (on-prem, air-gapped, non-GCP cloud), keep memory on the database you already use.
- **Local development**: Drop in SQLite for zero-config persistent memory that survives restarts, then flip the connection string to Postgres in production.

## Prerequisites

- Python 3.10 or later
- A supported database: SQLite, PostgreSQL, or MySQL / MariaDB

## Installation

Install the package together with the driver for your database:

```bash
pip install "adk-database-memory[sqlite]"    # SQLite (via aiosqlite)
pip install "adk-database-memory[postgres]"  # PostgreSQL (via asyncpg)
pip install "adk-database-memory[mysql]"     # MySQL / MariaDB (via aiomysql)
```

The core package does not include any database drivers. Choose the extra that matches your backend, or install your own async driver separately.

## Use with agent

The service implements `google.adk.memory.base_memory_service.BaseMemoryService`, so it slots into any ADK `Runner` that accepts a `memory_service`:

```python
import asyncio

from adk_database_memory import DatabaseMemoryService
from google.adk.agents import Agent
from google.adk.runners import InMemoryRunner

memory = DatabaseMemoryService("sqlite+aiosqlite:///memory.db")

agent = Agent(
    name="assistant",
    model="gemini-flash-latest",
    instruction="You are a helpful assistant.",
)

async def main():
    async with memory:
        # Run the agent, then persist the session to memory
        runner = InMemoryRunner(agent=agent, app_name="my_app")
        session = await runner.session_service.create_session(app_name="my_app", user_id="u1")
        # After the session completes:
        await memory.add_session_to_memory(session)

        # Later, recall relevant memories for a new query:
        result = await memory.search_memory(
            app_name="my_app",
            user_id="u1",
            query="what did we decide about the pricing model?",
        )
        for entry in result.memories:
            print(entry.author, entry.timestamp, entry.content)

asyncio.run(main())
```

## Supported backends

| Backend                      | Connection URL example                   | Extra          |
| ---------------------------- | ---------------------------------------- | -------------- |
| SQLite                       | `sqlite+aiosqlite:///memory.db`          | `[sqlite]`     |
| SQLite (in-memory)           | `sqlite+aiosqlite:///:memory:`           | `[sqlite]`     |
| PostgreSQL                   | `postgresql+asyncpg://user:pass@host/db` | `[postgres]`   |
| MySQL / MariaDB              | `mysql+aiomysql://user:pass@host/db`     | `[mysql]`      |
| Any async SQLAlchemy dialect | depends on driver                        | bring your own |

## API

| Method                                                 | Description                                                                                                   |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------- |
| `add_session_to_memory(session)`                       | Index every event in a completed session.                                                                     |
| `add_events_to_memory(app_name, user_id, events, ...)` | Index an explicit slice of events (useful for streaming ingestion).                                           |
| `search_memory(app_name, user_id, query)`              | Return `MemoryEntry` objects whose indexed keywords overlap with the query, scoped to the given app and user. |

On first write, the service creates a single table (`adk_memory_entries`) with an index on `(app_name, user_id)`. JSON content is stored as `JSONB` on PostgreSQL, `LONGTEXT` on MySQL, and `TEXT` on SQLite.

Retrieval uses the same keyword-extraction and matching approach as the in-memory and Firestore memory services in ADK. For embedding-based recall, pair this package with Vertex AI Memory Bank or a vector store.

## Resources

- [GitHub repository](https://github.com/anmolg1997/adk-database-memory): source code, issues, and examples.
- [PyPI package](https://pypi.org/project/adk-database-memory/): releases and install instructions.
- [ADK Memory overview](/sessions/memory/): background on how ADK uses memory services.

# Datadog Observability for ADK

Supported in: Python

[Datadog LLM Observability](https://www.datadoghq.com/product/llm-observability/) helps AI engineers, data scientists, and application developers quickly develop, evaluate, and monitor LLM applications. Confidently improve output quality, performance, costs, and overall risk with structured experiments, end-to-end tracing across AI agents, and evaluations.

## Overview

Datadog LLM Observability can [automatically instrument and trace your agents built on Google ADK](https://docs.datadoghq.com/llm_observability/instrumentation/auto_instrumentation?tab=python#google-adk), allowing you to:

- **Observe agent executions and interactions** - Automatically capture every agent run, tool call, and code execution within your agents
- **Capture LLM calls and responses** made with the underlying Google GenAI SDK
- **Debug issues** by providing error rates, token usage and cost, and out-of-the-box evaluations on your LLM calls and tool usage

## Prerequisites

Sign up for a [Datadog account](https://www.datadoghq.com/) if you do not have one and [get your API key](https://docs.datadoghq.com/account_management/api-app-keys/#api-keys).

## Installation

Install the required packages:

```bash
pip install ddtrace
```

## Setup

### Create an Application using the Google ADK

If you do not have an application using the Google ADK, follow the steps in the [ADK Getting Started Guide](https://google.github.io/adk-docs/get-started/) to create a sample ADK agent.

### Configure Environment Variables

You will need to specify an ML Application name in the following environment variables. An ML Application is a grouping of LLM Observability traces associated with a specific LLM-based application. See [ML Application Naming Guidelines](https://docs.datadoghq.com/llm_observability/instrumentation/sdk?tab=python#application-naming-guidelines) for more information on limitations with ML Application names.

```shell
export DD_API_KEY=<YOUR_DD_API_KEY>
export DD_SITE=<YOUR_DD_SITE>
export DD_LLMOBS_ENABLED=true
export DD_LLMOBS_ML_APP=<YOUR_ML_APP_NAME>
export DD_LLMOBS_AGENTLESS_ENABLED=true
export DD_APM_TRACING_ENABLED=false  # Only set this if you are not using Datadog APM
```

These variables must be exported before running your application so the following `ddtrace-run` command can use them, as opposed to putting them in the agent's `.env` file.

### Run Your Application

Once you have configured your environment variables, you can run your application and start observing your LLM-based applications.

```shell
ddtrace-run adk run my_agent
```

## Observe

Navigate to the [Datadog LLM Observability Traces View](https://app.datadoghq.com/llm/traces) to see the traces generated by your application.

## Support and Resources

- [Datadog LLM Observability](https://www.datadoghq.com/product/llm-observability/)
- [Datadog Support](https://docs.datadoghq.com/help/)

# Daytona plugin for ADK

Supported in ADKPython

The [Daytona ADK plugin](https://github.com/daytonaio/daytona-adk-plugin) connects your ADK agent to [Daytona](https://www.daytona.io/) sandboxes. This integration gives your agent the ability to execute code, run shell commands, and manage files in isolated environments, enabling secure execution of AI-generated code.

## Use cases

- **Secure Code Execution**: Run Python, JavaScript, and TypeScript code in isolated sandboxes without risking your local environment.
- **Shell Command Automation**: Execute shell commands with configurable timeouts and working directories for build tasks, installations, or system operations.
- **File Management**: Upload scripts and datasets to sandboxes, then retrieve generated outputs and results.

## Prerequisites

- A [Daytona](https://www.daytona.io/) account
- Daytona API key

## Installation

```bash
pip install daytona-adk
```

## Use with agent

```python
from daytona_adk import DaytonaPlugin
from google.adk.agents import Agent

plugin = DaytonaPlugin(
  api_key="your-daytona-api-key" # Or set DAYTONA_API_KEY environment variable
)

root_agent = Agent(
    model="gemini-flash-latest",
    name="sandbox_agent",
    instruction="Help users execute code and commands in a secure sandbox",
    tools=plugin.get_tools(),
)
```

## Available tools

| Tool                                 | Description                                    |
| ------------------------------------ | ---------------------------------------------- |
| `execute_code_in_daytona`            | Execute Python, JavaScript, or TypeScript code |
| `execute_command_in_daytona`         | Run shell commands                             |
| `upload_file_to_daytona`             | Upload scripts or data files to the sandbox    |
| `read_file_from_daytona`             | Read script outputs or generated files         |
| `start_long_running_command_daytona` | Start background processes (servers, watchers) |

## Learn more

For a detailed guide on building a code generator agent that writes, tests, and verifies code in secure sandboxes, check out [this guide](https://www.daytona.io/docs/en/google-adk-code-generator).

## Additional resources

- [Code Generator Agent Guide](https://www.daytona.io/docs/en/google-adk-code-generator)
- [Daytona ADK on PyPI](https://pypi.org/project/daytona-adk/)
- [Daytona ADK on GitHub](https://github.com/daytonaio/daytona-adk-plugin)
- [Daytona Documentation](https://www.daytona.io/docs)

# ElevenLabs MCP tool for ADK

Supported in ADKPythonTypeScript

The [ElevenLabs MCP Server](https://github.com/elevenlabs/elevenlabs-mcp) connects your ADK agent to the [ElevenLabs](https://elevenlabs.io/) AI audio platform. This integration gives your agent the ability to generate speech, clone voices, transcribe audio, create sound effects, and build conversational AI experiences using natural language.

## Use cases

- **Text-to-Speech Generation**: Convert text into natural-sounding speech using a variety of voices, with fine-grained control over stability, style, and similarity settings.
- **Voice Cloning & Design**: Clone voices from audio samples or generate new voices from text descriptions of desired characteristics like age, gender, accent, and tone.
- **Audio Processing**: Isolate speech from background noise, convert audio to sound like different voices, or transcribe speech to text with speaker identification.
- **Sound Effects & Soundscapes**: Generate sound effects and ambient soundscapes from text descriptions, such as "a thunderstorm in a dense jungle with animals reacting to the weather."

## Prerequisites

- Sign up for an [ElevenLabs account](https://elevenlabs.io/app/sign-up)
- Generate an [API key](https://elevenlabs.io/app/settings/api-keys) from your account settings

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

ELEVENLABS_API_KEY = "YOUR_ELEVENLABS_API_KEY"

root_agent = Agent(
    model="gemini-flash-latest",
    name="elevenlabs_agent",
    instruction="Help users generate speech, clone voices, and process audio",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="uvx",
                    args=["elevenlabs-mcp"],
                    env={
                        "ELEVENLABS_API_KEY": ELEVENLABS_API_KEY,
                    }
                ),
                timeout=30,
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const ELEVENLABS_API_KEY = "YOUR_ELEVENLABS_API_KEY";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "elevenlabs_agent",
    instruction: "Help users generate speech, clone voices, and process audio",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "uvx",
                args: ["elevenlabs-mcp"],
                env: {
                    ELEVENLABS_API_KEY: ELEVENLABS_API_KEY,
                },
            },
        }),
    ],
});

export { rootAgent };
```

## Available tools

### Text-to-speech and voice

| Tool                        | Description                                       |
| --------------------------- | ------------------------------------------------- |
| `text_to_speech`            | Generate speech from text using a specified voice |
| `speech_to_speech`          | Transform audio to sound like a different voice   |
| `text_to_voice`             | Generate a voice preview from text description    |
| `create_voice_from_preview` | Save a generated voice preview to your library    |
| `voice_clone`               | Clone a voice from audio samples                  |
| `get_voice`                 | Get details about a specific voice                |
| `search_voices`             | Search for voices in your library                 |
| `search_voice_library`      | Search the public voice library                   |
| `list_models`               | List available text-to-speech models              |

### Audio processing

| Tool                      | Description                                          |
| ------------------------- | ---------------------------------------------------- |
| `speech_to_text`          | Transcribe audio to text with speaker identification |
| `text_to_sound_effects`   | Generate sound effects from text descriptions        |
| `isolate_audio`           | Separate speech from background noise and music      |
| `play_audio`              | Play an audio file locally                           |
| `compose_music`           | Generate music from a description                    |
| `create_composition_plan` | Create a plan for music composition                  |

### Conversational AI

| Tool                          | Description                                    |
| ----------------------------- | ---------------------------------------------- |
| `create_agent`                | Create a conversational AI agent               |
| `get_agent`                   | Get details about a specific agent             |
| `list_agents`                 | List all your conversational AI agents         |
| `add_knowledge_base_to_agent` | Add a knowledge base to an agent               |
| `make_outbound_call`          | Initiate an outbound phone call using an agent |
| `list_phone_numbers`          | List available phone numbers                   |
| `get_conversation`            | Get details about a specific conversation      |
| `list_conversations`          | List all conversations                         |

### Account

| Tool                 | Description                              |
| -------------------- | ---------------------------------------- |
| `check_subscription` | Check your subscription and credit usage |

## Configuration

The ElevenLabs MCP server can be configured using environment variables:

| Variable                     | Description                             | Default     |
| ---------------------------- | --------------------------------------- | ----------- |
| `ELEVENLABS_API_KEY`         | Your ElevenLabs API key                 | Required    |
| `ELEVENLABS_MCP_BASE_PATH`   | Base path for file operations           | `~/Desktop` |
| `ELEVENLABS_MCP_OUTPUT_MODE` | How generated files are returned        | `files`     |
| `ELEVENLABS_API_RESIDENCY`   | Data residency region (enterprise only) | `us`        |

### Output modes

The `ELEVENLABS_MCP_OUTPUT_MODE` environment variable supports three modes:

- **`files`** (default): Save files to disk and return file paths
- **`resources`**: Return files as MCP resources (base64-encoded binary data)
- **`both`**: Save files to disk AND return as MCP resources

## Additional resources

- [ElevenLabs MCP Server Repository](https://github.com/elevenlabs/elevenlabs-mcp)
- [Introducing ElevenLabs MCP](https://elevenlabs.io/blog/introducing-elevenlabs-mcp)
- [ElevenLabs Documentation](https://elevenlabs.io/docs)

# Environment Toolsets for ADK

Supported in ADKPython v1.29.0Experimental

Some types of tasks, particularly coding and file operations, require an agent to interact with a compute environment that can run code and operate on files that persist across multiple agent requests. The ***EnvironmentToolset*** class for ADK allows agents to interact with an environment to perform file operations and execute shell commands. The Environment Toolset is designed as a general framework for configuring and using local or remote execution environments with ADK agents. ADK provides a [***LocalEnvironment***](#local-environment) implementation for use with the Environment Toolset framework.

Experimental

The Environment Toolset feature is experimental and may be updated. We welcome your [feedback](https://github.com/google/adk-python/issues/new?template=feature_request.md)!

## Get started

Enable local environment interactions by adding the ***EnvironmentToolset*** with a ***LocalEnvironment*** instance to your agent's tools.

```python
from google.adk import Agent
from google.adk.environment import LocalEnvironment
from google.adk.tools.environment import EnvironmentToolset

root_agent = Agent(
    model="gemini-flash-latest",
    name="my_agent",
    instruction="""
    You are a helpful AI assistant that can use the local environment
    to execute commands and file I/O. Follow the rules of the
    environment and the user's instructions.
    """,
    tools=[
        EnvironmentToolset(
            environment=LocalEnvironment(),
        ),
    ],
)
```

For a full implementation example, see the [Local environment sample](https://github.com/google/adk-python/tree/main/contributing/samples/local_environment).

### Try with agent

You can interact with an agent configured with the Environment Toolset by providing prompts that require file operations and command execution. Try the following prompt in an interactive session with an agent:

```text
Write a Python file named hello.py to the working directory
that prints 'Hello from ADK!'. Then read the file to verify
its contents, and finally execute it using a command.
```

Based on these instructions, the agent performs the following operations:

- Write File: The agent writes a `hello.py` file with the content "Hello from ADK!".
- Read File: The agent reads the `hello.py` file and verifies its content.
- Execute: The agent runs the `hello.py` file and returns the output.

## LocalEnvironment

The ***LocalEnvironment*** class is an environment implementation provided by ADK for use with ***Environment Toolset***. This environment provides the following capabilities:

- **Local Execution:** Run shell commands and scripts directly on the local machine using Python asyncio subprocesses.
- **File Operations:** Create, read, and modify files within a specified working directory.
- **Customization:** Configure custom environment variables and working directories for the agent's workspace.
- **Framework Compatibility:** Works with both ADK 1.0 and ADK 2.0 framework versions, including graph-based workflows.

### Configuration options

The ***LocalEnvironment*** class supports the following parameters:

- **working_dir**: (optional) The directory where the agent will perform file operations and execute commands. Setting a working directory means that any generated files are still accessible after the agent runs. For more details, see [File persistence](#file-persistence).
- **env_vars**: (optional) A dictionary of environment variables to be set for the execution context.

The following code sample shows how to set these options for a ***LocalEnvironment*** object:

```python
local_environment=LocalEnvironment(
    working_dir="/tmp/my_agent_workspace",
    env_vars={"PORT": "8080", "LOG_LEVEL": "DEBUG"},
)
```

### File operations

The ***LocalEnvironment*** implementation includes the following tools an agent can run within a local compute environment:

- ***ReadFile***: Read an existing text file based on agent instructions.
- ***EditFile***: Edit an existing text file based on agent instructions.
- ***WriteFile***: Create a new text file based on agent instructions.
- ***Execute***: Execute terminal commands, including running installers, shell scripts, and program code, based on agent instructions.

Danger: Potential data loss, code execution

Executing terminal commands in a local environment can cause loss of data and impact the execution of code and applications in that environment. Exercise caution and consider implementing human permission checks before allowing agents to change files and execute commands.

Commands executed with ***LocalEnvironment*** use `asyncio.create_subprocess_shell`, ensuring that the agent remains responsive during long-running tasks.

### File persistence

Files and file output generated with the ***LocalEnvironment*** are placed in a temporary directory by default. That directory is removed when an agent is shut down, for example, when exiting an ADK Web session. However, if you set a ***working directory*** for the environment, any files written there *are not removed* after the agent shuts down.

**Tip:** If you want more control over how files are persisted between agent sessions, use [***Artifacts***](/artifacts/) and the Artifact Service to upload and download files to the environment.

## Custom environments

The ***EnvironmentToolset*** architecture is designed to be extensible so you can build your own custom environments, including remote environments. We encourage you to build execution environments for use with this feature using the [BaseEnvironment](https://github.com/google/adk-python/blob/main/src/google/adk/environment/_base_environment.py) class. You can review the code for the [LocalEnvironment](https://github.com/google/adk-python/blob/main/src/google/adk/environment/_local_environment.py) implementation to help you get started.

# Google Cloud Agent Platform express mode for ADK

Supported in ADKPython v0.1.0Java v0.1.0Preview

Google Cloud Agent Platform express mode provides a no-cost access tier for prototyping and development, allowing you to use Agent Platform services without creating a full Google Cloud Project. This service includes access to many powerful Agent Platform services, including:

- [Agent Runtime SessionService](#agent-runtime-session-service)
- [Agent Runtime MemoryBankService](#memory-bank)

You can sign up for an express mode account using a Google account and receive an API key to use with the ADK. Obtain an API key through the [Google Cloud Console](https://console.cloud.google.com/expressmode). For more information, see [Agent Platform express mode](https://cloud.google.com/vertex-ai/generative-ai/docs/start/express-mode/overview).

Preview release

The Agent Platform express mode feature is a Preview release. For more information, see the [launch stage descriptions](https://cloud.google.com/products#product-launch-stages).

Agent Platform express mode limitations

Agent Platform express mode projects are only valid for 90 days and only select services are available to be used with limited quota. For example, the number of Agent Runtime instances are restricted to 10 and deployment to Agent Runtime requires paid access. To remove the quota restrictions and use all of Agent Platform's services, add a billing account to your express mode project.

## Configure Agent Runtime container

When using Agent Platform express mode, create an `AgentEngine` object to enable Agent Platform management of agent components such as `Session` and `Memory` objects. With this approach, `Session` objects are handled as children of the `AgentEngine` object. Before running your agent make sure your environment variables are set correctly, as shown below:

agent/.env

```text
GOOGLE_GENAI_USE_VERTEXAI=TRUE
GOOGLE_API_KEY=PASTE_YOUR_ACTUAL_EXPRESS_MODE_API_KEY_HERE
```

Next, create your Agent Runtime instance using the Agent Platform SDK.

1. Import Agent Platform SDK.

   ```py
   import vertexai
   from vertexai import agent_engines
   ```

1. Initialize the Agent Platform Client with your API key and create an agent engine instance.

   ```py
   # Create Agent Runtime with Gen AI SDK
   client = vertexai.Client(
     api_key="YOUR_API_KEY",
   )

   agent_engine = client.agent_engines.create(
     config={
       "display_name": "Demo Agent Runtime",
       "description": "Agent Runtime for Session and Memory",
     })
   ```

1. Get the Agent Runtime name and ID from the response to use with Memories and Sessions.

   ```py
   APP_ID = agent_engine.api_resource.name.split('/')[-1]
   ```

## Manage Sessions with `VertexAiSessionService`

[`VertexAiSessionService`](/sessions/session#sessionservice-implementations) is compatible with Agent Platform Express Mode API Keys. You can instead initialize the session object without any project or location.

```py
# Requires: pip install google-adk[vertexai]
# Plus environment variable setup:
# GOOGLE_GENAI_USE_VERTEXAI=TRUE
# GOOGLE_API_KEY=PASTE_YOUR_ACTUAL_EXPRESS_MODE_API_KEY_HERE
from google.adk.sessions import VertexAiSessionService

# The app_name used with this service should be the Reasoning Engine ID or name
APP_ID = "your-reasoning-engine-id"

# Project and location are not required when initializing with Agent Platform express mode
session_service = VertexAiSessionService(agent_engine_id=APP_ID)
# Use REASONING_ENGINE_APP_ID when calling service methods, e.g.:
# session = await session_service.create_session(app_name=APP_ID, user_id= ...)
```

Session Service Quotas

For Free express mode Projects, `VertexAiSessionService` has the following quota:

- 10 Create, delete, or update Agent Runtime sessions per minute
- 30 Append event to Agent Runtime sessions per minute

## Manage Memory with `VertexAiMemoryBankService`

[`VertexAiMemoryBankService`](/sessions/memory.md#memory-bank) is compatible with Agent Platform express mode API Keys. You can instead initialize the memory object without any project or location.

```py
# Requires: pip install google-adk[vertexai]
# Plus environment variable setup:
# GOOGLE_GENAI_USE_VERTEXAI=TRUE
# GOOGLE_API_KEY=PASTE_YOUR_ACTUAL_EXPRESS_MODE_API_KEY_HERE
from google.adk.memory import VertexAiMemoryBankService

# The app_name used with this service should be the Reasoning Engine ID or name
APP_ID = "your-reasoning-engine-id"

# Project and location are not required when initializing with express mode
memory_service = VertexAiMemoryBankService(agent_engine_id=APP_ID)
# Generate a memory from that session so the Agent can remember relevant details about the user
# memory = await memory_service.add_session_to_memory(session)
```

Memory Service Quotas

For Free express mode Projects, `VertexAiMemoryBankService` has the following quota:

- 10 Create, delete, or update Agent Runtime memory resources per minute
- 10 Get, list, or retrieve from Agent Runtime Memory Bank per minute

### Code Sample: Weather Agent with Session and Memory

This code sample shows a weather agent that utilizes both `VertexAiSessionService` and `VertexAiMemoryBankService` for context management, allowing your agent to recall user preferences and conversations.

- [Weather Agent with Session and Memory](https://github.com/google/adk-docs/blob/main/examples/python/notebooks/express-mode-weather-agent.ipynb) using Agent Platform express mode

# Session State Management using Firestore

Supported in ADKJava

[Google Cloud Firestore](https://cloud.google.com/firestore) is a flexible, scalable NoSQL cloud database to store and sync data for client- and server-side development. ADK provides a native integration for managing persistent agent session states using Firestore, allowing continuous multi-turn conversations without losing conversation history.

## Use cases

- **Customer Support Agents**: Maintain context across long-running support tickets, allowing the agent to remember past troubleshooting steps and preferences across multiple sessions.
- **Personalized Assistants**: Build agents that accumulate knowledge about the user over time, personalizing future interactions based on historical conversations.
- **Multi-modal Workflows**: Seamlessly handle complex use cases involving images, videos, and audio alongside text conversations, leveraging the built-in GCS artifact storage.
- **Enterprise Chatbots**: Deploy highly reliable, conversational AI applications with production-grade persistence suitable for large-scale enterprise environments.

## Prerequisites

- A [Google Cloud Project](https://cloud.google.com/) with Firestore enabled
- A [Firestore database](https://cloud.google.com/firestore/native/docs/create-database-server-client-library) in your Google Cloud Project
- Appropriate [Google Cloud credentials](https://cloud.google.com/docs/authentication/provide-credentials-adc) configured in your environment

## Install dependencies

Note

Ensure you use the same version for both `google-adk` and `google-adk-firestore-session-service` to guarantee compatibility.

Add the following dependencies to your `pom.xml` (Maven) or `build.gradle` (Gradle), replacing `1.2.0` with your target ADK version:

### Maven

```xml
<dependencies>
    <!-- ADK Core -->
    <dependency>
        <groupId>com.google.adk</groupId>
        <artifactId>google-adk</artifactId>
        <version>1.2.0</version>
    </dependency>
    <!-- Firestore Session Service -->
    <dependency>
        <groupId>com.google.adk</groupId>
        <artifactId>google-adk-firestore-session-service</artifactId>
        <version>1.2.0</version>
    </dependency>
</dependencies>
```

### Gradle

```text
dependencies {
    // ADK Core
    implementation 'com.google.adk:google-adk:1.2.0'
    // Firestore Session Service
    implementation 'com.google.adk:google-adk-firestore-session-service:1.2.0'
}
```

## Example: Agent with Firestore Session Management

Use `FirestoreDatabaseRunner` to encapsulate your agent and Firestore-backed session management. Here is a complete example of setting up a simple assistant agent that remembers conversation context across turns using a custom session ID.

```java
import com.google.adk.agents.BaseAgent;
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.RunConfig;
import com.google.adk.runner.FirestoreDatabaseRunner;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.FirestoreOptions;
import io.reactivex.rxjava3.core.Flowable;
import java.util.Map;
import com.google.adk.sessions.FirestoreSessionService;
import com.google.adk.sessions.Session;
import com.google.adk.tools.Annotations.Schema;
import com.google.adk.tools.FunctionTool;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import com.google.adk.events.Event;
import java.util.Scanner;
import static java.nio.charset.StandardCharsets.UTF_8;

public class YourAgentApplication {

    public static void main(String[] args) {
        System.out.println("Starting YourAgentApplication...");

        RunConfig runConfig = RunConfig.builder().build();
        String appName = "hello-time-agent";

        BaseAgent timeAgent = initAgent();

        // Initialize Firestore
        FirestoreOptions firestoreOptions = FirestoreOptions.getDefaultInstance();
        Firestore firestore = firestoreOptions.getService();

        // Use FirestoreDatabaseRunner to persist session state
        FirestoreDatabaseRunner runner = new FirestoreDatabaseRunner(
                timeAgent,
                appName,
                firestore
        );

        // Create a new session or load an existing one
        Session session = new FirestoreSessionService(firestore)
                .createSession(appName, "user1234", null, "12345")
                .blockingGet();

        // Start interactive CLI
        try (Scanner scanner = new Scanner(System.in, UTF_8)) {
            while (true) {
                System.out.print("\\nYou > ");
                String userInput = scanner.nextLine();
                if ("quit".equalsIgnoreCase(userInput)) {
                    break;
                }

                Content userMsg = Content.fromParts(Part.fromText(userInput));
                Flowable<Event> events = runner.runAsync(session.userId(), session.id(), userMsg, runConfig);

                System.out.print("\\nAgent > ");
                events.blockingForEach(event -> {
                    if (event.finalResponse()) {
                        System.out.println(event.stringifyContent());
                    }
                });
            }
        }
    }

    /** Mock tool implementation */
    @Schema(description = "Get the current time for a given city")
    public static Map<String, String> getCurrentTime(
        @Schema(name = "city", description = "Name of the city to get the time for") String city) {
        return Map.of(
            "city", city,
            "time", "The time is 10:30am."
        );
    }

    private static BaseAgent initAgent() {
        return LlmAgent.builder()
            .name("hello-time-agent")
            .description("Tells the current time in a specified city")
            .instruction(\"""
                You are a helpful assistant that tells the current time in a city.
                Use the 'getCurrentTime' tool for this purpose.
                \""")
            .model("gemini-flash-latest")
            .tools(FunctionTool.create(YourAgentApplication.class, "getCurrentTime"))
            .build();
    }
}
```

## Configuration

Note

The Firestore Session Service supports properties file configuration. This allows you to easily target a dedicated Firestore database and define custom collection names for storing your agent session data.

You can customize your ADK application to use the Firestore session service by providing your own Firestore property settings, otherwise the library will use the default settings.

### Environment-Specific Configuration

The library prioritizes environment-specific property files over the default settings using the following resolution order:

1. **Environment Variable Override**: It first checks for an environment variable named `env`. If this variable is set (e.g., `env=dev`), it will attempt to load a properties file matching the template: `adk-firestore-{env}.properties` (e.g., `adk-firestore-dev.properties`).
1. **Default Fallback**: If the `env` variable is not set, or the environment-specific file cannot be found, the library defaults to loading `adk-firestore.properties`.

Sample Property Settings:

```properties
# Firestore collection name for storing session data
firebase.root.collection.name=adk-session
# Google Cloud Storage bucket name for artifact storage
gcs.adk.bucket.name=your-gcs-bucket-name
# stop words for keyword extraction
keyword.extraction.stopwords=a,about,above,after,again,against,all,am,an,and,any,are,aren't,as,at,be,because,been,before,being,below,between,both,but,by,can't,cannot,could,couldn't,did,didn't,do,does,doesn't,doing,don't,down,during,each,few,for,from,further,had,hadn't,has,hasn't,have,haven't,having,he,he'd,he'll,he's,her,here,here's,hers,herself,him,himself,his,how,i,i'd,i'll,i'm,i've,if,in,into,is
```

Important

`FirestoreDatabaseRunner` requires the `gcs.adk.bucket.name` property to be defined. This is because the runner internally initializes the `GcsArtifactService` to handle multi-modal artifact storage. If this property is missing or empty, the application will throw a `RuntimeException` during startup. This is used for storing artifacts like images, videos, audio files, etc. that are generated or processed by the agent.

## Resources

- [Firestore Session Service](https://github.com/google/adk-java/tree/main/contrib/firestore-session-service): Source code for the Firestore Session Service.
- [Spring Boot Google ADK + Firestore Example](https://github.com/mohan-ganesh/spring-boot-google-adk-firestore): An example project demonstrating how to build a Java-based Google ADK agent application using Cloud Firestore for session management.
- [Firestore Session Service - DeepWiki](https://deepwiki.com/google/adk-java/4.3-firestore-session-service): Detailed description of Firestore integration in the Google ADK for Java.

# Freeplay observability for ADK

Supported in ADKPython

[Freeplay](https://freeplay.ai/) provides an end-to-end workflow for building and optimizing AI agents, and it can be integrated with ADK. With Freeplay your whole team can easily collaborate to iterate on agent instructions (prompts), experiment with and compare different models and agent changes, run evals both offline and online to measure quality, monitor production, and review data by hand.

Key benefits of Freeplay:

- **Simple observability** - focused on agents, LLM calls and tool calls for easy human review
- **Online evals/automated scorers** - for error detection in production
- **Offline evals and experiment comparison** - to test changes before deploying
- **Prompt management** - supports pushing changes straight from the Freeplay playground to code
- **Human review workflow** - for collaboration on error analysis and data annotation
- **Powerful UI** - makes it possible for domain experts to collaborate closely with engineers

Freeplay and ADK complement one another. ADK gives you a powerful and expressive agent orchestration framework while Freeplay plugs in for observability, prompt management, evaluation and testing. Once you integrate with Freeplay, you can update prompts and evals from the Freeplay UI or from code, so that anyone on your team can contribute.

## Getting Started

Below is a guide for getting started with Freeplay and ADK. You can also find a full sample ADK agent repo [here](https://github.com/228Labs/freeplay-google-demo).

### Create a Freeplay Account

Sign up for a free [Freeplay account](https://freeplay.ai/signup).

After creating an account, you can define the following environment variables:

```text
FREEPLAY_PROJECT_ID=
FREEPLAY_API_KEY=
FREEPLAY_API_URL=
```

### Use Freeplay ADK Library

Install the Freeplay ADK library:

```text
pip install freeplay-python-adk
```

Freeplay will automatically capture OTel logs from your ADK application when you initialize observability:

```python
from freeplay_python_adk.client import FreeplayADK
FreeplayADK.initialize_observability()
```

You'll also want to pass in the Freeplay plugin to your App:

```python
from app.agent import root_agent
from freeplay_python_adk.freeplay_observability_plugin import FreeplayObservabilityPlugin
from google.adk.runners import App

app = App(
    name="app",
    root_agent=root_agent,
    plugins=[FreeplayObservabilityPlugin()],
)

__all__ = ["app"]
```

You can now use ADK as you normally would, and you will see logs flowing to Freeplay in the Observability section.

## Observability

Freeplay's Observability feature gives you a clear view into how your agent is behaving in production. You can dig into individual agent traces to understand each step and diagnose issues:

You can also use Freeplay's filtering functionality to search and filter the data across any segment of interest:

## Prompt Management (optional)

Freeplay offers [native prompt management](https://docs.freeplay.ai/docs/managing-prompts), which simplifies the process of version and testing different prompt versions. It allows you to experiment with changes to ADK agent instructions in the Freeplay UI, test different models, and push updates straight to your code, similar to a feature flag.

To leverage Freeplay's prompt management capabilities alongside ADK, you'll want to use the Freeplay ADK agent wrapper. `FreeplayLLMAgent` extends ADK's base `LlmAgent` class, so instead of having to hard code your prompts as agent instructions, you can version prompts in the Freeplay application.

First define a prompt in Freeplay by going to Prompts -> Create prompt template:

When creating your prompt template you'll need to add 3 elements, as described in the following sections:

### System Message

This corresponds to the "instructions" section in your code.

### Agent Context Variable

Adding the following to the bottom of your system message will create a variable for the ongoing agent context to be passed through:

```python
{{agent_context}}
```

### History Block

Click new message and change the role to 'history'. This will ensure the past messages are passed through when present.

Now in your code you can use the `FreeplayLLMAgent`:

```python
from freeplay_python_adk.client import FreeplayADK
from freeplay_python_adk.freeplay_llm_agent import (
    FreeplayLLMAgent,
)

FreeplayADK.initialize_observability()

root_agent = FreeplayLLMAgent(
    name="social_product_researcher",
    tools=[tavily_search],
)
```

When the `social_product_researcher` is invoked, the prompt will be retrieved from Freeplay and formatted with the proper input variables.

## Evaluation

Freeplay enables you to define, version, and run [evaluations](https://docs.freeplay.ai/docs/evaluations) from the Freeplay web application. You can define evaluations for any of your prompts or agents by going to Evaluations -> "New evaluation".

These evaluations can be configured to run for both online monitoring and offline evaluation. Datasets for offline evaluation can be uploaded to Freeplay or saved from log examples.

## Dataset Management

As you get data flowing into Freeplay, you can use these logs to start building up [datasets](https://docs.freeplay.ai/docs/datasets) to test against on a repeated basis. Use production logs to create golden datasets or collections of failure cases that you can use to test against as you make changes.

## Batch Testing

As you iterate on your agent, you can run batch tests (i.e., offline experiments) at both the [prompt](https://docs.freeplay.ai/docs/component-level-test-runs) and [end-to-end](https://docs.freeplay.ai/docs/end-to-end-test-runs) agent level. This allows you to compare multiple different models or prompt changes and quantify changes head to head across your full agent execution.

[Here](https://github.com/freeplayai/freeplay-google-demo/blob/main/examples/example_test_run.py) is a code example for executing a batch test on Freeplay with ADK.

## Sign up now

Go to [Freeplay](https://freeplay.ai/) to sign up for an account, and check out a full Freeplay \<> ADK Integration [here](https://github.com/freeplayai/freeplay-google-demo/tree/main)

# Agent Observability and Evaluation with Galileo

[Galileo](https://app.galileo.ai/) is an AI evaluation and observability platform that delivers end-to-end tracing, evaluation, and monitoring for AI applications. Galileo supports direct OpenTelemetry (OTel) trace ingestion from ADK for agent runs, tool calls, and model requests.

For more information, see Galileo’s [Google ADK integration](https://v2docs.galileo.ai/sdk-api/third-party-integrations/opentelemetry-and-openinference/google-adk) docs.

## Prerequisites

- A [Galileo API key](https://v2docs.galileo.ai/references/faqs/find-keys#galileo-api-key)
- A Galileo Project and Log stream
- A [Gemini API Key](https://aistudio.google.com/app/apikey)

## Install dependencies

```bash
pip install google-adk openinference-instrumentation-google-adk python-dotenv galileo
```

Optionally, use the `requirements.txt` from the [completed example](https://github.com/rungalileo/sdk-examples/tree/main/python/agent/google-adk).

## Set environment variables

Configure environment variables:

my_agent/.env

```text
# Gemini environment variables
GOOGLE_GENAI_USE_VERTEXAI=0
GOOGLE_API_KEY="YOUR_API_KEY"

# Galileo environment variables
GALILEO_API_KEY="YOUR_API_KEY"
GALILEO_PROJECT="YOUR_PROJECT"
GALILEO_LOG_STREAM="YOUR_LOG_STREAM"
```

## Configure OpenTelemetry (required)

You must configure an OTLP exporter and set a global tracer provider before using any ADK components so that spans are emitted to Galileo.

```python
# my_agent/agent.py

from dotenv import load_dotenv

load_dotenv()

# OpenTelemetry imports
from opentelemetry.sdk import trace as trace_sdk

# Galileo span processor (auto-configures OTLP headers & endpoint from env vars)
from galileo import otel

# OpenInference instrumentation for ADK
from openinference.instrumentation.google_adk import GoogleADKInstrumentor

# Create tracer provider and register Galileo span processor
tracer_provider = trace_sdk.TracerProvider()
galileo_span_processor = otel.GalileoSpanProcessor()
tracer_provider.add_span_processor(galileo_span_processor)

# Instrument Google ADK with OpenInference (this captures inputs/outputs)
GoogleADKInstrumentor().instrument(tracer_provider=tracer_provider)
```

## Example: Trace an ADK agent

Now you can add the agent code for a simple current time agent, after the code that sets up the OTLP exporter and tracer provider:

```python
# my_agent/agent.py

from google.adk.agents import Agent

def get_current_time(city: str) -> dict:
    """Returns the current time in a specified city."""
    return {"status": "success", "city": city, "time": "10:30 AM"}


root_agent = Agent(
    model="gemini-flash-latest",
    name="root_agent",
    description="Tells the current time in a specified city.",
    instruction=(
        "You are a helpful assistant that tells the current time in cities. "
        "Use the 'get_current_time' tool for this purpose."
    ),
    tools=[get_current_time],
)
```

Run the agent with:

```bash
adk run my_agent
```

And ask it a question:

```console
What time is it in London?
```

```console
[root_agent]: The current time in London is 10:30 AM.
```

See the full [Google ADK + OpenTelemetry Example Project](https://github.com/rungalileo/sdk-examples/tree/main/python/agent/google-adk) for a completed example.

## View traces in Galileo

Select your Project and inspect the traces and spans in your Log Stream.

## Resources

- [Galileo Google ADK Integration Documentation](https://v2docs.galileo.ai/sdk-api/third-party-integrations/opentelemetry-and-openinference/google-adk): Official documentation for integrating a Google ADK project with Galileo using OpenTelemetry and OpenInference.
- [Google ADK + OpenTelemetry Example Project](https://github.com/rungalileo/sdk-examples/tree/main/python/agent/google-adk): This is an example project demonstrating how to use Galileo with the Google ADK. This example is a completed [Google ADK Python Quickstart](https://adk.dev/get-started/python/index.md) with Galileo instrumented on top.

# GitHub MCP tool for ADK

Supported in ADKPythonTypeScript

The [GitHub MCP Server](https://github.com/github/github-mcp-server) connects AI tools directly to GitHub's platform. This gives your ADK agent the ability to read repositories and code files, manage issues and PRs, analyze code, and automate workflows using natural language.

## Use cases

- **Repository Management**: Browse and query code, search files, analyze commits, and understand project structure across any repository you have access to.
- **Issue & PR Automation**: Create, update, and manage issues and pull requests. Let AI help triage bugs, review code changes, and maintain project boards.
- **Code Analysis**: Examine security findings, review Dependabot alerts, understand code patterns, and get comprehensive insights into your codebase.

## Prerequisites

- Create a [Personal Access Token](https://github.com/settings/personal-access-tokens/new) in GitHub. Refer to the [documentation](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens) for more information.

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams

GITHUB_TOKEN = "YOUR_GITHUB_TOKEN"

root_agent = Agent(
    model="gemini-flash-latest",
    name="github_agent",
    instruction="Help users get information from GitHub",
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url="https://api.githubcopilot.com/mcp/",
                headers={
                    "Authorization": f"Bearer {GITHUB_TOKEN}",
                    "X-MCP-Toolsets": "all",
                    "X-MCP-Readonly": "true"
                },
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const GITHUB_TOKEN = "YOUR_GITHUB_TOKEN";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "github_agent",
    instruction: "Help users get information from GitHub",
    tools: [
        new MCPToolset({
            type: "StreamableHTTPConnectionParams",
            url: "https://api.githubcopilot.com/mcp/",
            transportOptions: {
                requestInit: {
                    headers: {
                        Authorization: `Bearer ${GITHUB_TOKEN}`,
                        "X-MCP-Toolsets": "all",
                        "X-MCP-Readonly": "true",
                    },
                },
            },
        }),
    ],
});

export { rootAgent };
```

## Available tools

| Tool                         | Description                                                                               |
| ---------------------------- | ----------------------------------------------------------------------------------------- |
| `context`                    | Tools that provide context about the current user and GitHub context you are operating in |
| `copilot`                    | Copilot related tools (e.g. Copilot Coding Agent)                                         |
| `copilot_spaces`             | Copilot Spaces related tools                                                              |
| `actions`                    | GitHub Actions workflows and CI/CD operations                                             |
| `code_security`              | Code security related tools, such as GitHub Code Scanning                                 |
| `dependabot`                 | Dependabot tools                                                                          |
| `discussions`                | GitHub Discussions related tools                                                          |
| `experiments`                | Experimental features that are not considered stable yet                                  |
| `gists`                      | GitHub Gist related tools                                                                 |
| `github_support_docs_search` | Search docs to answer GitHub product and support questions                                |
| `issues`                     | GitHub Issues related tools                                                               |
| `labels`                     | GitHub Labels related tools                                                               |
| `notifications`              | GitHub Notifications related tools                                                        |
| `orgs`                       | GitHub Organization related tools                                                         |
| `projects`                   | GitHub Projects related tools                                                             |
| `pull_requests`              | GitHub Pull Request related tools                                                         |
| `repos`                      | GitHub Repository related tools                                                           |
| `secret_protection`          | Secret protection related tools, such as GitHub Secret Scanning                           |
| `security_advisories`        | Security advisories related tools                                                         |
| `stargazers`                 | GitHub Stargazers related tools                                                           |
| `users`                      | GitHub User related tools                                                                 |

## Configuration

The Remote GitHub MCP server has optional headers that can be used to configure available toolsets and read-only mode:

- `X-MCP-Toolsets`: Comma-separated list of toolsets to enable. (e.g., "repos,issues")

  - If the list is empty, default toolsets will be used. If a bad toolset is provided, the server will fail to start and emit a 400 bad request status. Whitespace is ignored.

- `X-MCP-Readonly`: Enables only "read" tools.

  - If this header is empty, "false", "f", "no", "n", "0", or "off" (ignoring whitespace and case), it will be interpreted as false. All other values are interpreted as true.

## Additional resources

- [GitHub MCP Server Repository](https://github.com/github/github-mcp-server)
- [Remote GitHub MCP Server Documentation](https://github.com/github/github-mcp-server/blob/main/docs/remote-server.md)
- [Policies and Governance for the GitHub MCP Server](https://github.com/github/github-mcp-server/blob/main/docs/policies-and-governance.md)

# GitLab MCP tool for ADK

Supported in ADKPythonTypeScript

The [GitLab MCP Server](https://docs.gitlab.com/user/gitlab_duo/model_context_protocol/mcp_server/) connects your ADK agent directly to [GitLab.com](https://gitlab.com/) or your self-managed GitLab instance. This integration gives your agent the ability to manage issues and merge requests, inspect CI/CD pipelines, perform semantic code searches, and automate development workflows using natural language.

## Use cases

- **Semantic Code Exploration**: Navigate your codebase using natural language. Unlike standard text search, you can query the logic and intent of your code to quickly understand complex implementations.
- **Accelerate Merge Request Reviews**: Get up to speed on code changes instantly. Retrieve full merge request contexts, analyze specific diffs, and review commit history to provide faster, more meaningful feedback to your team.
- **Troubleshoot CI/CD Pipelines**: Diagnose build failures without leaving your chat. Inspect pipeline statuses and retrieve detailed job logs to pinpoint exactly why a specific merge request or commit failed its checks.

## Prerequisites

- A GitLab account with a Premium or Ultimate subscription and [GitLab Duo](https://docs.gitlab.com/user/gitlab_duo/) enabled
- [Beta and experimental features](https://docs.gitlab.com/user/gitlab_duo/turn_on_off/#turn-on-beta-and-experimental-features) enabled in your GitLab settings

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

# Replace with your instance URL if self-hosted (e.g., "gitlab.example.com")
GITLAB_INSTANCE_URL = "gitlab.com"

root_agent = Agent(
    model="gemini-flash-latest",
    name="gitlab_agent",
    instruction="Help users get information from GitLab",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params = StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "mcp-remote",
                        f"https://{GITLAB_INSTANCE_URL}/api/v4/mcp",
                        "--static-oauth-client-metadata",
                        "{\"scope\": \"mcp\"}",
                    ],
                ),
                timeout=30,
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

// Replace with your instance URL if self-hosted (e.g., "gitlab.example.com")
const GITLAB_INSTANCE_URL = "gitlab.com";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "gitlab_agent",
    instruction: "Help users get information from GitLab",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: [
                    "-y",
                    "mcp-remote",
                    `https://${GITLAB_INSTANCE_URL}/api/v4/mcp`,
                    "--static-oauth-client-metadata",
                    '{"scope": "mcp"}',
                ],
            },
        }),
    ],
});

export { rootAgent };
```

Note

When you run this agent for the first time, a browser window will open automatically (and an authorization URL will be printed) requesting OAuth permissions. You must approve this request to allow the agent to access your GitLab data.

## Available tools

| Tool                          | Description                                                               |
| ----------------------------- | ------------------------------------------------------------------------- |
| `get_mcp_server_version`      | Returns the current version of the GitLab MCP server                      |
| `create_issue`                | Creates a new issue in a GitLab project                                   |
| `get_issue`                   | Retrieves detailed information about a specific GitLab issue              |
| `create_merge_request`        | Creates a merge request in a project                                      |
| `get_merge_request`           | Retrieves detailed information about a specific GitLab merge request      |
| `get_merge_request_commits`   | Retrieves the list of commits in a specific merge request                 |
| `get_merge_request_diffs`     | Retrieves the diffs for a specific merge request                          |
| `get_merge_request_pipelines` | Retrieves the pipelines for a specific merge request                      |
| `get_pipeline_jobs`           | Retrieves the jobs for a specific CI/CD pipeline                          |
| `gitlab_search`               | Searches for a term across the entire GitLab instance with the search API |
| `semantic_code_search`        | Searches for relevant code snippets in a project                          |

## Additional resources

- [GitLab MCP Server Documentation](https://docs.gitlab.com/user/gitlab_duo/model_context_protocol/mcp_server/)

# Google Cloud GKE Code Executor tool for ADK

Supported in ADKPython v1.14.0

The GKE Code Executor (`GkeCodeExecutor`) provides a secure and scalable method for running LLM-generated code by leveraging Google Kubernetes Engine (GKE). You should use this executor for production environments on GKE where security and isolation are critical. It supports two execution modes:

1. **Sandbox Mode (Recommended):** Utilizes the [Agent Sandbox](https://github.com/kubernetes-sigs/agent-sandbox) client to execute code within sandbox instances created on-demand from a template. This mode offers lower latency by using [pre-warmed sandboxes](https://docs.cloud.google.com/kubernetes-engine/docs/how-to/agent-sandbox#create_a_sandboxtemplate_and_sandboxwarmpool) and supports more direct interaction with the sandbox environment.
1. **Job Mode:** Uses the GKE Sandbox environment with gVisor for workload isolation. For each code execution request, it dynamically creates an ephemeral, sandboxed Kubernetes Job with a hardened Pod configuration. This mode is provided for backward compatibility.

## Execution Modes

### Sandbox Mode (`executor_type="sandbox"`)

This is the recommended mode. It uses the `k8s-agent-sandbox` client library to create and communicate with the Agent Sandbox in the GKE Cluster. When a request to execute code is made, it performs the following steps:

1. Creates a `SandboxClaim` using the specified template.
1. Waits for the sandbox instance to become ready.
1. Executes the code in the claimed sandbox.
1. Retrieves the standard output and error.
1. Deletes the `SandboxClaim`, which in turn cleans up the sandbox instance.

This approach is faster than the Job mode as it leverages pre-warmed sandboxes and optimizes startup time provided by the Agent Sandbox controller.

**Key Benefits:**

In addition to all the benefits of the Job mode, Sandbox mode also offers the following features:

- **Lower Latency:** Aims to reduce startup time compared to creating full Kubernetes Jobs.
- **Managed Environment:** Leverages the Agent Sandbox framework for sandbox lifecycle management.

**Prerequisites:**

- An existing Agent Sandbox deployment in your GKE cluster, including the sandbox controller and it's extensions (e.g., sandbox claim controller & sandbox warmpool controller), router, gateway and relevant `SandboxTemplate` resources (e.g., `python-sandbox-template`).
- The necessary RBAC permissions for the ADK agent to create and delete `SandboxClaim` resources.

### Job Mode (`executor_type="job"`)

This mode is provided for backward compatibility. When a request to execute code is made, the `GkeCodeExecutor` performs the following steps:

1. **Creates a ConfigMap:** A Kubernetes ConfigMap is created to store the Python code that needs to be executed.
1. **Creates a Sandboxed Pod:** A new Kubernetes Job is created, which in turn creates a Pod with a hardened security context and the gVisor runtime enabled. The code from the ConfigMap is mounted into this Pod.
1. **Executes the Code:** The code is executed within the sandboxed Pod, isolated from the underlying node and other workloads.
1. **Retrieves the Result:** The standard output and error streams from the execution are captured from the Pod's logs.
1. **Cleans Up Resources:** Once the execution is complete, the Job and the associated ConfigMap are automatically deleted, ensuring that no artifacts are left behind.

**Key Benefits:**

- **Enhanced Security:** Code is executed in a gVisor-sandboxed environment with kernel-level isolation.
- **Ephemeral Environments:** Each code execution runs in its own ephemeral Pod, to prevent state transfer between executions.
- **Resource Control:** You can configure CPU and memory limits for the execution Pods to prevent resource abuse.
- **Scalability:** Allows you to run a large number of code executions in parallel, with GKE handling the scheduling and scaling of the underlying nodes.
- **Minimal Setup:** Relies on standard GKE features and gVisor.

## System requirements

The following requirements must be met to successfully deploy your ADK project with the GKE Code Executor tool:

- GKE cluster with a **gVisor-enabled node pool** (required for both Job Mode's default image and typical Agent Sandbox templates).
- Agent's service account requires specific **RBAC permissions**:
  - **Job Mode:** Create, watch, and delete **Jobs**; Manage **ConfigMaps**; List **Pods** and read their **logs**. For a complete, ready-to-use configuration for Job Mode, see the [deployment_rbac.yaml](https://github.com/google/adk-python/blob/main/contributing/samples/gke_agent_sandbox/deployment_rbac.yaml) sample.
  - **Sandbox Mode:** Permissions to create, get, watch, and delete **SandboxClaim** and **Sandbox** resources within the namespace where the Agent Sandbox is deployed.
- Install the client library with the appropriate extras: `pip install google-adk[gke]`

## Configuration parameters

The `GkeCodeExecutor` can be configured with the following parameters:

| Parameter              | Type                        | Description                                                                                                           |
| ---------------------- | --------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| `namespace`            | `str`                       | Kubernetes namespace where the execution resources (Jobs or SandboxClaims) will be created. Defaults to `"default"`.  |
| `executor_type`        | `Literal["job", "sandbox"]` | Specifies the execution mode. Defaults to `"job"`.                                                                    |
| `image`                | `str`                       | (Job Mode) Container image to use for the execution Pod. Defaults to `"python:3.11-slim"`.                            |
| `timeout_seconds`      | `int`                       | (Job Mode) Timeout in seconds for the code execution. Defaults to `300`.                                              |
| `cpu_requested`        | `str`                       | (Job Mode) Amount of CPU to request for the execution Pod. Defaults to `"200m"`.                                      |
| `mem_requested`        | `str`                       | (Job Mode) Amount of memory to request for the execution Pod. Defaults to `"256Mi"`.                                  |
| `cpu_limit`            | `str`                       | (Job Mode) Maximum amount of CPU the execution Pod can use. Defaults to `"500m"`.                                     |
| `mem_limit`            | `str`                       | (Job Mode) Maximum amount of memory the execution Pod can use. Defaults to `"512Mi"`.                                 |
| `kubeconfig_path`      | `str`                       | Path to a kubeconfig file to use for authentication. Falls back to in-cluster config or the default local kubeconfig. |
| `kubeconfig_context`   | `str`                       | The `kubeconfig` context to use.                                                                                      |
| `sandbox_gateway_name` | `str \| None`               | (Sandbox Mode) The name of the sandbox gateway to use. Optional.                                                      |
| `sandbox_template`     | `str \| None`               | (Sandbox Mode) The name of the `SandboxTemplate` to use. Defaults to `"python-sandbox-template"`.                     |

## Usage Examples

```python
from google.adk.agents import LlmAgent
from google.adk.code_executors import GkeCodeExecutor
from google.adk.code_executors import CodeExecutionInput
from google.adk.agents.invocation_context import InvocationContext

# Initialize the executor for Sandbox Mode
# Namespace should have RBAC for SandboxClaims and Sandbox
gke_sandbox_executor = GkeCodeExecutor(
    namespace="agent-sandbox-system",  # Typically where agent-sandbox is installed
    executor_type="sandbox",
    sandbox_template="python-sandbox-template",
    sandbox_gateway_name="your-gateway-name", # Optional
)

# Example direct execution:
ctx = InvocationContext()
result = gke_sandbox_executor.execute_code(ctx, CodeExecutionInput(code="print('Hello from Sandbox Mode')"))
print(result.stdout)

# Example with an Agent:
gke_sandbox_agent = LlmAgent(
    name="gke_sandbox_coding_agent",
    model="gemini-flash-latest",
    instruction="You are a helpful AI agent that writes and executes Python code using sandboxes.",
    code_executor=gke_sandbox_executor,
)
```

```python
from google.adk.agents import LlmAgent
from google.adk.code_executors import GkeCodeExecutor
from google.adk.code_executors import CodeExecutionInput
from google.adk.agents.invocation_context import InvocationContext

# Initialize the executor for Job Mode
# Namespace should have RBAC for Jobs, ConfigMaps, Pods, Logs
gke_executor = GkeCodeExecutor(
    namespace="agent-ns",
    executor_type="job",
    timeout_seconds=600,
    cpu_limit="1000m",  # 1 CPU core
    mem_limit="1Gi",
)

# Example direct execution:
ctx = InvocationContext()
result = gke_executor.execute_code(ctx, CodeExecutionInput(code="print('Hello from Job Mode')"))
print(result.stdout)

# Example with an Agent:
gke_agent = LlmAgent(
    name="gke_coding_agent",
    model="gemini-flash-latest",
    instruction="You are a helpful AI agent that writes and executes Python code.",
    code_executor=gke_executor,
)
```

# GoodMem plugin for ADK

Supported in ADKPython

The [GoodMem ADK plugin](https://github.com/PAIR-Systems-Inc/goodmem-adk) connects your ADK agent to [GoodMem](https://goodmem.ai), a vector-based semantic memory service. This integration gives your agent persistent, searchable memory across conversations, enabling it to recall past interactions, user preferences, and uploaded documents.

There are two integration approaches:

| Approach                                          | Description                                                                                                                      |
| ------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| **Plugin** (`GoodmemPlugin`)                      | Implicit, deterministic memory at every turn via ADK callbacks. Saves all conversation turns and file attachments automatically. |
| **Tools** (`GoodmemSaveTool`, `GoodmemFetchTool`) | Explicit, agent-controlled memory. The agent decides when to save and retrieve information.                                      |

## Use cases

- **Persistent memory for agents**: Give your agents long-term memory that they can rely on across conversations.
- **Hands-free, multimodal memory management**: Automatically saves and retrieves information in conversations, including user messages, agent responses, and file attachments (PDF, DOCX, etc.).
- **Never start from scratch**: Agents recall who you are, what you've discussed, and solutions you've already worked through — saving tokens and avoiding redundant work.

## Prerequisites

- A [GoodMem](https://goodmem.ai/quick-start) instance (self-hosted or cloud)
- GoodMem API key
- [Gemini API key](https://aistudio.google.com/app/api-keys) (for auto-creating embeddings with Gemini)

## Installation

```bash
pip install goodmem-adk
```

## Use with agent

```python
import os
from google.adk.agents import LlmAgent
from google.adk.apps import App
from goodmem_adk import GoodmemPlugin

plugin = GoodmemPlugin(
    base_url=os.getenv("GOODMEM_BASE_URL"),  # e.g. "http://localhost:8080"
    api_key=os.getenv("GOODMEM_API_KEY"),
    top_k=5,  # Number of memories to retrieve per turn
)

agent = LlmAgent(
    name="memory_agent",
    model="gemini-flash-latest",
    instruction="You are a helpful assistant with persistent memory.",
)

app = App(name="GoodmemPluginDemo", root_agent=agent, plugins=[plugin])
```

```python
import os
from google.adk.agents import LlmAgent
from google.adk.apps import App
from goodmem_adk import GoodmemSaveTool, GoodmemFetchTool

save_tool = GoodmemSaveTool(
    base_url=os.getenv("GOODMEM_BASE_URL"),  # e.g. "http://localhost:8080"
    api_key=os.getenv("GOODMEM_API_KEY"),
)
fetch_tool = GoodmemFetchTool(
    base_url=os.getenv("GOODMEM_BASE_URL"),
    api_key=os.getenv("GOODMEM_API_KEY"),
    top_k=5,
)

agent = LlmAgent(
    name="memory_agent",
    model="gemini-flash-latest",
    instruction="You are a helpful assistant with persistent memory.",
    tools=[save_tool, fetch_tool],
)

app = App(name="GoodmemToolsDemo", root_agent=agent)
```

## Available tools

### Plugin callbacks

The `GoodmemPlugin` uses ADK callbacks to manage memory automatically:

| Callback                   | Description                                                  |
| -------------------------- | ------------------------------------------------------------ |
| `on_user_message_callback` | Saves user messages and file attachments to memory           |
| `before_model_callback`    | Retrieves relevant memories and injects them into the prompt |
| `after_model_callback`     | Saves the agent's response to memory                         |

These callbacks are deterministic and run during every agent interaction, saving all information passed through the agent to memory. The agent doesn't need to decide when to save or retrieve information.

### Tools

When using the tools approach, the agent has access to:

| Tool            | Description                                                 |
| --------------- | ----------------------------------------------------------- |
| `goodmem_save`  | Save text content and file attachments to persistent memory |
| `goodmem_fetch` | Search memories using semantic similarity queries           |

These tools are invoked by the agent on demand, and the agent can choose when to save (possibly with rewrites) or retrieve information based on the conversation context.

## Configuration

### Environment variables

| Variable              | Required | Description                                           |
| --------------------- | -------- | ----------------------------------------------------- |
| `GOODMEM_BASE_URL`    | Yes      | GoodMem server URL (without `/v1` suffix)             |
| `GOODMEM_API_KEY`     | Yes      | API key for GoodMem                                   |
| `GOOGLE_API_KEY`      | Yes      | Gemini API key for auto-creating Gemini embedder      |
| `GOODMEM_EMBEDDER_ID` | No       | Pin a specific embedder (must exist)                  |
| `GOODMEM_SPACE_ID`    | No       | Pin a specific memory space (must exist)              |
| `GOODMEM_SPACE_NAME`  | No       | Override default space name (auto-created if missing) |

### Space resolution

If no space is configured, one is auto-created per user:

- Plugin: `adk_chat_{user_id}`
- Tools: `adk_tool_{user_id}`

## Additional resources

- [GoodMem ADK on GitHub](https://github.com/PAIR-Systems-Inc/goodmem-adk)
- [GoodMem Documentation](https://goodmem.ai)
- [GoodMem ADK on PyPI](https://pypi.org/project/goodmem-adk/)

# Google Developer Knowledge MCP tool for ADK

Supported in ADKPythonTypeScript

The [Google Developer Knowledge MCP server](https://developers.google.com/knowledge/mcp) provides programmatic access to Google's public developer documentation, enabling you to integrate this knowledge base into your own applications and workflows. By connecting your ADK agent to Google's official library of documentation, it ensures the code and guidance you receive are up-to-date and based on authoritative context.

## Use cases

- **Implementation guidance**: Ask for the best way to implement specific features (e.g., push notifications using Firebase Cloud Messaging).
- **Code generation and explanation**: Search documentation for code examples, such as listing all buckets in a Cloud Storage project in Python.
- **Troubleshooting and debugging**: Query error messages or API key watermarks to quickly resolve issues.
- **Comparative analysis and summarization**: Create comparisons between services like Cloud Run and Cloud Functions.

## Prerequisites

- A [Google Cloud project](https://developers.google.com/workspace/guides/create-project)
- [Developer Knowledge API enabled](https://console.cloud.google.com/start/api?id=developerknowledge.googleapis.com)
- Completed [Authentication Configuration](https://developers.google.com/knowledge/mcp#authentication) (OAuth or API Key)

## Installation

You must enable the Developer Knowledge MCP server in your Google Cloud Project. Please refer to the official [Installation Guide](https://developers.google.com/knowledge/mcp#installation) for the precise `gcloud` command and instructions.

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams

DEVELOPER_KNOWLEDGE_API_KEY = "YOUR_DEVELOPER_KNOWLEDGE_API_KEY"

root_agent = Agent(
    model="gemini-flash-latest",
    name="google_knowledge_agent",
    instruction="Search Google developer documentation for implementation guidance.",
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url="https://developerknowledge.googleapis.com/mcp",
                headers={"X-Goog-Api-Key": DEVELOPER_KNOWLEDGE_API_KEY},
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const DEVELOPER_KNOWLEDGE_API_KEY = "YOUR_DEVELOPER_KNOWLEDGE_API_KEY";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "google_knowledge_agent",
    instruction: "Search Google developer documentation for implementation guidance.",
    tools: [
        new MCPToolset({
            type: "StreamableHTTPConnectionParams",
            url: "https://developerknowledge.googleapis.com/mcp",
            transportOptions: {
                requestInit: {
                    headers: {
                        "X-Goog-Api-Key": DEVELOPER_KNOWLEDGE_API_KEY,
                    },
                },
            },
        }),
    ],
});

export { rootAgent };
```

## Available tools

| Tool name          | Description                                                                                          |
| ------------------ | ---------------------------------------------------------------------------------------------------- |
| `search_documents` | Searches Google's developer documentation to find relevant pages and snippets for your query         |
| `get_documents`    | Retrieves the full page content of multiple documents using the parent reference from search results |

## Additional resources

- [Developer Knowledge MCP Documentation](https://developers.google.com/knowledge/mcp)
- [Developer Knowledge API Reference](https://developers.google.com/knowledge/api)
- [Corpus Reference](https://developers.google.com/knowledge/reference/corpus-reference)

# Gemini API Google Search tool for ADK

Supported in ADKPython v0.1.0TypeScript v0.2.0Go v0.1.0Java v0.2.0

The `google_search` tool allows the agent to perform web searches using Google Search. The `google_search` tool is only compatible with Gemini 2 models. For further details of the tool, see [Understanding Google Search grounding](/grounding/google_search_grounding/).

Additional requirements when using the `google_search` tool

When you use grounding with Google Search, and you receive Search suggestions in your response, you must display the Search suggestions in production and in your applications. For more information on grounding with Google Search, see Grounding with Google Search documentation for [Google AI Studio](https://ai.google.dev/gemini-api/docs/grounding/search-suggestions) or [Agent Platform](https://cloud.google.com/vertex-ai/generative-ai/docs/grounding/grounding-search-suggestions). The UI code (HTML) is returned in the Gemini response as `renderedContent`, and you will need to show the HTML in your app, in accordance with the policy.

Warning: Single tool per agent limitation

This tool can only be used ***by itself*** within an agent instance. For more information about this limitation and workarounds, see [Limitations for ADK tools](/tools/limitations/#one-tool-one-agent).

```py
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

from google.adk.agents import Agent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.tools import google_search
from google.genai import types

APP_NAME="google_search_agent"
USER_ID="user1234"
SESSION_ID="1234"


root_agent = Agent(
    name="basic_search_agent",
    model="gemini-2.0-flash",
    description="Agent to answer questions using Google Search.",
    instruction="I can answer your questions by searching the internet. Just ask me anything!",
    # google_search is a pre-built tool which allows the agent to perform Google searches.
    tools=[google_search]
)

# Session and Runner
async def setup_session_and_runner():
    session_service = InMemorySessionService()
    session = await session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID)
    runner = Runner(agent=root_agent, app_name=APP_NAME, session_service=session_service)
    return session, runner

# Agent Interaction
async def call_agent_async(query):
    content = types.Content(role='user', parts=[types.Part(text=query)])
    session, runner = await setup_session_and_runner()
    events = runner.run_async(user_id=USER_ID, session_id=SESSION_ID, new_message=content)

    async for event in events:
        if event.is_final_response():
            final_response = event.content.parts[0].text
            print("Agent Response: ", final_response)

# Note: In Colab, you can directly use 'await' at the top level.
# If running this code as a standalone Python script, you'll need to use asyncio.run() or manage the event loop.
await call_agent_async("what's the latest ai news?")
```

```typescript
import {GOOGLE_SEARCH, LlmAgent} from '@google/adk';

export const rootAgent = new LlmAgent({
  model: 'gemini-flash-latest',
  name: 'root_agent',
  description:
      'an agent whose job it is to perform Google search queries and answer questions about the results.',
  instruction:
      'You are an agent whose job is to perform Google search queries and answer questions about the results.',
  tools: [GOOGLE_SEARCH],
});
```

```go
// Copyright 2025 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package main

import (
    "context"
    "fmt"
    "log"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/runner"
    "google.golang.org/adk/session"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/geminitool"
    "google.golang.org/genai"
)

func createSearchAgent(ctx context.Context) (agent.Agent, error) {
    model, err := gemini.NewModel(ctx, "gemini-2.5-flash", &genai.ClientConfig{})
    if err != nil {
        return nil, fmt.Errorf("failed to create model: %v", err)
    }

    return llmagent.New(llmagent.Config{
        Name:        "basic_search_agent",
        Model:       model,
        Description: "Agent to answer questions using Google Search.",
        Instruction: "I can answer your questions by searching the web. Just ask me anything!",
        Tools:       []tool.Tool{geminitool.GoogleSearch{}},
    })
}

const (
    userID  = "user1234"
    appName = "Google Search_agent"
)

func callAgent(ctx context.Context, a agent.Agent, prompt string) error {
    sessionService := session.InMemoryService()
    session, err := sessionService.Create(ctx, &session.CreateRequest{
        AppName: appName,
        UserID:  userID,
    })
    if err != nil {
        return fmt.Errorf("failed to create the session service: %v", err)
    }

    config := runner.Config{
        AppName:        appName,
        Agent:          a,
        SessionService: sessionService,
    }
    r, err := runner.New(config)
    if err != nil {
        return fmt.Errorf("failed to create the runner: %v", err)
    }

    sessionID := session.Session.ID()
    userMsg := &genai.Content{
        Parts: []*genai.Part{{Text: prompt}},
        Role:  string(genai.RoleUser),
    }

    // The r.Run method streams events and errors.
    // The loop iterates over the results, handling them as they arrive.
    for event, err := range r.Run(ctx, userID, sessionID, userMsg, agent.RunConfig{
        StreamingMode: agent.StreamingModeSSE,
    }) {
        if err != nil {
            fmt.Printf("\nAGENT_ERROR: %v\n", err)
        } else if event.Partial {
            for _, p := range event.LLMResponse.Content.Parts {
                fmt.Print(p.Text)
            }
        }
    }
    return nil
}

func main() {
    agent, err := createSearchAgent(context.Background())
    if err != nil {
        log.Fatalf("Failed to create agent: %v", err)
    }
    fmt.Println("Agent created:", agent.Name())
    prompt := "what's the latest ai news?"
    fmt.Printf("\nPrompt: %s\nResponse: ", prompt)
    if err := callAgent(context.Background(), agent, prompt); err != nil {
        log.Fatalf("Error calling agent: %v", err)
    }
    fmt.Println("\n---")
}
```

```java
import com.google.adk.agents.BaseAgent;
import com.google.adk.agents.LlmAgent;
import com.google.adk.runner.Runner;
import com.google.adk.sessions.InMemorySessionService;
import com.google.adk.sessions.Session;
import com.google.adk.tools.GoogleSearchTool;
import com.google.common.collect.ImmutableList;
import com.google.genai.types.Content;
import com.google.genai.types.Part;

public class GoogleSearchAgentApp {

  private static final String APP_NAME = "Google Search_agent";
  private static final String USER_ID = "user1234";
  private static final String SESSION_ID = "1234";

  /**
   * Calls the agent with the given query and prints the final response.
   *
   * @param runner The runner to use.
   * @param query The query to send to the agent.
   */
  public static void callAgent(Runner runner, String query) {
    Content content =
        Content.fromParts(Part.fromText(query));

    InMemorySessionService sessionService = (InMemorySessionService) runner.sessionService();
    Session session =
        sessionService
            .createSession(APP_NAME, USER_ID, /* state= */ null, SESSION_ID)
            .blockingGet();

    runner
        .runAsync(session.userId(), session.id(), content)
        .forEach(
            event -> {
              if (event.finalResponse()
                  && event.content().isPresent()
                  && event.content().get().parts().isPresent()
                  && !event.content().get().parts().get().isEmpty()
                  && event.content().get().parts().get().get(0).text().isPresent()) {
                String finalResponse = event.content().get().parts().get().get(0).text().get();
                System.out.println("Agent Response: " + finalResponse);
              }
            });
  }

  public static void main(String[] args) {
    // Google Search is a pre-built tool which allows the agent to perform Google searches.
    GoogleSearchTool googleSearchTool = new GoogleSearchTool();

    BaseAgent rootAgent =
        LlmAgent.builder()
            .name("basic_search_agent")
            .model("gemini-2.0-flash") // Ensure to use a Gemini 2.0 model for Google Search Tool
            .description("Agent to answer questions using Google Search.")
            .instruction(
                "I can answer your questions by searching the internet. Just ask me anything!")
            .tools(ImmutableList.of(googleSearchTool))
            .build();

    // Session and Runner
    InMemorySessionService sessionService = new InMemorySessionService();
    Runner runner = new Runner(rootAgent, APP_NAME, null, sessionService);

    // Agent Interaction
    callAgent(runner, "what's the latest ai news?");
  }
}
```

# Hugging Face MCP tool for ADK

Supported in ADKPythonTypeScript

The [Hugging Face MCP Server](https://github.com/huggingface/hf-mcp-server) can be used to connect your ADK agent to the Hugging Face Hub and thousands of Gradio AI Applications.

## Use cases

- **Discover AI/ML Assets**: Search and filter the Hub for models, datasets, and papers based on tasks, libraries, or keywords.
- **Build Multi-Step Workflows**: Chain tools together, such as transcribing audio with one tool and then summarizing the resulting text with another.
- **Find AI Applications**: Search for Gradio Spaces that can perform a specific task, like background removal or text-to-speech.

## Prerequisites

- Create a [user access token](https://huggingface.co/settings/tokens) in Hugging Face. Refer to the [documentation](https://huggingface.co/docs/hub/en/security-tokens) for more information.

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

HUGGING_FACE_TOKEN = "YOUR_HUGGING_FACE_TOKEN"

root_agent = Agent(
    model="gemini-flash-latest",
    name="hugging_face_agent",
    instruction="Help users get information from Hugging Face",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params = StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "@llmindset/hf-mcp-server",
                    ],
                    env={
                        "HF_TOKEN": HUGGING_FACE_TOKEN,
                    }
                ),
                timeout=30,
            ),
        )
    ],
)
```

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams

HUGGING_FACE_TOKEN = "YOUR_HUGGING_FACE_TOKEN"

root_agent = Agent(
    model="gemini-flash-latest",
    name="hugging_face_agent",
    instruction="Help users get information from Hugging Face",
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url="https://huggingface.co/mcp",
                headers={
                    "Authorization": f"Bearer {HUGGING_FACE_TOKEN}",
                },
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const HUGGING_FACE_TOKEN = "YOUR_HUGGING_FACE_TOKEN";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "hugging_face_agent",
    instruction: "Help users get information from Hugging Face",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: ["-y", "@llmindset/hf-mcp-server"],
                env: {
                    HF_TOKEN: HUGGING_FACE_TOKEN,
                },
            },
        }),
    ],
});

export { rootAgent };
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const HUGGING_FACE_TOKEN = "YOUR_HUGGING_FACE_TOKEN";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "hugging_face_agent",
    instruction: "Help users get information from Hugging Face",
    tools: [
        new MCPToolset({
            type: "StreamableHTTPConnectionParams",
            url: "https://huggingface.co/mcp",
            transportOptions: {
                requestInit: {
                    headers: {
                        Authorization: `Bearer ${HUGGING_FACE_TOKEN}`,
                    },
                },
            },
        }),
    ],
});

export { rootAgent };
```

## Available tools

| Tool                          | Description                                                |
| ----------------------------- | ---------------------------------------------------------- |
| Spaces Semantic Search        | Find the best AI Apps via natural language queries         |
| Papers Semantic Search        | Find ML Research Papers via natural language queries       |
| Model Search                  | Search for ML models with filters for task, library, etc…  |
| Dataset Search                | Search for datasets with filters for author, tags, etc…    |
| Documentation Semantic Search | Search the Hugging Face documentation library              |
| Hub Repository Details        | Get detailed information about Models, Datasets and Spaces |

## Configuration

To configure which tools are available in your Hugging Face Hub MCP server, visit the [MCP Settings Page](https://huggingface.co/settings/mcp) in your Hugging Face account.

To configure the local MCP server, you can use the following environment variables:

- `TRANSPORT`: The transport type to use (`stdio`, `sse`, `streamableHttp`, or `streamableHttpJson`)
- `DEFAULT_HF_TOKEN`: ⚠️ Requests are serviced with the `HF_TOKEN` received in the Authorization: Bearer header. The DEFAULT_HF_TOKEN is used if no header was sent. Only set this in Development / Test environments or for local STDIO Deployments. ⚠️
- If running with stdio transport, `HF_TOKEN` is used if `DEFAULT_HF_TOKEN` is not set.
- `HF_API_TIMEOUT`: Timeout for Hugging Face API requests in milliseconds (default: 12500ms / 12.5 seconds)
- `USER_CONFIG_API`: URL to use for User settings (defaults to Local front-end)
- `MCP_STRICT_COMPLIANCE`: set to True for GET 405 rejects in JSON Mode (default serves a welcome page).
- `AUTHENTICATE_TOOL`: whether to include an Authenticate tool to issue an OAuth challenge when called
- `SEARCH_ENABLES_FETCH`: When set to true, automatically enables the hf_doc_fetch tool whenever hf_doc_search is enabled

## Additional resources

- [Hugging Face MCP Server Repository](https://github.com/huggingface/hf-mcp-server)
- [Hugging Face MCP Server Documentation](https://huggingface.co/docs/hub/en/hf-mcp-server)

# Knowledge Engine tool for ADK

Supported in ADKPython v0.1.0Java v0.2.0

The `vertex_ai_rag_retrieval` tool allows the agent to perform private data retrieval using Knowledge Engine.

When you use grounding with Knowledge Engine, you need to prepare a RAG corpus beforehand. Please refer to the [RAG ADK agent sample](https://github.com/google/adk-samples/blob/main/python/agents/RAG/rag/shared_libraries/prepare_corpus_and_data.py) or [Knowledge Engine page](https://cloud.google.com/vertex-ai/generative-ai/docs/rag-engine/rag-quickstart) for setting it up.

Warning: Single tool per agent limitation

This tool can only be used ***by itself*** within an agent instance. For more information about this limitation and workarounds, see [Limitations for ADK tools](/tools/limitations/).

```py
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os

from google.adk.agents import Agent
from google.adk.tools.retrieval.vertex_ai_rag_retrieval import VertexAiRagRetrieval
from vertexai.preview import rag

from dotenv import load_dotenv
from .prompts import return_instructions_root

load_dotenv()

ask_vertex_retrieval = VertexAiRagRetrieval(
    name="retrieve_rag_documentation",
    description=(
        "Use this tool to retrieve documentation and reference materials for the question from the RAG corpus,"
    ),
    rag_resources=[
        rag.RagResource(
            # please fill in your own rag corpus
            # here is a sample rag corpus for testing purpose
            # e.g. projects/123/locations/us-central1/ragCorpora/456
            rag_corpus=os.environ.get("RAG_CORPUS")
        )
    ],
    similarity_top_k=10,
    vector_distance_threshold=0.6,
)

root_agent = Agent(
    model="gemini-2.0-flash-001",
    name="ask_rag_agent",
    instruction=return_instructions_root(),
    tools=[
        ask_vertex_retrieval,
    ],
)
```

# LangWatch observability for ADK

Supported in ADKPython

[LangWatch](https://langwatch.ai) is an open-source LLMOps platform for observability, evaluation, and prompt optimization. It provides comprehensive tracing for ADK agents using [OpenInference instrumentation](https://github.com/Arize-ai/openinference/tree/main/python/instrumentation/openinference-instrumentation-google-adk), allowing you to monitor, debug, and improve your agents in development and production.

## Overview

LangWatch captures traces from ADK using its built-in OpenTelemetry support, giving you:

- **Automatic tracing** - Capture every agent run, tool call, and model request with full context
- **Online evaluation** - Continuously score production traffic for quality and safety
- **Guardrails** - Block or modify harmful responses in real-time
- **Prompt management** - Version, test, and optimize prompts with built-in A/B testing
- **Datasets and experiments** - Build evaluation sets from real traces and run batch experiments

## Installation

Install the required packages:

```bash
pip install langwatch openinference-instrumentation-google-adk google-adk
```

## Setup

Sign up at [langwatch.ai](https://langwatch.ai) or [self-host](https://langwatch.ai/docs/self-hosting/overview) the platform, then set your API key:

```bash
export LANGWATCH_API_KEY="your-langwatch-api-key"
export GOOGLE_API_KEY="your-gemini-api-key"
```

Initialize tracing:

```python
import langwatch
from openinference.instrumentation.google_adk import GoogleADKInstrumentor

langwatch.setup(
    instrumentors=[GoogleADKInstrumentor()]
)
```

That's it. All ADK agent activity will now be traced and sent to your LangWatch dashboard automatically.

## Observe

With tracing initialized, run your ADK agent as usual and all interactions will appear in LangWatch:

```python
import langwatch
from google.adk.agents import Agent
from google.adk.runners import InMemoryRunner
from google.genai import types
from openinference.instrumentation.google_adk import GoogleADKInstrumentor

langwatch.setup(
    instrumentors=[GoogleADKInstrumentor()]
)

# Define a tool
def get_weather(city: str) -> dict:
    """Retrieves the current weather report for a specified city.

    Args:
        city (str): The name of the city.

    Returns:
        dict: status and result or error msg.
    """
    if city.lower() == "new york":
        return {
            "status": "success",
            "report": (
                "The weather in New York is sunny with a temperature of 25 degrees"
                " Celsius (77 degrees Fahrenheit)."
            ),
        }
    else:
        return {
            "status": "error",
            "error_message": f"Weather information for '{city}' is not available.",
        }

# Create an agent with tools
agent = Agent(
    name="weather_agent",
    model="gemini-flash-latest",
    description="Agent to answer questions about the weather.",
    instruction="You must use the available tools to find an answer.",
    tools=[get_weather],
)

app_name = "weather_app"
user_id = "test_user"
session_id = "test_session"
runner = InMemoryRunner(agent=agent, app_name=app_name)
session_service = runner.session_service

await session_service.create_session(
    app_name=app_name,
    user_id=user_id,
    session_id=session_id,
)

# Run the agent — all interactions will be traced
async for event in runner.run_async(
    user_id=user_id,
    session_id=session_id,
    new_message=types.Content(
        role="user",
        parts=[types.Part(text="What is the weather in New York?")],
    ),
):
    if event.is_final_response():
        print(event.content.parts[0].text.strip())
```

## Adding Custom Metadata

Use the `@langwatch.trace()` decorator to attach additional context to your traces:

```python
@langwatch.trace(name="ADK Weather Agent")
def run_agent(user_message: str):
    current_trace = langwatch.get_current_trace()
    if current_trace:
        current_trace.update(
            metadata={
                "user_id": "user_123",
                "agent_name": "weather_agent",
                "environment": "production",
            }
        )

    user_msg = types.Content(
        role="user", parts=[types.Part(text=user_message)]
    )
    for event in runner.run(
        user_id="demo-user",
        session_id="demo-session",
        new_message=user_msg,
    ):
        if event.is_final_response():
            return event.content.parts[0].text

    return "No response generated"
```

## Support and Resources

- [LangWatch Documentation](https://langwatch.ai/docs)
- [ADK Integration Guide](https://langwatch.ai/docs/integration/python/integrations/google-ai)
- [LangWatch Repository on GitHub](https://github.com/langwatch/langwatch)
- [Community Discord](https://discord.gg/langwatch)

# Linear MCP tool for ADK

Supported in ADKPythonTypeScript

The [Linear MCP Server](https://linear.app/docs/mcp) connects your ADK agent to [Linear](https://linear.app/), a purpose-built tool for planning and building products. This integration gives your agent the ability to manage issues, track project cycles, and automate development workflows using natural language.

## Use cases

- **Streamline Issue Management**: Create, update, and organize issues using natural language. Let your agent handle logging bugs, assigning tasks, and updating statuses.
- **Track Projects and Cycles**: Get instant visibility into your team's momentum. Query the status of active cycles, check project milestones, and retrieve deadlines.
- **Contextual Search & Summarization**: Quickly catch up on long discussion threads or find specific project specifications. Your agent can search documentation and summarize complex issues.

## Prerequisites

- [Sign up](https://linear.app/signup) for a Linear account
- Generate an API key in [Linear Settings > Security & access](https://linear.app/docs/security-and-access) (if using API authentication)

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

root_agent = Agent(
    model="gemini-flash-latest",
    name="linear_agent",
    instruction="Help users manage issues, projects, and cycles in Linear",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "mcp-remote",
                        "https://mcp.linear.app/mcp",
                    ]
                ),
                timeout=30,
            ),
        )
    ],
)
```

Note

When you run this agent for the first time, a browser window will open automatically to request access via OAuth. Alternatively, you can use the authorization URL printed in the console. You must approve this request to allow the agent to access your Linear data.

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams

LINEAR_API_KEY = "YOUR_LINEAR_API_KEY"

root_agent = Agent(
    model="gemini-flash-latest",
    name="linear_agent",
    instruction="Help users manage issues, projects, and cycles in Linear",
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url="https://mcp.linear.app/mcp",
                headers={
                    "Authorization": f"Bearer {LINEAR_API_KEY}",
                },
            ),
        )
    ],
)
```

Note

This code example uses an API key for authentication. To use a browser-based OAuth authentication flow instead, remove the `headers` parameter and run the agent.

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "linear_agent",
    instruction: "Help users manage issues, projects, and cycles in Linear",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: ["-y", "mcp-remote", "https://mcp.linear.app/mcp"],
            },
        }),
    ],
});

export { rootAgent };
```

Note

When you run this agent for the first time, a browser window will open automatically to request access via OAuth. Alternatively, you can use the authorization URL printed in the console. You must approve this request to allow the agent to access your Linear data.

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const LINEAR_API_KEY = "YOUR_LINEAR_API_KEY";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "linear_agent",
    instruction: "Help users manage issues, projects, and cycles in Linear",
    tools: [
        new MCPToolset({
            type: "StreamableHTTPConnectionParams",
            url: "https://mcp.linear.app/mcp",
            transportOptions: {
                requestInit: {
                    headers: {
                        Authorization: `Bearer ${LINEAR_API_KEY}`,
                    },
                },
            },
        }),
    ],
});

export { rootAgent };
```

Note

This code example uses an API key for authentication. To use a browser-based OAuth authentication flow instead, remove the `header` property and run the agent.

## Available tools

| Tool                   | Description                  |
| ---------------------- | ---------------------------- |
| `list_comments`        | List comments on an issue    |
| `create_comment`       | Create a comment on an issue |
| `list_cycles`          | List cycles in a project     |
| `get_document`         | Get a document               |
| `list_documents`       | List documents               |
| `get_issue`            | Get an issue                 |
| `list_issues`          | List issues                  |
| `create_issue`         | Create an issue              |
| `update_issue`         | Update an issue              |
| `list_issue_statuses`  | List issue statuses          |
| `get_issue_status`     | Get an issue status          |
| `list_issue_labels`    | List issue labels            |
| `create_issue_label`   | Create an issue label        |
| `list_projects`        | List projects                |
| `get_project`          | Get a project                |
| `create_project`       | Create a project             |
| `update_project`       | Update a project             |
| `list_project_labels`  | List project labels          |
| `list_teams`           | List teams                   |
| `get_team`             | Get a team                   |
| `list_users`           | List users                   |
| `get_user`             | Get a user                   |
| `search_documentation` | Search documentation         |

## Additional resources

- [Linear MCP Server Documentation](https://linear.app/docs/mcp)
- [Linear Getting Started Guide](https://linear.app/docs/start-guide)

# Mailgun MCP tool for ADK

Supported in ADKPythonTypeScript

The [Mailgun MCP Server](https://github.com/mailgun/mailgun-mcp-server) connects your ADK agent to [Mailgun](https://www.mailgun.com/), a transactional email service. This integration gives your agent the ability to send emails, track delivery metrics, manage domains and templates, and handle mailing lists using natural language.

## Use cases

- **Send and Manage Emails**: Compose and send transactional or marketing emails, retrieve stored messages, and resend messages through conversational commands.
- **Monitor Delivery Performance**: Fetch delivery statistics, analyze bounce classifications, and review suppression lists to maintain sender reputation.
- **Manage Email Infrastructure**: Verify domain DNS configuration, configure tracking settings, create email templates, and set up inbound routing rules.

## Prerequisites

- Create a [Mailgun account](https://www.mailgun.com/)
- Generate an API key from the [Mailgun Dashboard](https://app.mailgun.com/settings/api_security)

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

MAILGUN_API_KEY = "YOUR_MAILGUN_API_KEY"

root_agent = Agent(
    model="gemini-flash-latest",
    name="mailgun_agent",
    instruction="Help users send emails and manage their Mailgun account",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "@mailgun/mcp-server",
                    ],
                    env={
                        "MAILGUN_API_KEY": MAILGUN_API_KEY,
                        # "MAILGUN_API_REGION": "eu",  # Optional: defaults to "us"
                    }
                ),
                timeout=30,
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const MAILGUN_API_KEY = "YOUR_MAILGUN_API_KEY";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "mailgun_agent",
    instruction: "Help users send emails and manage their Mailgun account",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: ["-y", "@mailgun/mcp-server"],
                env: {
                    MAILGUN_API_KEY: MAILGUN_API_KEY,
                    // MAILGUN_API_REGION: "eu",  // Optional: defaults to "us"
                },
            },
        }),
    ],
});

export { rootAgent };
```

## Available tools

### Messaging

| Tool                 | Description                                                 |
| -------------------- | ----------------------------------------------------------- |
| `send_email`         | Send an email with support for HTML content and attachments |
| `get_stored_message` | Retrieve a stored email message                             |
| `resend_message`     | Resend a previously sent message                            |

### Domains

| Tool                       | Description                                       |
| -------------------------- | ------------------------------------------------- |
| `get_domain`               | View details for a specific domain                |
| `verify_domain`            | Verify DNS configuration for a domain             |
| `get_tracking_settings`    | View tracking settings (click, open, unsubscribe) |
| `update_tracking_settings` | Update tracking settings for a domain             |

### Webhooks

| Tool             | Description                          |
| ---------------- | ------------------------------------ |
| `list_webhooks`  | List all event webhooks for a domain |
| `create_webhook` | Create a new event webhook           |
| `update_webhook` | Update an existing webhook           |
| `delete_webhook` | Delete a webhook                     |

### Routes

| Tool           | Description                      |
| -------------- | -------------------------------- |
| `list_routes`  | View inbound email routing rules |
| `update_route` | Update an inbound routing rule   |

### Mailing lists

| Tool                  | Description                                 |
| --------------------- | ------------------------------------------- |
| `create_mailing_list` | Create a new mailing list                   |
| `manage_list_members` | Add, remove, or update mailing list members |

### Templates

| Tool                       | Description                         |
| -------------------------- | ----------------------------------- |
| `create_template`          | Create a new email template         |
| `manage_template_versions` | Create and manage template versions |

### Analytics and stats

| Tool            | Description                                                            |
| --------------- | ---------------------------------------------------------------------- |
| `query_metrics` | Query sending and usage metrics for a date range                       |
| `get_logs`      | Retrieve email event logs                                              |
| `get_stats`     | View aggregate statistics by domain, tag, provider, device, or country |

### Suppressions

| Tool               | Description                       |
| ------------------ | --------------------------------- |
| `get_bounces`      | View bounced email addresses      |
| `get_unsubscribes` | View unsubscribed email addresses |
| `get_complaints`   | View complaint records            |
| `get_allowlist`    | View allowlist entries            |

### IPs

| Tool           | Description                          |
| -------------- | ------------------------------------ |
| `list_ips`     | View IP assignments                  |
| `get_ip_pools` | View dedicated IP pool configuration |

### Bounce classification

| Tool                        | Description                              |
| --------------------------- | ---------------------------------------- |
| `get_bounce_classification` | Analyze bounce types and delivery issues |

## Configuration

| Variable             | Required | Default | Description              |
| -------------------- | -------- | ------- | ------------------------ |
| `MAILGUN_API_KEY`    | Yes      | —       | Your Mailgun API key     |
| `MAILGUN_API_REGION` | No       | `us`    | API region: `us` or `eu` |

## Additional resources

- [Mailgun MCP Server Repository](https://github.com/mailgun/mailgun-mcp-server)
- [Mailgun MCP Integration Guide](https://www.mailgun.com/resources/integrations/mcp-server/)
- [Mailgun Documentation](https://documentation.mailgun.com/)

# Markifact MCP tool for ADK

Supported in ADKPythonTypeScript

The [Markifact MCP Server](https://github.com/markifact/markifact-mcp) connects your ADK agent to [Markifact](https://www.markifact.com), an AI marketing automation platform with 300+ operations across 20+ platforms including Google Ads, Meta Ads, GA4, TikTok Ads, and Shopify. This integration gives your agent the ability to manage campaigns, analyze performance, and automate marketing workflows using natural language, with approval prompts on every write operation.

## Use cases

- **Spend hygiene**: surface wasted budget across Google Ads, Meta, TikTok and LinkedIn with concrete pause and reallocation recommendations.
- **Unified reporting**: one prompt produces blended spend, ROAS, CAC and conversion deltas across every connected channel and GA4.
- **Briefs to live campaigns**: go from a one-line brief to drafted Search, Performance Max, Meta Advantage+, TikTok or LinkedIn campaigns ready for human approval.
- **Lead handoff**: sweep Meta and LinkedIn lead forms, enrich in HubSpot or Klaviyo, and trigger WhatsApp or Slack follow-ups.

## Prerequisites

- A [Markifact](https://www.markifact.com) account (free tier available)
- At least one platform connected from the Markifact dashboard (Google Ads, Meta, GA4, Shopify, etc.)
- See the [Markifact docs](https://docs.markifact.com) for connection setup

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

root_agent = Agent(
    model="gemini-flash-latest",
    name="marketing_agent",
    instruction=(
        "You are a performance marketing agent that helps users manage "
        "ad campaigns, run analytics, sync e-commerce data, and "
        "execute marketing workflows across Google Ads, Meta Ads, GA4, "
        "TikTok Ads, LinkedIn Ads, Shopify, HubSpot, and more. "
        "Always confirm with the user before any write operation."
    ),
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "mcp-remote",
                        "https://api.markifact.com/mcp",
                    ],
                ),
                timeout=30,
            ),
        )
    ],
)
```

Note

When you run this agent for the first time, a browser window opens automatically to request access via OAuth. Approve the request in your browser to grant the agent access to your connected accounts.

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset, StreamableHTTPConnectionParams

MARKIFACT_ACCESS_TOKEN = "YOUR_MARKIFACT_ACCESS_TOKEN"

root_agent = Agent(
    model="gemini-flash-latest",
    name="marketing_agent",
    instruction=(
        "You are a performance marketing agent that helps users manage "
        "ad campaigns, run analytics, sync e-commerce data, and "
        "execute marketing workflows across Google Ads, Meta Ads, GA4, "
        "TikTok Ads, LinkedIn Ads, Shopify, HubSpot, and more. "
        "Always confirm with the user before any write operation."
    ),
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url="https://api.markifact.com/mcp",
                headers={
                    "Authorization": f"Bearer {MARKIFACT_ACCESS_TOKEN}",
                },
            ),
        )
    ],
)
```

Note

If you already have a Markifact access token, you can connect directly using Streamable HTTP without the OAuth browser flow.

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "marketing_agent",
    instruction:
        "You are a performance marketing agent that helps users manage " +
        "ad campaigns, run analytics, sync e-commerce data, and " +
        "execute marketing workflows across Google Ads, Meta Ads, GA4, " +
        "TikTok Ads, LinkedIn Ads, Shopify, HubSpot, and more. " +
        "Always confirm with the user before any write operation.",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: [
                    "-y",
                    "mcp-remote",
                    "https://api.markifact.com/mcp",
                ],
            },
        }),
    ],
});

export { rootAgent };
```

Note

When you run this agent for the first time, a browser window opens automatically to request access via OAuth. Approve the request in your browser to grant the agent access to your connected accounts.

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const MARKIFACT_ACCESS_TOKEN = "YOUR_MARKIFACT_ACCESS_TOKEN";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "marketing_agent",
    instruction:
        "You are a performance marketing agent that helps users manage " +
        "ad campaigns, run analytics, sync e-commerce data, and " +
        "execute marketing workflows across Google Ads, Meta Ads, GA4, " +
        "TikTok Ads, LinkedIn Ads, Shopify, HubSpot, and more. " +
        "Always confirm with the user before any write operation.",
    tools: [
        new MCPToolset({
            type: "StreamableHTTPConnectionParams",
            url: "https://api.markifact.com/mcp",
            transportOptions: {
                requestInit: {
                    headers: {
                        Authorization: `Bearer ${MARKIFACT_ACCESS_TOKEN}`,
                    },
                },
            },
        }),
    ],
});

export { rootAgent };
```

Note

If you already have a Markifact access token, you can connect directly using Streamable HTTP without the OAuth browser flow.

## Available tools

| Tool                   | Description                                                                |
| ---------------------- | -------------------------------------------------------------------------- |
| `find_operations`      | Semantic search over the operation registry, scoped by platform and intent |
| `get_operation_inputs` | Returns JSON Schema for a specific operation's inputs                      |
| `run_operation`        | Execute read operations                                                    |
| `run_write_operation`  | Execute write operations with approval protocol                            |
| `list_connections`     | List OAuth connections in the workspace                                    |
| `get_file_url`         | Get URLs for reports and exports                                           |
| `read_file`            | Read file contents                                                         |
| `upload_media`         | Upload media assets                                                        |

## Capabilities

| Capability              | Description                                                                          |
| ----------------------- | ------------------------------------------------------------------------------------ |
| Discovery               | Semantic search over 300+ operations with read/write classification                  |
| Approval-gated writes   | Four-step protocol around `run_write_operation` for any spend or destructive change  |
| Campaign management     | Create, edit, pause and resume campaigns, ad sets and ads across all paid channels   |
| Reporting & attribution | Cross-platform spend, ROAS and conversion blends, plus GA4 path and channel analysis |
| Audiences               | Custom audiences, lookalikes, exclusions and behavioural targeting per platform      |
| Creative                | Asset upload, variant rotation, fatigue detection and approval-gated publishing      |
| Commerce & CRM          | Shopify, HubSpot and Klaviyo sync with paid media for closed-loop reporting          |
| Messaging               | WhatsApp and Slack notifications for approvals, alerts and lead handoff              |
| File I/O                | Reports, exports and uploads via `get_file_url`, `read_file`, `upload_media`         |

## Supported platforms

| Category                   | Platforms                                                                                                                 |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| Paid media                 | Google Ads, Meta Ads, TikTok Ads, LinkedIn Ads, Microsoft Ads, Reddit Ads, Pinterest Ads, Snapchat Ads, Amazon Ads, DV360 |
| Analytics                  | GA4, BigQuery, Google Search Console, Google Merchant Center                                                              |
| E-commerce, CRM, messaging | Shopify, HubSpot, Klaviyo, WhatsApp, Slack                                                                                |
| Organic & social           | Facebook, Instagram, LinkedIn, Google Business Profile                                                                    |

## Additional resources

- [Markifact Website](https://www.markifact.com)
- [Markifact MCP Server on GitHub](https://github.com/markifact/markifact-mcp)
- [Skills on skills.sh](https://skills.sh/markifact/markifact-mcp)

# MCP Toolbox for Databases tool for ADK

Supported in ADKPythonTypescriptGo

[MCP Toolbox for Databases](https://github.com/googleapis/mcp-toolbox) is an open source MCP server for databases. It was designed with enterprise-grade and production-quality in mind. It enables you to develop tools easier, faster, and more securely by handling the complexities such as connection pooling, authentication, and more.

Google’s Agent Development Kit (ADK) has built in support for MCP Toolbox. For more information on [getting started](https://mcp-toolbox.dev/documentation/introduction/) or [configuring](https://mcp-toolbox.dev/documentation/configuration/) MCP Toolbox, see the [documentation](https://mcp-toolbox.dev/documentation/introduction/).

## Supported Data Sources

MCP Toolbox provides out-of-the-box toolsets for the following databases and data platforms:

### Google Cloud

- [BigQuery](https://mcp-toolbox.dev/integrations/bigquery/source/) (including tools for SQL execution, schema discovery, and AI-powered time series forecasting)
- [AlloyDB](https://mcp-toolbox.dev/integrations/alloydb/source/) (PostgreSQL-compatible, with tools for both standard queries and natural language queries)
- [AlloyDB Admin](https://mcp-toolbox.dev/integrations/alloydb/source/)
- [Spanner](https://mcp-toolbox.dev/integrations/spanner/source/) (supporting both GoogleSQL and PostgreSQL dialects)
- Cloud SQL (with dedicated support for [Cloud SQL for PostgreSQL](https://mcp-toolbox.dev/integrations/cloud-sql-pg/source/), [Cloud SQL for MySQL](https://mcp-toolbox.dev/integrations/cloud-sql-mysql/source/), and [Cloud SQL for SQL Server](https://mcp-toolbox.dev/integrations/cloud-sql-mssql/source/))
- [Cloud SQL Admin](https://mcp-toolbox.dev/integrations/cloud-sql-admin/source/)
- [Firestore](https://mcp-toolbox.dev/integrations/firestore/source/)
- [Bigtable](https://mcp-toolbox.dev/integrations/bigtable/source/)
- [Dataplex](https://mcp-toolbox.dev/integrations/dataplex/source/) (for data discovery and metadata search)
- [Cloud Monitoring](https://mcp-toolbox.dev/integrations/cloudmonitoring/source/)
- [Cloud Healthcare](https://mcp-toolbox.dev/integrations/cloudhealthcare/source/)
- [Cloud Logging Admin](https://mcp-toolbox.dev/integrations/cloudloggingadmin/source/)
- [Dataproc](https://mcp-toolbox.dev/integrations/dataproc/source/)
- [Serverless Spark](https://mcp-toolbox.dev/integrations/serverless-spark/source/)
- [Cloud GDA](https://mcp-toolbox.dev/integrations/cloudgda/source/)

### Relational & SQL Databases

- [PostgreSQL](https://mcp-toolbox.dev/integrations/postgres/source/) (generic)
- [MySQL](https://mcp-toolbox.dev/integrations/mysql/source/) (generic)
- [Microsoft SQL Server](https://mcp-toolbox.dev/integrations/mssql/source/) (generic)
- [ClickHouse](https://mcp-toolbox.dev/integrations/clickhouse/source/)
- [TiDB](https://mcp-toolbox.dev/integrations/tidb/source/)
- [OceanBase](https://mcp-toolbox.dev/integrations/oceanbase/source/)
- [Firebird](https://mcp-toolbox.dev/integrations/firebird/source/)
- [SQLite](https://mcp-toolbox.dev/integrations/sqlite/source/)
- [YugabyteDB](https://mcp-toolbox.dev/integrations/yuagbytedb/source/)
- [CockroachDB](https://mcp-toolbox.dev/integrations/cockroachdb/source/)
- [Oracle](https://mcp-toolbox.dev/integrations/oracle/source/)
- [SingleStore](https://mcp-toolbox.dev/integrations/singlestore/source/)

### NoSQL & Key-Value Stores

- [MongoDB](https://mcp-toolbox.dev/integrations/mongodb/source/)
- [Couchbase](https://mcp-toolbox.dev/integrations/couchbase/source/)
- [Redis](https://mcp-toolbox.dev/integrations/redis/source/)
- [Valkey](https://mcp-toolbox.dev/integrations/valkey/source/)
- [Cassandra](https://mcp-toolbox.dev/integrations/cassandra/source/)
- [Elasticsearch](https://mcp-toolbox.dev/integrations/elasticsearch/source/)

### Graph Databases

- [Neo4j](https://mcp-toolbox.dev/integrations/neo4j/source/) (with tools for Cypher queries and schema inspection)
- [Dgraph](https://mcp-toolbox.dev/integrations/dgraph/source/)

### Data Platforms & Federation

- [Looker](https://mcp-toolbox.dev/integrations/looker/source/) (for running Looks, queries, and building dashboards via the Looker API)
- [Trino](https://mcp-toolbox.dev/integrations/trino/source/) (for running federated queries across multiple sources)
- [Snowflake](https://mcp-toolbox.dev/integrations/snowflake/source/)
- [MindsDB](https://mcp-toolbox.dev/integrations/mindsdb/source/)

### Other

- [HTTP](https://mcp-toolbox.dev/integrations/http/source/)

## Configure and deploy

MCP Toolbox is an open source server that you deploy and manage yourself. For more instructions on deploying and configuring, see the official Toolbox documentation:

- [Installing the Server](https://mcp-toolbox.dev/documentation/introduction/)
- [Configuring MCP Toolbox](https://mcp-toolbox.dev/documentation/configuration/)

## Install Client SDK for ADK

ADK relies on the `toolbox-adk` python package to use MCP Toolbox. Install the package before getting started:

```shell
pip install google-adk[toolbox]
```

### Loading MCP Toolbox Tools

Once your MCP Toolbox server is configured, up and running, you can load tools from your server using ADK:

```python
from google.adk import Agent
from google.adk.tools.toolbox_toolset import ToolboxToolset

toolset = ToolboxToolset(
    server_url="http://127.0.0.1:5000"
)

root_agent = Agent(
    ...,
    tools=[toolset] # Provide the toolset to the Agent
)
```

### Authentication

The `ToolboxToolset` supports various authentication strategies including Workload Identity (ADC), User Identity (OAuth2), and API Keys. For full documentation, see the [MCP Toolbox ADK Authentication Guide](https://github.com/googleapis/mcp-toolbox-sdk-python/tree/main/packages/toolbox-adk#authentication).

**Example: Workload Identity (ADC)**

Recommended for Cloud Run, GKE, or local development with `gcloud auth login`.

```python
from google.adk.tools.toolbox_toolset import ToolboxToolset
from toolbox_adk import CredentialStrategy

# target_audience: The URL of your MCP Toolbox server
creds = CredentialStrategy.workload_identity(target_audience="<TOOLBOX_URL>")

toolset = ToolboxToolset(
    server_url="<TOOLBOX_URL>",
    credentials=creds
)
```

### Advanced Configuration

You can configure parameter binding and additional headers. See the [MCP Toolbox ADK documentation](https://github.com/googleapis/mcp-toolbox-sdk-python/tree/main/packages/toolbox-adk) for details. For example, you can bind values to tool parameters.

Note

These values are hidden from the model.

```python
toolset = ToolboxToolset(
    server_url="...",
    bound_params={
        "region": "us-central1",
        "api_key": lambda: get_api_key() # Can be a callable
    }
)
```

ADK relies on the `@toolbox-sdk/adk` TS package to use MCP Toolbox. Install the package before getting started:

```shell
npm install @toolbox-sdk/adk
```

### Loading MCP Toolbox Tools

Once your MCP Toolbox server is configured and up and running, you can load tools from your server using ADK:

```typescript
import {InMemoryRunner, LlmAgent} from '@google/adk';
import {Content} from '@google/genai';
import {ToolboxClient} from '@toolbox-sdk/adk'

const toolboxClient = new ToolboxClient("http://127.0.0.1:5000");
const loadedTools = await toolboxClient.loadToolset();

export const rootAgent = new LlmAgent({
  name: 'weather_time_agent',
  model: 'gemini-flash-latest',
  description:
    'Agent to answer questions about the time and weather in a city.',
  instruction:
    'You are a helpful agent who can answer user questions about the time and weather in a city.',
  tools: loadedTools,
});

async function main() {
  const userId = 'test_user';
  const appName = rootAgent.name;
  const runner = new InMemoryRunner({agent: rootAgent, appName});
  const session = await runner.sessionService.createSession({
    appName,
    userId,
  });

  const prompt = 'What is the weather in New York? And the time?';
  const content: Content = {
    role: 'user',
    parts: [{text: prompt}],
  };
  console.log(content);
  for await (const e of runner.runAsync({
    userId,
    sessionId: session.id,
    newMessage: content,
  })) {
    if (e.content?.parts?.[0]?.text) {
      console.log(`${e.author}: ${JSON.stringify(e.content, null, 2)}`);
    }
  }
}

main().catch(console.error);
```

ADK relies on the `mcp-toolbox-sdk-go` go module to use MCP Toolbox. Install the module before getting started:

```shell
go get github.com/googleapis/mcp-toolbox-sdk-go
```

### Loading MCP Toolbox Tools

Once your MCP Toolbox server is configured and up and running, you can load tools from your server using ADK:

```go
package main

import (
    "context"
    "fmt"

    "github.com/googleapis/mcp-toolbox-sdk-go/tbadk"
    "google.golang.org/adk/agent/llmagent"
)

func main() {

  toolboxClient, err := tbadk.NewToolboxClient("https://127.0.0.1:5000")
    if err != nil {
        log.Fatalf("Failed to create MCP Toolbox client: %v", err)
    }

  // Load a specific set of tools
  toolboxtools, err := toolboxClient.LoadToolset("my-toolset-name", ctx)
  if err != nil {
    return fmt.Sprintln("Could not load MCP Toolbox Toolset", err)
  }

  toolsList := make([]tool.Tool, len(toolboxtools))
    for i := range toolboxtools {
      toolsList[i] = &toolboxtools[i]
    }

  llmagent, err := llmagent.New(llmagent.Config{
    ...,
    Tools:       toolsList,
  })

  // Load a single tool
  tool, err := client.LoadTool("my-tool-name", ctx)
  if err != nil {
    return fmt.Sprintln("Could not load MCP Toolbox Tool", err)
  }

  llmagent, err := llmagent.New(llmagent.Config{
    ...,
    Tools:       []tool.Tool{&toolboxtool},
  })
}
```

## Advanced MCP Toolbox Features

MCP Toolbox has a variety of features to make developing Gen AI tools for databases. For more information, read more about the following features:

- [Authenticated Parameters](https://mcp-toolbox.dev/documentation/connect-to/toolbox-sdks/python-sdk/core/#parameter-binding): bind tool inputs to values from OIDC tokens automatically, making it easy to run sensitive queries without potentially leaking data
- [Authorized Invocations:](https://mcp-toolbox.dev/documentation/connect-to/toolbox-sdks/python-sdk/core/#client-to-server-authentication) restrict access to use a tool based on the users Auth token
- [OpenTelemetry](https://mcp-toolbox.dev/documentation/connect-to/toolbox-sdks/python-sdk/core/#opentelemetry): get metrics and tracing from Toolbox with OpenTelemetry

# MLflow AI Gateway for ADK agents

Supported in ADKPython

[MLflow AI Gateway](https://mlflow.org/docs/latest/genai/governance/ai-gateway/) is a database-backed LLM proxy built into the MLflow tracking server (MLflow ≥ 3.0). It provides a unified OpenAI-compatible API across dozens of providers, including Gemini, Anthropic, Mistral, Bedrock, Ollama, and more, with built-in secrets management, fallback/retry, traffic splitting, and budget tracking, all configured through the MLflow UI.

Since MLflow AI Gateway exposes an OpenAI-compatible endpoint, you can connect ADK agents to it using the [LiteLLM](/agents/models/litellm/) model connector.

## Use cases

- **Multi-provider routing**: Switch LLM providers without changing agent code
- **Secrets management**: Provider API keys stored encrypted on the server; your application sends no provider keys
- **Fallback & retry**: Automatic failover to backup models on failure
- **Budget tracking**: Per-endpoint or per-user token budgets
- **Traffic splitting**: Route percentages of requests to different models for A/B testing
- **Usage tracing**: Every call logged as an MLflow trace automatically

## Prerequisites

- MLflow version 3.0 or newer
- Google ADK and LiteLLM installed in your environment

## Setup

Install dependencies:

```bash
pip install mlflow[genai] google-adk litellm
```

Start the MLflow server:

```bash
mlflow server --host 127.0.0.1 --port 5000
```

The MLflow UI will be available at `http://localhost:5000`.

Create a gateway endpoint by navigating to the MLflow UI at `http://localhost:5000`, then go to **AI Gateway → Create Endpoint**. Select a provider (e.g., Google Gemini) and model (e.g., `gemini-flash-latest`), and enter your provider API key, which is stored encrypted on the server.

See the [MLflow AI Gateway documentation](https://mlflow.org/docs/latest/genai/governance/ai-gateway/endpoints/) for more details on endpoint configuration.

## Use with agent

Use the `LiteLlm` wrapper with `api_base` pointing to the MLflow Gateway's endpoint. The `model` parameter should use the `openai/` prefix followed by your gateway endpoint name.

```python
from google.adk.agents import LlmAgent
from google.adk.models.lite_llm import LiteLlm

# Point to MLflow AI Gateway endpoint.
# "my-chat-endpoint" is the endpoint name you created in the MLflow UI.
agent = LlmAgent(
    model=LiteLlm(
        model="openai/my-chat-endpoint",
        api_base="http://localhost:5000/gateway/openai/v1",
        api_key="unused",  # provider keys are managed by the MLflow server
    ),
    name="gateway_agent",
    instruction="You are a helpful assistant powered by MLflow AI Gateway.",
)
```

You can swap the underlying LLM provider at any time by reconfiguring the gateway endpoint in the MLflow UI with no code changes required in your ADK agent.

## Tips

- The `api_key` parameter is required by LiteLLM but not validated by the gateway. Set it to any non-empty string.
- Behind a proxy or on a remote host, replace `localhost:5000` with your server address.
- Combine with [MLflow Tracing](/integrations/mlflow-tracing/) for end-to-end observability of your ADK agents.

## Resources

- [MLflow AI Gateway Documentation](https://mlflow.org/docs/latest/genai/governance/ai-gateway/): Official documentation for MLflow AI Gateway covering endpoint management, query APIs, and gateway features.
- [MLflow Tracing for ADK](/integrations/mlflow-tracing/): Set up observability for your ADK agents with MLflow Tracing.
- [LiteLLM model connector](/agents/models/litellm/): Documentation for the LiteLLM wrapper used to connect ADK agents to compatible endpoints.

# MLflow observability for ADK

Supported in ADKPython

[MLflow Tracing](https://mlflow.org/docs/latest/genai/tracing/) provides first-class support for ingesting OpenTelemetry (OTel) traces. Google ADK emits OTel spans for agent runs, tool calls, and model requests, which you can send directly to an MLflow Tracking Server for analysis and debugging.

## Prerequisites

- MLflow version 3.6.0 or newer. OpenTelemetry ingestion is only supported in MLflow 3.6.0+.
- A SQL-based backend store (e.g., SQLite, PostgreSQL, MySQL). File-based stores do not support OTLP ingestion.
- Google ADK installed in your environment.

## Install dependencies

```bash
pip install "mlflow>=3.6.0" google-adk opentelemetry-sdk opentelemetry-exporter-otlp-proto-http
```

## Start the MLflow Tracking Server

Start MLflow with a SQL backend and a port (5000 in this example):

```bash
mlflow server --backend-store-uri sqlite:///mlflow.db --port 5000
```

You can point `--backend-store-uri` to other SQL backends (PostgreSQL, MySQL, MSSQL). OTLP ingestion is not supported with file-based backends.

## Configure OpenTelemetry (required)

You must configure an OTLP exporter and set a global tracer provider before using any ADK components so that spans are emitted to MLflow.

Initialize the OTLP exporter and global tracer provider in code before importing or constructing ADK agents/tools:

```python
# my_agent/agent.py
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import SimpleSpanProcessor

exporter = OTLPSpanExporter(
    endpoint="http://localhost:5000/v1/traces",
    headers={"x-mlflow-experiment-id": "123"}  # replace with your experiment id
)

provider = TracerProvider()
provider.add_span_processor(SimpleSpanProcessor(exporter))
trace.set_tracer_provider(provider)  # set BEFORE importing/using ADK
```

This configures the OpenTelemetry pipeline and sends ADK spans to the MLflow server on each run.

## Example: Trace an ADK agent

Now you can add the agent code for a simple math agent, after the code that sets up the OTLP exporter and tracer provider:

```python
# my_agent/agent.py
from google.adk.agents import LlmAgent
from google.adk.tools import FunctionTool


def calculator(a: float, b: float) -> str:
    """Add two numbers and return the result."""
    return str(a + b)


calculator_tool = FunctionTool(func=calculator)

root_agent = LlmAgent(
    name="MathAgent",
    model="gemini-flash-latest",
    instruction=(
        "You are a helpful assistant that can do math. "
        "When asked a math problem, use the calculator tool to solve it."
    ),
    tools=[calculator_tool],
)
```

Run the agent with:

```bash
adk run my_agent
```

And ask it a math problem:

```console
What is 12 + 34?
```

You should then see output similar to:

```console
[MathAgent]: The answer is 46.
```

## View traces in MLflow

Open the MLflow UI at `http://localhost:5000`, select your experiment, and inspect the trace tree and spans generated by your ADK agent.

## Tips

- Set the tracer provider before importing or initializing ADK objects so all spans are captured.
- Behind a proxy or on a remote host, replace `localhost:5000` with your server address.

## Resources

- [MLflow Tracing Documentation](https://mlflow.org/docs/latest/genai/tracing/): Official documentation for MLflow Tracing that covers other library integrations and downstream usage of traces, such as evaluation, monitoring, searching, and more.
- [OpenTelemetry in MLflow](https://mlflow.org/docs/latest/genai/tracing/opentelemetry/): Detailed guide on how to use OpenTelemetry with MLflow.
- [MLflow for Agents](https://mlflow.org/docs/latest/genai/): Comprehensive guide on how to use MLflow for building production-ready agents.

# MongoDB MCP tool for ADK

Supported in ADKPythonTypeScript

The [MongoDB MCP Server](https://github.com/mongodb-js/mongodb-mcp-server) connects your ADK agent to [MongoDB](https://www.mongodb.com/) databases and MongoDB Atlas clusters. This integration gives your agent the ability to query collections, manage databases, and interact with MongoDB Atlas infrastructure using natural language.

## Use cases

- **Data Exploration and Analysis**: Query MongoDB collections using natural language, run aggregations, and analyze document schemas without writing complex queries manually.
- **Database Administration**: List databases and collections, create indexes, manage users, and monitor database statistics through conversational commands.
- **Atlas Infrastructure Management**: Create and manage MongoDB Atlas clusters, configure access lists, and view performance recommendations directly from your agent.

## Prerequisites

- **For database access**: A MongoDB connection string (local, self-hosted, or Atlas cluster)
- **For Atlas management**: A [MongoDB Atlas](https://www.mongodb.com/atlas) service account with API credentials (client ID and secret)

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

# For database access, use a connection string:
CONNECTION_STRING = "mongodb://localhost:27017/myDatabase"

# For Atlas management, use API credentials:
# ATLAS_CLIENT_ID = "YOUR_ATLAS_CLIENT_ID"
# ATLAS_CLIENT_SECRET = "YOUR_ATLAS_CLIENT_SECRET"

root_agent = Agent(
    model="gemini-flash-latest",
    name="mongodb_agent",
    instruction="Help users query and manage MongoDB databases",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "mongodb-mcp-server",
                        "--readOnly",  # Remove for write operations
                    ],
                    env={
                        # For database access, use:
                        "MDB_MCP_CONNECTION_STRING": CONNECTION_STRING,
                        # For Atlas management, use:
                        # "MDB_MCP_API_CLIENT_ID": ATLAS_CLIENT_ID,
                        # "MDB_MCP_API_CLIENT_SECRET": ATLAS_CLIENT_SECRET,
                    },
                ),
                timeout=30,
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

// For database access, use a connection string:
const CONNECTION_STRING = "mongodb://localhost:27017/myDatabase";

// For Atlas management, use API credentials:
// const ATLAS_CLIENT_ID = "YOUR_ATLAS_CLIENT_ID";
// const ATLAS_CLIENT_SECRET = "YOUR_ATLAS_CLIENT_SECRET";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "mongodb_agent",
    instruction: "Help users query and manage MongoDB databases",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: [
                    "-y",
                    "mongodb-mcp-server",
                    "--readOnly", // Remove for write operations
                ],
                env: {
                    // For database access, use:
                    MDB_MCP_CONNECTION_STRING: CONNECTION_STRING,
                    // For Atlas management, use:
                    // MDB_MCP_API_CLIENT_ID: ATLAS_CLIENT_ID,
                    // MDB_MCP_API_CLIENT_SECRET: ATLAS_CLIENT_SECRET,
                },
            },
        }),
    ],
});

export { rootAgent };
```

## Available tools

### MongoDB database tools

| Tool                 | Description                                     |
| -------------------- | ----------------------------------------------- |
| `find`               | Run a find query against a MongoDB collection   |
| `aggregate`          | Run an aggregation against a MongoDB collection |
| `count`              | Get the number of documents in a collection     |
| `list-databases`     | List all databases for a MongoDB connection     |
| `list-collections`   | List all collections for a given database       |
| `collection-schema`  | Describe the schema for a collection            |
| `collection-indexes` | Describe the indexes for a collection           |
| `insert-many`        | Insert documents into a collection              |
| `update-many`        | Update documents matching a filter              |
| `delete-many`        | Remove documents matching a filter              |
| `create-collection`  | Create a new collection                         |
| `drop-collection`    | Remove a collection from the database           |
| `drop-database`      | Remove a database                               |
| `create-index`       | Create an index for a collection                |
| `drop-index`         | Drop an index from a collection                 |
| `rename-collection`  | Rename a collection                             |
| `db-stats`           | Get statistics for a database                   |
| `explain`            | Get query execution statistics                  |
| `export`             | Export query results in EJSON format            |

### MongoDB Atlas tools

Note

Atlas tools require API credentials. Set `MDB_MCP_API_CLIENT_ID` and `MDB_MCP_API_CLIENT_SECRET` environment variables to enable them.

| Tool                            | Description                      |
| ------------------------------- | -------------------------------- |
| `atlas-list-orgs`               | List MongoDB Atlas organizations |
| `atlas-list-projects`           | List MongoDB Atlas projects      |
| `atlas-list-clusters`           | List MongoDB Atlas clusters      |
| `atlas-inspect-cluster`         | Inspect metadata of a cluster    |
| `atlas-list-db-users`           | List database users              |
| `atlas-create-free-cluster`     | Create a free Atlas cluster      |
| `atlas-create-project`          | Create an Atlas project          |
| `atlas-create-db-user`          | Create a database user           |
| `atlas-create-access-list`      | Configure IP access list         |
| `atlas-inspect-access-list`     | View IP access list entries      |
| `atlas-list-alerts`             | List Atlas alerts                |
| `atlas-get-performance-advisor` | Get performance recommendations  |

## Configuration

### Environment variables

| Variable                    | Description                                   |
| --------------------------- | --------------------------------------------- |
| `MDB_MCP_CONNECTION_STRING` | MongoDB connection string for database access |
| `MDB_MCP_API_CLIENT_ID`     | Atlas API client ID for Atlas tools           |
| `MDB_MCP_API_CLIENT_SECRET` | Atlas API client secret for Atlas tools       |
| `MDB_MCP_READ_ONLY`         | Enable read-only mode (`true` or `false`)     |
| `MDB_MCP_DISABLED_TOOLS`    | Comma-separated list of tools to disable      |
| `MDB_MCP_LOG_PATH`          | Directory for log files                       |

### Read-only mode

The `--readOnly` flag restricts the server to read, connect, and metadata operations only. This prevents any create, update, or delete operations, making it safe for data exploration without risk of accidental modifications.

### Disabling tools

You can disable specific tools or categories using `MDB_MCP_DISABLED_TOOLS`:

- Tool names: `find`, `aggregate`, `insert-many`, etc.
- Categories: `atlas` (all Atlas tools), `mongodb` (all database tools)
- Operation types: `create`, `update`, `delete`, `read`, `metadata`

## Additional resources

- [MongoDB MCP Server Repository](https://github.com/mongodb-js/mongodb-mcp-server)
- [MongoDB Documentation](https://www.mongodb.com/docs/)
- [MongoDB Atlas](https://www.mongodb.com/atlas)

# Monocle observability for ADK

Supported in ADKPython

[Monocle](https://github.com/monocle2ai/monocle) is an open-source observability platform for monitoring, debugging, and improving LLM applications and AI Agents. It provides comprehensive tracing capabilities for your Google ADK applications through automatic instrumentation. Monocle generates OpenTelemetry-compatible traces that can be exported to various destinations including local files or console output.

## Overview

Monocle automatically instruments Google ADK applications, allowing you to:

- **Trace agent interactions** - Automatically capture every agent run, tool call, and model request with full context and metadata
- **Monitor execution flow** - Track agent state, delegation events, and execution flow through detailed traces
- **Debug issues** - Analyze detailed traces to quickly identify bottlenecks, failed tool calls, and unexpected agent behavior
- **Flexible export options** - Export traces to local files or console for analysis
- **OpenTelemetry compatible** - Generate standard OpenTelemetry traces that work with any OTLP-compatible backend

Monocle automatically instruments the following Google ADK components:

- **`BaseAgent.run_async`** - Captures agent execution, agent state, and delegation events
- **`FunctionTool.run_async`** - Captures tool execution, including tool name, parameters, and results
- **`Runner.run_async`** - Captures runner execution, including request context and execution flow

## Installation

### 1. Install Required Packages

```bash
pip install monocle_apptrace google-adk
```

## Setup

### 1. Configure Monocle Telemetry

Monocle automatically instruments Google ADK when you initialize telemetry. Simply call `setup_monocle_telemetry()` at the start of your application:

```python
from monocle_apptrace import setup_monocle_telemetry

# Initialize Monocle telemetry - automatically instruments Google ADK
setup_monocle_telemetry(workflow_name="my-adk-app")
```

That's it! Monocle will automatically detect and instrument your Google ADK agents, tools, and runners.

### 2. Configure Exporters (Optional)

By default, Monocle exports traces to local JSON files. You can configure different exporters using environment variables.

#### Export to Console (for debugging)

Set the environment variable:

```bash
export MONOCLE_EXPORTER="console"
```

#### Export to Local Files (default)

```bash
export MONOCLE_EXPORTER="file"
```

Or simply omit the `MONOCLE_EXPORTER` variable - it defaults to `file`.

## Observe

Now that you have tracing setup, all Google ADK SDK requests will be automatically traced by Monocle.

```python
from monocle_apptrace import setup_monocle_telemetry
from google.adk.agents import Agent
from google.adk.runners import InMemoryRunner
from google.genai import types

# Initialize Monocle telemetry - must be called before using ADK
setup_monocle_telemetry(workflow_name="weather_app")

# Define a tool function
def get_weather(city: str) -> dict:
    """Retrieves the current weather report for a specified city.

    Args:
        city (str): The name of the city for which to retrieve the weather report.

    Returns:
        dict: status and result or error msg.
    """
    if city.lower() == "new york":
        return {
            "status": "success",
            "report": (
                "The weather in New York is sunny with a temperature of 25 degrees"
                " Celsius (77 degrees Fahrenheit)."
            ),
        }
    else:
        return {
            "status": "error",
            "error_message": f"Weather information for '{city}' is not available.",
        }

# Create an agent with tools
agent = Agent(
    name="weather_agent",
    model="gemini-flash-latest",
    description="Agent to answer questions using weather tools.",
    instruction="You must use the available tools to find an answer.",
    tools=[get_weather]
)

app_name = "weather_app"
user_id = "test_user"
session_id = "test_session"
runner = InMemoryRunner(agent=agent, app_name=app_name)
session_service = runner.session_service

await session_service.create_session(
    app_name=app_name,
    user_id=user_id,
    session_id=session_id
)

# Run the agent (all interactions will be automatically traced)
async for event in runner.run_async(
    user_id=user_id,
    session_id=session_id,
    new_message=types.Content(role="user", parts=[
        types.Part(text="What is the weather in New York?")]
    )
):
    if event.is_final_response():
        print(event.content.parts[0].text.strip())
```

## Accessing Traces

By default, Monocle generates traces in JSON files in the local directory `./monocle`. The file name format is:

```text
monocle_trace_{workflow_name}_{trace_id}_{timestamp}.json
```

Each trace file contains an array of OpenTelemetry-compatible spans that capture:

- **Agent execution spans** - Agent state, delegation events, and execution flow
- **Tool execution spans** - Tool name, input parameters, and output results
- **LLM interaction spans** - Model calls, prompts, responses, and token usage (if using Gemini or other LLMs)

You can analyze these trace files using any OpenTelemetry-compatible tool or write custom analysis scripts.

## Visualizing Traces with VS Code Extension

The [Okahu Trace Visualizer](https://marketplace.visualstudio.com/items?itemName=OkahuAI.okahu-ai-observability) VS Code extension provides an interactive way to visualize and analyze Monocle-generated traces directly in Visual Studio Code.

### Installation

1. Open VS Code
1. Press `Ctrl+P` (or `Cmd+P` on Mac) to open Quick Open
1. Paste the following command and press Enter:

```text
ext install OkahuAI.okahu-ai-observability
```

Alternatively, you can install it from the [VS Code Marketplace](https://marketplace.visualstudio.com/items?itemName=OkahuAI.okahu-ai-observability).

### Features

The extension provides:

- **Custom Activity Bar Panel** - Dedicated sidebar for trace file management
- **Interactive File Tree** - Browse and select trace files with custom React UI
- **Split View Analysis** - Gantt chart visualization alongside JSON data viewer
- **Real-time Communication** - Seamless data flow between VS Code and React components
- **VS Code Theming** - Fully integrated with VS Code's light/dark themes

### Usage

1. After running your ADK application with Monocle tracing enabled, trace files will be generated in the `./monocle` directory
1. Open the Okahu Trace Visualizer panel from the VS Code Activity Bar
1. Browse and select trace files from the interactive file tree
1. View your traces with:
1. **Gantt chart visualization** - See the timeline and hierarchy of spans
1. **JSON data viewer** - Inspect detailed span attributes and events
1. **Token counts** - View token usage for LLM calls
1. **Error badges** - Quickly identify failed operations

## What Gets Traced

Monocle automatically captures the following information from Google ADK:

- **Agent Execution**: Agent state, delegation events, and execution flow
- **Tool Calls**: Tool name, input parameters, and output results
- **Runner Execution**: Request context and overall execution flow
- **Timing Information**: Start time, end time, and duration for each operation
- **Error Information**: Exceptions and error states

All traces are generated in OpenTelemetry format, making them compatible with any OTLP-compatible observability backend.

## Support and Resources

- [Monocle Documentation](https://docs.okahu.ai/monocle_overview/)
- [Monocle GitHub Repository](https://github.com/monocle2ai/monocle)
- [Google ADK Travel Agent Example](https://github.com/okahu-demos/adk-travel-agent)
- [Discord Community](https://discord.gg/D8vDbSUhJX)

# n8n MCP tool for ADK

Supported in ADKPythonTypeScript

The [n8n MCP Server](https://docs.n8n.io/advanced-ai/mcp/accessing-n8n-mcp-server/) connects your ADK agent to [n8n](https://n8n.io/), an extendable workflow automation tool. This integration allows your agent to securely connect to an n8n instance to search, inspect, and trigger workflows directly from a natural language interface.

Alternative: Workflow-level MCP Server

The configuration guide on this page covers **Instance-level MCP access**, which connects your agent to a central hub of enabled workflows. Alternatively, you can use the [MCP Server Trigger node](https://docs.n8n.io/integrations/builtin/core-nodes/n8n-nodes-langchain.mcptrigger/) to make a **single workflow** act as its own standalone MCP server. This method is useful if you want to craft specific server behaviors or expose tools isolated to one workflow.

## Use cases

- **Execute Complex Workflows**: Trigger multi-step business processes defined in n8n directly from your agent, leveraging reliable branching logic, loops, and error handling to ensure consistency.
- **Connect to External Apps**: Access pre-built integrations through n8n without writing custom tools for each service, eliminating the need to manage API authentication, headers, or boilerplate code.
- **Data Processing**: Offload complex data transformation tasks to n8n workflows, such as converting natural language into API calls or scraping and summarizing webpages, utilizing custom Python or JavaScript nodes for precise data shaping.

## Prerequisites

- An active n8n instance
- MCP access enabled in settings
- A valid MCP access token

Refer to the [n8n MCP documentation](https://docs.n8n.io/advanced-ai/mcp/accessing-n8n-mcp-server/) for detailed setup instructions.

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

N8N_INSTANCE_URL = "https://localhost:5678"
N8N_MCP_TOKEN = "YOUR_N8N_MCP_TOKEN"

root_agent = Agent(
    model="gemini-flash-latest",
    name="n8n_agent",
    instruction="Help users manage and execute workflows in n8n",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "supergateway",
                        "--streamableHttp",
                        f"{N8N_INSTANCE_URL}/mcp-server/http",
                        "--header",
                        f"authorization:Bearer {N8N_MCP_TOKEN}"
                    ]
                ),
                timeout=300,
            ),
        )
    ],
)
```

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams

N8N_INSTANCE_URL = "https://localhost:5678"
N8N_MCP_TOKEN = "YOUR_N8N_MCP_TOKEN"

root_agent = Agent(
    model="gemini-flash-latest",
    name="n8n_agent",
    instruction="Help users manage and execute workflows in n8n",
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url=f"{N8N_INSTANCE_URL}/mcp-server/http",
                headers={
                    "Authorization": f"Bearer {N8N_MCP_TOKEN}",
                },
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const N8N_INSTANCE_URL = "https://localhost:5678";
const N8N_MCP_TOKEN = "YOUR_N8N_MCP_TOKEN";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "n8n_agent",
    instruction: "Help users manage and execute workflows in n8n",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: [
                    "-y",
                    "supergateway",
                    "--streamableHttp",
                    `${N8N_INSTANCE_URL}/mcp-server/http`,
                    "--header",
                    `authorization:Bearer ${N8N_MCP_TOKEN}`,
                ],
            },
        }),
    ],
});

export { rootAgent };
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const N8N_INSTANCE_URL = "https://localhost:5678";
const N8N_MCP_TOKEN = "YOUR_N8N_MCP_TOKEN";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "n8n_agent",
    instruction: "Help users manage and execute workflows in n8n",
    tools: [
        new MCPToolset({
            type: "StreamableHTTPConnectionParams",
            url: `${N8N_INSTANCE_URL}/mcp-server/http`,
            transportOptions: {
                requestInit: {
                    headers: {
                        Authorization: `Bearer ${N8N_MCP_TOKEN}`,
                    },
                },
            },
        }),
    ],
});

export { rootAgent };
```

## Available tools

| Tool                   | Description                                             |
| ---------------------- | ------------------------------------------------------- |
| `search_workflows`     | Search for available workflows                          |
| `execute_workflow`     | Execute a specific workflow                             |
| `get_workflow_details` | Retrieve metadata and schema information for a workflow |

## Configuration

To make workflows accessible to your agent, they must meet the following criteria:

- **Be Active**: The workflow must be activated in n8n.
- **Supported Trigger**: Contain a Webhook, Schedule, Chat, or Form trigger node.
- **Enabled for MCP**: You must toggle "Available in MCP" in the workflow settings or select "Enable MCP access" from the workflow card menu.

## Additional resources

- [n8n MCP Server Documentation](https://docs.n8n.io/advanced-ai/mcp/accessing-n8n-mcp-server/)

# Notion MCP tool for ADK

Supported in ADKPythonTypeScript

The [Notion MCP Server](https://github.com/makenotion/notion-mcp-server) connects your ADK agent to Notion, allowing it to search, create, and manage pages, databases, and more within a workspace. This gives your agent the ability to query, create, and organize content in your Notion workspace using natural language.

## Use cases

- **Search your workspace**: Find project pages, meeting notes, or documents based on content.
- **Create new content**: Generate new pages for meeting notes, project plans, or tasks.
- **Manage tasks and databases**: Update the status of a task, add items to a database, or change properties.
- **Organize your workspace**: Move pages, duplicate templates, or add comments to documents.

## Prerequisites

- Obtain a Notion integration token by going to [Notion Integrations](https://www.notion.so/profile/integrations) in your profile. Refer to the [authorization documentation](https://developers.notion.com/docs/authorization) for more details.
- Ensure relevant pages and databases can be accessed by your integration. Visit the Access tab in your [Notion Integration](https://www.notion.so/profile/integrations) settings, then grant access by selecting the pages you'd like to use.

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

NOTION_TOKEN = "YOUR_NOTION_TOKEN"

root_agent = Agent(
    model="gemini-flash-latest",
    name="notion_agent",
    instruction="Help users get information from Notion",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params = StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "@notionhq/notion-mcp-server",
                    ],
                    env={
                        "NOTION_TOKEN": NOTION_TOKEN,
                    }
                ),
                timeout=30,
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const NOTION_TOKEN = "YOUR_NOTION_TOKEN";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "notion_agent",
    instruction: "Help users get information from Notion",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: ["-y", "@notionhq/notion-mcp-server"],
                env: {
                    NOTION_TOKEN: NOTION_TOKEN,
                },
            },
        }),
    ],
});

export { rootAgent };
```

## Available tools

| Tool                     | Description                                                                                                                                                       |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `notion-search`          | Search across your Notion workspace and connected tools like Slack, Google Drive, and Jira. Falls back to basic workspace search if AI features aren’t available. |
| `notion-fetch`           | Retrieves content from a Notion page or database by its URL                                                                                                       |
| `notion-create-pages`    | Creates one or more Notion pages with specified properties and content.                                                                                           |
| `notion-update-page`     | Update a Notion page's properties or content.                                                                                                                     |
| `notion-move-pages`      | Move one or more Notion pages or databases to a new parent.                                                                                                       |
| `notion-duplicate-page`  | Duplicate a Notion page within your workspace. This action is completed async.                                                                                    |
| `notion-create-database` | Creates a new Notion database, initial data source, and initial view with the specified properties.                                                               |
| `notion-update-database` | Update a Notion data source's properties, name, description, or other attributes.                                                                                 |
| `notion-create-comment`  | Add a comment to a page                                                                                                                                           |
| `notion-get-comments`    | Lists all comments on a specific page, including threaded discussions.                                                                                            |
| `notion-get-teams`       | Retrieves a list of teams (teamspaces) in the current workspace.                                                                                                  |
| `notion-get-users`       | Lists all users in the workspace with their details.                                                                                                              |
| `notion-get-user`        | Retrieve your user information by ID                                                                                                                              |
| `notion-get-self`        | Retrieves information about your own bot user and the Notion workspace you’re connected to.                                                                       |

## Additional resources

- [Notion MCP Server Documentation](https://developers.notion.com/docs/mcp)
- [Notion MCP Server Repository](https://github.com/makenotion/notion-mcp-server)

# PayPal MCP tool for ADK

Supported in ADKPythonTypeScript

The [PayPal MCP Server](https://github.com/paypal/paypal-mcp-server) connects your ADK agent to the [PayPal](https://www.paypal.com/) ecosystem. This integration gives your agent the ability to manage payments, invoices, subscriptions, and disputes using natural language, enabling automated commerce workflows and business insights.

## Use cases

- **Streamline Financial Operations**: Create orders, send invoices, and process refunds directly through chat without switching context. You can instruct your agent to "bill Client X" or "refund order Y" immediately.
- **Manage Subscriptions & Products**: Handle the full lifecycle of recurring billing by creating products, setting up subscription plans, and managing subscriber details using natural language.
- **Resolve Issues & Track Performance**: Summarize and accept dispute claims, track shipment statuses, and retrieve merchant insights to make data-driven decisions on the fly.

## Prerequisites

- Create a [PayPal Developer account](https://developer.paypal.com/)
- Create an app and retrieve your credentials from the [PayPal Developer Dashboard](https://developer.paypal.com/)
- [Generate an access token](https://developer.paypal.com/reference/get-an-access-token/) from your credentials

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

PAYPAL_ENVIRONMENT = "SANDBOX"  # Options: "SANDBOX" or "PRODUCTION"
PAYPAL_ACCESS_TOKEN = "YOUR_PAYPAL_ACCESS_TOKEN"

root_agent = Agent(
    model="gemini-flash-latest",
    name="paypal_agent",
    instruction="Help users manage their PayPal account",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "@paypal/mcp",
                        "--tools=all",
                        # (Optional) Specify which tools to enable
                        # "--tools=subscriptionPlans.list,subscriptionPlans.show",
                    ],
                    env={
                        "PAYPAL_ACCESS_TOKEN": PAYPAL_ACCESS_TOKEN,
                        "PAYPAL_ENVIRONMENT": PAYPAL_ENVIRONMENT,
                    }
                ),
                timeout=300,
            ),
        )
    ],
)
```

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import SseConnectionParams

PAYPAL_MCP_ENDPOINT = "https://mcp.sandbox.paypal.com/sse"  # Production: https://mcp.paypal.com/sse
PAYPAL_ACCESS_TOKEN = "YOUR_PAYPAL_ACCESS_TOKEN"

root_agent = Agent(
    model="gemini-flash-latest",
    name="paypal_agent",
    instruction="Help users manage their PayPal account",
    tools=[
        McpToolset(
            connection_params=SseConnectionParams(
                url=PAYPAL_MCP_ENDPOINT,
                headers={
                    "Authorization": f"Bearer {PAYPAL_ACCESS_TOKEN}",
                },
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const PAYPAL_ENVIRONMENT = "SANDBOX"; // Options: "SANDBOX" or "PRODUCTION"
const PAYPAL_ACCESS_TOKEN = "YOUR_PAYPAL_ACCESS_TOKEN";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "paypal_agent",
    instruction: "Help users manage their PayPal account",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: [
                    "-y",
                    "@paypal/mcp",
                    "--tools=all",
                    // (Optional) Specify which tools to enable
                    // "--tools=subscriptionPlans.list,subscriptionPlans.show",
                ],
                env: {
                    PAYPAL_ACCESS_TOKEN: PAYPAL_ACCESS_TOKEN,
                    PAYPAL_ENVIRONMENT: PAYPAL_ENVIRONMENT,
                },
            },
        }),
    ],
});

export { rootAgent };
```

Note

**Token Expiration**: PayPal Access Tokens have a limited lifespan of 3-8 hours. If your agent stops working, ensure your token has not expired and generate a new one if necessary. You should implement token refresh logic to handle token expiration.

## Available tools

### Catalog management

| Tool                   | Description                                                |
| ---------------------- | ---------------------------------------------------------- |
| `create_product`       | Create a new product in the PayPal catalog                 |
| `list_products`        | List products from the PayPal catalog                      |
| `show_product_details` | Show details of a specific product from the PayPal catalog |
| `update_product`       | Update an existing product in the PayPal catalog           |

### Dispute management

| Tool                   | Description                                                |
| ---------------------- | ---------------------------------------------------------- |
| `list_disputes`        | Retrieve a summary of all disputes with optional filtering |
| `get_dispute`          | Retrieve detailed information about a specific dispute     |
| `accept_dispute_claim` | Accept a dispute claim, resolving it in favor of the buyer |

### Invoices

| Tool                       | Description                                         |
| -------------------------- | --------------------------------------------------- |
| `create_invoice`           | Create a new invoice in the PayPal system           |
| `list_invoices`            | List invoices                                       |
| `get_invoice`              | Retrieve details about a specific invoice           |
| `send_invoice`             | Send an existing invoice to the specified recipient |
| `send_invoice_reminder`    | Send a reminder for an existing invoice             |
| `cancel_sent_invoice`      | Cancel a sent invoice                               |
| `generate_invoice_qr_code` | Generate a QR code for an invoice                   |

### Payments

| Tool            | Description                                                        |
| --------------- | ------------------------------------------------------------------ |
| `create_order`  | Create an order in the PayPal system based on the provided details |
| `create_refund` | Process a refund for a captured payment                            |
| `get_order`     | Get details of a specific payment                                  |
| `get_refund`    | Get the details for a specific refund                              |
| `pay_order`     | Capture payment for an authorized order                            |

### Reporting and insights

| Tool                    | Description                                                         |
| ----------------------- | ------------------------------------------------------------------- |
| `get_merchant_insights` | Retrieve business intelligence metrics and analytics for a merchant |
| `list_transactions`     | List all transactions                                               |

### Shipment tracking

| Tool                       | Description                                                   |
| -------------------------- | ------------------------------------------------------------- |
| `create_shipment_tracking` | Create shipment tracking information for a PayPal transaction |
| `get_shipment_tracking`    | Get shipment tracking information for a specific shipment     |
| `update_shipment_tracking` | Update shipment tracking information for a specific shipment  |

### Subscription management

| Tool                             | Description                                  |
| -------------------------------- | -------------------------------------------- |
| `cancel_subscription`            | Cancel an active subscription                |
| `create_subscription`            | Create a new subscription                    |
| `create_subscription_plan`       | Create a new subscription plan               |
| `update_subscription`            | Update an existing subscription              |
| `list_subscription_plans`        | List subscription plans                      |
| `show_subscription_details`      | Show details of a specific subscription      |
| `show_subscription_plan_details` | Show details of a specific subscription plan |

## Configuration

You can control which tools are enabled using the `--tools` command-line argument. This is useful for limiting the scope of the agent's permissions.

You can enable all tools with `--tools=all` or specify a comma-separated list of specific tool identifiers.

**Note**: The configuration identifiers below use dot notation (e.g., `invoices.create`) which differs from the tool names exposed to the agent (e.g., `create_invoice`).

**Products**: `products.create`, `products.list`, `products.update`, `products.show`

**Disputes**: `disputes.list`, `disputes.get`, `disputes.create`

**Invoices**: `invoices.create`, `invoices.list`, `invoices.get`, `invoices.send`, `invoices.sendReminder`, `invoices.cancel`, `invoices.generateQRC`

**Orders & Payments**: `orders.create`, `orders.get`, `orders.capture`, `payments.createRefund`, `payments.getRefunds`

**Transactions**: `transactions.list`

**Shipment**: `shipment.create`, `shipment.get`

**Subscriptions**: `subscriptionPlans.create`, `subscriptionPlans.list`, `subscriptionPlans.show`, `subscriptions.create`, `subscriptions.show`, `subscriptions.cancel`

## Additional resources

- [PayPal MCP Server Documentation](https://docs.paypal.ai/developer/tools/ai/mcp-quickstart)
- [PayPal MCP Server Repository](https://github.com/paypal/paypal-mcp-server)
- [PayPal Agent Tools Reference](https://docs.paypal.ai/developer/tools/ai/agent-tools-ref)

# Phoenix observability for ADK

Supported in ADKPython

[Phoenix](https://arize.com/docs/phoenix) is an open-source, self-hosted observability platform for monitoring, debugging, and improving LLM applications and AI Agents at scale. It provides comprehensive tracing and evaluation capabilities for your Google ADK applications. To get started, sign up for a [free account](https://phoenix.arize.com/).

## Overview

Phoenix can automatically collect traces from Google ADK using [OpenInference instrumentation](https://github.com/Arize-ai/openinference/tree/main/python/instrumentation/openinference-instrumentation-google-adk), allowing you to:

- **Trace agent interactions** - Automatically capture every agent run, tool call, model request, and response with full context and metadata
- **Evaluate performance** - Assess agent behavior using custom or pre-built evaluators and run experiments to test agent configurations
- **Debug issues** - Analyze detailed traces to quickly identify bottlenecks, failed tool calls, and unexpected agent behavior
- **Self-hosted control** - Keep your data on your own infrastructure

## Installation

### 1. Install Required Packages

```bash
pip install openinference-instrumentation-google-adk google-adk arize-phoenix-otel
```

## Setup

### 1. Launch Phoenix

These instructions show you how to use Phoenix Cloud. You can also [launch Phoenix](https://arize.com/docs/phoenix/integrations/llm-providers/google-gen-ai/google-adk-tracing) in a notebook, from your terminal, or self-host it using a container.

1. Sign up for a [free Phoenix account](https://phoenix.arize.com/).
1. From the Settings page of your new Phoenix Space, create your API key
1. Copy your endpoint which should look like: https://app.phoenix.arize.com/s/[your-space-name]

**Set your Phoenix endpoint and API Key:**

```python
import os

os.environ["PHOENIX_API_KEY"] = "ADD YOUR PHOENIX API KEY"
os.environ["PHOENIX_COLLECTOR_ENDPOINT"] = "ADD YOUR PHOENIX COLLECTOR ENDPOINT"

# If you created your Phoenix Cloud instance before June 24th, 2025, set the API key as a header:
# os.environ["PHOENIX_CLIENT_HEADERS"] = f"api_key={os.getenv('PHOENIX_API_KEY')}"
```

### 2. Connect your application to Phoenix

```python
from phoenix.otel import register

# Configure the Phoenix tracer
tracer_provider = register(
    project_name="my-llm-app",  # Default is 'default'
    auto_instrument=True        # Auto-instrument your app based on installed OI dependencies
)
```

## Observe

Now that you have tracing setup, all Google ADK SDK requests will be streamed to Phoenix for observability and evaluation.

```python
import nest_asyncio
nest_asyncio.apply()

from google.adk.agents import Agent
from google.adk.runners import InMemoryRunner
from google.genai import types

# Define a tool function
def get_weather(city: str) -> dict:
    """Retrieves the current weather report for a specified city.

    Args:
        city (str): The name of the city for which to retrieve the weather report.

    Returns:
        dict: status and result or error msg.
    """
    if city.lower() == "new york":
        return {
            "status": "success",
            "report": (
                "The weather in New York is sunny with a temperature of 25 degrees"
                " Celsius (77 degrees Fahrenheit)."
            ),
        }
    else:
        return {
            "status": "error",
            "error_message": f"Weather information for '{city}' is not available.",
        }

# Create an agent with tools
agent = Agent(
    name="weather_agent",
    model="gemini-flash-latest",
    description="Agent to answer questions using weather tools.",
    instruction="You must use the available tools to find an answer.",
    tools=[get_weather]
)

app_name = "weather_app"
user_id = "test_user"
session_id = "test_session"
runner = InMemoryRunner(agent=agent, app_name=app_name)
session_service = runner.session_service

await session_service.create_session(
    app_name=app_name,
    user_id=user_id,
    session_id=session_id
)

# Run the agent (all interactions will be traced)
async for event in runner.run_async(
    user_id=user_id,
    session_id=session_id,
    new_message=types.Content(role="user", parts=[
        types.Part(text="What is the weather in New York?")]
    )
):
    if event.is_final_response():
        print(event.content.parts[0].text.strip())
```

## Support and Resources

- [Phoenix Documentation](https://arize.com/docs/phoenix/integrations/llm-providers/google-gen-ai/google-adk-tracing)
- [Community Slack](https://arize-ai.slack.com/join/shared_invite/zt-11t1vbu4x-xkBIHmOREQnYnYDH1GDfCg#/shared-invite/email)
- [OpenInference Package](https://github.com/Arize-ai/openinference/tree/main/python/instrumentation/openinference-instrumentation-google-adk)

# Pinecone MCP tool for ADK

Supported in ADKPythonTypeScript

The [Pinecone MCP Server](https://github.com/pinecone-io/pinecone-mcp) connects your ADK agent to [Pinecone](https://www.pinecone.io/), a vector database for AI applications. This integration gives your agent the ability to manage indexes, store and search data using semantic search with metadata filtering, and search across multiple indexes with reranking.

## Use cases

- **Semantic Search and Retrieval**: Search stored data using natural language queries with metadata filtering and reranking.
- **Knowledge Base Management**: Store and manage data to build and maintain retrieval-augmented generation (RAG) systems.
- **Cross-Index Search**: Search across multiple Pinecone indexes simultaneously, with automatic deduplication and reranking of results.

## Prerequisites

- A [Pinecone](https://www.pinecone.io/) account
- An API key from the [Pinecone Console](https://app.pinecone.io)

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

PINECONE_API_KEY = "YOUR_PINECONE_API_KEY"

root_agent = Agent(
    model="gemini-flash-latest",
    name="pinecone_agent",
    instruction="Help users manage and search their Pinecone vector indexes",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "@pinecone-database/mcp",
                    ],
                    env={
                        "PINECONE_API_KEY": PINECONE_API_KEY,
                    }
                ),
                timeout=30,
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const PINECONE_API_KEY = "YOUR_PINECONE_API_KEY";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "pinecone_agent",
    instruction: "Help users manage and search their Pinecone vector indexes",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: ["-y", "@pinecone-database/mcp"],
                env: {
                    PINECONE_API_KEY: PINECONE_API_KEY,
                },
            },
        }),
    ],
});

export { rootAgent };
```

Note

Only indexes with [integrated inference](https://docs.pinecone.io/guides/inference/understanding-inference) are supported. Indexes without an integrated embedding model are not supported by this MCP server.

## Available tools

### Documentation

| Tool          | Description                                |
| ------------- | ------------------------------------------ |
| `search-docs` | Search the official Pinecone documentation |

### Index management

| Tool                     | Description                                                                    |
| ------------------------ | ------------------------------------------------------------------------------ |
| `list-indexes`           | List all Pinecone indexes                                                      |
| `describe-index`         | Describe the configuration of an index                                         |
| `describe-index-stats`   | Get statistics about an index, including record count and available namespaces |
| `create-index-for-model` | Create a new index with an integrated inference model for embedding            |

### Data operations

| Tool               | Description                                                                             |
| ------------------ | --------------------------------------------------------------------------------------- |
| `upsert-records`   | Insert or update records in an index with integrated inference                          |
| `search-records`   | Search for records using a text query with options for metadata filtering and reranking |
| `cascading-search` | Search across multiple indexes, deduplicating and reranking the results                 |
| `rerank-documents` | Rerank a collection of records or text documents using a specialized reranking model    |

## Additional resources

- [Pinecone MCP Server Repository](https://github.com/pinecone-io/pinecone-mcp)
- [Pinecone MCP Documentation](https://docs.pinecone.io/guides/operations/mcp-server)
- [Pinecone Documentation](https://docs.pinecone.io)

# Postman MCP tool for ADK

Supported in ADKPythonTypeScript

The [Postman MCP Server](https://github.com/postmanlabs/postman-mcp-server) connects your ADK agent to the [Postman](https://www.postman.com/) ecosystem. This integration gives your agent the ability to access workspaces, manage collections and environments, evaluate APIs, and automate workflows through natural language interactions.

## Use cases

- **API testing**: Continuously test your APIs using your Postman collections.
- **Collection management**: Create and tag collections, update documentation, add comments, or perform actions across multiple collections without leaving your editor.
- **Workspace and environment management**: Create workspaces and environments, and manage your environment variables.
- **Client code generation**: Generate production-ready client code that consumes APIs following best practices and project conventions.

## Prerequisites

- Create a [Postman account](https://identity.getpostman.com/signup)
- Generate a [Postman API key](https://postman.postman.co/settings/me/api-keys)

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

POSTMAN_API_KEY = "YOUR_POSTMAN_API_KEY"

root_agent = Agent(
    model="gemini-flash-latest",
    name="postman_agent",
    instruction="Help users manage their Postman workspaces and collections",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "@postman/postman-mcp-server",
                        # "--full",  # Use all 100+ tools
                        # "--code",  # Use code generation tools
                        # "--region", "eu",  # Use EU region
                    ],
                    env={
                        "POSTMAN_API_KEY": POSTMAN_API_KEY,
                    },
                ),
                timeout=30,
            ),
        )
    ],
)
```

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams

POSTMAN_API_KEY = "YOUR_POSTMAN_API_KEY"

root_agent = Agent(
    model="gemini-flash-latest",
    name="postman_agent",
    instruction="Help users manage their Postman workspaces and collections",
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url="https://mcp.postman.com/mcp",
                # (Optional) Use "/minimal" for essential tools only
                # (Optional) Use "/code" for code generation tools
                # (Optional) Use "https://mcp.eu.postman.com" for EU region
                headers={
                    "Authorization": f"Bearer {POSTMAN_API_KEY}",
                },
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const POSTMAN_API_KEY = "YOUR_POSTMAN_API_KEY";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "postman_agent",
    instruction: "Help users manage their Postman workspaces and collections",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: [
                    "-y",
                    "@postman/postman-mcp-server",
                    // "--full",  // Use all 100+ tools
                    // "--code",  // Use code generation tools
                    // "--region", "eu",  // Use EU region
                ],
                env: {
                    POSTMAN_API_KEY: POSTMAN_API_KEY,
                },
            },
        }),
    ],
});

export { rootAgent };
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const POSTMAN_API_KEY = "YOUR_POSTMAN_API_KEY";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "postman_agent",
    instruction: "Help users manage their Postman workspaces and collections",
    tools: [
        new MCPToolset({
            type: "StreamableHTTPConnectionParams",
            url: "https://mcp.postman.com/mcp",
            // (Optional) Use "/minimal" for essential tools only
            // (Optional) Use "/code" for code generation tools
            // (Optional) Use "https://mcp.eu.postman.com" for EU region
            transportOptions: {
                requestInit: {
                    headers: {
                        Authorization: `Bearer ${POSTMAN_API_KEY}`,
                    },
                },
            },
        }),
    ],
});

export { rootAgent };
```

## Configuration

Postman offers three tool configurations:

- **Minimal** (default): Essential tools for basic Postman operations. Best for simple modifications to collections, workspaces, or environments.
- **Full**: All available Postman API tools (100+ tools). Ideal for advanced collaboration and enterprise features.
- **Code**: Tools for searching API definitions and generating client code. Perfect for developers who need to consume APIs.

To select a configuration:

- **Local server**: Add `--full` or `--code` to the `args` list.
- **Remote server**: Change the URL path to `/minimal`, `/mcp` (full), or `/code`.

For EU region, use `--region eu` (local) or `https://mcp.eu.postman.com` (remote).

## Additional resources

- [Postman MCP Server on GitHub](https://github.com/postmanlabs/postman-mcp-server)
- [Postman API key settings](https://postman.postman.co/settings/me/api-keys)
- [Postman Learning Center](https://learning.postman.com/)

# Google Cloud Pub/Sub tool for ADK

Supported in ADKPython v1.22.0

The `PubSubToolset` allows agents to interact with [Google Cloud Pub/Sub](https://cloud.google.com/pubsub) service to publish, pull, and acknowledge messages.

## Prerequisites

Before using the `PubSubToolset`, you need to:

1. **Enable the Pub/Sub API** in your Google Cloud project.
1. **Authenticate and authorize**: Ensure that the principal (e.g., user, service account) running the agent has the necessary IAM permissions to perform Pub/Sub operations. For more information on Pub/Sub roles, see the [Pub/Sub access control documentation](https://cloud.google.com/pubsub/docs/access-control).
1. **Create a topic or subscription**: [Create a topic](https://cloud.google.com/pubsub/docs/create-topic) to publish messages and [create a subscription](https://cloud.google.com/pubsub/docs/create-subscription) to receive them.

## Usage

```py
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import asyncio
import os

from google.adk.agents import Agent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.tools.pubsub.config import PubSubToolConfig
from google.adk.tools.pubsub.pubsub_credentials import PubSubCredentialsConfig
from google.adk.tools.pubsub.pubsub_toolset import PubSubToolset
from google.genai import types
import google.auth

# Define constants for this example agent
AGENT_NAME = "pubsub_agent"
APP_NAME = "pubsub_app"
USER_ID = "user1234"
SESSION_ID = "1234"
GEMINI_MODEL = "gemini-2.0-flash"

# Define Pub/Sub tool config.
# You can optionally set the project_id here, or let the agent infer it from context/user input.
tool_config = PubSubToolConfig(project_id=os.getenv("GOOGLE_CLOUD_PROJECT"))

# Uses externally-managed Application Default Credentials (ADC) by default.
# This decouples authentication from the agent / tool lifecycle.
# https://cloud.google.com/docs/authentication/provide-credentials-adc
application_default_credentials, _ = google.auth.default()
credentials_config = PubSubCredentialsConfig(
    credentials=application_default_credentials
)

# Instantiate a Pub/Sub toolset
pubsub_toolset = PubSubToolset(
    credentials_config=credentials_config, pubsub_tool_config=tool_config
)

# Agent Definition
pubsub_agent = Agent(
    model=GEMINI_MODEL,
    name=AGENT_NAME,
    description=(
        "Agent to publish, pull, and acknowledge messages from Google Cloud"
        " Pub/Sub."
    ),
    instruction="""\
        You are a cloud engineer agent with access to Google Cloud Pub/Sub tools.
        You can publish messages to topics, pull messages from subscriptions, and acknowledge messages.
    """,
    tools=[pubsub_toolset],
)

# Session and Runner
session_service = InMemorySessionService()
session = asyncio.run(
    session_service.create_session(
        app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID
    )
)
runner = Runner(
    agent=pubsub_agent, app_name=APP_NAME, session_service=session_service
)


# Agent Interaction
def call_agent(query):
    """
    Helper function to call the agent with a query.
    """
    content = types.Content(role="user", parts=[types.Part(text=query)])
    events = runner.run(user_id=USER_ID, session_id=SESSION_ID, new_message=content)

    print("USER:", query)
    for event in events:
        if event.is_final_response():
            final_response = event.content.parts[0].text
            print("AGENT:", final_response)


call_agent("publish 'Hello World' to 'my-topic'")
call_agent("pull messages from 'my-subscription'")
```

## Tools

The `PubSubToolset` includes the following tools:

### `publish_message`

Publishes a message to a Pub/Sub topic.

| Parameter      | Type             | Description                                                                                              |
| -------------- | ---------------- | -------------------------------------------------------------------------------------------------------- |
| `topic_name`   | `str`            | The name of the Pub/Sub topic (e.g., `projects/my-project/topics/my-topic`).                             |
| `message`      | `str`            | The message content to publish.                                                                          |
| `attributes`   | `dict[str, str]` | (Optional) Attributes to attach to the message.                                                          |
| `ordering_key` | `str`            | (Optional) The ordering key for the message. If you set this parameter, messages are published in order. |

### `pull_messages`

Pulls messages from a Pub/Sub subscription.

| Parameter           | Type   | Description                                                                              |
| ------------------- | ------ | ---------------------------------------------------------------------------------------- |
| `subscription_name` | `str`  | The name of the Pub/Sub subscription (e.g., `projects/my-project/subscriptions/my-sub`). |
| `max_messages`      | `int`  | (Optional) The maximum number of messages to pull. Defaults to `1`.                      |
| `auto_ack`          | `bool` | (Optional) Whether to automatically acknowledge the messages. Defaults to `False`.       |

### `acknowledge_messages`

Acknowledges one or more messages on a Pub/Sub subscription.

| Parameter           | Type        | Description                                                                              |
| ------------------- | ----------- | ---------------------------------------------------------------------------------------- |
| `subscription_name` | `str`       | The name of the Pub/Sub subscription (e.g., `projects/my-project/subscriptions/my-sub`). |
| `ack_ids`           | `list[str]` | A list of acknowledgment IDs to acknowledge.                                             |

# Qdrant MCP tool for ADK

Supported in ADKPythonTypeScript

The [Qdrant MCP Server](https://github.com/qdrant/mcp-server-qdrant) connects your ADK agent to [Qdrant](https://qdrant.tech/), an open-source vector search engine. This integration gives your agent the ability to store and retrieve information using semantic search.

## Use cases

- **Semantic Memory for Agents**: Store conversation context, facts, or learned information that agents can retrieve later using natural language queries.
- **Code Repository Search**: Build a searchable index of code snippets, documentation, and implementation patterns that can be queried semantically.
- **Knowledge Base Retrieval**: Create a retrieval-augmented generation (RAG) system by storing documents and retrieving relevant context for responses.

## Prerequisites

- A running Qdrant instance. You can:
  - Use [Qdrant Cloud](https://cloud.qdrant.io/) (managed service)
  - Run locally with Docker: `docker run -p 6333:6333 qdrant/qdrant`
- (Optional) A Qdrant API key for authentication

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

QDRANT_URL = "http://localhost:6333"  # Or your Qdrant Cloud URL
COLLECTION_NAME = "my_collection"
# QDRANT_API_KEY = "YOUR_QDRANT_API_KEY"

root_agent = Agent(
    model="gemini-flash-latest",
    name="qdrant_agent",
    instruction="Help users store and retrieve information using semantic search",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="uvx",
                    args=["mcp-server-qdrant"],
                    env={
                        "QDRANT_URL": QDRANT_URL,
                        "COLLECTION_NAME": COLLECTION_NAME,
                        # "QDRANT_API_KEY": QDRANT_API_KEY,
                    }
                ),
                timeout=30,
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const QDRANT_URL = "http://localhost:6333"; // Or your Qdrant Cloud URL
const COLLECTION_NAME = "my_collection";
// const QDRANT_API_KEY = "YOUR_QDRANT_API_KEY";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "qdrant_agent",
    instruction: "Help users store and retrieve information using semantic search",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "uvx",
                args: ["mcp-server-qdrant"],
                env: {
                    QDRANT_URL: QDRANT_URL,
                    COLLECTION_NAME: COLLECTION_NAME,
                    // QDRANT_API_KEY: QDRANT_API_KEY,
                },
            },
        }),
    ],
});

export { rootAgent };
```

## Available tools

| Tool           | Description                                                    |
| -------------- | -------------------------------------------------------------- |
| `qdrant-store` | Store information in Qdrant with optional metadata             |
| `qdrant-find`  | Search for relevant information using natural language queries |

## Configuration

The Qdrant MCP server can be configured using environment variables:

| Variable                 | Description                                            | Default                                  |
| ------------------------ | ------------------------------------------------------ | ---------------------------------------- |
| `QDRANT_URL`             | URL of the Qdrant server                               | `None` (required)                        |
| `QDRANT_API_KEY`         | API key for Qdrant Cloud authentication                | `None`                                   |
| `COLLECTION_NAME`        | Name of the collection to use                          | `None`                                   |
| `QDRANT_LOCAL_PATH`      | Path for local persistent storage (alternative to URL) | `None`                                   |
| `EMBEDDING_MODEL`        | Embedding model to use                                 | `sentence-transformers/all-MiniLM-L6-v2` |
| `EMBEDDING_PROVIDER`     | Provider for embeddings (`fastembed` or `ollama`)      | `fastembed`                              |
| `TOOL_STORE_DESCRIPTION` | Custom description for the store tool                  | Default description                      |
| `TOOL_FIND_DESCRIPTION`  | Custom description for the find tool                   | Default description                      |

### Custom tool descriptions

You can customize the tool descriptions to guide the agent's behavior:

```python
env={
    "QDRANT_URL": "http://localhost:6333",
    "COLLECTION_NAME": "code-snippets",
    "TOOL_STORE_DESCRIPTION": "Store code snippets with descriptions. The 'information' parameter should contain a description of what the code does, while the actual code should be in 'metadata.code'.",
    "TOOL_FIND_DESCRIPTION": "Search for relevant code snippets using natural language. Describe the functionality you're looking for.",
}
```

## Additional resources

- [Qdrant MCP Server Repository](https://github.com/qdrant/mcp-server-qdrant)
- [Qdrant Documentation](https://qdrant.tech/documentation/)
- [Qdrant Cloud](https://cloud.qdrant.io/)

# Reflect and Retry plugin for ADK

Supported in ADKPython v1.16.0Go v0.5.0

The Reflect and Retry plugin can help your agent recover from error responses from ADK [Tools](/tools-custom/) and automatically retry the tool request. This plugin intercepts tool failures, provides structured guidance to the AI model for reflection and correction, and retries the operation up to a configurable limit. This plugin can help you build more resilience into your agent workflows, including the following capabilities:

- **Concurrency safe**: Uses locking to safely handle parallel tool executions.
- **Configurable scope**: Tracks failures per-invocation (default) or globally.
- **Granular tracking**: Failure counts are tracked per-tool.
- **Custom error extraction**: Supports detecting errors in normal tool responses.

## Add Reflect and Retry Plugin

Add this plugin to your ADK workflow by adding it to the plugins setting of your ADK project's App object, as shown below:

```python
from google.adk.apps.app import App
from google.adk.plugins import ReflectAndRetryToolPlugin

app = App(
    name="my_app",
    root_agent=root_agent,
    plugins=[
        ReflectAndRetryToolPlugin(max_retries=3),
    ],
)
```

```go
import (
    "google.golang.org/adk/plugin/retryandreflect"
    "google.golang.org/adk/runner"
)

// ... create rootAgent and sessionService ...

r, err := runner.New(runner.Config{
    AppName:        "my_app",
    Agent:          rootAgent,
    SessionService: sessionService,
    PluginConfig: runner.PluginConfig{
        Plugins: []*plugin.Plugin{
            retryandreflect.MustNew(retryandreflect.WithMaxRetries(3)),
        },
    },
})
```

With this configuration, if any tool called by an agent returns an error, the request is updated and tried again, up to a maximum of 3 attempts, per tool.

## Configuration settings

The Reflect and Retry Plugin has the following configuration options:

- **`max_retries`**: (optional) Total number of additional attempts the system makes to receive a non-error response. Default value is 3.
- **`throw_exception_if_retry_exceeded`**: (optional) If set to `False`, the system does not raise an error if the final retry attempt fails. Default value is `True`.
- **`tracking_scope`**: (optional)
  - **`TrackingScope.INVOCATION`**: Track tool failures across a single invocation and user. This value is the default.
  - **`TrackingScope.GLOBAL`**: Track tool failures across all invocations and all users.

### Advanced configuration

You can further modify the behavior of this plugin by extending the `ReflectAndRetryToolPlugin` class. The following code sample demonstrates a simple extension of the behavior by selecting responses with an error status:

```python
class CustomRetryPlugin(ReflectAndRetryToolPlugin):
  async def extract_error_from_result(self, *, tool, tool_args,tool_context,
  result):
    # Detect error based on response content
    if result.get('status') == 'error':
        return result
    return None  # No error detected

# add this modified plugin to your App object:
error_handling_plugin = CustomRetryPlugin(max_retries=5)
```

## Next steps

For complete code samples using the Reflect and Retry plugin, see the following:

- [Basic](https://github.com/google/adk-python/tree/main/contributing/samples/plugin_reflect_tool_retry/basic) code sample
- [Hallucinating function name](https://github.com/google/adk-python/tree/main/contributing/samples/plugin_reflect_tool_retry/hallucinating_func_name) code sample

# Restate plugin for ADK

Supported in ADKPython

[Restate](https://restate.dev) is a durable execution engine that turns ADK agents into innately resilient, robust systems. It provides persistent sessions, pause/resume for human approvals, resilient multi-agent orchestration, safe versioning, and full observability and control over every execution. All LLM calls and tool executions are journaled, so if anything fails, your agent recovers from exactly where it left off.

## Use cases

The Restate plugin gives your agents:

- **Durable execution**: Never lose progress. If your agent crashes, it picks up exactly where it left off, with automatic retries and recovery.
- **Pause/resume for human-in-the-loop**: Pause execution for days or weeks until a human approves, then resume where you left off.
- **Durable state**: Agent memory and conversation history persist across restarts with built-in session management.
- **Observability & Task control**: See exactly what your agent did and kill, pause, and resume agent executions at any time.
- **Resilient multi-agent orchestration**: Run resilient workflows across multiple agents with parallel execution.
- **Safe versioning**: Deploy new versions without breaking ongoing executions via immutable deployments.

## Prerequisites

- Python 3.12+
- A [Gemini API key](https://aistudio.google.com/app/api-keys)

To run the example below, you'll also need:

- [uv](https://docs.astral.sh/uv/) (Python package manager)
- [Docker](https://docs.docker.com/get-docker/) (or [Brew/npm/binary](https://docs.restate.dev/develop/local_dev#running-restate-server--cli-locally) for the Restate server)

## Installation

Install the Restate SDK for Python:

```bash
pip install "restate-sdk[serde]"
```

## Use with agent

Follow these steps to run a durable agent and inspect its execution journal in the Restate UI:

1. **Clone the [restate-google-adk-example repository](https://github.com/restatedev/restate-google-adk-example) and navigate to the example**

   ```bash
   git clone https://github.com/restatedev/restate-google-adk-example.git
   cd restate-google-adk-example/examples/hello-world
   ```

1. **Export your Gemini API key**

   ```bash
   export GOOGLE_API_KEY=your-api-key
   ```

1. **Start the weather agent**

   ```bash
   uv run .
   ```

1. **Start Restate in another terminal**

   ```bash
   docker run --name restate --rm -p 8080:8080 -p 9070:9070 -d \
     --add-host host.docker.internal:host-gateway \
     docker.restate.dev/restatedev/restate:latest
   ```

   Other installation methods: [Brew, npm, binary downloads](https://docs.restate.dev/develop/local_dev#running-restate-server--cli-locally)

1. **Register the agent**

   Open the Restate UI at `localhost:9070` and register your agent deployment (e.g., `http://host.docker.internal:9080`):

   Safe versioning

   Restate registers each deployment as an immutable snapshot. When you deploy a new version, ongoing executions finish on the original deployment while new requests route to the latest one. Learn more about [version-aware routing](https://docs.restate.dev/services/versioning).

1. **Send a request to the agent**

   In the Restate UI, select **WeatherAgent**, open the **Playground**, and send a request:

   Durable sessions and retries

   This request goes through Restate, which persists it before forwarding to your agent. Each session (here `session-1`) is isolated, stateful, and durable. If the agent crashes mid-execution, Restate automatically retries and resumes from the last journaled step, without losing progress.

1. **Inspect the execution journal**

   Click on the **Invocations** tab and then on your invocation to see the execution journal:

   Full control over agent executions

   Every LLM call and tool execution is recorded in the journal. From the UI, you can pause, resume, restart from any intermediate step, or kill an execution. Check the **State** tab to inspect your agent's current session data.

## Capabilities

The Restate plugin provides the following capabilities for your ADK agents:

| Capability                | Description                                                                                                 |
| ------------------------- | ----------------------------------------------------------------------------------------------------------- |
| Durable tool execution    | Wraps tool logic with `restate_object_context().run_typed()` so it retries and recovers automatically       |
| Human-in-the-loop         | Pauses execution with `restate_object_context().awakeable()` until an external signal (e.g. human approval) |
| Persistent sessions       | `RestateSessionService()` stores agent memory and conversation state durably                                |
| Durable LLM calls         | `RestatePlugin()` journals LLM calls with automatic retries                                                 |
| Multi-agent communication | Durable cross-agent HTTP calls with `restate_object_context().service_call()`                               |
| Parallel execution        | Run tools and agents concurrently with `restate.gather()` for deterministic recovery                        |

## Additional resources

- [Restate ADK example repository](https://github.com/restatedev/restate-google-adk-example) - Runnable examples including claims processing with human approval
- [Restate ADK tutorial](https://docs.restate.dev/tour/google-adk) - Walkthrough of agent development with Restate and ADK
- [Restate AI documentation](https://docs.restate.dev/ai) - Full reference for durable AI agent patterns
- [Restate SDK on PyPI](https://pypi.org/project/restate-sdk/) - Python package

# Google Cloud Spanner tool for ADK

Supported in ADKPython v1.11.0

These are a set of tools aimed to provide integration with Spanner, namely:

- **`list_table_names`**: Fetches table names present in a GCP Spanner database.
- **`list_table_indexes`**: Fetches table indexes present in a GCP Spanner database.
- **`list_table_index_columns`**: Fetches table index columns present in a GCP Spanner database.
- **`list_named_schemas`**: Fetches named schema for a Spanner database.
- **`get_table_schema`**: Fetches Spanner database table schema and metadata information.
- **`execute_sql`**: Runs a SQL query in Spanner database and fetch the result.
- **`similarity_search`**: Similarity search in Spanner using a text query.

They are packaged in the toolset `SpannerToolset`.

```py
# Copyright 2025 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import asyncio

from google.adk.agents import Agent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
# from google.adk.sessions import DatabaseSessionService
from google.adk.tools.google_tool import GoogleTool
from google.adk.tools.spanner import query_tool
from google.adk.tools.spanner.settings import SpannerToolSettings
from google.adk.tools.spanner.settings import Capabilities
from google.adk.tools.spanner.spanner_credentials import SpannerCredentialsConfig
from google.adk.tools.spanner.spanner_toolset import SpannerToolset
from google.genai import types
from google.adk.tools.tool_context import ToolContext
import google.auth
from google.auth.credentials import Credentials

# Define constants for this example agent
AGENT_NAME = "spanner_agent"
APP_NAME = "spanner_app"
USER_ID = "user1234"
SESSION_ID = "1234"
GEMINI_MODEL = "gemini-2.5-flash"

# Define Spanner tool config with read capability set to allowed.
tool_settings = SpannerToolSettings(capabilities=[Capabilities.DATA_READ])

# Define a credentials config - in this example we are using application default
# credentials
# https://cloud.google.com/docs/authentication/provide-credentials-adc
application_default_credentials, _ = google.auth.default()
credentials_config = SpannerCredentialsConfig(
    credentials=application_default_credentials
)

# Instantiate a Spanner toolset
spanner_toolset = SpannerToolset(
    credentials_config=credentials_config, spanner_tool_settings=tool_settings
)

# Optional
# Create a wrapped function tool for the agent on top of the built-in
# `execute_sql` tool in the Spanner toolset.
# For example, this customized tool can perform a dynamically-built query.
def count_rows_tool(
    table_name: str,
    credentials: Credentials,  # GoogleTool handles `credentials`
    settings: SpannerToolSettings,  # GoogleTool handles `settings`
    tool_context: ToolContext,  # GoogleTool handles `tool_context`
):
  """Counts the total number of rows for a specified table.

  Args:
    table_name: The name of the table for which to count rows.

  Returns:
      The total number of rows in the table.
  """

  # Replace the following settings for a specific Spanner database.
  PROJECT_ID = "<PROJECT_ID>"
  INSTANCE_ID = "<INSTANCE_ID>"
  DATABASE_ID = "<DATABASE_ID>"

  query = f"""
  SELECT count(*) FROM {table_name}
    """

  return query_tool.execute_sql(
      project_id=PROJECT_ID,
      instance_id=INSTANCE_ID,
      database_id=DATABASE_ID,
      query=query,
      credentials=credentials,
      settings=settings,
      tool_context=tool_context,
  )

# Agent Definition
spanner_agent = Agent(
    model=GEMINI_MODEL,
    name=AGENT_NAME,
    description=(
        "Agent to answer questions about Spanner database and execute SQL queries."
    ),
    instruction="""\
        You are a data assistant agent with access to several Spanner tools.
        Make use of those tools to answer the user's questions.
    """,
    tools=[
        spanner_toolset,
        # Add customized Spanner tool based on the built-in Spanner toolset.
        GoogleTool(
            func=count_rows_tool,
            credentials_config=credentials_config,
            tool_settings=tool_settings,
        ),
    ],
)


# Session and Runner
session_service = InMemorySessionService()

# Optionally, Spanner can be used as the Database Session Service for production.
# Note that it's suggested to use a dedicated instance/database for storing sessions.
# session_service_spanner_db_url = "spanner+spanner:///projects/PROJECT_ID/instances/INSTANCE_ID/databases/my-adk-session"
# session_service = DatabaseSessionService(db_url=session_service_spanner_db_url)

session = asyncio.run(
    session_service.create_session(
        app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID
    )
)
runner = Runner(
    agent=spanner_agent, app_name=APP_NAME, session_service=session_service
)


# Agent Interaction
def call_agent(query):
    """
    Helper function to call the agent with a query.
    """
    content = types.Content(role="user", parts=[types.Part(text=query)])
    events = runner.run(user_id=USER_ID, session_id=SESSION_ID, new_message=content)

    print("USER:", query)
    for event in events:
        if event.is_final_response():
            final_response = event.content.parts[0].text
            print("AGENT:", final_response)

# Replace the Spanner database and table names below with your own.
call_agent("List all tables in projects/<PROJECT_ID>/instances/<INSTANCE_ID>/databases/<DATABASE_ID>")
call_agent("Describe the schema of <TABLE_NAME>")
call_agent("List the top 5 rows in <TABLE_NAME>")
```

# StackOne plugin for ADK

Supported in ADKPython

The [StackOne ADK Plugin](https://github.com/StackOneHQ/stackone-adk-plugin) connects your ADK agent to hundreds of providers through [StackOne's](https://stackone.com) unified AI Integration gateway. Instead of manually defining tool functions for each API, this plugin dynamically discovers available tools from your connected providers and exposes them as native tools in ADK. It supports Human Resources Information Systems (HRIS), Applicant Tracking Systems (ATS), Customer Relationship Management (CRM), productivity and scheduling tools, and many more [integrations](https://www.stackone.com/connectors).

## Use cases

- **Sales and Revenue Operations**: Build agents that find leads in your CRM (e.g. HubSpot, Salesforce), enrich contact data, draft personalized outreach, and log activity back — all within one conversation.
- **People Operations**: Create agents that screen candidates in your ATS (e.g. Greenhouse, Ashby), check availability in your calendar tool (e.g. Google Calendar, Calendly), collect interview scorecards, move applicants through pipeline stages, and automate onboarding into your HRIS (e.g. BambooHR, Workday) — covering the full employee lifecycle without manual intervention.
- **Marketing Automation**: Build campaign agents that sync audience segments from your CRM to your email platform (e.g. Mailchimp, Klaviyo), trigger email sequences, and report on engagement metrics across channels.
- **Product Delivery**: Create agents that triage incoming feedback from your support tools (e.g. Intercom, Zendesk, Slack), prioritize and create issues in your project management tool (e.g. Linear, Jira), and resolve incidents using insights from an observability platform (e.g. PagerDuty, Datadog) — uniting product research, delivery, and reliability in a single workflow.

## Prerequisites

- A [StackOne account](https://app.stackone.com) with at least one connected provider
- A StackOne API key from the [StackOne Dashboard](https://app.stackone.com)
- A [Gemini API key](https://aistudio.google.com/apikey)

## Installation

```bash
pip install stackone-adk
```

Or with uv:

```bash
uv add stackone-adk
```

## Use with agent

Environment variables

Set your API keys as environment variables before running the examples below:

```bash
export STACKONE_API_KEY="your-stackone-api-key"
export GOOGLE_API_KEY="your-google-api-key"
```

Once `STACKONE_API_KEY` is set, the plugin automatically reads it and discovers your connected accounts.

```python
import asyncio

from google.adk.agents import Agent
from google.adk.apps import App
from google.adk.runners import InMemoryRunner
from stackone_adk import StackOnePlugin


async def main():
    plugin = StackOnePlugin()
    # Or scope to a specific account:
    # plugin = StackOnePlugin(account_id="YOUR_ACCOUNT_ID")

    tools = plugin.get_tools()
    print(f"Discovered {len(tools)} tools")

    agent = Agent(
        model="gemini-flash-latest",
        name="scheduling_agent",
        description="Manages scheduling, HR, and CRM through StackOne.",
        instruction=(
            "You are a helpful assistant powered by StackOne. "
            "You help users manage their scheduling, HR, and CRM tasks "
            "by using the available tools.\n\n"
            "Always be helpful and provide clear, organized responses."
        ),
        tools=tools,
    )

    app = App(
        name="scheduling_app",
        root_agent=agent,
        plugins=[plugin],
    )

    async with InMemoryRunner(app=app) as runner:
        events = await runner.run_debug(
            "Get my most recent scheduled meeting from Calendly.",
            quiet=True,
        )
        # Extract the agent's final text response
        for event in reversed(events):
            if event.content and event.content.parts:
                text_parts = [p.text for p in event.content.parts if p.text]
                if text_parts:
                    print("".join(text_parts))
                    break


asyncio.run(main())
```

```python
import asyncio

from google.adk.agents import Agent
from google.adk.runners import InMemoryRunner
from stackone_adk import StackOnePlugin


async def main():
    plugin = StackOnePlugin()
    # Or scope to a specific account:
    # plugin = StackOnePlugin(account_id="YOUR_ACCOUNT_ID")

    tools = plugin.get_tools()
    print(f"Discovered {len(tools)} tools")

    agent = Agent(
        model="gemini-flash-latest",
        name="scheduling_agent",
        description="Manages scheduling, HR, and CRM through StackOne.",
        instruction=(
            "You are a helpful assistant powered by StackOne. "
            "You help users manage their scheduling, HR, and CRM tasks "
            "by using the available tools.\n\n"
            "Always be helpful and provide clear, organized responses."
        ),
        tools=tools,
    )

    async with InMemoryRunner(
        app_name="scheduling_app", agent=agent
    ) as runner:
        events = await runner.run_debug(
            "Get my most recent scheduled meeting from Calendly.",
            quiet=True,
        )
        # Extract the agent's final text response
        for event in reversed(events):
            if event.content and event.content.parts:
                text_parts = [p.text for p in event.content.parts if p.text]
                if text_parts:
                    print("".join(text_parts))
                    break


asyncio.run(main())
```

## Search and execute mode

With `mode="search_and_execute"`, the plugin registers exactly two tools, `tool_search` and `tool_execute`. The model uses them at runtime to discover the right StackOne tool and invoke it, instead of seeing the full catalog upfront.

Registering every tool definition with the model has three costs:

- **Token overhead:** Tool schemas consume prompt tokens that could otherwise be available for reasoning.
- **Payload limits:** Large catalogs can exceed provider payload limits. Gemini, for example, imposes hard limits on the size and number of function declarations per request.
- **Selection accuracy:** Tool-selection quality degrades as the tool candidate set grows, since the model has more near-duplicates to disambiguate.

This mode keeps the registered tool count at two regardless of catalog size. The model resolves the right tool through a natural-language query at runtime.

This mode requires `stackone-adk>=0.2.0`.

```python
import asyncio

from google.adk.agents import Agent
from google.adk.apps import App
from google.adk.runners import InMemoryRunner
from stackone_adk import StackOnePlugin


async def main():
    plugin = StackOnePlugin(
        mode="search_and_execute",
        account_ids=["YOUR_ACCOUNT_ID"],
        search={"method": "auto", "top_k": 10},
    )

    agent = Agent(
        model="gemini-flash-latest",
        name="stackone_agent",
        description="Connects to multiple SaaS providers through StackOne.",
        instruction=(
            "You are an assistant powered by StackOne. To answer the "
            "user's request, first call tool_search with a short query "
            "to find the right action, then call tool_execute with the "
            "chosen tool name and parameters that match the schema "
            "returned by tool_search."
        ),
        tools=plugin.get_tools(),
    )

    app = App(
        name="stackone_app",
        root_agent=agent,
        plugins=[plugin],
    )

    async with InMemoryRunner(app=app) as runner:
        events = await runner.run_debug(
            "List the first 3 workers.",
            quiet=True,
        )
        for event in reversed(events):
            if event.content and event.content.parts:
                text_parts = [p.text for p in event.content.parts if p.text]
                if text_parts:
                    print("".join(text_parts))
                    break


asyncio.run(main())
```

The model first calls `tool_search` with a natural-language query and receives a short list of candidate tools, each with its name, description, and parameter schema. The model then calls `tool_execute` with the selected tool name and parameters that match the schema. Both calls route through StackOne's AI Integration Gateway via the SDK.

## Available tools

Unlike integrations with a fixed set of tools, StackOne tools are **dynamically discovered** from your connected providers via the StackOne API. The available tools depend on which SaaS providers you have connected in your [StackOne Dashboard](https://app.stackone.com).

To list discovered tools:

```python
plugin = StackOnePlugin(account_id="YOUR_ACCOUNT_ID") # Optional: omit to use all connected accounts
for tool in plugin.get_tools():
    print(f"{tool.name}: {tool.description}")
```

### Supported integration categories

| Category            | Example providers                                               |
| ------------------- | --------------------------------------------------------------- |
| HRIS                | HiBob, BambooHR, Workday, SAP SuccessFactors, Personio, Gusto   |
| ATS                 | Greenhouse, Ashby, Lever, Bullhorn, SmartRecruiters, Teamtailor |
| CRM & Sales         | Salesforce, HubSpot, Pipedrive, Zoho CRM, Close, Copper         |
| Marketing           | Mailchimp, Klaviyo, ActiveCampaign, Brevo, GetResponse          |
| Ticketing & Support | Zendesk, Freshdesk, Jira, ServiceNow, PagerDuty, Linear         |
| Productivity        | Asana, ClickUp, Slack, Microsoft Teams, Notion, Confluence      |
| Scheduling          | Calendly, Cal.com                                               |
| LMS & Learning      | 360Learning, Docebo, Go1, Cornerstone, LinkedIn Learning        |
| Commerce            | Shopify, BigCommerce, WooCommerce, Etsy                         |
| Developer Tools     | GitHub, GitLab, Twilio                                          |

For a complete list of 200+ supported providers, visit the [StackOne integrations page](https://www.stackone.com/connectors).

## Configuration

### Plugin parameters

| Parameter     | Type                            | Default             | Description                                                                                                         |
| ------------- | ------------------------------- | ------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `api_key`     | \`str                           | None\`              | `None`                                                                                                              |
| `account_id`  | \`str                           | None\`              | `None`                                                                                                              |
| `base_url`    | \`str                           | None\`              | `None`                                                                                                              |
| `plugin_name` | `str`                           | `"stackone_plugin"` | Plugin identifier for ADK.                                                                                          |
| `providers`   | \`list[str]                     | None\`              | `None`                                                                                                              |
| `actions`     | \`list[str]                     | None\`              | `None`                                                                                                              |
| `account_ids` | \`list[str]                     | None\`              | `None`                                                                                                              |
| `mode`        | \`Literal["search_and_execute"] | None\`              | `None`                                                                                                              |
| `search`      | \`SearchConfig                  | None\`              | `None`                                                                                                              |
| `execute`     | \`ExecuteToolsConfig            | None\`              | `None`                                                                                                              |
| `timeout`     | `float`                         | `180.0`             | Per-request timeout in seconds for HTTP calls (account discovery and tool execution). Increase for slow connectors. |

### Tool filtering

Filter tools by provider, action pattern, account ID, or any combination:

```python
# Specify accounts
plugin = StackOnePlugin(account_ids=["acct-hibob-1", "acct-bamboohr-1"])

# Read-only operations
plugin = StackOnePlugin(actions=["*_list_*", "*_get_*"])

# Specific actions with glob patterns
plugin = StackOnePlugin(actions=["calendly_list_events", "calendly_get_event_*"])

# Combined filters
plugin = StackOnePlugin(
    actions=["*_list_*", "*_get_*"],
    account_ids=["acct-hibob-1"],
)
```

## Additional resources

- [StackOne ADK Plugin Repository](https://github.com/StackOneHQ/stackone-adk-plugin)
- [StackOne Documentation](https://docs.stackone.com/)
- [StackOne Dashboard](https://app.stackone.com)
- [StackOne Python AI SDK](https://github.com/StackOneHQ/stackone-ai-python)

# Stripe MCP tool for ADK

Supported in ADKPythonTypeScript

The [Stripe MCP Server](https://docs.stripe.com/mcp) connects your ADK agent to the [Stripe](https://stripe.com/) ecosystem. This integration gives your agent the ability to manage payments, customers, subscriptions, and invoices using natural language, enabling automated commerce workflows and financial operations.

## Use cases

- **Automate Payment Operations**: Create payment links, process refunds, and list payment intents through conversational commands.
- **Streamline Invoicing**: Generate and finalize invoices, add line items, and track outstanding payments without leaving your development environment.
- **Access Business Insights**: Query account balances, list products and prices, and search across Stripe resources to make data-driven decisions.

## Prerequisites

- Create a [Stripe account](https://dashboard.stripe.com/register)
- Generate a [Restricted API key](https://dashboard.stripe.com/apikeys) from the Stripe Dashboard

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters

STRIPE_SECRET_KEY = "YOUR_STRIPE_SECRET_KEY"

root_agent = Agent(
    model="gemini-flash-latest",
    name="stripe_agent",
    instruction="Help users manage their Stripe account",
    tools=[
        McpToolset(
            connection_params=StdioConnectionParams(
                server_params=StdioServerParameters(
                    command="npx",
                    args=[
                        "-y",
                        "@stripe/mcp",
                        "--tools=all",
                        # (Optional) Specify which tools to enable
                        # "--tools=customers.read,invoices.read,products.read",
                    ],
                    env={
                        "STRIPE_SECRET_KEY": STRIPE_SECRET_KEY,
                    }
                ),
                timeout=30,
            ),
        )
    ],
)
```

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams

STRIPE_SECRET_KEY = "YOUR_STRIPE_SECRET_KEY"

root_agent = Agent(
    model="gemini-flash-latest",
    name="stripe_agent",
    instruction="Help users manage their Stripe account",
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url="https://mcp.stripe.com",
                headers={
                    "Authorization": f"Bearer {STRIPE_SECRET_KEY}",
                },
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const STRIPE_SECRET_KEY = "YOUR_STRIPE_SECRET_KEY";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "stripe_agent",
    instruction: "Help users manage their Stripe account",
    tools: [
        new MCPToolset({
            type: "StdioConnectionParams",
            serverParams: {
                command: "npx",
                args: [
                    "-y",
                    "@stripe/mcp",
                    "--tools=all",
                    // (Optional) Specify which tools to enable
                    // "--tools=customers.read,invoices.read,products.read",
                ],
                env: {
                    STRIPE_SECRET_KEY: STRIPE_SECRET_KEY,
                },
            },
        }),
    ],
});

export { rootAgent };
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const STRIPE_SECRET_KEY = "YOUR_STRIPE_SECRET_KEY";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "stripe_agent",
    instruction: "Help users manage their Stripe account",
    tools: [
        new MCPToolset({
            type: "StreamableHTTPConnectionParams",
            url: "https://mcp.stripe.com",
            transportOptions: {
                requestInit: {
                    headers: {
                        Authorization: `Bearer ${STRIPE_SECRET_KEY}`,
                    },
                },
            },
        }),
    ],
});

export { rootAgent };
```

Best practices

Enable human confirmation of tool actions and exercise caution when using the Stripe MCP server alongside other MCP servers to mitigate prompt injection risks.

## Available tools

| Resource      | Tool                          | API                     |
| ------------- | ----------------------------- | ----------------------- |
| Account       | `get_stripe_account_info`     | Retrieve account        |
| Balance       | `retrieve_balance`            | Retrieve balance        |
| Coupon        | `create_coupon`               | Create coupon           |
| Coupon        | `list_coupons`                | List coupons            |
| Customer      | `create_customer`             | Create customer         |
| Customer      | `list_customers`              | List customers          |
| Dispute       | `list_disputes`               | List disputes           |
| Dispute       | `update_dispute`              | Update dispute          |
| Invoice       | `create_invoice`              | Create invoice          |
| Invoice       | `create_invoice_item`         | Create invoice item     |
| Invoice       | `finalize_invoice`            | Finalize invoice        |
| Invoice       | `list_invoices`               | List invoices           |
| Payment Link  | `create_payment_link`         | Create payment link     |
| PaymentIntent | `list_payment_intents`        | List PaymentIntents     |
| Price         | `create_price`                | Create price            |
| Price         | `list_prices`                 | List prices             |
| Product       | `create_product`              | Create product          |
| Product       | `list_products`               | List products           |
| Refund        | `create_refund`               | Create refund           |
| Subscription  | `cancel_subscription`         | Cancel subscription     |
| Subscription  | `list_subscriptions`          | List subscriptions      |
| Subscription  | `update_subscription`         | Update subscription     |
| Others        | `search_stripe_resources`     | Search Stripe resources |
| Others        | `fetch_stripe_resources`      | Fetch Stripe object     |
| Others        | `search_stripe_documentation` | Search Stripe knowledge |

## Additional resources

- [Stripe MCP Server Documentation](https://docs.stripe.com/mcp)
- [Stripe MCP Server on GitHub](https://github.com/stripe/ai/tree/main/tools/modelcontextprotocol)
- [Build on Stripe with LLMs](https://docs.stripe.com/building-with-llms)
- [Add Stripe to your agentic workflows](https://docs.stripe.com/agents)

# Supermetrics MCP tool for ADK

Supported in ADKPythonTypeScript

The [Supermetrics MCP Server](https://mcp.supermetrics.com) connects your ADK agent to the [Supermetrics](https://supermetrics.com/) platform, giving it access to marketing data across 100+ sources including Google Ads, Meta Ads, LinkedIn Ads, and Google Analytics 4. Your agent can discover data sources, explore available metrics, and run queries against your connected accounts using natural language.

## Use cases

- **Marketing Performance Reporting**: Query impressions, clicks, spend, and conversions across campaigns and time periods. Build automated reports that aggregate data from multiple platforms in a single response.
- **Cross-Platform Analysis**: Compare performance across Google Ads, Meta Ads, LinkedIn Ads, and other channels side by side, using a consistent query interface regardless of the underlying platform.
- **Campaign Monitoring**: Retrieve up-to-date metrics for active campaigns and ad accounts, enabling agents to surface anomalies, track pacing, or summarize daily performance.
- **Data Exploration**: Discover which data sources, accounts, and fields are available to a given user before building a query, so agents can adapt dynamically to each user's connected integrations.

## Prerequisites

- Create a [Supermetrics account](https://supermetrics.com/) (a 14-day free trial is created automatically on first login)
- Generate an API key from the [Supermetrics Hub](https://hub.supermetrics.com/)

## Use with agent

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset, StreamableHTTPConnectionParams

SUPERMETRICS_API_KEY = "YOUR_SUPERMETRICS_API_KEY"

root_agent = Agent(
    model="gemini-flash-latest",
    name="supermetrics_agent",
    instruction="Help users query and analyze their marketing data from Supermetrics",
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url="https://mcp.supermetrics.com/mcp",
                headers={
                    "Authorization": f"Bearer {SUPERMETRICS_API_KEY}",
                },
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const SUPERMETRICS_API_KEY = "YOUR_SUPERMETRICS_API_KEY";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "supermetrics_agent",
    instruction: "Help users query and analyze their marketing data from Supermetrics",
    tools: [
        new MCPToolset({
            type: "StreamableHTTPConnectionParams",
            url: "https://mcp.supermetrics.com/mcp",
            transportOptions: {
                requestInit: {
                    headers: {
                        Authorization: `Bearer ${SUPERMETRICS_API_KEY}`,
                    },
                },
            },
        }),
    ],
});

export { rootAgent };
```

Query workflow

Data retrieval follows a multi-step workflow: on a user request, first fetch the current date with `get_today`. Next discover a data source with `data_source_discovery`, find connected accounts with `accounts_discovery`, inspect available fields with `field_discovery`, submit a query with `data_query`, then poll `get_async_query_results` with the returned `schedule_id` until results are ready.

## Available tools

| Tool                      | Description                                                                      |
| ------------------------- | -------------------------------------------------------------------------------- |
| `data_source_discovery`   | List available marketing data sources (Google Ads, Meta Ads, etc.) and their IDs |
| `accounts_discovery`      | Discover connected accounts for a specific data source                           |
| `field_discovery`         | Explore available metrics and dimensions for a data source                       |
| `data_query`              | Submit a data query; returns a `schedule_id` for async result retrieval          |
| `get_async_query_results` | Poll for and retrieve the results of a submitted query by `schedule_id`          |
| `user_info`               | Retrieve the authenticated user's profile, team information, and license status  |
| `get_today`               | Get the current date in formats suitable for query date range parameters         |

## Additional resources

- [Supermetrics Hub](https://hub.supermetrics.com/)
- [Supermetrics Knowledge Base](https://docs.supermetrics.com/)
- [Data Source Documentation](https://docs.supermetrics.com/docs/connect)
- [OpenAPI Specification](https://mcp.supermetrics.com/openapi.json)

# Temporal plugin for ADK

Supported in ADKPython

[Temporal](https://temporal.io) is a general-purpose durable execution platform that makes ADK agents resilient, scalable, and production-ready. LLM calls and tool executions run as Temporal [Activities](https://docs.temporal.io/activities) with automatic retries and recovery. If anything fails, your agent picks up exactly where it left off - no manual session management or external database required.

## Use cases

The Temporal plugin gives your agents:

- **Durable execution**: Never lose progress. If your agent crashes or stalls, Temporal automatically recovers from the last successful step - no manual [session resumption](/runtime/resume/#resume-a-stopped-workflow) required.
- **Built-in retries and rate limiting**: Configurable [retry policies](https://docs.temporal.io/encyclopedia/retry-policies) with backoff, plus mechanisms for handling backpressure from LLM providers.
- **Long-running and ambient agents**: Support for agents and tools that run for hours, days, or indefinitely using blocking awaits.
- **Human-in-the-loop**: Pause execution until a human approves, then resume where you left off. Temporal's [task routing](https://docs.temporal.io/task-routing) scalably routes incoming signals (such as user chats or approvals) to the correct workflow.
- **Observability and debugging**: Inspect every step of your agent's execution, replay workflows deterministically, and pinpoint failures using the [Temporal UI](https://docs.temporal.io/web-ui).

## Prerequisites

- Python 3.10+
- A [Gemini API key](https://aistudio.google.com/app/api-keys) (or any [supported model](/agents/models/))
- A running Temporal server ([local dev server](https://docs.temporal.io/cli#start-dev-server), [self-hosted](https://docs.temporal.io/self-hosted-guide), or [Temporal Cloud](https://temporal.io/cloud))
- Temporal Python SDK [1.24.0](https://github.com/temporalio/sdk-python/releases/tag/1.24.0)

Note that as of Temporal Python 1.24.0, this integration is experimental and there may be future breaking changes.

## Installation

Install the Temporal Python SDK along with the google-adk extra:

```bash
pip install "temporalio[google-adk]"
```

## Use with agent

### Basic setup

The integration has two sides: the **workflow side** (where your agent runs) and the **worker side** (which hosts the execution environment).

**1. Define your agent and workflow**

Create an ADK agent and wrap it in a Temporal Workflow. Use `TemporalModel` to route LLM calls through Temporal Activities.

```python
from contextlib import aclosing
from datetime import timedelta
from google.adk.agents import Agent
from google.adk.runners import InMemoryRunner
from google.genai import types
from temporalio import activity, workflow
from temporalio.common import RetryPolicy
from temporalio.contrib.google_adk_agents import TemporalModel
from temporalio.contrib.google_adk_agents.workflow import activity_tool
from temporalio.workflow import ActivityConfig

# A Temporal Activity

@activity.defn
async def get_weather(city: str) -> str:
    """Get current weather for a city."""
    # Your weather API call here
    return f"72°F and sunny in {city}"

# Wrap the activity as an ADK tool.  This tool will get memoized, retried, and timed out.
weather_tool = activity_tool(
    get_weather,
    start_to_close_timeout=timedelta(seconds=30),
    retry_policy=RetryPolicy(maximum_attempts=3),
)

# Use your agent
agent = Agent(
    name="weather_agent",
    model=TemporalModel(
      "gemini-flash-latest",
      activity_config=ActivityConfig(summary="Weather Agent")),
    tools=[weather_tool],
)

# Drop your agent in a Workflow to give it durable execution.

@workflow.defn
class WeatherAgentWorkflow:
    @workflow.run
    async def run(self, user_message: str) -> str:
        # For testing; for production, use Runner()
        runner = InMemoryRunner(agent=agent, app_name="weather_app")
        session = await runner.session_service.create_session(
            user_id="user", app_name="weather_app"
        )
        result = ""
        async with aclosing(runner.run_async(
            user_id="user",
            session_id=session.id,
            new_message=types.Content(
                role="user", parts=[types.Part.from_text(text=user_message)]
            ),
        )) as events:
            async for event in events:
                if event.content and event.content.parts:
                    for part in event.content.parts:
                        if part.text:
                            result = part.text
        return result
```

**2. Configure and start the worker**

Use `GoogleAdkPlugin` to configure the worker to make ADK ready to run in a Workflow on a distributed system:

```python
import asyncio
from temporalio.client import Client
from temporalio.worker import Worker
from temporalio.contrib.google_adk_agents import GoogleAdkPlugin

async def main():
    client = await Client.connect(
        "localhost:7233",
        plugins=[GoogleAdkPlugin()]
    )

    worker = Worker(
        client,
        task_queue="my-agent-task-queue",
        workflows=[WeatherAgentWorkflow],
        activities=[get_weather],
    )
    await worker.run()

asyncio.run(main())
```

**3. Start a workflow execution**

```python
import asyncio
from temporalio.client import Client
from temporalio.contrib.google_adk_agents import GoogleAdkPlugin

async def start():
    client = await Client.connect(
        "localhost:7233",
        plugins=[GoogleAdkPlugin()]
    )
    result = await client.execute_workflow(
        WeatherAgentWorkflow.run,
        "What's the weather in San Francisco?",
        id="weather-agent-1",
        task_queue="my-agent-task-queue",
    )
    print(result)

asyncio.run(start())
```

### Using MCP tools

Execute [MCP](/mcp/) tools as Temporal Activities:

```python
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StdioConnectionParams
from mcp import StdioServerParameters
from temporalio.client import Client
from temporalio.contrib.google_adk_agents import (
    GoogleAdkPlugin,
    TemporalModel,
    TemporalMcpToolSet,
    TemporalMcpToolSetProvider,
)

# Define a shared factory for your MCP toolset.
# Both the worker (TemporalMcpToolSetProvider) and agent (TemporalMcpToolSet) use it.
def toolset_factory(_):
    return McpToolset(
        connection_params=StdioConnectionParams(
            server_params=StdioServerParameters(
                command="npx",
                args=["-y", "@modelcontextprotocol/server-filesystem", "/path/to/dir"],
            ),
        ),
    )

# The provider tells the worker how to instantiate the toolset.
toolset_provider = TemporalMcpToolSetProvider("my-tools", toolset_factory)

# Configure the client with the toolset provider
client = await Client.connect(
    "localhost:7233",
    plugins=[GoogleAdkPlugin(toolset_providers=[toolset_provider])]
)

# Reference the toolset by name when you declare your Agent (inside a @workflow.run).
# not_in_workflow_toolset lets this agent also run locally with `adk web`.
agent = Agent(
    name="tool_agent",
    model=TemporalModel("gemini-flash-latest"),
    tools=[TemporalMcpToolSet("my-tools", not_in_workflow_toolset=toolset_factory)],
)
```

### Local development with `adk web`

For ease of local development, the Temporal wrappers automatically fall back to direct execution when run outside a Temporal Workflow, so you can use `adk web` and other ADK development commands without a running Temporal server. You won't get the benefits of durable execution in this mode, nor will you be precisely testing the production behavior.

- `TemporalModel` and `activity_tool` work automatically — they detect they're outside a workflow and call the underlying LLM or function directly.
- `TemporalMcpToolSet` requires the `not_in_workflow_toolset` parameter (shown in the MCP example above) so it knows how to instantiate the toolset locally.

## How it works

The plugin ensures your ADK agent runs deterministically inside Temporal Workflow code, and causes inputs and outputs to be serialized and recorded for robust recovery. For example:

- **LLM calls** are executed as Temporal Activities via `TemporalModel`. If a call fails or the worker crashes, Temporal retries or replays from the last successful step, adding resilience and reducing token spend.
- **Non-deterministic operations** like (`time.time()`, `uuid.uuid4()`) are automatically replaced with Temporal's deterministic equivalents (`workflow.now()`, `workflow.uuid4()`) when run in Workflow code (but not Activity code).
- **ADK and Gemini modules** are configured for Temporal's [sandbox](https://docs.temporal.io/develop/python/best-practices/python-sdk-sandbox) environment with automatic passthrough.
- **Pydantic serialization** is configured automatically for ADK's data types.

## Additional capabilities

| Capability                | Description                                                                                                                                                                                                                                            |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| Durable tool execution    | `activity_tool` wraps tool functions as Activities, supporting long-running tools, automatic retries, and heartbeating                                                                                                                                 |
| MCP tool support          | `TemporalMcpToolSet` executes MCP tools as Activities with full event propagation                                                                                                                                                                      |
| Human-in-the-loop         | Your Agent Workflow can wait for [Signals](https://docs.temporal.io/sending-messages#sending-signals) and [Updates](https://docs.temporal.io/sending-messages#sending-updates) to wait for human input, and clients can send those to resume the Agent |
| Deterministic runtime     | `GoogleAdkPlugin` replaces non-deterministic calls with Temporal-safe equivalents                                                                                                                                                                      |
| Debuggability             | Every LLM call and tool execution is visible as an Activity in the Temporal UI, making it trivial to debug faults.                                                                                                                                     |
| Observability             | Work with your favorite Observability solution using OpenTelemetry, with cross-process spans that are resilient to crashes.                                                                                                                            |
| Safe versioning           | Deploy new agent versions using [Temporal Worker Versioning](https://docs.temporal.io/production-deployment/worker-deployments/worker-versioning) without disrupting in-flight executions                                                              |
| Multi-agent orchestration | Compose multiple agents within a Workflow, or scale them to more complex use cases by using [Child Workflows](https://docs.temporal.io/child-workflows) or [Nexus](https://docs.temporal.io/nexus)                                                     |

## Additional resources

- [Temporal Python SDK documentation](https://docs.temporal.io/develop/python) - Full reference for Temporal's Python SDK
- [Temporal Python SDK on PyPI](https://pypi.org/project/temporalio/) - Python package
- [Temporal Cloud](https://temporal.io/cloud) - Managed Temporal service
- [Orchestrating ambient agents with Temporal](https://temporal.io/blog/orchestrating-ambient-agents-with-temporal) - Blog post on long-running agent patterns

# W&B Weave observability for ADK

Supported in ADKPython

[W&B Weave](https://weave-docs.wandb.ai/) provides a powerful platform for logging and visualizing model calls. By integrating Google ADK with Weave, you can track and analyze your agent's performance and behavior using OpenTelemetry (OTEL) traces.

## Prerequisites

1. Sign up for an account at [WandB](https://wandb.ai).
1. Obtain your API key from [WandB Authorize](https://wandb.ai/authorize).
1. Configure your environment with the required API keys:

```bash
export WANDB_API_KEY=<your-wandb-api-key>
export GOOGLE_API_KEY=<your-google-api-key>
```

## Install Dependencies

Ensure you have the necessary packages installed:

```bash
pip install google-adk opentelemetry-sdk opentelemetry-exporter-otlp-proto-http
```

## Sending Traces to Weave

This example demonstrates how to configure OpenTelemetry to send Google ADK traces to Weave.

```python
# math_agent/agent.py

import base64
import os
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk import trace as trace_sdk
from opentelemetry.sdk.trace.export import SimpleSpanProcessor
from opentelemetry import trace

from google.adk.agents import LlmAgent
from google.adk.tools import FunctionTool

from dotenv import load_dotenv

load_dotenv()

# Configure Weave endpoint and authentication
WANDB_BASE_URL = "https://trace.wandb.ai"
PROJECT_ID = "your-entity/your-project"  # e.g., "teamid/projectid"
OTEL_EXPORTER_OTLP_ENDPOINT = f"{WANDB_BASE_URL}/otel/v1/traces"

# Set up authentication
WANDB_API_KEY = os.getenv("WANDB_API_KEY")
AUTH = base64.b64encode(f"api:{WANDB_API_KEY}".encode()).decode()

OTEL_EXPORTER_OTLP_HEADERS = {
    "Authorization": f"Basic {AUTH}",
    "project_id": PROJECT_ID,
}

# Create the OTLP span exporter with endpoint and headers
exporter = OTLPSpanExporter(
    endpoint=OTEL_EXPORTER_OTLP_ENDPOINT,
    headers=OTEL_EXPORTER_OTLP_HEADERS,
)

# Create a tracer provider and add the exporter
tracer_provider = trace_sdk.TracerProvider()
tracer_provider.add_span_processor(SimpleSpanProcessor(exporter))

# Set the global tracer provider BEFORE importing/using ADK
trace.set_tracer_provider(tracer_provider)

# Define a simple tool for demonstration
def calculator(a: float, b: float) -> str:
    """Add two numbers and return the result.

    Args:
        a: First number
        b: Second number

    Returns:
        The sum of a and b
    """
    return str(a + b)

calculator_tool = FunctionTool(func=calculator)

# Create an LLM agent
root_agent = LlmAgent(
    name="MathAgent",
    model="gemini-flash-latest",
    instruction=(
        "You are a helpful assistant that can do math. "
        "When asked a math problem, use the calculator tool to solve it."
    ),
    tools=[calculator_tool],
)
```

## View Traces in Weave dashboard

Once the agent runs, all its traces are logged to the corresponding project on [the Weave dashboard](https://wandb.ai/home).

You can view a timeline of calls that your ADK agent made during execution -

## Notes

- **Environment Variables**: Ensure your environment variables are correctly set for both WandB and Google API keys.
- **Project Configuration**: Replace `<your-entity>/<your-project>` with your actual WandB entity and project name.
- **Entity Name**: You can find your entity name by visiting your [WandB dashboard](https://wandb.ai/home) and checking the **Teams** field in the left sidebar.
- **Tracer Provider**: It's critical to set the global tracer provider before using any ADK components to ensure proper tracing.

By following these steps, you can effectively integrate Google ADK with Weave, enabling comprehensive logging and visualization of your AI agents' model calls, tool invocations, and reasoning processes.

## Resources

- **[Send OpenTelemetry Traces to Weave](https://weave-docs.wandb.ai/guides/tracking/otel)** - Comprehensive guide on configuring OTEL with Weave, including authentication and advanced configuration options.
- **[Navigate the Trace View](https://weave-docs.wandb.ai/guides/tracking/trace-tree)** - Learn how to effectively analyze and debug your traces in the Weave UI, including understanding trace hierarchies and span details.
- **[Weave Integrations](https://weave-docs.wandb.ai/guides/integrations/)** - Explore other framework integrations and see how Weave can work with your entire AI stack.

# Windsor.ai MCP tool for ADK

Supported in ADKPythonTypeScript

The [Windsor MCP Server](https://github.com/windsor-ai/windsor_mcp) connects your ADK agent to [Windsor.ai](https://windsor.ai/), a data integration platform that unifies marketing, sales, and customer data from 325+ sources. This integration gives your agent the ability to query and analyze cross-channel business data using natural language, without writing SQL or custom scripts.

## Use cases

- **Marketing Performance Analysis**: Analyze campaign performance across channels like Facebook Ads, Google Ads, TikTok Ads, and more. Ask questions like "What campaigns had the best ROAS last month?" and get instant insights.
- **Cross-Channel Reporting**: Generate comprehensive reports combining data from multiple platforms such as GA4, Shopify, Salesforce, and HubSpot to get a unified view of business performance.
- **Budget Optimization**: Identify underperforming campaigns, detect budget inefficiencies, and get AI-driven recommendations for spend allocation across advertising channels.

## Prerequisites

- A [Windsor.ai](https://windsor.ai/) account with connected data sources
- A Windsor.ai API key (obtain from [onboard.windsor.ai](https://onboard.windsor.ai))

## Use with agent

```python
import os
from google.adk.agents import Agent
from google.adk.tools.mcp_tool import McpToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams

# Required for recursive $ref in MCP schema (https://github.com/google/adk-python/issues/3870)
os.environ["ADK_ENABLE_JSON_SCHEMA_FOR_FUNC_DECL"] = "1"

WINDSOR_API_KEY = "YOUR_WINDSOR_API_KEY"

root_agent = Agent(
    model="gemini-flash-latest",
    name="windsor_agent",
    instruction="Help users analyze their marketing and business data.",
    tools=[
        McpToolset(
            connection_params=StreamableHTTPConnectionParams(
                url="https://mcp.windsor.ai",
                headers={
                    "Authorization": f"Bearer {WINDSOR_API_KEY}",
                },
            ),
        )
    ],
)
```

```typescript
import { LlmAgent, MCPToolset } from "@google/adk";

const WINDSOR_API_KEY = "YOUR_WINDSOR_API_KEY";

const rootAgent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "windsor_agent",
    instruction: "Help users analyze their marketing and business data.",
    tools: [
        new MCPToolset({
            type: "StreamableHTTPConnectionParams",
            url: "https://mcp.windsor.ai",
            transportOptions: {
                requestInit: {
                    headers: {
                        Authorization: `Bearer ${WINDSOR_API_KEY}`,
                    },
                },
            },
        }),
    ],
});

export { rootAgent };
```

## Capabilities

Windsor MCP provides a natural language interface to your integrated business data. Rather than exposing discrete tools, it interprets your questions and returns structured insights from your connected data sources.

| Capability           | Description                                                        |
| -------------------- | ------------------------------------------------------------------ |
| Data querying        | Query normalized data from any of your 325+ connected platforms    |
| Performance analysis | Analyze KPIs, trends, and campaign metrics across channels         |
| Report generation    | Create marketing dashboards and cross-channel performance reports  |
| Budget analysis      | Identify spend inefficiencies and get optimization recommendations |
| Anomaly detection    | Detect outliers and unusual patterns in performance data           |

## Supported data sources

Windsor.ai connects to 325+ platforms, including:

- **Advertising**: Facebook Ads, Google Ads, TikTok Ads, LinkedIn Ads, Microsoft Ads
- **Analytics**: Google Analytics 4, Adobe Analytics
- **CRM**: Salesforce, HubSpot
- **E-commerce**: Shopify
- **And more**: See the [full list of connectors](https://windsor.ai/) on the Windsor.ai website

## Additional resources

- [Windsor MCP Server Repository](https://github.com/windsor-ai/windsor_mcp)
- [Windsor.ai Documentation](https://windsor.ai/documentation/windsor-mcp/)
- [Windsor MCP Introduction](https://windsor.ai/introducing-windsor-mcp/)
- [Windsor MCP Use Cases & Examples](https://windsor.ai/how-to-use-windsor-mcp-examples-use-cases/)

# Limitations for ADK tools

Some ADK tools have limitations that can impact how you implement them within an agent workflow. This page lists these tool limitations and workarounds, if available.

## One tool per agent limitation

ONLY for Search in ADK Python v1.15.0 and lower

This limitation only applies to the use of Google Search and Agent Search tools in ADK Python v1.15.0 and lower. ADK Python release v1.16.0 and higher provides a built-in workaround to remove this limitation.

In general, you can use more than one tool in an agent, but use of specific tools within an agent excludes the use of any other tools in that agent. The following ADK Tools can only be used by themselves, without any other tools, in a single agent object:

- [Code Execution](/integrations/code-execution/) with Gemini API (Note: in TypeScript, this requires Gemini 2.0+ and does not have this limitation)
- [Google Search](/integrations/google-search/) with Gemini API (Note: limitation only applies to Gemini 1.x models in TypeScript)
- [Agent Search](/integrations/agent-search/) (Note: currently unavailable in TypeScript)

For example, the following approach that uses one of these tools along with other tools, within a single agent, is ***not supported***:

```py
root_agent = Agent(
    name="RootAgent",
    model="gemini-flash-latest",
    description="Code Agent",
    tools=[custom_function],
    code_executor=BuiltInCodeExecutor() # <-- NOT supported when used with tools
)
```

```typescript
import {Agent, BuiltInCodeExecutor} from '@google/adk';

const rootAgent = new Agent({
  name: 'RootAgent',
  model: 'gemini-flash-latest',
  description: 'Code Agent',
  tools: [myCustomTool], // Assume myCustomTool is defined
  codeExecutor: new BuiltInCodeExecutor(), // <-- NOT supported when used with tools
});
```

```java
 LlmAgent searchAgent =
        LlmAgent.builder()
            .model(MODEL_ID)
            .name("SearchAgent")
            .instruction("You're a specialist in Google Search")
            .tools(new GoogleSearchTool(), new YourCustomTool()) // <-- NOT supported
            .build();
```

### Workaround #1: AgentTool.create() method

Supported in ADKPythonTypeScript (v0.6.1+)Java

The following code sample demonstrates how to use multiple built-in tools or how to use built-in tools with other tools by using multiple agents:

```py
from google.adk.tools.agent_tool import AgentTool
from google.adk.agents import Agent
from google.adk.tools import google_search
from google.adk.code_executors import BuiltInCodeExecutor

search_agent = Agent(
    model='gemini-flash-latest',
    name='SearchAgent',
    instruction="""
    You're a specialist in Google Search
    """,
    tools=[google_search],
)
coding_agent = Agent(
    model='gemini-flash-latest',
    name='CodeAgent',
    instruction="""
    You're a specialist in Code Execution
    """,
    code_executor=BuiltInCodeExecutor(),
)
root_agent = Agent(
    name="RootAgent",
    model="gemini-flash-latest",
    description="Root Agent",
    tools=[AgentTool(agent=search_agent), AgentTool(agent=coding_agent)],
)
```

```typescript
import {Agent, AgentTool, BuiltInCodeExecutor, GOOGLE_SEARCH} from '@google/adk';

const searchAgent = new Agent({
  model: 'gemini-flash-latest',
  name: 'SearchAgent',
  instruction: "You're a specialist in Google Search",
  tools: [GOOGLE_SEARCH],
});

const codingAgent = new Agent({
  model: 'gemini-flash-latest', // Built-in code execution requires Gemini 2.0+ in ADK JS
  name: 'CodeAgent',
  instruction: "You're a specialist in Code Execution",
  codeExecutor: new BuiltInCodeExecutor(),
});

const rootAgent = new Agent({
  name: 'RootAgent',
  model: 'gemini-flash-latest',
  description: 'Root Agent',
  tools: [new AgentTool({agent: searchAgent}), new AgentTool({agent: codingAgent})],
});
```

```java
import com.google.adk.agents.BaseAgent;
import com.google.adk.agents.LlmAgent;
import com.google.adk.tools.AgentTool;
import com.google.adk.tools.BuiltInCodeExecutionTool;
import com.google.adk.tools.GoogleSearchTool;
import com.google.common.collect.ImmutableList;

public class NestedAgentApp {

  private static final String MODEL_ID = "gemini-flash-latest";

  public static void main(String[] args) {

    // Define the SearchAgent
    LlmAgent searchAgent =
        LlmAgent.builder()
            .model(MODEL_ID)
            .name("SearchAgent")
            .instruction("You're a specialist in Google Search")
            .tools(new GoogleSearchTool()) // Instantiate GoogleSearchTool
            .build();


    // Define the CodingAgent
    LlmAgent codingAgent =
        LlmAgent.builder()
            .model(MODEL_ID)
            .name("CodeAgent")
            .instruction("You're a specialist in Code Execution")
            .tools(new BuiltInCodeExecutionTool()) // Instantiate BuiltInCodeExecutionTool
            .build();

    // Define the RootAgent, which uses AgentTool.create() to wrap SearchAgent and CodingAgent
    BaseAgent rootAgent =
        LlmAgent.builder()
            .name("RootAgent")
            .model(MODEL_ID)
            .description("Root Agent")
            .tools(
                AgentTool.create(searchAgent), // Use create method
                AgentTool.create(codingAgent)   // Use create method
             )
            .build();

    // Note: This sample only demonstrates the agent definitions.
    // To run these agents, you'd need to integrate them with a Runner and SessionService,
    // similar to the previous examples.
    System.out.println("Agents defined successfully:");
    System.out.println("  Root Agent: " + rootAgent.name());
    System.out.println("  Search Agent (nested): " + searchAgent.name());
    System.out.println("  Code Agent (nested): " + codingAgent.name());
  }
}
```

### Workaround #2: bypass_multi_tools_limit

Supported in ADKPythonJava

ADK Python has a built-in workaround which bypasses this limitation for `GoogleSearchTool` and `VertexAiSearchTool` (use `bypass_multi_tools_limit=True` to enable it), as shown in the [built_in_multi_tools](https://github.com/google/adk-python/tree/main/contributing/samples/built_in_multi_tools). sample agent.

Warning

Built-in tools cannot be used within a sub-agent, with the exception of `GoogleSearchTool` and `VertexAiSearchTool` in ADK Python because of the workaround mentioned above.

For example, the following approach that uses built-in tools within sub-agents is **not supported**:

```py
url_context_agent = Agent(
    model='gemini-flash-latest',
    name='UrlContextAgent',
    instruction="""
    You're a specialist in URL Context
    """,
    tools=[url_context],
)
coding_agent = Agent(
    model='gemini-flash-latest',
    name='CodeAgent',
    instruction="""
    You're a specialist in Code Execution
    """,
    code_executor=BuiltInCodeExecutor(),
)
root_agent = Agent(
    name="RootAgent",
    model="gemini-flash-latest",
    description="Root Agent",
    sub_agents=[
        url_context_agent,
        coding_agent
    ],
)
```

```typescript
import {Agent, BuiltInCodeExecutor} from '@google/adk';

const urlContextAgent = new Agent({
  model: 'gemini-flash-latest',
  name: 'UrlContextAgent',
  instruction: "You're a specialist in URL Context",
  tools: [myCustomTool], // Assume myCustomTool is defined
});

const codingAgent = new Agent({
  model: 'gemini-flash-latest',
  name: 'CodeAgent',
  instruction: "You're a specialist in Code Execution",
  codeExecutor: new BuiltInCodeExecutor(),
});

const rootAgent = new Agent({
  name: 'RootAgent',
  model: 'gemini-flash-latest',
  description: 'Root Agent',
  subAgents: [urlContextAgent, codingAgent], // NOT supported when sub-agents use built-in tools
});
```

```java
LlmAgent searchAgent =
    LlmAgent.builder()
        .model("gemini-flash-latest")
        .name("SearchAgent")
        .instruction("You're a specialist in Google Search")
        .tools(new GoogleSearchTool())
        .build();

LlmAgent codingAgent =
    LlmAgent.builder()
        .model("gemini-flash-latest")
        .name("CodeAgent")
        .instruction("You're a specialist in Code Execution")
        .tools(new BuiltInCodeExecutionTool())
        .build();


LlmAgent rootAgent =
    LlmAgent.builder()
        .name("RootAgent")
        .model("gemini-flash-latest")
        .description("Root Agent")
        .subAgents(searchAgent, codingAgent) // Not supported, as the sub agents use built in tools.
        .build();
```




