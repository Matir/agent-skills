# Python Quickstart for ADK

This guide shows you how to get up and running with Agent Development Kit (ADK) for Python. Before you start, make sure you have the following installed:

- Python 3.10 or later
- `pip` for installing packages

## Installation

Install ADK by running the following command:

```shell
pip install google-adk
```

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

## Create an agent project

Run the `adk create` command to start a new agent project.

```shell
adk create my_agent
```

### Explore the agent project

The created agent project has the following structure, with the `agent.py` file containing the main control code for the agent.

```text
my_agent/
    agent.py      # main agent code
    .env          # API keys or project IDs
    __init__.py
```

## Update your agent project

The `agent.py` file contains a `root_agent` definition which is the only required element of an ADK agent. You can also define tools for the agent to use. Update the generated `agent.py` code to include a `get_current_time` tool for use by the agent, as shown in the following code:

```python
from google.adk.agents.llm_agent import Agent

# Mock tool implementation
def get_current_time(city: str) -> dict:
    """Returns the current time in a specified city."""
    return {"status": "success", "city": city, "time": "10:30 AM"}

root_agent = Agent(
    model='gemini-flash-latest',
    name='root_agent',
    description="Tells the current time in a specified city.",
    instruction="You are a helpful assistant that tells the current time in cities. Use the 'get_current_time' tool for this purpose.",
    tools=[get_current_time],
)
```

### Set your API key

This project uses the Gemini API, which requires an API key. If you don't already have Gemini API key, create a key in Google AI Studio on the [API Keys](https://aistudio.google.com/app/apikey) page.

In a terminal window, write your API key into an `.env` file as an environment variable:

Update: my_agent/.env

```console
echo 'GOOGLE_API_KEY="YOUR_API_KEY"' > .env
```

Using other AI models with ADK

ADK supports the use of many generative AI models. For more information on configuring other models in ADK agents, see [Models & Authentication](/agents/models).

## Run your agent

You can run your ADK agent with an interactive command-line interface using the `adk run` command or the ADK web user interface provided by the ADK using the `adk web` command. Both these options allow you to test and interact with your agent.

### Run with command-line interface

Run your agent using the `adk run` command-line tool.

```console
adk run my_agent
```

### Run with web interface

The ADK framework provides web interface you can use to test and interact with your agent. You can start the web interface using the following command:

```console
adk web --port 8000
```

Note

Run this command from the **parent directory** that contains your `my_agent/` folder. For example, if your agent is inside `agents/my_agent/`, run `adk web` from the `agents/` directory.

This command starts a web server with a chat interface for your agent. You can access the web interface at (http://localhost:8000). Select the agent at the upper left corner and type a request.

Caution: ADK Web for development only

ADK Web is ***not meant for use in production deployments***. You should use ADK Web for development and debugging purposes only.

## Next: Build your agent

Now that you have ADK installed and your first agent running, try building your own agent with our build guides:

- [Build your agent](/tutorials/)




# Build a streaming agent with Python

With this quickstart, you'll learn to create a simple agent and use ADK Streaming to enable voice and video communication with it that is low-latency and bidirectional. We will install ADK, set up a basic "Google Search" agent, try running the agent with Streaming with `adk web` tool, and then explain how to build a simple asynchronous web app by yourself using ADK Streaming and [FastAPI](https://fastapi.tiangolo.com/).

**Note:** This guide assumes you have experience using a terminal in Windows, Mac, and Linux environments.

## Supported models for voice/video streaming

In order to use voice/video streaming in ADK, you will need to use Gemini models that support the Live API. You can find the **model ID(s)** that supports the Gemini Live API in the documentation:

- [Google AI Studio: Gemini Live API](https://ai.google.dev/gemini-api/docs/models#live-api)
- [Agent Platform: Gemini Live API](https://cloud.google.com/vertex-ai/generative-ai/docs/live-api)

## 1. Setup Environment & Install ADK

Create & Activate Virtual Environment (Recommended):

```bash
# Create
python3 -m venv .venv
# Activate (each new terminal)
# macOS/Linux: source .venv/bin/activate
# Windows CMD: .venv\Scripts\activate.bat
# Windows PowerShell: .venv\Scripts\Activate.ps1
```

Install ADK:

```bash
pip install google-adk
```

## 2. Project Structure

Create the following folder structure with empty files:

```console
adk-streaming/  # Project folder
└── app/ # the web app folder
    ├── .env # Gemini API key
    └── google_search_agent/ # Agent folder
        ├── __init__.py # Python package
        └── agent.py # Agent definition
```

### agent.py

Copy-paste the following code block into the `agent.py` file.

For `model`, please double-check the model ID as described earlier in the [Models section](#supported-models).

```py
from google.adk.agents import Agent
from google.adk.tools import google_search  # Import the tool

root_agent = Agent(
   # A unique name for the agent.
   name="basic_search_agent",
   # The Large Language Model (LLM) that agent will use.
   # Please fill in the latest model id that supports live from
   # https://adk.dev/get-started/streaming/quickstart-streaming/#supported-models
   model="...",
   # A short description of the agent's purpose.
   description="Agent to answer questions using Google Search.",
   # Instructions to set the agent's behavior.
   instruction="You are an expert researcher. You always stick to the facts.",
   # Add google_search tool to perform grounding with Google search.
   tools=[google_search]
)
```

`agent.py` is where all your agent(s)' logic will be stored, and you must have a `root_agent` defined.

Notice how easily you integrated [grounding with Google Search](https://ai.google.dev/gemini-api/docs/grounding?lang=python#configure-search) capabilities. The `Agent` class and the `google_search` tool handle the complex interactions with the LLM and grounding with the search API, allowing you to focus on the agent's *purpose* and *behavior*.

Copy-paste the following code block to `__init__.py` file.

__init__.py

```py
from . import agent
```

## 3. Set up the platform

To run the agent, choose a platform from either Google AI Studio or Google Cloud Agent Platform:

1. Get an API key from [Google AI Studio](https://aistudio.google.com/apikey).

1. Open the **`.env`** file located inside (`app/`) and copy-paste the following code.

   .env

   ```text
   GOOGLE_GENAI_USE_VERTEXAI=FALSE
   GOOGLE_API_KEY=PASTE_YOUR_ACTUAL_API_KEY_HERE
   ```

1. Replace `PASTE_YOUR_ACTUAL_API_KEY_HERE` with your actual `API KEY`.

1. You need an existing [Google Cloud](https://cloud.google.com/?e=48754805&hl=en) account and a project.

   - Set up a [Google Cloud project](https://cloud.google.com/vertex-ai/generative-ai/docs/start/quickstarts/quickstart-multimodal#setup-gcp)
   - Set up the [gcloud CLI](https://cloud.google.com/vertex-ai/generative-ai/docs/start/quickstarts/quickstart-multimodal#setup-local)
   - Authenticate to Google Cloud, from the terminal by running `gcloud auth login`.
   - [Enable the Agent Platform API](https://console.cloud.google.com/flows/enableapi?apiid=aiplatform.googleapis.com).

1. Open the **`.env`** file located inside (`app/`). Copy-paste the following code and update the project ID and location.

   .env

   ```text
   GOOGLE_GENAI_USE_VERTEXAI=TRUE
   GOOGLE_CLOUD_PROJECT=PASTE_YOUR_ACTUAL_PROJECT_ID
   GOOGLE_CLOUD_LOCATION=us-central1
   ```

## 4. Try the agent with `adk web`

Now it's ready to try the agent. Run the following command to launch the **dev UI**. First, make sure to set the current directory to `app`:

```shell
cd app
```

Also, set `SSL_CERT_FILE` variable with the following command. This is required for the voice and video tests later.

```bash
export SSL_CERT_FILE=$(python3 -m certifi)
```

```powershell
$env:SSL_CERT_FILE = (python3 -m certifi)
```

Then, run the dev UI:

```shell
adk web
```

Note for Windows users

When hitting the `_make_subprocess_transport NotImplementedError`, consider using `adk web --no-reload` instead.

Caution: ADK Web for development only

ADK Web is ***not meant for use in production deployments***. You should use ADK Web for development and debugging purposes only.

Open the URL provided (usually `http://localhost:8000` or `http://127.0.0.1:8000`) **directly in your browser**. This connection stays entirely on your local machine. Select `google_search_agent`.

### Try with voice and video

To try with voice, reload the web browser, click the microphone button to enable the voice input, and ask the the following questions in voice. The agent will use the google_search tool to get the latest information to answer those questions. You will hear the answer in voice in real-time.

- What is the weather in New York?
- What is the time in New York?
- What is the weather in Paris?
- What is the time in Paris?

To try with video, reload the web browser, click the camera button to enable the video input, and ask questions like "What do you see?". The agent will answer what they see in the video input.

#### Caveat

- You can not use text chat with the native-audio models. You will see errors when entering text messages on `adk web`.

### Stop the tool

Stop `adk web` by pressing `Ctrl-C` on the console.

### Note on ADK Streaming

The following features will be supported in the future versions of the ADK Streaming: Callback, LongRunningTool, ExampleTool, and Shell agent (e.g. SequentialAgent).

Congratulations! You've successfully created and interacted with your first Streaming agent using ADK!

## Next steps: build custom streaming app

The [Gemini Live API Toolkit development guide series](https://adk.dev/streaming/dev-guide/part1/index.md) gives an overview of the server and client code for a custom asynchronous web app built with ADK Streaming, enabling real-time, bidirectional audio and text communication.




# Coding with AI

You can use AI coding assistants to build agents with Agent Development Kit (ADK). Give your coding agent ADK expertise by installing development skills into your project, or by connecting it to ADK documentation through an MCP server.

- [**Agents CLI in Agent Platform**](#agents-cli): Command-line tool and coding skills for ADK development.
- [**ADK Docs MCP Server**](#adk-docs-mcp-server): Connect your coding tool to ADK documentation through an MCP server.
- [**ADK Docs Index**](#adk-docs-index): Machine-readable documentation files following the `llms.txt` standard.

## agents-cli

[Agents CLI in Agent Platform](https://google.github.io/agents-cli/) is the command-line tool for ADK development. It provides scaffolding commands, deployment tools, and development skills that work with any compatible coding assistant, including Gemini CLI, Antigravity, Claude Code, and Cursor.

To install Agents CLI and set up ADK development skills:

```bash
uvx google-agents-cli setup
```

This installs both the CLI and coding skills. Browse the [Agents CLI documentation](https://google.github.io/agents-cli/) for more details.

### CLI Commands

| Command                       | Description                                |
| ----------------------------- | ------------------------------------------ |
| `agents-cli scaffold create`  | Create a new ADK agent project             |
| `agents-cli scaffold enhance` | Add deployment to existing project         |
| `agents-cli eval`             | Run agent evaluations                      |
| `agents-cli deploy`           | Deploy to Agent Runtime, Cloud Run, or GKE |
| `agents-cli publish`          | Publish to Gemini Enterprise               |

### Development Skills

After setup, the following skills are available in your coding tool:

| Skill                             | Description                                  |
| --------------------------------- | -------------------------------------------- |
| `google-agents-cli-workflow`      | Development lifecycle and coding guidelines  |
| `google-agents-cli-adk-code`      | Python API quick reference and docs index    |
| `google-agents-cli-scaffold`      | Project scaffolding                          |
| `google-agents-cli-eval`          | Evaluation methodology and scoring           |
| `google-agents-cli-deploy`        | Agent Runtime, Cloud Run, and GKE deployment |
| `google-agents-cli-publish`       | Gemini Enterprise registration               |
| `google-agents-cli-observability` | Tracing, logging, and integrations           |

## ADK Docs MCP Server

You can configure your coding tool to search and read ADK documentation using an MCP server. Below are setup instructions for popular tools.

### Gemini CLI

To add the ADK docs MCP server to [Gemini CLI](https://geminicli.com/), install the [ADK Docs Extension](https://github.com/derailed-dash/adk-docs-ext):

```bash
gemini extensions install https://github.com/derailed-dash/adk-docs-ext
```

### Antigravity

To add the ADK docs MCP server to [Antigravity](https://antigravity.google/) (requires [`uv`](https://docs.astral.sh/uv/)):

1. Open the MCP store via the **...** (more) menu at the top of the editor's agent panel.

1. Click on **Manage MCP Servers** then **View raw config**.

1. Add the following to `mcp_config.json`:

   ```json
   {
     "mcpServers": {
       "adk-docs-mcp": {
         "command": "uvx",
         "args": [
           "--from",
           "mcpdoc",
           "mcpdoc",
           "--urls",
           "AgentDevelopmentKit:https://adk.dev/llms.txt",
           "--transport",
           "stdio"
         ]
       }
     }
   }
   ```

### Claude Code

To add the ADK docs MCP server to [Claude Code](https://code.claude.com/docs/en/overview):

```bash
claude mcp add adk-docs --transport stdio -- uvx --from mcpdoc mcpdoc --urls AgentDevelopmentKit:https://adk.dev/llms.txt --transport stdio
```

### Cursor

To add the ADK docs MCP server to [Cursor](https://cursor.com/) (requires [`uv`](https://docs.astral.sh/uv/)):

1. Open **Cursor Settings** and navigate to the **Tools & MCP** tab.

1. Click on **New MCP Server**, which will open `mcp.json` for editing.

1. Add the following to `mcp.json`:

   ```json
   {
     "mcpServers": {
       "adk-docs-mcp": {
         "command": "uvx",
         "args": [
           "--from",
           "mcpdoc",
           "mcpdoc",
           "--urls",
           "AgentDevelopmentKit:https://adk.dev/llms.txt",
           "--transport",
           "stdio"
         ]
       }
     }
   }
   ```

### Other Tools

Any coding tool that supports MCP servers can use the same server configuration shown above. Adapt the JSON example from the Antigravity or Cursor sections for your tool's MCP settings.

## ADK Docs Index

The ADK documentation is available as machine-readable files following the [`llms.txt` standard](https://llmstxt.org/). These files are generated with every documentation update and are always up to date.

| File            | Description                         | URL                                                      |
| --------------- | ----------------------------------- | -------------------------------------------------------- |
| `llms.txt`      | Documentation index with links      | [`adk.dev/llms.txt`](https://adk.dev/llms.txt)           |
| `llms-full.txt` | Full documentation in a single file | [`adk.dev/llms-full.txt`](https://adk.dev/llms-full.txt) |




# Build agents with Agent Config

Supported in ADKPython v1.11.0Java v0.3.0Go v0.3.0Experimental

The ADK Agent Config feature lets you build an ADK workflow without writing code. An Agent Config uses a YAML format text file with a brief description of the agent, allowing just about anyone to assemble and run an ADK agent. The following is a simple example of a basic Agent Config definition:

```yaml
name: assistant_agent
model: gemini-flash-latest
description: A helper agent that can answer users' questions.
instruction: You are an agent to help answer users' various questions.
```

You can use Agent Config files to build more complex agents which can incorporate Functions, Tools, Sub-Agents, and more. This page describes how to build and run ADK workflows with the Agent Config feature. For detailed information on the syntax and settings supported by the Agent Config format, see the [Agent Config syntax reference](/api-reference/agentconfig/).

Experimental

The Agent Config feature is experimental and has some [known limitations](#known-limitations). We welcome your [feedback](https://github.com/google/adk-python/issues/new?template=feature_request.md&labels=agent%20config)!

## Get started

This section describes how to set up and start building agents with the ADK and the Agent Config feature, including installation setup, building an agent, and running your agent.

### Setup

You need to install the Google Agent Development Kit libraries, and provide an access key for a generative AI model such as Gemini API. This section provides details on what you must install and configure before you can run agents with the Agent Config files.

Note

The Agent Config feature currently only supports Gemini models. For more information about additional; functional restrictions, see [Known limitations](#known-limitations).

To set up ADK for use with Agent Config:

1. Install the ADK Python libraries by following the [Installation](/get-started/installation/#python) instructions. *Python is currently required.* For more information, see the [Known limitations](#known-limitations).

1. Verify that ADK is installed by running the following command in your terminal:

   ```text
   adk --version
   ```

   This command should show the ADK version you have installed.

Tip

If the `adk` command fails to run and the version is not listed in step 2, make sure your Python environment is active. Execute `source .venv/bin/activate` in your terminal on Mac and Linux. For other platform commands, see the [Installation](/get-started/installation/#python) page.

### Build an agent

You build an agent with Agent Config using the `adk create` command to create the project files for an agent, and then editing the `root_agent.yaml` file it generates for you.

To create an ADK project for use with Agent Config:

1. In your terminal window, run the following command to create a config-based agent:

   ```text
   adk create --type=config my_agent
   ```

   This command generates a `my_agent/` folder, containing a `root_agent.yaml` file and an `.env` file.

1. In the `my_agent/.env` file, set environment variables for your agent to access generative AI models and other services:

   1. For Gemini model access through Google API, add a line to the file with your API key:

      ```text
      GOOGLE_GENAI_USE_VERTEXAI=0
      GOOGLE_API_KEY=<your-Google-Gemini-API-key>
      ```

      You can get an API key from the Google AI Studio [API Keys](https://aistudio.google.com/app/apikey) page.

   1. For Gemini model access through Google Cloud, add these lines to the file:

      ```text
      GOOGLE_GENAI_USE_VERTEXAI=1
      GOOGLE_CLOUD_PROJECT=<your_gcp_project>
      GOOGLE_CLOUD_LOCATION=us-central1
      ```

      For information on creating a Cloud Project, see the Google Cloud docs for [Creating and managing projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects).

1. Using text editor, edit the Agent Config file `my_agent/root_agent.yaml`, as shown below:

```text
# yaml-language-server: $schema=https://raw.githubusercontent.com/google/adk-python/refs/heads/main/src/google/adk/agents/config_schemas/AgentConfig.json
name: assistant_agent
model: gemini-flash-latest
description: A helper agent that can answer users' questions.
instruction: You are an agent to help answer users' various questions.
```

You can discover more configuration options for your `root_agent.yaml` agent configuration file by referring to the ADK [samples repository](https://github.com/search?q=repo%3Agoogle%2Fadk-python+path%3A%2F%5Econtributing%5C%2Fsamples%5C%2F%2F+.yaml&type=code) or the [Agent Config syntax](/api-reference/agentconfig/) reference.

### Run the agent

Once you have completed editing your Agent Config, you can run your agent using the web interface, command line terminal execution, or API server mode.

To run your Agent Config-defined agent:

1. In your terminal, navigate to the `my_agent/` directory containing the `root_agent.yaml` file.
1. Type one of the following commands to run your agent:
   - `adk web` - Run web UI interface for your agent.
   - `adk run` - Run your agent in the terminal without a user interface.
   - `adk api_server` - Run your agent as a service that can be used by other applications.

For more information on the ways to run your agent, see [Agent Runtime](/runtime/#ways-to-run-agents). For more information about the ADK command line options, see the [ADK CLI reference](/api-reference/cli/).

### Run programmatically

You can also bypass the CLI and dynamically load and execute a configuration-based agent directly in your code. The utility loads the configuration and instantiates the proper agent class (such as `LlmAgent`) transparently as a `BaseAgent` subclass.

```python
import asyncio
from google.adk.agents import config_agent_utils
from google.adk.runners import Runner

async def main():
    # Load the agent directly from the YAML config file
    agent = config_agent_utils.from_config("my_agent/root_agent.yaml")
    # ...

if __name__ == "__main__":
    asyncio.run(main())
```

```java
import com.google.adk.agents.BaseAgent;
import com.google.adk.agents.ConfigAgentUtils;

public class AgentApp {
    public static void main(String[] args) throws Exception {
        // Load the agent directly from the YAML config file
        BaseAgent agent = ConfigAgentUtils.fromConfig("my_agent/root_agent.yaml");
        // ...
    }
}
```

## Example configs

This section shows examples of Agent Config files to get you started building agents. For additional and more complete examples, see the ADK [samples repository](https://github.com/search?q=repo%3Agoogle%2Fadk-python+path%3A%2F%5Econtributing%5C%2Fsamples%5C%2F%2F+root_agent.yaml&type=code).

### Built-in tool example

The following example uses a built-in ADK tool function for using google search to provide functionality to the agent. This agent automatically uses the search tool to reply to user requests.

```text
# yaml-language-server: $schema=https://raw.githubusercontent.com/google/adk-python/refs/heads/main/src/google/adk/agents/config_schemas/AgentConfig.json
name: search_agent
model: gemini-flash-latest
description: 'an agent whose job it is to perform Google search queries and answer questions about the results.'
instruction: You are an agent whose job is to perform Google search queries and answer questions about the results.
tools:
  - name: google_search
```

For more details, see the full code for this sample in the [ADK sample repository](https://github.com/google/adk-python/blob/main/contributing/samples/tool_builtin_config/root_agent.yaml).

### Custom tool example

The following example uses a custom tool built with Python code and listed in the `tools:` section of the config file. The agent uses this tool to check if a list of numbers provided by the user are prime numbers.

```text
# yaml-language-server: $schema=https://raw.githubusercontent.com/google/adk-python/refs/heads/main/src/google/adk/agents/config_schemas/AgentConfig.json
agent_class: LlmAgent
model: gemini-flash-latest
name: prime_agent
description: Handles checking if numbers are prime.
instruction: |
  You are responsible for checking whether numbers are prime.
  When asked to check primes, you must call the check_prime tool with a list of integers.
  Never attempt to determine prime numbers manually.
  Return the prime number results to the root agent.
tools:
  - name: ma_llm.check_prime
```

For more details, see the full code for this sample in the [ADK sample repository](https://github.com/google/adk-python/blob/main/contributing/samples/multi_agent_llm_config/prime_agent.yaml).

### Sub-agents example

The following example shows an agent defined with two sub-agents in the `sub_agents:` section, and an example tool in the `tools:` section of the config file. This agent determines what the user wants, and delegates to one of the sub-agents to resolve the request. The sub-agents are defined using Agent Config YAML files.

```text
# yaml-language-server: $schema=https://raw.githubusercontent.com/google/adk-python/refs/heads/main/src/google/adk/agents/config_schemas/AgentConfig.json
agent_class: LlmAgent
model: gemini-flash-latest
name: root_agent
description: Learning assistant that provides tutoring in code and math.
instruction: |
  You are a learning assistant that helps students with coding and math questions.

  You delegate coding questions to the code_tutor_agent and math questions to the math_tutor_agent.

  Follow these steps:
  1. If the user asks about programming or coding, delegate to the code_tutor_agent.
  2. If the user asks about math concepts or problems, delegate to the math_tutor_agent.
  3. Always provide clear explanations and encourage learning.
sub_agents:
  - config_path: code_tutor_agent.yaml
  - config_path: math_tutor_agent.yaml
```

For more details, see the full code for this sample in the [ADK sample repository](https://github.com/google/adk-python/blob/main/contributing/samples/multi_agent_basic_config/root_agent.yaml).

## Deploy agent configs

You can deploy Agent Config agents with [Cloud Run](/deploy/cloud-run/) and [Agent Runtime](/deploy/agent-runtime/), using the same procedure as code-based agents. For more information on how to prepare and deploy Agent Config-based agents, see the [Cloud Run](/deploy/cloud-run/) and [Agent Runtime](/deploy/agent-runtime/) deployment guides.

## Known limitations

The Agent Config feature is experimental and includes the following limitations:

- **Model support:** Only Gemini models are currently supported. Integration with third-party models is in progress.
- **Programming language:** The Agent Config feature currently supports Python and Java code for tools and other functionality requiring programming code.
- **ADK Tool support:** The following ADK tools are supported by the Agent Config feature, but *not all tools are fully supported*:
  - `google_search`
  - `google_maps_grounding`
  - `load_artifacts`
  - `url_context`
  - `exit_loop`
  - `preload_memory`
  - `get_user_choice`
  - `enterprise_web_search`
  - `load_web_page`: Requires a fully-qualified path to access web pages.
  - `AgentTool`: Allows an agent to call another agent.
  - `LongRunningFunctionTool`: Supports long-running functions.
  - `McpToolset`: Connects to Model Context Protocol (MCP) servers.
  - `ExampleTool`: Provides example-based few-shot learning for tools.
- **Agent Type Support:** The `LangGraphAgent` and `A2aAgent` types are not yet supported.
- **Agent Search:** The `VertexAiSearchTool` is currently supported in Python and Java Agent Configs.

## Next steps

For ideas on how and what to build with ADK Agent Configs, see the yaml-based agent definitions in the ADK [adk-samples](https://github.com/search?q=repo:google/adk-python+path:/%5Econtributing%5C/samples%5C//+root_agent.yaml&type=code) repository. For detailed information on the syntax and settings supported by the Agent Config format, see the [Agent Config syntax reference](/api-reference/agentconfig/).




# AI Models for ADK agents

Supported in ADKPythonTypescriptGoJava

Agent Development Kit (ADK) is designed for flexibility, allowing you to integrate various Large Language Models (LLMs) into your agents. This section details how to leverage Gemini and integrate other popular models effectively, including those hosted externally or running locally.

ADK provides several mechanisms for model integration:

1. **Direct String / Registry:** For models tightly integrated with Google Cloud, such as Gemini models accessed via Google AI Studio or Agent Platform, or models hosted on Agent Platform endpoints. You access these models by providing the model name or endpoint resource string and ADK's internal registry resolves this string to the appropriate backend client.

   - [Gemini models](/agents/models/google-gemini/)
   - [Claude models](/agents/models/anthropic/)
   - [Agent Platform hosted models](/agents/models/agent-platform/)

1. **Model connectors:** For broader compatibility, especially models outside the Google ecosystem or those requiring specific client configurations, such as models accessed via Apigee or LiteLLM. You instantiate a specific wrapper class, such as `ApigeeLlm` or `LiteLlm`, and pass this object as the `model` parameter to your `LlmAgent`.

   - [Apigee models](/agents/models/apigee/)
   - [LiteLLM models](/agents/models/litellm/)
   - [Ollama model hosting](/agents/models/ollama/)
   - [vLLM model hosting](/agents/models/vllm/)
   - [LiteRT-LM model hosting](/agents/models/litert-lm/)

1. **[Model routing](/agents/models/routing/):** For dynamically selecting between multiple models at runtime using a router function, with automatic failover on error.

# Agent Platform hosted models for ADK agents

For enterprise-grade scalability, reliability, and integration with Google Cloud's MLOps ecosystem, you can use models deployed to Agent Platform Endpoints. This includes models from Model Garden or your own fine-tuned models.

**Integration Method:** Pass the full Agent Platform Endpoint resource string (`projects/PROJECT_ID/locations/LOCATION/endpoints/ENDPOINT_ID`) directly to the `model` parameter of `LlmAgent`.

## Agent Platform Setup

Ensure your environment is configured for Agent Platform:

1. **Authentication:** Use Application Default Credentials (ADC):

   ```shell
   gcloud auth application-default login
   ```

1. **Environment Variables:** Set your project and location:

   ```shell
   export GOOGLE_CLOUD_PROJECT="YOUR_PROJECT_ID"
   export GOOGLE_CLOUD_LOCATION="YOUR_VERTEX_AI_LOCATION" # e.g., us-central1
   ```

1. **Enable Agent Platform Backend:** Crucially, ensure the `google-genai` library targets Agent Platform:

   ```shell
   export GOOGLE_GENAI_USE_VERTEXAI=TRUE
   ```

## Model Garden Deployments

Supported in ADKPython v0.2.0Java v0.1.0

You can deploy various open and proprietary models from the [Model Garden](https://console.cloud.google.com/vertex-ai/model-garden) to an endpoint.

**Example:**

```python
from google.adk.agents import LlmAgent
from google.genai import types # For config objects

# --- Example Agent using a Llama 3 model deployed from Model Garden ---

# Replace with your actual Agent Platform Endpoint resource name
llama3_endpoint = "projects/YOUR_PROJECT_ID/locations/us-central1/endpoints/YOUR_LLAMA3_ENDPOINT_ID"

agent_llama3_vertex = LlmAgent(
    model=llama3_endpoint,
    name="llama3_vertex_agent",
    instruction="You are a helpful assistant based on Llama 3, hosted on Agent Platform.",
    generate_content_config=types.GenerateContentConfig(max_output_tokens=2048),
    # ... other agent parameters
)
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.models.Gemini;
import com.google.genai.types.GenerateContentConfig;

// ...

// Replace with your actual Agent Platform Endpoint resource name
String llama3Endpoint = "projects/YOUR_PROJECT_ID/locations/us-central1/endpoints/YOUR_LLAMA3_ENDPOINT_ID";

LlmAgent agentLlama3Vertex = LlmAgent.builder()
    .model(Gemini.builder()
        .modelName(llama3Endpoint)
        .build())
    .name("llama3_vertex_agent")
    .instruction("You are a helpful assistant based on Llama 3, hosted on Agent Platform.")
    .generateContentConfig(GenerateContentConfig.builder()
        .maxOutputTokens(2048)
        .build())
    // ... other agent parameters
    .build();
```

## Fine-tuned Model Endpoints

Supported in ADKPython v0.2.0Java v0.1.0

Deploying your fine-tuned models (whether based on Gemini or other architectures supported by Agent Platform) results in an endpoint that can be used directly.

**Example:**

```python
from google.adk.agents import LlmAgent

# --- Example Agent using a fine-tuned Gemini model endpoint ---

# Replace with your fine-tuned model's endpoint resource name
finetuned_gemini_endpoint = "projects/YOUR_PROJECT_ID/locations/us-central1/endpoints/YOUR_FINETUNED_ENDPOINT_ID"

agent_finetuned_gemini = LlmAgent(
    model=finetuned_gemini_endpoint,
    name="finetuned_gemini_agent",
    instruction="You are a specialized assistant trained on specific data.",
    # ... other agent parameters
)
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.models.Gemini;

// ...

// Replace with your fine-tuned model's endpoint resource name
String finetunedGeminiEndpoint = "projects/YOUR_PROJECT_ID/locations/us-central1/endpoints/YOUR_FINETUNED_ENDPOINT_ID";

LlmAgent agentFinetunedGemini = LlmAgent.builder()
    .model(Gemini.builder()
        .modelName(finetunedGeminiEndpoint)
        .build())
    .name("finetuned_gemini_agent")
    .instruction("You are a specialized assistant trained on specific data.")
    // ... other agent parameters
    .build();
```

## Anthropic Claude on Agent Platform

Supported in ADKPython v0.2.0Java v0.1.0

Some providers, like Anthropic, make their models available directly through Agent Platform.

**Example:**

**Integration Method:** Uses the direct model string (e.g., `"claude-3-sonnet@20240229"`), *but requires manual registration* within ADK.

**Why Registration?** ADK's registry automatically recognizes `gemini-*` strings and standard Agent Platform endpoint strings (`projects/.../endpoints/...`) and routes them via the `google-genai` library. For other model types used directly via Agent Platform (like Claude), you must explicitly tell the ADK registry which specific wrapper class (`Claude` in this case) knows how to handle that model identifier string with the Agent Platform backend.

**Setup:**

1. **Agent Platform Environment:** Ensure the consolidated Agent Platform setup (ADC, Env Vars, `GOOGLE_GENAI_USE_VERTEXAI=TRUE`) is complete.

1. **Install Provider Library:** Install the necessary client library configured for Agent Platform.

   ```shell
   pip install "anthropic[vertex]"
   ```

1. **Register Model Class:** Add this code near the start of your application, *before* creating an agent using the Claude model string:

   ```python
   # Required for using Claude model strings directly via Agent Platform with LlmAgent
   from google.adk.models.anthropic_llm import Claude
   from google.adk.models.registry import LLMRegistry

   LLMRegistry.register(Claude)
   ```

```python
from google.adk.agents import LlmAgent
from google.adk.models.anthropic_llm import Claude # Import needed for registration
from google.adk.models.registry import LLMRegistry # Import needed for registration
from google.genai import types

# --- Register Claude class (do this once at startup) ---
LLMRegistry.register(Claude)

# --- Example Agent using Claude 3 Sonnet on Agent Platform ---

# Standard model name for Claude 3 Sonnet on Agent Platform
claude_model_vertexai = "claude-3-sonnet@20240229"

agent_claude_vertexai = LlmAgent(
    model=claude_model_vertexai, # Pass the direct string after registration
    name="claude_vertexai_agent",
    instruction="You are an assistant powered by Claude 3 Sonnet on Agent Platform.",
    generate_content_config=types.GenerateContentConfig(max_output_tokens=4096),
    # ... other agent parameters
)
```

**Integration Method:** Directly instantiate the provider-specific model class (e.g., `com.google.adk.models.Claude`) and configure it with an Agent Platform backend.

**Why Direct Instantiation?** The Java ADK's `LlmRegistry` primarily handles Gemini models by default. For third-party models like Claude on Agent Platform, you directly provide an instance of the ADK's wrapper class (e.g., `Claude`) to the `LlmAgent`. This wrapper class is responsible for interacting with the model via its specific client library, configured for Agent Platform.

**Setup:**

1. **Agent Platform Environment:**

   - Ensure your Google Cloud project and region are correctly set up.
   - **Application Default Credentials (ADC):** Make sure ADC is configured correctly in your environment. This is typically done by running `gcloud auth application-default login`. The Java client libraries use these credentials to authenticate with Agent Platform. Follow the [Google Cloud Java documentation on ADC](https://cloud.google.com/java/docs/reference/google-auth-library/latest/com.google.auth.oauth2.GoogleCredentials#com_google_auth_oauth2_GoogleCredentials_getApplicationDefault__) for detailed setup.

1. **Provider Library Dependencies:**

   - **Third-Party Client Libraries (Often Transitive):** The ADK core library often includes the necessary client libraries for common third-party models on Agent Platform (like Anthropic's required classes) as **transitive dependencies**. This means you might not need to explicitly add a separate dependency for the Anthropic Vertex SDK in your `pom.xml` or `build.gradle`.

1. **Instantiate and Configure the Model:** When creating your `LlmAgent`, instantiate the `Claude` class (or the equivalent for another provider) and configure its `VertexBackend`.

```java
import com.anthropic.client.AnthropicClient;
import com.anthropic.client.okhttp.AnthropicOkHttpClient;
import com.anthropic.vertex.backends.VertexBackend;
import com.google.adk.agents.LlmAgent;
import com.google.adk.models.Claude; // ADK's wrapper for Claude
import com.google.auth.oauth2.GoogleCredentials;
import java.io.IOException;

// ... other imports

public class ClaudeVertexAiAgent {

    public static LlmAgent createAgent() throws IOException {
        // Model name for Claude 3 Sonnet on Agent Platform (or other versions)
        String claudeModelVertexAi = "claude-3-7-sonnet"; // Or any other Claude model

        // Configure the AnthropicOkHttpClient with the VertexBackend
        AnthropicClient anthropicClient = AnthropicOkHttpClient.builder()
            .backend(
                VertexBackend.builder()
                    .region("us-east5") // Specify your Agent Platform region
                    .project("your-gcp-project-id") // Specify your GCP Project ID
                    .googleCredentials(GoogleCredentials.getApplicationDefault())
                    .build())
            .build();

        // Instantiate LlmAgent with the ADK Claude wrapper
        LlmAgent agentClaudeVertexAi = LlmAgent.builder()
            .model(new Claude(claudeModelVertexAi, anthropicClient)) // Pass the Claude instance
            .name("claude_vertexai_agent")
            .instruction("You are an assistant powered by Claude 3 Sonnet on Agent Platform.")
            // .generateContentConfig(...) // Optional: Add generation config if needed
            // ... other agent parameters
            .build();

        return agentClaudeVertexAi;
    }

    public static void main(String[] args) {
        try {
            LlmAgent agent = createAgent();
            System.out.println("Successfully created agent: " + agent.name());
            // Here you would typically set up a Runner and Session to interact with the agent
        } catch (IOException e) {
            System.err.println("Failed to create agent: " + e.getMessage());
            e.printStackTrace();
        }
    }
}
```

## Open Models on Agent Platform

Supported in ADKPython v0.1.0Java v0.1.0

Agent Platform offers a curated selection of open-source models, such as Meta Llama, through Model-as-a-Service (MaaS). These models are accessible via managed APIs, allowing you to deploy and scale without managing the underlying infrastructure. For a full list of available options, see the [Agent Platform open models for MaaS](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/maas/use-open-models#open-models) documentation.

You can use the [LiteLLM](https://docs.litellm.ai/) library to access open models like Meta's Llama on Agent Platform MaaS

**Integration Method:** Use the `LiteLlm` wrapper class and set it as the `model` parameter of `LlmAgent`. Make sure you go through the [LiteLLM model connector for ADK agents](/agents/models/litellm/#litellm-model-connector-for-adk-agents) documentation on how to use LiteLLM in ADK

**Setup:**

1. **Agent Platform Environment:** Ensure the consolidated Agent Platform setup (ADC, Env Vars, `GOOGLE_GENAI_USE_VERTEXAI=TRUE`) is complete.

1. **Install LiteLLM:**

   ```shell
   pip install litellm
   ```

**Example:**

```python
from google.adk.agents import LlmAgent
from google.adk.models.lite_llm import LiteLlm

# --- Example Agent using Meta's Llama 4 Scout ---
agent_llama_vertexai = LlmAgent(
    model=LiteLlm(model="vertex_ai/meta/llama-4-scout-17b-16e-instruct-maas"), # LiteLLM model string format
    name="llama4_agent",
    instruction="You are a helpful assistant powered by Llama 4 Scout.",
    # ... other agent parameters
)
```

# Claude models for ADK agents

Supported in ADKJava v0.2.0

You can integrate Anthropic's Claude models directly using an Anthropic API key or from an Agent Platform backend into your Java ADK applications by using the ADK's `Claude` wrapper class. You can also access Anthropic models through Google Cloud Agent Platform services. For more information, see the [Third-Party Models on Agent Platform](/agents/models/agent-platform/#anthropic-claude) section. You can also use Anthropic models through the [LiteLLM](/agents/models/litellm/) library for Python.

## Get started

The following code examples show a basic implementation for using Anthropic models in your agents:

```java
public static LlmAgent createAgent() {

  AnthropicClient anthropicClient = AnthropicOkHttpClient.builder()
      .apiKey("ANTHROPIC_API_KEY")
      .build();

  Claude claudeModel = new Claude(
      "claude-sonnet-4-6", anthropicClient
  );

  return LlmAgent.builder()
      .name("claude_direct_agent")
      .model(claudeModel)
      .instruction("You are a helpful AI assistant powered by Anthropic Claude.")
      .build();
}
```

## Prerequisites

1. **Dependencies:**

   - **Anthropic SDK Classes (Transitive):** The Java ADK's `com.google.adk.models.Claude` wrapper relies on classes from Anthropic's official Java SDK. These are typically included as *transitive dependencies*. For more information, see the [Anthropic Java SDK](https://github.com/anthropics/anthropic-sdk-java).

1. **Anthropic API Key:**

   - Obtain an API key from Anthropic. Securely manage this key using a secret manager.

## Example implementation

Instantiate `com.google.adk.models.Claude`, providing the desired Claude model name and an `AnthropicOkHttpClient` configured with your API key. Then, pass the `Claude` instance to your `LlmAgent`, as shown in the following example:

```java
import com.anthropic.client.AnthropicClient;
import com.google.adk.agents.LlmAgent;
import com.google.adk.models.Claude;
import com.anthropic.client.okhttp.AnthropicOkHttpClient; // From Anthropic's SDK

public class DirectAnthropicAgent {

  private static final String CLAUDE_MODEL_ID = "claude-sonnet-4-6"; // Or your preferred Claude model

  public static LlmAgent createAgent() {

    // It's recommended to load sensitive keys from a secure config
    AnthropicClient anthropicClient = AnthropicOkHttpClient.builder()
        .apiKey("ANTHROPIC_API_KEY")
        .build();

    Claude claudeModel = new Claude(
        CLAUDE_MODEL_ID,
        anthropicClient
    );

    return LlmAgent.builder()
        .name("claude_direct_agent")
        .model(claudeModel)
        .instruction("You are a helpful AI assistant powered by Anthropic Claude.")
        // ... other LlmAgent configurations
        .build();
  }

  public static void main(String[] args) {
    try {
      LlmAgent agent = createAgent();
      System.out.println("Successfully created direct Anthropic agent: " + agent.name());
    } catch (IllegalStateException e) {
      System.err.println("Error creating agent: " + e.getMessage());
    }
  }
}
```

# Apigee AI Gateway for ADK agents

Supported in ADKPython v1.18.0Java v0.4.0

[Apigee](https://docs.cloud.google.com/apigee/docs/api-platform/get-started/what-apigee) provides a powerful [AI Gateway](https://cloud.google.com/solutions/apigee-ai), transforming how you manage and govern your generative AI model traffic. By exposing your AI model endpoint (like Agent Platform or the Gemini API) through an Apigee proxy, you immediately gain enterprise-grade capabilities:

- **Model Safety:** Implement security policies like Model Armor for threat protection.
- **Traffic Governance:** Enforce Rate Limiting and Token Limiting to manage costs and prevent abuse.
- **Performance:** Improve response times and efficiency using Semantic Caching and advanced model routing.
- **Monitoring & Visibility:** Get granular monitoring, analysis, and auditing of all your AI requests.

Note

The `ApigeeLLM` wrapper is currently designed for use with Agent Platform and the Gemini API (generateContent). We are continually expanding support for other models and interfaces.

## Example implementation

Integrate Apigee's governance into your agent's workflow by instantiating the `ApigeeLlm` wrapper object and pass it to an `LlmAgent` or other agent type.

```python
from google.adk.agents import LlmAgent
from google.adk.models.apigee_llm import ApigeeLlm

# Instantiate the ApigeeLlm wrapper
model = ApigeeLlm(
    # Specify the Apigee route to your model. For more info, check out the ApigeeLlm documentation (https://github.com/google/adk-python/tree/main/contributing/samples/hello_world_apigeellm).
    model="apigee/gemini-flash-latest",
    # The proxy URL of your deployed Apigee proxy including the base path
    proxy_url=f"https://{APIGEE_PROXY_URL}",
    # Pass necessary authentication/authorization headers (like an API key)
    custom_headers={"foo": "bar"}
)

# Pass the configured model wrapper to your LlmAgent
agent = LlmAgent(
    model=model,
    name="my_governed_agent",
    instruction="You are a helpful assistant powered by Gemini and governed by Apigee.",
    # ... other agent parameters
)
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.models.ApigeeLlm;
import com.google.common.collect.ImmutableMap;

ApigeeLlm apigeeLlm =
        ApigeeLlm.builder()
            .modelName("apigee/gemini-flash-latest") // Specify the Apigee route to your model. For more info, check out the ApigeeLlm documentation
            .proxyUrl(APIGEE_PROXY_URL) //The proxy URL of your deployed Apigee proxy including the base path
            .customHeaders(ImmutableMap.of("foo", "bar")) //Pass necessary authentication/authorization headers (like an API key)
            .build();
LlmAgent agent =
    LlmAgent.builder()
        .model(apigeeLlm)
        .name("my_governed_agent")
        .description("my_governed_agent")
        .instruction("You are a helpful assistant powered by Gemini and governed by Apigee.")
        // tools will be added next
        .build();
```

With this configuration, every API call from your agent will be routed through Apigee first, where all necessary policies (security, rate limiting, logging) are executed before the request is securely forwarded to the underlying AI model endpoint. For a full code example using the Apigee proxy, see [Hello World Apigee LLM](https://github.com/google/adk-python/tree/main/contributing/samples/hello_world_apigeellm).

# Google Gemini models for ADK agents

Supported in ADKPython v0.1.0Typescript v0.2.0Go v0.1.0Java v0.2.0

ADK supports the Google Gemini family of generative AI models that provide a powerful set of models with a wide range of features. ADK provides support for many Gemini features, including [Code Execution](/integrations/code-execution/), [Google Search](/integrations/google-search/), [Context caching](/context/caching/), [Computer use](/integrations/computer-use/) and the [Interactions API](#interactions-api).

## Get started

The following code examples show a basic implementation for using Gemini models in your agents:

```python
from google.adk.agents import LlmAgent

# --- Example using a stable Gemini Flash model ---
agent_gemini_flash = LlmAgent(
    # Use the latest stable Flash model identifier
    model="gemini-flash-latest",
    name="gemini_flash_agent",
    instruction="You are a fast and helpful Gemini assistant.",
    # ... other agent parameters
)
```

```typescript
import {LlmAgent} from '@google/adk';

// --- Example #2: using a powerful Gemini Pro model with API Key in model ---
export const rootAgent = new LlmAgent({
  name: 'hello_time_agent',
  model: 'gemini-flash-latest',
  description: 'Gemini flash agent',
  instruction: `You are a fast and helpful Gemini assistant.`,
});
```

```go
import (
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/genai"
)

// --- Example using a stable Gemini Flash model ---
modelFlash, err := gemini.NewModel(ctx, "gemini-2.0-flash", &genai.ClientConfig{})
if err != nil {
    log.Fatalf("failed to create model: %v", err)
}
agentGeminiFlash, err := llmagent.New(llmagent.Config{
    // Use the latest stable Flash model identifier
    Model:       modelFlash,
    Name:        "gemini_flash_agent",
    Instruction: "You are a fast and helpful Gemini assistant.",
    // ... other agent parameters
})
if err != nil {
    log.Fatalf("failed to create agent: %v", err)
}
```

```java
// --- Example #1: using a stable Gemini Flash model with ENV variables---
LlmAgent agentGeminiFlash =
    LlmAgent.builder()
        // Use the latest stable Flash model identifier
        .model("gemini-flash-latest") // Set ENV variables to use this model
        .name("gemini_flash_agent")
        .instruction("You are a fast and helpful Gemini assistant.")
        // ... other agent parameters
        .build();
```

Note: Gemini model selector `gemini-flash-latest`

Most code examples in ADK documentation use `gemini-flash-latest` to select the [latest available](https://ai.google.dev/gemini-api/docs/models#latest) Gemini Flash version. However, if you access Gemini from a regional endpoint, such as `us-central1`, this selection string may not work. In that case, use a specific model version string from the [Gemini models](https://ai.google.dev/gemini-api/docs/models) page or Google Cloud [Gemini models](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models) list.

## Gemini model authentication

This section covers authenticating with Google's Gemini models, either through Google AI Studio for rapid development or Google Cloud Agent Platform for enterprise applications. This is the most direct way to use Google's flagship models within ADK.

**Integration Method:** Once you are authenticated using one of the below methods, you can pass the model's identifier string directly to the `model` parameter of `LlmAgent`.

Tip

The `google-genai` library, used internally by ADK for Gemini models, can connect through either Google AI Studio or Agent Platform.

**Model support for voice/video streaming**

In order to use voice/video streaming in ADK, you will need to use Gemini models that support the Live API. You can find the **model ID(s)** that support the Gemini Live API in the documentation:

- [Google AI Studio: Gemini Live API](https://ai.google.dev/gemini-api/docs/models#live-api)
- [Agent Platform: Gemini Live API](https://cloud.google.com/vertex-ai/generative-ai/docs/live-api)

### Google AI Studio

This is the simplest method and is recommended for getting started quickly.

- **Authentication Method:** API Key

- **Setup:**

  1. **Get an API key:** Obtain your key from [Google AI Studio](https://aistudio.google.com/apikey).

  1. **Set environment variables:** Create a `.env` file (Python) or `.properties` (Java) in your project's root directory and add the following lines. ADK will automatically load this file.

     ```shell
     export GOOGLE_API_KEY="YOUR_GOOGLE_API_KEY"
     export GOOGLE_GENAI_USE_VERTEXAI=FALSE
     ```

     (or)

     Pass these variables during the model initialization via the `Client` (see example below).

- **Models:** Find all available models on the [Google AI for Developers site](https://ai.google.dev/gemini-api/docs/models).

### Google Cloud Agent Platform

For scalable and production-oriented use cases, Agent Platform is the recommended platform. Gemini on Agent Platform supports enterprise-grade features, security, and compliance controls. Based on your development environment and usecase, *choose one of the below methods to authenticate*.

**Pre-requisites:** A Google Cloud Project with [Agent Platform enabled](https://console.cloud.google.com/apis/enableflow;apiid=aiplatform.googleapis.com).

### **Method A: User Credentials (for Local Development)**

1. **Install the gcloud CLI:** Follow the official [installation instructions](https://cloud.google.com/sdk/docs/install).

1. **Log in using ADC:** This command opens a browser to authenticate your user account for local development.

   ```bash
   gcloud auth application-default login
   ```

1. **Set environment variables:**

   ```shell
   export GOOGLE_CLOUD_PROJECT="YOUR_PROJECT_ID"
   export GOOGLE_CLOUD_LOCATION="YOUR_VERTEX_AI_LOCATION" # e.g., us-central1
   ```

   Explicitly tell the library to use Agent Platform:

   ```shell
   export GOOGLE_GENAI_USE_VERTEXAI=TRUE
   ```

1. **Models:** Find available model IDs in the [Agent Platform documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/learn/models).

### **Method B: Agent Platform Express Mode**

[Agent Platform Express Mode](https://cloud.google.com/vertex-ai/generative-ai/docs/start/express-mode/overview) offers a simplified, API-key-based setup for rapid prototyping.

1. **Sign up for Express Mode** to get your API key.

1. **Set environment variables:**

   ```shell
   export GOOGLE_GENAI_API_KEY="PASTE_YOUR_EXPRESS_MODE_API_KEY_HERE"
   export GOOGLE_GENAI_USE_VERTEXAI=TRUE
   ```

### **Method C: Service Account (for Production & Automation)**

For deployed applications, a service account is the standard method.

1. [**Create a Service Account**](https://cloud.google.com/iam/docs/service-accounts-create#console) and grant it the `Agent Platform User` role.
1. **Provide credentials to your application:**
   - **On Google Cloud:** If you are running the agent in Cloud Run, GKE, VM or other Google Cloud services, the environment can automatically provide the service account credentials. You don't have to create a key file.

   - **Elsewhere:** Create a [service account key file](https://cloud.google.com/iam/docs/keys-create-delete#console) and point to it with an environment variable:

     ```bash
     export GOOGLE_APPLICATION_CREDENTIALS="/path/to/your/keyfile.json"
     ```

     Instead of the key file, you can also authenticate the service account using Workload Identity. But this is outside the scope of this guide.

Secure Your Credentials

Service account credentials or API keys are powerful credentials. Never expose them publicly. Use a secret manager such as [Google Cloud Secret Manager](https://cloud.google.com/security/products/secret-manager) to store and access them securely in production.

Gemini model versions

Always check the official Gemini documentation for the latest model names, including specific preview versions if needed. Preview models might have different availability or quota limitations.

## Troubleshooting

### Error Code 429 - RESOURCE_EXHAUSTED

This error usually happens if the number of your requests exceeds the capacity allocated to process requests.

To mitigate this, you can do one of the following:

1. Request higher quota limits for the model you are trying to use.

1. Enable client-side retries. Retries allow the client to automatically retry the request after a delay, which can help if the quota issue is temporary.

   There are two ways you can set retry options:

   **Option 1:** Set retry options on the Agent as a part of generate_content_config.

   You would use this option if you are instantiating this model adapter by yourself.

   ```python
   root_agent = Agent(
       model='gemini-flash-latest',
       # ...
       generate_content_config=types.GenerateContentConfig(
           # ...
           http_options=types.HttpOptions(
               # ...
               retry_options=types.HttpRetryOptions(initial_delay=1, attempts=2),
               # ...
           ),
           # ...
       )
   ```

   ```java
   import com.google.adk.agents.LlmAgent;
   import com.google.genai.types.GenerateContentConfig;
   import com.google.genai.types.HttpOptions;
   import com.google.genai.types.HttpRetryOptions;

   // ...

   LlmAgent rootAgent = LlmAgent.builder()
       .model("gemini-flash-latest")
       // ...
       .generateContentConfig(GenerateContentConfig.builder()
           // ...
           .httpOptions(HttpOptions.builder()
               // ...
               .retryOptions(HttpRetryOptions.builder().initialDelay(1.0).attempts(2).build())
               // ...
               .build())
           // ...
           .build())
       .build();
   ```

   **Option 2:** Retry options on this model adapter.

   You would use this option if you were instantiating the instance of adapter by yourself.

   ```python
   from google.genai import types

   # ...

   agent = Agent(
       model=Gemini(
       retry_options=types.HttpRetryOptions(initial_delay=1, attempts=2),
       )
   )
   ```

   ```java
   import com.google.adk.agents.LlmAgent;
   import com.google.adk.models.Gemini;
   import com.google.genai.Client;
   import com.google.genai.types.HttpOptions;
   import com.google.genai.types.HttpRetryOptions;

   // ...

   LlmAgent agent = LlmAgent.builder()
       .model(Gemini.builder()
           .modelName("gemini-flash-latest")
           .apiClient(Client.builder()
               .httpOptions(HttpOptions.builder()
                   .retryOptions(HttpRetryOptions.builder().initialDelay(1.0).attempts(2).build())
                   .build())
               .build())
           .build())
       .build();
   ```

## Gemini Interactions API

Supported in ADKPython v1.21.0

The Gemini [Interactions API](https://ai.google.dev/gemini-api/docs/interactions) is an alternative to the ***generateContent*** inference API, which provides stateful conversation capabilities, allowing you to chain interactions using a `previous_interaction_id` instead of sending the full conversation history with each request. Using this feature can be more efficient for long conversations.

You can enable the Interactions API by setting the `use_interactions_api=True` parameter in the Gemini model configuration, as shown in the following code snippet:

```python
from google.adk.agents.llm_agent import Agent
from google.adk.models.google_llm import Gemini
from google.adk.tools.google_search_tool import GoogleSearchTool

root_agent = Agent(
    model=Gemini(
        model="gemini-flash-latest",
        use_interactions_api=True,  # Enable Interactions API
    ),
    name="interactions_test_agent",
    tools=[
        GoogleSearchTool(bypass_multi_tools_limit=True),  # Converted to function tool
        get_current_weather,  # Custom function tool
    ],
)
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.models.Gemini;
import com.google.adk.tools.GoogleSearchTool;

// Note: Interactions API support in Java ADK is currently under development.
LlmAgent rootAgent = LlmAgent.builder()
    .model(Gemini.builder()
        .modelName("gemini-flash-latest")
        .build())
    .name("interactions_test_agent")
    .tools(
        GoogleSearchTool.INSTANCE, // Search tool
        getCurrentWeather // Custom function tool
    )
    .build();
```

For a complete code sample, see the [Interactions API sample](https://github.com/google/adk-python/tree/main/contributing/samples/interactions_api).

### Known limitations

The Interactions API **does not** support mixing custom function calling tools with built-in tools, such as the [Google Search](/integrations/google-search/), tool, within the same agent. You can work around this limitation by configuring the the built-in tool to operate as a custom tool using the `bypass_multi_tools_limit` parameter:

```python
# Use bypass_multi_tools_limit=True to convert google_search to a function tool
GoogleSearchTool(bypass_multi_tools_limit=True)
```

```java
// Note: bypassMultiToolsLimit is Python-specific.
// In Java, simply use the tool instance.
GoogleSearchTool.INSTANCE;
```

In this example, this option converts the built-in google_search to a function calling tool (via GoogleSearchAgentTool), which allows it to work alongside custom function tools.

# Google Gemma models for ADK agents

Supported in ADKPython v0.1.0

ADK agents can use the [Google Gemma](https://ai.google.dev/gemma/docs) family of generative AI models that offer a wide range of capabilities. ADK supports many Gemma features, including [Tool Calling](/tools-custom/) and [Structured Output](/agents/llm-agents/#structuring-data-input_schema-output_schema-output_key).

You can use Gemma 4 through the [Gemini API](https://ai.google.dev/gemini-api/docs), or with one of many self-hosting options on Google Cloud: [Agent Platform](https://console.cloud.google.com/vertex-ai/publishers/google/model-garden/gemma4), [Google Kubernetes Engine](https://docs.cloud.google.com/kubernetes-engine/docs/tutorials/serve-gemma-gpu-vllm), [Cloud Run](https://docs.cloud.google.com/run/docs/run-gemma-on-cloud-run).

## Gemini API Example

Create an API key in [Google AI Studio](https://aistudio.google.com/app/apikey).

```python
# Set GEMINI_API_KEY environment variable to your API key
# export GEMINI_API_KEY="YOUR_API_KEY"

from google.adk.agents import LlmAgent
from google.adk.models import Gemini

# Simple tool to try
def get_weather(location: str) -> str:
    return f"Location: {location}. Weather: sunny, 76 degrees Fahrenheit, 8 mph wind."

root_agent = LlmAgent(
    model=Gemini(model="gemma-4-31b-it"),
    name="weather_agent",
    instruction="You are a helpful assistant that can provide current weather.",
    tools=[get_weather]
)
```

```java
// Set GEMINI_API_KEY environment variable to your API key
// export GEMINI_API_KEY="YOUR_API_KEY"

import com.google.adk.agents.LlmAgent;
import com.google.adk.tools.Annotations.Schema;
import com.google.adk.tools.FunctionTool;

LlmAgent weatherAgent = LlmAgent.builder()
    .model("gemma-4-31b-it")
    .name("weather_agent")
    .instruction("""
        You are a helpful assistant that can provide current weather.
    """)
    .tools(FunctionTool.create(this, "getWeather")]    
    .build();

@Schema(name = "getWeather", 
        description = "Retrieve the weather forecast for a given location")
public Map<String, String> getWeather(
    @Schema(name = "location",
            description = "The location for the weather forecast")
    String location) {
    return Map.of("forecast", "Location: " + location 
        + ". Weather: sunny, 76 degrees Fahrenheit, 8 mph wind.");
}
```

## vLLM Example

To access Gemma 4 endpoints in these services, you can use vLLM models through the [LiteLLM](/agents/models/litellm/) library for Python, and through [LangChain4j](https://docs.langchain4j.dev/) for Java.

The following example shows how to use a Gemma 4 vLLM endpoint with ADK agents.

### Setup

1. **Deploy Model:** Deploy your chosen model using [Agent Platform](https://console.cloud.google.com/vertex-ai/publishers/google/model-garden/gemma4), [Google Kubernetes Engine](https://docs.cloud.google.com/kubernetes-engine/docs/tutorials/serve-gemma-gpu-vllm), or [Cloud Run](https://docs.cloud.google.com/run/docs/run-gemma-on-cloud-run), and use its OpenAI-compatible API endpoint. Note that the API base URL includes `/v1` (e.g., `https://your-vllm-endpoint.run.app/v1`).
   - *Important for ADK Tools:* When deploying, ensure the serving tool supports and enables compatible tool/function calling and reasoning parsers.
1. **Authentication:** Determine how your endpoint handles authentication (e.g., API key, bearer token).

### Code

```python
import subprocess
from google.adk.agents import LlmAgent
from google.adk.models.lite_llm import LiteLlm

# --- Example Agent using a model hosted on a vLLM endpoint ---

# Endpoint URL provided by your model deployment
api_base_url = "https://your-vllm-endpoint.run.app/v1"

# Model name as recognized by *your* vLLM endpoint configuration
model_name_at_endpoint = "openai/google/gemma-4-31B-it"

# Simple tool to try
def get_weather(location: str) -> str:
    return f"Location: {location}. Weather: sunny, 76 degrees Fahrenheit, 8 mph wind."

# Authentication (Example: using gcloud identity token for a Cloud Run deployment)
# Adapt this based on your endpoint's security
try:
    gcloud_token = subprocess.check_output(
        ["gcloud", "auth", "print-identity-token", "-q"]
    ).decode().strip()
    auth_headers = {"Authorization": f"Bearer {gcloud_token}"}
except Exception as e:
    print(f"Warning: Could not get gcloud token - {e}.")
    auth_headers = None # Or handle error appropriately

root_agent = LlmAgent(
    model=LiteLlm(
        model=model_name_at_endpoint,
        api_base=api_base_url,
        # Pass authentication headers if needed
        extra_headers=auth_headers
        # Alternatively, if endpoint uses an API key:
        # api_key="YOUR_ENDPOINT_API_KEY",
        extra_body={
            "chat_template_kwargs": {
                "enable_thinking": True # Enable thinking
            },
            "skip_special_tokens": False # Should be set to False
        },
    ),
    name="weather_agent",
    instruction="You are a helpful assistant that can provide current weather.",
    tools=[get_weather] # Tools!
)
```

To use Gemma hosted on vLLM, you must use an OpenAI compatible library. LangChain4j offers an OpenAI dependency that you can add to your `pom.xml`:

```xml
<!-- LangChain4j to ADK bridge -->
<dependency>
    <groupId>com.google.adk</groupId>
    <artifactId>google-adk-langchain4j</artifactId>
    <version>${adk.version}</version>
</dependency>
<!-- Core LangChain4j library -->
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j-core</artifactId>
    <version>${langchain4j.version}</version>
</dependency>
<!-- OpenAI compatible model -->
<dependency>
    <groupId>dev.langchain4j</groupId>
    <artifactId>langchain4j-open-ai</artifactId>
    <version>${langchain4j.version}</version>
</dependency>
```

Create an OpenAI compatible chat model (streaming or non-streaming), wrap it with the `LangChain4j` wrapper, then pass it to the `LlmAgent`:

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.tools.Annotations.Schema;
import com.google.adk.tools.FunctionTool;
import dev.langchain4j.model.chat.StreamingChatModel;
import dev.langchain4j.model.openai.OpenAiStreamingChatModel;

// Endpoint URL provided by your model deployment
String apiBaseUrl = "https://your-vllm-endpoint.run.app/v1";

// Model name as recognized by *your* vLLM endpoint configuration
String gemmaModelName = "gg-hf-gg/gemma-4-31b-it";

// First, define an OpenAI compatible chat model with LangChain4j
StreamingChatModel model =
    OpenAiStreamingChatModel.builder()
        .modelName(gemmaModelName)
        // If your endpoint requires an API key
        // .apiKey("YOUR_ENDPOINT_API_KEY")
        .baseUrl(apiBaseUrl)
        .customParameters(
            Map.of(
                "skip_special_tokens", false,
                "chat_template_kwargs", Map.of("enable_thinking", true)
            )
        )
        .build();

// Configure the agent with the LangChain4j wrapper model
LlmAgent weatherAgent = LlmAgent.builder()
    .model(new LangChain4j(model))
    .name("weather_agent")
    .instruction("""
        You are a helpful assistant that can provide the current weather.
    """)
    .tools(FunctionTool.create(this, "getWeather")]    
    .build();

@Schema(name = "getWeather", 
        description = "Retrieve the weather forecast for a given location")
public Map<String, String> getWeather(
    @Schema(name = "location",
            description = "The location for the weather forecast")
    String location) {
    return Map.of("forecast", "Location: " + location 
        + ". Weather: sunny, 76 degrees Fahrenheit, 8 mph wind.");
}
```

## Build a food tour agent with Gemma 4, ADK, and Google Maps MCP

This sample shows how to build a personalized food tour agent using Gemma 4, ADK, and the Google Maps MCP server. The agent takes a user’s dish photo or text description, a location, and an optional budget, then recommends places to eat and organizes them into a walking route.

### Prerequisites

- Get an API key in [Google AI Studio](https://aistudio.google.com/app/apikey). Set `GEMINI_API_KEY` environment variable to your Gemini API key.
- Enable [Google Maps API](https://console.cloud.google.com/maps-api/) on Google Cloud Console.
- Create a [Google Maps Platform API key](https://console.cloud.google.com/maps-api/credentials). Set `MAPS_API_KEY` environment variable to your API key.
- Install ADK and configure it in your Python environment or configure the Java dependencies in your Java project.

### Project structure

```bash
food_tour_app/
├── __init__.py
└── agent.py
```

**Full project can be found [here](https://github.com/google/adk-samples/tree/main/python/agents/gemma-food-tour-guide)**

`agent.py`

```python
import os
import dotenv
from google.adk.agents import LlmAgent
from google.adk.models import Gemini
from google.adk.tools.mcp_tool.mcp_toolset import MCPToolset
from google.adk.tools.mcp_tool.mcp_session_manager import StreamableHTTPConnectionParams

dotenv.load_dotenv()

system_instruction = """
You are an expert personalized food tour guide.
Your goal is to build a culinary tour based on the user's inputs: a photo of a dish (or a text description), a location, and a budget.

Follow these 4 rigorous steps:
1. **Identify the Cuisine/Dish:** Analyze the user's provided description or image URL to determine the primary cuisine or specific dish.
2. **Find the Best Spots:** Use the `search_places` tool to find highly rated restaurants, stalls, or cafes serving that cuisine/dish in the user's specified location.
   **CRITICAL RULE FOR PLACES:** `search_places` returns AI-generated place data summaries along with `place_id`, latitude/longitude coordinates, and map links for each place, but may lack a direct, explicit name field. You must carefully associate each described place to its provided `place_id` or `lat_lng`.
3. **Build the Route:** Use the `compute_routes` tool to structure a walking-optimized route between the selected spots.
   **CRITICAL ROUTING RULE:** To avoid hallucinating, you MUST provide the `origin` and `destination` using the exact `place_id` string OR `lat_lng` object returned by `search_places`. Do NOT guess or hallucinate an `address` or `place_id` if you do not know the exact name.
4. **Insider Tips:** Provide specific "order this, skip that" insider tips for each location on the tour.

Structure your response clearly and concisely. If the user provides a budget, ensure your suggestions align with it.
"""

MAPS_MCP_URL = "https://mapstools.googleapis.com/mcp"

def get_maps_mcp_toolset():
    dotenv.load_dotenv()
    maps_api_key = os.getenv("MAPS_API_KEY")
    if not maps_api_key:
        print("Warning: MAPS_API_KEY environment variable not found.")
        maps_api_key = "no_api_found"

    tools = MCPToolset(
        connection_params=StreamableHTTPConnectionParams(
            url=MAPS_MCP_URL,
            headers={
                "X-Goog-Api-Key": maps_api_key
            }
        )
    )
    print("Google Maps MCP Toolset configured.")
    return tools

maps_toolset = get_maps_mcp_toolset()

root_agent = LlmAgent(
    model=Gemini(model="gemma-4-31b-it"),
    name="food_tour_agent",
    instruction=system_instruction,
    tools=[maps_toolset],
)
```

### Environment variables

Set the required environment variables before running the agent.

```text
export MAPS_API_KEY="YOUR_GOOGLE_MAPS_API_KEY"
export GEMINI_API_KEY="YOUR_GEMINI_API_KEY"
```

### Example usage

To test out the capabilities of the Food Tour Agent, try pasting one of these prompts into the chat:

- *"I want to do a ramen tour in Toronto. My budget is $60 for the day. Give me a walking route for the top 3 spots and tell me what I should order at each."*
- *"I have this photo of a deep dish pizza [insert image URL]. I want to find the best places for this around Navy Pier in Chicago. Structure a walking tour and tell me what the must-have slice is at each stop."*
- *"I'm in Downtown Austin looking for an authentic BBQ tour. Let's keep the budget under $100. Build a walking route between 3 highly-rated spots and give me insider tips on the best cuts of meat to get."*

The agent will:

1. Infer the likely cuisine or dish style
1. Search for relevant places using Google Maps MCP tools
1. Compute a walking route between selected stops
1. Return a structured food tour with recommendations and insider tips

# LiteLLM model connector for ADK agents

Supported in ADKPython v0.1.0

ADK Python Security Advisory: LiteLLM supply chain compromise

Unauthorized code was identified in LiteLLM versions 1.82.7 and 1.82.8 on PyPI on March 24, 2026. If you use ADK Python with the `eval` or `extensions` extras, update to the latest version of ADK Python immediately. If you installed or upgraded LiteLLM during this period, rotate all secrets and credentials. For details and required actions, refer to the [ADK security advisory](https://github.com/google/adk-python/issues/5005) and [LiteLLM's Security Update: Suspected Supply Chain Incident](https://docs.litellm.ai/blog/security-update-march-2026).

[LiteLLM](https://docs.litellm.ai/) is a Python library that acts as a translation layer for models and model hosting services, providing a standardized, OpenAI-compatible interface to over 100+ LLMs. ADK provides integration through the LiteLLM library, allowing you to access a vast range of LLMs from providers like OpenAI, Anthropic (non-Agent Platform), Cohere, and many others. You can run open-source models locally or self-host them and integrate them using LiteLLM for operational control, cost savings, privacy, or offline use cases.

You can use the LiteLLM library to access remote or locally hosted AI models:

- **Remote model host:** Use the `LiteLlm` wrapper class and set it as the `model` parameter of `LlmAgent`.
- **Local model host:** Use the `LiteLlm` wrapper class configured to point to your local model server. For examples of local model hosting solutions, see the [Ollama](/agents/models/ollama/) or [vLLM](/agents/models/vllm/) documentation.

Windows Encoding with LiteLLM

When using ADK agents with LiteLLM on Windows, you might encounter a `UnicodeDecodeError`. This error occurs because LiteLLM may attempt to read cached files using the default Windows encoding (`cp1252`) instead of UTF-8. Prevent this error by setting the `PYTHONUTF8` environment variable to `1`. This forces Python to use UTF-8 for all file I/O.

**Example (PowerShell):**

```powershell
# Set for the current session
$env:PYTHONUTF8 = "1"

# Set persistently for the user
[System.Environment]::SetEnvironmentVariable('PYTHONUTF8', '1', [System.EnvironmentVariableTarget]::User)
```

## Setup

1. **Install LiteLLM:**

   ```shell
   pip install litellm
   ```

1. **Set Provider API Keys:** Configure API keys as environment variables for the specific providers you intend to use.

   - *Example for OpenAI:*

     ```shell
     export OPENAI_API_KEY="YOUR_OPENAI_API_KEY"
     ```

   - *Example for Anthropic (non-Agent Platform):*

     ```shell
     export ANTHROPIC_API_KEY="YOUR_ANTHROPIC_API_KEY"
     ```

   - *Consult the [LiteLLM Providers Documentation](https://docs.litellm.ai/docs/providers) for the correct environment variable names for other providers.*

## Example implementation

```python
from google.adk.agents import LlmAgent
from google.adk.models.lite_llm import LiteLlm

# --- Example Agent using OpenAI's GPT-4o ---
# (Requires OPENAI_API_KEY)
agent_openai = LlmAgent(
    model=LiteLlm(model="openai/gpt-4o"), # LiteLLM model string format
    name="openai_agent",
    instruction="You are a helpful assistant powered by GPT-4o.",
    # ... other agent parameters
)

# --- Example Agent using Anthropic's Claude Haiku (non-Vertex) ---
# (Requires ANTHROPIC_API_KEY)
agent_claude_direct = LlmAgent(
    model=LiteLlm(model="anthropic/claude-3-haiku-20240307"),
    name="claude_direct_agent",
    instruction="You are an assistant powered by Claude Haiku.",
    # ... other agent parameters
)
```

# LiteRT-LM model host for ADK agents

Supported in ADKPython v0.1.0

[LiteRT-LM](https://github.com/google-ai-edge/LiteRT-LM) is a C++ library to efficiently run language models across edge platforms. On desktop (Linux, macOS, and Windows), ADK integrates with LiteRT-LM-hosted models through the LiteRT-LM server launched by the LiteRT-LM CLI `lit`.

## Get started

LiteRT-LM works with the `Gemini` class. You only have to set the `base_url` and `model` parameters.

1. Set `base_url` to the LiteRT-LM server URL, for example: `localhost:8001`.
1. Set `model` to the LiteRT-LM model name, for example: `gemma3n-e2b`.

```py
from google.adk.agents import Agent
from google.adk.models import Gemini

root_agent = Agent(
    model=Gemini(
        model="gemma3n-e2b",
        base_url="http://localhost:8001",
    ),
    name="dice_agent",
    description=(
        "hello world agent that can roll a die of 8 sides and check prime"
        " numbers."
    ),
    instruction="""
      You roll dice and answer questions about the outcome of the dice rolls.
    """,
    tools=[
        roll_die,
        check_prime,
    ],
)
```

Then run the agent as usual:

```bash
adk web
```

## Running the LiteRT-LM Server

The LiteRT-LM server is a separate process that serves LiteRT-LM models. It is started by the LiteRT-LM CLI tool `lit`.

### Download the `lit` CLI tool

Download the `lit` CLI tool by following these [instructions](https://github.com/google-ai-edge/LiteRT-LM?tab=readme-ov-file#desktop-cli-lit) in the LiteRT-LM GitHub repository.

### Download a model

Before you start the server, you need to download a model. You'll need a *Hugging Face* user access token to download a LiteRT-LM model using `lit`. You can get a token for your *Hugging Face* account [here](https://huggingface.co/settings/tokens).

To see a list of models available for download, use the `lit list` command:

```bash
lit list --show_all
```

Download a model using the `lit pull` command:

```bash
export HUGGING_FACE_HUB_TOKEN="**your Hugging Face token**"
lit pull gemma3n-e2b
```

### Run the server

After downloading a model, start the LiteRT-LM server locally by running the following command:

```bash
lit serve --port 8001
```

Local Server Port Number

You may choose any port number for the LiteRT-LM server as long as it matches the `base_url` you set in the `Gemini` class in your agent code.

### Debugging

To see incoming requests to the LiteRT-LM server and the exact input sent to the model, use the `--verbose` flag:

```bash
lit serve --port 8001 --verbose
```

# Ollama model host for ADK agents

Supported in ADKPython v0.1.0

[Ollama](https://ollama.com/) is a tool that allows you to host and run open-source models locally. ADK integrates with Ollama-hosted models through the [LiteLLM](/agents/models/litellm/) model connector library.

## Get started

Use the LiteLLM wrapper to create agents with Ollama-hosted models. The following code example shows a basic implementation for using Gemma open models with your agents:

```py
root_agent = Agent(
    model=LiteLlm(model="ollama_chat/gemma3:latest"),
    name="dice_agent",
    description=(
        "hello world agent that can roll a dice of 8 sides and check prime"
        " numbers."
    ),
    instruction="""
      You roll dice and answer questions about the outcome of the dice rolls.
    """,
    tools=[
        roll_die,
        check_prime,
    ],
)
```

Warning: Use `ollama_chat`interface

Make sure you set the provider `ollama_chat` instead of `ollama`. Using `ollama` can result in unexpected behaviors such as infinite tool call loops and ignoring previous context.

Use `OLLAMA_API_BASE` environment variable

Although you can specify the `api_base` parameter in LiteLLM for generation, as of v1.65.5, the library relies on the environment variable for other API calls. Therefore, you should set the `OLLAMA_API_BASE` environment variable for your Ollama server URL to ensure all requests are routed correctly.

```bash
export OLLAMA_API_BASE="http://localhost:11434"
adk web
```

## Model choice

If your agent is relying on tools, make sure that you select a model with tool support from [Ollama website](https://ollama.com/search?c=tools). For reliable results, use a model with tool support. You can check tool support for the model using the following command:

```bash
ollama show mistral-small3.1
  Model
    architecture        mistral3
    parameters          24.0B
    context length      131072
    embedding length    5120
    quantization        Q4_K_M

  Capabilities
    completion
    vision
    tools
```

You should see **tools** listed under capabilities. You can also look at the template the model is using and tweak it based on your needs.

```bash
ollama show --modelfile llama3.2 > model_file_to_modify
```

For instance, the default template for the above model inherently suggests that the model shall call a function all the time. This may result in an infinite loop of function calls.

```text
Given the following functions, please respond with a JSON for a function call
with its proper arguments that best answers the given prompt.

Respond in the format {"name": function name, "parameters": dictionary of
argument name and its value}. Do not use variables.
```

You can swap such prompts with a more descriptive one to prevent infinite tool call loops, for instance:

```text
Review the user's prompt and the available functions listed below.

First, determine if calling one of these functions is the most appropriate way
to respond. A function call is likely needed if the prompt asks for a specific
action, requires external data lookup, or involves calculations handled by the
functions. If the prompt is a general question or can be answered directly, a
function call is likely NOT needed.

If you determine a function call IS required: Respond ONLY with a JSON object in
the format {"name": "function_name", "parameters": {"argument_name": "value"}}.
Ensure parameter values are concrete, not variables.

If you determine a function call IS NOT required: Respond directly to the user's
prompt in plain text, providing the answer or information requested. Do not
output any JSON.
```

Then you can create a new model with the following command:

```bash
ollama create llama3.2-modified -f model_file_to_modify
```

## Use OpenAI provider

Alternatively, you can use `openai` as the provider name. This approach requires setting the `OPENAI_API_BASE=http://localhost:11434/v1` and `OPENAI_API_KEY=anything` env variables instead of `OLLAMA_API_BASE`. Note that the `API_BASE` value has *`/v1`* at the end.

```py
root_agent = Agent(
    model=LiteLlm(model="openai/mistral-small3.1"),
    name="dice_agent",
    description=(
        "hello world agent that can roll a dice of 8 sides and check prime"
        " numbers."
    ),
    instruction="""
      You roll dice and answer questions about the outcome of the dice rolls.
    """,
    tools=[
        roll_die,
        check_prime,
    ],
)
```

```bash
export OPENAI_API_BASE=http://localhost:11434/v1
export OPENAI_API_KEY=anything
adk web
```

### Debugging

You can see the request sent to the Ollama server by adding the following in your agent code just after imports.

```py
import litellm
litellm._turn_on_debug()
```

Look for a line like the following:

```bash
Request Sent from LiteLLM:
curl -X POST \
http://localhost:11434/api/chat \
-d '{'model': 'mistral-small3.1', 'messages': [{'role': 'system', 'content': ...
```

# Route between models

Supported in ADKTypeScript v1.0.0Experimental

Experimental

Model routing is experimental and may change in future releases. We welcome your [feedback](https://github.com/google/adk-js/issues/new?template=feature_request.md)!

An `LlmAgent` uses a single model by default. When you need to dynamically select between different models for each request, you can define a routing function that chooses which model to use. `RoutedLlm` provides this capability, enabling model fallback on error, A/B testing between models, and auto-routing by input complexity. If the selected model fails before producing any output, the routing function is called again with error context so it can select a different model.

Pass a `RoutedLlm` as an `LlmAgent`'s `model` parameter. Use `RoutedLlm` when only the model varies between routes. If you also need to switch instructions, tools, or sub-agents, use [`RoutedAgent`](https://adk.dev/agents/routing/index.md) instead.

## How routing works

The `LlmRouter` function receives the map of available models and the current `LlmRequest`, and returns the key of the model to use:

```typescript
type LlmRouter = (
  models: Readonly<Record<string, BaseLlm>>,
  request: LlmRequest,
  errorContext?: { failedKeys: ReadonlySet<string>; lastError: unknown },
) => Promise<string | undefined> | string | undefined;
```

The `models` parameter accepts either a `Record<string, BaseLlm>` with explicit keys, or an array of `BaseLlm` instances. If an array is provided, each model's name is used as its key.

Failover follows the same rules as [`RoutedAgent`](https://adk.dev/agents/routing/#how-routing-works): the router is re-called with `errorContext` only if the selected model fails before yielding any response. After yielding, errors propagate without retry. The router can return `undefined` to stop retrying and propagate the last error.

**Live connections:** `RoutedLlm.connect()` selects the model at connection time. Once a live connection is established, the model cannot be switched mid-stream.

## Basic usage

The following example creates a `RoutedLlm` that tries a primary model first and falls back to a secondary model if the primary fails. The router checks `errorContext.failedKeys` to avoid re-selecting the failed model:

```typescript
import {
  BaseLlm,
  Gemini,
  LlmRequest,
  LlmAgent,
  RoutedLlm,
  InMemoryRunner,
} from '@google/adk';

const primaryModel = new Gemini({ model: 'gemini-flash-latest' });
const fallbackModel = new Gemini({ model: 'gemini-pro-latest' });

const router = (
  models: Readonly<Record<string, BaseLlm>>,
  request: LlmRequest,
  // errorContext is provided when a previously selected model fails
  errorContext?: { failedKeys: ReadonlySet<string>; lastError: unknown },
) => {
  if (!errorContext) {
    return 'primary'; // Try primary first
  }
  if (errorContext.failedKeys.has('primary')) {
    return 'fallback'; // Fall back if primary failed
  }
  return undefined; // No more options, propagate the error
};

const routedLlm = new RoutedLlm({
  models: { primary: primaryModel, fallback: fallbackModel },
  router,
});

// Use RoutedLlm as the model for an LlmAgent
const agent = new LlmAgent({
  name: 'my_agent',
  model: routedLlm,
  instruction: 'You are a helpful assistant.',
});

const runner = new InMemoryRunner({ agent, appName: 'my_app' });

const session = await runner.sessionService.createSession({
  appName: 'my_app',
  userId: 'user_1',
});

const run = runner.runAsync({
  userId: 'user_1',
  sessionId: session.id,
  newMessage: { role: 'user', parts: [{ text: 'Hello!' }] },
});

for await (const event of run) {
  if (event.content?.parts?.[0]?.text) {
    console.log(event.content.parts[0].text);
  }
}
```

# vLLM model host for ADK agents

Supported in ADKPython v0.1.0

Tools such as [vLLM](https://github.com/vllm-project/vllm) allow you to host models efficiently and serve them as an OpenAI-compatible API endpoint. You can use vLLM models through the [LiteLLM](/agents/models/litellm/) library for Python.

## Setup

1. **Deploy Model:** Deploy your chosen model using vLLM (or a similar tool). Note the API base URL (e.g., `https://your-vllm-endpoint.run.app/v1`).
   - *Important for ADK Tools:* When deploying, ensure the serving tool supports and enables OpenAI-compatible tool/function calling. For vLLM, this might involve flags like `--enable-auto-tool-choice` and potentially a specific `--tool-call-parser`, depending on the model. Refer to the vLLM documentation on Tool Use.
1. **Authentication:** Determine how your endpoint handles authentication (e.g., API key, bearer token).

## Integration Example

The following example shows how to use a vLLM endpoint with ADK agents.

```python
import subprocess
from google.adk.agents import LlmAgent
from google.adk.models.lite_llm import LiteLlm

# --- Example Agent using a Gemma 4 model hosted on a vLLM endpoint ---

# Endpoint URL provided by your vLLM deployment
api_base_url = "https://your-vllm-endpoint.run.app/v1"

# Model name as recognized by *your* vLLM endpoint configuration
model_name_at_endpoint = "hosted_vllm/google/gemma-4-E4B-it" # Example from vllm_test.py

# Authentication (Example: using gcloud identity token for a Cloud Run deployment)
# Adapt this based on your endpoint's security
try:
    gcloud_token = subprocess.check_output(
        ["gcloud", "auth", "print-identity-token", "-q"]
    ).decode().strip()
    auth_headers = {"Authorization": f"Bearer {gcloud_token}"}
except Exception as e:
    print(f"Warning: Could not get gcloud token - {e}. Endpoint might be unsecured or require different auth.")
    auth_headers = None # Or handle error appropriately

agent_vllm = LlmAgent(
    model=LiteLlm(
        model=model_name_at_endpoint,
        api_base=api_base_url,
        # This extra_body values specific to Gemma 4.
        extra_body={
            "chat_template_kwargs": {
                "enable_thinking": True # Enable thinking
            },
            "skip_special_tokens": False # Should be set to False
        },
        # Pass authentication headers if needed
        extra_headers=auth_headers,
        # Alternatively, if endpoint uses an API key:
        # api_key="YOUR_ENDPOINT_API_KEY"
    ),
    name="vllm_agent",
    instruction="You are a helpful assistant running on a self-hosted vLLM endpoint.",
    # ... other agent parameters
)
```




