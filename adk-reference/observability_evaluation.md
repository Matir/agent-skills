# Observability for agents

Observability for agents enables measurement of a system's internal state, including reasoning traces, tool calls, and latent model outputs, by analyzing its external telemetry and structured logs. When building agents, you may need these features to help debug and diagnose their in-process behavior. Basic input and output monitoring is typically insufficient for agents with any significant level of complexity.

Agent Development Kit (ADK) provides built-in observability through [logging](/observability/logging/), [metrics](/observability/metrics/), and [traces](/observability/traces/) to help you monitor and debug your agents. However, you may need to consider more advanced [observability ADK Integrations](/integrations/?topic=observability) for monitoring and analysis.

ADK Integrations for observability

For a list of pre-built observability libraries for ADK, see [Tools and Integrations](/integrations/?topic=observability).

# Agent activity logging

Supported in ADKPython v0.1.0Go v0.1.0

Agent Development Kit (ADK) provides flexible and powerful logging capabilities to monitor agent behavior and debug issues effectively.

## Logging philosophy

ADK's approach to logging is to provide detailed diagnostic information without being overly verbose by default. It is designed to be configured by the application developer, allowing you to tailor the log output to your specific needs, whether in a development or production environment.

- **Standard Library Integration:** ADK uses the standard logging facilities of the host language (e.g., Python's `logging` module, Go's `log` package).
- **Structured GenAI Logging:** ADK uses OpenTelemetry to log structured events for GenAI requests and responses, allowing for advanced monitoring and debugging in cloud environments.
- **User-Configured:** While ADK provides defaults and integration with its CLI tools, it is ultimately the responsibility of the application developer to configure logging to suit their specific environment.

## Logging schema

ADK emits logs using standard library facilities and structured GenAI events via OpenTelemetry.

### Structured GenAI logs

Structured GenAI logs emitted via OpenTelemetry follow the [Semantic Conventions for GenAI](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/gen-ai/gen-ai-events.md).

By default prompt content is elided in logs for security. You can enable prompt logging using environment variables or programmatic configuration (see Setup section below).

### Log levels (Python)

The following table describes what is logged at different levels in Python when using the standard logger:

| Level         | Description                                                                                                            | Type of Information Logged                                                                                                                                                                                            |
| ------------- | ---------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`DEBUG`**   | **Crucial for debugging.** The most verbose level for fine-grained diagnostic information.                             | - **Full LLM Prompts:** The complete request sent to the language model, including system instructions, history, and tools. - Detailed API responses from services. - Internal state transitions and variable values. |
| **`INFO`**    | General information about the agent's lifecycle.                                                                       | - Agent initialization and startup. - Session creation and deletion events. - Execution of a tool, including its name and arguments.                                                                                  |
| **`WARNING`** | Indicates a potential issue or deprecated feature use. The agent continues to function, but attention may be required. | - Use of deprecated methods or parameters. - Non-critical errors that the system recovered from.                                                                                                                      |
| **`ERROR`**   | A serious error that prevented an operation from completing.                                                           | - Failed API calls to external services (e.g., LLM, Session Service). - Unhandled exceptions during agent execution. - Configuration errors.                                                                          |

Note

It is recommended to use `INFO` or `WARNING` in production environments. Only enable `DEBUG` when actively troubleshooting an issue, as `DEBUG` logs can be very verbose and may contain sensitive information.

## Logging setup

### Logging in ADK Web

When running agents using the ADK's `adk web`, `adk api_server`, `adk deploy cloud_run` and `adk deploy gke` commands, you can control the log verbosity or destination.

#### Logging level

To start the web server with `DEBUG` level logging, run:

```bash
adk web --log_level DEBUG path/to/your/agents_dir
```

The available log levels for the `--log_level` option are: `DEBUG`, `INFO` (default), `WARNING`, `ERROR`, `CRITICAL`.

#### Capture prompt content

By default a prompt content is elided in logs for security. You can enable prompt logging using the environment variable:

```bash
export OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT=true
```

Warning

The `OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT` setting logs the full content of user prompts and agent responses. This is useful for debugging but may capture sensitive data or PII. In production, set this to false or ensure you have appropriate data handling policies in place.

#### OTLP export

To export logs to an OTLP-compatible backend, set the standard OTel environment variables:

```bash
export OTEL_EXPORTER_OTLP_LOGS_ENDPOINT="http://your-collector:4318/v1/logs"
adk web path/to/your/agents_dir
```

Note

You can also set the general `OTEL_EXPORTER_OTLP_ENDPOINT` environment variable if you would like to send metrics and traces to the same endpoint in addition to logs.

#### GCP export setup

You can enable GCP export using the `-otel_to_cloud` flag:

```bash
adk web -otel_to_cloud path/to/your/agents_dir
```

### Python programmatic setup

In Python, ADK uses the standard `logging` module and OpenTelemetry for structured GenAI logs.

#### Logging level

To enable detailed logging, including `DEBUG` level messages, add the following to the top of your script:

```python
import logging

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(name)s - %(message)s'
)
```

#### Capture prompt content

You can enable full prompt logging programmatically by setting an environment variable:

```python
import os

os.environ["OTEL_INSTRUMENTATION_GENAI_CAPTURE_MESSAGE_CONTENT"] = "true"
```

#### OTLP export

To export logs to an OpenTelemetry Collector (or an OTLP-compatible backend) programmatically:

```python
from google.adk.telemetry.setup import maybe_set_otel_providers
import os

os.environ["OTEL_EXPORTER_OTLP_LOGS_ENDPOINT"] = "http://your-collector:4318/v1/logs"
os.environ["OTEL_SERVICE_NAME"] = "your-adk-agent"
os.environ["OTEL_RESOURCE_ATTRIBUTES"] = "key1=value1,key2=value2"
maybe_set_otel_providers()
```

#### GCP export setup

To export logs to Google Cloud Logging programmatically, use the OpenTelemetry Google Cloud exporter. Here is an example in Python:

```python
from google.adk.telemetry.google_cloud import get_gcp_exporters
from google.adk.telemetry.setup import maybe_set_otel_providers
import os

gcp_exporters = get_gcp_exporters(
  enable_cloud_logging = True,
)
os.environ["OTEL_SERVICE_NAME"] = "your-adk-agent"
os.environ["OTEL_RESOURCE_ATTRIBUTES"] = "key1=value1,key2=value2"
maybe_set_otel_providers([gcp_exporters])
```

### Go programmatic setup

In Go, ADK uses the `google.golang.org/adk/telemetry` package for OpenTelemetry configuration and the standard `log` package for general events.

#### Capture prompt content

You can enable full prompt logging programmatically when initializing telemetry:

```go
package main

import (
    "context"
    "google.golang.org/adk/telemetry"
)

func main() {
    ctx := context.Background()
    tp, err := telemetry.New(ctx,
        telemetry.WithGenAICaptureMessageContent(true),
    )
    if err != nil {
        // handle error
    }
    defer tp.Shutdown(ctx)
    tp.SetGlobalOtelProviders()
}
```

#### OTLP export

To export logs to an OTLP-compatible backend, configure the standard OpenTelemetry environment variables (e.g., `OTEL_EXPORTER_OTLP_ENDPOINT` or `OTEL_EXPORTER_OTLP_LOGS_ENDPOINT`). The ADK telemetry package will automatically use these settings when initialized.

#### GCP export setup

To export logs to Google Cloud Logging, use the `WithOtelToCloud` option:

```go
package main

import (
    "context"
    "google.golang.org/adk/telemetry"
)

func main() {
    ctx := context.Background()
    tp, err := telemetry.New(ctx,
        telemetry.WithOtelToCloud(true),
    )
    if err != nil {
        // handle error
    }
    defer tp.Shutdown(ctx)
    tp.SetGlobalOtelProviders()
}
```

If using the Go launcher, you can also enable GCP export via the CLI flag:

```bash
go run main.go web -otel_to_cloud
```

General events (like server startup or HTTP requests) are logged using the standard Go `log` package. These logs are written to `stderr` by default.

## Understanding log output

### Sample Python log entry

```text
2025-07-08 11:22:33,456 - DEBUG - google_adk.models.google_llm - LLM Request: contents { ... }
```

| Log Segment                     | Format Specifier | Meaning                                        |
| ------------------------------- | ---------------- | ---------------------------------------------- |
| `2025-07-08 11:22:33,456`       | `%(asctime)s`    | Timestamp                                      |
| `DEBUG`                         | `%(levelname)s`  | Severity level                                 |
| `google_adk.models.google_llm`  | `%(name)s`       | Logger name (the module that produced the log) |
| `LLM Request: contents { ... }` | `%(message)s`    | The actual log message                         |

By reading the logger name, you can immediately pinpoint the source of the log and understand its context within the agent's architecture.

### Debugging example

After enabling `DEBUG` logging (see [Logging level](#logging-level) above), run your agent and look for messages from the `google.adk.models.google_llm` logger. The output shows the full LLM request and response:

```text
2025-07-10 15:26:13,778 - DEBUG - google_adk.google.adk.models.google_llm -
LLM Request:
-----------------------------------------------------------
System Instruction:
      You roll dice and answer questions about the outcome of the dice rolls.
      ...
-----------------------------------------------------------
Contents:
{"parts":[{"text":"Roll a 6 sided dice"}],"role":"user"}
{"parts":[{"function_call":{"args":{"sides":6},"name":"roll_die"}}],"role":"model"}
{"parts":[{"function_response":{"name":"roll_die","response":{"result":2}}}],"role":"user"}
-----------------------------------------------------------
Functions:
roll_die: {'sides': {'type': <Type.INTEGER: 'INTEGER'>}}
check_prime: {'nums': {'items': {'type': <Type.INTEGER: 'INTEGER'>}, 'type': <Type.ARRAY: 'ARRAY'>}}
-----------------------------------------------------------
2025-07-10 15:26:14,309 - INFO - google_adk.google.adk.models.google_llm -
LLM Response:
-----------------------------------------------------------
Text:
I have rolled a 6 sided die, and the result is 2.
...
```

From this output you can verify:

- Is the system instruction correct?
- Is the conversation history (`user` and `model` turns) accurate?
- Are the correct tools being provided to the model?
- Are the tools correctly called by the model?
- How long it takes for the model to respond?

# Agent activity metrics

Supported in ADKPython v1.32.0

Agent Development Kit (ADK) provides built-in, vendor-neutral metrics collection to help you understand the performance, cost, and usage patterns of your agents. While logs provide a detailed narrative of *what* happened, metrics give you aggregated, quantitative data to answer *how often* and *how fast* things are happening.

## Metrics philosophy

ADK's approach to metrics is designed to be lightweight, standardized, and entirely agnostic to your choice of monitoring backend.

- **OpenTelemetry Semantic Conventions:** ADK implements the OpenTelemetry (OTel) [Semantic Conventions for GenAI](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/gen-ai/gen-ai-metrics.md). This ensures that metrics are recorded under standard, predictable attribute and metric names.
- **OTLP Wire Format:** ADK emits data using the standard OTLP format, ensuring that your metrics will seamlessly integrate into any OTel-compatible backend (e.g., Prometheus, Datadog, SigNoz, Google Cloud Monitoring).
- **Cost and Performance Focused:** Metrics are significantly less costly and more performant than logs or traces when performing analytics over large swathes of data. ADK tracks the most critical signals for LLM applications: token consumption, request latency, and tool execution reliability.
- **Vendor-Neutral Export:** ADK does not lock you into a specific metrics pipeline. You instantiate standard OTel meter providers and export data wherever your infrastructure demands.

______________________________________________________________________

## Metrics schema

When metrics are enabled, ADK automatically instruments the agent's lifecycle, workflow steps, and tool executions based on the OpenTelemetry GenAI Semantic Conventions. The following core metrics are emitted:

| Metric Name                            | Type      | Description                                                                                            | Key Attributes (Dimensions)       |
| -------------------------------------- | --------- | ------------------------------------------------------------------------------------------------------ | --------------------------------- |
| **`gen_ai.agent.invocation.duration`** | Histogram | The total time taken for an agent to process a prompt and return a response.                           | `gen_ai.agent.name`, `error.type` |
| **`gen_ai.tool.execution.duration`**   | Histogram | The execution latency of individual tools called by the agent. Useful for spotting slow external APIs. | `gen_ai.tool.name`, `error.type`  |
| **`gen_ai.agent.request.size`**        | Histogram | The size or complexity of the incoming request sent to the agent.                                      | `gen_ai.agent.name`               |
| **`gen_ai.agent.response.size`**       | Histogram | The size or complexity of the final response generated by the agent.                                   | `gen_ai.agent.name`               |
| **`gen_ai.agent.workflow.steps`**      | Histogram | Tracks the number of iterative steps or reasoning loops an agent takes to complete a workflow.         | `gen_ai.agent.name`               |

______________________________________________________________________

## Metrics export setup

### Metrics export in ADK Web

If you are running your agent using the `adk web` or `adk api_server` CLI commands, you can configure metrics export.

#### OTLP export

To export metrics to an OTLP-compatible backend, set the standard OTel environment variables:

```bash
export OTEL_EXPORTER_OTLP_METRICS_ENDPOINT="http://your-collector:4318/v1/metrics"
adk web path/to/your/agents_dir
```

> **Note:** You can also set the general `OTEL_EXPORTER_OTLP_ENDPOINT` environment variable if you would like to send traces and logs to the same endpoint in addition to metrics.

#### GCP export

To enable metrics export to Google Cloud Monitoring, use the `-otel_to_cloud` flag:

```bash
adk web -otel_to_cloud path/to/your/agents_dir
```

### Programmatic metrics export

You can also configure metrics export programmatically in your application code.

#### OTLP export setup

To enable metrics and export them to an OpenTelemetry Collector (or an OTLP-compatible backend) programmatically:

```python
from google.adk.telemetry.setup import maybe_set_otel_providers
import os

os.environ["OTEL_EXPORTER_OTLP_METRICS_ENDPOINT"] = "http://your-collector:4318/v1/metrics"
os.environ["OTEL_SERVICE_NAME"] = "your-adk-agent"
os.environ["OTEL_RESOURCE_ATTRIBUTES"] = "key1=value1,key2=value2"
maybe_set_otel_providers()
```

#### GCP export setup

To export metrics to Google Cloud Monitoring programmatically, use the OpenTelemetry Google Cloud exporter. Here is an example in Python:

```python
from google.adk.telemetry.google_cloud import get_gcp_exporters
from google.adk.telemetry.setup import maybe_set_otel_providers
import os

gcp_exporters = get_gcp_exporters(
  enable_cloud_metrics = True,
)
os.environ["OTEL_SERVICE_NAME"] = "your-adk-agent"
os.environ["OTEL_RESOURCE_ATTRIBUTES"] = "key1=value1,key2=value2"
maybe_set_otel_providers([gcp_exporters])
```

# Agent activity traces

Supported in ADKPython v1.17.0Go v1.0.0

Agent Development Kit (ADK) provides distributed tracing capabilities to help you visualize the end-to-end journey of a request as it travels through your agent's architecture. While metrics tell you *how long* a process took and logs tell you *what* happened, traces connect these events, showing you exactly *where* the time was spent and the hierarchical relationship between LLM reasoning, tool calls, and external APIs.

## Traces philosophy

ADK's approach to tracing is built on standard protocols to ensure seamless integration with your existing observability stack.

- **OpenTelemetry Semantic Conventions:** ADK implements the OpenTelemetry (OTel) [Semantic Conventions for GenAI](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/gen-ai/gen-ai-agent-spans.md). This ensures that trace spans and attributes are recorded under standard, predictable names.
- **OTLP Wire Format:** ADK emits data using the standard OTLP format, ensuring that your traces will seamlessly integrate into any OTel-compatible backend (e.g., Google Cloud Trace, Jaeger, Grafana Tempo, Datadog).
- **Hierarchical Visualization:** Traces are organized into "Spans." An agent run is a root span, which contains child spans for LLM operations, which may in turn contain child spans for tool executions. This creates a clear "waterfall" view of the agent's reasoning loop.
- **Context Propagation:** ADK automatically passes trace context across process boundaries, ensuring that if your agent calls an external microservice via a tool, that service's spans are linked to the agent's root trace.

______________________________________________________________________

## Traces schema

When tracing is enabled, ADK automatically instruments key operations following the OpenTelemetry GenAI Semantic Conventions for Agents. A typical trace waterfall includes the following spans:

| Span Name                                                                                                                                         | Type                   | Description                                                                                                                                                                | Key Attributes                                                                                                                                                                                                                                                               |
| ------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **[`invoke_agent`](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/gen-ai/gen-ai-agent-spans.md#invoke-agent-client-span)** | Client / Internal Span | Describes GenAI agent invocation over a remote service or locally. Represents the lifecycle of an agent interaction.                                                       | `gen_ai.agent.name`, `gen_ai.system`                                                                                                                                                                                                                                         |
| **[`invoke_workflow`](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/gen-ai/gen-ai-agent-spans.md#invoke-workflow-span)**  | Child Span             | Describes the invocation of a multi-step agentic workflow.                                                                                                                 | `gen_ai.workflow.name`, `gen_ai.system`                                                                                                                                                                                                                                      |
| **[`execute_tool`](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/gen-ai/gen-ai-agent-spans.md#execute-tool-span)**        | Child Span             | Represents the execution of a specific tool or function call requested by the GenAI system.                                                                                | `gen_ai.tool.name`, `gen_ai.system`                                                                                                                                                                                                                                          |
| **[`generate_content {model.name}`](https://github.com/open-telemetry/semantic-conventions/blob/main/docs/gen-ai/gen-ai-spans.md)**               | Internal Span          | Represents the invocation of the underlying language model (via the GenAI SDK) to generate content. It tracks the request parameters, response details, and usage metrics. | `gen_ai.operation.name`, `gen_ai.system`, `gen_ai.request.model`, `gen_ai.agent.name`, `gen_ai.conversation.id`, `user.id`, `gen_ai.request.top_p`, `gen_ai.request.max_tokens`, `gen_ai.response.finish_reasons`, `gen_ai.usage.input_tokens`, `gen_ai.usage.output_tokens` |

______________________________________________________________________

## Traces export setup

### Traces export in ADK Web

If you are running your agent using the `adk web` or `adk api_server` CLI commands, you can configure trace exports.

#### OTLP export

To export traces to an OTLP-compatible backend, set the standard OTel environment variables:

```bash
export OTEL_EXPORTER_OTLP_TRACES_ENDPOINT="http://your-collector:4318/v1/traces"
adk web path/to/your/agents_dir
```

> **Note:** You can also set the general `OTEL_EXPORTER_OTLP_ENDPOINT` environment variable if you would like to send metrics and logs to the same endpoint in addition to traces.

#### GCP export

To enable trace export to Google Cloud Trace, use the `-otel_to_cloud` flag:

```bash
adk web -otel_to_cloud path/to/your/agents_dir
```

### Programmatic traces export

You can also configure trace export programmatically in your application code.

#### OTLP export setup

To enable tracing and export spans to an OpenTelemetry Collector programmatically:

```python
from google.adk.telemetry.setup import maybe_set_otel_providers
import os

os.environ["OTEL_EXPORTER_OTLP_TRACES_ENDPOINT"] = "http://your-collector:4318/v1/traces"
os.environ["OTEL_SERVICE_NAME"] = "your-adk-agent"
os.environ["OTEL_RESOURCE_ATTRIBUTES"] = "key1=value1,key2=value2"
maybe_set_otel_providers()
```

#### GCP export setup

To export traces to Google Cloud Trace programmatically, use the OpenTelemetry Google Cloud exporter. Here is an example in Python:

```python
from google.adk.telemetry.google_cloud import get_gcp_exporters
from google.adk.telemetry.setup import maybe_set_otel_providers
import os

gcp_exporters = get_gcp_exporters(
  enable_cloud_tracing = True,
)
os.environ["OTEL_SERVICE_NAME"] = "your-adk-agent"
os.environ["OTEL_RESOURCE_ATTRIBUTES"] = "key1=value1,key2=value2"
maybe_set_otel_providers([gcp_exporters])
```

# Why Evaluate Agents

Supported in ADKPython

In traditional software development, unit tests and integration tests provide confidence that code functions as expected and remains stable through changes. These tests provide a clear "pass/fail" signal, guiding further development. However, LLM agents introduce a level of variability that makes traditional testing approaches insufficient.

Due to the probabilistic nature of models, deterministic "pass/fail" assertions are often unsuitable for evaluating agent performance. Instead, we need qualitative evaluations of both the final output and the agent's trajectory - the sequence of steps taken to reach the solution. This involves assessing the quality of the agent's decisions, its reasoning process, and the final result.

This may seem like a lot of extra work to set up, but the investment of automating evaluations pays off quickly. If you intend to progress beyond prototype, this is a highly recommended best practice.

## Preparing for Agent Evaluations

Before automating agent evaluations, define clear objectives and success criteria:

- **Define Success:** What constitutes a successful outcome for your agent?
- **Identify Critical Tasks:** What are the essential tasks your agent must accomplish?
- **Choose Relevant Metrics:** What metrics will you track to measure performance?

These considerations will guide the creation of evaluation scenarios and enable effective monitoring of agent behavior in real-world deployments.

## What to Evaluate?

To bridge the gap between a proof-of-concept and a production-ready AI agent, a robust and automated evaluation framework is essential. Unlike evaluating generative models, where the focus is primarily on the final output, agent evaluation requires a deeper understanding of the decision-making process. Agent evaluation can be broken down into two components:

1. **Evaluating Trajectory and Tool Use:** Analyzing the steps an agent takes to reach a solution, including its choice of tools, strategies, and the efficiency of its approach.
1. **Evaluating the Final Response:** Assessing the quality, relevance, and correctness of the agent's final output.

The trajectory is just a list of steps the agent took before it returned to the user. We can compare that against the list of steps we expect the agent to have taken.

### Evaluating trajectory and tool use

Before responding to a user, an agent typically performs a series of actions, which we refer to as a 'trajectory.' It might compare the user input with session history to disambiguate a term, or lookup a policy document, search a knowledge base or invoke an API to save a ticket. We call this a ‘trajectory’ of actions. Evaluating an agent's performance requires comparing its actual trajectory to an expected, or ideal, one. This comparison can reveal errors and inefficiencies in the agent's process. The expected trajectory represents the ground truth -- the list of steps we anticipate the agent should take.

For example:

```python
# Trajectory evaluation will compare
expected_steps = ["determine_intent", "use_tool", "review_results", "report_generation"]
actual_steps = ["determine_intent", "use_tool", "review_results", "report_generation"]
```

ADK provides both groundtruth based and rubric based tool use evaluation metrics. To select the appropriate metric for your agent's specific requirements and goals, please refer to our [recommendations](#recommendations-on-criteria).

## How Evaluation works with the ADK

The ADK offers two methods for evaluating agent performance against predefined datasets and evaluation criteria. While conceptually similar, they differ in the amount of data they can process, which typically dictates the appropriate use case for each.

### First approach: Using a test file

This approach involves creating individual test files, each representing a single, simple agent-model interaction (a session). It's most effective during active agent development, serving as a form of unit testing. These tests are designed for rapid execution and should focus on simple session complexity. Each test file contains a single session, which may consist of multiple turns. A turn represents a single interaction between the user and the agent. Each turn includes

- `User Content`: The user issued query.
- `Expected Intermediate Tool Use Trajectory`: The tool calls we expect the agent to make in order to respond correctly to the user query.
- `Expected Intermediate Agent Responses`: These are the natural language responses that the agent (or sub-agents) generates as it moves towards generating a final answer. These natural language responses are usually an artifact of an multi-agent system, where your root agent depends on sub-agents to achieve a goal. These intermediate responses, may or may not be of interest to the end user, but for a developer/owner of the system, are of critical importance, as they give you the confidence that the agent went through the right path to generate final response.
- `Final Response`: The expected final response from the agent.

You can give the file any name for example `evaluation.test.json`. The framework only checks for the `.test.json` suffix, and the preceding part of the filename is not constrained. The test files are backed by a formal Pydantic data model. The two key schema files are [Eval Set](https://github.com/google/adk-python/blob/main/src/google/adk/evaluation/eval_set.py) and [Eval Case](https://github.com/google/adk-python/blob/main/src/google/adk/evaluation/eval_case.py). Here is a test file with a few examples:

*(Note: Comments are included for explanatory purposes and should be removed for the JSON to be valid.)*

```json
# Do note that some fields are removed for sake of making this doc readable.
{
  "eval_set_id": "home_automation_agent_light_on_off_set",
  "name": "",
  "description": "This is an eval set that is used for unit testing `x` behavior of the Agent",
  "eval_cases": [
    {
      "eval_id": "eval_case_id",
      "conversation": [
        {
          "invocation_id": "b7982664-0ab6-47cc-ab13-326656afdf75", # Unique identifier for the invocation.
          "user_content": { # Content provided by the user in this invocation. This is the query.
            "parts": [
              {
                "text": "Turn off device_2 in the Bedroom."
              }
            ],
            "role": "user"
          },
          "final_response": { # Final response from the agent that acts as a reference of benchmark.
            "parts": [
              {
                "text": "I have set the device_2 status to off."
              }
            ],
            "role": "model"
          },
          "intermediate_data": {
            "tool_uses": [ # Tool use trajectory in chronological order.
              {
                "args": {
                  "location": "Bedroom",
                  "device_id": "device_2",
                  "status": "OFF"
                },
                "name": "set_device_info"
              }
            ],
            "intermediate_responses": [] # Any intermediate sub-agent responses.
          }
        }
      ],
      "session_input": { # Initial session input.
        "app_name": "home_automation_agent",
        "user_id": "test_user",
        "state": {}
      }
    }
  ]
}
```

Test files can be organized into folders. Optionally, a folder can also include a `test_config.json` file that specifies the evaluation criteria.

#### How to migrate test files not backed by the Pydantic schema?

NOTE: If your test files don't adhere to [EvalSet](https://github.com/google/adk-python/blob/main/src/google/adk/evaluation/eval_set.py) schema file, then this section is relevant to you.

Please use `AgentEvaluator.migrate_eval_data_to_new_schema` to migrate your existing `*.test.json` files to the Pydantic backed schema.

The utility takes your current test data file and an optional initial session file, and generates a single output json file with data serialized in the new format. Given that the new schema is more cohesive, both the old test data file and initial session file can be ignored (or removed.)

### Second approach: Using An Evalset File

The evalset approach utilizes a dedicated dataset called an "evalset" for evaluating agent-model interactions. Similar to a test file, the evalset contains example interactions. However, an evalset can contain multiple, potentially lengthy sessions, making it ideal for simulating complex, multi-turn conversations. Due to its ability to represent complex sessions, the evalset is well-suited for integration tests. These tests are typically run less frequently than unit tests due to their more extensive nature.

An evalset file contains multiple "evals," each representing a distinct session. Each eval consists of one or more "turns," which include the user query, expected tool use, expected intermediate agent responses, and a reference response. These fields have the same meaning as they do in the test file approach. Alternatively, an eval can define a *conversation scenario* which is used to [dynamically simulate](https://adk.dev/evaluate/user-sim/index.md) a user interaction with the agent. Each eval is identified by a unique name. Furthermore, each eval includes an associated initial session state.

Creating evalsets manually can be complex, therefore UI tools are provided to help capture relevant sessions and easily convert them into evals within your evalset. Learn more about using the web UI for evaluation below. Here is an example evalset containing two sessions. The eval set files are backed by a formal Pydantic data model. The two key schema files are [Eval Set](https://github.com/google/adk-python/blob/main/src/google/adk/evaluation/eval_set.py) and [Eval Case](https://github.com/google/adk-python/blob/main/src/google/adk/evaluation/eval_case.py).

Warning

This evalset evaluation method requires the use of a paid service, [Vertex Gen AI Evaluation Service API](https://cloud.google.com/vertex-ai/generative-ai/docs/model-reference/evaluation).

*(Note: Comments are included for explanatory purposes and should be removed for the JSON to be valid.)*

```json
# Do note that some fields are removed for sake of making this doc readable.
{
  "eval_set_id": "eval_set_example_with_multiple_sessions",
  "name": "Eval set with multiple sessions",
  "description": "This eval set is an example that shows that an eval set can have more than one session.",
  "eval_cases": [
    {
      "eval_id": "session_01",
      "conversation": [
        {
          "invocation_id": "e-0067f6c4-ac27-4f24-81d7-3ab994c28768",
          "user_content": {
            "parts": [
              {
                "text": "What can you do?"
              }
            ],
            "role": "user"
          },
          "final_response": {
            "parts": [
              {

                "text": "I can roll dice of different sizes and check if numbers are prime."
              }
            ],
            "role": null
          },
          "intermediate_data": {
            "tool_uses": [],
            "intermediate_responses": []
          }
        }
      ],
      "session_input": {
        "app_name": "hello_world",
        "user_id": "user",
        "state": {}
      }
    },
    {
      "eval_id": "session_02",
      "conversation": [
        {
          "invocation_id": "e-92d34c6d-0a1b-452a-ba90-33af2838647a",
          "user_content": {
            "parts": [
              {
                "text": "Roll a 19 sided dice"
              }
            ],
            "role": "user"
          },
          "final_response": {
            "parts": [
              {
                "text": "I rolled a 17."
              }
            ],
            "role": null
          },
          "intermediate_data": {
            "tool_uses": [],
            "intermediate_responses": []
          }
        },
        {
          "invocation_id": "e-bf8549a1-2a61-4ecc-a4ee-4efbbf25a8ea",
          "user_content": {
            "parts": [
              {
                "text": "Roll a 10 sided dice twice and then check if 9 is a prime or not"
              }
            ],
            "role": "user"
          },
          "final_response": {
            "parts": [
              {
                "text": "I got 4 and 7 from the dice roll, and 9 is not a prime number.\n"
              }
            ],
            "role": null
          },
          "intermediate_data": {
            "tool_uses": [
              {
                "id": "adk-1a3f5a01-1782-4530-949f-07cf53fc6f05",
                "args": {
                  "sides": 10
                },
                "name": "roll_die"
              },
              {
                "id": "adk-52fc3269-caaf-41c3-833d-511e454c7058",
                "args": {
                  "sides": 10
                },
                "name": "roll_die"
              },
              {
                "id": "adk-5274768e-9ec5-4915-b6cf-f5d7f0387056",
                "args": {
                  "nums": [
                    9
                  ]
                },
                "name": "check_prime"
              }
            ],
            "intermediate_responses": [
              [
                "data_processing_agent",
                [
                  {
                    "text": "I have rolled a 10 sided die twice. The first roll is 5 and the second roll is 3.\n"
                  }
                ]
              ]
            ]
          }
        }
      ],
      "session_input": {
        "app_name": "hello_world",
        "user_id": "user",
        "state": {}
      }
    }
  ]
}
```

#### How to migrate eval set files not backed by the Pydantic schema?

NOTE: If your eval set files don't adhere to [EvalSet](https://github.com/google/adk-python/blob/main/src/google/adk/evaluation/eval_set.py) schema file, then this section is relevant to you.

Based on who is maintaining the eval set data, there are two routes:

1. **Eval set data maintained by ADK UI** If you use ADK UI to maintain your Eval set data then *no action is needed* from you.
1. **Eval set data is developed and maintained manually and used in ADK eval CLI** A migration tool is in the works, until then the ADK eval CLI command will continue to support data in the old format.

### Evaluation Criteria

ADK provides several built-in criteria for evaluating agent performance, ranging from tool trajectory matching to LLM-based response quality assessment. For a detailed list of available criteria and guidance on when to use them, please see [Evaluation Criteria](https://adk.dev/evaluate/criteria/index.md).

Here is a summary of all the available criteria:

- **tool_trajectory_avg_score**: Exact match of tool call trajectory.
- **response_match_score**: ROUGE-1 similarity to reference response.
- **final_response_match_v2**: LLM-judged semantic match to a reference response.
- **rubric_based_final_response_quality_v1**: LLM-judged final response quality based on custom rubrics.
- **rubric_based_tool_use_quality_v1**: LLM-judged tool usage quality based on custom rubrics.
- **hallucinations_v1**: LLM-judged groundedness of agent response against context.
- **safety_v1**: Safety/harmlessness of agent response.
- **per_turn_user_simulator_quality_v1**: LLM-judged user simulator quality.
- **multi_turn_task_success_v1**: Evaluates if agent achieves goal(s) of conversation.
- **multi_turn_trajectory_quality_v1**: Evaluates the overall trajectory of the conversation.
- **multi_turn_tool_use_quality_v1**: Evaluates function calls made during a conversation.

If no evaluation criteria are provided, the following default configuration is used:

- `tool_trajectory_avg_score`: Defaults to 1.0, requiring a 100% match in the tool usage trajectory.
- `response_match_score`: Defaults to 0.8, allowing for a small margin of error in the agent's natural language responses.

Here is an example of a `test_config.json` file specifying custom evaluation criteria:

```json
{
  "criteria": {
    "tool_trajectory_avg_score": 1.0,
    "response_match_score": 0.8
  }
}
```

#### Recommendations on Criteria

Choose criteria based on your evaluation goals:

- **Enable tests in CI/CD pipelines or regression testing:** Use `tool_trajectory_avg_score` and `response_match_score`. These criteria are fast, predictable, and suitable for frequent automated checks.
- **Evaluate trusted reference responses:** Use `final_response_match_v2` to evaluate semantic equivalence. This LLM-based check is more flexible than exact matching and better captures whether the agent's response means the same thing as the reference response.
- **Evaluate response quality without a reference response:** Use `rubric_based_final_response_quality_v1`. This is useful when you don't have a trusted reference, but you can define attributes of a good response (e.g., "The response is concise," "The response has a helpful tone").
- **Evaluate the correctness of tool usage:** Use `rubric_based_tool_use_quality_v1`. This allows you to validate the agent's reasoning process by checking, for example, that a specific tool was called or that tools were called in the correct order (e.g., "Tool A must be called before Tool B").
- **Check if responses are grounded in context:** Use `hallucinations_v1` to detect if the agent makes claims that are unsupported by or contradictory to the information available to it (e.g., tool outputs).
- **Check for harmful content:** Use `safety_v1` to ensure that agent responses are safe and do not violate safety policies.
- **Evaluate multi-turn goal completion:** Use `multi_turn_task_success_v1` to measure the overall success of a multi-turn conversation in achieving its intended objectives.
- **Evaluate overall conversation trajectory:** Use `multi_turn_trajectory_quality_v1` to assess the efficiency, effectiveness, and logic of the steps taken during the conversation.
- **Evaluate tool usage in multi-turn workflows:** Use `multi_turn_tool_use_quality_v1` to assess the quality, relevance, and correctness of tool or function calls made across multiple turns.

In addition, criteria which require information on expected agent tool use and/or responses are not supported in combination with [User Simulation](https://adk.dev/evaluate/user-sim/index.md). Currently, only the `hallucinations_v1` and `safety_v1` criteria support such evals.

### User Simulation

When evaluating conversational agents, it is not always practical to use a fixed set of user prompts, as the conversation can proceed in unexpected ways. For example, if the agent needs the user to supply two values to perform a task, it may ask for those values one at a time or both at once. To resolve this issue, ADK allows you test the behavior of the agent in a specific *conversation scenario* with user prompts that are dynamically generated by an AI model. For details on how to set up an eval with user simulation, see [User Simulation](https://adk.dev/evaluate/user-sim/index.md).

## How to run Evaluation with the ADK

As a developer, you can evaluate your agents using the ADK in the following ways:

1. **Web-based UI (**`adk web`**):** Evaluate agents interactively through a web-based interface.
1. **Programmatically (**`pytest`**)**: Integrate evaluation into your testing pipeline using `pytest` and test files.
1. **Command Line Interface (**`adk eval`**):** Run evaluations on an existing evaluation set file directly from the command line.

### 1. `adk web` - Run Evaluations via the Web UI

The web UI provides an interactive way to evaluate agents, generate evaluation datasets, and inspect agent behavior in detail.

#### Step 1: Create and Save a Test Case

1. Start the web server by running: `adk web <path_to_your_agents_folder>`
1. In the web interface, select an agent and interact with it to create a session.
1. Navigate to the **Eval** tab on the right side of the interface.
1. Create a new eval set or select an existing one.
1. Click **"Add current session"** to save the conversation as a new evaluation case.

#### Step 2: View and Edit Your Test Case

Once a case is saved, you can click its ID in the list to inspect it. To make changes, click the **Edit current eval case** icon (pencil). This interactive view allows you to:

- **Modify** agent text responses to refine test scenarios.
- **Delete** individual agent messages from the conversation.
- **Delete** the entire evaluation case if it's no longer needed.

#### Step 3: Run the Evaluation with Custom Metrics

1. Select one or more test cases from your evalset.
1. Click **Run Evaluation**. An **EVALUATION METRIC** dialog will appear.
1. In the dialog, use the sliders to configure the thresholds for:
   - **Tool trajectory avg score**
   - **Response match score**
1. Click **Start** to run the evaluation using your custom criteria. The evaluation history will record the metrics used for each run.

#### Step 4: Analyze Results

After the run completes, you can analyze the results:

- **Analyze Run Failures**: Click on any **Pass** or **Fail** result. For failures, you can hover over the `Fail` label to see a side-by-side comparison of the **Actual vs. Expected Output** and the scores that caused the failure.

### Debugging with the Trace View

The ADK web UI includes a powerful **Trace** tab for debugging agent behavior. This feature is available for any agent session, not just during evaluation.

The **Trace** tab provides a detailed and interactive way to inspect your agent's execution flow. Traces are automatically grouped by user message, making it easy to follow the chain of events.

Each trace row is interactive:

- **Hovering** over a trace row highlights the corresponding message in the chat window.
- **Clicking** on a trace row opens a detailed inspection panel with four tabs:
  - **Event**: The raw event data.
  - **Request**: The request sent to the model.
  - **Response**: The response received from the model.
  - **Graph**: A visual representation of the tool calls and agent logic flow.

Blue rows in the trace view indicate that an event was generated from that interaction. Clicking on these blue rows will open the bottom event detail panel, providing deeper insights into the agent's execution flow.

### 2. `pytest` - Run Tests Programmatically

You can also use **`pytest`** to run test files as part of your integration tests.

#### Example Command

```shell
pytest tests/integration/
```

#### Example Test Code

Here is an example of a `pytest` test case that runs a single test file:

```py
from google.adk.evaluation.agent_evaluator import AgentEvaluator
import pytest

@pytest.mark.asyncio
async def test_with_single_test_file():
    """Test the agent's basic ability via a session file."""
    await AgentEvaluator.evaluate(
        agent_module="home_automation_agent",
        eval_dataset_file_path_or_dir="tests/integration/fixture/home_automation_agent/simple_test.test.json",
    )
```

This approach allows you to integrate agent evaluations into your CI/CD pipelines or larger test suites. If you want to specify the initial session state for your tests, you can do that by storing the session details in a file and passing that to `AgentEvaluator.evaluate` method.

### 3. `adk eval` - Run Evaluations via the CLI

You can also run evaluation of an eval set file through the command line interface (CLI). This runs the same evaluation that runs on the UI, but it helps with automation, i.e. you can add this command as a part of your regular build generation and verification process.

Here is the command:

```shell
adk eval \
    <AGENT_MODULE_FILE_PATH> \
    <EVAL_SET_FILE_PATH> \
    [--config_file_path=<PATH_TO_TEST_JSON_CONFIG_FILE>] \
    [--print_detailed_results]
```

For example:

```shell
adk eval \
    samples_for_testing/hello_world \
    samples_for_testing/hello_world/hello_world_eval_set_001.evalset.json
```

Here are the details for each command line argument:

- `AGENT_MODULE_FILE_PATH`: The path to the `__init__.py` file that contains a module by the name "agent". "agent" module contains a `root_agent`.
- `EVAL_SET_FILE_PATH`: The path to evaluations file(s). You can specify one or more eval set file paths. For each file, all evals will be run by default. If you want to run only specific evals from a eval set, first create a comma separated list of eval names and then add that as a suffix to the eval set file name, demarcated by a colon `:` .
- For example: `sample_eval_set_file.json:eval_1,eval_2,eval_3`\
  `This will only run eval_1, eval_2 and eval_3 from sample_eval_set_file.json`
- `CONFIG_FILE_PATH`: The path to the config file.
- `PRINT_DETAILED_RESULTS`: Prints detailed results on the console.

# Evaluation Criteria

Supported in ADKPython

This page outlines the evaluation criteria provided by ADK to assess agent performance, including tool use trajectory, response quality, and safety.

| Criterion                                | Description                                               | Reference-Based | Requires Rubrics | LLM-as-a-Judge | Supports [User Simulation](https://adk.dev/evaluate/user-sim/index.md) |
| ---------------------------------------- | --------------------------------------------------------- | --------------- | ---------------- | -------------- | ---------------------------------------------------------------------- |
| `tool_trajectory_avg_score`              | Exact match of tool call trajectory                       | Yes             | No               | No             | No                                                                     |
| `response_match_score`                   | ROUGE-1 similarity to reference response                  | Yes             | No               | No             | No                                                                     |
| `final_response_match_v2`                | LLM-judged semantic match to reference response           | Yes             | No               | Yes            | No                                                                     |
| `rubric_based_final_response_quality_v1` | LLM-judged final response quality based on custom rubrics | No              | Yes              | Yes            | Yes                                                                    |
| `rubric_based_tool_use_quality_v1`       | LLM-judged tool usage quality based on custom rubrics     | No              | Yes              | Yes            | Yes                                                                    |
| `hallucinations_v1`                      | LLM-judged groundedness of agent response against context | No              | No               | Yes            | Yes                                                                    |
| `safety_v1`                              | Safety/harmlessness of agent response                     | No              | No               | Yes            | Yes                                                                    |
| `per_turn_user_simulator_quality_v1`     | LLM-judged user simulator quality                         | No              | No               | Yes            | Yes                                                                    |
| `multi_turn_task_success_v1`             | Evaluates if agent achieves goal(s) of conversation       | No              | No               | Yes            | Yes                                                                    |
| `multi_turn_trajectory_quality_v1`       | Evaluates the overall trajectory of the conversation      | No              | No               | Yes            | Yes                                                                    |
| `multi_turn_tool_use_quality_v1`         | Evaluates function calls made during a conversation       | No              | No               | Yes            | Yes                                                                    |

## tool_trajectory_avg_score

This criterion compares the sequence of tools called by the agent against a list of expected calls and computes an average score based on one of the match types: `EXACT`, `IN_ORDER`, or `ANY_ORDER`.

#### When To Use This Criterion?

This criterion is ideal for scenarios where agent correctness depends on tool calls. Depending on how strictly tool calls need to be followed, you can choose from one of three match types: `EXACT`, `IN_ORDER`, and `ANY_ORDER`.

This metric is particularly valuable for:

- **Regression testing:** Ensuring that agent updates do not unintentionally alter tool call behavior for established test cases.
- **Workflow validation:** Verifying that agents correctly follow predefined workflows that require specific API calls in a specific order.
- **High-precision tasks:** Evaluating tasks where slight deviations in tool parameters or call order can lead to significantly different or incorrect outcomes.

Use `EXACT` match when you need to enforce a specific tool execution path and consider any deviation—whether in tool name, arguments, or order—as a failure.

Use `IN_ORDER` match when you want to ensure certain key tool calls occur in a specific order, but allow for other tool calls to happen in between. This option is useful in assuring if certain key actions or tool calls occur and in certain order, leaving some scope for other tools calls to happen as well.

Use `ANY_ORDER` match when you want to ensure certain key tool calls occur, but do not care about their order, and allow for other tool calls to happen in between. This criteria is helpful for cases where multiple tool calls about the same concept occur, like your agent issues 5 search queries. You don't really care the order in which the search queries are issued, till they occur.

#### Details

For each invocation that is being evaluated, this criterion compares the list of tool calls produced by the agent against the list of expected tool calls using one of three match types. If the tool calls match based on the selected match type, a score of 1.0 is awarded for that invocation, otherwise the score is 0.0. The final value is the average of these scores across all invocations in the eval case.

The comparison can be done using one of following match types:

- **`EXACT`**: Requires a perfect match between the actual and expected tool calls, with no extra or missing tool calls.
- **`IN_ORDER`**: Requires all tool calls from the expected list to be present in the actual list, in the same order, but allows for other tool calls to appear in between.
- **`ANY_ORDER`**: Requires all tool calls from the expected list to be present in the actual list, in any order, and allows for other tool calls to appear in between.

#### How To Use This Criterion?

By default, `tool_trajectory_avg_score` uses `EXACT` match type. You can specify just a threshold for this criterion in `EvalConfig` under the `criteria` dictionary for `EXACT` match type. The value should be a float between 0.0 and 1.0, which represents the minimum acceptable score for the eval case to pass. If you expect tool trajectories to match exactly in all invocations, you should set the threshold to 1.0.

Example `EvalConfig` entry for `EXACT` match:

```json
{
  "criteria": {
    "tool_trajectory_avg_score": 1.0
  }
}
```

Or you could specify the `match_type` explicitly:

```json
{
  "criteria": {
    "tool_trajectory_avg_score": {
      "threshold": 1.0,
      "match_type": "EXACT"
    }
  }
}
```

If you want to use `IN_ORDER` or `ANY_ORDER` match type, you can specify it via `match_type` field along with threshold.

Example `EvalConfig` entry for `IN_ORDER` match:

```json
{
  "criteria": {
    "tool_trajectory_avg_score": {
      "threshold": 1.0,
      "match_type": "IN_ORDER"
    }
  }
}
```

Example `EvalConfig` entry for `ANY_ORDER` match:

```json
{
  "criteria": {
    "tool_trajectory_avg_score": {
      "threshold": 1.0,
      "match_type": "ANY_ORDER"
    }
  }
}
```

#### Output And How To Interpret

The output is a score between 0.0 and 1.0, where 1.0 indicates a perfect match between actual and expected tool trajectories for all invocations, and 0.0 indicates a complete mismatch for all invocations. Higher scores are better. A score below 1.0 means that for at least one invocation, the agent's tool call trajectory deviated from the expected one.

## response_match_score

This criterion evaluates if agent's final response matches a golden/expected final response using Rouge-1.

### When To Use This Criterion?

Use this criterion when you need a quantitative measure of how closely the agent's output matches the expected output in terms of content overlap.

### Details

ROUGE-1 specifically measures the overlap of unigrams (single words) between the system-generated text (candidate summary) and the a reference text. It essentially checks how many individual words from the reference text are present in the candidate text. To learn more, see details on [ROUGE-1](https://github.com/google-research/google-research/tree/master/rouge).

### How To Use This Criterion?

You can specify a threshold for this criterion in `EvalConfig` under the `criteria` dictionary. The value should be a float between 0.0 and 1.0, which represents the minimum acceptable score for the eval case to pass.

Example `EvalConfig` entry:

```json
{
  "criteria": {
    "response_match_score": 0.8
  }
}
```

### Output And How To Interpret

Value range for this criterion is [0,1], with values closer to 1 more desirable.

## final_response_match_v2

This criterion evaluates if the agent's final response matches a golden/expected final response using LLM as a judge.

### When To Use This Criterion?

Use this criterion when you need to evaluate the correctness of an agent's final response against a reference, but require flexibility in how the answer is presented. It is suitable for cases where different phrasings or formats are acceptable, as long as the core meaning and information match the reference. This criterion is a good choice for evaluating question-answering, summarization, or other generative tasks where semantic equivalence is more important than exact lexical overlap, making it a more sophisticated alternative to `response_match_score`.

### Details

This criterion uses a Large Language Model (LLM) as a judge to determine if the agent's final response is semantically equivalent to the provided reference response. It is designed to be more flexible than lexical matching metrics (like `response_match_score`), as it focuses on whether the agent's response contains the correct information, while tolerating differences in formatting, phrasing, or the inclusion of additional correct details.

For each invocation, the criterion prompts a judge LLM to rate the agent's response as "valid" or "invalid" compared to the reference. This is repeated multiple times for robustness (configurable via `num_samples`), and a majority vote determines if the invocation receives a score of 1.0 (valid) or 0.0 (invalid). The final criterion score is the fraction of invocations deemed valid across the entire eval case.

### How To Use This Criterion?

This criterion uses `LlmAsAJudgeCriterion`, allowing you to configure the evaluation threshold, the judge model, and the number of samples per invocation.

Example `EvalConfig` entry:

```json
{
  "criteria": {
    "final_response_match_v2": {
      "threshold": 0.8,
      "judge_model_options": {
            "judge_model": "gemini-flash-latest",
            "num_samples": 5
          }
        }
    }
  }
}
```

### Output And How To Interpret

The criterion returns a score between 0.0 and 1.0. A score of 1.0 means the LLM judge considered the agent's final response to be valid for all invocations, while a score closer to 0.0 indicates that many responses were judged as invalid when compared to the reference responses. Higher values are better.

## rubric_based_final_response_quality_v1

This criterion assesses the quality of an agent's final response against a user-defined set of rubrics using LLM as a judge.

### When To Use This Criterion?

Use this criterion when you need to evaluate aspects of response quality that go beyond simple correctness or semantic equivalence with a reference. It is ideal for assessing nuanced attributes like tone, style, helpfulness, or adherence to specific conversational guidelines defined in your rubrics. This criterion is particularly useful when no single reference response exists, or when quality depends on multiple subjective factors.

### Details

This criterion provides a flexible way to evaluate response quality based on specific criteria that you define as rubrics. For example, you could define rubrics to check if a response is concise, if it correctly infers user intent, or if it avoids jargon.

The criterion uses an LLM-as-a-judge to evaluate the agent's final response against each rubric, producing a `yes` (1.0) or `no` (0.0) verdict for each. Like other LLM-based metrics, it samples the judge model multiple times per invocation and uses a majority vote to determine the score for each rubric in that invocation. The overall score for an invocation is the average of its rubric scores. The final criterion score for the eval case is the average of these overall scores across all invocations.

### How To Use This Criterion?

This criterion uses `RubricsBasedCriterion`, which requires a list of rubrics to be provided in the `EvalConfig`. Each rubric should be defined with a unique ID and its content.

Example `EvalConfig` entry:

```json
{
  "criteria": {
    "rubric_based_final_response_quality_v1": {
      "threshold": 0.8,
      "judge_model_options": {
        "judge_model": "gemini-flash-latest",
        "num_samples": 5
      },
      "rubrics": [
        {
          "rubric_id": "conciseness",
          "rubric_content": {
            "text_property": "The agent's response is direct and to the point."
          }
        },
        {
          "rubric_id": "intent_inference",
          "rubric_content": {
            "text_property": "The agent's response accurately infers the user's underlying goal from ambiguous queries."
          }
        }
      ]
    }
  }
}
```

### Output And How To Interpret

The criterion outputs an overall score between 0.0 and 1.0, where 1.0 indicates that the agent's responses satisfied all rubrics across all invocations, and 0.0 indicates that no rubrics were satisfied. The results also include detailed per-rubric scores for each invocation. Higher values are better.

## rubric_based_tool_use_quality_v1

This criterion assesses the quality of an agent's tool usage against a user-defined set of rubrics using LLM as a judge.

### When To Use This Criterion?

Use this criterion when you need to evaluate *how* an agent uses tools, rather than just *if* the final response is correct. It is ideal for assessing whether the agent selected the right tool, used the correct parameters, or followed a specific sequence of tool calls. This is useful for validating agent reasoning processes, debugging tool-use errors, and ensuring adherence to prescribed workflows, especially in cases where multiple tool-use paths could lead to a similar final answer but only one path is considered correct.

### Details

This criterion provides a flexible way to evaluate tool usage based on specific rules that you define as rubrics. For example, you could define rubrics to check if a specific tool was called, if its parameters were correct, or if tools were called in a particular order.

The criterion uses an LLM-as-a-judge to evaluate the agent's tool calls and responses against each rubric, producing a `yes` (1.0) or `no` (0.0) verdict for each. Like other LLM-based metrics, it samples the judge model multiple times per invocation and uses a majority vote to determine the score for each rubric in that invocation. The overall score for an invocation is the average of its rubric scores. The final criterion score for the eval case is the average of these overall scores across all invocations.

### How To Use This Criterion?

This criterion uses `RubricsBasedCriterion`, which requires a list of rubrics to be provided in the `EvalConfig`. Each rubric should be defined with a unique ID and its content, describing a specific aspect of tool use to evaluate.

Example `EvalConfig` entry:

```json
{
  "criteria": {
    "rubric_based_tool_use_quality_v1": {
      "threshold": 1.0,
      "judge_model_options": {
        "judge_model": "gemini-flash-latest",
        "num_samples": 5
      },
      "rubrics": [
        {
          "rubric_id": "geocoding_called",
          "rubric_content": {
            "text_property": "The agent calls the GeoCoding tool before calling the GetWeather tool."
          }
        },
        {
          "rubric_id": "getweather_called",
          "rubric_content": {
            "text_property": "The agent calls the GetWeather tool with coordinates derived from the user's location."
          }
        }
      ]
    }
  }
}
```

### Output And How To Interpret

The criterion outputs an overall score between 0.0 and 1.0, where 1.0 indicates that the agent's tool usage satisfied all rubrics across all invocations, and 0.0 indicates that no rubrics were satisfied. The results also include detailed per-rubric scores for each invocation. Higher values are better.

## hallucinations_v1

This criterion assesses whether a model response contains any false, contradictory, or unsupported claims.

### When To Use This Criterion?

Use this criterion to ensure the agent's response is grounded in the provided context (e.g., tool outputs, user query, instructions) and does not contain hallucinations.

### Details

This criterion assesses whether a model response contains any false, contradictory, or unsupported claims based on context that includes developer instructions, user prompt, tool definitions, and tool invocations and their results. It uses LLM-as-a-judge and follows a two-step process:

1. **Segmenter**: Segments the agent response into individual sentences.
1. **Sentence Validator**: Evaluates each segmented sentence against the provided context for grounding. Each sentence is labeled as `supported`, `unsupported`, `contradictory`, `disputed` or `not_applicable`.

The metric computes an Accuracy Score: the percentage of sentences that are `supported` or `not_applicable`. By default, only the final response is evaluated. If `evaluate_intermediate_nl_responses` is set to true in the criterion, intermediate natural language responses from agents are also evaluated.

### How To Use This Criterion?

This criterion uses `HallucinationsCriterion`, allowing you to configure the evaluation threshold, the judge model, the number of samples per invocation and whether to evaluate intermediate natural language responses.

Example `EvalConfig` entry:

```json
{
  "criteria": {
    "hallucinations_v1": {
      "threshold": 0.8,
      "judge_model_options": {
            "judge_model": "gemini-flash-latest",
          },
      "evaluate_intermediate_nl_responses": true
    }
  }
}
```

### Output And How To Interpret

The criterion returns a score between 0.0 and 1.0. A score of 1.0 means all sentences in agent's response are grounded in the context, while a score closer to 0.0 indicates that many sentences are false, contradictory, or unsupported. Higher values are better.

## safety_v1

This criterion evaluates the safety (harmlessness) of an Agent's Response.

### When To Use This Criterion?

This criterion should be used when you need to ensure that agent responses comply with safety guidelines and do not produce harmful or inappropriate content. It is essential for user-facing applications or any system where response safety is a priority.

### Details

This criterion assesses whether the agent's response contains any harmful content, such as hate speech, harassment, or dangerous information. Unlike other metrics implemented natively within ADK, `safety_v1` delegates the evaluation to the Agent Platform Eval SDK.

### How To Use This Criterion?

Using this criterion requires a Google Cloud Project. You must have `GOOGLE_CLOUD_PROJECT` and `GOOGLE_CLOUD_LOCATION` environment variables set, typically in an `.env` file in your agent's directory, for the Agent Platform SDK to function correctly.

You can specify a threshold for this criterion in `EvalConfig` under the `criteria` dictionary. The value should be a float between 0.0 and 1.0, representing the minimum safety score for a response to be considered passing.

Example `EvalConfig` entry:

```json
{
  "criteria": {
    "safety_v1": 0.8
  }
}
```

### Output And How To Interpret

The criterion returns a score between 0.0 and 1.0. Scores closer to 1.0 indicate that the response is safe, while scores closer to 0.0 indicate potential safety issues.

## per_turn_user_simulator_quality_v1

This criterion evaluates whether a user simulator is faithful to a conversation plan and persona.

#### When To Use This Criterion?

Use this criterion when you need to evaluate a user simulator in a multi-turn conversation. It is designed to assess whether the simulator follows the conversation plan and persona defined in the `ConversationScenario`.

#### Details

This criterion determines whether the a user simulator follows a defined `ConversationScenario` in a multi-turn conversation.

For the first turn, this criterion checks if user simulator response matches the `starting_prompt` in the `ConversationScenario`. For subsequent turns, it uses LLM-as-a-judge to evaluate if the user response follows the `conversation_plan` and `user_persona` in the `ConversationScenario`. To check adherence to the persona, we use the `violation_rubrics` specified in the `UserPersona`.

#### How To Use This Criterion?

This criterion allows you to configure the evaluation threshold, the judge model and the number of samples per invocation. The criterion also lets you specify a `stop_signal`, which signals the LLM judge that the conversation was completed. For best results, use the stop signal in `LlmBackedUserSimulator`.

Example `EvalConfig` entry:

```json
{
  "criteria": {
    "per_turn_user_simulator_quality_v1": {
      "threshold": 1.0,
      "judge_model_options": {
        "judge_model": "gemini-flash-latest",
        "num_samples": 5
      },
      "stop_signal": "</finished>"
    }
  }
}
```

#### Output And How To Interpret

The criterion returns a score between 0.0 and 1.0, representing the fraction of turns in which the user simulator's response was judged to be valid according to the conversation scenario. A score of 1.0 indicates that the simulator behaved as expected in all turns, while a score closer to 0.0 indicates that the simulator deviated in many turns. Higher values are better.

### multi_turn_task_success_v1

This criterion evaluates if the agent achieved the goal or goals of the conversation.

#### When To Use This Criterion?

Use this criterion when you want to measure the overall success of a multi-turn conversation in achieving its intended objectives. It focuses on the final outcome rather than the specific steps taken to reach it.

#### Details

This criterion takes into account all the turns of the multi-turn conversation to determine if the task was successfully completed. It delegates the evaluation to the Agent Platform Eval SDK.

#### How To Use This Criterion?

Using this criterion requires a Google Cloud Project. You must have `GOOGLE_CLOUD_PROJECT` and `GOOGLE_CLOUD_LOCATION` environment variables set, typically in an `.env` file in your agent's directory, for the Agent Platform SDK to function correctly.

You can specify a threshold for this criterion in `EvalConfig` under the `criteria` dictionary. The value should be a float between 0.0 and 1.0, representing the minimum score for the conversation to be considered a success.

Example `EvalConfig` entry:

```json
{
  "criteria": {
    "multi_turn_task_success_v1": 0.8
  }
}
```

#### Output And How To Interpret

The criterion returns a score between 0.0 and 1.0. Scores closer to 1.0 indicate that the task was successfully achieved, while scores closer to 0.0 indicate failure to achieve the goals.

### multi_turn_trajectory_quality_v1

This criterion evaluates the overall trajectory of the conversation.

#### When To Use This Criterion?

This metric is different from `multi_turn_task_success_v1`, in the sense that task success only concerns itself with whether the goal was achieved or not. How that was achieved is not its concern. This metric, on the other hand, evaluates the path or trajectory that the agent took to achieve the goal. Use this criterion when you care about the efficiency, effectiveness, and logic of the steps taken during the conversation.

#### Details

This criterion is a reference-free metric that assesses the quality of the interaction trajectory across multiple turns. It delegates the evaluation to the Agent Platform Eval SDK.

#### How To Use This Criterion?

Using this criterion requires a Google Cloud Project. You must have `GOOGLE_CLOUD_PROJECT` and `GOOGLE_CLOUD_LOCATION` environment variables set, typically in an `.env` file in your agent's directory, for the Agent Platform SDK to function correctly.

You can specify a threshold for this criterion in `EvalConfig` under the `criteria` dictionary. The value should be a float between 0.0 and 1.0, representing the minimum trajectory quality score to be considered passing.

Example `EvalConfig` entry:

```json
{
  "criteria": {
    "multi_turn_trajectory_quality_v1": 0.8
  }
}
```

#### Output And How To Interpret

The criterion returns a score between 0.0 and 1.0. Scores closer to 1.0 indicate a high-quality trajectory, while scores closer to 0.0 indicate a poor or inefficient trajectory.

### multi_turn_tool_use_quality_v1

This criterion evaluates the function calls made during a multi-turn conversation.

#### When To Use This Criterion?

Use this criterion to specifically assess the quality, relevance, and correctness of tool or function calls made by the agent across multiple turns of a conversation. It's useful for debugging agent capabilities such as whether the agent knows when and how to select proper tools in complex, multi-step workflows.

#### Details

This metric is reference-free and evaluates the function calling behavior without requiring a golden trajectory. It delegates the evaluation to the Vertex AI General AI Eval SDK.

#### How To Use This Criterion?

Using this criterion requires a Google Cloud Project. You must have `GOOGLE_CLOUD_PROJECT` and `GOOGLE_CLOUD_LOCATION` environment variables set, typically in an `.env` file in your agent's directory, for the Agent Platform SDK to function correctly.

You can specify a threshold for this criterion in `EvalConfig` under the `criteria` dictionary. The value should be a float between 0.0 and 1.0, representing the minimum tool use quality score to be considered passing.

Example `EvalConfig` entry:

```json
{
  "criteria": {
    "multi_turn_tool_use_quality_v1": 0.8
  }
}
```

#### Output And How To Interpret

The criterion returns a score between 0.0 and 1.0. Scores closer to 1.0 indicate excellent tool usage throughout the conversation, while scores closer to 0.0 indicate poor

## Custom Metrics for Agent Evaluation

Supported in ADKPython v1.18.0

If you require specialized metrics tailored to your specific use cases or domains that are not covered by built-in options, you can define your own custom metrics.

## Define a Custom Metric

A custom metric is a Python function that evaluates an agent's performance on a given evaluation case and returns an [`EvaluationResult`](https://github.com/google/adk-python/blob/main/src/google/adk/evaluation/evaluator.py). The function receives the [`EvalMetric`](https://github.com/google/adk-python/blob/main/src/google/adk/evaluation/eval_metrics.py), the list of [`Invocation`](https://github.com/google/adk-python/blob/main/src/google/adk/evaluation/eval_case.py) objects produced by the agent during the evaluation run, and optionally, a list of expected invocations or a [`ConversationScenario`](https://github.com/google/adk-python/blob/main/src/google/adk/evaluation/eval_case.py) as defined in the eval case.

Each `Invocation` object represents a single turn of interaction between the user and the agent, and contains information such as tool trajectory, intermediate responses, and final response for that turn.

Your custom metric function must have the following signature:

```python
from typing import Optional
from google.adk.evaluation.eval_case import Invocation
from google.adk.evaluation.eval_metrics import EvalMetric
from google.adk.evaluation.conversation_scenarios import ConversationScenario
from google.adk.evaluation.evaluator import EvaluationResult

def my_custom_metric_function(
    eval_metric: EvalMetric,
    actual_invocations: list[Invocation],
    expected_invocations: Optional[list[Invocation]],
    conversation_scenario: Optional[ConversationScenario],
) -> EvaluationResult:
  ...
```

The function should return an `EvaluationResult` object with the `overall_score`, `overall_eval_status`, and `per_invocation_results` fields populated.

### Example

Here is a simple example of a custom metric that checks if the agent's final response in each turn matches the expected final response exactly.

```python
import statistics
from typing import Optional

from google.adk.evaluation.conversation_scenarios import ConversationScenario
from google.adk.evaluation.eval_case import Invocation
from google.adk.evaluation.eval_metrics import EvalMetric
from google.adk.evaluation.eval_metrics import EvalStatus
from google.adk.evaluation.evaluator import EvaluationResult, PerInvocationResult

def check_final_response_exact_match(
    eval_metric: EvalMetric,
    actual_invocations: list[Invocation],
    expected_invocations: Optional[list[Invocation]],
    conversation_scenario: Optional[ConversationScenario],
) -> EvaluationResult:
  """Checks if the final response of the first turn matches the expected
  response."""
  if not expected_invocations:
    return EvaluationResult(overall_score=0.0, overall_eval_status=EvalStatus.NOT_EVALUATED)

  per_invocation_results = []

  for actual, expected in zip(actual_invocations, expected_invocations):
    actual_final_response = "".join([part.text for part in actual.final_response.parts])
    expected_final_response = "".join([part.text for part in expected.final_response.parts])
    score = 1.0 if actual_final_response == expected_final_response else 0.0
    eval_status = EvalStatus.PASSED if score else EvalStatus.FAILED
    invocation_result = PerInvocationResult(
        actual_invocation=actual,
        expected_invocation=expected,
        score=score,
        eval_status=eval_status
    )
    per_invocation_results.append(invocation_result)

  average_score = statistics.mean(result.score for result in per_invocation_results)

  threshold = eval_metric.criterion.threshold
  overall_eval_status = (
    EvalStatus.PASSED if average_score >= threshold else EvalStatus.FAILED
  )
  return EvaluationResult(
      overall_score=average_score,
      overall_eval_status=overall_eval_status,
      per_invocation_results=per_invocation_results,
  )
```

#### Async Metric

If your custom metric needs to make asynchronous calls, such as calling an API, you can define it as an `async` function.

The following is an example of a custom metric function that uses a fake async profanity checker API to check if the agent response contains profanity.

```python
import asyncio
import statistics
from typing import Optional

from google.adk.evaluation.conversation_scenarios import ConversationScenario
from google.adk.evaluation.eval_case import Invocation
from google.adk.evaluation.eval_metrics import EvalMetric
from google.adk.evaluation.eval_metrics import EvalStatus
from google.adk.evaluation.evaluator import EvaluationResult, PerInvocationResult

class ProfanityChecker:
  """A fake profanity checker that mimics an async API."""

  async def check(self, text: str) -> bool:
    """Returns True if profanity is detected, False otherwise."""
    await asyncio.sleep(0.01)
    return "profanity" in text.lower()

profanity_checker = ProfanityChecker()

async def check_for_profanity(
    eval_metric: EvalMetric,
    actual_invocations: list[Invocation],
    expected_invocations: Optional[list[Invocation]],
    conversation_scenario: Optional[ConversationScenario],
) -> EvaluationResult:
  """Checks if the agent response contains profanity using a fake async API."""
  per_invocation_results = []

  for invocation in actual_invocations:
    agent_response = "".join(part.text for part in invocation.final_response.parts)
    has_profanity = await profanity_checker.check(agent_response)
    score = 0.0 if has_profanity else 1.0
    eval_status = EvalStatus.FAILED if has_profanity else EvalStatus.PASSED

    invocation_result = PerInvocationResult(
        actual_invocation=invocation,
        score=score,
        eval_status=eval_status
    )
    per_invocation_results.append(invocation_result)

  scores = [
      result.score
      for result in per_invocation_results
      if result.eval_status != EvalStatus.NOT_EVALUATED
  ]

  average_score = statistics.mean(scores)

  threshold = eval_metric.criterion.threshold
  overall_eval_status = (
      EvalStatus.PASSED if average_score >= threshold else EvalStatus.FAILED
  )
  return EvaluationResult(
      overall_score=average_score,
      overall_eval_status=overall_eval_status,
      per_invocation_results=per_invocation_results,
  )
```

## Use a Custom Metric

To use your custom metric in an evaluation run with `adk eval`, you need to specify it in your `EvalConfig` JSON file.

1. Add your custom metric as one of the eval `criteria`. The key is your metric name, and the value is the passing threshold.
1. Add a `custom_metrics` object to `EvalConfig`. Inside this object, add an entry for each custom metric, where the key is the metric name (matching the one in `criteria`) and the value is an object containing `code_config`.
1. The `code_config` object should contain a `name` field with a string representing the Python import path to your custom metric function, in the format `my.module.my_function`.

### Example `EvalConfig`

Assuming your `check_final_response_match` function is defined in `my_agent.metrics.py`, your `EvalConfig` might look like this:

```json
{
  "criteria": {
    "my_check_final_response_exact_match": {
      "threshold": 0.8
    },
    "tool_trajectory_avg_score": {
      "threshold": 1.0
    }
  },
  "custom_metrics": {
    "my_check_final_response_exact_match": {
      "code_config": {
        "name": "my_agent.metrics.check_final_response_exact_match"
      }
    }
  }
}
```

With this configuration, when you run `adk eval --config_file_path=<path_to_this_config>`, ADK will execute `check_final_response_exact_match` for each eval case, and check if the returned score is >= 0.8 to mark the `response_match` criterion as passed or failed.

### Providing Metric Information

You can optionally provide metadata about your custom metric, such as its description and value range, by adding a [`MetricInfo`](https://github.com/google/adk-python/blob/main/src/google/adk/evaluation/eval_metrics.py#L369) object within your custom metric definition in `EvalConfig`. If `metric_info` is not provided, ADK will use default values (`min_value`=0.0, `max_value`=1.0).

This information can be used by ADK tools for display and result aggregation purposes.

Here is an example of providing `metric_info` for a custom metric that returns a score between -1.0 and 1.0:

```json
{
  "criteria": {
    "my_metric": {
      "threshold": 0.5
    }
  },
  "custom_metrics": {
    "my_metric": {
      "code_config": {
        "name": "my_agent.metrics.my_metric_function"
      },
      "metric_info": {
        "metric_name": "my_metric",
        "description": "This metric evaluates XYZ and returns a score between -1.0 and 1.0.",
        "metric_value_info": {
          "interval": {
            "min_value": -1.0,
            "max_value": 1.0
          }
        }
      }
    }
  }
}
```

# Environment simulation for evaluations

Supported in ADKPython v1.24.0

When evaluating agents that rely on external dependencies — such as APIs, databases, or third-party services — running those tools live during testing can be slow, costly, or unreliable. The **Environment Simulator** lets you safely intercept these tool calls during agent execution and replace them with controlled, deterministic responses, without modifying the agent itself. This approach can fill a critical gap in the agent improvement loop, allowing you to create hermetic, offline test runs that isolate your agent logic for reliable scoring.

Overall, this feature lets you:

- Test how an agent handles API errors or edge-case responses.
- Run evaluations offline, without access to live backends.
- Generate realistic mock responses automatically using an LLM.
- Produce reproducible test runs by seeding probabilistic injections.

The Environment Simulation integrates with ADK's tool execution pipeline via the [`before_tool_callback`](/callbacks/types-of-callbacks/#tool-execution-callbacks) hook or the [plugin system](/plugins/), so no changes to your agent code are required.

```text
The Environment Simulation is an experimental feature. Its API may change in future
releases.
```

## How it works

While [User Simulation](/evaluate/user-sim/) drives the conversation forward, Environment Simulation provides the stable backend. At a high level, the Environment Simulator sits between your agent and its tools. When the agent calls a tool, the simulator intercepts the call and decides whether to return a synthetic response — either a predefined injection or an LLM-generated mock — or to let the real tool execute.

The decision logic follows this order for each configured tool:

1. **Injection configs** are checked first, in order. If a matching injection is found (based on argument matching and probability), its error or response is returned immediately.
1. **Mock strategy** is used as a fallback if no injection config applies. The simulator calls an LLM to generate a realistic response based on the tool's schema and any stateful context.
1. **No-op** is returned (`None`) if the tool is not in the simulator config, allowing the real tool to execute normally.

## Integration

The `EnvironmentSimulationFactory` class provides two integration points:

- `create_callback()` — Returns an async callable suitable for use as a `before_tool_callback` on any `LlmAgent`.
- `create_plugin()` — Returns an `EnvironmentSimulationPlugin` instance that integrates with the ADK plugin system.

### Using as a callback

The following example shows how to create an environment simulation as one of the adk agent callbacks.

```python
from google.adk.agents import LlmAgent
from google.adk.tools.environment_simulation import EnvironmentSimulationFactory
from google.adk.tools.environment_simulation.environment_simulation_config import (
    EnvironmentSimulationConfig,
    InjectedError,
    InjectionConfig,
    ToolSimulationConfig,
)

config = EnvironmentSimulationConfig(
    tool_simulation_configs=[
        ToolSimulationConfig(
            tool_name="get_user_profile",
            injection_configs=[
                InjectionConfig(
                    injected_error=InjectedError(
                        injected_http_error_code=503,
                        error_message="Service temporarily unavailable.",
                    )
                )
            ],
        )
    ]
)

agent = LlmAgent(
    name="my_agent",
    model="gemini-2.5-flash",
    tools=[get_user_profile],
    before_tool_callback=EnvironmentSimulationFactory.create_callback(config),
)
```

### Using as a plugin

The following example shows how to create environment simulation as an ADK agent plugin.

```python
from google.adk.apps import App
from google.adk.tools.environment_simulation import EnvironmentSimulationFactory
from google.adk.tools.environment_simulation.environment_simulation_config import (
    EnvironmentSimulationConfig,
    MockStrategy,
    ToolSimulationConfig,
)

config = EnvironmentSimulationConfig(
    tool_simulation_configs=[
        ToolSimulationConfig(
            tool_name="search_products",
            mock_strategy_type=MockStrategy.MOCK_STRATEGY_TOOL_SPEC,
        )
    ]
)

app = App(
    agent=my_agent,
    plugins=[EnvironmentSimulationFactory.create_plugin(config)],
)
```

## Configuration reference

You can configure the Environment Simulator with a set of dataclasses. The following sections provide a detailed reference for each configuration object.

### `EnvironmentSimulationConfig`

The top-level configuration object.

| Field                            | Type                         | Default              | Description                                                                                                                   |
| -------------------------------- | ---------------------------- | -------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `tool_simulation_configs`        | `List[ToolSimulationConfig]` | required             | One entry per tool to simulate. Must not be empty, and tool names must be unique.                                             |
| `simulation_model`               | `str`                        | `"gemini-2.5-flash"` | The LLM used for tool connection analysis and mock response generation.                                                       |
| `simulation_model_configuration` | `GenerateContentConfig`      | thinking enabled     | LLM generation config for internal simulator calls.                                                                           |
| `environment_data`               | `str \| None`                | `None`               | Optional environment context (e.g., a JSON database snapshot) passed to mock strategies to generate more realistic responses. |
| `tracing`                        | `str \| None`                | `None`               | Tracing data (e.g., a prior agent run trace in JSON string format) to provide historical context.                             |

### `ToolSimulationConfig`

Defines how a single named tool should be simulated.

| Field                | Type                    | Default                     | Description                                                                |
| -------------------- | ----------------------- | --------------------------- | -------------------------------------------------------------------------- |
| `tool_name`          | `str`                   | required                    | Must match the tool's registered name exactly.                             |
| `injection_configs`  | `List[InjectionConfig]` | `[]`                        | Zero or more injection configs, checked in order before the mock strategy. |
| `mock_strategy_type` | `MockStrategy`          | `MOCK_STRATEGY_UNSPECIFIED` | Fallback strategy when no injection is triggered.                          |

### `InjectionConfig`

Controls a single synthetic response that can be injected into a tool call. Exactly one of `injected_error` or `injected_response` must be set.

| Field                      | Type                     | Default | Description                                                                                             |
| -------------------------- | ------------------------ | ------- | ------------------------------------------------------------------------------------------------------- |
| `injected_error`           | `InjectedError \| None`  | `None`  | Error to return (mutually exclusive with `injected_response`).                                          |
| `injected_response`        | `Dict[str, Any] \| None` | `None`  | Fixed response dict to return (mutually exclusive with `injected_error`).                               |
| `injection_probability`    | `float`                  | `1.0`   | Probability `[0.0, 1.0]` that this injection fires.                                                     |
| `match_args`               | `Dict[str, Any] \| None` | `None`  | If set, the injection only fires when the tool's arguments contain all key-value pairs in `match_args`. |
| `injected_latency_seconds` | `float`                  | `0.0`   | Artificial delay (≤ 120 s) added before returning the injection result.                                 |
| `random_seed`              | `int \| None`            | `None`  | Seed for the probability check, enabling deterministic injection behavior.                              |

### `InjectedError`

Defines an HTTP-style error response.

| Field                                           | Type  | Description                        |
| ----------------------------------------------- | ----- | ---------------------------------- |
| `injected_http_error_code`                      | `int` | HTTP status code to surface as     |
| : : : `"error_code"` in the tool response. :    |       |                                    |
| `error_message`                                 | `str` | Human-readable message surfaced as |
| : : : `"error_message"` in the tool response. : |       |                                    |

### `MockStrategy`

Enum controlling how the simulator generates responses when no injection fires.

| Value                                                 | Description                                    |
| ----------------------------------------------------- | ---------------------------------------------- |
| `MOCK_STRATEGY_TOOL_SPEC`                             | Uses the tool's schema and stateful context to |
| : : prompt an LLM to generate a realistic response. : |                                                |
| `MOCK_STRATEGY_TRACING`                               | *(Deprecated)* Please use                      |
| : : `MOCK_STRATEGY_TOOL_SPEC` with tracing input. :   |                                                |

## Injection mode

Use injection configs to test specific failure or edge-case scenarios. Injections are evaluated in list order; the first one whose `match_args` criteria are met (and whose probability check passes) is applied.

### Injecting errors

The following example shows how to inject errors with specific error code and error message to the agent.

```python
from google.adk.tools.environment_simulation.environment_simulation_config import (
    InjectedError,
    InjectionConfig,
    ToolSimulationConfig,
)

ToolSimulationConfig(
    tool_name="charge_payment",
    injection_configs=[
        InjectionConfig(
            injected_error=InjectedError(
                injected_http_error_code=402,
                error_message="Payment declined.",
            )
        )
    ],
)
```

The agent will receive `{"error_code": 402, "error_message": "Payment declined."}` instead of a real tool result, allowing you to evaluate how the agent handles payment failures.

### Injecting fixed responses

Use the following InjectionConfig to specify a success response with fixed response payload.

```python
InjectionConfig(
    injected_response={"status": "ok", "order_id": "ORD-9999"}
)
```

### Conditional injection with argument matching

Use `match_args` to inject only when specific arguments are passed.

```python
InjectionConfig(
    match_args={"item_id": "ITEM-404"},
    injected_error=InjectedError(
        injected_http_error_code=404,
        error_message="Item not found.",
    ),
)
```

Here, the error is injected only when the tool is called with `item_id="ITEM-404"`. All other calls pass through to the next injection config or to the mock strategy.

### Probabilistic injection

Set `injection_probability` to a value between `0.0` and `1.0` to simulate flaky behavior. For reproducible test runs, pin the random outcome with `random_seed`.

```python
InjectionConfig(
    injection_probability=0.3,
    random_seed=42,
    injected_error=InjectedError(
        injected_http_error_code=500,
        error_message="Internal server error.",
    ),
)
```

### Injecting latency

Use `injected_latency_seconds` to simulate slow backend responses, useful for testing timeout handling or user experience under degraded conditions.

```python
InjectionConfig(
    injected_latency_seconds=5.0,
    injected_response={"result": "slow but successful"},
)
```

### Combining multiple injection configs

Multiple injection configs on a single tool are checked in order. You can combine them to test multiple scenarios:

```python
ToolSimulationConfig(
    tool_name="get_inventory",
    injection_configs=[
        # Always fail for a specific out-of-stock item
        InjectionConfig(
            match_args={"sku": "OOS-001"},
            injected_response={"quantity": 0, "available": False},
        ),
        # Randomly fail 20% of the time for all other items
        InjectionConfig(
            injection_probability=0.2,
            random_seed=7,
            injected_error=InjectedError(
                injected_http_error_code=503,
                error_message="Inventory service unavailable.",
            ),
        ),
    ],
)
```

## Mock strategy mode

When you want the simulator to generate plausible responses automatically — rather than returning hand-crafted values — use `MOCK_STRATEGY_TOOL_SPEC`.

The simulator uses an LLM to:

1. Analyze the schemas of all tools the agent has access to, and identify *stateful dependencies* between them (e.g., a `create_order` tool produces an `order_id` that `get_order` consumes).
1. Track a **state store** of IDs and resources created during the session.
1. Generate a response that is consistent with the tool's schema and the current state — returning a 404-style error if a consuming tool requests a resource that was never created.

```python
from google.adk.tools.environment_simulation.environment_simulation_config import (
    EnvironmentSimulationConfig,
    MockStrategy,
    ToolSimulationConfig,
)

config = EnvironmentSimulationConfig(
    tool_simulation_configs=[
        ToolSimulationConfig(
            tool_name="create_order",
            mock_strategy_type=MockStrategy.MOCK_STRATEGY_TOOL_SPEC,
        ),
        ToolSimulationConfig(
            tool_name="get_order",
            mock_strategy_type=MockStrategy.MOCK_STRATEGY_TOOL_SPEC,
        ),
        ToolSimulationConfig(
            tool_name="cancel_order",
            mock_strategy_type=MockStrategy.MOCK_STRATEGY_TOOL_SPEC,
        ),
    ]
)
```

With this config, the simulator will automatically generate an `order_id` when `create_order` is mocked, and use it to return consistent results (or a not-found error) when `get_order` or `cancel_order` are subsequently called.

### Providing environment data

Pass domain-specific context through `environment_data` to make mock responses more realistic. This can be a JSON string representing a snapshot of your database or any structured context the LLM should use when generating responses.

```python
import json

db_snapshot = {
    "products": [
        {"id": "P-001", "name": "Wireless Headphones", "price": 79.99, "stock": 12},
        {"id": "P-002", "name": "USB-C Hub", "price": 34.99, "stock": 0},
    ],
    "warehouse_location": "US-WEST-2",
}

config = EnvironmentSimulationConfig(
    tool_simulation_configs=[
        ToolSimulationConfig(
            tool_name="search_products",
            mock_strategy_type=MockStrategy.MOCK_STRATEGY_TOOL_SPEC,
        ),
    ],
    environment_data=json.dumps(db_snapshot),
)
```

The LLM will use this data to return product names, prices, and stock levels that match your domain, rather than generating arbitrary placeholder values.

### Providing tracing data

Feed traces generated in the agent to be mocked through `tracing` to make mock responses more realistic.

```python
import json

agent_traces = [
    {
        "invocation_id": "inv-001",
        "user_content": {"role": "user", "parts": [{"text": "Search for high-end headphones"}]},
        "intermediate_data": {
            "tool_uses": [
                {
                    "name": "search_products",
                    "args": {"query": "high-end headphones"},
                    "response": {"products": [{"id": "P-123", "name": "Premium Wireless ANC Headphones"}]}
                }
            ]
        }
    }
]

config = EnvironmentSimulationConfig(
    tool_simulation_configs=[
        ToolSimulationConfig(
            tool_name="search_products",
            mock_strategy_type=MockStrategy.MOCK_STRATEGY_TOOL_SPEC,
        ),
    ],
    tracing=json.dumps(agent_traces),
)
```

The LLM will use this data to return product names, prices, and stock levels that match your domain, rather than generating arbitrary placeholder values.

## Mixing injections and mock strategy

Injection configs and a mock strategy can be combined on the same tool. Injections are always checked first; the mock strategy fires only when no injection applies.

```python
ToolSimulationConfig(
    tool_name="send_notification",
    injection_configs=[
        # Always fail for a known-bad recipient
        InjectionConfig(
            match_args={"recipient_id": "INVALID"},
            injected_error=InjectedError(
                injected_http_error_code=400,
                error_message="Invalid recipient.",
            ),
        ),
    ],
    # For all other recipients, generate a plausible success response
    mock_strategy_type=MockStrategy.MOCK_STRATEGY_TOOL_SPEC,
)
```

# User Simulation

Supported in ADKPython v1.18.0

When evaluating conversational agents, it is not always practical to use a fixed set of user prompts, as the conversation can proceed in unexpected ways. For example, if the agent needs the user to supply two values to perform a task, it may ask for those values one at a time or both at once. To resolve this issue, ADK can dynamically generate user prompts using a generative AI model.

To use this feature, you must specify a [`ConversationScenario`](https://github.com/google/adk-python/blob/main/src/google/adk/evaluation/conversation_scenarios.py) which dictates the user's goals in their conversation with the agent. You may also specify a user persona that you expect the user to adhere to.

A `ConversationScenario` consists of the following components:

- `starting_prompt`: A fixed initial prompt that the user should use to start the conversation with the agent.
- `conversation_plan`: A high-level guideline for the goals the user must achieve.
- `user_persona`: A definition of the user's traits, such as technical expertise or linguistic style.

A sample conversation scenario for the [`hello_world`](https://github.com/google/adk-python/tree/main/contributing/samples/hello_world) agent is shown below:

```json
{
  "starting_prompt": "What can you do for me?",
  "conversation_plan": "Ask the agent to roll a 20-sided die. After you get the result, ask the agent to check if it is prime."
}
```

The LLM uses the `conversation_plan`, along with the conversation history, to dynamically generate user prompts.

You can also specify a pre-built `user_persona` in the following manner:

```json
{
  "starting_prompt": "What can you do for me?",
  "conversation_plan": "Ask the agent to roll a 20-sided die. After you get the result, ask the agent to check if it is prime.",
  "user_persona": "NOVICE"
}
```

While the conversation plan dictates what must be accomplished, the persona dictates how the model phrases its queries and reacts to the agent's responses.

Try it in Colab

Test this entire workflow yourself in an interactive notebook on [Simulating User Conversations to Dynamically Evaluate ADK Agents](https://github.com/google/adk-samples/blob/main/python/notebooks/evaluation/user_simulation_in_adk_evals.ipynb). You'll define a conversation scenario, run a "dry run" to check the dialogue, and then perform a full evaluation to score the agent's responses.

## User Personas

A User Persona is a role that the simulated user adopts during the conversation. It is defined by a set of **behaviors** that dictate how the user interacts with the agent, such as their communication style, how they provide information, and how they react to errors.

A `UserPersona` consists of the following fields:

- `id`: A unique identifier for the persona.
- `description`: A high-level description of who the user is and how they interact with the agent.
- `behaviors`: A list of `UserBehavior` objects that define specific traits.

Each `UserBehavior` includes:

- `name`: The name of the behavior.
- `description`: A summary of the expected behavior.
- `behavior_instructions`: Specific instructions given to the simulated user (LLM) on how to act.
- `violation_rubrics`: Used by evaluators to determine whether the user is following this behavior. If **any** of these rubrics are **satisfied**, the evaluator should determine the behavior was **not** followed.

## Pre-built Personas

ADK provides a set of pre-built personas composed of common behaviors. The table below summarizes the behaviors for each persona:

| Behavior                       | **EXPERT** persona                             | **NOVICE** persona                            | **EVALUATOR** persona   |
| ------------------------------ | ---------------------------------------------- | --------------------------------------------- | ----------------------- |
| **Advance**                    | Detail oriented (proactively provides details) | Goal oriented (waits to be asked for details) | Detail oriented         |
| **Answer**                     | Relevant questions only                        | Answer all questions                          | Relevant questions only |
| **Correct Agent Inaccuracies** | Yes                                            | No                                            | No                      |
| **Troubleshoot Agent Errors**  | Once                                           | Never                                         | Never                   |
| **Tone**                       | Professional                                   | Conversational                                | Conversational          |

## Example: Evaluating the [`hello_world`](https://github.com/google/adk-python/tree/main/contributing/samples/hello_world) agent with conversation scenarios

To add evaluation cases containing conversation scenarios to a new or existing [`EvalSet`](https://github.com/google/adk-python/blob/main/src/google/adk/evaluation/eval_set.py), you need to first create a list of conversation scenarios to test the agent in.

Try saving the following to `contributing/samples/hello_world/conversation_scenarios.json`:

```json
{
  "scenarios": [
    {
      "starting_prompt": "What can you do for me?",
      "conversation_plan": "Ask the agent to roll a 20-sided die. After you get the result, ask the agent to check if it is prime.",
      "user_persona": "NOVICE"
    },
    {
      "starting_prompt": "Hi, I'm running a tabletop RPG in which prime numbers are bad!",
      "conversation_plan": "Say that you don't care about the value; you just want the agent to tell you if a roll is good or bad. Once the agent agrees, ask it to roll a 6-sided die. Finally, ask the agent to do the same with 2 20-sided dice.",
      "user_persona": "EXPERT"
    }
  ]
}
```

You will also need a session input file containing information used during evaluation. Try saving the following to `contributing/samples/hello_world/session_input.json`:

```json
{
  "app_name": "hello_world",
  "user_id": "user"
}
```

Then, you can add the conversation scenarios to an `EvalSet`:

```bash
# (optional) create a new EvalSet
adk eval_set create \
  contributing/samples/hello_world \
  eval_set_with_scenarios

# add conversation scenarios to the EvalSet as new eval cases
adk eval_set add_eval_case \
  contributing/samples/hello_world \
  eval_set_with_scenarios \
  --scenarios_file contributing/samples/hello_world/conversation_scenarios.json \
  --session_input_file contributing/samples/hello_world/session_input.json
```

By default, ADK runs evaluations with metrics that require the agent's expected response to be specified. Since that is not the case for a dynamic conversation scenario, we will use an [`EvalConfig`](https://github.com/google/adk-python/blob/main/src/google/adk/evaluation/eval_config.py) with some alternate supported metrics.

Try saving the following to `contributing/samples/hello_world/eval_config.json`:

```json
{
  "criteria": {
    "hallucinations_v1": {
      "threshold": 0.5,
      "evaluate_intermediate_nl_responses": true
    },
    "safety_v1": {
      "threshold": 0.8
    }
  }
}
```

Finally, you can use the `adk eval` command to run the evaluation:

```bash
adk eval \
    contributing/samples/hello_world \
    --config_file_path contributing/samples/hello_world/eval_config.json \
    eval_set_with_scenarios \
    --print_detailed_results
```

## User simulator configuration

You can override the default user simulator configuration to change the model, internal model behavior, and the maximum number of user-agent interactions. The below `EvalConfig` shows the default user simulator configuration:

```json
{
  "criteria": {
    # same as before
  },
  "user_simulator_config": {
    "model": "gemini-flash-latest",
    "model_configuration": {
      "thinking_config": {
        "include_thoughts": true,
        "thinking_budget": 10240
      }
    },
    "max_allowed_invocations": 20
  }
}
```

- `model`: The model backing the user simulator.
- `model_configuration`: A [`GenerateContentConfig`](https://github.com/googleapis/python-genai/blob/6196b1b4251007e33661bb5d7dc27bafee3feefe/google/genai/types.py#L4295) which controls the model behavior.
- `max_allowed_invocations`: The maximum user-agent interactions allowed before the conversation is forcefully terminated. This should be set to be greater than the longest reasonable user-agent interaction in your `EvalSet`.
- `custom_instructions`: Optional. Overrides the default instructions for the user simulator. The instruction string must contain the following formatting placeholders using [Jinja](https://jinja.palletsprojects.com/en/stable/templates/#) syntax (*do not substitute values in advance!*):
  - `{{ stop_signal }}` : text to be generated when the user simulator decides that the conversation is over.
  - `{{ conversation_plan }}` : the overall plan for the conversation that the user simulator must follow.
  - `{{ conversation_history }}` : the conversation between the user and the agent so far.
  - You can also access the `UserPersona` object through the `{{ persona }}` placeholder.

## Custom Personas

You can define your own custom persona by providing a `UserPersona` object in the `ConversationScenario`.

Example of a custom persona definition:

```json
{
  "starting_prompt": "I need help with my account.",
  "conversation_plan": "Ask the agent to reset your password.",
  "user_persona": {
    "id": "IMPATIENT_USER",
    "description": "A user who is in a rush and gets easily frustrated.",
    "behaviors": [
      {
        "name": "Short responses",
        "description": "The user should provide very short, sometimes incomplete responses.",
        "behavior_instructions": [
            "Keep your responses under 10 words.",
            "Omit polite phrases."
        ],
        "violation_rubrics": [
            "The user response is over 10 words.",
            "The user response is overly polite."
        ]
      }
    ]
  }
}
```

## Generating Evaluation Cases via User Simulation

Writing evaluation cases manually can be time-consuming and may not cover all potential failure modes. ADK provides a command to automatically generate diverse and realistic conversation scenarios based on your agent's definition using the Agent Platform Eval SDK.

Prerequisites: Agent Platform Credentials

Generating evaluation cases uses the [Vertex Gen AI Evaluation Service API](https://docs.cloud.google.com/vertex-ai/generative-ai/docs/models/evaluation-overview). You must have a Google Cloud project with the Agent Platform API enabled and valid Application Default Credentials (ADC) configured in your environment.

### Command Syntax

```bash
adk eval_set generate_eval_cases \
    <AGENT_MODULE_FILE_PATH> \
    <EVAL_SET_ID> \
    --user_simulation_config_file=<PATH_TO_CONFIG_FILE>
```

### Configuration File Format

The `--user_simulation_config_file` expects a JSON file matching the `ConversationGenerationConfig` schema:

```json
{
  "count": 5,
  "generation_instruction": "Generate scenarios where the user asks to control home devices under different conditions.",
  "environment_context": "Available devices: device_1 (Light), device_2 (Thermostat).",
  "model_name": "gemini-flash-latest"
}
```

### Configuration Fields

- **`count`** (required): The number of conversation scenarios to generate.
- **`generation_instruction`** (optional): A natural language prompt guiding the specific types of scenarios or goals you want to test.
- **`environment_context`** (optional): Context describing the backend data or state accessible to the agent's tools. This helps the generator create queries that are grounded in realistic data (e.g., valid device IDs).
- **`model_name`** (required): The Gemini model used for generation (e.g., `gemini-flash-latest`).




