# Run Agents

# Agent Runtime

Supported in ADKPython v0.1.0TypeScript v0.2.0Go v0.1.0Java v0.1.0

ADK provides several ways to run and test your agents during development. Choose the method that best fits your development workflow.

## Ways to run agents

- **Dev UI**

  ______________________________________________________________________

  Use `adk web` to launch a browser-based interface for interacting with your agents.

  [Use the Web Interface](https://adk.dev/runtime/web-interface/index.md)

- **Command Line**

  ______________________________________________________________________

  Use `adk run` to interact with your agents directly in the terminal.

  [Use the Command Line](https://adk.dev/runtime/command-line/index.md)

- **API Server**

  ______________________________________________________________________

  Use `adk api_server` to expose your agents through a RESTful API.

  [Use the API Server](https://adk.dev/runtime/api-server/index.md)

- **Ambient Agents**

  ______________________________________________________________________

  Build autonomous agents that process events, monitor systems, and respond asynchronously without human intervention.

  [Use Ambient Agents](https://adk.dev/runtime/ambient-agents/index.md)

## Technical reference

For more in-depth information on runtime configuration and behavior, see these pages:

- **[Event Loop](https://adk.dev/runtime/event-loop/index.md)**: Understand the core event loop that powers ADK, including the yield/pause/resume cycle.
- **[Resume Agents](https://adk.dev/runtime/resume/index.md)**: Learn how to resume agent execution from a previous state.
- **[Cancel Agent Runs](https://adk.dev/runtime/cancel/index.md)**: Gracefully cancel running agent invocations using AbortSignal (TypeScript).
- **[Runtime Config](https://adk.dev/runtime/runconfig/index.md)**: Configure runtime behavior with RunConfig.

# Trigger actions with ambient agents

Supported in ADKPython v1.29.0Go v1.1.0

When running an agent workflow, you may want to activate it in response to an event or new data being available, rather than waiting for input from a human. You can configure ADK agents with triggers to respond to events and perform work, known as *ambient agents*. These agents can run as background processes to process data, monitor events, and respond asynchronously without human intervention. You can use ambient agents to:

- **React to cloud events.** Process a file when it's uploaded to [Cloud Storage](https://cloud.google.com/storage), respond to database changes, or handle audit log entries.
- **Process messages from a queue.** Analyze incoming support tickets, moderate content, classify documents, or run QA as items arrive.
- **Run on a schedule.** Generate daily reports, run periodic monitoring checks, or process batch jobs at regular intervals.
- **Monitor infrastructure.** React to a continuous stream of events across your infrastructure and act on changes autonomously.

## Getting results from ambient agents

Because ambient agents run without human interaction, you need to route their outputs to a notification channel. Common patterns include:

- **[Structured logging](https://adk.dev/observability/logging/index.md).** Write JSON logs and configure [Cloud Monitoring](https://cloud.google.com/monitoring/support/notification-options) alerts to notify via email, Slack, or PagerDuty.
- **[Pub/Sub](https://cloud.google.com/pubsub).** Publish results to a topic for downstream services to consume.
- **[Application Integration](https://cloud.google.com/application-integration/docs/listen-pub-sub-topic-send-email).** Route agent outputs to email, Jira, or other systems.

## How to build ambient agents

ADK provides two approaches:

|                         | [`/run`](https://adk.dev/runtime/api-server/index.md)                         | Trigger endpoints                                                                                                                                                                                                                               |
| ----------------------- | ----------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Event sources**       | Any (Pub/Sub, webhooks, cron, custom services)                                | [Cloud Pub/Sub](https://cloud.google.com/pubsub), [Eventarc](https://cloud.google.com/eventarc) ([Standard](https://cloud.google.com/eventarc/standard/docs/overview) and [Advanced](https://cloud.google.com/eventarc/advanced/docs/overview)) |
| **Payload parsing**     | You handle it                                                                 | Automatic (Base64 decoding, CloudEvent parsing)                                                                                                                                                                                                 |
| **Session creation**    | Enable `--auto_create_session`                                                | Automatic (one per event)                                                                                                                                                                                                                       |
| **Session storage**     | Your configured [`SessionService`](https://adk.dev/sessions/session/index.md) | Your configured [`SessionService`](https://adk.dev/sessions/session/index.md)                                                                                                                                                                   |
| **Concurrency control** | You handle it                                                                 | Built-in semaphore with configurable limit                                                                                                                                                                                                      |
| **Retry logic**         | You handle it                                                                 | Exponential backoff with jitter for transient errors                                                                                                                                                                                            |
| **Best for**            | Custom integrations, non-GCP sources                                          | GCP-native event-driven workloads                                                                                                                                                                                                               |

## Using `/run`

Use the [`/run`](https://adk.dev/runtime/api-server/index.md) endpoint when you need full control over the integration or are working with non-GCP event sources. Enable `--auto_create_session` so that sessions are created automatically, then connect any HTTP client to call `/run` when events arrive.

```bash
adk api_server --auto_create_session path/to/your/agent
```

This pattern works with any event source that can make an HTTP request.

Example: Processing incoming webhooks

The following [Cloud Run function](https://cloud.google.com/functions/docs/writing/write-event-driven-functions) receives a webhook from an external service (for example, GitHub) and forwards it to your agent:

```python
import json
import uuid

import functions_framework
import requests

AGENT_URL = "https://my-agent-service-xxxxx.run.app"

@functions_framework.http
def handle_webhook(request):
    """Cloud Run function that receives webhooks and forwards to the agent."""
    payload = request.get_json(silent=True) or {}

    requests.post(
        f"{AGENT_URL}/apps/my_agent/run",
        json={
            "app_name": "my_agent",
            "user_id": payload.get("account", "webhook-caller"),
            "session_id": str(uuid.uuid4()),
            "new_message": {
                "role": "user",
                "parts": [{"text": json.dumps(payload)}],
            },
        },
    )

    return ("ok", 200)
```

Example: Send an event with curl

```bash
curl -X POST http://localhost:8000/apps/my_agent/run \
  -H "Content-Type: application/json" \
  -d '{
    "app_name": "my_agent",
    "user_id": "webhook-caller",
    "session_id": "session-123",
    "new_message": {
      "role": "user",
      "parts": [{"text": "{\"order_id\": \"1234\", \"status\": \"new\"}"}]
    }
  }'
```

## Using trigger endpoints

Use trigger endpoints when your event sources are Pub/Sub or Eventarc and you want ADK to handle payload parsing, session creation, concurrency, and retries.

### How events are processed

Pub/Sub and Eventarc deliver events to your agent as HTTP POST requests. When a trigger endpoint receives an event, it:

1. **Parses the request** according to the source format (Pub/Sub push message or CloudEvent).
1. **Decodes the payload.** Base64-encoded message data is decoded and, if possible, parsed as JSON.
1. **Creates a session** automatically with a generated UUID. Unlike the `/run` endpoint, you do not need to enable `--auto_create_session` — trigger endpoints always create a new session per event.
1. **Runs your agent** with the decoded event as a user message.
1. **Returns a status code.** A `200` response tells Pub/Sub or Eventarc that the event was processed successfully. A `500` response signals a failure, and the event source retries delivery based on its retry policy.

### Supported sources

| Source       | Endpoint                            | Description                                                                                                                                                                                                                                                                                                     |
| ------------ | ----------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Pub/Sub**  | `/apps/{app_name}/trigger/pubsub`   | Receives messages from a [Pub/Sub push subscription](https://cloud.google.com/pubsub/docs/push).                                                                                                                                                                                                                |
| **Eventarc** | `/apps/{app_name}/trigger/eventarc` | Receives [CloudEvents](https://cloudevents.io/) delivered by [Eventarc](https://cloud.google.com/eventarc) ([Standard](https://cloud.google.com/eventarc/standard/docs/overview) or [Advanced](https://cloud.google.com/eventarc/advanced/docs/overview)), supporting both structured and binary content modes. |

### Example agent

The following agent processes events from a trigger endpoint. It uses a `parse_event` tool to extract the event data and attributes, then analyzes the contents.

Agent code (`event_processing_agent/agent.py`)

```python
import json

from google.adk.agents import LlmAgent


def parse_event(raw_event: str) -> dict:
    """Parse and extract structured data from a trigger event.

    Trigger endpoints deliver events as a JSON string with 'data' and
    'attributes' fields. This tool extracts those fields so the agent
    can reason about the event contents.
    """
    try:
        event = json.loads(raw_event)
    except json.JSONDecodeError as e:
        return {"error": f"Failed to parse event JSON: {e}"}
    return {
        "data": event.get("data"),
        "attributes": event.get("attributes", {}),
    }


root_agent = LlmAgent(
    model="gemini-flash-latest",
    name="event_processor",
    instruction="""You are an event-processing agent that handles incoming
events from Pub/Sub and Eventarc triggers.

When you receive an event:
1. Use the `parse_event` tool to extract the event data and attributes.
2. Analyze the event contents and determine what action to take.
3. Summarize what you found and what action you would recommend.

Be concise and structured in your responses.""",
    tools=[parse_event],
)
```

The following agent processes events from a trigger endpoint. It extracts the event data and attributes, then analyzes the contents.

Agent code (`event_processing_agent.go`)

```go
import (
    "context"
    "log"
    "os"

    "google.golang.org/genai"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/cmd/launcher"
    "google.golang.org/adk/cmd/launcher/full"
    "google.golang.org/adk/model/gemini"
)

func main() {
    ctx := context.Background()

    model, err := gemini.NewModel(ctx, "gemini-2.5-flash", &genai.ClientConfig{
        APIKey: os.Getenv("GOOGLE_API_KEY"),
    })
    if err != nil {
        log.Fatalf("Failed to create model: %v", err)
    }

    a, err := llmagent.New(llmagent.Config{
        Name:        "event_processor",
        Model:       model,
        Description: "Agent to process the events from Pub/Sub and Eventarc triggers.",
        Instruction: `
        You are an event-processing agent that handles incoming
        events from Pub/Sub and Eventarc triggers.

        When you receive an event:
        1. Analyze the event contents and determine what action to take.
        2. Summarize what you found and what action you would recommend.

        Be concise and structured in your responses.`,
    })
    if err != nil {
        log.Fatalf("Failed to create agent: %v", err)
    }

    config := &launcher.Config{
        AgentLoader: agent.NewSingleLoader(a),
    }

    l := full.NewLauncher()
    if err = l.Execute(ctx, config, os.Args[1:]); err != nil {
        log.Fatalf("Run failed: %v\n\n%s", err, l.CommandLineSyntax())
    }
}
```

### Enable triggers

Trigger endpoints are disabled by default. Enable them with the `--trigger_sources` flag:

```shell
adk api_server --trigger_sources "pubsub,eventarc" path/to/your/agent
```

For production deployments, you can enable triggers programmatically in a custom FastAPI entry point:

Deployment entry point (`main.py`)

```python
import os

import uvicorn
from google.adk.cli.fast_api import get_fast_api_app

AGENT_DIR = os.path.dirname(os.path.abspath(__file__))

app = get_fast_api_app(
    agents_dir=AGENT_DIR,
    web=False,
    trigger_sources=["pubsub", "eventarc"],
)

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8000)))
```

Trigger endpoints are disabled by default. Enable them with the corresponding trigger flag:

```shell
go run agent.go web api pubsub eventarc
```

### Try it locally

**1. Start the server with triggers enabled:**

```bash
adk api_server --trigger_sources "pubsub" event_processing_agent
```

```bash
go run event_processing_agent.go web api pubsub
```

**2. Send a test event:**

```bash
curl -X POST http://localhost:8000/apps/event_processing_agent/trigger/pubsub \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "data": "eyJvcmRlcl9pZCI6ICIxMjM0IiwgInN0YXR1cyI6ICJuZXcifQ==",
      "attributes": {"source": "orders-service"}
    },
    "subscription": "projects/my-project/subscriptions/orders-sub"
  }'
```

The Base64 value decodes to `{"order_id": "1234", "status": "new"}`.

A successful response:

```json
{"status": "success"}
```

## Trigger sources

### Parameter mapping

The `/run` endpoint requires you to provide `app_name`, `user_id`, and `session_id`. Trigger endpoints derive these automatically:

| Parameter    | Source                                                                           |
| ------------ | -------------------------------------------------------------------------------- |
| `app_name`   | Extracted from the URL path (`/apps/{app_name}/trigger/...`)                     |
| `session_id` | Auto-generated UUID per event                                                    |
| `user_id`    | Pub/Sub: the `subscription` field. Eventarc: the `source` or `ce-source` header. |

### Message format

All trigger endpoints normalize the incoming event into a consistent JSON structure before passing it to your agent as the user message:

```json
{
  "data": "<decoded event payload>",
  "attributes": {"key": "value"}
}
```

- **`data`**: The decoded event payload. If the original data is JSON, it is parsed into a structured object. Otherwise, it is passed as a plain string.
- **`attributes`**: Key-value metadata from the event source (for example, Pub/Sub message attributes or CloudEvents headers like `ce-type`, `ce-source`).

Your agent receives this JSON string as the input message and can parse it to extract the data and attributes.

### Pub/Sub

The Pub/Sub trigger endpoint processes messages from a [Pub/Sub push subscription](https://cloud.google.com/pubsub/docs/push). Use it when your applications or services publish messages to a topic, for example:

- A support portal publishes incoming tickets for triage and routing.
- A content pipeline sends documents for classification or moderation.
- A monitoring service publishes alerts for automated analysis.

#### Request format

Pub/Sub push subscriptions send requests in this format:

```json
{
  "message": {
    "data": "eyJvcmRlcl9pZCI6ICIxMjM0IiwgInN0YXR1cyI6ICJuZXcifQ==",
    "attributes": {"source": "orders-service"},
    "messageId": "123456789",
    "publishTime": "2026-04-08T12:00:00Z"
  },
  "subscription": "projects/my-project/subscriptions/my-sub"
}
```

The `data` field is Base64-encoded. The trigger endpoint decodes it automatically.

#### Response

| HTTP Status | Meaning                                                                                                                                                                                                                                                                                                     |
| ----------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **200**     | Event processed successfully. Pub/Sub acknowledges the message.                                                                                                                                                                                                                                             |
| **400**     | Invalid request (malformed Base64 encoding). Message is not retried.                                                                                                                                                                                                                                        |
| **500**     | Processing failed (transient or non-transient agent errors). Pub/Sub retries delivery based on its [retry policy](https://cloud.google.com/pubsub/docs/handling-failures). Configure a [dead-letter queue](https://cloud.google.com/pubsub/docs/dead-letter-topics) to catch messages that fail repeatedly. |

### Eventarc

The Eventarc trigger endpoint processes [CloudEvents](https://cloud.google.com/eventarc/docs/cloudevents) delivered by [Eventarc](https://cloud.google.com/eventarc), both [Standard](https://cloud.google.com/eventarc/standard/docs/overview) and [Advanced](https://cloud.google.com/eventarc/advanced/docs/overview) editions. Use it to react to events across Google Cloud, for example:

- A file is uploaded to [Cloud Storage](https://cloud.google.com/storage) (classify, summarize, or extract data from documents).
- A record is written to [BigQuery](https://cloud.google.com/bigquery) (run anomaly detection or generate alerts).
- An [Audit Log](https://cloud.google.com/logging/docs/audit) entry is created (flag policy violations or suspicious activity).

Both content modes are supported:

- **Binary content mode** (Eventarc default): CloudEvents attributes are sent as `ce-*` HTTP headers, and the body contains the event data (typically a Pub/Sub message wrapper).
- **Structured content mode**: All CloudEvents attributes and data are in the JSON body.

Test with curl (structured mode)

```bash
curl -X POST http://localhost:8000/apps/my_agent/trigger/eventarc \
  -H "Content-Type: application/json" \
  -d '{
    "specversion": "1.0",
    "type": "google.cloud.storage.object.v1.finalized",
    "source": "//storage.googleapis.com/projects/my-project",
    "id": "event-123",
    "data": {
      "bucket": "my-bucket",
      "name": "uploads/document.pdf"
    }
  }'
```

Test with curl (binary mode)

```bash
curl -X POST http://localhost:8000/apps/my_agent/trigger/eventarc \
  -H "Content-Type: application/json" \
  -H "ce-type: google.cloud.storage.object.v1.finalized" \
  -H "ce-source: //storage.googleapis.com/projects/my-project" \
  -H "ce-id: event-456" \
  -H "ce-specversion: 1.0" \
  -d '{
    "message": {
      "data": "eyJidWNrZXQiOiAibXktYnVja2V0IiwgIm5hbWUiOiAiZG9jLnBkZiJ9",
      "attributes": {"eventType": "OBJECT_FINALIZE"}
    },
    "subscription": "projects/my-project/subscriptions/eventarc-sub"
  }'
```

#### Response

| HTTP Status | Meaning                                                                 |
| ----------- | ----------------------------------------------------------------------- |
| **200**     | Event processed successfully. Eventarc acknowledges delivery.           |
| **500**     | Processing failed. Eventarc retries delivery based on its retry policy. |

## Configuration

### Concurrency control

Trigger endpoints use a semaphore to limit the number of concurrent agent invocations. This prevents your agent from exceeding your LLM model quota during bursts of events.

| Setting                    | Default | Environment Variable         |
| -------------------------- | ------- | ---------------------------- |
| Max concurrent invocations | 10      | `ADK_TRIGGER_MAX_CONCURRENT` |

| Setting                    | Default | Flag                            |
| -------------------------- | ------- | ------------------------------- |
| Max concurrent invocations | 10      | `--trigger_max_concurrent_runs` |

When the concurrency limit is reached, incoming requests are queued and processed as slots become available. Concurrency control is per process. If you deploy multiple Cloud Run instances, each instance maintains its own independent semaphore.

```bash
# Allow up to 5 concurrent agent invocations
export ADK_TRIGGER_MAX_CONCURRENT=5
```

```bash
go run event_processing_agent.go web api pubsub --trigger_max_concurrent_runs=5
```

### Automatic retry with backoff

Trigger endpoints include built-in retry logic for transient errors such as `429 RESOURCE_EXHAUSTED` responses. When a transient error is detected, the request is retried with exponential backoff and jitter.

| Setting            | Default | Environment Variable           |
| ------------------ | ------- | ------------------------------ |
| Max retry attempts | 3       | `ADK_TRIGGER_MAX_RETRIES`      |
| Base backoff delay | 1.0s    | `ADK_TRIGGER_RETRY_BASE_DELAY` |
| Max backoff delay  | 30.0s   | `ADK_TRIGGER_RETRY_MAX_DELAY`  |

| Setting            | Default | Flag                    |
| ------------------ | ------- | ----------------------- |
| Max retry attempts | 3       | `--trigger_max_retries` |
| Base backoff delay | 1.0s    | `--trigger_base_delay`  |
| Max backoff delay  | 30.0s   | `--trigger_max_delay`   |

If all retries are exhausted, the endpoint returns HTTP 500, signaling Pub/Sub or Eventarc to retry delivery at a higher level. Non-transient errors fail immediately without retries.

### Error handling and disaster recovery

Disaster recovery for trigger-based workloads is handled by the triggering service, not by ADK:

- If your agent crashes or returns an error, Pub/Sub or Eventarc does not receive an acknowledgement and automatically redelivers the message.
- After maximum retries are exhausted, unprocessed messages move to a [dead-letter queue (DLQ)](https://cloud.google.com/pubsub/docs/dead-letter-topics) if configured.
- Each redelivery creates a new session. Trigger workloads are stateless by design.

### Timeout considerations

All trigger endpoints process synchronously and wait for your agent to complete before returning a response. This is by design: keeping the HTTP request alive ensures that the hosting infrastructure does not terminate the process while your agent is still working. The synchronous response code (200 or 500) is what allows Pub/Sub and Eventarc to correctly acknowledge success or trigger a retry.

The maximum processing time is governed by the upstream service:

| Service      | Max Timeout                                                                                                                                                                                             |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Pub/Sub push | 10 minutes (ack deadline)                                                                                                                                                                               |
| Eventarc     | 10 minutes ([Standard](https://cloud.google.com/eventarc/standard/docs/overview) uses Pub/Sub as transport; [Advanced](https://cloud.google.com/eventarc/advanced/docs/overview) delivers via pipeline) |

Trigger endpoints are designed for agents that complete within 10 minutes. This is suitable for processing individual events, running validations, classifying documents, and writing results to downstream services.

Long-running agents

Trigger endpoints are not suitable for agents that take more than 10 minutes to complete. For long-running workloads, use [Pub/Sub pull subscriptions](https://cloud.google.com/pubsub/docs/pull), [Cloud Run Jobs](https://cloud.google.com/run/docs/create-jobs), or a worker pool architecture instead.

### Session lifecycle

Sessions follow the same pattern as all other ADK entry points. They are created through your configured [`SessionService`](https://adk.dev/sessions/session/index.md). By default, ADK uses `InMemorySessionService`, which makes trigger sessions ephemeral: created per event and discarded after processing.

If you configure a persistent `SessionService` (for example, `DatabaseSessionService`), trigger sessions are stored automatically. This can be useful for auditing, debugging, and post-mortem analysis of event-driven workloads.

## Deploy

The examples below use [Cloud Run](https://cloud.google.com/run) as the deployment target. Cloud Run is currently the recommended platform for deploying ambient agents with trigger endpoints.

Authentication and security

Trigger endpoints are standard HTTP routes within the ADK web server. Authentication and security are enforced at the deployment level, the same as any other ADK endpoint. When deployed with authentication enabled (recommended), all endpoints require valid credentials. GCP services authenticate using [service account](https://cloud.google.com/iam/docs/service-accounts) identities. See each service's documentation for details.

Deploy your agent to Cloud Run with triggers enabled using the `--trigger_sources` flag:

```bash
adk deploy cloud_run \
  --project=$GOOGLE_CLOUD_PROJECT \
  --region=$GOOGLE_CLOUD_LOCATION \
  --trigger_sources="pubsub,eventarc" \
  path/to/your/agent
```

Deploy your agent to Cloud Run with triggers enabled using the corresponding trigger flag (all the settings are prefixed with trigger type)

```bash
adk deploy cloud_run \
  --project=$GOOGLE_CLOUD_PROJECT \
  --region=$GOOGLE_CLOUD_LOCATION \
  --pubsub \
  --pubsub_max_concurrent_runs=5 \
  --eventarc \
  --eventarc_max_concurrent_runs=5
```

After deployment, connect the appropriate GCP infrastructure to your agent's trigger endpoint:

- **Pub/Sub**: Create a [push subscription](https://cloud.google.com/pubsub/docs/push) pointing to `/apps/{app_name}/trigger/pubsub`.
- **Eventarc**: Create an [Eventarc Standard trigger](https://docs.cloud.google.com/eventarc/standard/docs/event-providers-targets) or an [Eventarc Advanced pipeline](https://cloud.google.com/eventarc/advanced/docs/overview) routing to `/apps/{app_name}/trigger/eventarc`.
- **Cloud Scheduler**: Create a [scheduler job](https://cloud.google.com/scheduler/docs/creating) that publishes to your Pub/Sub topic on a cron schedule.

See [Deploy to Cloud Run](https://adk.dev/deploy/cloud-run/index.md) for full deployment instructions.

## What's next?

- Learn how to [deploy your agent to Cloud Run](https://adk.dev/deploy/cloud-run/index.md)
- Explore [API server endpoints](https://adk.dev/runtime/api-server/index.md) for interactive agent invocations
- Use the [Pub/Sub toolset](https://adk.dev/integrations/pubsub/index.md) to give your agent the ability to publish and pull messages

# Use the API Server

Supported in ADKPython v0.1.0TypeScript v0.2.0Go v0.1.0Java v0.1.0

Before you deploy your agent, you should test it to ensure that it is working as intended. Use the API server in ADK to expose your agents through a REST API for programmatic testing and integration.

## Start the API server

Use the following command to run your agent in an ADK API server:

```shell
adk api_server
```

```shell
npx adk api_server
```

```shell
go run agent.go web api
```

Make sure to update the port number.

With Maven, compile and run the ADK web server:

```console
mvn compile exec:java \
 -Dexec.args="--adk.agents.source-dir=src/main/java/agents --server.port=8080"
```

With Gradle, the `build.gradle` or `build.gradle.kts` build file should have the following Java plugin in its plugins section:

```groovy
plugins {
    id('java')
    // other plugins
}
```

Then, elsewhere in the build file, at the top-level, create a new task:

```groovy
tasks.register('runADKWebServer', JavaExec) {
    dependsOn classes
    classpath = sourceSets.main.runtimeClasspath
    mainClass = 'com.google.adk.web.AdkWebServer'
    args '--adk.agents.source-dir=src/main/java/agents', '--server.port=8080'
}
```

Finally, on the command-line, run the following command:

```console
gradle runADKWebServer
```

In Java, both the Dev UI and the API server are bundled together.

This command will launch a local web server, where you can run cURL commands or send API requests to test your agent. By default, the server runs on `http://localhost:8000`.

Advanced Usage and Debugging

For a complete reference on all available endpoints, request/response formats, and tips for debugging (including how to use the interactive API documentation), see the **ADK API Server Guide** below.

## Test locally

Testing locally involves launching a local web server, creating a session, and sending queries to your agent. First, ensure you are in the correct working directory.

For TypeScript, you should be inside the agent project directory itself.

```console
parent_folder/
└── my_sample_agent/  <-- For TypeScript, run commands from here
    └── agent.py (or Agent.java or agent.ts)
```

**Launch the Local Server**

Next, launch the local server using the commands listed above.

The output should appear similar to:

```shell
INFO:     Started server process [12345]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://localhost:8000 (Press CTRL+C to quit)
```

```shell
+-----------------------------------------------------------------------------+
| ADK Web Server started                                                      |
|                                                                             |
| For local testing, access at http://localhost:8000.                         |
+-----------------------------------------------------------------------------+
```

```shell
2025-05-13T23:32:08.972-06:00  INFO 37864 --- [ebServer.main()] o.s.b.w.embedded.tomcat.TomcatWebServer  : Tomcat started on port 8080 (http) with context path '/'
2025-05-13T23:32:08.980-06:00  INFO 37864 --- [ebServer.main()] com.google.adk.web.AdkWebServer          : Started AdkWebServer in 1.15 seconds (process running for 2.877)
2025-05-13T23:32:08.981-06:00  INFO 37864 --- [ebServer.main()] com.google.adk.web.AdkWebServer          : AdkWebServer application started successfully.
```

Your server is now running locally. Ensure you use the correct ***port number*** in all the subsequent commands.

**Create a new session**

With the API server still running, open a new terminal window or tab and create a new session with the agent using:

```shell
curl -X POST http://localhost:8000/apps/my_sample_agent/users/u_123/sessions/s_123 \
  -H "Content-Type: application/json" \
  -d '{"key1": "value1", "key2": 42}'
```

Let's break down what's happening:

- `http://localhost:8000/apps/my_sample_agent/users/u_123/sessions/s_123`: This creates a new session for your agent `my_sample_agent`, which is the name of the agent folder, for a user ID (`u_123`) and for a session ID (`s_123`). You can replace `my_sample_agent` with the name of your agent folder. You can replace `u_123` with a specific user ID, and `s_123` with a specific session ID.
- `{"key1": "value1", "key2": 42}`: This is optional. You can use this to customize the agent's pre-existing state (dict) when creating the session.

This should return the session information if it was created successfully. The output should appear similar to:

```json
{"id":"s_123","appName":"my_sample_agent","userId":"u_123","state":{"key1":"value1","key2":42},"events":[],"lastUpdateTime":1743711430.022186}
```

Info

You cannot create multiple sessions with exactly the same user ID and session ID. If you try to, you may see a response, like: `{"detail":"Session already exists: s_123"}`. To fix this, you can either delete that session (e.g., `s_123`), or choose a different session ID.

**Send a query**

There are two ways to send queries via POST to your agent, via the `/run` or `/run_sse` routes.

- `POST http://localhost:8000/run`: collects all events as a list and returns the list all at once. Suitable for most users (if you are unsure, we recommend using this one).
- `POST http://localhost:8000/run_sse`: returns as Server-Sent-Events, which is a stream of event objects. Suitable for those who want to be notified as soon as the event is available. With `/run_sse`, you can also set `streaming` to `true` to enable token-level streaming.

**Using `/run`**

```shell
curl -X POST http://localhost:8000/run \
-H "Content-Type: application/json" \
-d '{
"appName": "my_sample_agent",
"userId": "u_123",
"sessionId": "s_123",
"newMessage": {
    "role": "user",
    "parts": [{
    "text": "Hey whats the weather in new york today"
    }]
}
}'
```

In TypeScript, currently only `camelCase` field names are supported (e.g. `appName`, `userId`, `sessionId`, etc.).

If using `/run`, you will see the full output of events at the same time, as a list, which should appear similar to:

```json
[{"content":{"parts":[{"functionCall":{"id":"af-e75e946d-c02a-4aad-931e-49e4ab859838","args":{"city":"new york"},"name":"get_weather"}}],"role":"model"},"invocationId":"e-71353f1e-aea1-4821-aa4b-46874a766853","author":"weather_time_agent","actions":{"stateDelta":{},"artifactDelta":{},"requestedAuthConfigs":{}},"longRunningToolIds":[],"id":"2Btee6zW","timestamp":1743712220.385936},{"content":{"parts":[{"functionResponse":{"id":"af-e75e946d-c02a-4aad-931e-49e4ab859838","name":"get_weather","response":{"status":"success","report":"The weather in New York is sunny with a temperature of 25 degrees Celsius (41 degrees Fahrenheit)."}}}],"role":"user"},"invocationId":"e-71353f1e-aea1-4821-aa4b-46874a766853","author":"weather_time_agent","actions":{"stateDelta":{},"artifactDelta":{},"requestedAuthConfigs":{}},"id":"PmWibL2m","timestamp":1743712221.895042},{"content":{"parts":[{"text":"OK. The weather in New York is sunny with a temperature of 25 degrees Celsius (41 degrees Fahrenheit).\n"}],"role":"model"},"invocationId":"e-71353f1e-aea1-4821-aa4b-46874a766853","author":"weather_time_agent","actions":{"stateDelta":{},"artifactDelta":{},"requestedAuthConfigs":{}},"id":"sYT42eVC","timestamp":1743712221.899018}]
```

**Using `/run_sse`**

```shell
curl -X POST http://localhost:8000/run_sse \
-H "Content-Type: application/json" \
-d '{
"appName": "my_sample_agent",
"userId": "u_123",
"sessionId": "s_123",
"newMessage": {
    "role": "user",
    "parts": [{
    "text": "Hey whats the weather in new york today"
    }]
},
"streaming": false
}'
```

You can set `streaming` to `true` to enable token-level streaming, which means the response will be returned to you in multiple chunks and the output should appear similar to:

```shell
data: {"content":{"parts":[{"functionCall":{"id":"af-f83f8af9-f732-46b6-8cb5-7b5b73bbf13d","args":{"city":"new york"},"name":"get_weather"}}],"role":"model"},"invocationId":"e-3f6d7765-5287-419e-9991-5fffa1a75565","author":"weather_time_agent","actions":{"stateDelta":{},"artifactDelta":{},"requestedAuthConfigs":{}},"longRunningToolIds":[],"id":"ptcjaZBa","timestamp":1743712255.313043}

data: {"content":{"parts":[{"functionResponse":{"id":"af-f83f8af9-f732-46b6-8cb5-7b5b73bbf13d","name":"get_weather","response":{"status":"success","report":"The weather in New York is sunny with a temperature of 25 degrees Celsius (41 degrees Fahrenheit)."}}}],"role":"user"},"invocationId":"e-3f6d7765-5287-419e-9991-5fffa1a75565","author":"weather_time_agent","actions":{"stateDelta":{},"artifactDelta":{},"requestedAuthConfigs":{}},"id":"5aocxjaq","timestamp":1743712257.387306}

data: {"content":{"parts":[{"text":"OK. The weather in New York is sunny with a temperature of 25 degrees Celsius (41 degrees Fahrenheit).\n"}],"role":"model"},"invocationId":"e-3f6d7765-5287-419e-9991-5fffa1a75565","author":"weather_time_agent","actions":{"stateDelta":{},"artifactDelta":{},"requestedAuthConfigs":{}},"id":"rAnWGSiV","timestamp":1743712257.391317}
```

**Send a query with a base64 encoded file using `/run` or `/run_sse`**

```shell
curl -X POST http://localhost:8000/run \
-H 'Content-Type: application/json' \
-d '{
   "appName":"my_sample_agent",
   "userId":"u_123",
   "sessionId":"s_123",
   "newMessage":{
      "role":"user",
      "parts":[
         {
            "text":"Describe this image"
         },
         {
            "inlineData":{
               "displayName":"my_image.png",
               "data":"iVBORw0KGgoAAAANSUhEUgAAAgAAAAIACAYAAAD0eNT6AAAACXBIWXMAAAsTAAALEwEAmpw...",
               "mimeType":"image/png"
            }
         }
      ]
   },
   "streaming":false
}'
```

Info

If you are using `/run_sse`, you should see each event as soon as it becomes available.

## Integrations

ADK uses [Callbacks](https://adk.dev/callbacks/index.md) to integrate with third-party observability tools. These integrations capture detailed traces of agent calls and interactions, which are crucial for understanding behavior, debugging issues, and evaluating performance.

- [Comet Opik](https://github.com/comet-ml/opik) is an open-source LLM observability and evaluation platform that [natively supports ADK](https://www.comet.com/docs/opik/tracing/integrations/adk).

## Deploy your agent

Now that you've verified the local operation of your agent, you're ready to move on to deploying your agent! Here are some ways you can deploy your agent:

- Deploy to [Agent Runtime](https://adk.dev/deploy/agent-runtime/index.md), a simple way to deploy your ADK agents to a managed service on Agent Platform on Google Cloud.
- Deploy to [Cloud Run](https://adk.dev/deploy/cloud-run/index.md) and have full control over how you scale and manage your agents using serverless architecture on Google Cloud.

## Interactive API docs

The API server automatically generates interactive API documentation using Swagger UI. This is an invaluable tool for exploring endpoints, understanding request formats, and testing your agent directly from your browser.

To access the interactive docs, start the API server and navigate to <http://localhost:8000/docs> in your web browser.

You will see a complete, interactive list of all available API endpoints, which you can expand to see detailed information about parameters, request bodies, and response schemas. You can even click "Try it out" to send live requests to your running agents.

## API endpoints

The following sections detail the primary endpoints for interacting with your agents.

JSON Naming Convention

- **Both Request and Response bodies** will use `camelCase` for field names (e.g., `"appName"`).

### Utility endpoints

#### List available agents

Returns a list of all agent applications discovered by the server.

- **Method:** `GET`
- **Path:** `/list-apps`

**Example Request**

```shell
curl -X GET http://localhost:8000/list-apps
```

**Example Response**

```json
["my_sample_agent", "another_agent"]
```

______________________________________________________________________

### Session management

Sessions store the state and event history for a specific user's interaction with an agent.

#### Update a session

Updates an existing session.

- **Method:** `PATCH`
- **Path:** `/apps/{app_name}/users/{user_id}/sessions/{session_id}`

**Request Body**

```json
{
  "stateDelta": {
    "key1": "value1",
    "key2": 42
  }
}
```

**Example Request**

```shell
curl -X PATCH http://localhost:8000/apps/my_sample_agent/users/u_123/sessions/s_abc \
  -H "Content-Type: application/json" \
  -d '{"stateDelta":{"visit_count": 5}}'
```

**Example Response**

```json
{"id":"s_abc","appName":"my_sample_agent","userId":"u_123","state":{"visit_count":5},"events":[],"lastUpdateTime":1743711430.022186}
```

#### Get a session

Retrieves the details of a specific session, including its current state and all associated events.

- **Method:** `GET`
- **Path:** `/apps/{app_name}/users/{user_id}/sessions/{session_id}`

**Example Request**

```shell
curl -X GET http://localhost:8000/apps/my_sample_agent/users/u_123/sessions/s_abc
```

**Example Response**

```json
{"id":"s_abc","appName":"my_sample_agent","userId":"u_123","state":{"visit_count":5},"events":[...],"lastUpdateTime":1743711430.022186}
```

#### Delete a session

Deletes a session and all of its associated data.

- **Method:** `DELETE`
- **Path:** `/apps/{app_name}/users/{user_id}/sessions/{session_id}`

**Example Request**

```shell
curl -X DELETE http://localhost:8000/apps/my_sample_agent/users/u_123/sessions/s_abc
```

**Example Response** A successful deletion returns an empty response with a `204 No Content` status code.

______________________________________________________________________

### Agent execution

These endpoints are used to send a new message to an agent and get a response.

#### Run agent (single response)

Executes the agent and returns all generated events in a single JSON array after the run is complete.

- **Method:** `POST`
- **Path:** `/run`

**Request Body**

```json
{
  "appName": "my_sample_agent",
  "userId": "u_123",
  "sessionId": "s_abc",
  "newMessage": {
    "role": "user",
    "parts": [
      { "text": "What is the capital of France?" }
    ]
  }
}
```

In TypeScript, currently only `camelCase` field names are supported (e.g. `appName`, `userId`, `sessionId`, etc.).

**Example Request**

```shell
curl -X POST http://localhost:8000/run \
  -H "Content-Type: application/json" \
  -d '{
    "appName": "my_sample_agent",
    "userId": "u_123",
    "sessionId": "s_abc",
    "newMessage": {
      "role": "user",
      "parts": [{"text": "What is the capital of France?"}]
    }
  }'
```

#### Run agent (streaming)

Executes the agent and streams events back to the client as they are generated using [Server-Sent Events (SSE)](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events).

- **Method:** `POST`
- **Path:** `/run_sse`

**Request Body** The request body is the same as for `/run`, with an additional optional `streaming` flag.

```json
{
  "appName": "my_sample_agent",
  "userId": "u_123",
  "sessionId": "s_abc",
  "newMessage": {
    "role": "user",
    "parts": [
      { "text": "What is the weather in New York?" }
    ]
  },
  "streaming": true
}
```

- `streaming`: (Optional) Set to `true` to enable token-level streaming for model responses. Defaults to `false`.

**Example Request**

```shell
curl -X POST http://localhost:8000/run_sse \
  -H "Content-Type: application/json" \
  -d '{
    "appName": "my_sample_agent",
    "userId": "u_123",
    "sessionId": "s_abc",
    "newMessage": {
      "role": "user",
      "parts": [{"text": "What is the weather in New York?"}]
    },
    "streaming": false
  }'
```

# Cancel agent runs

Supported in ADKTypeScript v1.0.0

When an agent run takes too long, encounters changing conditions, or is no longer needed, you may want to cancel it without losing the work already completed. Cancellation in ADK is non-destructive: events already committed to the session remain persisted.

ADK supports graceful cancellation using `AbortController` and `AbortSignal`. Pass an `AbortSignal` to `runner.runAsync()` to cancel the entire invocation at any point in the execution stack, including agent execution, LLM generation, tool execution, and plugin callbacks.

## Get started

Create an `AbortController`, pass its `signal` to `runner.runAsync()`, and call `controller.abort()` when you want to cancel execution:

```typescript
import { Runner, InMemorySessionService, LlmAgent, FunctionTool } from '@google/adk';
import { z } from 'zod';

const getInfo = new FunctionTool({
  name: 'get_info',
  description: 'Gets information about a topic.',
  parameters: z.object({ topic: z.string() }),
  execute: (args) => ({ result: `Info about ${args.topic}` }),
});

const agent = new LlmAgent({
  name: 'my_agent',
  model: 'gemini-flash-latest',
  instruction: 'Always use the get_info tool before answering.',
  tools: [getInfo],
});

const sessionService = new InMemorySessionService();
const runner = new Runner({ agent, appName: 'my_app', sessionService });
const session = await sessionService.createSession({ appName: 'my_app', userId: 'user_1' });

const controller = new AbortController();
const run = runner.runAsync({
  userId: session.userId,
  sessionId: session.id,
  newMessage: { role: 'user', parts: [{ text: 'Tell me about quantum computing.' }] },
  abortSignal: controller.signal,
});

let count = 0;
for await (const event of run) {
  count++;
  console.log('Event:', event.author);
  controller.abort(); // Without this, 3+ events; with it, only 1.
}
console.log(`Done. Received ${count} event(s).`);
```

## How cancellation propagates

When you abort the signal, cancellation propagates down through the entire execution stack. Each component checks `abortSignal.aborted` at critical lifecycle points and terminates early when it detects cancellation:

| Component           | What happens on abort                                                                                                    |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **Runner**          | Stops before session fetch, after plugin callbacks, and within the event streaming loop.                                 |
| **LlmAgent**        | Stops between execution steps, before/after model callbacks, and within response streaming.                              |
| **LoopAgent**       | Stops between loop iterations and between sub-agent executions.                                                          |
| **ParallelAgent**   | Stops when merging results from concurrent sub-agent runs.                                                               |
| **Models (Gemini)** | The signal is passed to the underlying Google GenAI SDK via `config.abortSignal`, cancelling the in-flight HTTP request. |
| **AgentTool**       | Passes the signal to the sub-agent runner and checks for abort after session creation.                                   |
| **MCPTool**         | Passes the signal to the MCP client's `callTool` method.                                                                 |

The `InvocationContext` also registers a listener on the signal that automatically sets `endInvocation = true` when triggered, signaling all components to wind down.

### Behavior on cancellation

When an `AbortSignal` is triggered, the following applies:

- **Graceful termination:** The async generator returned by `runner.runAsync()` completes (stops yielding events) without throwing an error.
- **Committed events persist:** Any events that were already yielded and processed by the Runner before the abort remain committed to the session history.
- **No partial events:** Events that were in progress but not yet yielded are discarded.
- **Resource cleanup:** In-flight LLM requests to the Gemini API are cancelled through the SDK's native `AbortSignal` support, freeing network resources.

## Advanced examples

The following examples show additional cancellation patterns beyond the basic `AbortController` usage.

### Cancellation with a timeout

Use `AbortSignal.timeout()` to automatically cancel an agent run after a specified duration. This is useful for enforcing time limits on agent execution.

Using the same agent and runner setup from the get started example, replace everything from `const controller` onwards with:

```typescript
const run = runner.runAsync({
  userId: session.userId,
  sessionId: session.id,
  newMessage: { role: 'user', parts: [{ text: 'Tell me about quantum computing.' }] },
  abortSignal: AbortSignal.timeout(2_000), // Cancel after 2 seconds
});

let count = 0;
for await (const event of run) {
  count++;
  console.log('Event:', event.author);
}
console.log(`Done. Received ${count} event(s).`);
```

You can also combine a timeout with programmatic cancellation using `AbortSignal.any()`. Using the same setup, replace everything from `const controller` onwards with:

```typescript
const controller = new AbortController();

// Cancel on timeout OR programmatically via controller.abort()
// e.g.: cancelButton.addEventListener('click', () => controller.abort());
const combinedSignal = AbortSignal.any([
  controller.signal,
  AbortSignal.timeout(60_000),
]);

const run = runner.runAsync({
  userId: session.userId,
  sessionId: session.id,
  newMessage: { role: 'user', parts: [{ text: 'Tell me about quantum computing.' }] },
  abortSignal: combinedSignal,
});
```

### AbortSignal in custom tools

When you pass an `AbortSignal` to `runner.runAsync()`, it is available on `toolContext.abortSignal` inside your custom tools. The following example shows the pattern for checking the abort signal inside a custom tool:

```typescript
import { FunctionTool } from '@google/adk';
import { z } from 'zod';

const fetchItems = async (id: string) => ['item1', 'item2', 'item3'];
const processItem = async (item: string) => ({ processed: item });

const longRunningTool = new FunctionTool({
  name: 'process_data',
  description: 'Processes data in multiple steps.',
  parameters: z.object({
    dataId: z.string(),
  }),
  execute: async (args, toolContext) => {
    const items = await fetchItems(args.dataId);

    const results = [];
    for (const item of items) {
      // Check the abort signal before each step
      if (toolContext?.abortSignal?.aborted) {
        return { status: 'cancelled', processed: results.length };
      }

      results.push(await processItem(item));
    }

    return { status: 'complete', processed: results.length };
  },
});
```

# Use the Command Line

Supported in ADKPython v0.1.0TypeScript v0.2.0Go v0.1.0Java v0.1.0

ADK provides an interactive terminal interface for testing your agents. This is useful for quick testing, scripted interactions, and CI/CD pipelines.

## Run an agent

Use the following command to run your agent in the ADK command line interface:

```shell
adk run my_agent
```

```shell
npx @google/adk-devtools run agent.ts
```

```shell
go run agent.go
```

Create an `AgentCliRunner` class (see [Java Quickstart](https://adk.dev/get-started/java/index.md)) and run:

```shell
mvn compile exec:java -Dexec.mainClass="com.example.agent.AgentCliRunner"
```

This starts an interactive session where you can type queries and see agent responses directly in your terminal:

```shell
Running agent my_agent, type exit to exit.
[user]: What's the weather in New York?
[my_agent]: The weather in New York is sunny with a temperature of 25°C.
[user]: exit
```

## Session options

The `adk run` command includes options for saving, resuming, and replaying sessions.

### Save sessions

To save the session when you exit:

```shell
adk run --save_session path/to/my_agent
```

You'll be prompted to enter a session ID, and the session will be saved to `path/to/my_agent/<session_id>.session.json`.

You can also specify the session ID upfront:

```shell
adk run --save_session --session_id my_session path/to/my_agent
```

### Resume sessions

To continue a previously saved session:

```shell
adk run --resume path/to/my_agent/my_session.session.json path/to/my_agent
```

This loads the previous session state and event history, displays it, and allows you to continue the conversation.

### Replay sessions

To replay a session file without interactive input:

```shell
adk run --replay path/to/input.json path/to/my_agent
```

The input file should contain initial state and queries:

```json
{
  "state": {"key": "value"},
  "queries": ["What is 2 + 2?", "What is the capital of France?"]
}
```

## Storage options

| Option                   | Description                 | Default                        |
| ------------------------ | --------------------------- | ------------------------------ |
| `--session_service_uri`  | Custom session storage URI  | SQLite under `.adk/session.db` |
| `--artifact_service_uri` | Custom artifact storage URI | Local `.adk/artifacts`         |

### Example with storage options

```shell
adk run --session_service_uri "sqlite:///my_sessions.db" path/to/my_agent
```

## All options

| Option                   | Description                                      |
| ------------------------ | ------------------------------------------------ |
| `--save_session`         | Save the session to a JSON file on exit          |
| `--session_id`           | Session ID to use when saving                    |
| `--resume`               | Path to a saved session file to resume           |
| `--replay`               | Path to an input file for non-interactive replay |
| `--session_service_uri`  | Custom session storage URI                       |
| `--artifact_service_uri` | Custom artifact storage URI                      |

# Runtime Event Loop

Supported in ADKPython v0.1.0Typescript v0.2.0Go v0.1.0Java v0.1.0

The ADK Runtime is the underlying engine that powers your agent application during user interactions. It's the system that takes your defined agents, tools, and callbacks and orchestrates their execution in response to user input, managing the flow of information, state changes, and interactions with external services like LLMs or storage.

Think of the Runtime as the **"engine"** of your agentic application. You define the parts (agents, tools), and the Runtime handles how they connect and run together to fulfill a user's request.

## Core Idea: The Event Loop

At its heart, the ADK Runtime operates on an **Event Loop**. This loop facilitates a back-and-forth communication between the `Runner` component and your defined "Execution Logic" (which includes your Agents, the LLM calls they make, Callbacks, and Tools).

In simple terms:

1. The `Runner` receives a user query and asks the main `Agent` to start processing.
1. The `Agent` (and its associated logic) runs until it has something to report (like a response, a request to use a tool, or a state change) – it then **yields** or **emits** an `Event`.
1. The `Runner` receives this `Event`, processes any associated actions (like saving state changes via `Services`), and forwards the event onwards (e.g., to the user interface).
1. The `Agent`'s logic **resumes** from where it paused only *after* the `Runner` has processed the event, and then potentially sees the effects of the changes committed by the Runner.
1. This cycle repeats until the agent has no more events to yield for the current user query.

This event-driven loop is the fundamental pattern governing how ADK executes your agent code.

## The Heartbeat: The Event Loop - Inner workings

The Event Loop is the core operational pattern defining the interaction between the `Runner` and your custom code (Agents, Tools, Callbacks, collectively referred to as "Execution Logic" or "Logic Components" in the design document). It establishes a clear division of responsibilities:

Note

The specific method names and parameter names may vary slightly by SDK language (e.g., `agent.run_async(...)` in Python, `agent.Run(...)` in Go, `agent.runAsync(...)` in Java and TypeScript). Refer to the language-specific API documentation for details.

### Runner's Role (Orchestrator)

The `Runner` acts as the central coordinator for a single user invocation. Its responsibilities in the loop are:

1. **Initiation:** Receives the end user's query (`new_message`) and typically appends it to the session history via the `SessionService`.
1. **Kick-off:** Starts the event generation process by calling the main agent's execution method (e.g., `agent_to_run.run_async(...)`).
1. **Receive & Process:** Waits for the agent logic to `yield` or `emit` an `Event`. Upon receiving an event, the Runner **promptly processes** it. This involves:
   - Using configured `Services` (`SessionService`, `ArtifactService`, `MemoryService`) to commit changes indicated in `event.actions` (like `state_delta`, `artifact_delta`).
   - Performing other internal bookkeeping.
1. **Yield Upstream:** Forwards the processed event onwards (e.g., to the calling application or UI for rendering).
1. **Iterate:** Signals the agent logic that processing is complete for the yielded event, allowing it to resume and generate the *next* event.

*Conceptual Runner Loop:*

```py
# Simplified view of Runner's main loop logic
def run(new_query, ...) -> Generator[Event]:
    # 1. Append new_query to session event history (via SessionService)
    session_service.append_event(session, Event(author='user', content=new_query))

    # 2. Kick off event loop by calling the agent
    agent_event_generator = agent_to_run.run_async(context)

    async for event in agent_event_generator:
        # 3. Process the generated event and commit changes
        session_service.append_event(session, event) # Commits state/artifact deltas etc.
        # memory_service.update_memory(...) # If applicable
        # artifact_service might have already been called via context during agent run

        # 4. Yield event for upstream processing (e.g., UI rendering)
        yield event
        # Runner implicitly signals agent generator can continue after yielding
```

```typescript
// Simplified view of Runner's main loop logic
async * runAsync(newQuery: Content, ...): AsyncGenerator<Event, void, void> {
    // 1. Append newQuery to session event history (via SessionService)
    await sessionService.appendEvent({
        session,
        event: createEvent({author: 'user', content: newQuery})
    });

    // 2. Kick off event loop by calling the agent
    const agentEventGenerator = agentToRun.runAsync(context);

    for await (const event of agentEventGenerator) {
        // 3. Process the generated event and commit changes
        // Commits state/artifact deltas etc.
        await sessionService.appendEvent({session, event});
        // memoryService.updateMemory(...) // If applicable
        // artifactService might have already been called via context during agent run

        // 4. Yield event for upstream processing (e.g., UI rendering)
        yield event;
        // Runner implicitly signals agent generator can continue after yielding
    }
}
```

```go
// Simplified conceptual view of the Runner's main loop logic in Go
func (r *Runner) RunConceptual(ctx context.Context, session *session.Session, newQuery *genai.Content) iter.Seq2[*Event, error] {
    return func(yield func(*Event, error) bool) {
        // 1. Append new_query to session event history (via SessionService)
        // ...
        userEvent := session.NewEvent(ctx.InvocationID()) // Simplified for conceptual view
        userEvent.Author = "user"
        userEvent.LLMResponse = model.LLMResponse{Content: newQuery}

        if _, err := r.sessionService.Append(ctx, &session.AppendRequest{Event: userEvent}); err != nil {
            yield(nil, err)
            return
        }

        // 2. Kick off event stream by calling the agent
        // Assuming agent.Run also returns iter.Seq2[*Event, error]
        agentEventsAndErrs := r.agent.Run(ctx, &agent.RunRequest{Session: session, Input: newQuery})

        for event, err := range agentEventsAndErrs {
            if err != nil {
                if !yield(event, err) { // Yield event even if there's an error, then stop
                    return
                }
                return // Agent finished with an error
            }

            // 3. Process the generated event and commit changes
            // Only commit non-partial event to a session service (as seen in actual code)
            if !event.LLMResponse.Partial {
                if _, err := r.sessionService.Append(ctx, &session.AppendRequest{Event: event}); err != nil {
                    yield(nil, err)
                    return
                }
            }
            // memory_service.update_memory(...) // If applicable
            // artifact_service might have already been called via context during agent run

            // 4. Yield event for upstream processing
            if !yield(event, nil) {
                return // Upstream consumer stopped
            }
        }
        // Agent finished successfully
    }
}
```

```java
// Simplified conceptual view of the Runner's main loop logic in Java.
public Flowable<Event> runConceptual(
    Session session,
    InvocationContext invocationContext,
    Content newQuery
    ) {

    // 1. Append new_query to session event history (via SessionService)
    // ...
    sessionService.appendEvent(session, userEvent).blockingGet();

    // 2. Kick off event stream by calling the agent
    Flowable<Event> agentEventStream = agentToRun.runAsync(invocationContext);

    // 3. Process each generated event, commit changes, and "yield" or "emit"
    return agentEventStream.map(event -> {
        // This mutates the session object (adds event, applies stateDelta).
        // The return value of appendEvent (a Single<Event>) is conceptually
        // just the event itself after processing.
        sessionService.appendEvent(session, event).blockingGet(); // Simplified blocking call

        // memory_service.update_memory(...) // If applicable - conceptual
        // artifact_service might have already been called via context during agent run

        // 4. "Yield" event for upstream processing
        //    In RxJava, returning the event in map effectively yields it to the next operator or subscriber.
        return event;
    });
}
```

### Execution Logic's Role (Agent, Tool, Callback)

Your code within agents, tools, and callbacks is responsible for the actual computation and decision-making. Its interaction with the loop involves:

1. **Execute:** Runs its logic based on the current `InvocationContext`, including the session state *as it was when execution resumed*.
1. **Yield:** When the logic needs to communicate (send a message, call a tool, report a state change), it constructs an `Event` containing the relevant content and actions, and then `yield`s this event back to the `Runner`.
1. **Pause:** Crucially, execution of the agent logic **pauses immediately** after the `yield` statement (or `return` in RxJava). It waits for the `Runner` to complete step 3 (processing and committing).
1. **Resume:** *Only after* the `Runner` has processed the yielded event does the agent logic resume execution from the statement immediately following the `yield`.
1. **See Updated State:** Upon resumption, the agent logic can now reliably access the session state (`ctx.session.state`) reflecting the changes that were committed by the `Runner` from the *previously yielded* event.

*Conceptual Execution Logic:*

```py
# Simplified view of logic inside Agent.run_async, callbacks, or tools

# ... previous code runs based on current state ...

# 1. Determine a change or output is needed, construct the event
# Example: Updating state
update_data = {'field_1': 'value_2'}
event_with_state_change = Event(
    author=self.name,
    actions=EventActions(state_delta=update_data),
    content=types.Content(parts=[types.Part(text="State updated.")])
    # ... other event fields ...
)

# 2. Yield the event to the Runner for processing & commit
yield event_with_state_change
# <<<<<<<<<<<< EXECUTION PAUSES HERE >>>>>>>>>>>>

# <<<<<<<<<<<< RUNNER PROCESSES & COMMITS THE EVENT >>>>>>>>>>>>

# 3. Resume execution ONLY after Runner is done processing the above event.
# Now, the state committed by the Runner is reliably reflected.
# Subsequent code can safely assume the change from the yielded event happened.
val = ctx.session.state['field_1']
# here `val` is guaranteed to be "value_2" (assuming Runner committed successfully)
print(f"Resumed execution. Value of field_1 is now: {val}")

# ... subsequent code continues ...
# Maybe yield another event later...
```

```typescript
// Simplified view of logic inside Agent.runAsync, callbacks, or tools

// ... previous code runs based on current state ...

// 1. Determine a change or output is needed, construct the event
// Example: Updating state
const updateData = {'field_1': 'value_2'};
const eventWithStateChange = createEvent({
    author: this.name,
    actions: createEventActions({stateDelta: updateData}),
    content: {parts: [{text: "State updated."}]}
    // ... other event fields ...
});

// 2. Yield the event to the Runner for processing & commit
yield eventWithStateChange;
// <<<<<<<<<<<< EXECUTION PAUSES HERE >>>>>>>>>>>>

// <<<<<<<<<<<< RUNNER PROCESSES & COMMITS THE EVENT >>>>>>>>>>>>

// 3. Resume execution ONLY after Runner is done processing the above event.
// Now, the state committed by the Runner is reliably reflected.
// Subsequent code can safely assume the change from the yielded event happened.
const val = ctx.session.state['field_1'];
// here `val` is guaranteed to be "value_2" (assuming Runner committed successfully)
console.log(`Resumed execution. Value of field_1 is now: ${val}`);

// ... subsequent code continues ...
// Maybe yield another event later...
```

```go
// Simplified view of logic inside Agent.Run, callbacks, or tools

// ... previous code runs based on current state ...

// 1. Determine a change or output is needed, construct the event
// Example: Updating state
updateData := map[string]interface{}{"field_1": "value_2"}
eventWithStateChange := &Event{
    Author: self.Name(),
    Actions: &EventActions{StateDelta: updateData},
    Content: genai.NewContentFromText("State updated.", "model"),
    // ... other event fields ...
}

// 2. Yield the event to the Runner for processing & commit
// In Go, this is done by sending the event to a channel.
eventsChan <- eventWithStateChange
// <<<<<<<<<<<< EXECUTION PAUSES HERE (conceptually) >>>>>>>>>>>>
// The Runner on the other side of the channel will receive and process the event.
// The agent's goroutine might continue, but the logical flow waits for the next input or step.

// <<<<<<<<<<<< RUNNER PROCESSES & COMMITS THE EVENT >>>>>>>>>>>>

// 3. Resume execution ONLY after Runner is done processing the above event.
// In a real Go implementation, this would likely be handled by the agent receiving
// a new RunRequest or context indicating the next step. The updated state
// would be part of the session object in that new request.
// For this conceptual example, we'll just check the state.
val := ctx.State.Get("field_1")
// here `val` is guaranteed to be "value_2" because the Runner would have
// updated the session state before calling the agent again.
fmt.Printf("Resumed execution. Value of field_1 is now: %v\n", val)

// ... subsequent code continues ...
// Maybe send another event to the channel later...
```

```java
// Simplified view of logic inside Agent.runAsync, callbacks, or tools
// ... previous code runs based on current state ...

// 1. Determine a change or output is needed, construct the event
// Example: Updating state
ConcurrentMap<String, Object> updateData = new ConcurrentHashMap<>();
updateData.put("field_1", "value_2");

EventActions actions = EventActions.builder().stateDelta(updateData).build();
Content eventContent = Content.builder().parts(Part.fromText("State updated.")).build();

Event eventWithStateChange = Event.builder()
    .author(self.name())
    .actions(actions)
    .content(Optional.of(eventContent))
    // ... other event fields ...
    .build();

// 2. "Yield" the event. In RxJava, this means emitting it into the stream.
//    The Runner (or upstream consumer) will subscribe to this Flowable.
//    When the Runner receives this event, it will process it (e.g., call sessionService.appendEvent).
//    The 'appendEvent' in Java ADK mutates the 'Session' object held within 'ctx' (InvocationContext).

// <<<<<<<<<<<< CONCEPTUAL PAUSE POINT >>>>>>>>>>>>
// In RxJava, the emission of 'eventWithStateChange' happens, and then the stream
// might continue with a 'flatMap' or 'concatMap' operator that represents
// the logic *after* the Runner has processed this event.

// To model the "resume execution ONLY after Runner is done processing":
// The Runner's `appendEvent` is usually an async operation itself (returns Single<Event>).
// The agent's flow needs to be structured such that subsequent logic
// that depends on the committed state runs *after* that `appendEvent` completes.

// This is how the Runner typically orchestrates it:
// Runner:
//   agent.runAsync(ctx)
//     .concatMapEager(eventFromAgent ->
//         sessionService.appendEvent(ctx.session(), eventFromAgent) // This updates ctx.session().state()
//             .toFlowable() // Emits the event after it's processed
//     )
//     .subscribe(processedEvent -> { /* UI renders processedEvent */ });

// So, within the agent's own logic, if it needs to do something *after* an event it yielded
// has been processed and its state changes are reflected in ctx.session().state(),
// that subsequent logic would typically be in another step of its reactive chain.

// For this conceptual example, we'll emit the event, and then simulate the "resume"
// as a subsequent operation in the Flowable chain.

return Flowable.just(eventWithStateChange) // Step 2: Yield the event
    .concatMap(yieldedEvent -> {
        // <<<<<<<<<<<< RUNNER CONCEPTUALLY PROCESSES & COMMITS THE EVENT >>>>>>>>>>>>
        // At this point, in a real runner, ctx.session().appendEvent(yieldedEvent) would have been called
        // by the Runner, and ctx.session().state() would be updated.
        // Since we are *inside* the agent's conceptual logic trying to model this,
        // we assume the Runner's action has implicitly updated our 'ctx.session()'.

        // 3. Resume execution.
        // Now, the state committed by the Runner (via sessionService.appendEvent)
        // is reliably reflected in ctx.session().state().
        Object val = ctx.session().state().get("field_1");
        // here `val` is guaranteed to be "value_2" because the `sessionService.appendEvent`
        // called by the Runner would have updated the session state within the `ctx` object.

        System.out.println("Resumed execution. Value of field_1 is now: " + val);

        // ... subsequent code continues ...
        // If this subsequent code needs to yield another event, it would do so here.
```

This cooperative yield/pause/resume cycle between the `Runner` and your Execution Logic, mediated by `Event` objects, forms the core of the ADK Runtime.

## Key components of the Runtime

Several components work together within the ADK Runtime to execute an agent invocation. Understanding their roles clarifies how the event loop functions:

1. ### `Runner`
   - **Role:** The main entry point and orchestrator for a single user query (`run_async`).
   - **Function:** Manages the overall Event Loop, receives events yielded by the Execution Logic, coordinates with Services to process and commit event actions (state/artifact changes), and forwards processed events upstream (e.g., to the UI). It essentially drives the conversation turn by turn based on yielded events. (Defined in `google.adk.runners.runner`).
1. ### Execution Logic Components
   - **Role:** The parts containing your custom code and the core agent capabilities.
   - **Components:**
   - `Agent` (`BaseAgent`, `LlmAgent`, etc.): Your primary logic units that process information and decide on actions. They implement the `_run_async_impl` method which yields events.
   - `Tools` (`BaseTool`, `FunctionTool`, `AgentTool`, etc.): External functions or capabilities used by agents (often `LlmAgent`) to interact with the outside world or perform specific tasks. They execute and return results, which are then wrapped in events.
   - `Callbacks` (Functions): User-defined functions attached to agents (e.g., `before_agent_callback`, `after_model_callback`) that hook into specific points in the execution flow, potentially modifying behavior or state, whose effects are captured in events.
   - **Function:** Perform the actual thinking, calculation, or external interaction. They communicate their results or needs by **yielding `Event` objects** and pausing until the Runner processes them.
1. ### `Event`
   - **Role:** The message passed back and forth between the `Runner` and the Execution Logic.
   - **Function:** Represents an atomic occurrence (user input, agent text, tool call/result, state change request, control signal). It carries both the content of the occurrence and the intended side effects (`actions` like `state_delta`).
1. ### `Services`
   - **Role:** Backend components responsible for managing persistent or shared resources. Used primarily by the `Runner` during event processing.
   - **Components:**
   - `SessionService` (`BaseSessionService`, `InMemorySessionService`, etc.): Manages `Session` objects, including saving/loading them, applying `state_delta` to the session state, and appending events to the `event history`.
   - `ArtifactService` (`BaseArtifactService`, `InMemoryArtifactService`, `GcsArtifactService`, etc.): Manages the storage and retrieval of binary artifact data. Although `save_artifact` is called via context during execution logic, the `artifact_delta` in the event confirms the action for the Runner/SessionService.
   - `MemoryService` (`BaseMemoryService`, etc.): (Optional) Manages long-term semantic memory across sessions for a user.
   - **Function:** Provide the persistence layer. The `Runner` interacts with them to ensure changes signaled by `event.actions` are reliably stored *before* the Execution Logic resumes.
1. ### `Session`
   - **Role:** A data container holding the state and history for *one specific conversation* between a user and the application.
   - **Function:** Stores the current `state` dictionary, the list of all past `events` (`event history`), and references to associated artifacts. It's the primary record of the interaction, managed by the `SessionService`.
1. ### `Invocation`
   - **Role:** A conceptual term representing everything that happens in response to a *single* user query, from the moment the `Runner` receives it until the agent logic finishes yielding events for that query.
   - **Function:** An invocation might involve multiple agent runs (if using agent transfer or `AgentTool`), multiple LLM calls, tool executions, and callback executions, all tied together by a single `invocation_id` within the `InvocationContext`. State variables prefixed with `temp:` are strictly scoped to a single invocation and discarded afterwards.

These players interact continuously through the Event Loop to process a user's request.

## How It Works: A Simplified Invocation

Let's trace a simplified flow for a typical user query that involves an LLM agent calling a tool:

### Step-by-Step Breakdown

1. **User Input:** The User sends a query (e.g., "What's the capital of France?").
1. **Runner Starts:** `Runner.run_async` begins. It interacts with the `SessionService` to load the relevant `Session` and adds the user query as the first `Event` to the session history. An `InvocationContext` (`ctx`) is prepared.
1. **Agent Execution:** The `Runner` calls `agent.run_async(ctx)` on the designated root agent (e.g., an `LlmAgent`).
1. **LLM Call (Example):** The `Agent_Llm` determines it needs information, perhaps by calling a tool. It prepares a request for the `LLM`. Let's assume the LLM decides to call `MyTool`.
1. **Yield FunctionCall Event:** The `Agent_Llm` receives the `FunctionCall` response from the LLM, wraps it in an `Event(author='Agent_Llm', content=Content(parts=[Part(function_call=...)]))`, and `yields` or `emits` this event.
1. **Agent Pauses:** The `Agent_Llm`'s execution pauses immediately after the `yield`.
1. **Runner Processes:** The `Runner` receives the FunctionCall event. It passes it to the `SessionService` to record it in the history. The `Runner` then yields the event upstream to the `User` (or application).
1. **Agent Resumes:** The `Runner` signals that the event is processed, and `Agent_Llm` resumes execution.
1. **Tool Execution:** The `Agent_Llm`'s internal flow now proceeds to execute the requested `MyTool`. It calls `tool.run_async(...)`.
1. **Tool Returns Result:** `MyTool` executes and returns its result (e.g., `{'result': 'Paris'}`).
1. **Yield FunctionResponse Event:** The agent (`Agent_Llm`) wraps the tool result into an `Event` containing a `FunctionResponse` part (e.g., `Event(author='Agent_Llm', content=Content(role='user', parts=[Part(function_response=...)]))`). This event might also contain `actions` if the tool modified state (`state_delta`) or saved artifacts (`artifact_delta`). The agent `yield`s this event.
1. **Agent Pauses:** `Agent_Llm` pauses again.
1. **Runner Processes:** `Runner` receives the FunctionResponse event. It passes it to `SessionService` which applies any `state_delta`/`artifact_delta` and adds the event to history. `Runner` yields the event upstream.
1. **Agent Resumes:** `Agent_Llm` resumes, now knowing the tool result and any state changes are committed.
1. **Final LLM Call (Example):** `Agent_Llm` sends the tool result back to the `LLM` to generate a natural language response.
1. **Yield Final Text Event:** `Agent_Llm` receives the final text from the `LLM`, wraps it in an `Event(author='Agent_Llm', content=Content(parts=[Part(text=...)]))`, and `yield`s it.
1. **Agent Pauses:** `Agent_Llm` pauses.
1. **Runner Processes:** `Runner` receives the final text event, passes it to `SessionService` for history, and yields it upstream to the `User`. This is likely marked as the `is_final_response()`.
1. **Agent Resumes & Finishes:** `Agent_Llm` resumes. Having completed its task for this invocation, its `run_async` generator finishes.
1. **Runner Completes:** The `Runner` sees the agent's generator is exhausted and finishes its loop for this invocation.

This yield/pause/process/resume cycle ensures that state changes are consistently applied and that the execution logic always operates on the most recently committed state after yielding an event.

## Important Runtime Behaviors

Understanding a few key aspects of how the ADK Runtime handles state, streaming, and asynchronous operations is crucial for building predictable and efficient agents.

### State Updates & Commitment Timing

- **The Rule:** When your code (in an agent, tool, or callback) modifies the session state (e.g., `context.state['my_key'] = 'new_value'`), this change is initially recorded locally within the current `InvocationContext`. The change is only **guaranteed to be persisted** (saved by the `SessionService`) *after* the `Event` carrying the corresponding `state_delta` in its `actions` has been `yield`-ed by your code and subsequently processed by the `Runner`.
- **Implication:** Code that runs *after* resuming from a `yield` can reliably assume that the state changes signaled in the *yielded event* have been committed.

```py
# Inside agent logic (conceptual)

# 1. Modify state
ctx.session.state['status'] = 'processing'
event1 = Event(..., actions=EventActions(state_delta={'status': 'processing'}))

# 2. Yield event with the delta
yield event1
# --- PAUSE --- Runner processes event1, SessionService commits 'status' = 'processing' ---

# 3. Resume execution
# Now it's safe to rely on the committed state
current_status = ctx.session.state['status'] # Guaranteed to be 'processing'
print(f"Status after resuming: {current_status}")
```

```typescript
// Inside agent logic (conceptual)

// 1. Modify state
// In TypeScript, you modify state via the context, which tracks the change.
ctx.state.set('status', 'processing');
// The framework will automatically populate actions with the state
// delta from the context. For illustration, it's shown here.
const event1 = createEvent({
    actions: createEventActions({stateDelta: {'status': 'processing'}}),
    // ... other event fields
});

// 2. Yield event with the delta
yield event1;
// --- PAUSE --- Runner processes event1, SessionService commits 'status' = 'processing' ---

// 3. Resume execution
// Now it's safe to rely on the committed state in the session object.
const currentStatus = ctx.session.state['status']; // Guaranteed to be 'processing'
console.log(`Status after resuming: ${currentStatus}`);
```

```go
  // Inside agent logic (conceptual)

func (a *Agent) RunConceptual(ctx agent.InvocationContext) iter.Seq2[*session.Event, error] {
  // The entire logic is wrapped in a function that will be returned as an iterator.
  return func(yield func(*session.Event, error) bool) {
      // ... previous code runs based on current state from the input `ctx` ...
      // e.g., val := ctx.State().Get("field_1") might return "value_1" here.

      // 1. Determine a change or output is needed, construct the event
      updateData := map[string]interface{}{"field_1": "value_2"}
      eventWithStateChange := session.NewEvent(ctx.InvocationID())
      eventWithStateChange.Author = a.Name()
      eventWithStateChange.Actions = &session.EventActions{StateDelta: updateData}
      // ... other event fields ...


      // 2. Yield the event to the Runner for processing & commit.
      // The agent's execution continues immediately after this call.
      if !yield(eventWithStateChange, nil) {
          // If yield returns false, it means the consumer (the Runner)
          // has stopped listening, so we should stop producing events.
          return
      }

      // <<<<<<<<<<<< RUNNER PROCESSES & COMMITS THE EVENT >>>>>>>>>>>>
      // This happens outside the agent, after the agent's iterator has
      // produced the event.

      // 3. The agent CANNOT immediately see the state change it just yielded.
      // The state is immutable within a single `Run` invocation.
      val := ctx.State().Get("field_1")
      // `val` here is STILL "value_1" (or whatever it was at the start).
      // The updated state ("value_2") will only be available in the `ctx`
      // of the *next* `Run` invocation in a subsequent turn.

      // ... subsequent code continues, potentially yielding more events ...
      finalEvent := session.NewEvent(ctx.InvocationID())
      finalEvent.Author = a.Name()
      // ...
      yield(finalEvent, nil)
  }
}
```

```java
// Inside agent logic (conceptual)
// ... previous code runs based on current state ...

// 1. Prepare state modification and construct the event
ConcurrentHashMap<String, Object> stateChanges = new ConcurrentHashMap<>();
stateChanges.put("status", "processing");

EventActions actions = EventActions.builder().stateDelta(stateChanges).build();
Content content = Content.builder().parts(Part.fromText("Status update: processing")).build();

Event event1 = Event.builder()
    .actions(actions)
    // ...
    .build();

// 2. Yield event with the delta
return Flowable.just(event1)
    .map(
        emittedEvent -> {
            // --- CONCEPTUAL PAUSE & RUNNER PROCESSING ---
            // 3. Resume execution (conceptually)
            // Now it's safe to rely on the committed state.
            String currentStatus = (String) ctx.session().state().get("status");
            System.out.println("Status after resuming (inside agent logic): " + currentStatus); // Guaranteed to be 'processing'

            // The event itself (event1) is passed on.
            // If subsequent logic within this agent step produced *another* event,
            // you'd use concatMap to emit that new event.
            return emittedEvent;
        });

// ... subsequent agent logic might involve further reactive operators
// or emitting more events based on the now-updated `ctx.session().state()`.
```

### "Dirty Reads" of Session State

- **Definition:** While commitment happens *after* the yield, code running *later within the same invocation*, but *before* the state-changing event is actually yielded and processed, **can often see the local, uncommitted changes**. This is sometimes called a "dirty read".
- **Example:**

```py
# Code in before_agent_callback
callback_context.state['field_1'] = 'value_1'
# State is locally set to 'value_1', but not yet committed by Runner

# ... agent runs ...

# Code in a tool called later *within the same invocation*
# Readable (dirty read), but 'value_1' isn't guaranteed persistent yet.
val = tool_context.state['field_1'] # 'val' will likely be 'value_1' here
print(f"Dirty read value in tool: {val}")

# Assume the event carrying the state_delta={'field_1': 'value_1'}
# is yielded *after* this tool runs and is processed by the Runner.
```

```typescript
// Code in beforeAgentCallback
callbackContext.state.set('field_1', 'value_1');
// State is locally set to 'value_1', but not yet committed by Runner

// --- agent runs ... ---

// --- Code in a tool called later *within the same invocation* ---
// Readable (dirty read), but 'value_1' isn't guaranteed persistent yet.
const val = toolContext.state.get('field_1'); // 'val' will likely be 'value_1' here
console.log(`Dirty read value in tool: ${val}`);

// Assume the event carrying the state_delta={'field_1': 'value_1'}
// is yielded *after* this tool runs and is processed by the Runner.
```

```go
// Code in before_agent_callback
// The callback would modify the context's session state directly.
// This change is local to the current invocation context.
ctx.State.Set("field_1", "value_1")
// State is locally set to 'value_1', but not yet committed by Runner

// ... agent runs ...

// Code in a tool called later *within the same invocation*
// Readable (dirty read), but 'value_1' isn't guaranteed persistent yet.
val := ctx.State.Get("field_1") // 'val' will likely be 'value_1' here
fmt.Printf("Dirty read value in tool: %v\n", val)

// Assume the event carrying the state_delta={'field_1': 'value_1'}
// is yielded *after* this tool runs and is processed by the Runner.
```

```java
// Modify state - Code in BeforeAgentCallback
// AND stages this change in callbackContext.eventActions().stateDelta().
callbackContext.state().put("field_1", "value_1");

// --- agent runs ... ---

// --- Code in a tool called later *within the same invocation* ---
// Readable (dirty read), but 'value_1' isn't guaranteed persistent yet.
Object val = toolContext.state().get("field_1"); // 'val' will likely be 'value_1' here
System.out.println("Dirty read value in tool: " + val);
// Assume the event carrying the state_delta={'field_1': 'value_1'}
// is yielded *after* this tool runs and is processed by the Runner.
```

- **Implications:**
- **Benefit:** Allows different parts of your logic within a single complex step (e.g., multiple callbacks or tool calls before the next LLM turn) to coordinate using state without waiting for a full yield/commit cycle.
- **Caveat:** Relying heavily on dirty reads for critical logic can be risky. If the invocation fails *before* the event carrying the `state_delta` is yielded and processed by the `Runner`, the uncommitted state change will be lost. For critical state transitions, ensure they are associated with an event that gets successfully processed.

### Streaming vs. Non-Streaming Output (`partial=True`)

This primarily relates to how responses from the LLM are handled, especially when using streaming generation APIs.

- **Streaming:** The LLM generates its response token-by-token or in small chunks.
- The framework (often within `BaseLlmFlow`) yields multiple `Event` objects for a single conceptual response. Most of these events will have `partial=True`.
- The `Runner`, upon receiving an event with `partial=True`, typically **forwards it immediately** upstream (for UI display) but **skips processing its `actions`** (like `state_delta`).
- Eventually, the framework yields a final event for that response, marked as non-partial (`partial=False` or implicitly via `turn_complete=True`).
- The `Runner` **fully processes only this final event**, committing any associated `state_delta` or `artifact_delta`.
- **Non-Streaming:** The LLM generates the entire response at once. The framework yields a single event marked as non-partial, which the `Runner` processes fully.
- **Why it Matters:** Ensures that state changes are applied atomically and only once based on the *complete* response from the LLM, while still allowing the UI to display text progressively as it's generated.

## Async is Primary (`run_async`)

- **Core Design:** The ADK Runtime is fundamentally built on asynchronous patterns and libraries (like Python's `asyncio`, Java's `RxJava`, and native `Promise`s and `AsyncGenerator`s in TypeScript) to handle concurrent operations (like waiting for LLM responses or tool executions) efficiently without blocking.
- **Main Entry Point:** `Runner.run_async` is the primary method for executing agent invocations. All core runnable components (Agents, specific flows) use `asynchronous` methods internally.
- **Synchronous Convenience (`run`):** A synchronous `Runner.run` method exists mainly for convenience (e.g., in simple scripts or testing environments). However, internally, `Runner.run` typically just calls `Runner.run_async` and manages the async event loop execution for you.
- **Developer Experience:** We recommend designing your applications (e.g., web servers using ADK) to be asynchronous for best performance. In Python, this means using `asyncio`; in Java, leverage `RxJava`'s reactive programming model; and in TypeScript, this means building using native `Promise`s and `AsyncGenerator`s.
- **Sync Callbacks/Tools:** The ADK framework supports both asynchronous and synchronous functions for tools and callbacks.
  - **Blocking I/O:** For long-running synchronous I/O operations, the framework attempts to prevent stalls. Python ADK may use asyncio.to_thread, while Java ADK often relies on appropriate RxJava schedulers or wrappers for blocking calls. In TypeScript, the framework simply awaits the function; if a synchronous function performs blocking I/O, it will stall the event loop. Developers should use asynchronous I/O APIs (which return a Promise) whenever possible.
  - **CPU-Bound Work:** Purely CPU-intensive synchronous tasks will still block their execution thread in both environments.

Understanding these behaviors helps you write more robust ADK applications and debug issues related to state consistency, streaming updates, and asynchronous execution.

# Resume stopped agents

Supported in ADKPython v1.14.0

An ADK agent's execution can be interrupted by various factors including dropped network connections, power failure, or a required external system going offline. The Resume feature of ADK allows an agent workflow to pick up where it left off, avoiding the need to restart the entire workflow. In ADK Python 1.16 and higher, you can configure an ADK workflow to be resumable, so that it tracks the execution of workflow and then allows you to resume it after an unexpected interruption.

This guide explains how to configure your ADK agent workflow to be resumable. If you use Custom Agents, you can update them to be resumable. For more information, see [Add resume to custom Agents](#custom-agents).

## Add resumable configuration

Enable the Resume function for an agent workflow by applying a Resumability configuration to the App object of your ADK workflow, as shown in the following code example:

```python
app = App(
    name='my_resumable_agent',
    root_agent=root_agent,
    # Set the resumability config to enable resumability.
    resumability_config=ResumabilityConfig(
        is_resumable=True,
    ),
)
```

Caution: Long Running Functions, Confirmations, Authentication

For agents that use [Long Running Functions](/tools-custom/function-tools/#long-run-tool), [Confirmations](/tools-custom/confirmation/), or [Authentication](/tools-custom/authentication/) requiring user input, adding a resumable confirmation changes how these features operate. For more information, see the documentation for those features.

Note: Custom Agents

Resume is not supported by default for Custom Agents. You must update the agent code for a Custom Agent to support the Resume feature. For information on modifying Custom Agents to support incremental resume functionality, see [Add resume to custom Agents](#custom-agents).

## Resume a stopped workflow

When an ADK workflow stops execution you can resume the workflow using a command containing the Invocation ID for the workflow instance, which can be found in the [Event](/events/#understanding-and-using-events) history of the workflow. Make sure the ADK API server is running, in case it was interrupted or powered off, and then run the following command to resume the workflow, as shown in the following API request example.

```console
# restart the API server if needed:
adk api_server my_resumable_agent/

# resume the agent:
curl -X POST http://localhost:8000/run_sse \
 -H "Content-Type: application/json" \
 -d '{
   "app_name": "my_resumable_agent",
   "user_id": "u_123",
   "session_id": "s_abc",
   "invocation_id": "invocation-123",
 }'
```

You can also resume a workflow using the Runner object Run Async method, as shown below:

```python
runner.run_async(user_id='u_123', session_id='s_abc',
    invocation_id='invocation-123')

# When new_message is set to a function response,
# we are trying to resume a long running function.
```

Note

Resuming a workflow from the ADK Web user interface or using the ADK command line (CLI) tool is not currently supported.

## How it works

The Resume feature works by logging completed Agent workflow tasks, including incremental steps using [Events](/events/) and [Event Actions](/events/#detecting-actions-and-side-effects). tracking completion of agent tasks within a resumable workflow. If a workflow is interrupted and then later restarted, the system resumes the workflow by setting the completion state of each agent. If an agent did not complete, the workflow system reinstates any completed Events for that agent, and restarts the workflow from the partially completed state. For multi-agent workflows, the specific resume behavior varies, based on the multi-agent classes in your workflow, as described below:

- **Sequential Agent**: Reads the current_sub_agent from its saved state to find the next sub-agent to run in the sequence.
- **Loop Agent**: Uses the current_sub_agent and times_looped values to continue the loop from the last completed iteration and sub-agent.
- **Parallel Agent**: Determines which sub-agents have already completed and only runs those that have not finished.

Event logging includes results from Tools which successfully returned a result. So if an agent successfully executed Function Tools A and B, and then failed during execution of tool C, the system reinstates the results from the tools A and B, and resumes the workflow by re-running the tool C request.

Caution: Tool execution behavior

When resuming a workflow with Tools, the Resume feature ensures that the Tools in an agent are run ***at least once***, and may run more than once when resuming a workflow. If your agent uses Tools where duplicate runs would have a negative impact, such as purchases, you should modify the Tool to check for and prevent duplicate runs.

Note: Workflow modification with Resume not supported

Do not modify a stopped agent workflow before resuming it. For example adding or removing agents from workflow that has stopped and then resuming that workflow is not supported.

## Add resume to custom Agents

Custom agents have specific implementation requirements in order to support resumability. You must decide on and define workflow steps within your custom agent which produce a result which can be preserved before handing off to the next step of processing. The following steps outline how to modify a Custom Agent to support a workflow Resume.

- **Create CustomAgentState class**: Extend the BaseAgentState to create an object that preserves the state of your agent.
  - **Optionally, create WorkFlowStep class**: If your custom agent has sequential steps, consider creating a WorkFlowStep list object that defines the discrete, savable steps of the agent.
- **Add initial agent state:** Modify your agent's async run function to set the initial state of your agent.
- **Add agent state checkpoints**: Modify your agent's async run function to generate and save the agent state for each completed step of the agent's overall task.
- **Add end of agent status to track agent state:** Modify your agent's async run function to include an `end_of_agent=True` status upon successful completion of the agent's full task.

The following example shows the required code modifications to the example StoryFlowAgent class shown in the [Custom Agents](/agents/custom-agents/#full-code-example) guide:

```python
class WorkflowStep(int, Enum):
 INITIAL_STORY_GENERATION = 1
 CRITIC_REVISER_LOOP = 2
 POST_PROCESSING = 3
 CONDITIONAL_REGENERATION = 4

# Extend BaseAgentState

### class StoryFlowAgentState(BaseAgentState):

###   step = WorkflowStep

@override
async def _run_async_impl(
    self, ctx: InvocationContext
) -> AsyncGenerator[Event, None]:
    """
    Implements the custom orchestration logic for the story workflow.
    Uses the instance attributes assigned by Pydantic (e.g., self.story_generator).
    """
    agent_state = self._load_agent_state(ctx, WorkflowStep)

    if agent_state is None:
      # Record the start of the agent
      agent_state = StoryFlowAgentState(step=WorkflowStep.INITIAL_STORY_GENERATION)
      yield self._create_agent_state_event(ctx, agent_state)

    next_step = agent_state.step
    logger.info(f"[{self.name}] Starting story generation workflow.")

    # Step 1. Initial Story Generation
    if next_step <= WorkflowStep.INITIAL_STORY_GENERATION:
      logger.info(f"[{self.name}] Running StoryGenerator...")
      async for event in self.story_generator.run_async(ctx):
          yield event

      # Check if story was generated before proceeding
      if "current_story" not in ctx.session.state or not ctx.session.state[
          "current_story"
      ]:
          return  # Stop processing if initial story failed

    agent_state = StoryFlowAgentState(step=WorkflowStep.CRITIC_REVISER_LOOP)
    yield self._create_agent_state_event(ctx, agent_state)

    # Step 2. Critic-Reviser Loop
    if next_step <= WorkflowStep.CRITIC_REVISER_LOOP:
      logger.info(f"[{self.name}] Running CriticReviserLoop...")
      async for event in self.loop_agent.run_async(ctx):
          logger.info(
              f"[{self.name}] Event from CriticReviserLoop: "
              f"{event.model_dump_json(indent=2, exclude_none=True)}"
          )
          yield event

    agent_state = StoryFlowAgentState(step=WorkflowStep.POST_PROCESSING)
    yield self._create_agent_state_event(ctx, agent_state)

    # Step 3. Sequential Post-Processing (Grammar and Tone Check)
    if next_step <= WorkflowStep.POST_PROCESSING:
      logger.info(f"[{self.name}] Running PostProcessing...")
      async for event in self.sequential_agent.run_async(ctx):
          logger.info(
              f"[{self.name}] Event from PostProcessing: "
              f"{event.model_dump_json(indent=2, exclude_none=True)}"
          )
          yield event

    agent_state = StoryFlowAgentState(step=WorkflowStep.CONDITIONAL_REGENERATION)
    yield self._create_agent_state_event(ctx, agent_state)

    # Step 4. Tone-Based Conditional Logic
    if next_step <= WorkflowStep.CONDITIONAL_REGENERATION:
      tone_check_result = ctx.session.state.get("tone_check_result")
      if tone_check_result == "negative":
          logger.info(f"[{self.name}] Tone is negative. Regenerating story...")
          async for event in self.story_generator.run_async(ctx):
              logger.info(
                  f"[{self.name}] Event from StoryGenerator (Regen): "
                  f"{event.model_dump_json(indent=2, exclude_none=True)}"
              )
              yield event
      else:
          logger.info(f"[{self.name}] Tone is not negative. Keeping current story.")

    logger.info(f"[{self.name}] Workflow finished.")
    yield self._create_agent_state_event(ctx, end_of_agent=True)
```

# Runtime Configuration

Supported in ADKPython v0.1.0Typescript v0.2.0Go v0.1.0Java v0.1.0

`RunConfig` defines runtime behavior and options for agents in ADK. It controls speech and streaming settings, function calling, artifact saving, and limits on LLM calls.

When constructing an agent run, you can pass a `RunConfig` to customize how the agent interacts with models, handles audio, and streams responses. By default, no streaming is enabled and inputs aren’t retained as artifacts. Use `RunConfig` to override these defaults.

## Class Definition

The `RunConfig` class holds configuration parameters for an agent's runtime behavior.

- Python ADK uses Pydantic for this validation.
- Go ADK has mutable structs by default.
- Java ADK typically uses immutable data classes.
- TypeScript ADK uses a standard interface, with type safety provided by the TypeScript compiler.

```python
class RunConfig(BaseModel):
    """Configs for runtime behavior of agents."""

    model_config = ConfigDict(
        extra='forbid',
    )

    speech_config: Optional[types.SpeechConfig] = None
    response_modalities: Optional[list[str]] = None
    save_input_blobs_as_artifacts: bool = False
    support_cfc: bool = False
    streaming_mode: StreamingMode = StreamingMode.NONE
    output_audio_transcription: Optional[types.AudioTranscriptionConfig] = None
    max_llm_calls: int = 500
```

```typescript
export interface RunConfig {
  speechConfig?: SpeechConfig;
  responseModalities?: Modality[];
  saveInputBlobsAsArtifacts: boolean;
  supportCfc: boolean;
  streamingMode: StreamingMode;
  outputAudioTranscription?: AudioTranscriptionConfig;
  maxLlmCalls: number;
  // ... and other properties
}

export enum StreamingMode {
  NONE = 'none',
  SSE = 'sse',
  BIDI = 'bidi',
}
```

```go
type StreamingMode string

const (
    StreamingModeNone StreamingMode = "none"
    StreamingModeSSE  StreamingMode = "sse"
)

// RunConfig controls runtime behavior.
type RunConfig struct {
    // Streaming mode, None or StreamingMode.SSE.
    StreamingMode StreamingMode
    // Whether or not to save the input blobs as artifacts
    SaveInputBlobsAsArtifacts bool
}
```

```java
public abstract class RunConfig {

  public enum StreamingMode {
    NONE,
    SSE,
    BIDI
  }

  public abstract @Nullable SpeechConfig speechConfig();

  public abstract ImmutableList<Modality> responseModalities();

  public abstract boolean saveInputBlobsAsArtifacts();

  public abstract @Nullable AudioTranscriptionConfig outputAudioTranscription();

  public abstract int maxLlmCalls();

  // ...
}
```

## Runtime Parameters

| Parameter                       | Python Type                                | TypeScript Type                       | Go Type         | Java Type                                             | Default (Py / TS / Go / Java)                                                                  | Description                                                                                                                                                 |
| ------------------------------- | ------------------------------------------ | ------------------------------------- | --------------- | ----------------------------------------------------- | ---------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `speech_config`                 | `Optional[types.SpeechConfig]`             | `SpeechConfig` (optional)             | N/A             | `SpeechConfig` (nullable via `@Nullable`)             | `None` / `undefined`/ N/A / `null`                                                             | Configures speech synthesis (voice, language) using the `SpeechConfig` type.                                                                                |
| `response_modalities`           | `Optional[list[str]]`                      | `Modality[]` (optional)               | N/A             | `ImmutableList<Modality>`                             | `None` / `undefined` / N/A / Empty `ImmutableList`                                             | List of desired output modalities (e.g., Python: `["TEXT", "AUDIO"]`; Java/TS: uses structured `Modality` objects).                                         |
| `save_input_blobs_as_artifacts` | `bool`                                     | `boolean`                             | `bool`          | `boolean`                                             | `False` / `false` / `false` / `false`                                                          | If `true`, saves input blobs (e.g., uploaded files) as run artifacts for debugging/auditing.                                                                |
| `streaming_mode`                | `StreamingMode`                            | `StreamingMode`                       | `StreamingMode` | `StreamingMode`                                       | `StreamingMode.NONE` / `StreamingMode.NONE` / `agent.StreamingModeNone` / `StreamingMode.NONE` | Sets the streaming behavior: `NONE` (default), `SSE` (server-sent events), or `BIDI` (bidirectional).                                                       |
| `output_audio_transcription`    | `Optional[types.AudioTranscriptionConfig]` | `AudioTranscriptionConfig` (optional) | N/A             | `AudioTranscriptionConfig` (nullable via `@Nullable`) | `None` / `undefined` / N/A / `null`                                                            | Configures transcription of generated audio output using the `AudioTranscriptionConfig` type.                                                               |
| `max_llm_calls`                 | `int`                                      | `number`                              | N/A             | `int`                                                 | `500` / `500` / N/A / `500`                                                                    | Limits total LLM calls per run. `0` or negative means unlimited. Exceeding language limits (e.g. `sys.maxsize`, `Number.MAX_SAFE_INTEGER`) raises an error. |
| `support_cfc`                   | `bool`                                     | `boolean`                             | N/A             | `bool`                                                | `False` / `false` / N/A / `false`                                                              | **Python/TypeScript:** Enables Compositional Function Calling. Requires `streaming_mode=SSE` and uses the LIVE API. **Experimental.**                       |

### `speech_config`

Supported in ADKPython v0.1.0Java v0.1.0

Note

The interface or definition of `SpeechConfig` is the same, irrespective of the language.

Speech configuration settings for live agents with audio capabilities. The `SpeechConfig` class has the following structure:

```python
class SpeechConfig(_common.BaseModel):
    """The speech generation configuration."""

    voice_config: Optional[VoiceConfig] = Field(
        default=None,
        description="""The configuration for the speaker to use.""",
    )
    language_code: Optional[str] = Field(
        default=None,
        description="""Language code (ISO 639. e.g. en-US) for the speech synthesization.
        Only available for Live API.""",
    )
```

The `voice_config` parameter uses the `VoiceConfig` class:

```python
class VoiceConfig(_common.BaseModel):
    """The configuration for the voice to use."""

    prebuilt_voice_config: Optional[PrebuiltVoiceConfig] = Field(
        default=None,
        description="""The configuration for the speaker to use.""",
    )
```

And `PrebuiltVoiceConfig` has the following structure:

```python
class PrebuiltVoiceConfig(_common.BaseModel):
    """The configuration for the prebuilt speaker to use."""

    voice_name: Optional[str] = Field(
        default=None,
        description="""The name of the prebuilt voice to use.""",
    )
```

These nested configuration classes allow you to specify:

- `voice_config`: The name of the prebuilt voice to use (in the `PrebuiltVoiceConfig`)
- `language_code`: ISO 639 language code (e.g., "en-US") for speech synthesis

When implementing voice-enabled agents, configure these parameters to control how your agent sounds when speaking.

### `response_modalities`

Supported in ADKPython v0.1.0Java v0.1.0

Defines the output modalities for the agent. If not set, defaults to AUDIO. Response modalities determine how the agent communicates with users through various channels (e.g., text, audio).

### `save_input_blobs_as_artifacts`

Supported in ADKPython v0.1.0Go v0.1.0Java v0.1.0

When enabled, input blobs will be saved as artifacts during agent execution. This is useful for debugging and audit purposes, allowing developers to review the exact data received by agents.

### `support_cfc`

Supported in ADKPython v0.1.0Experimental

Enables Compositional Function Calling (CFC) support. Only applicable when using StreamingMode.SSE. When enabled, the LIVE API will be invoked as only it supports CFC functionality.

Experimental release

The `support_cfc` feature is experimental and its API or behavior might change in future releases.

### `streaming_mode`

Supported in ADKPython v0.1.0Go v0.1.0

Configures the streaming behavior of the agent. Possible values:

- `StreamingMode.NONE`: No streaming; responses delivered as complete units
- `StreamingMode.SSE`: Server-Sent Events streaming; one-way streaming from server to client
- `StreamingMode.BIDI`: Bidirectional streaming; simultaneous communication in both directions

Streaming modes affect both performance and user experience. SSE streaming lets users see partial responses as they're generated, while BIDI streaming enables real-time interactive experiences.

### `output_audio_transcription`

Supported in ADKPython v0.1.0Java v0.1.0

Configuration for transcribing audio outputs from live agents with audio response capability. This enables automatic transcription of audio responses for accessibility, record-keeping, and multi-modal applications.

### `max_llm_calls`

Supported in ADKPython v0.1.0Java v0.1.0

Sets a limit on the total number of LLM calls for a given agent run.

- Values greater than 0 and less than `sys.maxsize`: Enforces a bound on LLM calls
- Values less than or equal to 0: Allows unbounded LLM calls *(not recommended for production)*

This parameter prevents excessive API usage and potential runaway processes. Since LLM calls often incur costs and consume resources, setting appropriate limits is crucial.

## Validation Rules

Supported in ADKPython v0.1.0Typescript v0.2.0Go v0.1.0Java v0.1.0

The `RunConfig` class validates its parameters to ensure proper agent operation. While Python ADK uses `Pydantic` for automatic type validation, Java and TypeScript ADK rely on their static type systems and may include explicit checks in the `RunConfig`'s constructor. For the `max_llm_calls` parameter specifically:

1. Extremely large values (like `sys.maxsize` in Python, `Integer.MAX_VALUE` in Java, or `Number.MAX_SAFE_INTEGER` in TypeScript) are typically disallowed to prevent issues.
1. Values of zero or less will usually trigger a warning about unlimited LLM interactions.

### Basic runtime configuration

```python
from google.genai.adk import RunConfig, StreamingMode

config = RunConfig(
    streaming_mode=StreamingMode.NONE,
    max_llm_calls=100
)
```

```typescript
import { RunConfig, StreamingMode } from '@google/adk';

const config: RunConfig = {
  streamingMode: StreamingMode.NONE,
  maxLlmCalls: 100,
};
```

```go
import "google.golang.org/adk/agent"

config := agent.RunConfig{
    StreamingMode: agent.StreamingModeNone,
}
```

```java
import com.google.adk.agents.RunConfig;
import com.google.adk.agents.RunConfig.StreamingMode;

RunConfig config = RunConfig.builder()
        .setStreamingMode(StreamingMode.NONE)
        .setMaxLlmCalls(100)
        .build();
```

This configuration creates a non-streaming agent with a limit of 100 LLM calls, suitable for simple task-oriented agents where complete responses are preferable.

### Enabling streaming

```python
from google.genai.adk import RunConfig, StreamingMode

config = RunConfig(
    streaming_mode=StreamingMode.SSE,
    max_llm_calls=200
)
```

```typescript
import { RunConfig, StreamingMode } from '@google/adk';

const config: RunConfig = {
  streamingMode: StreamingMode.SSE,
  maxLlmCalls: 200,
};
```

```go
import "google.golang.org/adk/agent"

config := agent.RunConfig{
    StreamingMode: agent.StreamingModeSSE,
}
```

```java
import com.google.adk.agents.RunConfig;
import com.google.adk.agents.RunConfig.StreamingMode;

RunConfig config = RunConfig.builder()
    .setStreamingMode(StreamingMode.SSE)
    .setMaxLlmCalls(200)
    .build();
```

Using SSE streaming allows users to see responses as they're generated, providing a more responsive feel for chatbots and assistants.

### Enabling speech support

```python
from google.genai.adk import RunConfig, StreamingMode
from google.genai import types

config = RunConfig(
    speech_config=types.SpeechConfig(
        language_code="en-US",
        voice_config=types.VoiceConfig(
            prebuilt_voice_config=types.PrebuiltVoiceConfig(
                voice_name="Kore"
            )
        ),
    ),
    response_modalities=["AUDIO", "TEXT"],
    save_input_blobs_as_artifacts=True,
    support_cfc=True,
    streaming_mode=StreamingMode.SSE,
    max_llm_calls=1000,
)
```

```typescript
import { RunConfig, StreamingMode } from '@google/adk';

const config: RunConfig = {
    speechConfig: {
        languageCode: "en-US",
        voiceConfig: {
            prebuiltVoiceConfig: {
                voiceName: "Kore"
            }
        },
    },
    responseModalities: [
      { modality: "AUDIO" },
      { modality: "TEXT" }
    ],
    saveInputBlobsAsArtifacts: true,
    supportCfc: true,
    streamingMode: StreamingMode.SSE,
    maxLlmCalls: 1000,
};
```

```java
import com.google.adk.agents.RunConfig;
import com.google.adk.agents.RunConfig.StreamingMode;
import com.google.common.collect.ImmutableList;
import com.google.genai.types.Content;
import com.google.genai.types.Modality;
import com.google.genai.types.Part;
import com.google.genai.types.PrebuiltVoiceConfig;
import com.google.genai.types.SpeechConfig;
import com.google.genai.types.VoiceConfig;

RunConfig runConfig =
    RunConfig.builder()
        .setStreamingMode(StreamingMode.SSE)
        .setMaxLlmCalls(1000)
        .setSaveInputBlobsAsArtifacts(true)
        .setResponseModalities(ImmutableList.of(new Modality("AUDIO"), new Modality("TEXT")))
        .setSpeechConfig(
            SpeechConfig.builder()
                .voiceConfig(
                    VoiceConfig.builder()
                        .prebuiltVoiceConfig(
                            PrebuiltVoiceConfig.builder().voiceName("Kore").build())
                        .build())
                .languageCode("en-US")
                .build())
        .build();
```

This comprehensive example configures an agent with:

- Speech capabilities using the "Kore" voice (US English)
- Both audio and text output modalities
- Artifact saving for input blobs (useful for debugging)
- Experimental CFC support enabled **(Python and TypeScript)**
- SSE streaming for responsive interaction
- A limit of 1000 LLM calls

### Enabling CFC Support

Supported in ADKPython v0.1.0Typescript v0.2.0Experimental

```python
from google.genai.adk import RunConfig, StreamingMode

config = RunConfig(
    streaming_mode=StreamingMode.SSE,
    support_cfc=True,
    max_llm_calls=150
)
```

```typescript
import { RunConfig, StreamingMode } from '@google/adk';

const config: RunConfig = {
    streamingMode: StreamingMode.SSE,
    supportCfc: true,
    maxLlmCalls: 150,
};
```

Enabling Compositional Function Calling (CFC) creates an agent that can dynamically execute functions based on model outputs, powerful for applications requiring complex workflows.

Experimental release

The Compositional Function Calling (CFC) streaming feature is an experimental release.

# Use the Web Interface

Supported in ADKPython v0.1.0TypeScript v0.2.0Go v0.1.0Java v0.1.0

The ADK web interface lets you test your agents directly in the browser. This tool provides a simple way to interactively develop and debug your agents.

Caution: ADK Web for development only

ADK Web is ***not meant for use in production deployments***. You should use ADK Web for development and debugging purposes only.

## Start the web interface

Use the following command to run your agent in the ADK web interface:

```shell
adk web
```

```shell
npx adk web
```

```shell
go run agent.go web api webui
```

Make sure to update the port number.

With Maven, compile and run the ADK web server:

```console
mvn compile exec:java \
 -Dexec.args="--adk.agents.source-dir=src/main/java/agents --server.port=8080"
```

With Gradle, the `build.gradle` or `build.gradle.kts` build file should have the following Java plugin in its plugins section:

```groovy
plugins {
    id('java')
    // other plugins
}
```

Then, elsewhere in the build file, at the top-level, create a new task:

```groovy
tasks.register('runADKWebServer', JavaExec) {
    dependsOn classes
    classpath = sourceSets.main.runtimeClasspath
    mainClass = 'com.google.adk.web.AdkWebServer'
    args '--adk.agents.source-dir=src/main/java/agents', '--server.port=8080'
}
```

Finally, on the command-line, run the following command:

```console
gradle runADKWebServer
```

In Java, the Web Interface and the API server are bundled together.

The server starts on `http://localhost:8000` by default:

```shell
+-----------------------------------------------------------------------------+
| ADK Web Server started                                                      |
|                                                                             |
| For local testing, access at http://localhost:8000.                         |
+-----------------------------------------------------------------------------+
```

## Features

Key features of the ADK web interface include:

- **Chat interface**: Send messages to your agents and view responses in real-time
- **Session management**: Create and switch between sessions
- **State inspection**: View and modify session state during development
- **Event history**: Inspect all events generated during agent execution

## Common options

| Option                   | Description                        | Default                |
| ------------------------ | ---------------------------------- | ---------------------- |
| `--port`                 | Port to run the server on          | `8000`                 |
| `--host`                 | Host binding address               | `127.0.0.1`            |
| `--session_service_uri`  | Custom session storage URI         | In-memory              |
| `--artifact_service_uri` | Custom artifact storage URI        | Local `.adk/artifacts` |
| `--reload/--no-reload`   | Enable auto-reload on code changes | `true`                 |

### Example with options

```shell
adk web --port 3000 --session_service_uri "sqlite:///sessions.db"
```




# Deploying Your Agent

Once you've built and tested your agent using ADK, the next step is to deploy it so it can be accessed, queried, and used in production or integrated with other applications. Deployment moves your agent from your local development machine to a scalable and reliable environment.

## Deployment Options

Your ADK agent can be deployed to a range of different environments based on your needs for production readiness or custom flexibility:

### Agent Runtime on Agent Platform

[Agent Runtime](https://adk.dev/deploy/agent-runtime/index.md) is a fully managed auto-scaling service on Google Cloud specifically designed for deploying, managing, and scaling AI agents built with frameworks such as ADK.

Learn more about [deploying your agent to Agent Runtime](https://adk.dev/deploy/agent-runtime/index.md).

### Cloud Run

[Cloud Run](https://cloud.google.com/run) is a managed auto-scaling compute platform on Google Cloud that enables you to run your agent as a container-based application.

Learn more about [deploying your agent to Cloud Run](https://adk.dev/deploy/cloud-run/index.md).

### Google Kubernetes Engine (GKE)

[Google Kubernetes Engine (GKE)](https://cloud.google.com/kubernetes-engine) is a managed Kubernetes service of Google Cloud that allows you to run your agent in a containerized environment. GKE is a good option if you need more control over the deployment as well as for running Open Models.

Learn more about [deploying your agent to GKE](https://adk.dev/deploy/gke/index.md).

### Other Container-friendly Infrastructure

You can manually package your Agent into a container image and then run it in any environment that supports container images. For example you can run it locally in Docker or Podman. This is a good option if you prefer to run offline or disconnected, or otherwise in a system that has no connection to Google Cloud.

Follow the instructions for [deploying your agent to Cloud Run](https://adk.dev/deploy/cloud-run/#deployment-commands). In the "Deployment Commands" section for gcloud CLI, you will find an example FastAPI entry point and Dockerfile.

# Deploy to Cloud Run

Supported in ADKPythonTypeScriptGoJava

[Cloud Run](https://cloud.google.com/run) is a fully managed platform that enables you to run your code directly on top of Google's scalable infrastructure.

To deploy your agent, you can use either the `adk deploy cloud_run` command *(recommended for Python)*, or with `gcloud run deploy` command through Cloud Run.

## Agent sample

For each of the commands, we will reference the `Capital Agent` sample defined on the [LLM agent](https://adk.dev/agents/llm-agents/index.md) page. We will assume it's in a directory (eg: `capital_agent`).

To proceed, confirm that your agent code is configured as follows:

1. Agent code is in a file called `agent.py` within your agent directory.

1. Your agent variable is named `root_agent`.

1. `__init__.py` is within your agent directory and contains `from . import agent`.

1. Your `requirements.txt` file is present in the agent directory.

1. Agent code is in a file called `agent.ts` within your project directory.

1. Your agent variable is named `rootAgent` and is exported.

1. Your `package.json` file is present in the agent directory with `@google/adk` and other dependencies.

1. Your application's entry point (the main package and main() function) is in a single Go file. Using main.go is a strong convention.

1. Your agent instance is passed to a launcher configuration, typically using agent.NewSingleLoader(yourAgent). The adkgo tool uses this launcher to start your agent with the correct services.

1. Your go.mod and go.sum files are present in your project directory to manage dependencies.

Refer to the following section for more details. You can also find a [sample app](https://github.com/google/adk-docs/tree/main/examples/go/cloud-run) in the Github repo.

1. Agent code is in a file called `CapitalAgent.java` within your agent directory.
1. Your agent variable is global and follows the format `public static final BaseAgent ROOT_AGENT`.
1. Your agent definition is present in a static class method.

Refer to the following section for more details. You can also find a [sample app](https://github.com/google/adk-docs/tree/main/examples/java/cloud-run) in the Github repo.

## Environment variables

Set your environment variables as described in the [Setup and Installation](https://adk.dev/get-started/installation/index.md) guide.

```bash
export GOOGLE_CLOUD_PROJECT=your-project-id
export GOOGLE_CLOUD_LOCATION=us-central1 # Or your preferred location
export GOOGLE_GENAI_USE_VERTEXAI=True
```

*(Replace `your-project-id` with your actual GCP project ID)*

Alternatively you can also use an API key from AI Studio

```bash
export GOOGLE_CLOUD_PROJECT=your-project-id
export GOOGLE_CLOUD_LOCATION=us-central1 # Or your preferred location
export GOOGLE_GENAI_USE_VERTEXAI=FALSE
export GOOGLE_API_KEY=your-api-key
```

*(Replace `your-project-id` with your actual GCP project ID and `your-api-key` with your actual API key from AI Studio)*

## Prerequisites

1. You should have a Google Cloud project. You need to know your:
   1. Project name (i.e. "my-project")
   1. Project location (i.e. "us-central1")
   1. Service account (i.e. "1234567890-compute@developer.gserviceaccount.com")
   1. GOOGLE_API_KEY

## Secret

Please make sure you have created a secret which can be read by your service account.

### Cloud Build Permissions

Since the `adk deploy` command uses Google Cloud Build to automate the build process, you must set your default compute service account to have permission to use Cloud Build. The following command example shows how to grant this permission:

````bash
gcloud projects add-iam-policy-binding [PROJECT_ID] \
    --member="serviceAccount:[PROJECT_NUMBER]-compute@developer.gserviceaccount.com" \
    --role="roles/cloudbuild.builds.builder"

### Entry for GOOGLE_API_KEY secret

You can create your secret manually or use CLI:
```bash
echo "<<put your GOOGLE_API_KEY here>>" | gcloud secrets create GOOGLE_API_KEY --project=my-project --data-file=-
````

### Permissions to read

You should give appropriate permission for you service account to read this secret.

```bash
gcloud secrets add-iam-policy-binding GOOGLE_API_KEY --member="serviceAccount:1234567890-compute@developer.gserviceaccount.com" --role="roles/secretmanager.secretAccessor" --project=my-project
```

## Deployment payload

When you deploy your ADK agent workflow to Google Cloud Run, the following content is uploaded to the service:

- Your ADK agent code
- Any dependencies declared in your ADK agent code
- ADK API server code version used by your agent

The default deployment *does not* include the ADK web user interface libraries, unless you specify it as deployment setting, such as the `--with_ui` option for `adk deploy cloud_run` command.

## Deployment commands

### adk CLI

The `adk deploy cloud_run` command deploys your agent code to Google Cloud Run.

Ensure you have authenticated with Google Cloud (`gcloud auth login` and `gcloud config set project <your-project-id>`).

#### Setup environment variables

Optional but recommended: Setting environment variables can make the deployment commands cleaner.

```bash
# Set your Google Cloud Project ID
export GOOGLE_CLOUD_PROJECT="your-gcp-project-id"

# Set your desired Google Cloud Location
export GOOGLE_CLOUD_LOCATION="us-central1" # Example location

# Set the path to your agent code directory
export AGENT_PATH="./capital_agent" # Assuming capital_agent is in the current directory

# Set a name for your Cloud Run service (optional)
export SERVICE_NAME="capital-agent-service"

# Set an application name (optional)
export APP_NAME="capital_agent_app"
```

#### Command usage

##### Minimal command

```bash
adk deploy cloud_run \
--project=$GOOGLE_CLOUD_PROJECT \
--region=$GOOGLE_CLOUD_LOCATION \
$AGENT_PATH
```

##### Full command with optional flags

```bash
adk deploy cloud_run \
--project=$GOOGLE_CLOUD_PROJECT \
--region=$GOOGLE_CLOUD_LOCATION \
--service_name=$SERVICE_NAME \
--app_name=$APP_NAME \
--with_ui \
$AGENT_PATH
```

##### Arguments

- `AGENT_PATH`: (Required) Positional argument specifying the path to the directory containing your agent's source code (e.g., `$AGENT_PATH` in the examples, or `capital_agent/`). This directory must contain at least an `__init__.py` and your main agent file (e.g., `agent.py`).

##### Options

- `--project TEXT`: (Required) Your Google Cloud project ID (e.g., `$GOOGLE_CLOUD_PROJECT`).
- `--region TEXT`: (Required) The Google Cloud location for deployment (e.g., `$GOOGLE_CLOUD_LOCATION`, `us-central1`).
- `--service_name TEXT`: (Optional) The name for the Cloud Run service (e.g., `$SERVICE_NAME`). Defaults to `adk-default-service-name`.
- `--app_name TEXT`: (Optional) The application name for the ADK API server (e.g., `$APP_NAME`). Defaults to the name of the directory specified by `AGENT_PATH` (e.g., `capital_agent` if `AGENT_PATH` is `./capital_agent`).
- `--agent_engine_id TEXT`: (Optional) If you are using a managed session service via Agent Runtime, provide its resource ID here.
- `--port INTEGER`: (Optional) The port number the ADK API server will listen on within the container. Defaults to 8000.
- `--with_ui`: (Optional) If included, deploys the ADK dev UI alongside the agent API server. By default, only the API server is deployed.
- `--temp_folder TEXT`: (Optional) Specifies a directory for storing intermediate files generated during the deployment process. Defaults to a timestamped folder in the system's temporary directory. *(Note: This option is generally not needed unless troubleshooting issues).*
- `--help`: Show the help message and exit.

##### Passing gcloud CLI Arguments

To pass specific gcloud flags through the `adk deploy cloud_run` command, use the double-dash separator (`--`) after the ADK arguments. Any flags (except ADK-managed) following the `--` will be passed directly to the underlying gcloud command.

###### Syntax Example:

```bash
adk deploy cloud_run [ADK_FLAGS] -- [GCLOUD_FLAGS]
```

###### Example:

```bash
adk deploy cloud_run --project=[PROJECT_ID] --region=[REGION] path/to/my_agent    -- --no-allow-unauthenticated --min-instances=2
```

##### Authenticated access

During the deployment process, you might be prompted: `Allow unauthenticated invocations to [your-service-name] (y/N)?`.

- Enter `y` to allow public access to your agent's API endpoint without authentication.
- Enter `N` (or press Enter for the default) to require authentication (e.g., using an identity token as shown in the "Testing your agent" section).

Upon successful execution, the command deploys your agent to Cloud Run and provide the URL of the deployed service.

### gcloud CLI for Python

Alternatively, you can deploy using the standard `gcloud run deploy` command with a `Dockerfile`. This method requires more manual setup compared to the `adk` command but offers flexibility, particularly if you want to embed your agent within a custom [FastAPI](https://fastapi.tiangolo.com/) application.

Ensure you have authenticated with Google Cloud (`gcloud auth login` and `gcloud config set project <your-project-id>`).

#### Project Structure

Organize your project files as follows:

```text
your-project-directory/
├── capital_agent/
│   ├── __init__.py
│   └── agent.py       # Your agent code (see "Agent sample" tab)
├── main.py            # FastAPI application entry point
├── requirements.txt   # Python dependencies
└── Dockerfile         # Container build instructions
```

Create the following files (`main.py`, `requirements.txt`, `Dockerfile`) in the root of `your-project-directory/`.

#### Code files

1. This file sets up the FastAPI application using `get_fast_api_app()` from ADK:

   main.py

   ```python
   import os

   import uvicorn
   from fastapi import FastAPI
   from google.adk.cli.fast_api import get_fast_api_app

   # Get the directory where main.py is located
   AGENT_DIR = os.path.dirname(os.path.abspath(__file__))
   # Example session service URI (e.g., SQLite)
   # Note: Use 'sqlite+aiosqlite' instead of 'sqlite' because DatabaseSessionService requires an async driver
   SESSION_SERVICE_URI = "sqlite+aiosqlite:///./sessions.db"
   # Example allowed origins for CORS
   ALLOWED_ORIGINS = ["http://localhost", "http://localhost:8080", "*"]
   # Set web=True if you intend to serve a web interface, False otherwise
   SERVE_WEB_INTERFACE = True

   # Call the function to get the FastAPI app instance
   # Ensure the agent directory name ('capital_agent') matches your agent folder
   app: FastAPI = get_fast_api_app(
       agents_dir=AGENT_DIR,
       session_service_uri=SESSION_SERVICE_URI,
       allow_origins=ALLOWED_ORIGINS,
       web=SERVE_WEB_INTERFACE,
   )

   # You can add more FastAPI routes or configurations below if needed
   # Example:
   # @app.get("/hello")
   # async def read_root():
   #     return {"Hello": "World"}

   if __name__ == "__main__":
       # Use the PORT environment variable provided by Cloud Run, defaulting to 8080
       uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
   ```

   *Note: We specify `agent_dir` to the directory `main.py` is in and use `os.environ.get("PORT", 8080)` for Cloud Run compatibility.*

1. List the necessary Python packages:

   requirements.txt

   ```text
   google-adk
   # Add any other dependencies your agent needs
   ```

1. Define the container image:

   Dockerfile

   ```dockerfile
   FROM python:3.13-slim
   WORKDIR /app

   COPY requirements.txt .
   RUN pip install --no-cache-dir -r requirements.txt

   RUN adduser --disabled-password --gecos "" myuser && \
       chown -R myuser:myuser /app

   COPY . .

   USER myuser

   ENV PATH="/home/myuser/.local/bin:$PATH"

   CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port $PORT"]
   ```

#### Defining Multiple Agents

You can define and deploy multiple agents within the same Cloud Run instance by creating separate folders in the root of `your-project-directory/`. Each folder represents one agent and must define a `root_agent` in its configuration.

Example structure:

```text
your-project-directory/
├── capital_agent/
│   ├── __init__.py
│   └── agent.py       # contains `root_agent` definition
├── population_agent/
│   ├── __init__.py
│   └── agent.py       # contains `root_agent` definition
└── ...
```

#### Deploy using `gcloud`

Navigate to `your-project-directory` in your terminal.

```bash
gcloud run deploy capital-agent-service \
--source . \
--region $GOOGLE_CLOUD_LOCATION \
--project $GOOGLE_CLOUD_PROJECT \
--allow-unauthenticated \
--set-env-vars="GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT,GOOGLE_CLOUD_LOCATION=$GOOGLE_CLOUD_LOCATION,GOOGLE_GENAI_USE_VERTEXAI=$GOOGLE_GENAI_USE_VERTEXAI"
# Add any other necessary environment variables your agent might need
```

- `capital-agent-service`: The name you want to give your Cloud Run service.
- `--source .`: Tells gcloud to build the container image from the Dockerfile in the current directory.
- `--region`: Specifies the deployment region.
- `--project`: Specifies the GCP project.
- `--allow-unauthenticated`: Allows public access to the service. Remove this flag for private services.
- `--set-env-vars`: Passes necessary environment variables to the running container. Ensure you include all variables required by ADK and your agent (like API keys if not using Application Default Credentials).

`gcloud` will build the Docker image, push it to Google Artifact Registry, and deploy it to Cloud Run. Upon completion, it will output the URL of your deployed service.

For a full list of deployment options, see the [`gcloud run deploy` reference documentation](https://cloud.google.com/sdk/gcloud/reference/run/deploy).

### adk CLI

The `adk deploy cloud_run` command deploys your agent code to Google Cloud Run.

Ensure you have authenticated with Google Cloud (`gcloud auth login` and `gcloud config set project <your-project-id>`).

#### Setup environment variables

Optional but recommended: Setting environment variables can make the deployment commands cleaner.

```bash
# Set your Google Cloud Project ID
export GOOGLE_CLOUD_PROJECT="your-gcp-project-id"

# Set your desired Google Cloud Location
export GOOGLE_CLOUD_LOCATION="us-central1" # Example location

# Set a name for your Cloud Run service (optional)
export SERVICE_NAME="capital-agent-service"
```

#### Command usage

This deployment command should be run from the directory of your agent code, where your `package.json` file is located.

##### Minimal command

```bash
npx adk deploy cloud_run \
--project=$GOOGLE_CLOUD_PROJECT \
--region=$GOOGLE_CLOUD_LOCATION
```

##### Full command with optional flags

```bash
npx adk deploy cloud_run \
--project=$GOOGLE_CLOUD_PROJECT \
--region=$GOOGLE_CLOUD_LOCATION \
--service_name=$SERVICE_NAME \
--with_ui
```

##### Options

- `--project TEXT`: (Required) Your Google Cloud project ID (e.g., `$GOOGLE_CLOUD_PROJECT`).
- `--region TEXT`: (Required) The Google Cloud location for deployment (e.g., `$GOOGLE_CLOUD_LOCATION`, `us-central1`).
- `--service_name TEXT`: (Optional) The name for the Cloud Run service (e.g., `$SERVICE_NAME`). Defaults to `adk-default-service-name`.
- `--port INTEGER`: (Optional) The port number the ADK API server will listen on within the container. Defaults to 8000.
- `--with_ui`: (Optional) If included, deploys the ADK dev UI alongside the agent API server. By default, only the API server is deployed.
- `--temp_folder TEXT`: (Optional) Specifies a directory for storing intermediate files generated during the deployment process. Defaults to a timestamped folder in the system's temporary directory. *(Note: This option is generally not needed unless troubleshooting issues).*
- `--help`: Show the help message and exit.

##### Authenticated access

During the deployment process, you might be prompted: `Allow unauthenticated invocations to [your-service-name] (y/N)?`.

- Enter `y` to allow public access to your agent's API endpoint without authentication.
- Enter `N` (or press Enter for the default) to require authentication (e.g., using an identity token as shown in the "Testing your agent" section).

Upon successful execution, the command deploys your agent to Cloud Run and provides the URL of the deployed service.

### adk CLI

The adkgo command is located in the google/adk-go repository under cmd/adkgo. Before using it, you need to build it from the root of the adk-go repository:

`go build ./cmd/adkgo`

The adkgo deploy cloudrun command automates the deployment of your application. You do not need to provide your own Dockerfile.

#### Agent Code Structure

When using the adkgo tool, your main.go file must use the launcher framework. This is because the tool compiles your code and then runs the resulting executable with specific command-line arguments (like web, api, a2a) to start the required services. The launcher is designed to parse these arguments correctly.

Your main.go should look like this:

main.go

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
    "os"
    "strings"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/cmd/launcher"
    "google.golang.org/adk/cmd/launcher/full"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/functiontool"
    "google.golang.org/genai"
)

type getCapitalCityArgs struct {
    Country string `json:"country" jsonschema:"The country for which to find the capital city."`
}

func getCapitalCity(ctx tool.Context, args getCapitalCityArgs) (string, error) {
    capitals := map[string]string{
        "united states": "Washington, D.C.",
        "canada":        "Ottawa",
        "france":        "Paris",
        "japan":         "Tokyo",
    }
    capital, ok := capitals[strings.ToLower(args.Country)]
    if !ok {
        return "", fmt.Errorf("couldn't find the capital for %s", args.Country)
    }

    return capital, nil
}

func main() {
    ctx := context.Background()

    model, err := gemini.NewModel(ctx, "gemini-2.5-flash", &genai.ClientConfig{
        APIKey: os.Getenv("GOOGLE_API_KEY"),
    })
    if err != nil {
        log.Fatalf("Failed to create model: %v", err)
    }

    capitalTool, err := functiontool.New(
        functiontool.Config{
            Name:        "get_capital_city",
            Description: "Retrieves the capital city for a given country.",
        },
        getCapitalCity,
    )
    if err != nil {
        log.Fatalf("Failed to create function tool: %v", err)
    }

    geoAgent, err := llmagent.New(llmagent.Config{
        Name:        "capital_agent",
        Model:       model,
        Description: "Agent to find the capital city of a country.",
        Instruction: "I can answer your questions about the capital city of a country.",
        Tools:       []tool.Tool{capitalTool},
    })
    if err != nil {
        log.Fatalf("Failed to create agent: %v", err)
    }

    config := &launcher.Config{
        AgentLoader: agent.NewSingleLoader(geoAgent),
    }

    l := full.NewLauncher()
    err = l.Execute(ctx, config, os.Args[1:])
    if err != nil {
        log.Fatalf("run failed: %v\n\n%s", err, l.CommandLineSyntax())
    }
}
```

#### How it Works

1. The adkgo tool compiles your main.go into a statically linked binary for Linux.
1. It generates a Dockerfile that copies this binary into a minimal container.
1. It uses gcloud to build and deploy this container to Cloud Run.
1. After deployment, it starts a local proxy that securely connects to your new service.

Ensure you have authenticated with Google Cloud (`gcloud auth login` and `gcloud config set project <your-project-id>`).

#### Setup environment variables

Optional but recommended: Setting environment variables can make the deployment commands cleaner.

```bash
# Set your Google Cloud Project ID
export GOOGLE_CLOUD_PROJECT="your-gcp-project-id"

# Set your desired Google Cloud Location
export GOOGLE_CLOUD_LOCATION="us-central1"

# Set the path to your agent's main Go file
export AGENT_PATH="./examples/go/cloud-run/main.go"

# Set a name for your Cloud Run service
export SERVICE_NAME="capital-agent-service"
```

#### Command usage

```bash
./adkgo deploy cloudrun \
    -p $GOOGLE_CLOUD_PROJECT \
    -r $GOOGLE_CLOUD_LOCATION \
    -s $SERVICE_NAME \
    --proxy_port=8081 \
    --server_port=8080 \
    -e $AGENT_PATH \
    --a2a --api --webui
```

##### Required

- `-p, --project_name`: Your Google Cloud project ID (e.g., $GOOGLE_CLOUD_PROJECT).
- `-r, --region`: The Google Cloud location for deployment (e.g., $GOOGLE_CLOUD_LOCATION, us-central1).
- `-s, --service_name`: The name for the Cloud Run service (e.g., $SERVICE_NAME).
- `-e, --entry_point_path`: Path to the main Go file containing your agent's source code (e.g., $AGENT_PATH).

##### Optional

- `--proxy_port`: The local port for the authenticating proxy to listen on. Defaults to 8081.
- `--server_port`: The port number the server will listen on within the Cloud Run container. Defaults to 8080.
- `--a2a`: If included, enables Agent2Agent communication. Enabled by default.
- `--a2a_agent_url`: A2A agent card URL as advertised in the public agent card. This flag is only valid when used with the --a2a flag.
- `--api`: If included, deploys the ADK API server. Enabled by default.
- `--webui`: If included, deploys the ADK dev UI alongside the agent API server. Enabled by default.
- `--temp_dir`: Temp directory for build artifacts. Defaults to os.TempDir().
- `--help`: Show the help message and exit.

##### Authenticated access

The service is deployed with --no-allow-unauthenticated by default.

Upon successful execution, the command deploys your agent to Cloud Run and provide a local URL to access the service through the proxy.

### gcloud CLI for Java

You can deploy Java Agents using the standard `gcloud run deploy` command and a `Dockerfile`. This is the current recommended way to deploy Java Agents to Google Cloud Run.

Ensure you are [authenticated](https://cloud.google.com/docs/authentication/gcloud) with Google Cloud. Specifically, run the commands `gcloud auth login` and `gcloud config set project <your-project-id>` from your terminal.

#### Project Structure

Organize your project files as follows:

```text
your-project-directory/
├── src/
│   └── main/
│       └── java/
│             └── agents/
│                 ├── capitalagent/
│                     └── CapitalAgent.java    # Your agent code
├── pom.xml                                    # Java adk and adk-dev dependencies
└── Dockerfile                                 # Container build instructions
```

Create the `pom.xml` and `Dockerfile` in the root of your project directory. Your Agent code file (`CapitalAgent.java`) inside a directory as shown above.

#### Code files

1. This is our Agent definition. This is the same code as present in [LLM agent](https://adk.dev/agents/llm-agents/index.md) with two caveats:

   - The Agent is now initialized as a **global public static final variable**.
   - The definition of the agent can be exposed in a static method or inlined during declaration.

   See the code for the `CapitalAgent` example in the [examples](https://github.com/google/adk-docs/blob/main/examples/java/cloud-run/src/main/java/agents/capitalagent/CapitalAgent.java) repository.

1. Add the following dependencies and plugin to the pom.xml file.

   pom.xml

   ```xml
   <dependencies>
     <dependency>
        <groupId>com.google.adk</groupId>
        <artifactId>google-adk</artifactId>
        <version>1.2.0</version>
     </dependency>
     <dependency>
        <groupId>com.google.adk</groupId>
        <artifactId>google-adk-dev</artifactId>
        <version>1.2.0</version>
     </dependency>
   </dependencies>

   <plugin>
     <groupId>org.codehaus.mojo</groupId>
     <artifactId>exec-maven-plugin</artifactId>
     <version>3.2.0</version>
     <configuration>
       <mainClass>com.google.adk.web.AdkWebServer</mainClass>
       <classpathScope>compile</classpathScope>
     </configuration>
   </plugin>
   ```

1. Define the container image:

   Dockerfile

   ```dockerfile
   # Use an official Maven image with a JDK. Choose a version appropriate for your project.
   FROM maven:3.8-openjdk-17 AS builder

   WORKDIR /app

   COPY pom.xml .
   RUN mvn dependency:go-offline -B

   COPY src ./src

   # Expose the port your application will listen on.
   # Cloud Run will set the PORT environment variable, which your app should use.
   EXPOSE 8080

   # The command to run your application.
   # Use a shell so ${PORT} expands and quote exec.args so agent source-dir is passed correctly.
   ENTRYPOINT ["sh", "-c", "mvn compile exec:java \
       -Dexec.mainClass=com.google.adk.web.AdkWebServer \
       -Dexec.classpathScope=compile \
       -Dexec.args='--server.port=${PORT:-8080} --adk.agents.source-dir=target'"]
   ```

#### Deploy using `gcloud`

Navigate to `your-project-directory` in your terminal.

```bash
gcloud run deploy capital-agent-service \
--source . \
--region $GOOGLE_CLOUD_LOCATION \
--project $GOOGLE_CLOUD_PROJECT \
--allow-unauthenticated \
--set-env-vars="GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT,GOOGLE_CLOUD_LOCATION=$GOOGLE_CLOUD_LOCATION,GOOGLE_GENAI_USE_VERTEXAI=$GOOGLE_GENAI_USE_VERTEXAI"
# Add any other necessary environment variables your agent might need
```

- `capital-agent-service`: The name you want to give your Cloud Run service.
- `--source .`: Tells gcloud to build the container image from the Dockerfile in the current directory.
- `--region`: Specifies the deployment region.
- `--project`: Specifies the GCP project.
- `--allow-unauthenticated`: Allows public access to the service. Remove this flag for private services.
- `--set-env-vars`: Passes necessary environment variables to the running container. Ensure you include all variables required by ADK and your agent (like API keys if not using Application Default Credentials).

`gcloud` will build the Docker image, push it to Google Artifact Registry, and deploy it to Cloud Run. Upon completion, it will output the URL of your deployed service.

For a full list of deployment options, see the [`gcloud run deploy` reference documentation](https://cloud.google.com/sdk/gcloud/reference/run/deploy).

## Testing your agent

Once your agent is deployed to Cloud Run, you can interact with it via the deployed UI (if enabled) or directly with its API endpoints using tools like `curl`. You'll need the service URL provided after deployment.

### UI Testing

If you deployed your agent with the UI enabled:

- **adk CLI:** You included the corresponding flag (`--webui` in Go or `--with_ui` in Python or Typescript) during deployment.
- **gcloud CLI:** You set `SERVE_WEB_INTERFACE = True` in your `main.py`.

You can test your agent by simply navigating to the Cloud Run service URL provided after deployment in your web browser.

```bash
# Example URL format
# https://your-service-name-abc123xyz.a.run.app
```

The ADK dev UI allows you to interact with your agent, manage sessions, and view execution details directly in the browser.

To verify your agent is working as intended, you can:

1. Select your agent from the dropdown menu.
1. Type a message and verify that you receive an expected response from your agent.

If you experience any unexpected behavior, check the [Cloud Run](https://console.cloud.google.com/run) console logs.

### API Testing (curl)

You can interact with the agent's API endpoints using tools like `curl`. This is useful for programmatic interaction or if you deployed without the UI.

You'll need the service URL provided after deployment and potentially an identity token for authentication if your service isn't set to allow unauthenticated access.

#### Set the application URL

Replace the example URL with the actual URL of your deployed Cloud Run service.

```bash
export APP_URL="YOUR_CLOUD_RUN_SERVICE_URL"
# Example: export APP_URL="https://adk-default-service-name-abc123xyz.a.run.app"
```

#### Get an identity token (if needed)

If your service requires authentication (i.e., you didn't use `--allow-unauthenticated` with `gcloud` or answered 'N' to the prompt with `adk`), obtain an identity token.

```bash
export TOKEN=$(gcloud auth print-identity-token)
```

*If your service allows unauthenticated access, you can omit the `-H "Authorization: Bearer $TOKEN"` header from the `curl` commands below.*

#### List available apps

Verify the deployed application name.

```bash
curl -X GET -H "Authorization: Bearer $TOKEN" $APP_URL/list-apps
```

*(Adjust the `app_name` in the following commands based on this output if needed. The default is often the agent directory name, e.g., `capital_agent`)*.

#### Create or Update a Session

Initialize or update the state for a specific user and session. Replace `capital_agent` with your actual app name if different. The values `user_123` and `session_abc` are example identifiers; you can replace them with your desired user and session IDs.

```bash
curl -X POST -H "Authorization: Bearer $TOKEN" \
    $APP_URL/apps/capital_agent/users/user_123/sessions/session_abc \
    -H "Content-Type: application/json" \
    -d '{"preferred_language": "English", "visit_count": 5}'
```

#### Run the Agent

Send a prompt to your agent. Replace `capital_agent` with your app name and adjust the user/session IDs and prompt as needed.

```bash
curl -X POST -H "Authorization: Bearer $TOKEN" \
    $APP_URL/run_sse \
    -H "Content-Type: application/json" \
    -d '{
    "app_name": "capital_agent",
    "user_id": "user_123",
    "session_id": "session_abc",
    "new_message": {
        "role": "user",
        "parts": [{
        "text": "What is the capital of Canada?"
        }]
    },
    "streaming": false
    }'
```

- Set `"streaming": true` if you want to receive Server-Sent Events (SSE).
- The response will contain the agent's execution events, including the final answer.

# Deploy to Google Kubernetes Engine (GKE)

Supported in ADKPython

[GKE](https://cloud.google.com/gke) is the Google Cloud managed Kubernetes service. It allows you to deploy and manage containerized applications using Kubernetes.

To deploy your agent you will need to have a Kubernetes cluster running on GKE. You can create a cluster using the Google Cloud Console or the `gcloud` command line tool.

In this example we will deploy a simple agent to GKE. The agent will be a FastAPI application that uses `Gemini 2.0 Flash` as the LLM. We can use Agent Platform or AI Studio as the LLM provider using the Environment variable `GOOGLE_GENAI_USE_VERTEXAI`.

## Environment variables

Set your environment variables as described in the [Setup and Installation](https://adk.dev/get-started/installation/index.md) guide. You also need to install the `kubectl` command line tool. You can find instructions to do so in the [Google Kubernetes Engine Documentation](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl).

```bash
export GOOGLE_CLOUD_PROJECT=your-project-id # Your GCP project ID
export GOOGLE_CLOUD_LOCATION=us-central1 # Or your preferred location
export GOOGLE_GENAI_USE_VERTEXAI=true # Set to true if using Agent Platform
export GOOGLE_CLOUD_PROJECT_NUMBER=$(gcloud projects describe --format json $GOOGLE_CLOUD_PROJECT | jq -r ".projectNumber")
```

If you don't have `jq` installed, you can use the following command to get the project number:

```bash
gcloud projects describe $GOOGLE_CLOUD_PROJECT
```

And copy the project number from the output.

```bash
export GOOGLE_CLOUD_PROJECT_NUMBER=YOUR_PROJECT_NUMBER
```

## Enable APIs and Permissions

Ensure you have authenticated with Google Cloud (`gcloud auth login` and `gcloud config set project <your-project-id>`).

Enable the necessary APIs for your project. You can do this using the `gcloud` command line tool.

```bash
gcloud services enable \
    container.googleapis.com \
    artifactregistry.googleapis.com \
    cloudbuild.googleapis.com \
    aiplatform.googleapis.com
```

Grant necessary roles to the default compute engine service account required by the `gcloud builds submit` command.

```bash
ROLES_TO_ASSIGN=(
    "roles/artifactregistry.writer"
    "roles/storage.objectViewer"
    "roles/logging.viewer"
    "roles/logging.logWriter"
)

for ROLE in "${ROLES_TO_ASSIGN[@]}"; do
    gcloud projects add-iam-policy-binding "${GOOGLE_CLOUD_PROJECT}" \
        --member="serviceAccount:${GOOGLE_CLOUD_PROJECT_NUMBER}-compute@developer.gserviceaccount.com" \
        --role="${ROLE}"
done
```

## Deployment payload

When you deploy your ADK agent workflow to the Google Cloud GKE, the following content is uploaded to the service:

- Your ADK agent code
- Any dependencies declared in your ADK agent code
- ADK API server code version used by your agent

The default deployment *does not* include the ADK web user interface libraries, unless you specify it as deployment setting, such as the `--with_ui` option for `adk deploy gke` command.

## Deployment options

You can deploy your agent to GKE either **manually using Kubernetes manifests** or **automatically using the `adk deploy gke` command**. Choose the approach that best suits your workflow.

## Option 1: Manual Deployment using gcloud and kubectl

### Create a GKE cluster

You can create a GKE cluster using the `gcloud` command line tool. This example creates an Autopilot cluster named `adk-cluster` in the `us-central1` region.

> If creating a GKE Standard cluster, make sure [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) is enabled. Workload Identity is enabled by default in an AutoPilot cluster.

```bash
gcloud container clusters create-auto adk-cluster \
    --location=$GOOGLE_CLOUD_LOCATION \
    --project=$GOOGLE_CLOUD_PROJECT
```

After creating the cluster, you need to connect to it using `kubectl`. This command configures `kubectl` to use the credentials for your new cluster.

```bash
gcloud container clusters get-credentials adk-cluster \
    --location=$GOOGLE_CLOUD_LOCATION \
    --project=$GOOGLE_CLOUD_PROJECT
```

### Create Your Agent

We will reference the `capital_agent` example defined on the [LLM agents](https://adk.dev/agents/llm-agents/index.md) page.

To proceed, organize your project files as follows:

```text
your-project-directory/
├── capital_agent/
│   ├── __init__.py
│   └── agent.py       # Your agent code (see "Capital Agent example" below)
├── main.py            # FastAPI application entry point
├── requirements.txt   # Python dependencies
└── Dockerfile         # Container build instructions
```

### Code files

Create the following files (`main.py`, `requirements.txt`, `Dockerfile`, `capital_agent/agent.py`, `capital_agent/__init__.py`) in the root of `your-project-directory/`.

1. This is the Capital Agent example inside the `capital_agent` directory

   capital_agent/agent.py

   ```python
   from google.adk.agents import LlmAgent 

   # Define a tool function
   def get_capital_city(country: str) -> str:
     """Retrieves the capital city for a given country."""
     # Replace with actual logic (e.g., API call, database lookup)
     capitals = {"france": "Paris", "japan": "Tokyo", "canada": "Ottawa"}
     return capitals.get(country.lower(), f"Sorry, I don't know the capital of {country}.")

   # Add the tool to the agent
   capital_agent = LlmAgent(
       model="gemini-flash-latest",
       name="capital_agent", #name of your agent
       description="Answers user questions about the capital city of a given country.",
       instruction="""You are an agent that provides the capital city of a country... (previous instruction text)""",
       tools=[get_capital_city] # Provide the function directly
   )

   # ADK will discover the root_agent instance
   root_agent = capital_agent
   ```

   Mark your directory as a python package

   capital_agent/__init__.py

   ```python
   from . import agent
   ```

1. This file sets up the FastAPI application using `get_fast_api_app()` from ADK:

   main.py

   ```python
   import os

   import uvicorn
   from fastapi import FastAPI
   from google.adk.cli.fast_api import get_fast_api_app

   # Get the directory where main.py is located
   AGENT_DIR = os.path.dirname(os.path.abspath(__file__))
   # Example session service URI (e.g., SQLite)
   # Note: Use 'sqlite+aiosqlite' instead of 'sqlite' because DatabaseSessionService requires an async driver
   SESSION_SERVICE_URI = "sqlite+aiosqlite:///./sessions.db"
   # Example allowed origins for CORS
   ALLOWED_ORIGINS = ["http://localhost", "http://localhost:8080", "*"]
   # Set web=True if you intend to serve a web interface, False otherwise
   SERVE_WEB_INTERFACE = True

   # Call the function to get the FastAPI app instance
   # Ensure the agent directory name ('capital_agent') matches your agent folder
   app: FastAPI = get_fast_api_app(
       agents_dir=AGENT_DIR,
       session_service_uri=SESSION_SERVICE_URI,
       allow_origins=ALLOWED_ORIGINS,
       web=SERVE_WEB_INTERFACE,
   )

   # You can add more FastAPI routes or configurations below if needed
   # Example:
   # @app.get("/hello")
   # async def read_root():
   #     return {"Hello": "World"}

   if __name__ == "__main__":
       # Use the PORT environment variable provided by Cloud Run, defaulting to 8080
       uvicorn.run(app, host="0.0.0.0", port=int(os.environ.get("PORT", 8080)))
   ```

   *Note: We specify `agent_dir` to the directory `main.py` is in and use `os.environ.get("PORT", 8080)` for Cloud Run compatibility.*

1. List the necessary Python packages:

   requirements.txt

   ```text
   google-adk
   # Add any other dependencies your agent needs
   ```

1. Define the container image:

   Dockerfile

   ```dockerfile
   FROM python:3.13-slim
   WORKDIR /app

   COPY requirements.txt .
   RUN pip install --no-cache-dir -r requirements.txt

   RUN adduser --disabled-password --gecos "" myuser && \
       chown -R myuser:myuser /app

   COPY . .

   USER myuser

   ENV PATH="/home/myuser/.local/bin:$PATH"

   CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port $PORT"]
   ```

### Build the container image

You need to create a Google Artifact Registry repository to store your container images. You can do this using the `gcloud` command line tool.

```bash
gcloud artifacts repositories create adk-repo \
    --repository-format=docker \
    --location=$GOOGLE_CLOUD_LOCATION \
    --description="ADK repository"
```

Build the container image using the `gcloud` command line tool. This example builds the image and tags it as `adk-repo/adk-agent:latest`.

```bash
gcloud builds submit \
    --tag $GOOGLE_CLOUD_LOCATION-docker.pkg.dev/$GOOGLE_CLOUD_PROJECT/adk-repo/adk-agent:latest \
    --project=$GOOGLE_CLOUD_PROJECT \
    .
```

Verify the image is built and pushed to the Artifact Registry:

```bash
gcloud artifacts docker images list \
  $GOOGLE_CLOUD_LOCATION-docker.pkg.dev/$GOOGLE_CLOUD_PROJECT/adk-repo \
  --project=$GOOGLE_CLOUD_PROJECT
```

### Configure Kubernetes Service Account for Agent Platform

If your agent uses Agent Platform, you need to create a Kubernetes service account with the necessary permissions. This example creates a service account named `adk-agent-sa` and binds it to the `Agent Platform User` role.

> If you are using AI Studio and accessing the model with an API key you can skip this step.

```bash
kubectl create serviceaccount adk-agent-sa
```

```bash
gcloud projects add-iam-policy-binding projects/${GOOGLE_CLOUD_PROJECT} \
    --role=roles/aiplatform.user \
    --member=principal://iam.googleapis.com/projects/${GOOGLE_CLOUD_PROJECT_NUMBER}/locations/global/workloadIdentityPools/${GOOGLE_CLOUD_PROJECT}.svc.id.goog/subject/ns/default/sa/adk-agent-sa \
    --condition=None
```

### Create the Kubernetes manifest files

Create a Kubernetes deployment manifest file named `deployment.yaml` in your project directory. This file defines how to deploy your application on GKE.

deployment.yaml

```yaml
cat <<  EOF > deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: adk-agent
spec:
  replicas: 1
  selector:
    matchLabels:
      app: adk-agent
  template:
    metadata:
      labels:
        app: adk-agent
    spec:
      serviceAccount: adk-agent-sa
      containers:
      - name: adk-agent
        imagePullPolicy: Always
        image: $GOOGLE_CLOUD_LOCATION-docker.pkg.dev/$GOOGLE_CLOUD_PROJECT/adk-repo/adk-agent:latest
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
            ephemeral-storage: "128Mi"
          requests:
            memory: "128Mi"
            cpu: "500m"
            ephemeral-storage: "128Mi"
        ports:
        - containerPort: 8080
        env:
          - name: PORT
            value: "8080"
          - name: GOOGLE_CLOUD_PROJECT
            value: $GOOGLE_CLOUD_PROJECT
          - name: GOOGLE_CLOUD_LOCATION
            value: $GOOGLE_CLOUD_LOCATION
          - name: GOOGLE_GENAI_USE_VERTEXAI
            value: "$GOOGLE_GENAI_USE_VERTEXAI"
          # If using AI Studio, set GOOGLE_GENAI_USE_VERTEXAI to false and set the following:
          # - name: GOOGLE_API_KEY
          #   value: $GOOGLE_API_KEY
          # Add any other necessary environment variables your agent might need
---
apiVersion: v1
kind: Service
metadata:
  name: adk-agent
spec:       
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 8080
  selector:
    app: adk-agent
EOF
```

### Deploy the Application

Deploy the application using the `kubectl` command line tool. This command applies the deployment and service manifest files to your GKE cluster.

```bash
kubectl apply -f deployment.yaml
```

After a few moments, you can check the status of your deployment using:

```bash
kubectl get pods -l=app=adk-agent
```

This command lists the pods associated with your deployment. You should see a pod with a status of `Running`.

Once the pod is running, you can check the status of the service using:

```bash
kubectl get service adk-agent
```

If the output shows a `External IP`, it means your service is accessible from the internet. It may take a few minutes for the external IP to be assigned.

You can get the external IP address of your service using:

```bash
kubectl get svc adk-agent -o=jsonpath='{.status.loadBalancer.ingress[0].ip}'
```

## Option 2: Automated Deployment using `adk deploy gke`

ADK provides a CLI command to streamline GKE deployment. This avoids the need to manually build images, write Kubernetes manifests, or push to Artifact Registry.

#### Prerequisites

Before you begin, ensure you have the following set up:

1. **A running GKE cluster:** You need an active Kubernetes cluster on Google Cloud.

1. **Required CLIs:**

   - **`gcloud` CLI:** The Google Cloud CLI must be installed, authenticated, and configured to use your target project. Run `gcloud auth login` and `gcloud config set project [YOUR_PROJECT_ID]`.
   - **kubectl:** The Kubernetes CLI must be installed to deploy the application to your cluster.

1. **Enabled Google Cloud APIs:** Make sure the following APIs are enabled in your Google Cloud project:

   - Kubernetes Engine API (`container.googleapis.com`)
   - Cloud Build API (`cloudbuild.googleapis.com`)
   - Container Registry API (`containerregistry.googleapis.com`)

1. **Required IAM Permissions:** The user or Compute Engine default service account running the command needs, at a minimum, the following roles:

1. **Kubernetes Engine Developer** (`roles/container.developer`): To interact with the GKE cluster.

1. **Storage Object Viewer** (`roles/storage.objectViewer`): To allow Cloud Build to download the source code from the Cloud Storage bucket where gcloud builds submit uploads it.

1. **Artifact Registry Create on Push Writer** (`roles/artifactregistry.createOnPushWriter`): To allow Cloud Build to push the built container image to Artifact Registry. This role also permits the on-the-fly creation of the special gcr.io repository within Artifact Registry if needed on the first push.

1. **Logs Writer** (`roles/logging.logWriter`): To allow Cloud Build to write build logs to Cloud Logging.

### The `deploy gke` Command

The command takes the path to your agent and parameters specifying the target GKE cluster.

#### Syntax

```bash
adk deploy gke [OPTIONS] AGENT_PATH
```

### Arguments & Options

| Argument       | Description                                                                              | Required |
| -------------- | ---------------------------------------------------------------------------------------- | -------- |
| AGENT_PATH     | The local file path to your agent's root directory.                                      | Yes      |
| --project      | The Google Cloud Project ID where your GKE cluster is located.                           | Yes      |
| --cluster_name | The name of your GKE cluster.                                                            | Yes      |
| --region       | The Google Cloud region of your cluster (e.g., us-central1).                             | Yes      |
| --with_ui      | Deploys both the agent's back-end API and a companion front-end user interface.          | No       |
| --log_level    | Sets the logging level for the deployment process. Options: debug, info, warning, error. | No       |

### How It Works

When you run the `adk deploy gke` command, the ADK performs the following steps automatically:

- Containerization: It builds a Docker container image from your agent's source code.
- Image Push: It tags the container image and pushes it to your project's Artifact Registry.
- Manifest Generation: It dynamically generates the necessary Kubernetes manifest files (a `Deployment` and a `Service`).
- Cluster Deployment: It applies these manifests to your specified GKE cluster, which triggers the following:

The `Deployment` instructs GKE to pull the container image from Artifact Registry and run it in one or more Pods.

The `Service` creates a stable network endpoint for your agent. By default, this is a LoadBalancer service, which provisions a public IP address to expose your agent to the internet.

### Example Usage

Here is a practical example of deploying an agent located at `~/agents/multi_tool_agent/` to a GKE cluster named test.

```bash
adk deploy gke \
    --project myproject \
    --cluster_name test \
    --region us-central1 \
    --with_ui \
    --log_level info \
    ~/agents/multi_tool_agent/
```

### Verifying Your Deployment

If you used `adk deploy gke`, verify the deployment using `kubectl`:

1. Check the Pods: Ensure your agent's pods are in the Running state.

```bash
kubectl get pods
```

You should see output like `adk-default-service-name-xxxx-xxxx ... 1/1 Running` in the default namespace.

1. Find the External IP: Get the public IP address for your agent's service.

```bash
kubectl get service
NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
adk-default-service-name   LoadBalancer   34.118.228.70   34.63.153.253   80:32581/TCP   5d20h
```

We can navigate to the external IP and interact with the agent via UI

## Testing your agent

Once your agent is deployed to GKE, you can interact with it via the deployed UI (if enabled) or directly with its API endpoints using tools like `curl`. You'll need the service URL provided after deployment.

### UI Testing

If you deployed your agent with the UI enabled:

You can test your agent by simply navigating to the kubernetes service URL in your web browser.

The ADK dev UI allows you to interact with your agent, manage sessions, and view execution details directly in the browser.

To verify your agent is working as intended, you can:

1. Select your agent from the dropdown menu.
1. Type a message and verify that you receive an expected response from your agent.

If you experience any unexpected behavior, check the pod logs for your agent using:

```bash
kubectl logs -l app=adk-agent
```

### API Testing (curl)

You can interact with the agent's API endpoints using tools like `curl`. This is useful for programmatic interaction or if you deployed without the UI.

#### Set the application URL

Replace the example URL with the actual URL of your deployed Cloud Run service.

```bash
export APP_URL=$(kubectl get service adk-agent -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
```

#### List available apps

Verify the deployed application name.

```bash
curl -X GET $APP_URL/list-apps
```

*(Adjust the `app_name` in the following commands based on this output if needed. The default is often the agent directory name, e.g., `capital_agent`)*.

#### Create or Update a Session

Initialize or update the state for a specific user and session. Replace `capital_agent` with your actual app name if different. The values `user_123` and `session_abc` are example identifiers; you can replace them with your desired user and session IDs.

```bash
curl -X POST \
    $APP_URL/apps/capital_agent/users/user_123/sessions/session_abc \
    -H "Content-Type: application/json" \
    -d '{"preferred_language": "English", "visit_count": 5}'
```

#### Run the Agent

Send a prompt to your agent. Replace `capital_agent` with your app name and adjust the user/session IDs and prompt as needed.

```bash
curl -X POST $APP_URL/run_sse \
    -H "Content-Type: application/json" \
    -d '{
    "app_name": "capital_agent",
    "user_id": "user_123",
    "session_id": "session_abc",
    "new_message": {
        "role": "user",
        "parts": [{
        "text": "What is the capital of Canada?"
        }]
    },
    "streaming": false
    }'
```

- Set `"streaming": true` if you want to receive Server-Sent Events (SSE).
- The response will contain the agent's execution events, including the final answer.

## Troubleshooting

These are some common issues you might encounter when deploying your agent to GKE:

### 403 Permission Denied for `Gemini 2.0 Flash`

This usually means that the Kubernetes service account does not have the necessary permission to access the Agent Platform API. Ensure that you have created the service account and bound it to the `Agent Platform User` role as described in the [Configure Kubernetes Service Account for Agent Platform](#configure-kubernetes-service-account-for-agent-platform) section. If you are using AI Studio, ensure that you have set the `GOOGLE_API_KEY` environment variable in the deployment manifest and it is valid.

### 404 or Not Found response

This usually means there is an error in your request. Check the application logs to diagnose the problem.

```bash
export POD_NAME=$(kubectl get pod -l app=adk-agent -o jsonpath='{.items[0].metadata.name}')
kubectl logs $POD_NAME
```

### Attempt to write a readonly database

You might see there is no session id created in the UI and the agent does not respond to any messages. This is usually caused by the SQLite database being read-only. This can happen if you run the agent locally and then create the container image which copies the SQLite database into the container. The database is then read-only in the container.

```bash
sqlalchemy.exc.OperationalError: (sqlite3.OperationalError) attempt to write a readonly database
[SQL: UPDATE app_states SET state=?, update_time=CURRENT_TIMESTAMP WHERE app_states.app_name = ?]
```

To fix this issue, you can either:

Delete the SQLite database file from your local machine before building the container image. This will create a new SQLite database when the container is started.

```bash
rm -f sessions.db
```

or (recommended) you can add a `.dockerignore` file to your project directory to exclude the SQLite database from being copied into the container image.

.dockerignore

```text
sessions.db
```

Build the container image abd deploy the application again.

### Insufficient Permission to Stream Logs `ERROR: (gcloud.builds.submit)`

This error can occur when you don't have sufficient permissions to stream build logs, or your VPC-SC security policy restricts access to the default logs bucket.

To check the progress of the build, follow the link provided in the error message or navigate to the Cloud Build page in the Google Cloud Console.

You can also verify the image was built and pushed to the Artifact Registry using the command under the [Build the container image](#build-the-container-image) section.

### Gemini-2.0-Flash Not Supported in Live Api

When using the ADK Dev UI for your deployed agent, text-based chat works, but voice (e.g., clicking the microphone button) fail. You might see a `websockets.exceptions.ConnectionClosedError` in the pod logs indicating that your model is "not supported in the live api".

This error occurs because the agent is configured with a model (like `gemini-flash-latest` in the example) that does not support the Gemini Live API. The Live API is required for real-time, bidirectional streaming of audio and video.

## Cleanup

To delete the GKE cluster and all associated resources, run:

```bash
gcloud container clusters delete adk-cluster \
    --location=$GOOGLE_CLOUD_LOCATION \
    --project=$GOOGLE_CLOUD_PROJECT
```

To delete the Artifact Registry repository, run:

```bash
gcloud artifacts repositories delete adk-repo \
    --location=$GOOGLE_CLOUD_LOCATION \
    --project=$GOOGLE_CLOUD_PROJECT
```

You can also delete the project if you no longer need it. This will delete all resources associated with the project, including the GKE cluster, Artifact Registry repository, and any other resources you created.

```bash
gcloud projects delete $GOOGLE_CLOUD_PROJECT
```

# Deploy to Agent Runtime

Supported in ADKPython

Google Cloud Agent Platform [Agent Runtime](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview) is a set of modular services that help developers scale and govern agents in production. The Agent Runtime runtime enables you to deploy agents in production with end-to-end managed infrastructure so you can focus on creating intelligent and impactful agents. When you deploy an ADK agent to Agent Runtime, your code runs in the *Agent Runtime runtime* environment, which is part of the larger set of agent services provided by the Agent Runtime product.

This guide includes the following deployment paths, which serve different purposes:

- **[Standard deployment](/deploy/agent-runtime/deploy/)**: Follow this standard deployment path if you want to carefully manage deploying an ADK agent to the Agent Runtime runtime. This deployment path uses Cloud Console, ADK command line interface, and provides step-by-step instructions. This path is recommended for users who are already familiar with configuring Google Cloud projects, and users preparing for production deployments.
- **[Agents CLI deployment](/deploy/agent-runtime/agents-cli/)**: Follow this accelerated deployment path to set up a fully configured Google Cloud environment with CI/CD, infrastructure-as-code, and deployment pipelines for your ADK agent. You need a Google Cloud project with billing enabled. Agents CLI in Agent Platform helps you deploy ADK projects quickly and it includes advanced service configurations that extend the core capabilities of the Agent Runtime runtime for more mature use cases.

Agent Runtime service on Google Cloud

Agent Runtime is a paid service and you may incur costs if you go above the no-cost access tier. More information can be found on the [Agent Runtime pricing page](https://cloud.google.com/vertex-ai/pricing#vertex-ai-agent-engine).

## Deployment payload

When you deploy your ADK agent project to Agent Runtime, the following content is uploaded to the service:

- Your ADK agent code
- Any dependencies declared in your ADK agent code

The deployment *does not* include the ADK API server or the ADK web user interface libraries. The Agent Runtime service provides the libraries for ADK API server functionality.

# Deploy to Agent Runtime with Agents CLI

Supported in ADKPython

This deployment procedure describes how to perform a deployment using [Agents CLI in Agent Platform](https://google.github.io/agents-cli/) and the ADK. Deploying to Agent Runtime via Agents CLI provides an accelerated path to a production-ready environment. Agents CLI automatically configures Google Cloud resources, CI/CD pipelines, and Infrastructure-as-Code (Terraform) to support the entire development lifecycle. As a best practice, always ensure you review the generated configurations to align with your organization’s security and compliance standards before production deployment.

This deployment guide uses Agents CLI to apply a project template to your existing project, add deployment artifacts, and prepare your agent project for deployment. These instructions show you how to use Agents CLI to provision a Google Cloud project with services needed for deploying your ADK project, as follows:

- [Prerequisites](#prerequisites-ad): Set up Google Cloud project, IAM permissions, and install required software.
- [Prepare your ADK project](#prepare-ad): Modify your existing ADK project files to get ready for deployment.
- [Connect to your Google Cloud project](#connect-ad): Connect your development environment to Google Cloud and your Google Cloud project.
- [Deploy your ADK project](#deploy-ad): Provision required services in your Google Cloud project and upload your ADK project code.

For information on testing a deployed agent, see [Test deployed agent](https://adk.dev/deploy/agent-runtime/test/index.md). For more information on using Agents CLI and its command line tools, see the [CLI reference](https://google.github.io/agents-cli/cli/) and [Guide](https://google.github.io/agents-cli/).

### Prerequisites

You need the following resources configured to use this deployment path:

- **Google Cloud Project and Permissions**: A Google Cloud project with [billing enabled](https://cloud.google.com/billing/docs/how-to/modify-project). You can use an existing project or create a new one. You must have one of the following IAM roles assigned within this project:
  - **Agent Platform User role** — sufficient to deploy an agent to Agent Runtime.
  - **Owner role** — required for the full production setup (Terraform infrastructure provisioning, CI/CD pipelines, IAM configuration).

Note

An empty project is recommended to avoid conflicts with existing resources. For new projects, see [Creating and managing projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects).

- **Python Environment**: A Python version supported by [Agents CLI](https://google.github.io/agents-cli/guide/getting-started/).
- **uv Tool:** Manage Python development environment and running agents-cli tools. For installation details, see [Install uv](https://docs.astral.sh/uv/getting-started/installation/).
- **Google Cloud CLI tool**: The gcloud command line interface. For installation details, see [Google Cloud Command Line Interface](https://cloud.google.com/sdk/docs/install).
- **Make tool**: Build automation tool. This tool is part of most Unix-based systems, for installation details, see the [Make tool](https://www.gnu.org/software/make/) documentation.

### Prepare your ADK project

When you deploy an ADK project to Agent Runtime, you need some additional files to support the deployment operation. The following Agents CLI command backs up your project and then adds files to your project for deployment purposes.

These instructions assume you have an existing ADK project that you are modifying for deployment. If you do not have an ADK project, or want to use a test project, complete one of the [Get started](/get-started/) guides, which creates an agent project. The following instructions use the `my_agent` project as an example.

To prepare your ADK project for deployment to Agent Runtime:

1. In a terminal window of your development environment, navigate to the **parent directory** that contains your agent folder. For example, if your project structure is:

   ```text
   your-project-directory/
   ├── my_agent/
   │   ├── __init__.py
   │   ├── agent.py
   │   └── .env
   ```

   Navigate to `your-project-directory/`

1. Run the Agents CLI `scaffold enhance` command to add the files required for deployment into your project.

   ```shell
   agents-cli scaffold enhance --deployment-target agent_engine
   ```

1. Follow the instructions from the Agents CLI tool. In general, you can accept the default answers to all questions. However for the **GCP region**, option, make sure you select one of the [supported regions](https://docs.cloud.google.com/agent-builder/locations#supported-regions-agent-engine) for Agent Runtime.

When you successfully complete this process, the tool shows the following message:

```text
> Success! Your agent project is ready.
```

Note

The Agents CLI tool may show a reminder to connect to Google Cloud while running, but that connection is *not required* at this stage.

For more information about the changes Agents CLI makes to your ADK project, see [Changes to your ADK project](#adk-agents-cli-changes).

### Connect to your Google Cloud project

Before you deploy your ADK project, you must connect to Google Cloud and your project. After logging into your Google Cloud account, you should verify that your deployment target project is visible from your account and that it is configured as your current project.

To connect to Google Cloud and list your project:

1. In a terminal window of your development environment, login to your Google Cloud account:

   ```shell
   gcloud auth application-default login
   ```

1. Set your target project using the Google Cloud Project ID:

   ```shell
   gcloud config set project your-project-id-xxxxx
   ```

1. Verify your Google Cloud target project is set:

   ```shell
   gcloud config get-value project
   ```

Once you have successfully connected to Google Cloud and set your Cloud Project ID, you are ready to deploy your ADK project files to Agent Runtime.

### Deploy your ADK project

When using Agents CLI, you deploy using the `agents-cli deploy` command. This command builds a container from your agent code, pushes it to a registry, and deploys it to Agent Runtime in the hosted environment.

Important

*Make sure your Google Cloud target deployment project is set as your* **current project** *before performing these steps*. The `agents-cli deploy` command uses your currently set Google Cloud project when it performs a deployment. For information on setting and checking your current project, see [Connect to your Google Cloud project](#connect-ad).

To deploy your ADK project to Agent Runtime in your Google Cloud project:

1. In a terminal window, navigate to your agent project directory (e.g., `your-project-directory/`).

1. Deploy your agent code to the Google Cloud development environment:

   ```shell
   agents-cli deploy
   ```

   The command reads your `deployment_target` from `pyproject.toml` and deploys to the configured target (Agent Runtime, Cloud Run, or GKE).

1. (Optional) To enable observability features like prompt-response logging and content logs, provision the telemetry infrastructure:

   ```shell
   agents-cli infra single-project
   ```

   For more details, see the [Observability Guide](https://google.github.io/agents-cli/guide/observability/).

Once this process completes successfully, you should be able to interact with the agent running on Google Cloud Agent Runtime. For details on testing the deployed agent, see [Test deployed agent](/deploy/agent-runtime/test/).

### Changes to your ADK project

The Agents CLI tools add more files to your project for deployment. The procedure below backs up your existing project files before modifying them. This guide uses the [multi_tool_agent](https://github.com/google/adk-docs/tree/main/examples/python/snippets/get-started/multi_tool_agent) project as a reference example. The original project has the following file structure to start with:

```text
my_agent/
├─ __init__.py
├─ agent.py
└─ .env
```

After running the Agents CLI scaffold enhance command to add Agent Runtime deployment information, the new structure is as follows:

```text
my-agent/
├─ app/                 # Core application code
│   ├─ agent.py         # Main agent logic
│   ├─ agent_engine_app.py # Agent Runtime application logic
│   └─ utils/           # Utility functions and helpers
├─ .cloudbuild/         # CI/CD pipeline configurations for Google Cloud Build
├─ deployment/          # Infrastructure and deployment scripts
├─ notebooks/           # Jupyter notebooks for prototyping and evaluation
├─ tests/               # Unit, integration, and load tests
├─ Makefile             # Makefile for common commands
├─ GEMINI.md            # AI-assisted development guide
└─ pyproject.toml       # Project dependencies and configuration
```

See the *README.md* file in your updated ADK project folder for more information. For more information on using Agents CLI, see the [Agents CLI documentation](https://google.github.io/agents-cli/).

## Test deployed agents

After completing deployment of your ADK agent you should test the workflow in its new hosted environment. For more information on testing an ADK agent deployed to Agent Runtime, see [Test deployed agents in Agent Runtime](/deploy/agent-runtime/test/).

# Deploy to Agent Runtime

Supported in ADKPython

This deployment procedure describes how to perform a standard deployment of ADK agent code to Google Cloud [Agent Runtime](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview). You should follow this deployment path if you have an existing Google Cloud project and if you want to carefully manage deploying an ADK agent to Agent Runtime environment. These instructions use Cloud Console, the gcloud command line interface, and the ADK command line interface (ADK CLI). This path is recommended for users who are already familiar with configuring Google Cloud projects, and users preparing for production deployments.

These instructions describe how to deploy an ADK project to Google Cloud Agent Runtime environment, which includes the following stages:

- [Setup Google Cloud project](#setup-cloud-project)
- [Prepare agent project folder](#define-your-agent)
- [Deploy the agent](#deploy-agent)

## Setup Google Cloud project

To deploy your agent to Agent Runtime, you need a Google Cloud project:

1. **Sign into Google Cloud**:

   - If you're an **existing user** of Google Cloud:
     - Sign in via <https://console.cloud.google.com>
     - If you previously used a Free Trial that has expired, you may need to upgrade to a [Paid billing account](https://docs.cloud.google.com/free/docs/free-cloud-features#how-to-upgrade).
   - If you are a **new user** of Google Cloud:
     - You can sign up for the [Free Trial program](https://docs.cloud.google.com/free/docs/free-cloud-features). The Free Trial gets you a $300 Welcome credit to spend over 91 days on various [Google Cloud products](https://docs.cloud.google.com/free/docs/free-cloud-features#during-free-trial) and you won't be billed. During the Free Trial, you also get access to the [Google Cloud Free Tier](https://docs.cloud.google.com/free/docs/free-cloud-features#free-tier), which gives you free usage of select products up to specified monthly limits, and to product-specific free trials.

1. **Create a Google Cloud project**

   - If you already have an existing Google Cloud project, you can use it, but be aware this process is likely to add new services to the project.
   - If you want to create a new Google Cloud project, you can create a new one on the [Create Project](https://console.cloud.google.com/projectcreate) page.

1. **Get your Google Cloud Project ID**

   - You need your Google Cloud Project ID, which you can find on your GCP homepage. Make sure to note the Project ID (alphanumeric with hyphens), *not* the project number (numeric).

1. **Enable Agent Platform in your project**

   - To use Agent Runtime, you need to [enable the Agent Platform API](https://console.cloud.google.com/apis/library/aiplatform.googleapis.com). Click on the "Enable" button to enable the API. Once enabled, it should say "API Enabled".

1. **Enable Cloud Resource Manager API in your project**

   - To use Agent Runtime, you need to [enable the Cloud Resource Manager API](https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com/overview). Click on the "Enable" button to enable the API. Once enabled, it should say "API Enabled".

## Set up your coding environment

Now that you prepared your Google Cloud project, you can return to your coding environment. These steps require access to a terminal within your coding environment to run command line instructions.

### Authenticate your coding environment with Google Cloud

- You need to authenticate your coding environment so that you and your code can interact with Google Cloud. To do so, you need the gcloud CLI. If you have never used the gcloud CLI, you need to first [download and install it](https://docs.cloud.google.com/sdk/docs/install-sdk) before continuing with the steps below:

- Run the following command in your terminal to access your Google Cloud project as a user:

  ```shell
  gcloud auth login
  ```

  After authenticating, you should see the message `You are now authenticated with the gcloud CLI!`.

- Run the following command to authenticate your code so that it can work with Google Cloud:

  ```shell
  gcloud auth application-default login
  ```

  After authenticating, you should see the message `You are now authenticated with the gcloud CLI!`.

- (Optional) If you need to set or change your default project in gcloud, you can use:

  ```shell
  gcloud config set project MY-PROJECT-ID
  ```

### Define your agent

With your Google Cloud and coding environment prepared, you're ready to deploy your agent. The instructions assume that you have an agent project folder, such as:

```shell
multi_tool_agent/
├── .env
├── __init__.py
└── agent.py
```

For more details on the project files and format, see the [multi_tool_agent](https://github.com/google/adk-docs/tree/main/examples/python/snippets/get-started/multi_tool_agent) code sample.

## Deploy the agent

You can deploy from your terminal using the `adk deploy` command line tool. This process packages your code, builds it into a container, and deploys it to the managed Agent Runtime service. This process can take several minutes.

The following example deploy command uses the `multi_tool_agent` sample code as the project to be deployed:

```shell
PROJECT_ID=my-project-id
LOCATION_ID=us-central1

adk deploy agent_engine \
        --project=$PROJECT_ID \
        --region=$LOCATION_ID \
        --display_name="My First Agent" \
        multi_tool_agent
```

For `region`, you can find a list of the supported regions on the [Agent Builder locations page](https://docs.cloud.google.com/agent-builder/locations#supported-regions-agent-engine). To learn about the CLI options for the `adk deploy agent_engine` command, see the [ADK CLI Reference](/api-reference/cli/#adk-deploy-agent-engine).

### Deploy command output

Once successfully deployed, you should see the following output:

```shell
Creating AgentEngine
Create AgentEngine backing LRO: projects/123456789/locations/us-central1/reasoningEngines/751619551677906944/operations/2356952072064073728
View progress and logs at https://console.cloud.google.com/logs/query?project=hopeful-sunset-478017-q0
AgentEngine created. Resource name: projects/123456789/locations/us-central1/reasoningEngines/751619551677906944
To use this AgentEngine in another session:
agent_engine = vertexai.agent_engines.get('projects/123456789/locations/us-central1/reasoningEngines/751619551677906944')
Cleaning up the temp folder: /var/folders/k5/pv70z5m92s30k0n7hfkxszfr00mz24/T/agent_engine_deploy_src/20251219_134245
```

Note that you now have a `RESOURCE_ID` where your agent has been deployed (which in the example above is `751619551677906944`). You need this ID number along with the other values to use your agent on Agent Runtime.

## Using an agent on Agent Runtime

Once you have completed deployment of your ADK project, you can query the agent using the Agent Platform SDK, Python requests library, or a REST API client. This section provides some information on what you need to interact with your agent and how to construct URLs to interact with your agent's REST API.

To interact with your agent on Agent Runtime, you need the following:

- **PROJECT_ID** (example: "my-project-id") which you can find on your [project details page](https://console.cloud.google.com/iam-admin/settings)
- **LOCATION_ID** (example: "us-central1"), that you used to deploy your agent
- **RESOURCE_ID** (example: "751619551677906944"), which you can find on the [Agent Runtime UI](https://console.cloud.google.com/vertex-ai/agents/agent-engines)

The query URL structure is as follows:

```shell
https://$(LOCATION_ID)-aiplatform.googleapis.com/v1/projects/$(PROJECT_ID)/locations/$(LOCATION_ID)/reasoningEngines/$(RESOURCE_ID):query
```

You can make requests from your agent using this URL structure. For more information on how to make requests, see the instructions in the Agent Runtime documentation [Use an Agent Development Kit agent](https://docs.cloud.google.com/agent-builder/agent-engine/use/adk#rest-api). You can also check the Agent Runtime documentation to learn about how to manage your [deployed agent](https://docs.cloud.google.com/agent-builder/agent-engine/manage/overview). For more information on testing and interacting with a deployed agent, see [Test deployed agents in Agent Runtime](/deploy/agent-runtime/test/).

### Monitoring and verification

- You can monitor the deployment status in the [Agent Runtime UI](https://console.cloud.google.com/vertex-ai/agents/agent-engines) in the Google Cloud Console.
- For additional details, you can visit the Agent Runtime documentation [deploying an agent](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/deploy) and [managing deployed agents](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/manage/overview).

## Test deployed agents

After completing deployment of your ADK agent you should test the workflow in its new hosted environment. For more information on testing an ADK agent deployed to Agent Runtime, see [Test deployed agents in Agent Runtime](/deploy/agent-runtime/test/).

# Test deployed agents in Agent Runtime

These instructions explain how to test an ADK agent deployed to the [Agent Runtime](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/overview) runtime environment. Before using these instructions, you need to have completed the deployment of your agent to the Agent Runtime runtime environment using one of the [available methods](/deploy/agent-runtime/). This guide shows you how to view, interact, and test your deployed agent through the Google Cloud Console, and interact with the agent using REST API calls or the Agent Platform SDK for Python.

## View deployed agent in Cloud Console

To view your deployed agent in the Cloud Console:

- Navigate to the Agent Runtime page in the Google Cloud Console: <https://console.cloud.google.com/vertex-ai/agents/agent-engines>

This page lists all deployed agents in your currently selected Google Cloud project. If you do not see your agent listed, make sure you have your target project selected in Google Cloud Console. For more information on selecting an existing Google Cloud project, see [Creating and managing projects](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects).

## Find Google Cloud project information

You need the address and resource identification for your project (`PROJECT_ID`, `LOCATION_ID`, `RESOURCE_ID`) to be able to test your deployment. You can use Cloud Console or the `gcloud` command line tool to find this information.

Agent Platform express mode API key

If you are using Agent Platform express mode, you can skip this step and use your API key.

To find your project information with Google Cloud Console:

1. In the Google Cloud Console, navigate to the Agent Runtime page: <https://console.cloud.google.com/vertex-ai/agents/agent-engines>

1. At the top of the page, select **API URLs**, and then copy the **Query URL** string for your deployed agent, which should be in this format:

   ```text
   https://$(LOCATION_ID)-aiplatform.googleapis.com/v1/projects/$(PROJECT_ID)/locations/$(LOCATION_ID)/reasoningEngines/$(RESOURCE_ID):query
   ```

To find your project information with the `gcloud` command line tool:

1. In your development environment, make sure you are authenticated to Google Cloud and run the following command to list your project:

   ```shell
   gcloud projects list
   ```

1. With the Project ID you used for deployment, run this command to get the additional details:

   ```shell
   gcloud asset search-all-resources \
       --scope=projects/$(PROJECT_ID) \
       --asset-types='aiplatform.googleapis.com/ReasoningEngine' \
       --format="table(name,assetType,location,reasoning_engine_id)"
   ```

## Test using REST calls

A simple way to interact with your deployed agent in Agent Runtime is to use REST calls with the `curl` tool. This section describes how to check your connection to the agent and also to test processing of a request by the deployed agent.

### Check connection to agent

You can check your connection to the running agent using the **Query URL** available in the Agent Runtime section of the Cloud Console. This check does not execute the deployed agent, but returns information about the agent.

To send a REST call and get a response from deployed agent:

- In a terminal window of your development environment, build a request and execute it:

  ```shell
  curl -X GET \
      -H "Authorization: Bearer $(gcloud auth print-access-token)" \
      "https://$(LOCATION_ID)-aiplatform.googleapis.com/v1/projects/$(PROJECT_ID)/locations/$(LOCATION_ID)/reasoningEngines"
  ```

  ```shell
  curl -X GET \
      -H "x-goog-api-key:YOUR-EXPRESS-MODE-API-KEY" \
      "https://aiplatform.googleapis.com/v1/reasoningEngines"
  ```

If your deployment was successful, this request responds with a list of valid requests and expected data formats.

Remove `:query` parameter for connection URL

If you use the **Query URL** available in the Agent Runtime section of the Cloud Console, make sure to remove the `:query` parameter from end of the address.

Access for agent connections

This connection test requires the calling user has a valid access token for the deployed agent. When testing from other environments, make sure the calling user has access to connect to the agent in your Google Cloud project.

### Send an agent request

When getting responses from your agent project, you must first create a session, receive a Session ID, and then send your requests using that Session ID. This process is described in the following instructions.

To test interaction with the deployed agent via REST:

1. In a terminal window of your development environment, create a session by building a request using this template:

   ```shell
   curl \
       -H "Authorization: Bearer $(gcloud auth print-access-token)" \
       -H "Content-Type: application/json" \
       https://$(LOCATION_ID)-aiplatform.googleapis.com/v1/projects/$(PROJECT_ID)/locations/$(LOCATION_ID)/reasoningEngines/$(RESOURCE_ID):query \
       -d '{"class_method": "async_create_session", "input": {"user_id": "u_123"},}'
   ```

   ```shell
   curl \
       -H "x-goog-api-key:YOUR-EXPRESS-MODE-API-KEY" \
       -H "Content-Type: application/json" \
       https://aiplatform.googleapis.com/v1/reasoningEngines/$(RESOURCE_ID):query \
       -d '{"class_method": "async_create_session", "input": {"user_id": "u_123"},}'
   ```

1. In the response from the previous command, extract the created **Session ID** from the **id** field:

   ```json
   {
       "output": {
           "userId": "u_123",
           "lastUpdateTime": 1757690426.337745,
           "state": {},
           "id": "4857885913439920384", # Session ID
           "appName": "9888888855577777776",
           "events": []
       }
   }
   ```

1. In a terminal window of your development environment, send a message to your agent by building a request using this template and the Session ID created in the previous step:

   ```shell
   curl \
   -H "Authorization: Bearer $(gcloud auth print-access-token)" \
   -H "Content-Type: application/json" \
   https://$(LOCATION_ID)-aiplatform.googleapis.com/v1/projects/$(PROJECT_ID)/locations/$(LOCATION_ID)/reasoningEngines/$(RESOURCE_ID):streamQuery?alt=sse -d '{
   "class_method": "async_stream_query",
   "input": {
       "user_id": "u_123",
       "session_id": "4857885913439920384",
       "message": "Hey whats the weather in new york today?",
   }
   }'
   ```

   ```shell
   curl \
   -H "x-goog-api-key:YOUR-EXPRESS-MODE-API-KEY" \
   -H "Content-Type: application/json" \
   https://aiplatform.googleapis.com/v1/reasoningEngines/$(RESOURCE_ID):streamQuery?alt=sse -d '{
   "class_method": "async_stream_query",
   "input": {
       "user_id": "u_123",
       "session_id": "4857885913439920384",
       "message": "Hey whats the weather in new york today?",
   }
   }'
   ```

This request should generate a response from your deployed agent code in JSON format. For more information about interacting with a deployed ADK agent in Agent Runtime using REST calls, see [Manage deployed agents](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/manage/overview#console) and [Use an Agent Development Kit agent](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/use/adk) in the Agent Runtime documentation.

## Test using Python

You can use Python code for more sophisticated and repeatable testing of your agent deployed in Agent Runtime. These instructions describe how to create a session with the deployed agent, and then send a request to the agent for processing.

### Create a remote session

Use the `remote_app` object to create a connection to a deployed, remote agent:

```py
# If you are in a new script or used the ADK CLI to deploy, you can connect like this:
# remote_app = agent_engines.get("your-agent-resource-name")
remote_session = await remote_app.async_create_session(user_id="u_456")
print(remote_session)
```

Expected output for `create_session` (remote):

```console
{'events': [],
'user_id': 'u_456',
'state': {},
'id': '7543472750996750336',
'app_name': '7917477678498709504',
'last_update_time': 1743683353.030133}
```

The `id` value is the session ID, and `app_name` is the resource ID of the deployed agent on Agent Runtime.

#### Send queries to your remote agent

```py
async for event in remote_app.async_stream_query(
    user_id="u_456",
    session_id=remote_session["id"],
    message="whats the weather in new york",
):
    print(event)
```

Expected output for `async_stream_query` (remote):

```console
{'parts': [{'function_call': {'id': 'af-f1906423-a531-4ecf-a1ef-723b05e85321', 'args': {'city': 'new york'}, 'name': 'get_weather'}}], 'role': 'model'}
{'parts': [{'function_response': {'id': 'af-f1906423-a531-4ecf-a1ef-723b05e85321', 'name': 'get_weather', 'response': {'status': 'success', 'report': 'The weather in New York is sunny with a temperature of 25 degrees Celsius (41 degrees Fahrenheit).'}}}], 'role': 'user'}
{'parts': [{'text': 'The weather in New York is sunny with a temperature of 25 degrees Celsius (41 degrees Fahrenheit).'}], 'role': 'model'}
```

For more information about interacting with a deployed ADK agent in Agent Runtime, see [Manage deployed agents](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/manage/overview) and [Use a Agent Development Kit agent](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/use/adk) in the Agent Runtime documentation.

### Sending Multimodal Queries

To send multimodal queries (e.g., including images) to your agent, you can construct the `message` parameter of `async_stream_query` with a list of `types.Part` objects. Each part can be text or an image.

To include an image, you can use `types.Part.from_uri`, providing a Google Cloud Storage (GCS) URI for the image.

```python
from google.genai import types

image_part = types.Part.from_uri(
    file_uri="gs://cloud-samples-data/generative-ai/image/scones.jpg",
    mime_type="image/jpeg",
)
text_part = types.Part.from_text(
    text="What is in this image?",
)

async for event in remote_app.async_stream_query(
    user_id="u_456",
    session_id=remote_session["id"],
    message=[text_part, image_part],
):
    print(event)
```

Note

While the underlying communication with the model may involve Base64 encoding for images, the recommended and supported method for sending image data to an agent deployed on Agent Runtime is by providing a GCS URI.

## Clean up deployments

If you have performed deployments as tests, it is a good practice to clean up your cloud resources after you have finished. You can delete the deployed Agent Runtime instance to avoid any unexpected charges on your Google Cloud account.

```python
remote_app.delete(force=True)
```

The `force=True` parameter also deletes any child resources that were generated from the deployed agent, such as sessions. You can also delete your deployed agent via the [Agent Runtime UI](https://console.cloud.google.com/vertex-ai/agents/agent-engines) on Google Cloud.




