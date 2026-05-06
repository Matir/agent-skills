# Grounding agents with data

Grounding is the process that connects your AI agents to external information sources, allowing them to generate more accurate, current, and verifiable responses. By grounding agent responses in authoritative data, you can reduce hallucinations and provide users with answers backed by reliable sources.

ADK supports multiple grounding approaches:

- **Google Search Grounding**: Connect agents to real-time web information for queries requiring current data like news, weather, or facts that may have changed since the model's training.

- **Grounding with Search**: Connect agents to your organization's private documents and enterprise data for queries requiring proprietary information.

- **Agentic RAG**: Build agents that reason about how to search, constructing queries and filters dynamically using Agent Retrieval, Knowledge Engine, or other retrieval systems.

- **Google Search Grounding**

  ______________________________________________________________________

  Enable your agents to access real-time, authoritative information from the web. Learn how to set up Google Search grounding, understand the data flow, interpret grounded responses, and display citations to users.

  - [Understanding Google Search Grounding](https://adk.dev/grounding/google_search_grounding/index.md)

- **Grounding with Search**

  ______________________________________________________________________

  Connect your agents to indexed enterprise documents and private data repositories. Learn how to configure Agent Search datastores, ground responses in your organization's knowledge base, and provide source attribution.

  - [Understanding Grounding with Search](https://adk.dev/grounding/grounding_with_search/index.md)

- **Blog post: 10-minute Agentic RAG with Vector Search 2.0 and ADK**

  ______________________________________________________________________

  Learn how to build an Agentic RAG system that goes beyond simple retrieve-then-generate patterns. This article walks through building a travel agent that parses user intent, constructs metadata filters, and searches 2,000 London Airbnb listings using hybrid search with Vector Search 2.0 and ADK.

  - [Blog post: 10-minute Agentic RAG with Vector Search 2.0 and ADK](https://medium.com/google-cloud/10-minute-agentic-rag-with-the-new-vector-search-2-0-and-adk-655fff0bacac)

- **Vector Search 2.0 Travel Agent Notebook**

  ______________________________________________________________________

  A hands-on Jupyter notebook companion to the Agentic RAG blog post. Build an end-to-end travel agent using real Airbnb data, auto-embeddings, hybrid search with RRF ranking, and ADK tool integration.

  - [Vector Search 2.0 Travel Agent Notebook](https://github.com/google/adk-samples/blob/main/python/notebooks/grounding/vectorsearch2_travel_agent.ipynb)

- **Deep Search Agent**

  ______________________________________________________________________

  A production-ready fullstack research agent that transforms topics into comprehensive reports with citations. Features a two-phase workflow with human-in-the-loop plan approval, iterative search refinement, and multi-agent architecture for planning, researching, critiquing, and composing.

  - [Deep Search Agent](https://github.com/google/adk-samples/tree/main/python/agents/deep-search)

- **RAG Agent**

  ______________________________________________________________________

  A document Q&A agent powered by Knowledge Engine. Upload documents and ask questions to receive accurate answers with citations formatted as URLs pointing to source materials.

  - [RAG Agent](https://github.com/google/adk-samples/tree/main/python/agents/RAG)

# Google Search Grounding for agents

Supported in ADKPython v0.1.0TypeScript v0.2.0Java v0.1.0

[Google Search Grounding tool](/integrations/google-search/) is a powerful feature in the Agent Development Kit (ADK) that connects your AI agents directly to Google Search. By giving your agents access to real-time, authoritative information from the web, they can answer questions about recent events, current weather, stock prices, or any other dynamic data that falls outside the model's training window. The agent automatically decides when to search and seamlessly incorporates the results into its responses with proper citations.

## Creating a Grounded Agent

To enable Google Search Grounding, you include the search tool in your agent definition.

```python
from google.adk.agents import Agent
from google.adk.tools import google_search

root_agent = Agent(
    name="google_search_agent",
    model="gemini-flash-latest",
    instruction="Answer questions using Google Search when needed. Always cite sources.",
    description="Professional search assistant with Google Search capabilities",
    tools=[google_search]
)
```

```typescript
import { LlmAgent, GOOGLE_SEARCH } from '@google/adk';

const rootAgent = new LlmAgent({
    name: "google_search_agent",
    model: "gemini-flash-latest",
    instruction: "Answer questions using Google Search when needed. Always cite sources.",
    description: "Professional search assistant with Google Search capabilities",
    tools: [GOOGLE_SEARCH],
});
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.tools.GoogleSearchTool;

LlmAgent rootAgent = LlmAgent.builder()
    .name("google_search_agent")
    .model("gemini-flash-latest")
    .instruction("Answer questions using Google Search when needed. Always cite sources.")
    .description("Professional search assistant with Google Search capabilities")
    .tools(GoogleSearchTool.INSTANCE)
    .build();
```

## How grounding with Google Search works

Grounding is the process that connects your agent to real-time information from the web, allowing it to generate more accurate and current responses. When a user's prompt requires information that the model was not trained on, or that is time-sensitive, the agent's underlying Large Language Model intelligently decides to invoke the `google_search` tool to find the relevant facts.

### Data Flow Diagram

This diagram illustrates the step-by-step process of how a user query results in a grounded response.

### Detailed Description

The grounding agent uses the data flow described in the diagram to retrieve, process, and incorporate external information into the final answer presented to the user.

1. **User Query**: An end-user interacts with your agent by asking a question or giving a command.
1. **ADK Orchestration**: The Agent Development Kit orchestrates the agent's behavior and passes the user's message to the core of your agent.
1. **LLM Analysis and Tool-Calling**: The agent's LLM (e.g., a Gemini model) analyzes the prompt. If it determines that external, up-to-date information is required, it triggers the grounding mechanism by calling the `google search` tool. This is ideal for answering queries about recent news, weather, or facts not present in the model's training data.
1. **Grounding Service Interaction**: The `google search` tool interacts with an internal grounding service that formulates and sends one or more queries to the Google Search Index.
1. **Context Injection**: The grounding service retrieves the relevant web pages and snippets. It then integrates these search results into the model's context before the final response is generated. This crucial step allows the model to "reason" over factual, real-time data.
1. **Grounded Response Generation**: The LLM, now informed by the fresh search results, generates a response that incorporates the retrieved information.
1. **Response Presentation with Sources**: The ADK receives the final grounded response, which includes the necessary source URLs and `groundingMetadata`, and presents it to the user with attribution. This allows end-users to verify the information and builds trust in the agent's answers.

### Understanding the Error Response and Grounding Metadata

When the agent uses Google Search to ground a response, it returns a detailed set of information that includes not only the final text answer but also the sources it used to generate that answer. This metadata is crucial for verifying the response and for providing attribution to the original sources.

#### Example of a Grounded Response

The following is an example of the content object returned by the model after a grounded query.

**Final Answer Text:**

```text
"Yes, Inter Miami won their last game in the FIFA Club World Cup. They defeated FC Porto 2-1 in their second group stage match. Their first game in the tournament was a 0-0 draw against Al Ahly FC. Inter Miami is scheduled to play their third group stage match against Palmeiras on Monday, June 23, 2025."
```

**Grounding Metadata Snippet:**

```json
"groundingMetadata": {
  "groundingChunks": [
    { "web": { "title": "mlssoccer.com", "uri": "..." } },
    { "web": { "title": "intermiamicf.com", "uri": "..." } },
    { "web": { "title": "mlssoccer.com", "uri": "..." } }
  ],
  "groundingSupports": [
    {
      "groundingChunkIndices": [0, 1],
      "segment": {
        "startIndex": 65,
        "endIndex": 126,
        "text": "They defeated FC Porto 2-1 in their second group stage match."
      }
    },
    {
      "groundingChunkIndices": [1],
      "segment": {
        "startIndex": 127,
        "endIndex": 196,
        "text": "Their first game in the tournament was a 0-0 draw against Al Ahly FC."
      }
    },
    {
      "groundingChunkIndices": [0, 2],
      "segment": {
        "startIndex": 197,
        "endIndex": 303,
        "text": "Inter Miami is scheduled to play their third group stage match against Palmeiras on Monday, June 23, 2025."
      }
    }
  ],
  "searchEntryPoint": { ... }
}
```

#### How to Interpret the Response

The metadata provides a link between the text generated by the model and the sources that support it. Here is a step-by-step breakdown:

1. **groundingChunks**: This is a list of the web pages the model consulted. Each chunk contains the title of the webpage and a `uri` that links to the source.
1. **groundingSupports**: This list connects specific sentences in the final answer back to the `groundingChunks`.
1. **segment**: This object identifies a specific portion of the final text answer, defined by its `startIndex`, `endIndex`, and the text itself.
1. **groundingChunkIndices**: This array contains the index numbers that correspond to the sources listed in the `groundingChunks`. For example, the sentence "They defeated FC Porto 2-1..." is supported by information from `groundingChunks` at index 0 and 1.

### How to display grounding responses with Google Search

A critical part of using grounding is to correctly display the information, including citations and search suggestions, to the end-user. This builds trust and allows users to verify the information.

#### Displaying Search Suggestions

The `searchEntryPoint` object in the `groundingMetadata` contains pre-formatted HTML for displaying search query suggestions. These are typically rendered as clickable chips that allow the user to explore related topics.

**Rendered HTML from searchEntryPoint:** The metadata provides the necessary HTML and CSS to render the search suggestions bar, which includes the Google logo and chips for related queries. Integrating this HTML directly into your application's front end will display the suggestions as intended.

For more information, consult [using Google Search Suggestions](https://cloud.google.com/vertex-ai/generative-ai/docs/grounding/grounding-search-suggestions) in Agent Platform documentation.

# Grounding with Search for agents

Supported in ADKPython v0.1.0Java v0.1.0

[Agent Search](/integrations/agent-search/) is a powerful tool for the Agent Development Kit (ADK) that enables AI agents to access information from your private enterprise documents and data repositories. By connecting your agents to indexed enterprise content, you can provide users with answers grounded in your organization's knowledge base.

This feature is particularly valuable for enterprise-specific queries requiring information from internal documentation, policies, research papers, or any proprietary content that has been indexed in your [Agent Search](https://cloud.google.com/enterprise-search) datastore. When your agent determines that information from your knowledge base is needed, it automatically searches your indexed documents and incorporates the results into its response with proper attribution.

## Preparing Agent Search

Before creating a grounded agent, you must have an existing Agent Search Data Store. If you don't have one, follow the instructions in [Get started with custom search](https://cloud.google.com/generative-ai-app-builder/docs/try-enterprise-search#unstructured-data) to create one. You will need your `Data store ID` (e.g., `projects/YOUR_PROJECT_ID/locations/global/collections/default_collection/dataStores/YOUR_DATASTORE_ID`) to configure the agent.

## Authentication Setup

**Note: Agent Search requires Google Cloud Platform (Agent Platform) authentication. Google AI Studio is not supported for this tool.**

- Set up the [gcloud CLI](https://cloud.google.com/vertex-ai/generative-ai/docs/start/quickstarts/quickstart-multimodal#setup-local)
- Authenticate to Google Cloud, from the terminal by running `gcloud auth login`.
- For Python, open the **`.env`** file and specify your project ID and location.
- For Java, ensure your application environment has Google Cloud default credentials configured (`GOOGLE_APPLICATION_CREDENTIALS`).

.env

```text
GOOGLE_GENAI_USE_VERTEXAI=TRUE
GOOGLE_CLOUD_PROJECT=YOUR_PROJECT_ID
GOOGLE_CLOUD_LOCATION=LOCATION
```

## Creating a Grounded Agent

To enable Grounding with Search, you include the search tool in your agent definition, providing the `data_store_id`.

```python
from google.adk.agents import Agent
from google.adk.tools import VertexAiSearchTool

# Configuration
DATASTORE_ID = "projects/YOUR_PROJECT_ID/locations/global/collections/default_collection/dataStores/YOUR_DATASTORE_ID"

root_agent = Agent(
    name="vertex_search_agent",
    model="gemini-flash-latest",
    instruction="Answer questions using Agent Search to find information from internal documents. Always cite sources when available.",
    description="Enterprise document search assistant with Agent Search capabilities",
    tools=[VertexAiSearchTool(data_store_id=DATASTORE_ID)]
)
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.tools.VertexAiSearchTool;

// Configuration
String DATASTORE_ID = "projects/YOUR_PROJECT_ID/locations/global/collections/default_collection/dataStores/YOUR_DATASTORE_ID";

LlmAgent rootAgent = LlmAgent.builder()
    .name("vertex_search_agent")
    .model("gemini-flash-latest")
    .instruction("Answer questions using Agent Search to find information from internal documents. Always cite sources when available.")
    .description("Enterprise document search assistant with Agent Search capabilities")
    .tools(VertexAiSearchTool.builder().dataStoreId(DATASTORE_ID).build())
    .build();
```

## How Grounding with Search works

Grounding with Search is the process that connects your agent to your organization's indexed documents and data, allowing it to generate accurate responses based on private enterprise content. When a user's prompt requires information from your internal knowledge base, the agent's underlying LLM intelligently decides to invoke the `VertexAiSearchTool` to find relevant facts from your indexed documents.

### Data Flow Diagram

This diagram illustrates the step-by-step process of how a user query results in a grounded response.

### Detailed Description

The grounding agent uses the data flow described in the diagram to retrieve, process, and incorporate enterprise information into the final answer presented to the user.

1. **User Query**: An end-user interacts with your agent by asking a question about internal documents or enterprise data.
1. **ADK Orchestration**: The Agent Development Kit orchestrates the agent's behavior and passes the user's message to the core of your agent.
1. **LLM Analysis and Tool-Calling**: The agent's LLM (e.g., a Gemini model) analyzes the prompt. If it determines that information from your indexed documents is required, it triggers the grounding mechanism by calling the `VertexAiSearchTool`. This is ideal for answering queries about company policies, technical documentation, or proprietary research.
1. **Vertex AI Search Service Interaction**: The `VertexAiSearchTool` interacts with your configured Agent Search datastore, which contains your indexed enterprise documents. The service formulates and executes search queries against your private content.
1. **Document Retrieval & Ranking**: Agent Search retrieves and ranks the most relevant document chunks from your datastore based on semantic similarity and relevance scoring.
1. **Context Injection**: The search service integrates the retrieved document snippets into the model's context before the final response is generated. This crucial step allows the model to "reason" over your organization's factual data.
1. **Grounded Response Generation**: The LLM, now informed by relevant enterprise content, generates a response that incorporates the retrieved information from your documents.
1. **Response Presentation with Sources**: The ADK receives the final grounded response, which includes the necessary source document references and `groundingMetadata`, and presents it to the user with attribution. This allows end-users to verify the information against your enterprise sources.

## Understanding Grounding with Search response

When the agent uses Agent Search to ground a response, it returns detailed information that includes the final text answer and metadata about the documents used to generate that answer. This metadata is crucial for verifying the response and providing attribution to your enterprise sources.

### Example of a Grounded Response

The following is an example of the content object returned by the model after a grounded query against enterprise documents.

**Final Answer Text:**

```text
"Developing models for a medical scribe presents several significant challenges, primarily due to the complex nature of medical documentation, the sensitive data involved, and the demanding requirements of clinical workflows. Key challenges include: **Accuracy and Reliability:** Medical documentation requires extremely high levels of accuracy, as errors can lead to misdiagnoses, incorrect treatments, and legal repercussions. Ensuring that AI models can reliably capture nuanced medical language, distinguish between subjective and objective information, and accurately transcribe physician-patient interactions is a major hurdle. **Natural Language Understanding (NLU) and Speech Recognition:** Medical conversations are often rapid, involve highly specialized jargon, acronyms, and abbreviations, and can be spoken by individuals with diverse accents or speech patterns... [response continues with detailed analysis of privacy, integration, and technical challenges]"
```

**Grounding Metadata Snippet:**

```json
{
  "groundingMetadata": {
    "groundingChunks": [
      {
        "document": {
          "title": "AI in Medical Scribing: Technical Challenges",
          "uri": "projects/your-project/locations/global/dataStores/your-datastore-id/documents/doc-medical-scribe-ai-tech-challenges",
          "id": "doc-medical-scribe-ai-tech-challenges"
        }
      },
      {
        "document": {
          "title": "Regulatory and Ethical Hurdles for AI in Healthcare",
          "uri": "projects/your-project/locations/global/dataStores/your-datastore-id/documents/doc-ai-healthcare-ethics",
          "id": "doc-ai-healthcare-ethics"
        }
      }
    ],
    "groundingSupports": [
      {
        "groundingChunkIndices": [0, 1],
        "segment": {
          "endIndex": 637,
          "startIndex": 433,
          "text": "Ensuring that AI models can reliably capture nuanced medical language..."
        }
      }
    ],
    "retrievalQueries": [
      "challenges in natural language processing medical domain",
      "AI medical scribe challenges",
      "difficulties in developing AI for medical scribes"
    ]
  }
}
```

### How to Interpret the Response

The metadata provides a link between the text generated by the model and the enterprise documents that support it. Here is a step-by-step breakdown:

- **groundingChunks**: This is a list of the enterprise documents the model consulted. Each chunk contains the document `title`, `uri` (document path), and `id`.
- **groundingSupports**: This list connects specific sentences in the final answer back to the `groundingChunks`.
- **segment**: This object identifies a specific portion of the final text answer, defined by its `startIndex`, `endIndex`, and the `text` itself.
- **groundingChunkIndices**: This array contains the index numbers that correspond to the sources listed in the `groundingChunks`. For example, the text about "HIPAA compliance" is supported by information from `groundingChunks` at index 1 (the "Regulatory and Ethical Hurdles" document).
- **retrievalQueries**: This array shows the specific search queries that were executed against your datastore to find relevant information.

## How to display responses with Grounding with Search

Unlike Google Search grounding, Grounding with Search does not require specific display components. However, displaying citations and document references builds trust and allows users to verify information against your organization's authoritative sources.

### Optional Citation Display

Since grounding metadata is provided, you can choose to implement citation displays based on your application needs:

**Simple Text Display (Minimal Implementation):**

```python
for event in events:
    if event.is_final_response():
        print(event.content.parts[0].text)

        # Optional: Show source count
        if event.grounding_metadata:
            print(f"\nBased on {len(event.grounding_metadata.grounding_chunks)} documents")
```

```java
for (Event event : events) {
    if (event.finalResponse()) {
        System.out.println(event.content().parts().get(0).text());

        // Optional: Show source count
        if (event.groundingMetadata().isPresent()) {
            System.out.println("\nBased on " + event.groundingMetadata().get().groundingChunks().size() + " documents");
        }
    }
}
```

**Enhanced Citation Display (Optional):** You can implement interactive citations that show which documents support each statement. The grounding metadata provides all necessary information to map text segments to source documents.

### Implementation Considerations

When implementing Grounding with Search displays:

1. **Document Access**: Verify user permissions for referenced documents
1. **Simple Integration**: Basic text output requires no additional display logic
1. **Optional Enhancements**: Add citations only if your use case benefits from source attribution
1. **Document Links**: Convert document URIs to accessible internal links when needed
1. **Search Queries**: The `retrievalQueries` array shows what searches were performed against your datastore
# Reference

# ADK release notes

You can find the release notes in the code repositories for each supported language. For detailed information on ADK releases, see these locations:

- [ADK Python release notes](https://github.com/google/adk-python/releases)
- [ADK TypeScript release notes](https://github.com/google/adk-js/releases)
- [ADK Go release notes](https://github.com/google/adk-go/releases)
- [ADK Java release notes](https://github.com/google/adk-java/releases)

# API Reference

The Agent Development Kit (ADK) provides comprehensive API references for both Python and Java, allowing you to dive deep into all available classes, methods, and functionalities.

- **Python API Reference**

  ______________________________________________________________________

  Explore the complete API documentation for the Python Agent Development Kit. Discover detailed information on all modules, classes, functions, and examples to build sophisticated AI agents with Python.

  [View Python API Docs](https://adk.dev/api-reference/python/)

- **Go API Reference**

  ______________________________________________________________________

  Explore the complete API documentation for the Go Agent Development Kit. Discover detailed information on all modules, classes, and functions to build sophisticated AI agents with Go.

  [View Go API Docs](https://pkg.go.dev/google.golang.org/adk)

- **Java API Reference**

  ______________________________________________________________________

  Access the comprehensive Javadoc for the Java Agent Development Kit. This reference provides detailed specifications for all packages, classes, interfaces, and methods, enabling you to develop robust AI agents using Java.

  [View Java API Docs](https://adk.dev/api-reference/java/)

- **Typescript API Reference**

  ______________________________________________________________________

  Access the complete API documentation for the TypeScript Agent Development Kit. Find detailed information on all packages, classes, and methods to build powerful and flexible AI agents with TypeScript.

  [View Typescript API Docs](https://adk.dev/api-reference/typescript/)

- **CLI Reference**

  ______________________________________________________________________

  Explore the complete API documentation for the CLI including all of the valid options and subcommands.

  [View CLI Docs](https://adk.dev/api-reference/cli/)

- **Agent Config YAML reference**

  ______________________________________________________________________

  View the full Agent Config syntax for configuring ADK with YAML text files.

  [View Agent Config reference](https://adk.dev/api-reference/agentconfig/)

- **REST API Reference**

  ______________________________________________________________________

  Explore the REST API for the ADK web server. This reference provides details on the available endpoints, request and response formats, and more.

  [View REST API Docs](https://adk.dev/api-reference/rest/)
# Community

# Community Resources

Welcome! This page highlights resources built and maintained by the Agent Development Kit community.

Info

Google and the ADK team do not provide support for the content linked in these external community resources.

## Join the Community

- Want to discuss ADK, ask questions, or talk about all things agents? Head to **[r/agentdevelopmentkit](https://www.reddit.com/r/agentdevelopmentkit/)** on Reddit.
- Want updates on the monthly community call? Join the **[ADK Community Google Group](https://groups.google.com/g/adk-community)**.
- Want to file a bug or contribute to the ADK framework? Check out the **[Contributing Guide](/community/contributing-guide/)** to find the right repo and get started.

## Getting Started

## ADK Community Calls

Join the [ADK Community Google Group](https://groups.google.com/g/adk-community) for updates on the next call. Recent recordings are below, or browse the full [YouTube playlist](https://www.youtube.com/playlist?list=PLwi6PfxEP7zZbBPmWiZ8QbPcuKyAY5RR3).

## Courses & Deep Dives

## Agent Tutorials and Demos

## ADK for Java

## Translations

Community-provided translations of the ADK documentation.

- [🇨🇳 Chinese (中文) Documentation](https://adk.wiki/)
- [🇰🇷 Korean (한국어) Documentation](https://adk-labs.github.io/adk-docs/ko/)
- [🇯🇵 Japanese (日本語) Documentation](https://adk-labs.github.io/adk-docs/ja/)
- [🇪🇸 Spanish (Español) Documentation](https://adk-es.fabian-castro-c.dev/)

## Contributing Your Resource

Have an ADK resource to share (tutorial, translation, tool, video, or example)?

Refer to the steps in the **[Contributing Guide](/community/contributing-guide/)** for more information on how to get involved!

Thank you for your contributions to Agent Development Kit! ❤️

Thank you for your interest in contributing to Agent Development Kit (ADK)! We welcome contributions to the core frameworks, documentation, and related components, which are listed below.

This guide provides information on how to get involved.

## Join the community

- Want to discuss ADK, ask questions, or talk about all things agents? Head to **[r/agentdevelopmentkit](https://www.reddit.com/r/agentdevelopmentkit/)** on Reddit.
- Want updates on the monthly community call? Join the **[ADK Community Google Group](https://groups.google.com/g/adk-community)**.
- Want to file a bug or contribute to the ADK framework? See the sections below for how to find the right repo and get started.

## Preparing to contribute

### Choose the right repository

The ADK project is split across several repositories. Find the right one for your contribution:

| Repository                                                                      | Description                                                              | Detailed Guide                                                                                |
| ------------------------------------------------------------------------------- | ------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------- |
| [`google/adk-python`](https://github.com/google/adk-python)                     | Contains the core Python library source code                             | [`CONTRIBUTING.md`](https://github.com/google/adk-python/blob/main/CONTRIBUTING.md)           |
| [`google/adk-python-community`](https://github.com/google/adk-python-community) | Contains community-contributed tools, integrations, and scripts          | [`CONTRIBUTING.md`](https://github.com/google/adk-python-community/blob/main/CONTRIBUTING.md) |
| [`google/adk-js`](https://github.com/google/adk-js)                             | Contains the core JavaScript library source code                         | [`CONTRIBUTING.md`](https://github.com/google/adk-js/blob/main/CONTRIBUTING.md)               |
| [`google/adk-go`](https://github.com/google/adk-go)                             | Contains the core Go library source code                                 | [`CONTRIBUTING.md`](https://github.com/google/adk-go/blob/main/CONTRIBUTING.md)               |
| [`google/adk-java`](https://github.com/google/adk-java)                         | Contains the core Java library source code                               | [`CONTRIBUTING.md`](https://github.com/google/adk-java/blob/main/CONTRIBUTING.md)             |
| [`google/adk-docs`](https://github.com/google/adk-docs)                         | Contains the source for the documentation site you are currently reading | [`CONTRIBUTING.md`](https://github.com/google/adk-docs/blob/main/CONTRIBUTING.md)             |
| [`google/adk-samples`](https://github.com/google/adk-samples)                   | Contains sample agents for ADK                                           | [`CONTRIBUTING.md`](https://github.com/google/adk-samples/blob/main/CONTRIBUTING.md)          |
| [`google/adk-web`](https://github.com/google/adk-web)                           | Contains the source for the `adk web` dev UI                             |                                                                                               |

These repositories typically include a `CONTRIBUTING.md` file in the root of their repository with more detailed information on requirements, testing, code review processes, etc. for that particular component.

### Sign a CLA

Contributions to this project must be accompanied by a [Contributor License Agreement](https://cla.developers.google.com/about) (CLA). You (or your employer) retain the copyright to your contribution; this simply gives us permission to use and redistribute your contributions as part of the project.

If you or your current employer have already signed the Google CLA (even if it was for a different project), you probably don't need to do it again.

Visit <https://cla.developers.google.com/> to see your current agreements or to sign a new one.

### Review community guidelines

This project follows [Google's Open Source Community Guidelines](https://opensource.google/conduct/).

## How to contribute

There are several ways you can contribute to ADK:

### Reporting issues

If you find a bug in the framework or an error in the documentation:

- **Framework Bugs:** Open an issue in [`google/adk-python`](https://github.com/google/adk-python/issues/new), [`google/adk-js`](https://github.com/google/adk-js/issues/new), [`google/adk-go`](https://github.com/google/adk-go/issues/new), or [`google/adk-java`](https://github.com/google/adk-java/issues/new)
- **Documentation Errors:** [Open an issue in `google/adk-docs` (use bug template)](https://github.com/google/adk-docs/issues/new?template=bug_report.md)

### Suggesting enhancements

Have an idea for a new feature or an improvement to an existing one?

- **Framework Enhancements:** Open an issue in [`google/adk-python`](https://github.com/google/adk-python/issues/new), [`google/adk-js`](https://github.com/google/adk-js/issues/new), [`google/adk-go`](https://github.com/google/adk-go/issues/new), or [`google/adk-java`](https://github.com/google/adk-java/issues/new)
- **Documentation Enhancements:** [Open an issue in `google/adk-docs`](https://github.com/google/adk-docs/issues/new)

### Improving documentation

Found a typo, unclear explanation, or missing information? Submit your changes directly:

- **How:** Submit a Pull Request (PR) with your suggested improvements.
- **Where:** [Create a Pull Request in `google/adk-docs`](https://github.com/google/adk-docs/pulls)

### Writing code

Help fix bugs, implement new features or contribute code samples for the documentation:

**How:** Submit a Pull Request (PR) with your code changes.

- **Python Framework:** [Create a Pull Request in `google/adk-python`](https://github.com/google/adk-python/pulls)
- **TypeScript Framework:** [Create a Pull Request in `google/adk-js`](https://github.com/google/adk-js/pulls)
- **Go Framework:** [Create a Pull Request in `google/adk-go`](https://github.com/google/adk-go/pulls)
- **Java Framework:** [Create a Pull Request in `google/adk-java`](https://github.com/google/adk-java/pulls)
- **Documentation:** [Create a Pull Request in `google/adk-docs`](https://github.com/google/adk-docs/pulls)

### Code reviews

- All contributions, including those from project members, undergo a review process.
- We use GitHub Pull Requests (PRs) for code submission and review. Please ensure your PR clearly describes the changes you are making.

## License

By contributing, you agree that your contributions will be licensed under the project's [Apache 2.0 License](https://github.com/google/adk-docs/blob/main/LICENSE).

## Questions?

If you get stuck or have questions, feel free to open an issue on the relevant repository's issue tracker.



