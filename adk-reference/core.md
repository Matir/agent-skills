# Agent Development Kit (ADK)

> Build powerful multi-agent systems with Agent Development Kit (ADK)

An open-source, code-first toolkit for building, evaluating, and deploying sophisticated AI agents with flexibility and control.

# Build Agents

# Get started

Agent Development Kit (ADK) is designed to empower developers to quickly build, manage, evaluate and deploy AI-powered agents. These quick start guides get you set up and running a simple agent in less than 20 minutes.

- **Python Quickstart**

  ______________________________________________________________________

  Create your first Python ADK agent in minutes.

  [Start with Python](https://adk.dev/get-started/python/index.md)

- **Go Quickstart**

  ______________________________________________________________________

  Create your first Go ADK agent in minutes.

  [Start with Go](https://adk.dev/get-started/go/index.md)

- **Java Quickstart**

  ______________________________________________________________________

  Create your first Java ADK agent in minutes.

  [Start with Java](https://adk.dev/get-started/java/index.md)

- **TypeScript Quickstart**

  ______________________________________________________________________

  Create your first TypeScript ADK agent in minutes.

  [Start with TypeScript](https://adk.dev/get-started/typescript/index.md)

To get started with a technical overview check this [link](https://adk.dev/get-started/about/index.md).

# Agent Development Kit (ADK)

**Build, Evaluate and Deploy agents, seamlessly!**

ADK is designed to empower developers to build, manage, evaluate and deploy AI-powered agents. It provides a robust and flexible environment for creating both conversational and non-conversational agents, capable of handling complex tasks and workflows.

## Core Concepts

ADK is built around a few key primitives and concepts that make it powerful and flexible. Here are the essentials:

- **Agent:** The fundamental worker unit designed for specific tasks. Agents can use language models (`LlmAgent`) for complex reasoning, or act as deterministic controllers of the execution, which are called "[workflow agents](https://adk.dev/agents/workflow-agents/index.md)" (`SequentialAgent`, `ParallelAgent`, `LoopAgent`).
- **Tool:** Gives agents abilities beyond conversation, letting them interact with external APIs, search information, run code, or call other services.
- **Callbacks:** Custom code snippets you provide to run at specific points in the agent's process, allowing for checks, logging, or behavior modifications.
- **Session Management (`Session` & `State`):** Handles the context of a single conversation (`Session`), including its history (`Events`) and the agent's working memory for that conversation (`State`).
- **Memory:** Enables agents to recall information about a user across *multiple* sessions, providing long-term context (distinct from short-term session `State`).
- **Artifact Management (`Artifact`):** Allows agents to save, load, and manage files or binary data (like images, PDFs) associated with a session or user.
- **Code Execution:** The ability for agents (usually via Tools) to generate and execute code to perform complex calculations or actions.
- **Planning:** An advanced capability where agents can break down complex goals into smaller steps and plan how to achieve them like a ReAct planner.
- **Models:** The underlying LLM that powers `LlmAgent`s, enabling their reasoning and language understanding abilities.
- **Event:** The basic unit of communication representing things that happen during a session (user message, agent reply, tool use), forming the conversation history.
- **Runner:** The engine that manages the execution flow, orchestrates agent interactions based on Events, and coordinates with backend services.

***Note:** Features like Multimodal Streaming, Evaluation, Deployment, Debugging, and Trace are also part of the broader ADK ecosystem, supporting real-time interaction and the development lifecycle.*

## Key Capabilities

ADK offers several key advantages for developers building agentic applications:

1. **Multi-Agent System Design:** Easily build applications composed of multiple, specialized agents arranged hierarchically. Agents can coordinate complex tasks, delegate sub-tasks using LLM-driven transfer or explicit `AgentTool` invocation, enabling modular and scalable solutions.
1. **Rich Tool Ecosystem:** Equip agents with diverse capabilities. ADK supports integrating custom functions (`FunctionTool`), using other agents as tools (`AgentTool`), leveraging built-in functionalities like code execution, and interacting with external data sources and APIs (e.g., Search, Databases). Support for long-running tools allows handling asynchronous operations effectively.
1. **Flexible Orchestration:** Define complex agent workflows using built-in workflow agents (`SequentialAgent`, `ParallelAgent`, `LoopAgent`) alongside LLM-driven dynamic routing. This allows for both predictable pipelines and adaptive agent behavior.
1. **Integrated Developer Tooling:** Develop and iterate locally with ease. ADK includes tools like a command-line interface (CLI) and a Developer UI for running agents, inspecting execution steps (events, state changes), debugging interactions, and visualizing agent definitions.
1. **Native Streaming Support:** Build real-time, interactive experiences with [ADK Gemini Live API Toolkit](https://adk.dev/streaming/index.md) that provides native support for bidirectional streaming (text and audio). This integrates seamlessly with underlying capabilities like the [Gemini Live API for the Gemini Developer API](https://ai.google.dev/gemini-api/docs/live) (or for [Agent Platform](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/multimodal-live)), often enabled with simple configuration changes.
1. **Built-in Agent Evaluation:** Assess agent performance systematically. The framework includes tools to create multi-turn evaluation datasets and run evaluations locally (via CLI or the dev UI) to measure quality and guide improvements.
1. **Broad LLM Support:** While optimized for Google's Gemini models, the framework is designed for flexibility, allowing integration with various LLMs (potentially including open-source or fine-tuned models) through its `BaseLlm` interface.
1. **Artifact Management:** Enable agents to handle files and binary data. The framework provides mechanisms (`ArtifactService`, context methods) for agents to save, load, and manage versioned artifacts like images, documents, or generated reports during their execution.
1. **Extensibility and Interoperability:** ADK promotes an open ecosystem. While providing core tools, it allows developers to easily integrate and reuse third-party tools and data connectors.
1. **State and Memory Management:** Automatically handles short-term conversational memory (`State` within a `Session`) managed by the `SessionService`. Provides integration points for longer-term `Memory` services, allowing agents to recall user information across multiple sessions.

## Get Started

- Ready to build your first agent? [Get started](/get-started/)!




# Installing ADK

## Create & activate virtual environment

We recommend creating a virtual Python environment using [venv](https://docs.python.org/3/library/venv.html):

```shell
python3 -m venv .venv
```

Now, you can activate the virtual environment using the appropriate command for your operating system and environment:

```text
# Mac / Linux
source .venv/bin/activate

# Windows CMD:
.venv\Scripts\activate.bat

# Windows PowerShell:
.venv\Scripts\Activate.ps1
```

### Install ADK

```bash
pip install google-adk
```

(Optional) Verify your installation:

```bash
pip show google-adk
```

### Install ADK and ADK DevTools

```bash
npm install @google/adk @google/adk-devtools
```

## Create a new Go module

If you are starting a new project, you can create a new Go module:

```shell
go mod init example.com/my-agent
```

## Install ADK

To add the ADK to your project, run the following command:

```shell
go get google.golang.org/adk
```

This will add the ADK as a dependency to your `go.mod` file.

(Optional) Verify your installation by checking your `go.mod` file for the `google.golang.org/adk` entry.

You can either use maven or gradle to add the `google-adk` and `google-adk-dev` package.

`google-adk` is the core Java ADK library. Java ADK also comes with a pluggable example SpringBoot server to run your agents seamlessly. This optional package is present as part of `google-adk-dev`.

If you are using maven, add the following to your `pom.xml`:

pom.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://maven.apache.org/POM/4.0.0 http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example.agent</groupId>
    <artifactId>adk-agents</artifactId>
    <version>1.0-SNAPSHOT</version>

    <!-- Specify the version of Java you'll be using -->
    <properties>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <!-- The ADK core dependency -->
        <dependency>
            <groupId>com.google.adk</groupId>
            <artifactId>google-adk</artifactId>
            <version>1.2.0</version>
        </dependency>
        <!-- The ADK dev web UI to debug your agent -->
        <dependency>
            <groupId>com.google.adk</groupId>
            <artifactId>google-adk-dev</artifactId>
            <version>1.2.0</version>
        </dependency>
    </dependencies>

</project>
```

Here's a [complete pom.xml](https://github.com/google/adk-docs/tree/main/examples/java/cloud-run/pom.xml) file for reference.

If you are using gradle, add the dependency to your build.gradle:

build.gradle

```text
dependencies {
    implementation 'com.google.adk:google-adk:1.2.0'
    implementation 'com.google.adk:google-adk-dev:1.2.0'
}
```

You should also configure Gradle to pass `-parameters` to `javac`. (Alternatively, use `@Schema(name = "...")`).

## Next steps

- Try creating your first agent with the [**Get started**](/get-started/) guides.




