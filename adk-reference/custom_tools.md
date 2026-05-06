# Custom Tools for ADK

Supported in ADKPython v0.1.0Typescript v0.2.0Go v0.1.0Java v0.1.0

In an ADK agent workflow, Tools are programming functions with structured input and output that can be called by an ADK Agent to perform actions. ADK Tools function similarly to how you use a [Function Call](https://ai.google.dev/gemini-api/docs/function-calling) with Gemini or other generative AI models. You can perform various actions and programming functions with an ADK Tool, such as:

- Querying databases
- Making API requests: getting weather data, booking systems
- Searching the web
- Executing code snippets
- Retrieving information from documents (RAG)
- Interacting with other software or services

[ADK Tools and Integrations](/integrations/)

Before building your own tools for ADK, check out the **[ADK Tools and Integrations](/integrations/)** for pre-built tools and integrations you can use with ADK Agents.

## What is a Tool?

In the context of ADK, a Tool represents a specific capability provided to an AI agent, enabling it to perform actions and interact with the world beyond its core text generation and reasoning abilities. What distinguishes capable agents from basic language models is often their effective use of tools.

Technically, a tool is typically a modular code component—**like a Python, Java, or TypeScript function**, a class method, or even another specialized agent—designed to execute a distinct, predefined task. These tasks often involve interacting with external systems or data.

### Key Characteristics

**Action-Oriented:** Tools perform specific actions for an agent, such as searching for information, calling an API, or performing calculations.

**Extends Agent capabilities:** They empower agents to access real-time information, affect external systems, and overcome the knowledge limitations inherent in their training data.

**Execute predefined logic:** Crucially, tools execute specific, developer-defined logic. They do not possess their own independent reasoning capabilities like the agent's core Large Language Model (LLM). The LLM reasons about which tool to use, when, and with what inputs, but the tool itself just executes its designated function.

## How Agents Use Tools

Agents leverage tools dynamically through mechanisms often involving function calling. The process generally follows these steps:

1. **Reasoning:** The agent's LLM analyzes its system instruction, conversation history, and user request.
1. **Selection:** Based on the analysis, the LLM decides on which tool, if any, to execute, based on the tools available to the agent and the docstrings that describes each tool.
1. **Invocation:** The LLM generates the required arguments (inputs) for the selected tool and triggers its execution.
1. **Observation:** The agent receives the output (result) returned by the tool.
1. **Finalization:** The agent incorporates the tool's output into its ongoing reasoning process to formulate the next response, decide the subsequent step, or determine if the goal has been achieved.

Think of the tools as a specialized toolkit that the agent's intelligent core (the LLM) can access and utilize as needed to accomplish complex tasks.

## Tool Types in ADK

ADK offers flexibility by supporting several types of tools:

1. **[Function Tools](/tools-custom/function-tools/):** Tools created by you, tailored to your specific application's needs.
   - **[Functions/Methods](/tools-custom/function-tools/#1-function-tool):** Define standard synchronous functions or methods in your code (e.g., Python def).
   - **[Agents-as-Tools](/tools-custom/function-tools/#3-agent-as-a-tool):** Use another, potentially specialized, agent as a tool for a parent agent.
   - **[Long Running Function Tools](/tools-custom/function-tools/#2-long-running-function-tool):** Support for tools that perform asynchronous operations or take significant time to complete.
1. **[Built-in Tools](/integrations/):** Ready-to-use tools provided by the framework for common tasks. Examples: Google Search, Code Execution, Retrieval-Augmented Generation (RAG).
1. **Third-Party Tools:** Integrate tools seamlessly from popular external libraries.

Navigate to the respective documentation pages linked above for detailed information and examples for each tool type.

## Referencing Tool in Agent’s Instructions

Within an agent's instructions, you can directly reference a tool by using its **function name.** If the tool's **function name** and **docstring** are sufficiently descriptive, your instructions can primarily focus on **when the Large Language Model (LLM) should utilize the tool**. This promotes clarity and helps the model understand the intended use of each tool.

It is **crucial to clearly instruct the agent on how to handle different return values** that a tool might produce. For example, if a tool returns an error message, your instructions should specify whether the agent should retry the operation, give up on the task, or request additional information from the user.

Furthermore, ADK supports the sequential use of tools, where the output of one tool can serve as the input for another. When implementing such workflows, it's important to **describe the intended sequence of tool usage** within the agent's instructions to guide the model through the necessary steps.

### Example

The following example showcases how an agent can use tools by **referencing their function names in its instructions**. It also demonstrates how to guide the agent to **handle different return values from tools**, such as success or error messages, and how to orchestrate the **sequential use of multiple tools** to accomplish a task.

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
from google.adk.tools import FunctionTool
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types

APP_NAME="weather_sentiment_agent"
USER_ID="user1234"
SESSION_ID="1234"
MODEL_ID="gemini-2.0-flash"

# Tool 1
def get_weather_report(city: str) -> dict:
    """Retrieves the current weather report for a specified city.

    Returns:
        dict: A dictionary containing the weather information with a 'status' key ('success' or 'error') and a 'report' key with the weather details if successful, or an 'error_message' if an error occurred.
    """
    if city.lower() == "london":
        return {"status": "success", "report": "The current weather in London is cloudy with a temperature of 18 degrees Celsius and a chance of rain."}
    elif city.lower() == "paris":
        return {"status": "success", "report": "The weather in Paris is sunny with a temperature of 25 degrees Celsius."}
    else:
        return {"status": "error", "error_message": f"Weather information for '{city}' is not available."}

weather_tool = FunctionTool(func=get_weather_report)


# Tool 2
def analyze_sentiment(text: str) -> dict:
    """Analyzes the sentiment of the given text.

    Returns:
        dict: A dictionary with 'sentiment' ('positive', 'negative', or 'neutral') and a 'confidence' score.
    """
    if "good" in text.lower() or "sunny" in text.lower():
        return {"sentiment": "positive", "confidence": 0.8}
    elif "rain" in text.lower() or "bad" in text.lower():
        return {"sentiment": "negative", "confidence": 0.7}
    else:
        return {"sentiment": "neutral", "confidence": 0.6}

sentiment_tool = FunctionTool(func=analyze_sentiment)


# Agent
weather_sentiment_agent = Agent(
    model=MODEL_ID,
    name='weather_sentiment_agent',
    instruction="""You are a helpful assistant that provides weather information and analyzes the sentiment of user feedback.
**If the user asks about the weather in a specific city, use the 'get_weather_report' tool to retrieve the weather details.**
**If the 'get_weather_report' tool returns a 'success' status, provide the weather report to the user.**
**If the 'get_weather_report' tool returns an 'error' status, inform the user that the weather information for the specified city is not available and ask if they have another city in mind.**
**After providing a weather report, if the user gives feedback on the weather (e.g., 'That's good' or 'I don't like rain'), use the 'analyze_sentiment' tool to understand their sentiment.** Then, briefly acknowledge their sentiment.
You can handle these tasks sequentially if needed.""",
    tools=[weather_tool, sentiment_tool]
)

async def main():
    """Main function to run the agent asynchronously."""
    # Session and Runner Setup
    session_service = InMemorySessionService()
    # Use 'await' to correctly create the session
    await session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID)

    runner = Runner(agent=weather_sentiment_agent, app_name=APP_NAME, session_service=session_service)

    # Agent Interaction
    query = "weather in london?"
    print(f"User Query: {query}")
    content = types.Content(role='user', parts=[types.Part(text=query)])

    # The runner's run method handles the async loop internally
    events = runner.run(user_id=USER_ID, session_id=SESSION_ID, new_message=content)

    for event in events:
        if event.is_final_response():
            final_response = event.content.parts[0].text
            print("Agent Response:", final_response)

# Standard way to run the main async function
if __name__ == "__main__":
    asyncio.run(main())
```

```typescript
/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { LlmAgent, FunctionTool, InMemoryRunner, isFinalResponse, stringifyContent } from '@google/adk';
import { z } from "zod";
import { Content, createUserContent } from "@google/genai";

/**
 * Retrieves the current weather report for a specified city.
 */
function getWeatherReport(params: { city: string }): Record<string, any> {
    if (params.city.toLowerCase().includes("london")) {
        return {
            "status": "success",
            "report": "The current weather in London is cloudy with a " +
                "temperature of 18 degrees Celsius and a chance of rain.",
        };
    }
    if (params.city.toLowerCase().includes("paris")) {
        return {
            "status": "success",
            "report": "The weather in Paris is sunny with a temperature of 25 " +
                "degrees Celsius.",
        };
    }
    return {
        "status": "error",
        "error_message": `Weather information for '${params.city}' is not available.`,
    };
}

/**
 * Analyzes the sentiment of a given text.
 */
function analyzeSentiment(params: { text: string }): Record<string, any> {
    if (params.text.includes("cloudy") || params.text.includes("rain")) {
        return { "status": "success", "sentiment": "negative" };
    }
    if (params.text.includes("sunny")) {
        return { "status": "success", "sentiment": "positive" };
    }
    return { "status": "success", "sentiment": "neutral" };
}

const weatherTool = new FunctionTool({
    name: "get_weather_report",
    description: "Retrieves the current weather report for a specified city.",
    parameters: z.object({
        city: z.string().describe("The city to get the weather for."),
    }),
    execute: getWeatherReport,
});

const sentimentTool = new FunctionTool({
    name: "analyze_sentiment",
    description: "Analyzes the sentiment of a given text.",
    parameters: z.object({
        text: z.string().describe("The text to analyze the sentiment of."),
    }),
    execute: analyzeSentiment,
});

const instruction = `
    You are a helpful assistant that first checks the weather and then analyzes
    its sentiment.

    Follow these steps:
    1. Use the 'get_weather_report' tool to get the weather for the requested
       city.
    2. If the 'get_weather_report' tool returns an error, inform the user about
       the error and stop.
    3. If the weather report is available, use the 'analyze_sentiment' tool to
       determine the sentiment of the weather report.
    4. Finally, provide a summary to the user, including the weather report and
       its sentiment.
    `;

const agent = new LlmAgent({
    name: "weather_sentiment_agent",
    instruction: instruction,
    tools: [weatherTool, sentimentTool],
    model: "gemini-2.5-flash"
});

async function main() {

    const runner = new InMemoryRunner({ agent: agent, appName: "weather_sentiment_app" });

    await runner.sessionService.createSession({
        appName: "weather_sentiment_app",
        userId: "user1",
        sessionId: "session1"
    });

    const newMessage: Content = createUserContent("What is the weather in London?");

    for await (const event of runner.runAsync({
        userId: "user1",
        sessionId: "session1",
        newMessage: newMessage,
    })) {
        if (isFinalResponse(event) && event.content?.parts?.length) {
            const text = stringifyContent(event).trim();
            if (text) {
                console.log(text);
            }
        }
    }
}

main();
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
    "strings"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/runner"
    "google.golang.org/adk/session"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/functiontool"
    "google.golang.org/genai"
)

type getWeatherReportArgs struct {
    City string `json:"city" jsonschema:"The city for which to get the weather report."`
}

type getWeatherReportResult struct {
    Status string `json:"status"`
    Report string `json:"report,omitempty"`
}

func getWeatherReport(ctx tool.Context, args getWeatherReportArgs) (getWeatherReportResult, error) {
    if strings.ToLower(args.City) == "london" {
        return getWeatherReportResult{Status: "success", Report: "The current weather in London is cloudy with a temperature of 18 degrees Celsius and a chance of rain."}, nil
    }
    if strings.ToLower(args.City) == "paris" {
        return getWeatherReportResult{Status: "success", Report: "The weather in Paris is sunny with a temperature of 25 degrees Celsius."}, nil
    }
    return getWeatherReportResult{}, fmt.Errorf("weather information for '%s' is not available.", args.City)
}

type analyzeSentimentArgs struct {
    Text string `json:"text" jsonschema:"The text to analyze for sentiment."`
}

type analyzeSentimentResult struct {
    Sentiment  string  `json:"sentiment"`
    Confidence float64 `json:"confidence"`
}

func analyzeSentiment(ctx tool.Context, args analyzeSentimentArgs) (analyzeSentimentResult, error) {
    if strings.Contains(strings.ToLower(args.Text), "good") || strings.Contains(strings.ToLower(args.Text), "sunny") {
        return analyzeSentimentResult{Sentiment: "positive", Confidence: 0.8}, nil
    }
    if strings.Contains(strings.ToLower(args.Text), "rain") || strings.Contains(strings.ToLower(args.Text), "bad") {
        return analyzeSentimentResult{Sentiment: "negative", Confidence: 0.7}, nil
    }
    return analyzeSentimentResult{Sentiment: "neutral", Confidence: 0.6}, nil
}

func main() {
    ctx := context.Background()
    model, err := gemini.NewModel(ctx, "gemini-2.0-flash", &genai.ClientConfig{})
    if err != nil {
        log.Fatal(err)
    }

    weatherTool, err := functiontool.New(
        functiontool.Config{
            Name:        "get_weather_report",
            Description: "Retrieves the current weather report for a specified city.",
        },
        getWeatherReport,
    )
    if err != nil {
        log.Fatal(err)
    }

    sentimentTool, err := functiontool.New(
        functiontool.Config{
            Name:        "analyze_sentiment",
            Description: "Analyzes the sentiment of the given text.",
        },
        analyzeSentiment,
    )
    if err != nil {
        log.Fatal(err)
    }

    weatherSentimentAgent, err := llmagent.New(llmagent.Config{
        Name:        "weather_sentiment_agent",
        Model:       model,
        Instruction: "You are a helpful assistant that provides weather information and analyzes the sentiment of user feedback. **If the user asks about the weather in a specific city, use the 'get_weather_report' tool to retrieve the weather details.** **If the 'get_weather_report' tool returns a 'success' status, provide the weather report to the user.** **If the 'get_weather_report' tool returns an 'error' status, inform the user that the weather information for the specified city is not available and ask if they have another city in mind.** **After providing a weather report, if the user gives feedback on the weather (e.g., 'That's good' or 'I don't like rain'), use the 'analyze_sentiment' tool to understand their sentiment.** Then, briefly acknowledge their sentiment. You can handle these tasks sequentially if needed.",
        Tools:       []tool.Tool{weatherTool, sentimentTool},
    })
    if err != nil {
        log.Fatal(err)
    }

    sessionService := session.InMemoryService()
    runner, err := runner.New(runner.Config{
        AppName:        "weather_sentiment_agent",
        Agent:          weatherSentimentAgent,
        SessionService: sessionService,
    })
    if err != nil {
        log.Fatal(err)
    }

    session, err := sessionService.Create(ctx, &session.CreateRequest{
        AppName: "weather_sentiment_agent",
        UserID:  "user1234",
    })
    if err != nil {
        log.Fatal(err)
    }

    run(ctx, runner, session.Session.ID(), "weather in london?")
    run(ctx, runner, session.Session.ID(), "I don't like rain.")
}

func run(ctx context.Context, r *runner.Runner, sessionID string, prompt string) {
    fmt.Printf("\n> %s\n", prompt)
    events := r.Run(
        ctx,
        "user1234",
        sessionID,
        genai.NewContentFromText(prompt, genai.RoleUser),
        agent.RunConfig{
            StreamingMode: agent.StreamingModeNone,
        },
    )
    for event, err := range events {
        if err != nil {
            log.Fatalf("ERROR during agent execution: %v", err)
        }

        if event.Content.Parts[0].Text != "" {
            fmt.Printf("Agent Response: %s\n", event.Content.Parts[0].Text)
        }
    }
}
```

```java
import com.google.adk.agents.BaseAgent;
import com.google.adk.agents.LlmAgent;
import com.google.adk.runner.Runner;
import com.google.adk.sessions.InMemorySessionService;
import com.google.adk.sessions.Session;
import com.google.adk.tools.Annotations.Schema;
import com.google.adk.tools.FunctionTool;
import com.google.adk.tools.ToolContext; // Ensure this import is correct
import com.google.common.collect.ImmutableList;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

public class WeatherSentimentAgentApp {

  private static final String APP_NAME = "weather_sentiment_agent";
  private static final String USER_ID = "user1234";
  private static final String SESSION_ID = "1234";
  private static final String MODEL_ID = "gemini-2.0-flash";

  /**
   * Retrieves the current weather report for a specified city.
   *
   * @param city The city for which to retrieve the weather report.
   * @param toolContext The context for the tool.
   * @return A dictionary containing the weather information.
   */
  public static Map<String, Object> getWeatherReport(
      @Schema(name = "city")
      String city,
      @Schema(name = "toolContext")
      ToolContext toolContext) {
    Map<String, Object> response = new HashMap<>();

    if (city.toLowerCase(Locale.ROOT).equals("london")) {
      response.put("status", "success");
      response.put(
          "report",
          "The current weather in London is cloudy with a temperature of 18 degrees Celsius and a"
              + " chance of rain.");
    } else if (city.toLowerCase(Locale.ROOT).equals("paris")) {
      response.put("status", "success");
      response.put(
          "report", "The weather in Paris is sunny with a temperature of 25 degrees Celsius.");
    } else {
      response.put("status", "error");
      response.put(
          "error_message", String.format("Weather information for '%s' is not available.", city));
    }
    return response;
  }

  /**
   * Analyzes the sentiment of the given text.
   *
   * @param text The text to analyze.
   * @param toolContext The context for the tool.
   * @return A dictionary with sentiment and confidence score.
   */
  public static Map<String, Object> analyzeSentiment(
      @Schema(name = "text")
      String text,
      @Schema(name = "toolContext")
      ToolContext toolContext) {
    Map<String, Object> response = new HashMap<>();
    String lowerText = text.toLowerCase(Locale.ROOT);
    if (lowerText.contains("good") || lowerText.contains("sunny")) {
      response.put("sentiment", "positive");
      response.put("confidence", 0.8);
    } else if (lowerText.contains("rain") || lowerText.contains("bad")) {
      response.put("sentiment", "negative");
      response.put("confidence", 0.7);
    } else {
      response.put("sentiment", "neutral");
      response.put("confidence", 0.6);
    }
    return response;
  }

  /**
   * Calls the agent with the given query and prints the final response.
   *
   * @param runner The runner to use.
   * @param query The query to send to the agent.
   */
  public static void callAgent(Runner runner, String query) {
    Content content = Content.fromParts(Part.fromText(query));

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

  public static void main(String[] args) throws NoSuchMethodException {
    FunctionTool weatherTool =
        FunctionTool.create(
            WeatherSentimentAgentApp.class.getMethod(
                "getWeatherReport", String.class, ToolContext.class));
    FunctionTool sentimentTool =
        FunctionTool.create(
            WeatherSentimentAgentApp.class.getMethod(
                "analyzeSentiment", String.class, ToolContext.class));

    BaseAgent weatherSentimentAgent =
        LlmAgent.builder()
            .model(MODEL_ID)
            .name("weather_sentiment_agent")
            .description("Weather Sentiment Agent")
            .instruction("""
                    You are a helpful assistant that provides weather information and analyzes the
                    sentiment of user feedback
                    **If the user asks about the weather in a specific city, use the
                    'get_weather_report' tool to retrieve the weather details.**
                    **If the 'get_weather_report' tool returns a 'success' status, provide the
                    weather report to the user.**
                    **If the 'get_weather_report' tool returns an 'error' status, inform the
                    user that the weather information for the specified city is not available
                    and ask if they have another city in mind.**
                    **After providing a weather report, if the user gives feedback on the
                    weather (e.g., 'That's good' or 'I don't like rain'), use the
                    'analyze_sentiment' tool to understand their sentiment.** Then, briefly
                    acknowledge their sentiment.
                    You can handle these tasks sequentially if needed.
                    """)
            .tools(ImmutableList.of(weatherTool, sentimentTool))
            .build();

    InMemorySessionService sessionService = new InMemorySessionService();
    Runner runner = new Runner(weatherSentimentAgent, APP_NAME, null, sessionService);

    // Change the query to ensure the tool is called with a valid city that triggers a "success"
    // response from the tool, like "london" (without the question mark).
    callAgent(runner, "weather in paris");
  }
}
```

## Tool Context

For more advanced scenarios, ADK allows you to access additional contextual information within your tool function by including the special parameter `tool_context: ToolContext`. By including this in the function signature, ADK will **automatically** provide an **instance of the ToolContext** class when your tool is called during agent execution.

The **ToolContext** provides access to several key pieces of information and control levers:

- `state: State`: Read and modify the current session's state. Changes made here are tracked and persisted.
- `actions: EventActions`: Influence the agent's subsequent actions after the tool runs (e.g., skip summarization, transfer to another agent).
- `function_call_id: str`: The unique identifier assigned by the framework to this specific invocation of the tool. Useful for tracking and correlating with authentication responses. This can also be helpful when multiple tools are called within a single model response.
- `function_call_event_id: str`: This attribute provides the unique identifier of the **event** that triggered the current tool call. This can be useful for tracking and logging purposes.
- `auth_response: Any`: Contains the authentication response/credentials if an authentication flow was completed before this tool call.
- Access to Services: Methods to interact with configured services like Artifacts and Memory.

Note that you shouldn't include the `tool_context` parameter in the tool function docstring. Since `ToolContext` is automatically injected by the ADK framework *after* the LLM decides to call the tool function, it is not relevant for the LLM's decision-making and including it can confuse the LLM.

### **State Management**

The `tool_context.state` attribute provides direct read and write access to the state associated with the current session. It behaves like a dictionary but ensures that any modifications are tracked as deltas and persisted by the session service. This enables tools to maintain and share information across different interactions and agent steps.

- **Reading State**: Use standard dictionary access (`tool_context.state['my_key']`) or the `.get()` method (`tool_context.state.get('my_key', default_value)`).

- **Writing State**: Assign values directly (`tool_context.state['new_key'] = 'new_value'`). These changes are recorded in the state_delta of the resulting event.

- **State Prefixes**: Remember the standard state prefixes:

  - `app:*`: Shared across all users of the application.
  - `user:*`: Specific to the current user across all their sessions.
  - (No prefix): Specific to the current session.
  - `temp:*`: Temporary, not persisted across invocations (useful for passing data within a single run call but generally less useful inside a tool context which operates between LLM calls).

```py
from google.adk.tools import ToolContext, FunctionTool

def update_user_preference(preference: str, value: str, tool_context: ToolContext):
    """Updates a user-specific preference."""
    user_prefs_key = "user:preferences"
    # Get current preferences or initialize if none exist
    preferences = tool_context.state.get(user_prefs_key, {})
    preferences[preference] = value
    # Write the updated dictionary back to the state
    tool_context.state[user_prefs_key] = preferences
    print(f"Tool: Updated user preference '{preference}' to '{value}'")
    return {"status": "success", "updated_preference": preference}

pref_tool = FunctionTool(func=update_user_preference)

# In an Agent:
# my_agent = Agent(..., tools=[pref_tool])

# When the LLM calls update_user_preference(preference='theme', value='dark', ...):
# The tool_context.state will be updated, and the change will be part of the
# resulting tool response event's actions.state_delta.
```

```typescript
import { Context } from '@google/adk';

// Updates a user-specific preference.
export function updateUserThemePreference(
  value: string,
  context: Context
): Record<string, any> {
  const userPrefsKey = "user:preferences";

  // Get current preferences or initialize if none exist
  const preferences = context.state.get(userPrefsKey, {}) as Record<string, any>;
  preferences["theme"] = value;

  // Write the updated dictionary back to the state
  context.state.set(userPrefsKey, preferences);
  console.log(
    `Tool: Updated user preference ${userPrefsKey} to ${JSON.stringify(context.state.get(userPrefsKey))}`
  );

  return {
    status: "success",
    updated_preference: context.state.get(userPrefsKey),
  };
  // When the LLM calls updateUserThemePreference("dark"):
  // The context.state will be updated, and the change will be part of the
  // resulting tool response event's actions.stateDelta.
}
```

```go
import (
    "fmt"

    "google.golang.org/adk/tool"
)

type updateUserPreferenceArgs struct {
    Preference string `json:"preference" jsonschema:"The name of the preference to set."`
    Value      string `json:"value" jsonschema:"The value to set for the preference."`
}

type updateUserPreferenceResult struct {
    UpdatedPreference string `json:"updated_preference"`
}

func updateUserPreference(ctx tool.Context, args updateUserPreferenceArgs) (*updateUserPreferenceResult, error) {
    userPrefsKey := "user:preferences"
    val, err := ctx.State().Get(userPrefsKey)
    if err != nil {
        val = make(map[string]any)
    }

    preferencesMap, ok := val.(map[string]any)
    if !ok {
        preferencesMap = make(map[string]any)
    }

    preferencesMap[args.Preference] = args.Value

    if err := ctx.State().Set(userPrefsKey, preferencesMap); err != nil {
        return nil, err
    }

    fmt.Printf("Tool: Updated user preference '%s' to '%s'\n", args.Preference, args.Value)
    return &updateUserPreferenceResult{
        UpdatedPreference: args.Preference,
    }, nil
}
```

```java
import com.google.adk.tools.FunctionTool;
import com.google.adk.tools.ToolContext;

// Updates a user-specific preference.
public Map<String, String> updateUserThemePreference(String value, ToolContext toolContext) {
  String userPrefsKey = "user:preferences:theme";

  // Get current preferences or initialize if none exist
  String preference = toolContext.state().getOrDefault(userPrefsKey, "").toString();
  if (preference.isEmpty()) {
    preference = value;
  }

  // Write the updated dictionary back to the state
  toolContext.state().put("user:preferences", preference);
  System.out.printf("Tool: Updated user preference %s to %s", userPrefsKey, preference);

  return Map.of("status", "success", "updated_preference", toolContext.state().get(userPrefsKey).toString());
  // When the LLM calls updateUserThemePreference("dark"):
  // The toolContext.state will be updated, and the change will be part of the
  // resulting tool response event's actions.stateDelta.
}
```

### **Controlling Agent Flow**

The `tool_context.actions` attribute in Python and TypeScript, `ToolContext.actions()` in Java, and `tool.Context.Actions()` in Go, holds an **EventActions** object. Modifying attributes on this object allows your tool to influence what the agent or framework does after the tool finishes execution.

- **`skip_summarization: bool`**: (Default: False) If set to True, instructs the ADK to bypass the LLM call that typically summarizes the tool's output. This is useful if your tool's return value is already a user-ready message.
- **`transfer_to_agent: str`**: Set this to the name of another agent. The framework will halt the current agent's execution and **transfer control of the conversation to the specified agent**. This allows tools to dynamically hand off tasks to more specialized agents.
- **`escalate: bool`**: (Default: False) Setting this to True signals that the current agent cannot handle the request and should pass control up to its parent agent (if in a hierarchy). In a LoopAgent, setting **escalate=True** in a sub-agent's tool will terminate the loop.

#### Example

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
from google.adk.tools import FunctionTool
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.tools import ToolContext
from google.genai import types

APP_NAME="customer_support_agent"
USER_ID="user1234"
SESSION_ID="1234"


def check_and_transfer(query: str, tool_context: ToolContext) -> str:
    """Checks if the query requires escalation and transfers to another agent if needed."""
    if "urgent" in query.lower():
        print("Tool: Detected urgency, transferring to the support agent.")
        tool_context.actions.transfer_to_agent = "support_agent"
        return "Transferring to the support agent..."
    else:
        return f"Processed query: '{query}'. No further action needed."

escalation_tool = FunctionTool(func=check_and_transfer)

main_agent = Agent(
    model='gemini-2.0-flash',
    name='main_agent',
    instruction="""You are the first point of contact for customer support of an analytics tool. Answer general queries. If the user indicates urgency, use the 'escalation_tool' tool.""",
    tools=[escalation_tool]
)

support_agent = Agent(
    model='gemini-2.0-flash',
    name='support_agent',
    instruction="""You are the dedicated support agent. Mentioned you are a support handler and please help the user with their urgent issue."""
)

main_agent.sub_agents = [support_agent]

# Session and Runner
async def setup_session_and_runner():
    session_service = InMemorySessionService()
    session = await session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID)
    runner = Runner(agent=main_agent, app_name=APP_NAME, session_service=session_service)
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
await call_agent_async("this is urgent, i cant login")
```

```typescript
/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { LlmAgent, FunctionTool, Context, InMemoryRunner, isFinalResponse, stringifyContent } from '@google/adk';
import { z } from "zod";
import { Content, createUserContent } from "@google/genai";

function checkAndTransfer(
  params: { query: string },
  context?: Context
): Record<string, any> {
  if (!context) {
    // This should not happen in a normal ADK flow where the tool is called by an agent.
    throw new Error("Context is required to transfer agents.");
  }
  if (params.query.toLowerCase().includes("urgent")) {
    console.log("Tool: Urgent query detected, transferring to support_agent.");
    context.actions.transferToAgent = "support_agent";
    return { status: "success", message: "Transferring to support agent." };
  }

  console.log("Tool: Query is not urgent, handling normally.");
  return { status: "success", message: "Query will be handled by the main agent." };
}

const transferTool = new FunctionTool({
  name: "check_and_transfer",
  description: "Checks the user's query and transfers to a support agent if urgent.",
  parameters: z.object({
    query: z.string().describe("The user query to analyze."),
  }),
  execute: checkAndTransfer,
});

const supportAgent = new LlmAgent({
  name: "support_agent",
  description: "Handles urgent user requests about accounts.",
  instruction: "You are the support agent. Handle the user's urgent request.",
  model: "gemini-2.5-flash"
});

const mainAgent = new LlmAgent({
  name: "main_agent",
  description: "The main agent that routes non-urgent queries.",
  instruction: "You are the main agent. Use the check_and_transfer tool to analyze the user query. If the query is not urgent, handle it yourself.",
  tools: [transferTool],
  subAgents: [supportAgent],
  model: "gemini-2.5-flash"
});

async function main() {
  const runner = new InMemoryRunner({ agent: mainAgent, appName: "customer_support_app" });

  console.log("--- Running with a non-urgent query ---");
  await runner.sessionService.createSession({ appName: "customer_support_app", userId: "user1", sessionId: "session1" });
  const nonUrgentMessage: Content = createUserContent("I have a general question about my account.");
  for await (const event of runner.runAsync({ userId: "user1", sessionId: "session1", newMessage: nonUrgentMessage })) {
    if (isFinalResponse(event) && event.content?.parts?.length) {
      const text = stringifyContent(event).trim();
      if (text) {
        console.log(`Final Response: ${text}`);
      }
    }
  }

  console.log("\n--- Running with an urgent query ---");
  await runner.sessionService.createSession({ appName: "customer_support_app", userId: "user1", sessionId: "session2" });
  const urgentMessage: Content = createUserContent("My account is locked and this is urgent!");
  for await (const event of runner.runAsync({ userId: "user1", sessionId: "session2", newMessage: urgentMessage })) {
    if (isFinalResponse(event) && event.content?.parts?.length) {
      const text = stringifyContent(event).trim();
      if (text) {
        console.log(`Final Response: ${text}`);
      }
    }
  }
}

main();
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
    "strings"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/runner"
    "google.golang.org/adk/session"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/functiontool"
    "google.golang.org/genai"
)

type checkAndTransferArgs struct {
    Query string `json:"query" jsonschema:"The user's query to check for urgency."`
}

type checkAndTransferResult struct {
    Status string `json:"status"`
}

func checkAndTransfer(ctx tool.Context, args checkAndTransferArgs) (checkAndTransferResult, error) {
    if strings.Contains(strings.ToLower(args.Query), "urgent") {
        fmt.Println("Tool: Detected urgency, transferring to the support agent.")
        ctx.Actions().TransferToAgent = "support_agent"
        return checkAndTransferResult{Status: "Transferring to the support agent..."}, nil
    }
    return checkAndTransferResult{Status: fmt.Sprintf("Processed query: '%s'. No further action needed.", args.Query)}, nil
}

func main() {
    ctx := context.Background()
    model, err := gemini.NewModel(ctx, "gemini-2.0-flash", &genai.ClientConfig{})
    if err != nil {
        log.Fatal(err)
    }

    supportAgent, err := llmagent.New(llmagent.Config{
        Name:        "support_agent",
        Model:       model,
        Instruction: "You are the dedicated support agent. Mentioned you are a support handler and please help the user with their urgent issue.",
    })
    if err != nil {
        log.Fatal(err)
    }

    checkAndTransferTool, err := functiontool.New(
        functiontool.Config{
            Name:        "check_and_transfer",
            Description: "Checks if the query requires escalation and transfers to another agent if needed.",
        },
        checkAndTransfer,
    )
    if err != nil {
        log.Fatal(err)
    }

    mainAgent, err := llmagent.New(llmagent.Config{
        Name:        "main_agent",
        Model:       model,
        Instruction: "You are the first point of contact for customer support of an analytics tool. Answer general queries. If the user indicates urgency, use the 'check_and_transfer' tool.",
        Tools:       []tool.Tool{checkAndTransferTool},
        SubAgents:   []agent.Agent{supportAgent},
    })
    if err != nil {
        log.Fatal(err)
    }

    sessionService := session.InMemoryService()
    runner, err := runner.New(runner.Config{
        AppName:        "customer_support_agent",
        Agent:          mainAgent,
        SessionService: sessionService,
    })
    if err != nil {
        log.Fatal(err)
    }

    session, err := sessionService.Create(ctx, &session.CreateRequest{
        AppName: "customer_support_agent",
        UserID:  "user1234",
    })
    if err != nil {
        log.Fatal(err)
    }

    run(ctx, runner, session.Session.ID(), "this is urgent, i cant login")
}

func run(ctx context.Context, r *runner.Runner, sessionID string, prompt string) {
    fmt.Printf("\n> %s\n", prompt)
    events := r.Run(
        ctx,
        "user1234",
        sessionID,
        genai.NewContentFromText(prompt, genai.RoleUser),
        agent.RunConfig{
            StreamingMode: agent.StreamingModeNone,
        },
    )
    for event, err := range events {
        if err != nil {
            log.Fatalf("ERROR during agent execution: %v", err)
        }

        if event.Content.Parts[0].Text != "" {
            fmt.Printf("Agent Response: %s\n", event.Content.Parts[0].Text)
        }
    }
}
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.runner.Runner;
import com.google.adk.sessions.InMemorySessionService;
import com.google.adk.sessions.Session;
import com.google.adk.tools.Annotations.Schema;
import com.google.adk.tools.FunctionTool;
import com.google.adk.tools.ToolContext;
import com.google.common.collect.ImmutableList;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;

public class CustomerSupportAgentApp {

  private static final String APP_NAME = "customer_support_agent";
  private static final String USER_ID = "user1234";
  private static final String SESSION_ID = "1234";
  private static final String MODEL_ID = "gemini-2.0-flash";

  /**
   * Checks if the query requires escalation and transfers to another agent if needed.
   *
   * @param query The user's query.
   * @param toolContext The context for the tool.
   * @return A map indicating the result of the check and transfer.
   */
  public static Map<String, Object> checkAndTransfer(
      @Schema(name = "query", description = "the user query")
      String query,
      @Schema(name = "toolContext", description = "the tool context")
      ToolContext toolContext) {
    Map<String, Object> response = new HashMap<>();
    if (query.toLowerCase(Locale.ROOT).contains("urgent")) {
      System.out.println("Tool: Detected urgency, transferring to the support agent.");
      toolContext.actions().setTransferToAgent("support_agent");
      response.put("status", "transferring");
      response.put("message", "Transferring to the support agent...");
    } else {
      response.put("status", "processed");
      response.put(
          "message", String.format("Processed query: '%s'. No further action needed.", query));
    }
    return response;
  }

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
    // Fixed: session ID does not need to be an optional.
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

  public static void main(String[] args) throws NoSuchMethodException {
    FunctionTool escalationTool =
        FunctionTool.create(
            CustomerSupportAgentApp.class.getMethod(
                "checkAndTransfer", String.class, ToolContext.class));

    LlmAgent supportAgent =
        LlmAgent.builder()
            .model(MODEL_ID)
            .name("support_agent")
            .description("""
                The dedicated support agent.
                Mentions it is a support handler and helps the user with their urgent issue.
            """)
            .instruction("""
                You are the dedicated support agent.
                Mentioned you are a support handler and please help the user with their urgent issue.
            """)
            .build();

    LlmAgent mainAgent =
        LlmAgent.builder()
            .model(MODEL_ID)
            .name("main_agent")
            .description("""
                The first point of contact for customer support of an analytics tool.
                Answers general queries.
                If the user indicates urgency, uses the 'check_and_transfer' tool.
                """)
            .instruction("""
                You are the first point of contact for customer support of an analytics tool.
                Answer general queries.
                If the user indicates urgency, use the 'check_and_transfer' tool.
                """)
            .tools(ImmutableList.of(escalationTool))
            .subAgents(supportAgent)
            .build();
    // Fixed: LlmAgent.subAgents() expects 0 arguments.
    // Sub-agents are now added to the main agent via its builder,
    // as `subAgents` is a property that should be set during agent construction
    // if it's not dynamically managed.

    InMemorySessionService sessionService = new InMemorySessionService();
    Runner runner = new Runner(mainAgent, APP_NAME, null, sessionService);

    // Agent Interaction
    callAgent(runner, "this is urgent, i cant login");
  }
}
```

##### Explanation

- We define two agents: `main_agent` and `support_agent`. The `main_agent` is designed to be the initial point of contact.
- The `check_and_transfer` tool, when called by `main_agent`, examines the user's query.
- If the query contains the word "urgent", the tool accesses the `tool_context`, specifically **`tool_context.actions`**, and sets the transfer_to_agent attribute to `support_agent`.
- This action signals to the framework to **transfer the control of the conversation to the agent named `support_agent`**.
- When the `main_agent` processes the urgent query, the `check_and_transfer` tool triggers the transfer. The subsequent response would ideally come from the `support_agent`.
- For a normal query without urgency, the tool simply processes it without triggering a transfer.

This example illustrates how a tool, through EventActions in its ToolContext, can dynamically influence the flow of the conversation by transferring control to another specialized agent.

### **Authentication**

ToolContext provides mechanisms for tools interacting with authenticated APIs. If your tool needs to handle authentication, you might use the following:

- **`auth_response`** (in Python): Contains credentials (e.g., a token) if authentication was already handled by the framework before your tool was called (common with RestApiTool and OpenAPI security schemes). In TypeScript, this is retrieved via the getAuthResponse() method.
- **`request_credential(auth_config: dict)`** (in Python) or **`requestCredential(authConfig: AuthConfig)`** (in TypeScript): Call this method if your tool determines authentication is needed but credentials aren't available. This signals the framework to start an authentication flow based on the provided auth_config.
- **`get_auth_response()`** (in Python) or **`getAuthResponse(authConfig: AuthConfig)`** (in TypeScript): Call this in a subsequent invocation (after request_credential was successfully handled) to retrieve the credentials the user provided.

For detailed explanations of authentication flows, configuration, and examples, please refer to the dedicated Tool Authentication documentation page.

### **Context-Aware Data Access Methods**

These methods provide convenient ways for your tool to interact with persistent data associated with the session or user, managed by configured services.

- **`list_artifacts()`** (in Python) or **`listArtifacts()`** (in Java and TypeScript): Returns a list of filenames (or keys) for all artifacts currently stored for the session via the artifact_service. Artifacts are typically files (images, documents, etc.) uploaded by the user or generated by tools/agents.
- **`load_artifact(filename: str)`**: Retrieves a specific artifact by its filename from the **artifact_service**. You can optionally specify a version; if omitted, the latest version is returned. Returns a `google.genai.types.Part` object containing the artifact data and mime type, or None if not found.
- **`save_artifact(filename: str, artifact: types.Part)`**: Saves a new version of an artifact to the artifact_service. Returns the new version number (starting from 0).
- **`search_memory(query: str)`**: (Support in ADK Python, Go and TypeScript) Queries the user's long-term memory using the configured `memory_service`. This is useful for retrieving relevant information from past interactions or stored knowledge. The structure of the **SearchMemoryResponse** depends on the specific memory service implementation but typically contains relevant text snippets or conversation excerpts.

#### Example

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

from google.adk.tools import ToolContext, FunctionTool
from google.genai import types


def process_document(
    document_name: str, analysis_query: str, tool_context: ToolContext
) -> dict:
    """Analyzes a document using context from memory."""

    # 1. Load the artifact
    print(f"Tool: Attempting to load artifact: {document_name}")
    document_part = tool_context.load_artifact(document_name)

    if not document_part:
        return {"status": "error", "message": f"Document '{document_name}' not found."}

    document_text = document_part.text  # Assuming it's text for simplicity
    print(f"Tool: Loaded document '{document_name}' ({len(document_text)} chars).")

    # 2. Search memory for related context
    print(f"Tool: Searching memory for context related to: '{analysis_query}'")
    memory_response = tool_context.search_memory(
        f"Context for analyzing document about {analysis_query}"
    )
    memory_context = "\n".join(
        [
            m.events[0].content.parts[0].text
            for m in memory_response.memories
            if m.events and m.events[0].content
        ]
    )  # Simplified extraction
    print(f"Tool: Found memory context: {memory_context[:100]}...")

    # 3. Perform analysis (placeholder)
    analysis_result = f"Analysis of '{document_name}' regarding '{analysis_query}' using memory context: [Placeholder Analysis Result]"
    print("Tool: Performed analysis.")

    # 4. Save the analysis result as a new artifact
    analysis_part = types.Part.from_text(text=analysis_result)
    new_artifact_name = f"analysis_{document_name}"
    version = await tool_context.save_artifact(new_artifact_name, analysis_part)
    print(f"Tool: Saved analysis result as '{new_artifact_name}' version {version}.")

    return {
        "status": "success",
        "analysis_artifact": new_artifact_name,
        "version": version,
    }


doc_analysis_tool = FunctionTool(func=process_document)

# In an Agent:
# Assume artifact 'report.txt' was previously saved.
# Assume memory service is configured and has relevant past data.
# my_agent = Agent(..., tools=[doc_analysis_tool], artifact_service=..., memory_service=...)
```

```typescript
import { Part } from "@google/genai";
import { Context } from '@google/adk';

// Analyzes a document using context from memory.
export async function processDocument(
  params: { documentName: string; analysisQuery: string },
  context?: Context
): Promise<Record<string, any>> {
  if (!context) {
    throw new Error("Context is required for this tool.");
  }

  // 1. List all available artifacts
  const artifacts = await context.listArtifacts();
  console.log(`Listing all available artifacts: ${artifacts}`);

  // 2. Load an artifact
  console.log(`Tool: Attempting to load artifact: ${params.documentName}`);
  const documentPart = await context.loadArtifact(params.documentName);
  if (!documentPart) {
    console.log(`Tool: Document '${params.documentName}' not found.`);
    return {
      status: "error",
      message: `Document '${params.documentName}' not found.`, 
    };
  }

  const documentText = documentPart.text ?? "";
  console.log(
    `Tool: Loaded document '${params.documentName}' (${documentText.length} chars).`
  );

  // 3. Search memory for related context
  console.log(`Tool: Searching memory for context related to '${params.analysisQuery}'`);
  const memory_results = await context.searchMemory(params.analysisQuery);
  console.log(`Tool: Found ${memory_results.memories.length} relevant memories.`);
  const context_from_memory = memory_results.memories
    .map((m) => m.content.parts[0].text)
    .join("\n");

  // 4. Perform analysis (placeholder)
  const analysisResult =
    `Analysis of '${params.documentName}' regarding '${params.analysisQuery}':\n` +
    `Context from Memory:\n${context_from_memory}\n` +
    `[Placeholder Analysis Result]`;
  console.log("Tool: Performed analysis.");

  // 5. Save the analysis result as a new artifact
  const analysisPart: Part = { text: analysisResult };
  const newArtifactName = `analysis_${params.documentName}`;
  await context.saveArtifact(newArtifactName, analysisPart);
  console.log(`Tool: Saved analysis result to '${newArtifactName}'.`);

  return {
    status: "success",
    analysis_artifact: newArtifactName,
  };
}
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
    "fmt"

    "google.golang.org/adk/tool"
    "google.golang.org/genai"
)

type processDocumentArgs struct {
    DocumentName  string `json:"document_name" jsonschema:"The name of the document to be processed."`
    AnalysisQuery string `json:"analysis_query" jsonschema:"The query for the analysis."`
}

type processDocumentResult struct {
    Status           string `json:"status"`
    AnalysisArtifact string `json:"analysis_artifact,omitempty"`
    Version          int64  `json:"version,omitempty"`
    Message          string `json:"message,omitempty"`
}

func processDocument(ctx tool.Context, args processDocumentArgs) (*processDocumentResult, error) {
    fmt.Printf("Tool: Attempting to load artifact: %s\n", args.DocumentName)

    // List all artifacts
    listResponse, err := ctx.Artifacts().List(ctx)
    if err != nil {
        return nil, fmt.Errorf("failed to list artifacts")
    }

    fmt.Println("Tool: Available artifacts:")
    for _, file := range listResponse.FileNames {
        fmt.Printf(" - %s\n", file)
    }

    documentPart, err := ctx.Artifacts().Load(ctx, args.DocumentName)
    if err != nil {
        return nil, fmt.Errorf("document '%s' not found", args.DocumentName)
    }

    fmt.Printf("Tool: Loaded document '%s' of size %d bytes.\n", args.DocumentName, len(documentPart.Part.InlineData.Data))

    // 3. Search memory for related context
    fmt.Printf("Tool: Searching memory for context related to: '%s'\n", args.AnalysisQuery)
    memoryResp, err := ctx.SearchMemory(ctx, args.AnalysisQuery)
    if err != nil {
        fmt.Printf("Tool: Error searching memory: %v\n", err)
    }
    memoryResultCount := 0
    if memoryResp != nil {
        memoryResultCount = len(memoryResp.Memories)
    }
    fmt.Printf("Tool: Found %d memory results.\n", memoryResultCount)

    analysisResult := fmt.Sprintf("Analysis of '%s' regarding '%s' using memory context: [Placeholder Analysis Result]", args.DocumentName, args.AnalysisQuery)
    fmt.Println("Tool: Performed analysis.")

    analysisPart := genai.NewPartFromText(analysisResult)
    newArtifactName := fmt.Sprintf("analysis_%s", args.DocumentName)
    version, err := ctx.Artifacts().Save(ctx, newArtifactName, analysisPart)
    if err != nil {
        return nil, fmt.Errorf("failed to save artifact")
    }
    fmt.Printf("Tool: Saved analysis result as '%s' version %d.\n", newArtifactName, version.Version)

    return &processDocumentResult{
        Status:           "success",
        AnalysisArtifact: newArtifactName,
        Version:          version.Version,
    }, nil
}
```

```java
// Analyzes a document using context from memory.
// You can also list, load and save artifacts using Callback Context or LoadArtifacts tool.
public static @NonNull Maybe<ImmutableMap<String, Object>> processDocument(
    @Annotations.Schema(description = "The name of the document to analyze.") String documentName,
    @Annotations.Schema(description = "The query for the analysis.") String analysisQuery,
    ToolContext toolContext) {

  // 1. List all available artifacts
  System.out.printf(
      "Listing all available artifacts %s:", toolContext.listArtifacts().blockingGet());

  // 2. Load an artifact to memory
  System.out.println("Tool: Attempting to load artifact: " + documentName);
  Part documentPart = toolContext.loadArtifact(documentName, Optional.empty()).blockingGet();
  if (documentPart == null) {
    System.out.println("Tool: Document '" + documentName + "' not found.");
    return Maybe.just(
        ImmutableMap.<String, Object>of(
            "status", "error", "message", "Document '" + documentName + "' not found."));
  }
  String documentText = documentPart.text().orElse("");
  System.out.println(
      "Tool: Loaded document '" + documentName + "' (" + documentText.length() + " chars).");

  // 3. Perform analysis (placeholder)
  String analysisResult =
      "Analysis of '"
          + documentName
          + "' regarding '"
          + analysisQuery
          + " [Placeholder Analysis Result]";
  System.out.println("Tool: Performed analysis.");

  // 4. Save the analysis result as a new artifact
  Part analysisPart = Part.fromText(analysisResult);
  String newArtifactName = "analysis_" + documentName;

  toolContext.saveArtifact(newArtifactName, analysisPart);

  return Maybe.just(
      ImmutableMap.<String, Object>builder()
          .put("status", "success")
          .put("analysis_artifact", newArtifactName)
          .build());
}
// FunctionTool processDocumentTool =
//      FunctionTool.create(ToolContextArtifactExample.class, "processDocument");
// In the Agent, include this function tool.
// LlmAgent agent = LlmAgent().builder().tools(processDocumentTool).build();
```

By leveraging the **ToolContext**, developers can create more sophisticated and context-aware custom tools that seamlessly integrate with ADK's architecture and enhance the overall capabilities of their agents.

## Defining Effective Tool Functions

When using a method or function as an ADK Tool, how you define it significantly impacts the agent's ability to use it correctly. The agent's Large Language Model (LLM) relies heavily on the function's **name**, **parameters (arguments)**, **type hints**, and **docstring** / **source code comments** to understand its purpose and generate the correct call.

Here are key guidelines for defining effective tool functions:

- **Function Name:**

  - Use descriptive, verb-noun based names that clearly indicate the action (e.g., `get_weather`, `searchDocuments`, `schedule_meeting`).
  - Avoid generic names like `run`, `process`, `handle_data`, or overly ambiguous names like `doStuff`. Even with a good description, a name like `do_stuff` might confuse the model about when to use the tool versus, for example, `cancelFlight`.
  - The LLM uses the function name as a primary identifier during tool selection.

- **Parameters (Arguments):**

  - Your function can have any number of parameters.
  - Use clear and descriptive names (e.g., `city` instead of `c`, `search_query` instead of `q`).
  - **Provide type hints in Python** for all parameters (e.g., `city: str`, `user_id: int`, `items: list[str]`). This is essential for ADK to generate the correct schema for the LLM.
  - Ensure all parameter types are **JSON serializable**. All java primitives as well as standard Python types like `str`, `int`, `float`, `bool`, `list`, `dict`, and their combinations are generally safe. Avoid complex custom class instances as direct parameters unless they have a clear JSON representation.
  - **Do not set default values** for parameters. E.g., `def my_func(param1: str = "default")`. Default values are not reliably supported or used by the underlying models during function call generation. All necessary information should be derived by the LLM from the context or explicitly requested if missing.
  - **`self` / `cls` Handled Automatically:** Implicit parameters like `self` (for instance methods) or `cls` (for class methods) are automatically handled by ADK and excluded from the schema shown to the LLM. You only need to define type hints and descriptions for the logical parameters your tool requires the LLM to provide.

- **Return Type:**

  - The function's return value **must be a dictionary (`dict`)** in Python, a **Map** in Java, or a plain **object** in TypeScript.
  - If your function returns a non-dictionary type (e.g., a string, number, list), the ADK framework will automatically wrap it into a dictionary/Map like `{'result': your_original_return_value}` before passing the result back to the model.
  - Design the dictionary/Map keys and values to be **descriptive and easily understood *by the LLM***. Remember, the model reads this output to decide its next step.
  - Include meaningful keys. For example, instead of returning just an error code like `500`, return `{'status': 'error', 'error_message': 'Database connection failed'}`.
  - It's a **highly recommended practice** to include a `status` key (e.g., `'success'`, `'error'`, `'pending'`, `'ambiguous'`) to clearly indicate the outcome of the tool execution for the model.

- **Docstring / Source Code Comments:**

  - **This is critical.** The docstring is the primary source of descriptive information for the LLM.
  - **Clearly state what the tool *does*.** Be specific about its purpose and limitations.
  - **Explain *when* the tool should be used.** Provide context or example scenarios to guide the LLM's decision-making.
  - **Describe *each parameter* clearly.** Explain what information the LLM needs to provide for that argument.
  - Describe the **structure and meaning of the expected `dict` return value**, especially the different `status` values and associated data keys.
  - **Do not describe the injected ToolContext parameter**. Avoid mentioning the optional `tool_context: ToolContext` parameter within the docstring description since it is not a parameter the LLM needs to know about. ToolContext is injected by ADK, *after* the LLM decides to call it.

  **Example of a good definition:**

```python
def lookup_order_status(order_id: str) -> dict:
  """Fetches the current status of a customer's order using its ID.

  Use this tool ONLY when a user explicitly asks for the status of
  a specific order and provides the order ID. Do not use it for
  general inquiries.

  Args:
      order_id: The unique identifier of the order to look up.

  Returns:
      A dictionary indicating the outcome.
      On success, status is 'success' and includes an 'order' dictionary.
      On failure, status is 'error' and includes an 'error_message'.
      Example success: {'status': 'success', 'order': {'state': 'shipped', 'tracking_number': '1Z9...'}}
      Example error: {'status': 'error', 'error_message': 'Order ID not found.'}
  """
  # ... function implementation to fetch status ...
  if status_details := fetch_status_from_backend(order_id):
    return {
        "status": "success",
        "order": {
            "state": status_details.state,
            "tracking_number": status_details.tracking,
        },
    }
  else:
    return {"status": "error", "error_message": f"Order ID {order_id} not found."}
```

```typescript
/**
 * Fetches the current status of a customer's order using its ID.
 *
 * Use this tool ONLY when a user explicitly asks for the status of
 * a specific order and provides the order ID. Do not use it for
 * general inquiries.
 *
 * @param params The parameters for the function.
 * @param params.order_id The unique identifier of the order to look up.
 * @returns A dictionary indicating the outcome.
 *          On success, status is 'success' and includes an 'order' dictionary.
 *          On failure, status is 'error' and includes an 'error_message'.
 *          Example success: {'status': 'success', 'order': {'state': 'shipped', 'tracking_number': '1Z9...'}}
 *          Example error: {'status': 'error', 'error_message': 'Order ID not found.'}
 */
async function lookupOrderStatus(params: { order_id: string }): Promise<Record<string, any>> {
  // ... function implementation to fetch status from a backend ...
  const status_details = await fetchStatusFromBackend(params.order_id);
  if (status_details) {
    return {
      "status": "success",
      "order": {
        "state": status_details.state,
        "tracking_number": status_details.tracking,
      },
    };
  } else {
    return { "status": "error", "error_message": `Order ID ${params.order_id} not found.` };
  }
}

// Placeholder for a backend call
async function fetchStatusFromBackend(order_id: string): Promise<{state: string, tracking: string} | null> {
    if (order_id === "12345") {
        return { state: "shipped", tracking: "1Z9..." };
    }
    return null;
}
```

```go
import (
    "fmt"

    "google.golang.org/adk/tool"
)

type lookupOrderStatusArgs struct {
    OrderID string `json:"order_id" jsonschema:"The ID of the order to look up."`
}

type order struct {
    State          string `json:"state"`
    TrackingNumber string `json:"tracking_number"`
}

type lookupOrderStatusResult struct {
    Status string `json:"status"`
    Order  order  `json:"order,omitempty"`
}

func lookupOrderStatus(ctx tool.Context, args lookupOrderStatusArgs) (*lookupOrderStatusResult, error) {
    // ... function implementation to fetch status ...
    statusDetails, ok := fetchStatusFromBackend(args.OrderID)
    if !ok {
        return nil, fmt.Errorf("order ID %s not found", args.OrderID)
    }
    return &lookupOrderStatusResult{
        Status: "success",
        Order: order{
            State:          statusDetails.State,
            TrackingNumber: statusDetails.Tracking,
        },
    }, nil
}
```

```java
/**
 * Retrieves the current weather report for a specified city.
 *
 * @param city The city for which to retrieve the weather report.
 * @param toolContext The context for the tool.
 * @return A dictionary containing the weather information.
 */
public static Map<String, Object> getWeatherReport(String city, ToolContext toolContext) {
    Map<String, Object> response = new HashMap<>();
    if (city.toLowerCase(Locale.ROOT).equals("london")) {
        response.put("status", "success");
        response.put(
                "report",
                "The current weather in London is cloudy with a temperature of 18 degrees Celsius and a"
                        + " chance of rain.");
    } else if (city.toLowerCase(Locale.ROOT).equals("paris")) {
        response.put("status", "success");
        response.put("report", "The weather in Paris is sunny with a temperature of 25 degrees Celsius.");
    } else {
        response.put("status", "error");
        response.put("error_message", String.format("Weather information for '%s' is not available.", city));
    }
    return response;
}
```

- **Simplicity and Focus:**
  - **Keep Tools Focused:** Each tool should ideally perform one well-defined task.
  - **Fewer Parameters are Better:** Models generally handle tools with fewer, clearly defined parameters more reliably than those with many optional or complex ones.
  - **Use Simple Data Types:** Prefer basic types (`str`, `int`, `bool`, `float`, `List[str]`, in **Python**; `int`, `byte`, `short`, `long`, `float`, `double`, `boolean` and `char` in **Java**; or `string`, `number`, `boolean`, and arrays like `string[]` in **TypeScript**) over complex custom classes or deeply nested structures as parameters when possible.
  - **Decompose Complex Tasks:** Break down functions that perform multiple distinct logical steps into smaller, more focused tools. For instance, instead of a single `update_user_profile(profile: ProfileObject)` tool, consider separate tools like `update_user_name(name: str)`, `update_user_address(address: str)`, `update_user_preferences(preferences: list[str])`, etc. This makes it easier for the LLM to select and use the correct capability.

By adhering to these guidelines, you provide the LLM with the clarity and structure it needs to effectively utilize your custom function tools, leading to more capable and reliable agent behavior.

## Toolsets: Grouping and Dynamically Providing Tools

Supported in ADKPython v0.5.0Typescript v0.2.0

Beyond individual tools, ADK introduces the concept of a **Toolset** via the `BaseToolset` interface (defined in `google.adk.tools.base_toolset`). A toolset allows you to manage and provide a collection of `BaseTool` instances, often dynamically, to an agent.

This approach is beneficial for:

- **Organizing Related Tools:** Grouping tools that serve a common purpose (e.g., all tools for mathematical operations, or all tools interacting with a specific API).
- **Dynamic Tool Availability:** Enabling an agent to have different tools available based on the current context (e.g., user permissions, session state, or other runtime conditions). The `get_tools` method of a toolset can decide which tools to expose.
- **Integrating External Tool Providers:** Toolsets can act as adapters for tools coming from external systems, like an OpenAPI specification or an MCP server, converting them into ADK-compatible `BaseTool` objects.

### The `BaseToolset` Interface

Any class acting as a toolset in ADK should implement the `BaseToolset` abstract base class. This interface primarily defines two methods:

- **`async def get_tools(...) -> list[BaseTool]:`** This is the core method of a toolset. When an ADK agent needs to know its available tools, it will call `get_tools()` on each `BaseToolset` instance provided in its `tools` list.

  - It receives an optional `readonly_context` (an instance of `ReadonlyContext`). This context provides read-only access to information like the current session state (`readonly_context.state`), agent name, and invocation ID. The toolset can use this context to dynamically decide which tools to return.
  - It **must** return a `list` of `BaseTool` instances (e.g., `FunctionTool`, `RestApiTool`).

- **`async def close(self) -> None:`** This asynchronous method is called by the ADK framework when the toolset is no longer needed, for example, when an agent server is shutting down or the `Runner` is being closed. Implement this method to perform any necessary cleanup, such as closing network connections, releasing file handles, or cleaning up other resources managed by the toolset.

### Using Toolsets with Agents

You can include instances of your `BaseToolset` implementations directly in an `LlmAgent`'s `tools` list, alongside individual `BaseTool` instances.

When the agent initializes or needs to determine its available capabilities, the ADK framework will iterate through the `tools` list:

- If an item is a `BaseTool` instance, it's used directly.
- If an item is a `BaseToolset` instance, its `get_tools()` method is called (with the current `ReadonlyContext`), and the returned list of `BaseTool`s is added to the agent's available tools.

### Example: A Simple Math Toolset

Let's create a basic example of a toolset that provides simple arithmetic operations.

```py
import asyncio
from typing import Optional, List, Dict, Any

from google.adk.agents import LlmAgent
from google.adk.agents.readonly_context import ReadonlyContext
from google.adk.tools import BaseTool, FunctionTool
from google.adk.tools.base_toolset import BaseToolset
from google.adk.tools.tool_context import ToolContext
from google.adk.runners import InMemoryRunner


# 1. Define the individual tool functions
def add_numbers(a: int, b: int, tool_context: ToolContext) -> Dict[str, Any]:
    """Adds two integer numbers.
    Args:
        a: The first number.
        b: The second number.
    Returns:
        A dictionary with the sum, e.g., {'status': 'success', 'result': 5}
    """
    print(f"Tool: add_numbers called with a={a}, b={b}")
    result = a + b
    # Example: Storing something in tool_context state
    tool_context.state["last_math_operation"] = "addition"
    return {"status": "success", "result": result}


def subtract_numbers(a: int, b: int) -> Dict[str, Any]:
    """Subtracts the second number from the first.
    Args:
        a: The first number.
        b: The second number.
    Returns:
        A dictionary with the difference, e.g., {'status': 'success', 'result': 1}
    """
    print(f"Tool: subtract_numbers called with a={a}, b={b}")
    return {"status": "success", "result": a - b}


# 2. Create the Toolset by implementing BaseToolset
class SimpleMathToolset(BaseToolset):
    def __init__(self, prefix: str = "math"):
        self.prefix = prefix
        super().__init__(tool_name_prefix=self.prefix) # Toolset can customize names by passing a prefix

        # Create FunctionTool instances once
        self._add_tool = FunctionTool(
            func=add_numbers,
        )
        self._subtract_tool = FunctionTool(
            func=subtract_numbers,
        )
        print(f"SimpleMathToolset initialized with prefix '{self.prefix}'")

    async def get_tools(
        self, readonly_context: Optional[ReadonlyContext] = None
    ) -> List[BaseTool]:
        print("SimpleMathToolset.get_tools() called.")
        # Example of dynamic behavior:
        # Could use readonly_context.state to decide which tools to return
        # For instance, if readonly_context.state.get("enable_advanced_math"):
        #    return [self._add_tool, self._subtract_tool, self._multiply_tool]

        # For this simple example, always return both tools
        tools_to_return = [self._add_tool, self._subtract_tool]
        print(f"SimpleMathToolset providing tools: {[t.name for t in tools_to_return]}")
        return tools_to_return

    async def close(self) -> None:
        # No resources to clean up in this simple example
        print(f"SimpleMathToolset.close() called for prefix '{self.prefix}'.")
        await asyncio.sleep(0)  # Placeholder for async cleanup if needed


# 3. Define an individual tool (not part of the toolset)
def greet_user(name: str = "User") -> Dict[str, str]:
    """Greets the user."""
    print(f"Tool: greet_user called with name={name}")
    return {"greeting": f"Hello, {name}!"}


greet_tool = FunctionTool(func=greet_user)

# 4. Instantiate the toolset
math_toolset_instance = SimpleMathToolset(prefix="calculator")

# 5. Define an agent that uses both the individual tool and the toolset
calculator_agent = LlmAgent(
    name="CalculatorAgent",
    model="gemini-flash-latest",  # Replace with your desired model
    instruction="You are a helpful calculator and greeter. "
    "Use 'greet_user' for greetings. "
    "Use 'calculator_add_numbers' to add and 'calculator_subtract_numbers' to subtract. "
    "Announce the state of 'last_math_operation' if it's set.",
    tools=[greet_tool, math_toolset_instance],  # Individual tool  # Toolset instance
)

# 6. Run the agent
runner = InMemoryRunner(agent=calculator_agent, app_name="toolset_example_app")

async def main():
    print("\n--- Query 1: Greeting ---")
    await runner.run_debug("Hi there!")
    print("\n--- Query 2: Addition ---")
    await runner.run_debug("What is 5 plus 3?")
    await math_toolset_instance.close()

if __name__ == "__main__":
    asyncio.run(main())
```

```typescript
/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { LlmAgent, FunctionTool, Context, BaseToolset, InMemoryRunner, isFinalResponse, BaseTool, stringifyContent } from '@google/adk';
import { z } from "zod";
import { Content, createUserContent } from "@google/genai";

function addNumbers(params: { a: number; b: number }, context?: Context): Record<string, any> {
  if (!context) {
    throw new Error("Context is required for this tool.");
  }
  const result = params.a + params.b;
  context.state.set("last_math_result", result);
  return { result: result };
}

function subtractNumbers(params: { a: number; b: number }): Record<string, any> {
  return { result: params.a - params.b };
}

function greetUser(params: { name: string }): Record<string, any> {
  return { greeting: `Hello, ${params.name}!` };
}

class SimpleMathToolset extends BaseToolset {
  private readonly tools: BaseTool[];

  constructor(prefix = "") {
    super([]); // No filter
    this.tools = [
      new FunctionTool({
        name: `${prefix}add_numbers`,
        description: "Adds two numbers and stores the result in the session state.",
        parameters: z.object({ a: z.number(), b: z.number() }),
        execute: addNumbers,
      }),
      new FunctionTool({
        name: `${prefix}subtract_numbers`,
        description: "Subtracts the second number from the first.",
        parameters: z.object({ a: z.number(), b: z.number() }),
        execute: subtractNumbers,
      }),
    ];
  }

  async getTools(): Promise<BaseTool[]> {
    return this.tools;
  }

  async close(): Promise<void> {
    console.log("SimpleMathToolset closed.");
  }
}

async function main() {
  const mathToolset = new SimpleMathToolset("calculator_");
  const greetTool = new FunctionTool({
    name: "greet_user",
    description: "Greets the user.",
    parameters: z.object({ name: z.string() }),
    execute: greetUser,
  });

  const instruction =
    `You are a calculator and a greeter.
    If the user asks for a math operation, use the calculator tools.
    If the user asks for a greeting, use the greet_user tool.
    The result of the last math operation is stored in the 'last_math_result' state variable.`;

  const calculatorAgent = new LlmAgent({
    name: "calculator_agent",
    instruction: instruction,
    tools: [greetTool, mathToolset],
    model: "gemini-2.5-flash",
  });

  const runner = new InMemoryRunner({ agent: calculatorAgent, appName: "toolset_app" });
  await runner.sessionService.createSession({ appName: "toolset_app", userId: "user1", sessionId: "session1" });

  const message: Content = createUserContent("What is 5 + 3?");

  for await (const event of runner.runAsync({ userId: "user1", sessionId: "session1", newMessage: message })) {
    if (isFinalResponse(event) && event.content?.parts?.length) {
      const text = stringifyContent(event).trim();
      if (text) {
        console.log(`Response from agent: ${text}`);
      }
    }
  }

  await mathToolset.close();
}

main();
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.ReadonlyContext;
import com.google.adk.tools.Annotations.Schema;
import com.google.adk.tools.BaseTool;
import com.google.adk.tools.BaseToolset;
import com.google.adk.tools.FunctionTool;
import com.google.adk.tools.ToolContext;
import io.reactivex.rxjava3.core.Flowable;
import java.util.HashMap;
import java.util.Map;

public class SimpleMathToolsetApp {

  // 1. Define the individual tool functions

  /**
   * Adds two integer numbers.
   *
   * @param a The first number.
   * @param b The second number.
   * @param toolContext The tool context.
   * @return A map with the sum.
   */
  public static Map<String, Object> addNumbers(
      @Schema(name = "a", description = "The first number") int a,
      @Schema(name = "b", description = "The second number") int b,
      ToolContext toolContext) {
    System.out.println("Tool: add_numbers called with a=" + a + ", b=" + b);
    int result = a + b;
    // Example: Storing something in tool_context state
    toolContext.state().put("last_math_operation", "addition");
    Map<String, Object> response = new HashMap<>();
    response.put("status", "success");
    response.put("result", result);
    return response;
  }

  /**
   * Subtracts the second number from the first.
   *
   * @param a The first number.
   * @param b The second number.
   * @return A map with the difference.
   */
  public static Map<String, Object> subtractNumbers(
      @Schema(name = "a", description = "The first number") int a,
      @Schema(name = "b", description = "The second number") int b) {
    System.out.println("Tool: subtract_numbers called with a=" + a + ", b=" + b);
    Map<String, Object> response = new HashMap<>();
    response.put("status", "success");
    response.put("result", a - b);
    return response;
  }

  // 2. Create the Toolset by implementing BaseToolset
  public static class SimpleMathToolset implements BaseToolset {
    private final BaseTool addTool;
    private final BaseTool subtractTool;

    public SimpleMathToolset() throws NoSuchMethodException {
      // Create FunctionTool instances once
      this.addTool =
          FunctionTool.create(
              SimpleMathToolsetApp.class.getMethod(
                  "addNumbers", int.class, int.class, ToolContext.class));
      this.subtractTool =
          FunctionTool.create(
              SimpleMathToolsetApp.class.getMethod("subtractNumbers", int.class, int.class));
      System.out.println("SimpleMathToolset initialized");
    }

    @Override
    public Flowable<BaseTool> getTools(ReadonlyContext readonlyContext) {
      System.out.println("SimpleMathToolset.getTools() called.");
      // Example of dynamic behavior:
      // Could use readonlyContext to access state and conditionally return tools.
      // For this simple example, always return both tools:
      return Flowable.just(addTool, subtractTool);
    }

    @Override
    public void close() throws Exception {
      // No resources to clean up in this simple example
      System.out.println("SimpleMathToolset.close() called.");
    }
  }

  // 3. Define an individual tool (not part of the toolset)

  /**
   * Greets the user.
   *
   * @param name The name of the user.
   * @return A map with the greeting.
   */
  public static Map<String, Object> greetUser(
      @Schema(name = "name", description = "The name of the user") String name) {
    System.out.println("Tool: greetUser called with name=" + name);
    Map<String, Object> response = new HashMap<>();
    response.put("greeting", "Hello, " + name + "!");
    return response;
  }

  public static void main(String[] args) throws Exception {
    BaseTool greetTool =
        FunctionTool.create(SimpleMathToolsetApp.class.getMethod("greetUser", String.class));

    // 4. Instantiate the toolset
    BaseToolset mathToolsetInstance = new SimpleMathToolset();

    // 5. Define an agent that uses both the individual tool and the toolset
    LlmAgent calculatorAgent =
        LlmAgent.builder()
            .name("CalculatorAgent")
            .model("gemini-2.5-flash") // Replace with your desired model
            .instruction(
                "You are a helpful calculator and greeter. "
                    + "Use 'greetUser' for greetings. "
                    + "Use 'addNumbers' to add and 'subtractNumbers' to subtract. "
                    + "Announce the state of 'last_math_operation' if it's set.")
            .tools(greetTool, mathToolsetInstance) // Individual tool and Toolset instance
            .build();

    // System.out.println("Agent '" + calculatorAgent.name() + "' created.");

    // Runner runner = new Runner(calculatorAgent, ...);
    // ... setup and usage ...

    // Important: Clean up the toolset if it manages resources
    mathToolsetInstance.close();
  }
}
```

In this example:

- `SimpleMathToolset` implements `BaseToolset` and its `get_tools()` method returns `FunctionTool` instances for `add_numbers` and `subtract_numbers`. It also customizes their names using a prefix.
- The `calculator_agent` is configured with both an individual `greet_tool` and an instance of `SimpleMathToolset`.
- When `calculator_agent` is run, ADK will call `math_toolset_instance.get_tools()`. The agent's LLM will then have access to `greet_user`, `calculator_add_numbers`, and `calculator_subtract_numbers` to handle user requests.
- The `add_numbers` tool demonstrates writing to `tool_context.state`, and the agent's instruction mentions reading this state.
- The `close()` method is called to ensure any resources held by the toolset are released.

Toolsets offer a powerful way to organize, manage, and dynamically provide collections of tools to your ADK agents, leading to more modular, maintainable, and adaptable agentic applications.

# Authenticating with Tools

Supported in ADKPython v0.1.0

The tools and services you use within ADK agents may require access to protected resources, such as user data in email or calendar applications, or sales records in databases. Getting access to these resources typically requires an authentication process that includes credentials and access keys which must be carefully managed and protected. The requirements for managing authentication data can also change if you are running your agent locally or deploying it to a hosted service. If multiple users, with potentially different access permissions, are interacting with the agent, this creates another layer of authentication management requirements.

WARNING: Credential storage and security risks

Storing sensitive credentials such as access tokens and especially refresh tokens directly in the session state can pose security risks depending on your session storage backend, your ***SessionService*** implementation, and overall application security posture. Carefully consider how you manage credentials in ADK agents before deploying them for general use.

## Authentication and credential management

There are several ways to manage authentication and credentials in ADK agents. Each of these methods carries some amount of risk, so you should carefully consider which approach best serves your application and customers.

### Recommended: Authentication manager services

When deploying agents to production hosted environments, your agent's ability to properly authenticate to restricted tools and services becomes more challenging and more important to properly manage. This authentication challenge can become even more complicated when users of your agent have varying levels of access to restricted tools and data.

Rather than writing code to handle the authentication process and credential management for various tools used by your agent, use an *authentication manager* service that manages *both* for you. This service should handle the storage of keys and secrets, as well as the acquisition, management, and storage of OAuth access or refresh tokens. Learn more about Agent Identity Authentication Manager for [2-legged OAuth](https://docs.cloud.google.com/iam/docs/auth-with-2lo), [3-legged OAuth](https://docs.cloud.google.com/iam/docs/auth-with-3lo), and [API key](https://docs.cloud.google.com/iam/docs/auth-with-api-key).

### Self-managed authentication

If you decide to manage your own authentication process with ADK helper functions and your own code, consider these recommendations:

- **API keys and client secrets:** For any API keys and client secrets used inside ADK code, when running on a local compute environment use a local `.env` file excluded from version control. When your agent is hosted or otherwise in a production environment, use a secrets manager. For more details on secrets managers, see the [next section](#secrets-manager).
- **Interactive authentication:** When using interactive three-legged auth (3LO) OAuth or OpenID Connect (OIDC) for authentication to tools, write a service on the client application to acquire, manage access, and refresh tokens. Make sure to store these tokens against an authenticated user identifier in an encrypted database.

### Secrets manager services

For production environments, if you are not using an [authentication manager](#authentication-manager) service, you should store credentials in a dedicated secret manager service to protect that data. With this approach, a secret manager securely stores the credentials for any tools or services accessed by the agent as needed, and those secrets are not resident in agent's operating memory. For example, a custom ADK Tool using this method would have only short-lived access tokens or secure references in session memory, and retrieve longer-lived refresh tokens from the secrets manager when needed. When selecting a secrets manager, consider services from well-established providers, such as [Google Cloud Secret Manager](https://cloud.google.com/security/products/secret-manager) or other secret management services.

### Local encrypted secrets storage

For agent applications that are less security sensitive, keeping credentials in local, encrypted storage can be a viable option. Consider using dedicated local secrets storage system or encrypting the data in a local database using a robust encryption library, and then managing the encryption keys securely using a key management service. Take care to only keep short-lived access tokens in operating memory and access long-lived credentials and refresh tokens from encrypted local storage only when needed.

### In-memory secrets

This method *should only be used in the early development* and testing of your agent. With this approach, credentials are stored in the current ***InMemorySessionService*** instance. The data exists only in session memory and is not persisted. However, you should carefully consider the risks of using this method based on how long an agent session may last, who has access to the agent, and the security of the environment where the agent is running.

## Framework components

Within the ADK framework, the ***AuthScheme*** and ***AuthCredential*** are the key components for handling authentication methods and managing credential data:

- ***AuthScheme***: Defines *how* an API expects authentication credentials, such as an API Key in a header or an OAuth 2.0 Bearer token. ADK supports the same types of authentication schemes as OpenAPI 3.0 and uses specific classes for credential types, including ***APIKey***, ***HTTPBearer***, ***OAuth2***, and ***OpenIdConnectWithConfig***. For more details on each OpenAPI credential type, see [OpenAPI doc: Authentication](https://swagger.io/docs/specification/v3_0/authentication/).
- ***AuthCredential***: Holds the *initial* information needed to *start* the authentication process, such as your application's OAuth Client ID or Secret, or an API key value. An instance of this class includes an **auth_type**, such as `API_KEY`, `OAUTH2`, `SERVICE_ACCOUNT`, specifying the credential type.

The general authentication flow involves providing these details when configuring a tool. ADK then attempts to automatically exchange the initial credential, such as an access token, before the tool makes an API call. For flows requiring user interaction, including OAuth consent, ADK triggers a specific interactive process with your ***Agent Client*** application.

### Supported initial credential types

- **API_KEY:** Provides simple key-value authentication, which usually requires no authentication exchange.
- **HTTP:** Provides Basic Auth which is not recommended and may not be supported for exchange, or already obtained Bearer tokens. Bearer tokens do not require an authentication exchange.
- **OAUTH2:** Provides standard OAuth 2.0 authentication flows, and requires configuration with client ID, secret, and scopes. This method often triggers an interactive flow for user consent.
- **OPEN_ID_CONNECT:** Provides authentication based on OpenID Connect. Similar to OAuth2, this type often requires configuration and user interaction.
- **SERVICE_ACCOUNT:** Provides Google Cloud Service Account credentials as a JSON key or Application Default Credentials. This type typically exchanges a Bearer token.

## Tools and integrations quick guide

Here is a quick guide to authentication for key ADK toolsets:

- [***RestApiTool***](/tools-custom/openapi-tools/): Set `auth_scheme` and `auth_credential` during initialization
- [***OpenAPIToolset***](/tools-custom/openapi-tools/): Set `auth_scheme` and `auth_credential` during initialization
- [***APIHubToolset***](/integrations/apigee-api-hub/): Set `auth_scheme` and `auth_credential` during initialization, *if* the API requires authentication.
- [***ApplicationIntegrationToolset***](/integrations/application-integration/): Set `auth_scheme` and `auth_credential` during initialization, *if* the API requires authentication.
- [***GoogleApiToolSet***](https://github.com/google/adk-python/blob/main/src/google/adk/tools/google_api_tool/google_api_toolset.py): Use this toolset's specific authentication method.

For more authentication details for other pre-built tools and integrations see the [ADK Integrations](/integrations) catalog.

______________________________________________________________________

## Journey 1: Building Agentic Applications with Authenticated Tools

This section focuses on using pre-existing tools (like those from `RestApiTool/ OpenAPIToolset`, `APIHubToolset`, `GoogleApiToolSet`) that require authentication within your agentic application. Your main responsibility is configuring the tools and handling the client-side part of interactive authentication flows (if required by the tool).

### 1. Configuring Tools with Authentication

When adding an authenticated tool to your agent, you need to provide its required `AuthScheme` and your application's initial `AuthCredential`.

**A. Using OpenAPI-based Toolsets (`OpenAPIToolset`, `APIHubToolset`, etc.)**

Pass the scheme and credential during toolset initialization. The toolset applies them to all generated tools. Here are few ways to create tools with authentication in ADK.

Create a tool requiring an API Key.

```py
from google.adk.tools.openapi_tool.auth.auth_helpers import token_to_scheme_credential
from google.adk.tools.openapi_tool.openapi_spec_parser.openapi_toolset import OpenAPIToolset

auth_scheme, auth_credential = token_to_scheme_credential(
    "apikey", "query", "apikey", "YOUR_API_KEY_STRING"
)
sample_api_toolset = OpenAPIToolset(
    spec_str="...",  # Fill this with an OpenAPI spec string
    spec_str_type="yaml",
    auth_scheme=auth_scheme,
    auth_credential=auth_credential,
)
```

Create a tool requiring OAuth2.

```py
from google.adk.tools.openapi_tool.openapi_spec_parser.openapi_toolset import OpenAPIToolset
from fastapi.openapi.models import OAuth2
from fastapi.openapi.models import OAuthFlowAuthorizationCode
from fastapi.openapi.models import OAuthFlows
from google.adk.auth import AuthCredential
from google.adk.auth import AuthCredentialTypes
from google.adk.auth import OAuth2Auth

auth_scheme = OAuth2(
    flows=OAuthFlows(
        authorizationCode=OAuthFlowAuthorizationCode(
            authorizationUrl="https://accounts.google.com/o/oauth2/auth",
            tokenUrl="https://oauth2.googleapis.com/token",
            scopes={
                "https://www.googleapis.com/auth/calendar": "calendar scope"
            },
        )
    )
)
auth_credential = AuthCredential(
    auth_type=AuthCredentialTypes.OAUTH2,
    oauth2=OAuth2Auth(
        client_id=YOUR_OAUTH_CLIENT_ID,
        client_secret=YOUR_OAUTH_CLIENT_SECRET
    ),
)

calendar_api_toolset = OpenAPIToolset(
    spec_str=google_calendar_openapi_spec_str, # Fill this with an openapi spec
    spec_str_type='yaml',
    auth_scheme=auth_scheme,
    auth_credential=auth_credential,
)
```

Create a tool requiring Service Account.

```py
from google.adk.tools.openapi_tool.auth.auth_helpers import service_account_dict_to_scheme_credential
from google.adk.tools.openapi_tool.openapi_spec_parser.openapi_toolset import OpenAPIToolset

service_account_cred = json.loads(service_account_json_str)
auth_scheme, auth_credential = service_account_dict_to_scheme_credential(
    config=service_account_cred,
    scopes=["https://www.googleapis.com/auth/cloud-platform"],
)
sample_toolset = OpenAPIToolset(
    spec_str=sa_openapi_spec_str, # Fill this with an openapi spec
    spec_str_type='json',
    auth_scheme=auth_scheme,
    auth_credential=auth_credential,
)
```

Create a tool requiring OpenID connect.

```py
from google.adk.auth.auth_schemes import OpenIdConnectWithConfig
from google.adk.auth.auth_credential import AuthCredential, AuthCredentialTypes, OAuth2Auth
from google.adk.tools.openapi_tool.openapi_spec_parser.openapi_toolset import OpenAPIToolset

auth_scheme = OpenIdConnectWithConfig(
    authorization_endpoint=OAUTH2_AUTH_ENDPOINT_URL,
    token_endpoint=OAUTH2_TOKEN_ENDPOINT_URL,
    scopes=['openid', 'YOUR_OAUTH_SCOPES"]
)
auth_credential = AuthCredential(
    auth_type=AuthCredentialTypes.OPEN_ID_CONNECT,
    oauth2=OAuth2Auth(
        client_id="...",
        client_secret="...",
    )
)

userinfo_toolset = OpenAPIToolset(
    spec_str=content, # Fill in an actual spec
    spec_str_type='yaml',
    auth_scheme=auth_scheme,
    auth_credential=auth_credential,
)
```

**B. Using Google API Toolsets (e.g., `calendar_tool_set`)**

These toolsets often have dedicated configuration methods.

Tip: For how to create a Google OAuth Client ID & Secret, see this guide: [Get your Google API Client ID](https://developers.google.com/identity/gsi/web/guides/get-google-api-clientid#get_your_google_api_client_id)

```py
# Example: Configuring Google Calendar Tools
from google.adk.tools.google_api_tool import calendar_tool_set

client_id = "YOUR_GOOGLE_OAUTH_CLIENT_ID.apps.googleusercontent.com"
client_secret = "YOUR_GOOGLE_OAUTH_CLIENT_SECRET"

# Use the specific configure method for this toolset type
calendar_tool_set.configure_auth(
    client_id=oauth_client_id, client_secret=oauth_client_secret
)

# agent = LlmAgent(..., tools=calendar_tool_set.get_tool('calendar_tool_set'))
```

The sequence diagram of auth request flow (where tools are requesting auth credentials) looks like below:

### 2. Handling the Interactive OAuth/OIDC Flow (Client-Side)

If a tool requires user login/consent (typically OAuth 2.0 or OIDC), the ADK framework pauses execution and signals your ***Agent Client*** application. There are two cases:

- ***Agent Client*** application runs the agent directly (via `runner.run_async`) in the same process. e.g. UI backend, CLI app, or Spark job etc.
- ***Agent Client*** application interacts with ADK's fastapi server via `/run` or `/run_sse` endpoint. While ADK's fastapi server could be setup on the same server or different server as ***Agent Client*** application

The second case is a special case of first case, because `/run` or `/run_sse` endpoint also invokes `runner.run_async`. The only differences are:

- Whether to call a python function to run the agent (first case) or call a service endpoint to run the agent (second case).
- Whether the result events are in-memory objects (first case) or serialized json string in http response (second case).

Below sections focus on the first case and you should be able to map it to the second case very straightforward. We will also describe some differences to handle for the second case if necessary.

Here's the step-by-step process for your client application:

**Step 1: Run Agent & Detect Auth Request**

- Initiate the agent interaction using `runner.run_async`.
- Iterate through the yielded events.
- Look for a specific function call event whose function call has a special name: `adk_request_credential`. This event signals that user interaction is needed. You can use helper functions to identify this event and extract necessary information. (For the second case, the logic is similar. You deserialize the event from the http response).

```py
# runner = Runner(...)
# session = await session_service.create_session(...)
# content = types.Content(...) # User's initial query

print("\nRunning agent...")
events_async = runner.run_async(
    session_id=session.id, user_id='user', new_message=content
)

auth_request_function_call_id, auth_config = None, None

async for event in events_async:
    # Use helper to check for the specific auth request event
    if (auth_request_function_call := get_auth_request_function_call(event)):
        print("--> Authentication required by agent.")
        # Store the ID needed to respond later
        if not (auth_request_function_call_id := auth_request_function_call.id):
            raise ValueError(f'Cannot get function call id from function call: {auth_request_function_call}')
        # Get the AuthConfig containing the auth_uri etc.
        auth_config = get_auth_config(auth_request_function_call)
        break # Stop processing events for now, need user interaction

if not auth_request_function_call_id:
    print("\nAuth not required or agent finished.")
    # return # Or handle final response if received
```

*Helper functions `helpers.py`:*

```py
from google.adk.events import Event
from google.adk.auth import AuthConfig # Import necessary type
from google.genai import types

def get_auth_request_function_call(event: Event) -> types.FunctionCall:
    # Get the special auth request function call from the event
    if not event.content or not event.content.parts:
        return
    for part in event.content.parts:
        if (
            part
            and part.function_call
            and part.function_call.name == 'adk_request_credential'
            and event.long_running_tool_ids
            and part.function_call.id in event.long_running_tool_ids
        ):

            return part.function_call

def get_auth_config(auth_request_function_call: types.FunctionCall) -> AuthConfig:
    # Extracts the AuthConfig object from the arguments of the auth request function call
    if not auth_request_function_call.args or not (auth_config := auth_request_function_call.args.get('authConfig')):
        raise ValueError(f'Cannot get auth config from function call: {auth_request_function_call}')
    if isinstance(auth_config, dict):
        auth_config = AuthConfig.model_validate(auth_config)
    elif not isinstance(auth_config, AuthConfig):
        raise ValueError(f'Cannot get auth config {auth_config} is not an instance of AuthConfig.')
    return auth_config
```

**Step 2: Redirect User for Authorization**

- Get the authorization URL (`auth_uri`) from the `auth_config` extracted in the previous step.
- **Crucially, append your application's** redirect_uri as a query parameter to this `auth_uri`. This `redirect_uri` must be pre-registered with your OAuth provider (e.g., [Google Cloud Console](https://developers.google.com/identity/protocols/oauth2/web-server#creatingcred), [Okta admin panel](https://developer.okta.com/docs/guides/sign-into-web-app-redirect/spring-boot/main/#create-an-app-integration-in-the-admin-console)).
- Direct the user to this complete URL (e.g., open it in their browser).

```py
# (Continuing after detecting auth needed)

if auth_request_function_call_id and auth_config:
    # Get the base authorization URL from the AuthConfig
    base_auth_uri = auth_config.exchanged_auth_credential.oauth2.auth_uri

    if base_auth_uri:
        redirect_uri = 'http://localhost:8000/callback' # MUST match your OAuth client app config
        # Append redirect_uri (use urlencode in production)
        auth_request_uri = base_auth_uri + f'&redirect_uri={redirect_uri}'
        # Now you need to redirect your end user to this auth_request_uri or ask them to open this auth_request_uri in their browser
        # This auth_request_uri should be served by the corresponding auth provider and the end user should login and authorize your application to access their data
        # And then the auth provider will redirect the end user to the redirect_uri you provided
        # Next step: Get this callback URL from the user (or your web server handler)
    else:
         print("ERROR: Auth URI not found in auth_config.")
         # Handle error
```

**Step 3. Handle the Redirect Callback (Client):**

- Your application must have a mechanism (e.g., a web server route at the `redirect_uri`) to receive the user after they authorize the application with the provider.
- The provider redirects the user to your `redirect_uri` and appends an `authorization_code` (and potentially `state`, `scope`) as query parameters to the URL.
- Capture the **full callback URL** from this incoming request.
- (This step happens outside the main agent execution loop, in your web server or equivalent callback handler.)

**Step 4. Send Authentication Result Back to ADK (Client):**

- Once you have the full callback URL (containing the authorization code), retrieve the `auth_request_function_call_id` and the `auth_config` object saved in Client Step 1.
- Set the captured callback URL in the `exchanged_auth_credential.oauth2.auth_response_uri` field. Also ensure `exchanged_auth_credential.oauth2.redirect_uri` contains the redirect URI you used.
- Create a `types.Content` object containing a `types.Part` with a `types.FunctionResponse`.
  - Set `name` to `"adk_request_credential"`. (Note: This is a special name for ADK to proceed with authentication. Do not use other names.)
  - Set `id` to the `auth_request_function_call_id` you saved.
  - Set `response` to the *serialized* (e.g., `.model_dump()`) updated `AuthConfig` object.
- Call `runner.run_async` **again** for the same session, passing this `FunctionResponse` content as the `new_message`.

```py
# (Continuing after user interaction)

    # Simulate getting the callback URL (e.g., from user paste or web handler)
    auth_response_uri = await get_user_input(
        f'Paste the full callback URL here:\n> '
    )
    auth_response_uri = auth_response_uri.strip() # Clean input

    if not auth_response_uri:
        print("Callback URL not provided. Aborting.")
        return

    # Update the received AuthConfig with the callback details
    auth_config.exchanged_auth_credential.oauth2.auth_response_uri = auth_response_uri
    # Also include the redirect_uri used, as the token exchange might need it
    auth_config.exchanged_auth_credential.oauth2.redirect_uri = redirect_uri

    # Construct the FunctionResponse Content object
    auth_content = types.Content(
        role='user', # Role can be 'user' when sending a FunctionResponse
        parts=[
            types.Part(
                function_response=types.FunctionResponse(
                    id=auth_request_function_call_id,       # Link to the original request
                    name='adk_request_credential', # Special framework function name
                    response=auth_config.model_dump() # Send back the *updated* AuthConfig
                )
            )
        ],
    )

    # --- Resume Execution ---
    print("\nSubmitting authentication details back to the agent...")
    events_async_after_auth = runner.run_async(
        session_id=session.id,
        user_id='user',
        new_message=auth_content, # Send the FunctionResponse back
    )

    # --- Process Final Agent Output ---
    print("\n--- Agent Response after Authentication ---")
    async for event in events_async_after_auth:
        # Process events normally, expecting the tool call to succeed now
        print(event) # Print the full event for inspection
```

Note: Authorization response with Resume feature

If your ADK agent workflow is configured with the [Resume](/runtime/resume/) feature, you also must include the Invocation ID (`invocation_id`) parameter with the authorization response. The Invocation ID you provide must be the same invocation that generated the authorization request, otherwise the system starts a new invocation with the authorization response. If your agent uses the Resume feature, consider including the Invocation ID as a parameter with your authorization request, so it can be included with the authorization response. For more details on using the Resume feature, see [Resume stopped agents](/runtime/resume/).

**Step 5: ADK Handles Token Exchange & Tool Retry and gets Tool result**

- ADK receives the `FunctionResponse` for `adk_request_credential`.
- It uses the information in the updated `AuthConfig` (including the callback URL containing the code) to perform the OAuth **token exchange** with the provider's token endpoint, obtaining the access token (and possibly refresh token).
- ADK internally makes these tokens available by setting them in the session state.
- ADK **automatically retries** the original tool call (the one that initially failed due to missing auth).
- This time, the tool finds the valid tokens (via `tool_context.get_auth_response()`) and successfully executes the authenticated API call.
- The agent receives the actual result from the tool and generates its final response to the user.

______________________________________________________________________

The sequence diagram of auth response flow, where the ***Agent Client*** sends back the auth response and ADK retries the tool, is as follows:

## Journey 2: Building Custom Tools (`FunctionTool`) Requiring Authentication

This section focuses on implementing the authentication logic *inside* your custom Python function when creating a new ADK Tool. We will implement a `FunctionTool` as an example.

### Prerequisites

Your function signature *must* include [`tool_context: ToolContext`](https://adk.dev/tools-custom/#tool-context). ADK automatically injects this object, providing access to state and auth mechanisms.

```py
from google.adk.tools import FunctionTool, ToolContext
from typing import Dict

def my_authenticated_tool_function(param1: str, ..., tool_context: ToolContext) -> dict:
    # ... your logic ...
    pass

my_tool = FunctionTool(func=my_authenticated_tool_function)
```

### Authentication Logic within the Tool Function

Implement the following steps inside your function:

**Step 1: Check for Cached & Valid Credentials:**

Inside your tool function, first check if valid credentials (e.g., access/refresh tokens) are already stored from a previous run in this session. Credentials for the current sessions should be stored in `tool_context.invocation_context.session.state` (a dictionary of state) Check existence of existing credentials by checking `tool_context.invocation_context.session.state.get(credential_name, None)`.

```py
from google.oauth2.credentials import Credentials
from google.auth.transport.requests import Request

# Inside your tool function
TOKEN_CACHE_KEY = "my_tool_tokens" # Choose a unique key
SCOPES = ["scope1", "scope2"] # Define required scopes

creds = None
cached_token_info = tool_context.state.get(TOKEN_CACHE_KEY)
if cached_token_info:
    try:
        creds = Credentials.from_authorized_user_info(cached_token_info, SCOPES)
        if not creds.valid and creds.expired and creds.refresh_token:
            creds.refresh(Request())
            tool_context.state[TOKEN_CACHE_KEY] = json.loads(creds.to_json()) # Update cache
        elif not creds.valid:
            creds = None # Invalid, needs re-auth
            tool_context.state[TOKEN_CACHE_KEY] = None
    except Exception as e:
        print(f"Error loading/refreshing cached creds: {e}")
        creds = None
        tool_context.state[TOKEN_CACHE_KEY] = None

if creds and creds.valid:
    # Skip to Step 5: Make Authenticated API Call
    pass
else:
    # Proceed to Step 2...
    pass
```

**Step 2: Check for Auth Response from Client**

- If Step 1 didn't yield valid credentials, check if the client just completed the interactive flow by calling `exchanged_credential = tool_context.get_auth_response()`.
- This returns the updated `exchanged_credential` object sent back by the client (containing the callback URL in `auth_response_uri`).

```py
# Use auth_scheme and auth_credential configured in the tool.
# exchanged_credential: AuthCredential | None

exchanged_credential = tool_context.get_auth_response(AuthConfig(
  auth_scheme=auth_scheme,
  raw_auth_credential=auth_credential,
))
# If exchanged_credential is not None, then there is already an exchanged credential from the auth response.
if exchanged_credential:
   # ADK exchanged the access token already for us
        access_token = exchanged_credential.oauth2.access_token
        refresh_token = exchanged_credential.oauth2.refresh_token
        creds = Credentials(
            token=access_token,
            refresh_token=refresh_token,
            token_uri=auth_scheme.flows.authorizationCode.tokenUrl,
            client_id=auth_credential.oauth2.client_id,
            client_secret=auth_credential.oauth2.client_secret,
            scopes=list(auth_scheme.flows.authorizationCode.scopes.keys()),
        )
    # Cache the token in session state and call the API, skip to step 5
```

**Step 3: Initiate Authentication Request**

If no valid credentials (Step 1.) and no auth response (Step 2.) are found, the tool needs to start the OAuth flow. Define the AuthScheme and initial AuthCredential and call `tool_context.request_credential()`. Return a response indicating authorization is needed.

```py
# Use auth_scheme and auth_credential configured in the tool.

  tool_context.request_credential(AuthConfig(
    auth_scheme=auth_scheme,
    raw_auth_credential=auth_credential,
  ))
  return {'pending': true, 'message': 'Awaiting user authentication.'}

# By setting request_credential, ADK detects a pending authentication event. It pauses execution and ask end user to login.
```

**Step 4: Exchange Authorization Code for Tokens**

ADK automatically generates oauth authorization URL and presents it to your ***Agent Client*** application. your ***Agent Client*** application should follow the same way described in Journey 1 to redirect the user to the authorization URL (with `redirect_uri` appended). Once a user completes the login flow, ADK extracts the authentication callback url from ***Agent Client*** applications, automatically parses the auth code, and generates auth token. At the next Tool call, `tool_context.get_auth_response` in step 2 will contain a valid credential to use in subsequent API calls.

**Step 5: Cache Obtained Credentials**

After successfully obtaining the token from ADK (Step 2) or if the token is still valid (Step 1), **immediately store** the new `Credentials` object in `tool_context.state` (serialized, e.g., as JSON) using your cache key.

```py
# Inside your tool function, after obtaining 'creds' (either refreshed or newly exchanged)
# Cache the new/refreshed tokens
tool_context.state[TOKEN_CACHE_KEY] = json.loads(creds.to_json())
print(f"DEBUG: Cached/updated tokens under key: {TOKEN_CACHE_KEY}")
# Proceed to Step 6 (Make API Call)
```

**Step 6: Make Authenticated API Call**

- Once you have a valid `Credentials` object (`creds` from Step 1 or Step 4), use it to make the actual call to the protected API using the appropriate client library (e.g., `googleapiclient`, `requests`). Pass the `credentials=creds` argument.
- Include error handling, especially for `HttpError` 401/403, which might mean the token expired or was revoked between calls. If you get such an error, consider clearing the cached token (`tool_context.state.pop(...)`) and potentially returning the `auth_required` status again to force re-authentication.

```py
# Inside your tool function, using the valid 'creds' object
# Ensure creds is valid before proceeding
if not creds or not creds.valid:
   return {"status": "error", "error_message": "Cannot proceed without valid credentials."}

try:
   service = build("calendar", "v3", credentials=creds) # Example
   api_result = service.events().list(...).execute()
   # Proceed to Step 7
except Exception as e:
   # Handle API errors (e.g., check for 401/403, maybe clear cache and re-request auth)
   print(f"ERROR: API call failed: {e}")
   return {"status": "error", "error_message": f"API call failed: {e}"}
```

**Step 7: Return Tool Result**

- After a successful API call, process the result into a dictionary format that is useful for the LLM.
- **Crucially, include a** along with the data.

```py
# Inside your tool function, after successful API call
    processed_result = [...] # Process api_result for the LLM
    return {"status": "success", "data": processed_result}
```

Full Code

tools_and_agent.py

```py
import os

from google.adk.auth.auth_schemes import OpenIdConnectWithConfig
from google.adk.auth.auth_credential import AuthCredential, AuthCredentialTypes, OAuth2Auth
from google.adk.tools.openapi_tool.openapi_spec_parser.openapi_toolset import OpenAPIToolset
from google.adk.agents.llm_agent import LlmAgent

# --- Authentication Configuration ---
# This section configures how the agent will handle authentication using OpenID Connect (OIDC),
# often layered on top of OAuth 2.0.

# Define the Authentication Scheme using OpenID Connect.
# This object tells the ADK *how* to perform the OIDC/OAuth2 flow.
# It requires details specific to your Identity Provider (IDP), like Google OAuth, Okta, Auth0, etc.
# Note: Replace the example Okta URLs and credentials with your actual IDP details.
# All following fields are required, and available from your IDP.
auth_scheme = OpenIdConnectWithConfig(
    # The URL of the IDP's authorization endpoint where the user is redirected to log in.
    authorization_endpoint="https://your-endpoint.okta.com/oauth2/v1/authorize",
    # The URL of the IDP's token endpoint where the authorization code is exchanged for tokens.
    token_endpoint="https://your-token-endpoint.okta.com/oauth2/v1/token",
    # The scopes (permissions) your application requests from the IDP.
    # 'openid' is standard for OIDC. 'profile' and 'email' request user profile info.
    scopes=['openid', 'profile', "email"]
)

# Define the Authentication Credentials for your specific application.
# This object holds the client identifier and secret that your application uses
# to identify itself to the IDP during the OAuth2 flow.
# !! SECURITY WARNING: Avoid hardcoding secrets in production code. !!
# !! Use environment variables or a secret management system instead. !!
auth_credential = AuthCredential(
  auth_type=AuthCredentialTypes.OPEN_ID_CONNECT,
  oauth2=OAuth2Auth(
    client_id="CLIENT_ID",
    client_secret="CIENT_SECRET",
  )
)


# --- Toolset Configuration from OpenAPI Specification ---
# This section defines a sample set of tools the agent can use, configured with Authentication
# from steps above.
# This sample set of tools use endpoints protected by Okta and requires an OpenID Connect flow
# to acquire end user credentials.
with open(os.path.join(os.path.dirname(__file__), 'spec.yaml'), 'r') as f:
    spec_content = f.read()

userinfo_toolset = OpenAPIToolset(
   spec_str=spec_content,
   spec_str_type='yaml',
   # ** Crucially, associate the authentication scheme and credentials with these tools. **
   # This tells the ADK that the tools require the defined OIDC/OAuth2 flow.
   auth_scheme=auth_scheme,
   auth_credential=auth_credential,
)

# --- Agent Configuration ---
# Configure and create the main LLM Agent.
root_agent = LlmAgent(
    model='gemini-2.0-flash',
    name='enterprise_assistant',
    instruction='Help user integrate with multiple enterprise systems, including retrieving user information which may require authentication.',
    tools=userinfo_toolset.get_tools(),
)

# --- Ready for Use ---
# The `root_agent` is now configured with tools protected by OIDC/OAuth2 authentication.
# When the agent attempts to use one of these tools, the ADK framework will automatically
# trigger the authentication flow defined by `auth_scheme` and `auth_credential`
# if valid credentials are not already available in the session.
# The subsequent interaction flow would guide the user through the login process and handle
# token exchanging, and automatically attach the exchanged token to the endpoint defined in
# the tool.
```

agent_cli.py

```py
import asyncio
from dotenv import load_dotenv
from google.adk.artifacts.in_memory_artifact_service import InMemoryArtifactService
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types

from .helpers import is_pending_auth_event, get_function_call_id, get_function_call_auth_config, get_user_input
from .tools_and_agent import root_agent

load_dotenv()

agent = root_agent

async def async_main():
  """
  Main asynchronous function orchestrating the agent interaction and authentication flow.
  """
  # --- Step 1: Service Initialization ---
  # Use in-memory services for session and artifact storage (suitable for demos/testing).
  session_service = InMemorySessionService()
  artifacts_service = InMemoryArtifactService()

  # Create a new user session to maintain conversation state.
  session = session_service.create_session(
      state={},  # Optional state dictionary for session-specific data
      app_name='my_app', # Application identifier
      user_id='user' # User identifier
  )

  # --- Step 2: Initial User Query ---
  # Define the user's initial request.
  query = 'Show me my user info'
  print(f"user: {query}")

  # Format the query into the Content structure expected by the ADK Runner.
  content = types.Content(role='user', parts=[types.Part(text=query)])

  # Initialize the ADK Runner
  runner = Runner(
      app_name='my_app',
      agent=agent,
      artifact_service=artifacts_service,
      session_service=session_service,
  )

  # --- Step 3: Send Query and Handle Potential Auth Request ---
  print("\nRunning agent with initial query...")
  events_async = runner.run_async(
      session_id=session.id, user_id='user', new_message=content
  )

  # Variables to store details if an authentication request occurs.
  auth_request_event_id, auth_config = None, None

  # Iterate through the events generated by the first run.
  async for event in events_async:
    # Check if this event is the specific 'adk_request_credential' function call.
    if is_pending_auth_event(event):
      print("--> Authentication required by agent.")
      auth_request_event_id = get_function_call_id(event)
      auth_config = get_function_call_auth_config(event)
      # Once the auth request is found and processed, exit this loop.
      # We need to pause execution here to get user input for authentication.
      break


  # If no authentication request was detected after processing all events, exit.
  if not auth_request_event_id or not auth_config:
      print("\nAuthentication not required for this query or processing finished.")
      return # Exit the main function

  # --- Step 4: Manual Authentication Step (Simulated OAuth 2.0 Flow) ---
  # This section simulates the user interaction part of an OAuth 2.0 flow.
  # In a real web application, this would involve browser redirects.

  # Define the Redirect URI. This *must* match one of the URIs registered
  # with the OAuth provider for your application. The provider sends the user
  # back here after they approve the request.
  redirect_uri = 'http://localhost:8000/dev-ui' # Example for local development

  # Construct the Authorization URL that the user must visit.
  # This typically includes the provider's authorization endpoint URL,
  # client ID, requested scopes, response type (e.g., 'code'), and the redirect URI.
  # Here, we retrieve the base authorization URI from the AuthConfig provided by ADK
  # and append the redirect_uri.
  # NOTE: A robust implementation would use urlencode and potentially add state, scope, etc.
  auth_request_uri = (
      auth_config.exchanged_auth_credential.oauth2.auth_uri
      + f'&redirect_uri={redirect_uri}' # Simple concatenation; ensure correct query param format
  )

  print("\n--- User Action Required ---")
  # Prompt the user to visit the authorization URL, log in, grant permissions,
  # and then paste the *full* URL they are redirected back to (which contains the auth code).
  auth_response_uri = await get_user_input(
      f'1. Please open this URL in your browser to log in:\n   {auth_request_uri}\n\n'
      f'2. After successful login and authorization, your browser will be redirected.\n'
      f'   Copy the *entire* URL from the browser\'s address bar.\n\n'
      f'3. Paste the copied URL here and press Enter:\n\n> '
  )

  # --- Step 5: Prepare Authentication Response for the Agent ---
  # Update the AuthConfig object with the information gathered from the user.
  # The ADK framework needs the full response URI (containing the code)
  # and the original redirect URI to complete the OAuth token exchange process internally.
  auth_config.exchanged_auth_credential.oauth2.auth_response_uri = auth_response_uri
  auth_config.exchanged_auth_credential.oauth2.redirect_uri = redirect_uri

  # Construct a FunctionResponse Content object to send back to the agent/runner.
  # This response explicitly targets the 'adk_request_credential' function call
  # identified earlier by its ID.
  auth_content = types.Content(
      role='user',
      parts=[
          types.Part(
              function_response=types.FunctionResponse(
                  # Crucially, link this response to the original request using the saved ID.
                  id=auth_request_event_id,
                  # The special name of the function call we are responding to.
                  name='adk_request_credential',
                  # The payload containing all necessary authentication details.
                  response=auth_config.model_dump(),
              )
          )
      ],
  )

  # --- Step 6: Resume Execution with Authentication ---
  print("\nSubmitting authentication details back to the agent...")
  # Run the agent again, this time providing the `auth_content` (FunctionResponse).
  # The ADK Runner intercepts this, processes the 'adk_request_credential' response
  # (performs token exchange, stores credentials), and then allows the agent
  # to retry the original tool call that required authentication, now succeeding with
  # a valid access token embedded.
  events_async = runner.run_async(
      session_id=session.id,
      user_id='user',
      new_message=auth_content, # Provide the prepared auth response
  )

  # Process and print the final events from the agent after authentication is complete.
  # This stream now contain the actual result from the tool (e.g., the user info).
  print("\n--- Agent Response after Authentication ---")
  async for event in events_async:
    print(event)


if __name__ == '__main__':
  asyncio.run(async_main())
```

helpers.py

```py
from google.adk.auth import AuthConfig
from google.adk.events import Event
import asyncio

# --- Helper Functions ---
async def get_user_input(prompt: str) -> str:
  """
  Asynchronously prompts the user for input in the console.

  Uses asyncio's event loop and run_in_executor to avoid blocking the main
  asynchronous execution thread while waiting for synchronous `input()`.

  Args:
    prompt: The message to display to the user.

  Returns:
    The string entered by the user.
  """
  loop = asyncio.get_event_loop()
  # Run the blocking `input()` function in a separate thread managed by the executor.
  return await loop.run_in_executor(None, input, prompt)


def is_pending_auth_event(event: Event) -> bool:
  """
  Checks if an ADK Event represents a request for user authentication credentials.

  The ADK framework emits a specific function call ('adk_request_credential')
  when a tool requires authentication that hasn't been previously satisfied.

  Args:
    event: The ADK Event object to inspect.

  Returns:
    True if the event is an 'adk_request_credential' function call, False otherwise.
  """
  # Safely checks nested attributes to avoid errors if event structure is incomplete.
  return (
      event.content
      and event.content.parts
      and event.content.parts[0] # Assuming the function call is in the first part
      and event.content.parts[0].function_call
      # The specific function name indicating an auth request from the ADK framework.
      and event.content.parts[0].function_call.name == 'adk_request_credential'
  )


def get_function_call_id(event: Event) -> str:
  """
  Extracts the unique ID of the function call from an ADK Event.

  This ID is crucial for correlating a function *response* back to the specific
  function *call* that the agent initiated to request for auth credentials.

  Args:
    event: The ADK Event object containing the function call.

  Returns:
    The unique identifier string of the function call.

  Raises:
    ValueError: If the function call ID cannot be found in the event structure.
                (Corrected typo from `contents` to `content` below)
  """
  # Navigate through the event structure to find the function call ID.
  if (
      event
      and event.content
      and event.content.parts
      and event.content.parts[0] # Use content, not contents
      and event.content.parts[0].function_call
      and event.content.parts[0].function_call.id
  ):
    return event.content.parts[0].function_call.id
  # If the ID is missing, raise an error indicating an unexpected event format.
  raise ValueError(f'Cannot get function call id from event {event}')


def get_function_call_auth_config(event: Event) -> AuthConfig:
  """
  Extracts the authentication configuration details from an 'adk_request_credential' event.

  Client should use this AuthConfig to necessary authentication details (like OAuth codes and state)
  and sent it back to the ADK to continue OAuth token exchanging.

  Args:
    event: The ADK Event object containing the 'adk_request_credential' call.

  Returns:
    An AuthConfig object populated with details from the function call arguments.

  Raises:
    ValueError: If the 'auth_config' argument cannot be found in the event.
                (Corrected typo from `contents` to `content` below)
  """
  if (
      event
      and event.content
      and event.content.parts
      and event.content.parts[0] # Use content, not contents
      and event.content.parts[0].function_call
      and event.content.parts[0].function_call.args
      and event.content.parts[0].function_call.args.get('auth_config')
  ):
    # Reconstruct the AuthConfig object using the dictionary provided in the arguments.
    # The ** operator unpacks the dictionary into keyword arguments for the constructor.
    return AuthConfig(
          **event.content.parts[0].function_call.args.get('auth_config')
      )
  raise ValueError(f'Cannot get auth config from event {event}')
```

```yaml
openapi: 3.0.1
info:
title: Okta User Info API
version: 1.0.0
description: |-
   API to retrieve user profile information based on a valid Okta OIDC Access Token.
   Authentication is handled via OpenID Connect with Okta.
contact:
   name: API Support
   email: support@example.com # Replace with actual contact if available
servers:
- url: <substitute with your server name>
   description: Production Environment
paths:
/okta-jwt-user-api:
   get:
      summary: Get Authenticated User Info
      description: |-
      Fetches profile details for the user
      operationId: getUserInfo
      tags:
      - User Profile
      security:
      - okta_oidc:
            - openid
            - email
            - profile
      responses:
      '200':
         description: Successfully retrieved user information.
         content:
            application/json:
            schema:
               type: object
               properties:
                  sub:
                  type: string
                  description: Subject identifier for the user.
                  example: "abcdefg"
                  name:
                  type: string
                  description: Full name of the user.
                  example: "Example LastName"
                  locale:
                  type: string
                  description: User's locale, e.g., en-US or en_US.
                  example: "en_US"
                  email:
                  type: string
                  format: email
                  description: User's primary email address.
                  example: "username@example.com"
                  preferred_username:
                  type: string
                  description: Preferred username of the user (often the email).
                  example: "username@example.com"
                  given_name:
                  type: string
                  description: Given name (first name) of the user.
                  example: "Example"
                  family_name:
                  type: string
                  description: Family name (last name) of the user.
                  example: "LastName"
                  zoneinfo:
                  type: string
                  description: User's timezone, e.g., America/Los_Angeles.
                  example: "America/Los_Angeles"
                  updated_at:
                  type: integer
                  format: int64 # Using int64 for Unix timestamp
                  description: Timestamp when the user's profile was last updated (Unix epoch time).
                  example: 1743617719
                  email_verified:
                  type: boolean
                  description: Indicates if the user's email address has been verified.
                  example: true
               required:
                  - sub
                  - name
                  - locale
                  - email
                  - preferred_username
                  - given_name
                  - family_name
                  - zoneinfo
                  - updated_at
                  - email_verified
      '401':
         description: Unauthorized. The provided Bearer token is missing, invalid, or expired.
         content:
            application/json:
            schema:
               $ref: '#/components/schemas/Error'
      '403':
         description: Forbidden. The provided token does not have the required scopes or permissions to access this resource.
         content:
            application/json:
            schema:
               $ref: '#/components/schemas/Error'
components:
securitySchemes:
   okta_oidc:
      type: openIdConnect
      description: Authentication via Okta using OpenID Connect. Requires a Bearer Access Token.
      openIdConnectUrl: https://your-endpoint.okta.com/.well-known/openid-configuration
schemas:
   Error:
      type: object
      properties:
      code:
         type: string
         description: An error code.
      message:
         type: string
         description: A human-readable error message.
      required:
         - code
         - message
```

# Get action confirmation for ADK Tools

Supported in ADKPython v1.14.0TypeScript v0.2.0Go v0.3.0Experimental

Some agent workflows require confirmation for decision making, verification, security, or general oversight. In these cases, you want to get a response from a human or supervising system before proceeding with a workflow. The *Tool Confirmation* feature in the Agent Development Kit (ADK) allows an ADK Tool to pause its execution and interact with a user or other system for confirmation or to gather structured data before proceeding. You can use Tool Confirmation with an ADK Tool in the following ways:

- **[Boolean Confirmation](#boolean-confirmation):** You can configure a tool with a confirmation flag or provider. This option pauses the tool for a yes or no confirmation response.
- **[Advanced Confirmation](#advanced-confirmation):** For scenarios requiring structured data responses, you can configure a tool with a text prompt to explain the confirmation and an expected response.

Experimental

The Tool Confirmation feature is experimental and has some [known limitations](#known-limitations). We welcome your [feedback](https://github.com/google/adk-python/issues/new?template=feature_request.md&labels=tool%20confirmation)!

You can configure how a request is communicated to a user, and the system can also use [remote responses](#remote-response) sent via the ADK server's REST API. When using the confirmation feature with the ADK web user interface, the agent workflow displays a dialog box to the user to request input, as shown in Figure 1:

**Figure 1.** Example confirmation response request dialog box using an advanced, tool response implementation.

The following sections describe how to use this feature for the confirmation scenarios. For a complete code sample, see the [human_tool_confirmation](https://github.com/google/adk-python/blob/fc90ce968f114f84b14829f8117797a4c256d710/contributing/samples/human_tool_confirmation/agent.py) example. There are additional ways to incorporate human input into your agent workflow, for more details, see the [Human-in-the-loop](/agents/multi-agents/#human-in-the-loop-pattern) agent pattern.

## Boolean confirmation

When your tool only requires a simple `yes` or `no` from the user, you can append a confirmation step. In Python, Go, and Java, you can enable this by wrapping the tool with the `FunctionTool` class and setting the `require_confirmation` parameter (or equivalent) to `True`. In TypeScript, you implement this logic manually within the `execute` function using the `ToolContext`.

The following examples show how to enable boolean confirmation:

```python
root_agent = Agent(
    # ...
    tools = [
        # Set require_confirmation to True to require user confirmation
        # for the tool call.
        FunctionTool(reimburse, require_confirmation=True),
    ],
    # ...
)

# This implementation method requires minimal code, but is limited to simple
# approvals from the user or confirming system. For a complete example of this
# approach, see the following code sample for a more detailed example:
# https://github.com/google/adk-python/blob/main/contributing/samples/human_tool_confirmation/agent.py
```

Note

ADK for TypeScript currently requires manual implementation of confirmation logic within the tool's `execute` function.

```typescript
/**
 * A reimbursement tool with dynamic confirmation logic.
 */
export const reimburseTool = new FunctionTool({
  name: 'reimburse',
  description: 'Reimburse an amount. Large amounts (>1000) require manager approval.',
  parameters: z.object({
    amount: z.coerce.number().describe('The amount to reimburse.'),
  }),
  execute: async ({amount}, toolContext) => {
    // 1. Check if we already have a confirmed response.
    if (toolContext?.toolConfirmation?.confirmed) {
      const isLarge = amount > 1000;
      return {
        status: 'SUCCESS',
        message: isLarge 
          ? `Large reimbursement of ${amount} approved by manager and processed.`
          : `Reimbursement of ${amount} has been successfully processed.`,
      };
    }

    // 2. Request a tool confirmation.
    const isLarge = amount > 1000;
    toolContext?.requestConfirmation({
      hint: isLarge 
        ? `The amount ${amount} exceeds the $1000 limit and requires manager approval.`
        : `Do you want to reimburse ${amount}?`,
      payload: {amount},
    });

    // 3. Return a status that tells the agent we are waiting.
    // Note: The model won't see this until the turn resumes after confirmation.
    return {
      status: isLarge ? 'AWAITING_MANAGER_APPROVAL' : 'AWAITING_CONFIRMATION',
      message: 'This request requires approval to proceed.',
    };
  },
});

export const rootAgent = new LlmAgent({
  name: 'Finance_Assistant',
  model: 'gemini-flash-latest',
  instruction: `You are a Finance Assistant. 
  - You MUST use the 'reimburse' tool for ALL reimbursement requests.
  - MANDATORY: Every tool call MUST be accompanied by a text response in the same message.
  - THRESHOLD LOGIC:
    - For amounts <= 1000: Say "I am initiating the reimbursement request for [amount]. Please confirm it to proceed."
    - For amounts > 1000: Say "I am initiating the reimbursement request for [amount]. Since this exceeds $1000, manager approval is required. Please confirm the request to submit it for review."
  - EXAMPLES:
    User: "Reimburse me $45"
    Model: "I am initiating the reimbursement request for 45. Please confirm it to proceed." [Tool Call: reimburse(amount=45)]

    User: "Reimburse me $2500"
    Model: "I am initiating the reimbursement request for 2500. Since this exceeds $1000, manager approval is required. Please confirm the request to submit it for review." [Tool Call: reimburse(amount=2500)]
  - If the user provides a currency symbol (like $), ignore it and pass only the number to the tool.
  - In the Web UI, the user will see a 'Confirm' button. In the terminal, the user should simulate a confirmation response.`,
  tools: [reimburseTool],
});
```

```go
reimburseTool, _ := functiontool.New(functiontool.Config{
    Name:        "reimburse",
    Description: "Reimburse an amount",
    // Set RequireConfirmation to true to require user confirmation
    // for the tool call.
    RequireConfirmation: true,
}, func(ctx tool.Context, args ReimburseArgs) (ReimburseResult, error) {
    // actual implementation
    return ReimburseResult{Status: "ok"}, nil
})

rootAgent, _ := llmagent.New(llmagent.Config{
    // ...
    Tools: []tool.Tool{reimburseTool},
})
```

```java
LlmAgent rootAgent = LlmAgent.builder()
    // ...
    .tools(
        // Set requireConfirmation to true to require user confirmation
        // for the tool call.
        FunctionTool.create(myClassInstance, "reimburse", true)
    )
    // ...
    .build();
```

### Require confirmation function

You can modify the behavior of the confirmation requirement by using a function that returns a boolean response based on the tool's input. In TypeScript, this is handled by adding conditional logic to your `execute` function.

```python
async def confirmation_threshold(
    amount: int, tool_context: ToolContext
) -> bool:
  """Returns true if the amount is greater than 1000."""
  return amount > 1000

root_agent = Agent(
    # ...
    tools = [
        # Pass the threshold function to dynamically require confirmation
        FunctionTool(reimburse, require_confirmation=confirmation_threshold),
    ],
    # ...
)
```

```typescript
/* 
  Note: In TypeScript, dynamic threshold logic is implemented 
  directly within the tool's 'execute' function as shown above.
*/
```

```go
reimburseTool, _ := functiontool.New(functiontool.Config{
    Name:        "reimburse",
    Description: "Reimburse an amount",
    // RequireConfirmationProvider allows for dynamic determination
    // of whether user confirmation is needed.
    RequireConfirmationProvider: func(args ReimburseArgs) bool {
        return args.Amount > 1000
    },
}, func(ctx tool.Context, args ReimburseArgs) (ReimburseResult, error) {
    // actual implementation
    return ReimburseResult{Status: "ok"}, nil
})
```

```java
// In ADK Java, dynamic threshold confirmation logic is evaluated directly
// inside the tool logic using the ToolContext rather than via a lambda parameter.
public Map<String, Object> reimburse(
    @Schema(name="amount") int amount, ToolContext toolContext) {

  // 1. Dynamic threshold check
  if (amount > 1000) {
    Optional<ToolConfirmation> toolConfirmation = toolContext.toolConfirmation();
    if (toolConfirmation.isEmpty()) {
       toolContext.requestConfirmation("Amount > 1000 requires approval.");
       return Map.of("status", "Pending manager approval.");
    } else if (!toolConfirmation.get().confirmed()) {
       return Map.of("status", "Reimbursement rejected.");
    }
  }

  // 2. Proceed with actual tool logic
  return Map.of("status", "ok", "reimbursedAmount", amount);
}

LlmAgent rootAgent = LlmAgent.builder()
    // ...
    .tools(
        // No requireConfirmation flag is set because the custom threshold
        // logic is already handled inside the method!
        FunctionTool.create(this, "reimburse")
    )
    // ...
    .build();
```

## Advanced confirmation

When a tool confirmation requires more details for the user or a more complex response, use a tool_confirmation implementation. This approach extends the `ToolContext` object to add a text description of the request for the user and allows for more complex response data. When implementing tool confirmation this way, you can pause a tool's execution, request specific information, and then resume the tool with the provided data.

This confirmation flow has a request stage where the system assembles and sends an input request human response, and a response stage where the system receives and processes the returned data.

### Confirmation definition

When creating a Tool with advanced confirmation, use the `Tool Context Request Confirmation` method with `hint` and `payload` parameters:

- `hint`: Descriptive message that explains what is needed from the user.
- `payload`: The structure of the data you expect in return. This must be serializable into a JSON-formatted string.

For a complete example of this approach, see the [human_tool_confirmation](https://github.com/google/adk-python/blob/fc90ce968f114f84b14829f8117797a4c256d710/contributing/samples/human_tool_confirmation/agent.py) code sample. Keep in mind that the agent workflow tool execution pauses while a confirmation is obtained. After confirmation is received, you can access the confirmation response in the `tool_confirmation.payload` object and then proceed with the execution of the workflow.

The following code shows an example implementation for a tool that processes time off requests for an employee:

```python
def request_time_off(days: int, tool_context: ToolContext):
    """Request day off for the employee."""
    # ...
    tool_confirmation = tool_context.tool_confirmation
    if not tool_confirmation:
        tool_context.request_confirmation(
            hint=(
                'Please approve or reject the tool call request_time_off() by'
                ' responding with a FunctionResponse with an expected'
                ' ToolConfirmation payload.'
            ),
            payload={
                'approved_days': 0,
            },
        )
        # Return intermediate status indicating that the tool is waiting for
        # a confirmation response:
        return {'status': 'Manager approval is required.'}

    approved_days = tool_confirmation.payload['approved_days']
    approved_days = min(approved_days, days)
    if approved_days == 0:
        return {'status': 'The time off request is rejected.', 'approved_days': 0}
    return {
        'status': 'ok',
        'approved_days': approved_days,
    }
```

```typescript
/**
 * A tool that requests time off for an employee.
 * It uses the Advanced Confirmation pattern to request manager approval.
 */
export const requestTimeOffTool = new FunctionTool({
  name: 'request_time_off',
  description: 'Request days off for the employee.',
  parameters: z.object({
    days: z.number().describe('The number of days requested.'),
  }),
  execute: async ({days}, toolContext) => {
    const confirmation = toolContext?.toolConfirmation;

    if (!confirmation) {
      // Step 1: Request confirmation with a payload
      toolContext?.requestConfirmation({
        hint:
          'Please approve or reject the tool call request_time_off() by ' +
          'responding with a FunctionResponse with an expected ' +
          'ToolConfirmation payload.',
        payload: {
          approved_days: 0,
        },
      });

      // Return a descriptive status to the agent
      return {
        status: 'PENDING_MANAGER_APPROVAL',
        message: `A request for ${days} days is pending manager approval.`,
      };
    }

    // Step 2: Process the confirmation response
    if (!confirmation.confirmed) {
      return {
        status: 'CANCELLED',
        message: 'The request was cancelled by the user.',
      };
    }

    let approvedDays = (confirmation.payload as any)['approved_days'] as number;
    approvedDays = Math.min(approvedDays, days);

    if (approvedDays === 0) {
      return {
        status: 'REJECTED',
        message: 'The time off request was rejected by the manager.',
        approved_days: 0,
      };
    }

    return {
      status: 'SUCCESS',
      message: `The request for ${days} days was approved (Total approved: ${approvedDays}).`,
      approved_days: approvedDays,
    };
  },
});

export const rootAgent = new LlmAgent({
  name: 'HR_Assistant',
  model: 'gemini-flash-latest',
  instruction: `You are an HR Assistant. 
  1. Use the 'request_time_off' tool to help employees with leave requests.
  2. MANDATORY: Every tool call MUST be accompanied by a text response in the same message.
  3. EXAMPLE:
     User: "I want 5 days off"
     Model: "I am initiating your leave request for 5 days. Management approval is required, so please confirm this request." [Tool Call: request_time_off(days=5)]
  4. In the terminal, if they want to 'confirm', tell them to simulate a confirmation response. 
  5. Once confirmed, the system will automatically provide the result of the approval.`,
  tools: [requestTimeOffTool],
});
```

```go
func requestTimeOff(ctx tool.Context, args RequestTimeOffArgs) (map[string]any, error) {
    confirmation := ctx.ToolConfirmation()
    if confirmation == nil {
        ctx.RequestConfirmation(
            "Please approve or reject the tool call requestTimeOff() by "+
            "responding with a FunctionResponse with an expected "+
            "ToolConfirmation payload.",
            map[string]any{"approved_days": 0},
        )
        return map[string]any{"status": "Manager approval is required."}, nil
    }

    payload := confirmation.Payload.(map[string]any)
    // Values in map[string]any from JSON are float64 by default in Go
    approvedDays := int(payload["approved_days"].(float64))
    approvedDays = min(approvedDays, args.Days)

    if approvedDays == 0 {
        return map[string]any{"status": "The time off request is rejected.", "approved_days": 0}, nil
    }

    return map[string]any{
        "status": "ok",
        "approved_days": approvedDays,
    }, nil
}
```

```java
public Map<String, Object> requestTimeOff(
    @Schema(name="days") int days,
    ToolContext toolContext) {
    // Request day off for the employee.
    // ...
    Optional<ToolConfirmation> toolConfirmation = toolContext.toolConfirmation();
    if (toolConfirmation.isEmpty()) {
        toolContext.requestConfirmation(
            "Please approve or reject the tool call requestTimeOff() by " +
            "responding with a FunctionResponse with an expected " +
            "ToolConfirmation payload.",
            Map.of("approved_days", 0)
        );
        // Return intermediate status indicating that the tool is waiting for
        // a confirmation response:
        return Map.of("status", "Manager approval is required.");
    }

    Map<String, Object> payload = (Map<String, Object>) toolConfirmation.get().payload();
    int approvedDays = (int) payload.get("approved_days");
    approvedDays = Math.min(approvedDays, days);

    if (approvedDays == 0) {
        return Map.of("status", "The time off request is rejected.", "approved_days", 0);
    }

    return Map.of(
        "status", "ok",
        "approved_days", approvedDays
    );
}
```

## Remote confirmation with REST API

If there is no active user interface for a human confirmation of an agent workflow, you can handle the confirmation through a command-line interface or by routing it through another channel like email or a chat application. To confirm the tool call, the user or calling application needs to send a `FunctionResponse` event with the tool confirmation data.

You can send the request to the ADK API server's `/run` or `/run_sse` endpoint, or directly to the ADK runner. The following example uses a `curl` command to send the confirmation to the `/run_sse` endpoint:

```bash
 curl -X POST http://localhost:8000/run_sse \
 -H "Content-Type: application/json" \
 -d '{
    "app_name": "human_tool_confirmation",
    "user_id": "user",
    "session_id": "7828f575-2402-489f-8079-74ea95b6a300",
    "new_message": {
        "parts": [
            {
                "function_response": {
                    "id": "adk-13b84a8c-c95c-4d66-b006-d72b30447e35",
                    "name": "adk_request_confirmation",
                    "response": {
                        "confirmed": true,
                        "payload": {
                            "approved_days": 5
                        }
                    }
                }
            }
        ],
        "role": "user"
    }
}'
```

A REST-based response for a confirmation must meet the following requirements:

- The `id` in the `function_response` should match the `function_call_id` from the `adk_request_confirmation` `FunctionCall` event.

- The `name` should be `adk_request_confirmation`.

- The `response` object contains the `confirmed` status and any additional `payload` data.

  Note: Confirmation with Resume feature

  If your ADK agent workflow is configured with the [Resume](/runtime/resume/) feature, you also must include the Invocation ID (`invocation_id`) parameter with the confirmation response. The Invocation ID you provide must be the same invocation that generated the confirmation request, otherwise the system starts a new invocation with the confirmation response. If your agent uses the Resume feature, consider including the Invocation ID as a parameter with your confirmation request, so it can be included with the response. For more details on using the Resume feature, see [Resume stopped agents](/runtime/resume/).

## Known limitations

The tool confirmation feature has the following limitations:

- [DatabaseSessionService](/api-reference/python/google-adk.html#google.adk.sessions.DatabaseSessionService) is not supported by this feature.
- [VertexAiSessionService](/api-reference/python/google-adk.html#google.adk.sessions.VertexAiSessionService) is not supported by this feature.

## Next steps

For more information on building ADK tools for agent workflows, see [Function tools](/tools-custom/function-tools/).

# Function tools

Supported in ADKPython v0.1.0Typescript v0.2.0Go v0.1.0Java v0.1.0

When pre-built ADK tools don't meet your requirements, you can create custom *function tools*. Building function tools allows you to create tailored functionality, such as connecting to proprietary databases or implementing unique algorithms. For example, a function tool, `myfinancetool`, might be a function that calculates a specific financial metric. ADK also supports long-running functions, so if that calculation takes a while, the agent can continue working on other tasks.

ADK offers several ways to create functions tools, each suited to different levels of complexity and control:

- [Function Tools](#function-tool)
- [Long Running Function Tools](#long-run-tool)
- [Agents-as-a-Tool](#agent-tool)

## Function Tools

Transforming a Python function into a tool is a straightforward way to integrate custom logic into your agents. When you assign a function to an agent’s `tools` list, the framework automatically wraps it as a `FunctionTool`.

### How it Works

The ADK framework automatically inspects your Python function's signature—including its name, docstring, parameters, type hints, and default values—to generate a schema. This schema is what the LLM uses to understand the tool's purpose, when to use it, and what arguments it requires.

### Defining Function Signatures

A well-defined function signature is crucial for the LLM to use your tool correctly.

#### Parameters

##### Required Parameters

A parameter is considered **required** if it has a type hint but **no default value**. The LLM must provide a value for this argument when it calls the tool. The parameter's description is taken from the function's docstring.

Example: Required Parameters

```python
def get_weather(city: str, unit: str):
    """
    Retrieves the weather for a city in the specified unit.

    Args:
        city (str): The city name.
        unit (str): The temperature unit, either 'Celsius' or 'Fahrenheit'.
    """
    # ... function logic ...
    return {"status": "success", "report": f"Weather for {city} is sunny."}
```

In this example, both `city` and `unit` are mandatory. If the LLM tries to call `get_weather` without one of them, the ADK will return an error to the LLM, prompting it to correct the call.

In Go, you use struct tags to control the JSON schema. The two primary tags are `json` and `jsonschema`.

A parameter is considered **required** if its struct field does **not** have the `omitempty` or `omitzero` option in its `json` tag.

The `jsonschema` tag is used to provide the argument's description. This is crucial for the LLM to understand what the argument is for.

Example: Required Parameters

```go
// GetWeatherParams defines the arguments for the getWeather tool.
type GetWeatherParams struct {
    // This field is REQUIRED (no "omitempty").
    // The jsonschema tag provides the description.
    Location string `json:"location" jsonschema:"The city and state, e.g., San Francisco, CA"`

    // This field is also REQUIRED.
    Unit     string `json:"unit" jsonschema:"The temperature unit, either 'celsius' or 'fahrenheit'"`
}
```

In this example, both `location` and `unit` are mandatory.

In Java, primitive types (e.g., `int`, `double`, `boolean`) are inherently **required** because they cannot be null. For object types (like `String` or `Integer`), they are typically considered required unless explicitly marked as optional.

The `@Schema` annotation is used to provide the argument's description and can explicitly define parameter properties. This is crucial for the LLM to understand what the argument is for.

Example: Required Parameters

```java
// The @Schema annotation on the parameter provides the description.
public static Map<String, Object> getWeather(
    @Schema(description = "The city and state, e.g., San Francisco, CA", name = "location")
    String location,

    @Schema(description = "The temperature unit, either 'Celsius' or 'Fahrenheit'", name = "unit")
    String unit) {

    // ... function logic ...
    return Map.of("status", "success", "report", "Weather for " + location + " is sunny.");
}
```

In this example, both `location` and `unit` are mandatory.

##### Optional Parameters

A parameter is considered **optional** if you provide a **default value**. This is the standard Python way to define optional arguments. You can also mark a parameter as optional using `typing.Optional[SomeType]` or the `| None` syntax (Python 3.10+).

Example: Optional Parameters

```python
def search_flights(destination: str, departure_date: str, flexible_days: int = 0):
    """
    Searches for flights.

    Args:
        destination (str): The destination city.
        departure_date (str): The desired departure date.
        flexible_days (int, optional): Number of flexible days for the search. Defaults to 0.
    """
    # ... function logic ...
    if flexible_days > 0:
        return {"status": "success", "report": f"Found flexible flights to {destination}."}
    return {"status": "success", "report": f"Found flights to {destination} on {departure_date}."}
```

Here, `flexible_days` is optional. The LLM can choose to provide it, but it's not required.

A parameter is considered **optional** if its struct field has the `omitempty` or `omitzero` option in its `json` tag.

Example: Optional Parameters

```go
// GetWeatherParams defines the arguments for the getWeather tool.
type GetWeatherParams struct {
    // Location is required.
    Location string `json:"location" jsonschema:"The city and state, e.g., San Francisco, CA"`

    // Unit is optional.
    Unit string `json:"unit,omitempty" jsonschema:"The temperature unit, either 'celsius' or 'fahrenheit'"`

    // Days is optional.
    Days int `json:"days,omitzero" jsonschema:"The number of forecast days to return (defaults to 1)"`
}
```

Here, `unit` and `days` are optional. The LLM can choose to provide them, but they are not required.

A parameter can be considered **optional** in Java by using object types that allow `null` values (such as `Integer` instead of `int`), or by explicitly defining it as optional using `java.util.Optional`.

Example: Optional Parameters

```java
import java.util.Map;
import java.util.Optional;

public static Map<String, Object> searchFlights(
    @Schema(description = "The destination city.", name = "destination")
    String destination,

    @Schema(description = "The desired departure date.", name = "departureDate")
    String departureDate,

    @Schema(description = "Number of flexible days for the search. Defaults to 0.", name = "flexibleDays")
    Optional<Integer> flexibleDays) {

    // ... function logic ...
    int days = flexibleDays.orElse(0);
    if (days > 0) {
        return Map.of("status", "success", "report", "Found flexible flights to " + destination + ".");
    }
    return Map.of("status", "success", "report", "Found flights to " + destination + " on " + departureDate + ".");
}
```

Here, `flexibleDays` is optional. The LLM can choose to provide it, but it's not required.

##### Optional Parameters with `typing.Optional`

You can also mark a parameter as optional using `typing.Optional[SomeType]` or the `| None` syntax (Python 3.10+). This signals that the parameter can be `None`. When combined with a default value of `None`, it behaves as a standard optional parameter.

Example: `typing.Optional`

```python
from typing import Optional

def create_user_profile(username: str, bio: Optional[str] = None):
    """
    Creates a new user profile.

    Args:
        username (str): The user's unique username.
        bio (str, optional): A short biography for the user. Defaults to None.
    """
    # ... function logic ...
    if bio:
        return {"status": "success", "message": f"Profile for {username} created with a bio."}
    return {"status": "success", "message": f"Profile for {username} created."}
```

##### Variadic Parameters (`*args` and `**kwargs`)

While you can include `*args` (variable positional arguments) and `**kwargs` (variable keyword arguments) in your function signature for other purposes, they are **ignored by the ADK framework** when generating the tool schema for the LLM. The LLM will not be aware of them and cannot pass arguments to them. It's best to rely on explicitly defined parameters for all data you expect from the LLM.

#### Return Type

The preferred return type for a Function Tool is a **dictionary** in Python, a **Map** or custom **Record or POJO** in Java, or an **object** in TypeScript. This allows you to structure the response with key-value pairs, providing context and clarity to the LLM. If your function returns a type other than a dictionary or map, the framework automatically wraps it into a dictionary with a single key named **"result"**.

Strive to make your return values as descriptive as possible. *For example,* instead of returning a numeric error code, return a dictionary with an "error_message" key containing a human-readable explanation. **Remember that the LLM**, not a piece of code, needs to understand the result. As a best practice, include a "status" key in your return dictionary to indicate the overall outcome (e.g., "success", "error", "pending"), providing the LLM with a clear signal about the operation's state.

#### Docstrings

The docstring of your function serves as the tool's **description** and is sent to the LLM. Therefore, a well-written and comprehensive docstring is crucial for the LLM to understand how to use the tool effectively. Clearly explain the purpose of the function, the meaning of its parameters, and the expected return values. In Java, you can use Javadoc comments or the `@Schema(description="...")` annotation on your method to serve as this description.

### Passing Data Between Tools

When an agent calls multiple tools in a sequence, you might need to pass data from one tool to another. The recommended way to do this is by using the `temp:` prefix in the session state.

A tool can write data to a `temp:` variable, and a subsequent tool can read it. This data is only available for the current invocation and is discarded afterwards.

Shared Invocation Context

All tool calls within a single agent turn share the same `InvocationContext`. This means they also share the same temporary (`temp:`) state, which is how data can be passed between them.

### Example

Example

This tool is a python function which obtains the Stock price of a given Stock ticker/ symbol.

Note: You need to `pip install yfinance` library before using this tool.

```python
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
from google.genai import types

import yfinance as yf


APP_NAME = "stock_app"
USER_ID = "1234"
SESSION_ID = "session1234"

def get_stock_price(symbol: str):
    """
    Retrieves the current stock price for a given symbol.

    Args:
        symbol (str): The stock symbol (e.g., "AAPL", "GOOG").

    Returns:
        float: The current stock price, or None if an error occurs.
    """
    try:
        stock = yf.Ticker(symbol)
        historical_data = stock.history(period="1d")
        if not historical_data.empty:
            current_price = historical_data['Close'].iloc[-1]
            return current_price
        else:
            return None
    except Exception as e:
        print(f"Error retrieving stock price for {symbol}: {e}")
        return None


stock_price_agent = Agent(
    model='gemini-2.0-flash',
    name='stock_agent',
    instruction= 'You are an agent who retrieves stock prices. If a ticker symbol is provided, fetch the current price. If only a company name is given, first perform a Google search to find the correct ticker symbol before retrieving the stock price. If the provided ticker symbol is invalid or data cannot be retrieved, inform the user that the stock price could not be found.',
    description='This agent specializes in retrieving real-time stock prices. Given a stock ticker symbol (e.g., AAPL, GOOG, MSFT) or the stock name, use the tools and reliable data sources to provide the most up-to-date price.',
    tools=[get_stock_price], # You can add Python functions directly to the tools list; they will be automatically wrapped as FunctionTools.
)


# Session and Runner
async def setup_session_and_runner():
    session_service = InMemorySessionService()
    session = await session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID)
    runner = Runner(agent=stock_price_agent, app_name=APP_NAME, session_service=session_service)
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
await call_agent_async("stock price of GOOG")
```

The return value from this tool will be wrapped into a dictionary.

```json
{"result": "$123"}
```

This tool retrieves the mocked value of a stock price.

```typescript
/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import {Content, Part, createUserContent} from '@google/genai';
import { stringifyContent, FunctionTool, InMemoryRunner, LlmAgent } from '@google/adk';
import {z} from 'zod';

// Define the function to get the stock price
async function getStockPrice({ticker}: {ticker: string}): Promise<Record<string, unknown>> {
  console.log(`Getting stock price for ${ticker}`);
  // In a real-world scenario, you would fetch the stock price from an API
  const price = (Math.random() * 1000).toFixed(2);
  return {price: `$${price}`};
}

async function main() {
  // Define the schema for the tool's parameters using Zod
  const getStockPriceSchema = z.object({
    ticker: z.string().describe('The stock ticker symbol to look up.'),
  });

  // Create a FunctionTool from the function and schema
  const stockPriceTool = new FunctionTool({
    name: 'getStockPrice',
    description: 'Gets the current price of a stock.',
    parameters: getStockPriceSchema,
    execute: getStockPrice,
  });

  // Define the agent that will use the tool
  const stockAgent = new LlmAgent({
    name: 'stock_agent',
    model: 'gemini-2.5-flash',
    instruction: 'You can get the stock price of a company.',
    tools: [stockPriceTool],
  });

  // Create a runner for the agent
  const runner = new InMemoryRunner({agent: stockAgent});

  // Create a new session
  const session = await runner.sessionService.createSession({
    appName: runner.appName,
    userId: 'test-user',
  });

  const userContent: Content = createUserContent('What is the stock price of GOOG?');

  // Run the agent and get the response
  const response = [];
  for await (const event of runner.runAsync({
    userId: session.userId,
    sessionId: session.id,
    newMessage: userContent,
  })) {
    response.push(event);
  }

  // Print the final response from the agent
  const finalResponse = response[response.length - 1];
  if (finalResponse?.content?.parts?.length) {
    console.log(stringifyContent(finalResponse));
  }
}

main();
```

The return value from this tool will be an object.

```json
For input `GOOG`: {"price": 2800.0, "currency": "USD"}
```

This tool retrieves the mocked value of a stock price.

```go
import (
    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/runner"
    "google.golang.org/adk/session"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/functiontool"
    "google.golang.org/genai"
)

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
    "strings"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/runner"
    "google.golang.org/adk/session"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/agenttool"
    "google.golang.org/adk/tool/functiontool"

    "google.golang.org/genai"
)

// mockStockPrices provides a simple in-memory database of stock prices
// to simulate a real-world stock data API. This allows the example to
// demonstrate tool functionality without making external network calls.
var mockStockPrices = map[string]float64{
    "GOOG": 300.6,
    "AAPL": 123.4,
    "MSFT": 234.5,
}

// getStockPriceArgs defines the schema for the arguments passed to the getStockPrice tool.
// Using a struct is the recommended approach in the Go ADK as it provides strong
// typing and clear validation for the expected inputs.
type getStockPriceArgs struct {
    Symbol string `json:"symbol" jsonschema:"The stock ticker symbol, e.g., GOOG"`
}

// getStockPriceResults defines the output schema for the getStockPrice tool.
type getStockPriceResults struct {
    Symbol string  `json:"symbol"`
    Price  float64 `json:"price,omitempty"`
    Error  string  `json:"error,omitempty"`
}

// getStockPrice is a tool that retrieves the stock price for a given ticker symbol
// from the mockStockPrices map. It demonstrates how a function can be used as a
// tool by an agent. If the symbol is found, it returns a struct containing the
// symbol and its price. Otherwise, it returns a struct with an error message.
func getStockPrice(ctx tool.Context, input getStockPriceArgs) (getStockPriceResults, error) {
    symbolUpper := strings.ToUpper(input.Symbol)
    if price, ok := mockStockPrices[symbolUpper]; ok {
        fmt.Printf("Tool: Found price for %s: %f\n", input.Symbol, price)
        return getStockPriceResults{Symbol: input.Symbol, Price: price}, nil
    }
    return getStockPriceResults{}, fmt.Errorf("no data found for symbol")
}

// createStockAgent initializes and configures an LlmAgent.
// This agent is equipped with the getStockPrice tool and is instructed
// on how to respond to user queries about stock prices. It uses the
// Gemini model to understand user intent and decide when to use its tools.
func createStockAgent(ctx context.Context) (agent.Agent, error) {
    stockPriceTool, err := functiontool.New(
        functiontool.Config{
            Name:        "get_stock_price",
            Description: "Retrieves the current stock price for a given symbol.",
        },
        getStockPrice)
    if err != nil {
        return nil, err
    }

    model, err := gemini.NewModel(ctx, "gemini-2.5-flash", &genai.ClientConfig{})

    if err != nil {
        log.Fatalf("Failed to create model: %v", err)
    }

    return llmagent.New(llmagent.Config{
        Name:        "stock_agent",
        Model:       model,
        Instruction: "You are an agent who retrieves stock prices. If a ticker symbol is provided, fetch the current price. If only a company name is given, first perform a Google search to find the correct ticker symbol before retrieving the stock price. If the provided ticker symbol is invalid or data cannot be retrieved, inform the user that the stock price could not be found.",
        Description: "This agent specializes in retrieving real-time stock prices. Given a stock ticker symbol (e.g., AAPL, GOOG, MSFT) or the stock name, use the tools and reliable data sources to provide the most up-to-date price.",
        Tools: []tool.Tool{
            stockPriceTool,
        },
    })
}

// userID and appName are constants used to identify the user and application
// throughout the session. These values are important for logging, tracking,
// and managing state across different agent interactions.
const (
    userID  = "example_user_id"
    appName = "example_app"
)

// callAgent orchestrates the execution of the agent for a given prompt.
// It sets up the necessary services, creates a session, and uses a runner
// to manage the agent's lifecycle. It streams the agent's responses and
// prints them to the console, handling any potential errors during the run.
func callAgent(ctx context.Context, a agent.Agent, prompt string) {
    sessionService := session.InMemoryService()
    // Create a new session for the agent interactions.
    session, err := sessionService.Create(ctx, &session.CreateRequest{
        AppName: appName,
        UserID:  userID,
    })
    if err != nil {
        log.Fatalf("Failed to create the session service: %v", err)
    }
    config := runner.Config{
        AppName:        appName,
        Agent:          a,
        SessionService: sessionService,
    }

    // Create the runner to manage the agent execution.
    r, err := runner.New(config)

    if err != nil {
        log.Fatalf("Failed to create the runner: %v", err)
    }

    sessionID := session.Session.ID()

    userMsg := &genai.Content{
        Parts: []*genai.Part{
            genai.NewPartFromText(prompt),
        },
        Role: string(genai.RoleUser),
    }

    for event, err := range r.Run(ctx, userID, sessionID, userMsg, agent.RunConfig{
        StreamingMode: agent.StreamingModeNone,
    }) {
        if err != nil {
            fmt.Printf("\nAGENT_ERROR: %v\n", err)
        } else {
            for _, p := range event.Content.Parts {
                fmt.Print(p.Text)
            }
        }
    }
}

// RunAgentSimulation serves as the entry point for this example.
// It creates the stock agent and then simulates a series of user interactions
// by sending different prompts to the agent. This function showcases how the
// agent responds to various queries, including both successful and unsuccessful
// attempts to retrieve stock prices.
func RunAgentSimulation() {
    // Create the stock agent
    agent, err := createStockAgent(context.Background())
    if err != nil {
        panic(err)
    }

    fmt.Println("Agent created:", agent.Name())

    prompts := []string{
        "stock price of GOOG",
        "What's the price of MSFT?",
        "Can you find the stock price for an unknown company XYZ?",
    }

    // Simulate running the agent with different prompts
    for _, prompt := range prompts {
        fmt.Printf("\nPrompt: %s\nResponse: ", prompt)
        callAgent(context.Background(), agent, prompt)
        fmt.Println("\n---")
    }
}

// createSummarizerAgent creates an agent whose sole purpose is to summarize text.
func createSummarizerAgent(ctx context.Context) (agent.Agent, error) {
    model, err := gemini.NewModel(ctx, "gemini-2.5-flash", &genai.ClientConfig{})
    if err != nil {
        return nil, err
    }
    return llmagent.New(llmagent.Config{
        Name:        "SummarizerAgent",
        Model:       model,
        Instruction: "You are an expert at summarizing text. Take the user's input and provide a concise summary.",
        Description: "An agent that summarizes text.",
    })
}

// createMainAgent creates the primary agent that will use the summarizer agent as a tool.
func createMainAgent(ctx context.Context, tools ...tool.Tool) (agent.Agent, error) {
    model, err := gemini.NewModel(ctx, "gemini-2.5-flash", &genai.ClientConfig{})
    if err != nil {
        return nil, err
    }
    return llmagent.New(llmagent.Config{
        Name:  "MainAgent",
        Model: model,
        Instruction: "You are a helpful assistant. If you are asked to summarize a long text, use the 'summarize' tool. " +
            "After getting the summary, present it to the user by saying 'Here is a summary of the text:'.",
        Description: "The main agent that can delegate tasks.",
        Tools:       tools,
    })
}

func RunAgentAsToolSimulation() {
    ctx := context.Background()

    // 1. Create the Tool Agent (Summarizer)
    summarizerAgent, err := createSummarizerAgent(ctx)
    if err != nil {
        log.Fatalf("Failed to create summarizer agent: %v", err)
    }

    // 2. Wrap the Tool Agent in an AgentTool
    summarizeTool := agenttool.New(summarizerAgent, &agenttool.Config{
        SkipSummarization: true,
    })

    // 3. Create the Main Agent and provide it with the AgentTool
    mainAgent, err := createMainAgent(ctx, summarizeTool)
    if err != nil {
        log.Fatalf("Failed to create main agent: %v", err)
    }

    // 4. Run the main agent
    prompt := `
        Please summarize this text for me:
        Quantum computing represents a fundamentally different approach to computation,
        leveraging the bizarre principles of quantum mechanics to process information. Unlike classical computers
        that rely on bits representing either 0 or 1, quantum computers use qubits which can exist in a state of superposition - effectively
        being 0, 1, or a combination of both simultaneously. Furthermore, qubits can become entangled,
        meaning their fates are intertwined regardless of distance, allowing for complex correlations. This parallelism and
        interconnectedness grant quantum computers the potential to solve specific types of incredibly complex problems - such
        as drug discovery, materials science, complex system optimization, and breaking certain types of cryptography - far
        faster than even the most powerful classical supercomputers could ever achieve, although the technology is still largely in its developmental stages.
    `
    fmt.Printf("\nPrompt: %s\nResponse: ", prompt)
    callAgent(context.Background(), mainAgent, prompt)
    fmt.Println("\n---")
}


func main() {
    fmt.Println("Attempting to run the agent simulation...")
    RunAgentSimulation()
    fmt.Println("\nAttempting to run the agent-as-a-tool simulation...")
    RunAgentAsToolSimulation()
}
```

The return value from this tool will be a `getStockPriceResults` instance.

```json
For input `{"symbol": "GOOG"}`: {"price":300.6,"symbol":"GOOG"}
```

This tool retrieves the mocked value of a stock price.

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.events.Event;
import com.google.adk.runner.InMemoryRunner;
import com.google.adk.sessions.Session;
import com.google.adk.tools.Annotations.Schema;
import com.google.adk.tools.FunctionTool;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import io.reactivex.rxjava3.core.Flowable;
import java.util.Map;
import yahoofinance.Stock;
import yahoofinance.YahooFinance;
import java.math.BigDecimal;

public class StockPriceAgent {

  private static final String APP_NAME = "stock_agent";
  private static final String USER_ID = "user1234";

  // No longer using mock stock data - we fetch it live!

  @Schema(description = "Retrieves the current stock price for a given symbol.")
  public static Map<String, Object> getStockPrice(
      @Schema(description = "The stock symbol (e.g., \"AAPL\", \"GOOG\")",
        name = "symbol")
      String symbol) {

    try {
      Stock stock = YahooFinance.get(symbol.toUpperCase());
      if (stock != null && stock.getQuote().getPrice() != null) {
        BigDecimal currentPrice = stock.getQuote().getPrice();
        System.out.println("Tool: Found live price for " + symbol + ": " + currentPrice);
        return Map.of("symbol", symbol, "price", currentPrice.doubleValue());
      } else {
        return Map.of("symbol", symbol, "error", "No data found for symbol");
      }
    } catch (Exception e) {
      return Map.of("symbol", symbol, "error", e.getMessage());
    }
  }

  public static void callAgent(String prompt) {
    // Create the FunctionTool from the Java method
    FunctionTool getStockPriceTool = FunctionTool.create(StockPriceAgent.class, "getStockPrice");

    LlmAgent stockPriceAgent =
        LlmAgent.builder()
            .model("gemini-2.0-flash")
            .name("stock_agent")
            .instruction(
                "You are an agent who retrieves stock prices. If a ticker symbol is provided, fetch the current price. If only a company name is given, first perform a Google search to find the correct ticker symbol before retrieving the stock price. If the provided ticker symbol is invalid or data cannot be retrieved, inform the user that the stock price could not be found.")
            .description(
                "This agent specializes in retrieving real-time stock prices. Given a stock ticker symbol (e.g., AAPL, GOOG, MSFT) or the stock name, use the tools and reliable data sources to provide the most up-to-date price.")
            .tools(getStockPriceTool) // Add the Java FunctionTool
            .build();

    // Create an InMemoryRunner
    InMemoryRunner runner = new InMemoryRunner(stockPriceAgent, APP_NAME);
    // InMemoryRunner automatically creates a session service. Create a session using the service
    Session session = runner.sessionService().createSession(APP_NAME, USER_ID).blockingGet();
    Content userMessage = Content.fromParts(Part.fromText(prompt));

    // Run the agent
    Flowable<Event> eventStream = runner.runAsync(USER_ID, session.id(), userMessage);

    // Stream event response
    eventStream.blockingForEach(
        event -> {
          if (event.finalResponse()) {
            System.out.println(event.stringifyContent());
          }
        });
  }

  public static void main(String[] args) {
    callAgent("stock price of GOOG");
    callAgent("What's the price of MSFT?");
    callAgent("Can you find the stock price for an unknown company XYZ?");
  }
}
```

The return value from this tool will be wrapped into a Map.

```json
For input `GOOG`: {"symbol": "GOOG", "price": "1.0"}
```

### Best Practices

While you have considerable flexibility in defining your function, remember that simplicity enhances usability for the LLM. Consider these guidelines:

- **Fewer Parameters are Better:** Minimize the number of parameters to reduce complexity.
- **Simple Data Types:** Favor primitive data types like `str` and `int` over custom classes whenever possible.
- **Meaningful Names:** The function's name and parameter names significantly influence how the LLM interprets and utilizes the tool. Choose names that clearly reflect the function's purpose and the meaning of its inputs. Avoid generic names like `do_stuff()` or `beAgent()`.
- **Build for Parallel Execution:** Improve function calling performance when multiple tools are run by building for asynchronous operation. For information on enabling parallel execution for tools, see [Increase tool performance with parallel execution](/tools-custom/performance/).

## Long Running Function Tools

This tool is designed to help you start and manage tasks that are handled outside the operation of your agent workflow, and require a significant amount of processing time, without blocking the agent's execution. This tool is a subclass of `FunctionTool`.

When using a `LongRunningFunctionTool`, your function can initiate the long-running operation and optionally return an **initial result**, such as a long-running operation id. Once a long running function tool is invoked the agent runner pauses the agent run and lets the agent client to decide whether to continue or wait until the long-running operation finishes. The agent client can query the progress of the long-running operation and send back an intermediate or final response. The agent can then continue with other tasks. An example is the human-in-the-loop scenario where the agent needs human approval before proceeding with a task.

Warning: Execution handling

Long Running Function Tools are designed to help you start and *manage* long running tasks as part of your agent workflow, but ***not perform*** the actual, long task. For tasks that require significant time to complete, you should implement a separate server to do the task.

Tip: Parallel execution

Depending on the type of tool you are building, designing for asynchronous operation may be a better solution than creating a long running tool. For more information, see [Increase tool performance with parallel execution](/tools-custom/performance/).

### How it Works

In Python, you wrap a function with `LongRunningFunctionTool`. In Java, you pass a Method name to `LongRunningFunctionTool.create()`. In TypeScript, you instantiate the `LongRunningFunctionTool` class.

1. **Initiation:** When the LLM calls the tool, your function starts the long-running operation.
1. **Initial Updates:** Your function should optionally return an initial result (e.g. the long-running operation id). The ADK framework takes the result and sends it back to the LLM packaged within a `FunctionResponse`. This allows the LLM to inform the user (e.g., status, percentage complete, messages). And then the agent run is ended / paused.
1. **Continue or Wait:** After each agent run is completed. Agent client can query the progress of the long-running operation and decide whether to continue the agent run with an intermediate response (to update the progress) or wait until a final response is retrieved. Agent client should send the intermediate or final response back to the agent for the next run.
1. **Framework Handling:** The ADK framework manages the execution. It sends the intermediate or final `FunctionResponse` sent by agent client to the LLM to generate a user friendly message.

### Creating the Tool

Define your tool function and wrap it using the `LongRunningFunctionTool` class:

```python
# 1. Define the long running function
def ask_for_approval(
    purpose: str, amount: float
) -> dict[str, Any]:
    """Ask for approval for the reimbursement."""
    # create a ticket for the approval
    # Send a notification to the approver with the link of the ticket
    return {'status': 'pending', 'approver': 'Sean Zhou', 'purpose' : purpose, 'amount': amount, 'ticket-id': 'approval-ticket-1'}

def reimburse(purpose: str, amount: float) -> str:
    """Reimburse the amount of money to the employee."""
    # send the reimbrusement request to payment vendor
    return {'status': 'ok'}

# 2. Wrap the function with LongRunningFunctionTool
long_running_tool = LongRunningFunctionTool(func=ask_for_approval)
```

```typescript
// 1. Define the long-running function
function askForApproval(args: {purpose: string; amount: number}) {
  /**
   * Ask for approval for the reimbursement.
   */
  // create a ticket for the approval
  // Send a notification to the approver with the link of the ticket
  return {
    "status": "pending",
    "approver": "Sean Zhou",
    "purpose": args.purpose,
    "amount": args.amount,
    "ticket-id": "approval-ticket-1",
  };
}

// 2. Instantiate the LongRunningFunctionTool class with the long-running function
const longRunningTool = new LongRunningFunctionTool({
  name: "ask_for_approval",
  description: "Ask for approval for the reimbursement.",
  parameters: z.object({
    purpose: z.string().describe("The purpose of the reimbursement."),
    amount: z.number().describe("The amount to reimburse."),
  }),
  execute: askForApproval,
});
```

```go
import (
    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/functiontool"
    "google.golang.org/genai"
)

// CreateTicketArgs defines the arguments for our long-running tool.
type CreateTicketArgs struct {
    Urgency string `json:"urgency" jsonschema:"The urgency level of the ticket."`
}

// CreateTicketResults defines the *initial* output of our long-running tool.
type CreateTicketResults struct {
    Status   string `json:"status"`
    TicketId string `json:"ticket_id"`
}

// createTicketAsync simulates the *initiation* of a long-running ticket creation task.
func createTicketAsync(ctx tool.Context, args CreateTicketArgs) (CreateTicketResults, error) {
    log.Printf("TOOL_EXEC: 'create_ticket_long_running' called with urgency: %s (Call ID: %s)\n", args.Urgency, ctx.FunctionCallID())

    // "Generate" a ticket ID and return it in the initial response.
    ticketID := "TICKET-ABC-123"
    log.Printf("ACTION: Generated Ticket ID: %s for Call ID: %s\n", ticketID, ctx.FunctionCallID())

    // In a real application, you would save the association between the
    // FunctionCallID and the ticketID to handle the async response later.
    return CreateTicketResults{
        Status:   "started",
        TicketId: ticketID,
    }, nil
}

func createTicketAgent(ctx context.Context) (agent.Agent, error) {
    ticketTool, err := functiontool.New(
        functiontool.Config{
            Name:        "create_ticket_long_running",
            Description: "Creates a new support ticket with a specified urgency level.",
        },
        createTicketAsync,
    )
    if err != nil {
        return nil, fmt.Errorf("failed to create long running tool: %w", err)
    }

    model, err := gemini.NewModel(ctx, "gemini-2.5-flash", &genai.ClientConfig{})
    if err != nil {
        return nil, fmt.Errorf("failed to create model: %v", err)
    }

    return llmagent.New(llmagent.Config{
        Name:        "ticket_agent",
        Model:       model,
        Instruction: "You are a helpful assistant for creating support tickets. Provide the status of the ticket at each interaction.",
        Tools:       []tool.Tool{ticketTool},
    })
}
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.tools.LongRunningFunctionTool;
import java.util.HashMap;
import java.util.Map;

public class ExampleLongRunningFunction {

  // Define your Long Running function.
  // Ask for approval for the reimbursement.
  public static Map<String, Object> askForApproval(String purpose, double amount) {
    // Simulate creating a ticket and sending a notification
    System.out.println(
        "Simulating ticket creation for purpose: " + purpose + ", amount: " + amount);

    // Send a notification to the approver with the link of the ticket
    Map<String, Object> result = new HashMap<>();
    result.put("status", "pending");
    result.put("approver", "Sean Zhou");
    result.put("purpose", purpose);
    result.put("amount", amount);
    result.put("ticket-id", "approval-ticket-1");
    return result;
  }

  public static void main(String[] args) throws NoSuchMethodException {
    // Pass the method to LongRunningFunctionTool.create
    LongRunningFunctionTool approveTool =
        LongRunningFunctionTool.create(ExampleLongRunningFunction.class, "askForApproval");

    // Include the tool in the agent
    LlmAgent approverAgent =
        LlmAgent.builder()
            // ...
            .tools(approveTool)
            .build();
  }
}
```

### Intermediate / Final result Updates

Agent client received an event with long running function calls and check the status of the ticket. Then Agent client can send the intermediate or final response back to update the progress. The framework packages this value (even if it's None) into the content of the `FunctionResponse` sent back to the LLM.

Note: Long running function response with Resume feature

If your ADK agent workflow is configured with the [Resume](/runtime/resume/) feature, you also must include the Invocation ID (`invocation_id`) parameter with the long running function response. The Invocation ID you provide must be the same invocation that generated the long running function request, otherwise the system starts a new invocation with the response. If your agent uses the Resume feature, consider including the Invocation ID as a parameter with your long running function request, so it can be included with the response. For more details on using the Resume feature, see [Resume stopped agents](/runtime/resume/).

Applies to only Java ADK

When passing `ToolContext` with Function Tools, ensure that one of the following is true:

- The Schema is passed with the ToolContext parameter in the function signature, like:

  ```text
  @com.google.adk.tools.Annotations.Schema(name = "toolContext") ToolContext toolContext
  ```

  OR

- The following `-parameters` flag is set to the mvn compiler plugin

```text
<build>
    <plugins>
        <plugin>
            <groupId>org.apache.maven.plugins</groupId>
            <artifactId>maven-compiler-plugin</artifactId>
            <version>3.14.0</version> <!-- or newer -->
            <configuration>
                <compilerArgs>
                    <arg>-parameters</arg>
                </compilerArgs>
            </configuration>
        </plugin>
    </plugins>
</build>
```

This constraint is temporary and will be removed.

```python
# Agent Interaction
async def call_agent_async(query):

    def get_long_running_function_call(event: Event) -> types.FunctionCall:
        # Get the long running function call from the event
        if not event.long_running_tool_ids or not event.content or not event.content.parts:
            return
        for part in event.content.parts:
            if (
                part
                and part.function_call
                and event.long_running_tool_ids
                and part.function_call.id in event.long_running_tool_ids
            ):
                return part.function_call

    def get_function_response(event: Event, function_call_id: str) -> types.FunctionResponse:
        # Get the function response for the fuction call with specified id.
        if not event.content or not event.content.parts:
            return
        for part in event.content.parts:
            if (
                part
                and part.function_response
                and part.function_response.id == function_call_id
            ):
                return part.function_response

    content = types.Content(role='user', parts=[types.Part(text=query)])
    session, runner = await setup_session_and_runner()

    print("\nRunning agent...")
    events_async = runner.run_async(
        session_id=session.id, user_id=USER_ID, new_message=content
    )


    long_running_function_call, long_running_function_response, ticket_id = None, None, None
    async for event in events_async:
        # Use helper to check for the specific auth request event
        if not long_running_function_call:
            long_running_function_call = get_long_running_function_call(event)
        else:
            _potential_response = get_function_response(event, long_running_function_call.id)
            if _potential_response: # Only update if we get a non-None response
                long_running_function_response = _potential_response
                ticket_id = long_running_function_response.response['ticket-id']
        if event.content and event.content.parts:
            if text := ''.join(part.text or '' for part in event.content.parts):
                print(f'[{event.author}]: {text}')


    if long_running_function_response:
        # query the status of the correpsonding ticket via tciket_id
        # send back an intermediate / final response
        updated_response = long_running_function_response.model_copy(deep=True)
        updated_response.response = {'status': 'approved'}
        async for event in runner.run_async(
          session_id=session.id, user_id=USER_ID, new_message=types.Content(parts=[types.Part(function_response = updated_response)], role='user')
        ):
            if event.content and event.content.parts:
                if text := ''.join(part.text or '' for part in event.content.parts):
                    print(f'[{event.author}]: {text}')
```

```typescript
/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { LlmAgent, Runner, FunctionTool, LongRunningFunctionTool, InMemorySessionService, Event, stringifyContent } from '@google/adk';
import {z} from "zod";
import {Content, FunctionCall, FunctionResponse, createUserContent} from "@google/genai";

// 1. Define the long-running function
function askForApproval(args: {purpose: string; amount: number}) {
  /**
   * Ask for approval for the reimbursement.
   */
  // create a ticket for the approval
  // Send a notification to the approver with the link of the ticket
  return {
    "status": "pending",
    "approver": "Sean Zhou",
    "purpose": args.purpose,
    "amount": args.amount,
    "ticket-id": "approval-ticket-1",
  };
}

// 2. Instantiate the LongRunningFunctionTool class with the long-running function
const longRunningTool = new LongRunningFunctionTool({
  name: "ask_for_approval",
  description: "Ask for approval for the reimbursement.",
  parameters: z.object({
    purpose: z.string().describe("The purpose of the reimbursement."),
    amount: z.number().describe("The amount to reimburse."),
  }),
  execute: askForApproval,
});

function reimburse(args: {purpose: string; amount: number}) {
  /**
   * Reimburse the amount of money to the employee.
   */
  // send the reimbursement request to payment vendor
  return {status: "ok"};
}

const reimburseTool = new FunctionTool({
  name: "reimburse",
  description: "Reimburse the amount of money to the employee.",
  parameters: z.object({
    purpose: z.string().describe("The purpose of the reimbursement."),
    amount: z.number().describe("The amount to reimburse."),
  }),
  execute: reimburse,
});

// 3. Use the tool in an Agent
const reimbursementAgent = new LlmAgent({
  model: "gemini-2.5-flash",
  name: "reimbursement_agent",
  instruction: `
      You are an agent whose job is to handle the reimbursement process for
      the employees. If the amount is less than $100, you will automatically
      approve the reimbursement.

      If the amount is greater than $100, you will
      ask for approval from the manager. If the manager approves, you will
      call reimburse() to reimburse the amount to the employee. If the manager
      rejects, you will inform the employee of the rejection.
    `,
  tools: [reimburseTool, longRunningTool],
});

const APP_NAME = "human_in_the_loop";
const USER_ID = "1234";
const SESSION_ID = "session1234";

// Session and Runner
async function setupSessionAndRunner() {
  const sessionService = new InMemorySessionService();
  const session = await sessionService.createSession({
    appName: APP_NAME,
    userId: USER_ID,
    sessionId: SESSION_ID,
  });
  const runner = new Runner({
    agent: reimbursementAgent,
    appName: APP_NAME,
    sessionService: sessionService,
  });
  return {session, runner};
}

function getLongRunningFunctionCall(event: Event): FunctionCall | undefined {
  // Get the long-running function call from the event
  if (
    !event.longRunningToolIds ||
    !event.content ||
    !event.content.parts?.length
  ) {
    return;
  }
  for (const part of event.content.parts) {
    if (
      part &&
      part.functionCall &&
      event.longRunningToolIds &&
      part.functionCall.id &&
      event.longRunningToolIds.includes(part.functionCall.id)
    ) {
      return part.functionCall;
    }
  }
}

function getFunctionResponse(
  event: Event,
  functionCallId: string
): FunctionResponse | undefined {
  // Get the function response for the function call with specified id.
  if (!event.content || !event.content.parts?.length) {
    return;
  }
  for (const part of event.content.parts) {
    if (
      part &&
      part.functionResponse &&
      part.functionResponse.id === functionCallId
    ) {
      return part.functionResponse;
    }
  }
}

// Agent Interaction
async function callAgentAsync(query: string) {
  let longRunningFunctionCall: FunctionCall | undefined;
  let longRunningFunctionResponse: FunctionResponse | undefined;
  let ticketId: string | undefined;
  const content: Content = createUserContent(query);
  const {session, runner} = await setupSessionAndRunner();

  console.log("\nRunning agent...");
  const events = runner.runAsync({
    sessionId: session.id,
    userId: USER_ID,
    newMessage: content,
  });

  for await (const event of events) {
    // Use helper to check for the specific auth request event
    if (!longRunningFunctionCall) {
      longRunningFunctionCall = getLongRunningFunctionCall(event);
    } else {
      const _potentialResponse = getFunctionResponse(
        event,
        longRunningFunctionCall.id!
      );
      if (_potentialResponse) {
        // Only update if we get a non-None response
        longRunningFunctionResponse = _potentialResponse;
        ticketId = (
          longRunningFunctionResponse.response as {[key: string]: any}
        )[`ticket-id`];
      }
    }
    const text = stringifyContent(event);
    if (text) {
      console.log(`[${event.author}]: ${text}`);
    }
  }

  if (longRunningFunctionResponse) {
    // query the status of the corresponding ticket via ticket_id
    // send back an intermediate / final response
    const updatedResponse = JSON.parse(
      JSON.stringify(longRunningFunctionResponse)
    );
    updatedResponse.response = {status: "approved"};
    for await (const event of runner.runAsync({
      sessionId: session.id,
      userId: USER_ID,
      newMessage: createUserContent(JSON.stringify({functionResponse: updatedResponse})),
    })) {
      const text = stringifyContent(event);
      if (text) {
        console.log(`[${event.author}]: ${text}`);
      }
    }
  }
}

async function main() {
  // reimbursement that doesn't require approval
  await callAgentAsync("Please reimburse 50$ for meals");
  // reimbursement that requires approval
  await callAgentAsync("Please reimburse 200$ for meals");
}

main();
```

The following example demonstrates a multi-turn workflow. First, the user asks the agent to create a ticket. The agent calls the long-running tool and the client captures the `FunctionCall` ID. The client then simulates the asynchronous work completing by sending subsequent `FunctionResponse` messages back to the agent to provide the ticket ID and final status.

```go
// runTurn executes a single turn with the agent and returns the captured function call ID.
func runTurn(ctx context.Context, r *runner.Runner, sessionID, turnLabel string, content *genai.Content) string {
    var funcCallID atomic.Value // Safely store the found ID.

    fmt.Printf("\n--- %s ---\n", turnLabel)
    for event, err := range r.Run(ctx, userID, sessionID, content, agent.RunConfig{
        StreamingMode: agent.StreamingModeNone,
    }) {
        if err != nil {
            fmt.Printf("\nAGENT_ERROR: %v\n", err)
            continue
        }
        // Print a summary of the event for clarity.
        printEventSummary(event, turnLabel)

        // Capture the function call ID from the event.
        for _, part := range event.Content.Parts {
            if fc := part.FunctionCall; fc != nil {
                if fc.Name == "create_ticket_long_running" {
                    funcCallID.Store(fc.ID)
                }
            }
        }
    }

    if id, ok := funcCallID.Load().(string); ok {
        return id
    }
    return ""
}

func main() {
    ctx := context.Background()
    ticketAgent, err := createTicketAgent(ctx)
    if err != nil {
        log.Fatalf("Failed to create agent: %v", err)
    }

    // Setup the runner and session.
    sessionService := session.InMemoryService()
    session, err := sessionService.Create(ctx, &session.CreateRequest{AppName: appName, UserID: userID})
    if err != nil {
        log.Fatalf("Failed to create session: %v", err)
    }
    r, err := runner.New(runner.Config{AppName: appName, Agent: ticketAgent, SessionService: sessionService})
    if err != nil {
        log.Fatalf("Failed to create runner: %v", err)
    }

    // --- Turn 1: User requests to create a ticket. ---
    initialUserMessage := genai.NewContentFromText("Create a high urgency ticket for me.", genai.RoleUser)
    funcCallID := runTurn(ctx, r, session.Session.ID(), "Turn 1: User Request", initialUserMessage)
    if funcCallID == "" {
        log.Fatal("ERROR: Tool 'create_ticket_long_running' not called in Turn 1.")
    }
    fmt.Printf("ACTION: Captured FunctionCall ID: %s\n", funcCallID)

    // --- Turn 2: App provides the final status of the ticket. ---
    // In a real application, the ticketID would be retrieved from a database
    // using the funcCallID. For this example, we'll use the same ID.
    ticketID := "TICKET-ABC-123"
    willContinue := false // Signal that this is the final response.
    ticketStatusResponse := &genai.FunctionResponse{
        Name: "create_ticket_long_running",
        ID:   funcCallID,
        Response: map[string]any{
            "status":    "approved",
            "ticket_id": ticketID,
        },
        WillContinue: &willContinue,
    }
    appResponseWithStatus := &genai.Content{
        Role:  string(genai.RoleUser),
        Parts: []*genai.Part{{FunctionResponse: ticketStatusResponse}},
    }
    runTurn(ctx, r, session.Session.ID(), "Turn 2: App provides ticket status", appResponseWithStatus)
    fmt.Println("Long running function completed successfully.")
}

// printEventSummary provides a readable log of agent and LLM interactions.
func printEventSummary(event *session.Event, turnLabel string) {
    for _, part := range event.Content.Parts {
        // Check for a text part.
        if part.Text != "" {
            fmt.Printf("[%s][%s_TEXT]: %s\n", turnLabel, event.Author, part.Text)
        }
        // Check for a function call part.
        if fc := part.FunctionCall; fc != nil {
            fmt.Printf("[%s][%s_CALL]: %s(%v) ID: %s\n", turnLabel, event.Author, fc.Name, fc.Args, fc.ID)
        }
    }
}
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.events.Event;
import com.google.adk.runner.InMemoryRunner;
import com.google.adk.runner.Runner;
import com.google.adk.sessions.Session;
import com.google.adk.tools.Annotations.Schema;
import com.google.adk.tools.LongRunningFunctionTool;
import com.google.adk.tools.ToolContext;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.ImmutableMap;
import com.google.genai.types.Content;
import com.google.genai.types.FunctionCall;
import com.google.genai.types.FunctionResponse;
import com.google.genai.types.Part;
import java.util.Optional;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicReference;
import java.util.stream.Collectors;

public class LongRunningFunctionExample {

  private static String USER_ID = "user123";

  @Schema(
      name = "create_ticket_long_running",
      description = """
          Creates a new support ticket with a specified urgency level.
          Examples of urgency are 'high', 'medium', or 'low'.
          The ticket creation is a long-running process, and its ID will be provided when ready.
      """)
  public static void createTicketAsync(
      @Schema(
              name = "urgency",
              description =
                  "The urgency level for the new ticket, such as 'high', 'medium', or 'low'.")
          String urgency,
      @Schema(name = "toolContext") // Ensures ADK injection
          ToolContext toolContext) {
    System.out.printf(
        "TOOL_EXEC: 'create_ticket_long_running' called with urgency: %s (Call ID: %s)%n",
        urgency, toolContext.functionCallId().orElse("N/A"));
  }

  public static void main(String[] args) {
    LlmAgent agent =
        LlmAgent.builder()
            .name("ticket_agent")
            .description("Agent for creating tickets via a long-running task.")
            .model("gemini-2.0-flash")
            .tools(
                ImmutableList.of(
                    LongRunningFunctionTool.create(
                        LongRunningFunctionExample.class, "createTicketAsync")))
            .build();

    Runner runner = new InMemoryRunner(agent);
    Session session =
        runner.sessionService().createSession(agent.name(), USER_ID, null, null).blockingGet();

    // --- Turn 1: User requests ticket ---
    System.out.println("\n--- Turn 1: User Request ---");
    Content initialUserMessage =
        Content.fromParts(Part.fromText("Create a high urgency ticket for me."));

    AtomicReference<String> funcCallIdRef = new AtomicReference<>();
    runner
        .runAsync(USER_ID, session.id(), initialUserMessage)
        .blockingForEach(
            event -> {
              printEventSummary(event, "T1");
              if (funcCallIdRef.get() == null) { // Capture the first relevant function call ID
                event.content().flatMap(Content::parts).orElse(ImmutableList.of()).stream()
                    .map(Part::functionCall)
                    .flatMap(Optional::stream)
                    .filter(fc -> "create_ticket_long_running".equals(fc.name().orElse("")))
                    .findFirst()
                    .flatMap(FunctionCall::id)
                    .ifPresent(funcCallIdRef::set);
              }
            });

    if (funcCallIdRef.get() == null) {
      System.out.println("ERROR: Tool 'create_ticket_long_running' not called in Turn 1.");
      return;
    }
    System.out.println("ACTION: Captured FunctionCall ID: " + funcCallIdRef.get());

    // --- Turn 2: App provides initial ticket_id (simulating async tool completion) ---
    System.out.println("\n--- Turn 2: App provides ticket_id ---");
    String ticketId = "TICKET-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    FunctionResponse ticketCreatedFuncResponse =
        FunctionResponse.builder()
            .name("create_ticket_long_running")
            .id(funcCallIdRef.get())
            .response(ImmutableMap.of("ticket_id", ticketId))
            .build();
    Content appResponseWithTicketId =
        Content.builder()
            .parts(
                ImmutableList.of(
                    Part.builder().functionResponse(ticketCreatedFuncResponse).build()))
            .role("user")
            .build();

    runner
        .runAsync(USER_ID, session.id(), appResponseWithTicketId)
        .blockingForEach(event -> printEventSummary(event, "T2"));
    System.out.println("ACTION: Sent ticket_id " + ticketId + " to agent.");

    // --- Turn 3: App provides ticket status update ---
    System.out.println("\n--- Turn 3: App provides ticket status ---");
    FunctionResponse ticketStatusFuncResponse =
        FunctionResponse.builder()
            .name("create_ticket_long_running")
            .id(funcCallIdRef.get())
            .response(ImmutableMap.of("status", "approved", "ticket_id", ticketId))
            .build();
    Content appResponseWithStatus =
        Content.builder()
            .parts(
                ImmutableList.of(Part.builder().functionResponse(ticketStatusFuncResponse).build()))
            .role("user")
            .build();

    runner
        .runAsync(USER_ID, session.id(), appResponseWithStatus)
        .blockingForEach(event -> printEventSummary(event, "T3_FINAL"));
    System.out.println("Long running function completed successfully.");
  }

  private static void printEventSummary(Event event, String turnLabel) {
    event
        .content()
        .ifPresent(
            content -> {
              String text =
                  content.parts().orElse(ImmutableList.of()).stream()
                      .map(part -> part.text().orElse(""))
                      .filter(s -> !s.isEmpty())
                      .collect(Collectors.joining(" "));
              if (!text.isEmpty()) {
                System.out.printf("[%s][%s_TEXT]: %s%n", turnLabel, event.author(), text);
              }
              content.parts().orElse(ImmutableList.of()).stream()
                  .map(Part::functionCall)
                  .flatMap(Optional::stream)
                  .findFirst() // Assuming one function call per relevant event for simplicity
                  .ifPresent(
                      fc ->
                          System.out.printf(
                              "[%s][%s_CALL]: %s(%s) ID: %s%n",
                              turnLabel,
                              event.author(),
                              fc.name().orElse("N/A"),
                              fc.args().orElse(ImmutableMap.of()),
                              fc.id().orElse("N/A")));
            });
  }
}
```

Python complete example: File Processing Simulation

```python
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
from typing import Any
from google.adk.agents import Agent
from google.adk.events import Event
from google.adk.runners import Runner
from google.adk.tools import LongRunningFunctionTool
from google.adk.sessions import InMemorySessionService
from google.genai import types


# 1. Define the long running function
def ask_for_approval(
    purpose: str, amount: float
) -> dict[str, Any]:
    """Ask for approval for the reimbursement."""
    # create a ticket for the approval
    # Send a notification to the approver with the link of the ticket
    return {'status': 'pending', 'approver': 'Sean Zhou', 'purpose' : purpose, 'amount': amount, 'ticket-id': 'approval-ticket-1'}

def reimburse(purpose: str, amount: float) -> str:
    """Reimburse the amount of money to the employee."""
    # send the reimbrusement request to payment vendor
    return {'status': 'ok'}

# 2. Wrap the function with LongRunningFunctionTool
long_running_tool = LongRunningFunctionTool(func=ask_for_approval)


# 3. Use the tool in an Agent
file_processor_agent = Agent(
    # Use a model compatible with function calling
    model="gemini-2.0-flash",
    name='reimbursement_agent',
    instruction="""
      You are an agent whose job is to handle the reimbursement process for
      the employees. If the amount is less than $100, you will automatically
      approve the reimbursement.

      If the amount is greater than $100, you will
      ask for approval from the manager. If the manager approves, you will
      call reimburse() to reimburse the amount to the employee. If the manager
      rejects, you will inform the employee of the rejection.
    """,
    tools=[reimburse, long_running_tool]
)


APP_NAME = "human_in_the_loop"
USER_ID = "1234"
SESSION_ID = "session1234"

# Session and Runner
async def setup_session_and_runner():
    session_service = InMemorySessionService()
    session = await session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID)
    runner = Runner(agent=file_processor_agent, app_name=APP_NAME, session_service=session_service)
    return session, runner


# Agent Interaction
async def call_agent_async(query):

    def get_long_running_function_call(event: Event) -> types.FunctionCall:
        # Get the long running function call from the event
        if not event.long_running_tool_ids or not event.content or not event.content.parts:
            return
        for part in event.content.parts:
            if (
                part
                and part.function_call
                and event.long_running_tool_ids
                and part.function_call.id in event.long_running_tool_ids
            ):
                return part.function_call

    def get_function_response(event: Event, function_call_id: str) -> types.FunctionResponse:
        # Get the function response for the fuction call with specified id.
        if not event.content or not event.content.parts:
            return
        for part in event.content.parts:
            if (
                part
                and part.function_response
                and part.function_response.id == function_call_id
            ):
                return part.function_response

    content = types.Content(role='user', parts=[types.Part(text=query)])
    session, runner = await setup_session_and_runner()

    print("\nRunning agent...")
    events_async = runner.run_async(
        session_id=session.id, user_id=USER_ID, new_message=content
    )


    long_running_function_call, long_running_function_response, ticket_id = None, None, None
    async for event in events_async:
        # Use helper to check for the specific auth request event
        if not long_running_function_call:
            long_running_function_call = get_long_running_function_call(event)
        else:
            _potential_response = get_function_response(event, long_running_function_call.id)
            if _potential_response: # Only update if we get a non-None response
                long_running_function_response = _potential_response
                ticket_id = long_running_function_response.response['ticket-id']
        if event.content and event.content.parts:
            if text := ''.join(part.text or '' for part in event.content.parts):
                print(f'[{event.author}]: {text}')


    if long_running_function_response:
        # query the status of the correpsonding ticket via tciket_id
        # send back an intermediate / final response
        updated_response = long_running_function_response.model_copy(deep=True)
        updated_response.response = {'status': 'approved'}
        async for event in runner.run_async(
          session_id=session.id, user_id=USER_ID, new_message=types.Content(parts=[types.Part(function_response = updated_response)], role='user')
        ):
            if event.content and event.content.parts:
                if text := ''.join(part.text or '' for part in event.content.parts):
                    print(f'[{event.author}]: {text}')


# Note: In Colab, you can directly use 'await' at the top level.
# If running this code as a standalone Python script, you'll need to use asyncio.run() or manage the event loop.

# reimbursement that doesn't require approval
# asyncio.run(call_agent_async("Please reimburse 50$ for meals"))
await call_agent_async("Please reimburse 50$ for meals") # For Notebooks, uncomment this line and comment the above line
# reimbursement that requires approval
# asyncio.run(call_agent_async("Please reimburse 200$ for meals"))
await call_agent_async("Please reimburse 200$ for meals") # For Notebooks, uncomment this line and comment the above line
```

#### Key aspects of this example

- **`LongRunningFunctionTool`**: Wraps the supplied method/function; the framework handles sending yielded updates and the final return value as sequential FunctionResponses.
- **Agent instruction**: Directs the LLM to use the tool and understand the incoming FunctionResponse stream (progress vs. completion) for user updates.
- **Final return**: The function returns the final result dictionary, which is sent in the concluding FunctionResponse to indicate completion.

## Agent-as-a-Tool

This powerful feature allows you to leverage the capabilities of other agents within your system by calling them as tools. The Agent-as-a-Tool enables you to invoke another agent to perform a specific task, effectively **delegating responsibility**. This is conceptually similar to creating a Python function that calls another agent and uses the agent's response as the function's return value.

### Key difference from sub-agents

It's important to distinguish an Agent-as-a-Tool from a Sub-Agent.

- **Agent-as-a-Tool:** When Agent A calls Agent B as a tool (using Agent-as-a-Tool), Agent B's answer is **passed back** to Agent A, which then summarizes the answer and generates a response to the user. Agent A retains control and continues to handle future user input.
- **Sub-agent:** When Agent A calls Agent B as a sub-agent, the responsibility of answering the user is completely **transferred to Agent B**. Agent A is effectively out of the loop. All subsequent user input will be answered by Agent B.

### Usage

To use an agent as a tool, wrap the agent with the AgentTool class.

```python
tools=[AgentTool(agent=agent_b)]
```

```typescript
tools: [new AgentTool({agent: agentB})]
```

```go
agenttool.New(agent, &agenttool.Config{...})
```

```java
AgentTool.create(agent)
```

### Customization

The `AgentTool` class provides the following attributes for customizing its behavior:

- **skip_summarization: bool:** If set to True, the framework will **bypass the LLM-based summarization** of the tool agent's response. This can be useful when the tool's response is already well-formatted and requires no further processing.

Example

```python
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
from google.adk.tools.agent_tool import AgentTool
from google.genai import types

APP_NAME="summary_agent"
USER_ID="user1234"
SESSION_ID="1234"

summary_agent = Agent(
    model="gemini-2.0-flash",
    name="summary_agent",
    instruction="""You are an expert summarizer. Please read the following text and provide a concise summary.""",
    description="Agent to summarize text",
)

root_agent = Agent(
    model='gemini-2.0-flash',
    name='root_agent',
    instruction="""You are a helpful assistant. When the user provides a text, use the 'summarize' tool to generate a summary. Always forward the user's message exactly as received to the 'summarize' tool, without modifying or summarizing it yourself. Present the response from the tool to the user.""",
    tools=[AgentTool(agent=summary_agent, skip_summarization=True)]
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


long_text = """Quantum computing represents a fundamentally different approach to computation, 
leveraging the bizarre principles of quantum mechanics to process information. Unlike classical computers 
that rely on bits representing either 0 or 1, quantum computers use qubits which can exist in a state of superposition - effectively 
being 0, 1, or a combination of both simultaneously. Furthermore, qubits can become entangled, 
meaning their fates are intertwined regardless of distance, allowing for complex correlations. This parallelism and 
interconnectedness grant quantum computers the potential to solve specific types of incredibly complex problems - such 
as drug discovery, materials science, complex system optimization, and breaking certain types of cryptography - far 
faster than even the most powerful classical supercomputers could ever achieve, although the technology is still largely in its developmental stages."""


# Note: In Colab, you can directly use 'await' at the top level.
# If running this code as a standalone Python script, you'll need to use asyncio.run() or manage the event loop.
await call_agent_async(long_text)
```

```typescript
/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import { AgentTool, InMemoryRunner, LlmAgent } from '@google/adk';
import {Part, createUserContent} from '@google/genai';

/**
 * This example demonstrates how to use an agent as a tool.
 */
async function main() {
  // Define the summarization agent that will be used as a tool
  const summaryAgent = new LlmAgent({
    name: 'summary_agent',
    model: 'gemini-2.5-flash',
    description: 'Agent to summarize text',
    instruction:
      'You are an expert summarizer. Please read the following text and provide a concise summary.',
  });

  // Define the main agent that uses the summarization agent as a tool.
  // skipSummarization is set to true, so the main_agent will directly output
  // the result from the summary_agent without further processing.
  const mainAgent = new LlmAgent({
    name: 'main_agent',
    model: 'gemini-2.5-flash',
    instruction:
      "You are a helpful assistant. When the user provides a text, use the 'summary_agent' tool to generate a summary. Always forward the user's message exactly as received to the 'summary_agent' tool, without modifying or summarizing it yourself. Present the response from the tool to the user.",
    tools: [new AgentTool({agent: summaryAgent, skipSummarization: true})],
  });

  const appName = 'agent-as-a-tool-app';
  const runner = new InMemoryRunner({agent: mainAgent, appName});

  const longText = `Quantum computing represents a fundamentally different approach to computation, 
leveraging the bizarre principles of quantum mechanics to process information. Unlike classical computers 
that rely on bits representing either 0 or 1, quantum computers use qubits which can exist in a state of superposition - effectively 
being 0, 1, or a combination of both simultaneously. Furthermore, qubits can become entangled, 
meaning their fates are intertwined regardless of distance, allowing for complex correlations. This parallelism and 
interconnectedness grant quantum computers the potential to solve specific types of incredibly complex problems - such 
as drug discovery, materials science, complex system optimization, and breaking certain types of cryptography - far 
faster than even the most powerful classical supercomputers could ever achieve, although the technology is still largely in its developmental stages.`;

  // Create the session before running the agent
  await runner.sessionService.createSession({
    appName,
    userId: 'user1',
    sessionId: 'session1',
  });

  // Run the agent with the long text to summarize
  const events = runner.runAsync({
    userId: 'user1',
    sessionId: 'session1',
    newMessage: createUserContent(longText),
  });

  // Print the final response from the agent
  console.log('Agent Response:');
  for await (const event of events) {
    if (event.content?.parts?.length) {
      const responsePart = event.content.parts.find((p: Part) => p.functionResponse);
      if (responsePart && responsePart.functionResponse) {
        console.log(responsePart.functionResponse.response);
      }
    }
  }
}

main();
```

```go
import (
    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/agenttool"
    "google.golang.org/genai"
)

// createSummarizerAgent creates an agent whose sole purpose is to summarize text.
func createSummarizerAgent(ctx context.Context) (agent.Agent, error) {
    model, err := gemini.NewModel(ctx, "gemini-2.5-flash", &genai.ClientConfig{})
    if err != nil {
        return nil, err
    }
    return llmagent.New(llmagent.Config{
        Name:        "SummarizerAgent",
        Model:       model,
        Instruction: "You are an expert at summarizing text. Take the user's input and provide a concise summary.",
        Description: "An agent that summarizes text.",
    })
}

// createMainAgent creates the primary agent that will use the summarizer agent as a tool.
func createMainAgent(ctx context.Context, tools ...tool.Tool) (agent.Agent, error) {
    model, err := gemini.NewModel(ctx, "gemini-2.5-flash", &genai.ClientConfig{})
    if err != nil {
        return nil, err
    }
    return llmagent.New(llmagent.Config{
        Name:  "MainAgent",
        Model: model,
        Instruction: "You are a helpful assistant. If you are asked to summarize a long text, use the 'summarize' tool. " +
            "After getting the summary, present it to the user by saying 'Here is a summary of the text:'.",
        Description: "The main agent that can delegate tasks.",
        Tools:       tools,
    })
}

func RunAgentAsToolSimulation() {
    ctx := context.Background()

    // 1. Create the Tool Agent (Summarizer)
    summarizerAgent, err := createSummarizerAgent(ctx)
    if err != nil {
        log.Fatalf("Failed to create summarizer agent: %v", err)
    }

    // 2. Wrap the Tool Agent in an AgentTool
    summarizeTool := agenttool.New(summarizerAgent, &agenttool.Config{
        SkipSummarization: true,
    })

    // 3. Create the Main Agent and provide it with the AgentTool
    mainAgent, err := createMainAgent(ctx, summarizeTool)
    if err != nil {
        log.Fatalf("Failed to create main agent: %v", err)
    }

    // 4. Run the main agent
    prompt := `
        Please summarize this text for me:
        Quantum computing represents a fundamentally different approach to computation,
        leveraging the bizarre principles of quantum mechanics to process information. Unlike classical computers
        that rely on bits representing either 0 or 1, quantum computers use qubits which can exist in a state of superposition - effectively
        being 0, 1, or a combination of both simultaneously. Furthermore, qubits can become entangled,
        meaning their fates are intertwined regardless of distance, allowing for complex correlations. This parallelism and
        interconnectedness grant quantum computers the potential to solve specific types of incredibly complex problems - such
        as drug discovery, materials science, complex system optimization, and breaking certain types of cryptography - far
        faster than even the most powerful classical supercomputers could ever achieve, although the technology is still largely in its developmental stages.
    `
    fmt.Printf("\nPrompt: %s\nResponse: ", prompt)
    callAgent(context.Background(), mainAgent, prompt)
    fmt.Println("\n---")
}
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.events.Event;
import com.google.adk.runner.InMemoryRunner;
import com.google.adk.sessions.Session;
import com.google.adk.tools.AgentTool;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import io.reactivex.rxjava3.core.Flowable;

public class AgentToolCustomization {

  private static final String APP_NAME = "summary_agent";
  private static final String USER_ID = "user1234";

  public static void initAgentAndRun(String prompt) {

    LlmAgent summaryAgent =
        LlmAgent.builder()
            .model("gemini-2.0-flash")
            .name("summaryAgent")
            .instruction(
                "You are an expert summarizer. Please read the following text and provide a concise summary.")
            .description("Agent to summarize text")
            .build();

    // Define root_agent
    LlmAgent rootAgent =
        LlmAgent.builder()
            .model("gemini-2.0-flash")
            .name("rootAgent")
            .instruction(
                "You are a helpful assistant. When the user provides a text, always use the 'summaryAgent' tool to generate a summary. Always forward the user's message exactly as received to the 'summaryAgent' tool, without modifying or summarizing it yourself. Present the response from the tool to the user.")
            .description("Assistant agent")
            .tools(AgentTool.create(summaryAgent, true)) // Set skipSummarization to true
            .build();

    // Create an InMemoryRunner
    InMemoryRunner runner = new InMemoryRunner(rootAgent, APP_NAME);
    // InMemoryRunner automatically creates a session service. Create a session using the service
    Session session = runner.sessionService().createSession(APP_NAME, USER_ID).blockingGet();
    Content userMessage = Content.fromParts(Part.fromText(prompt));

    // Run the agent
    Flowable<Event> eventStream = runner.runAsync(USER_ID, session.id(), userMessage);

    // Stream event response
    eventStream.blockingForEach(
        event -> {
          if (event.finalResponse()) {
            System.out.println(event.stringifyContent());
          }
        });
  }

  public static void main(String[] args) {
    String longText =
        """
            Quantum computing represents a fundamentally different approach to computation,
            leveraging the bizarre principles of quantum mechanics to process information. Unlike classical computers
            that rely on bits representing either 0 or 1, quantum computers use qubits which can exist in a state of superposition - effectively
            being 0, 1, or a combination of both simultaneously. Furthermore, qubits can become entangled,
            meaning their fates are intertwined regardless of distance, allowing for complex correlations. This parallelism and
            interconnectedness grant quantum computers the potential to solve specific types of incredibly complex problems - such
            as drug discovery, materials science, complex system optimization, and breaking certain types of cryptography - far
            faster than even the most powerful classical supercomputers could ever achieve, although the technology is still largely in its developmental stages.""";

    initAgentAndRun(longText);
  }
}
```

### How it works

1. When the `root_agent` receives the long text, its instruction tells it to use the 'summarize' tool for long texts.
1. The framework recognizes 'summarize' as an `AgentTool` that wraps the `summary_agent`.
1. Behind the scenes, the `root_agent` will call the `summary_agent` with the long text as input.
1. The `summary_agent` will process the text according to its instruction and generate a summary.
1. **The response from the `summary_agent` is then passed back to the `root_agent`.**
1. The `root_agent` can then take the summary and formulate its final response to the user (e.g., "Here's a summary of the text: ...")




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
import uuid # For unique session IDs
from dotenv import load_dotenv

from google.adk.agents import LlmAgent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types

# --- OpenAPI Tool Imports ---
from google.adk.tools.openapi_tool.openapi_spec_parser.openapi_toolset import OpenAPIToolset

# --- Load Environment Variables (If ADK tools need them, e.g., API keys) ---
load_dotenv() # Create a .env file in the same directory if needed

# --- Constants ---
APP_NAME_OPENAPI = "openapi_petstore_app"
USER_ID_OPENAPI = "user_openapi_1"
SESSION_ID_OPENAPI = f"session_openapi_{uuid.uuid4()}" # Unique session ID
AGENT_NAME_OPENAPI = "petstore_manager_agent"
GEMINI_MODEL = "gemini-2.0-flash"

# --- Sample OpenAPI Specification (JSON String) ---
# A basic Pet Store API example using httpbin.org as a mock server
openapi_spec_string = """
{
  "openapi": "3.0.0",
  "info": {
    "title": "Simple Pet Store API (Mock)",
    "version": "1.0.1",
    "description": "An API to manage pets in a store, using httpbin for responses."
  },
  "servers": [
    {
      "url": "https://httpbin.org",
      "description": "Mock server (httpbin.org)"
    }
  ],
  "paths": {
    "/get": {
      "get": {
        "summary": "List all pets (Simulated)",
        "operationId": "listPets",
        "description": "Simulates returning a list of pets. Uses httpbin's /get endpoint which echoes query parameters.",
        "parameters": [
          {
            "name": "limit",
            "in": "query",
            "description": "Maximum number of pets to return",
            "required": false,
            "schema": { "type": "integer", "format": "int32" }
          },
          {
             "name": "status",
             "in": "query",
             "description": "Filter pets by status",
             "required": false,
             "schema": { "type": "string", "enum": ["available", "pending", "sold"] }
          }
        ],
        "responses": {
          "200": {
            "description": "A list of pets (echoed query params).",
            "content": { "application/json": { "schema": { "type": "object" } } }
          }
        }
      }
    },
    "/post": {
      "post": {
        "summary": "Create a pet (Simulated)",
        "operationId": "createPet",
        "description": "Simulates adding a new pet. Uses httpbin's /post endpoint which echoes the request body.",
        "requestBody": {
          "description": "Pet object to add",
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "required": ["name"],
                "properties": {
                  "name": {"type": "string", "description": "Name of the pet"},
                  "tag": {"type": "string", "description": "Optional tag for the pet"}
                }
              }
            }
          }
        },
        "responses": {
          "201": {
            "description": "Pet created successfully (echoed request body).",
            "content": { "application/json": { "schema": { "type": "object" } } }
          }
        }
      }
    },
    "/get?petId={petId}": {
      "get": {
        "summary": "Info for a specific pet (Simulated)",
        "operationId": "showPetById",
        "description": "Simulates returning info for a pet ID. Uses httpbin's /get endpoint.",
        "parameters": [
          {
            "name": "petId",
            "in": "path",
            "description": "This is actually passed as a query param to httpbin /get",
            "required": true,
            "schema": { "type": "integer", "format": "int64" }
          }
        ],
        "responses": {
          "200": {
            "description": "Information about the pet (echoed query params)",
            "content": { "application/json": { "schema": { "type": "object" } } }
          },
          "404": { "description": "Pet not found (simulated)" }
        }
      }
    }
  }
}
"""

# --- Create OpenAPIToolset ---
petstore_toolset = OpenAPIToolset(
    spec_str=openapi_spec_string,
    spec_str_type='json',
    # No authentication needed for httpbin.org
)

# --- Agent Definition ---
root_agent = LlmAgent(
    name=AGENT_NAME_OPENAPI,
    model=GEMINI_MODEL,
    tools=[petstore_toolset], # Pass the list of RestApiTool objects
    instruction="""You are a Pet Store assistant managing pets via an API.
    Use the available tools to fulfill user requests.
    When creating a pet, confirm the details echoed back by the API.
    When listing pets, mention any filters used (like limit or status).
    When showing a pet by ID, state the ID you requested.
    """,
    description="Manages a Pet Store using tools generated from an OpenAPI spec."
)

# --- Session and Runner Setup ---
async def setup_session_and_runner():
    session_service_openapi = InMemorySessionService()
    runner_openapi = Runner(
        agent=root_agent,
        app_name=APP_NAME_OPENAPI,
        session_service=session_service_openapi,
    )
    await session_service_openapi.create_session(
        app_name=APP_NAME_OPENAPI,
        user_id=USER_ID_OPENAPI,
        session_id=SESSION_ID_OPENAPI,
    )
    return runner_openapi

# --- Agent Interaction Function ---
async def call_openapi_agent_async(query, runner_openapi):
    print("\n--- Running OpenAPI Pet Store Agent ---")
    print(f"Query: {query}")

    content = types.Content(role='user', parts=[types.Part(text=query)])
    final_response_text = "Agent did not provide a final text response."
    try:
        async for event in runner_openapi.run_async(
            user_id=USER_ID_OPENAPI, session_id=SESSION_ID_OPENAPI, new_message=content
            ):
            # Optional: Detailed event logging for debugging
            # print(f"  DEBUG Event: Author={event.author}, Type={'Final' if event.is_final_response() else 'Intermediate'}, Content={str(event.content)[:100]}...")
            if event.get_function_calls():
                call = event.get_function_calls()[0]
                print(f"  Agent Action: Called function '{call.name}' with args {call.args}")
            elif event.get_function_responses():
                response = event.get_function_responses()[0]
                print(f"  Agent Action: Received response for '{response.name}'")
                # print(f"  Tool Response Snippet: {str(response.response)[:200]}...") # Uncomment for response details
            elif event.is_final_response() and event.content and event.content.parts:
                # Capture the last final text response
                final_response_text = event.content.parts[0].text.strip()

        print(f"Agent Final Response: {final_response_text}")

    except Exception as e:
        print(f"An error occurred during agent run: {e}")
        import traceback
        traceback.print_exc() # Print full traceback for errors
    print("-" * 30)

# --- Run Examples ---
async def run_openapi_example():
    runner_openapi = await setup_session_and_runner()

    # Trigger listPets
    await call_openapi_agent_async("Show me the pets available.", runner_openapi)
    # Trigger createPet
    await call_openapi_agent_async("Please add a new dog named 'Dukey'.", runner_openapi)
    # Trigger showPetById
    await call_openapi_agent_async("Get info for pet with ID 123.", runner_openapi)

# --- Execute ---
if __name__ == "__main__":
    print("Executing OpenAPI example...")
    # Use asyncio.run() for top-level execution
    try:
        asyncio.run(run_openapi_example())
    except RuntimeError as e:
        if "cannot be called from a running event loop" in str(e):
            print("Info: Cannot run asyncio.run from a running event loop (e.g., Jupyter/Colab).")
            # If in Jupyter/Colab, you might need to run like this:
            # await run_openapi_example()
        else:
            raise e
    print("OpenAPI example finished.")
```

# Increase tool performance with parallel execution

Supported in ADKPython v1.10.0

Starting with Agent Development Kit (ADK) version 1.10.0 for Python, the framework attempts to run any agent-requested [function tools](/tools-custom/function-tools/) in parallel. This behavior can significantly improve the performance and responsiveness of your agents, particularly for agents that rely on multiple external APIs or long-running tasks. For example, if you have 3 tools that each take 2 seconds, by running them in parallel, the total execution time will be closer to 2 seconds, instead of 6 seconds. The ability to run tool functions parallel can improve the performance of your agents, particularly in the following scenarios:

- **Research tasks:** Where the agent collects information from multiple sources before proceeding to the next stage of the workflow.
- **API calls:** Where the agent accesses several APIs independently, such as searching for available flights using APIs from multiple airlines.
- **Publishing and communication tasks:** When the agent needs to publish or communicate through multiple, independent channels or multiple recipients.

However, your custom tools must be built with asynchronous execution support to enable this performance improvement. This guide explains how parallel tool execution works in the ADK and how to build your tools to take full advantage of this processing feature.

Warning

Any ADK Tools that use synchronous processing in a set of tool function calls will block other tools from executing in parallel, even if the other tools allow for parallel execution.

## Build parallel-ready tools

Enable parallel execution of your tool functions by defining them as asynchronous functions. In Python code, this means using `async def` and `await` syntax which allows the ADK to run them concurrently in an `asyncio` event loop. The following sections show examples of agent tools built for parallel processing and asynchronous operations.

### Example of http web call

The following code example show how to modify the `get_weather()` function to operate asynchronously and allow for parallel execution:

```python
 async def get_weather(city: str) -> dict:
      async with aiohttp.ClientSession() as session:
          async with session.get(f"http://api.weather.com/{city}") as response:
              return await response.json()
```

### Example of database call

The following code example show how to write a database calling function to operate asynchronously:

```python
async def query_database(query: str) -> list:
      async with asyncpg.connect("postgresql://...") as conn:
          return await conn.fetch(query)
```

### Example of yielding behavior for long loops

In cases where a tool is processing multiple requests or numerous long-running requests, consider adding yielding code to allow other tools to execute, as shown in the following code sample:

```python
async def process_data(data: list) -> dict:
      results = []
      for i, item in enumerate(data):
          processed = await process_item(item)  # Yield point
          results.append(processed)

          # Add periodic yield points for long loops
          if i % 100 == 0:
              await asyncio.sleep(0)  # Yield control
      return {"results": results}
```

Important

Use the `asyncio.sleep()` function for pauses to avoid blocking execution of other functions.

### Example of thread pools for intensive operations

When performing processing-intensive functions, consider creating thread pools for better management of available computing resources, as shown in the following example:

```python
async def cpu_intensive_tool(data: list) -> dict:
      loop = asyncio.get_event_loop()

      # Use thread pool for CPU-bound work
      with ThreadPoolExecutor() as executor:
          result = await loop.run_in_executor(
              executor,
              expensive_computation,
              data
          )
      return {"result": result}
```

### Example of process chunking

When performing processes on long lists or large amounts of data, consider combining a thread pool technique with dividing up processing into chunks of data, and yielding processing time between the chunks, as shown in the following example:

```python
 async def process_large_dataset(dataset: list) -> dict:
      results = []
      chunk_size = 1000

      for i in range(0, len(dataset), chunk_size):
          chunk = dataset[i:i + chunk_size]

          # Process chunk in thread pool
          loop = asyncio.get_event_loop()
          with ThreadPoolExecutor() as executor:
              chunk_result = await loop.run_in_executor(
                  executor, process_chunk, chunk
              )

          results.extend(chunk_result)

          # Yield control between chunks
          await asyncio.sleep(0)

      return {"total_processed": len(results), "results": results}
```

## Write parallel-ready prompts and tool descriptions

When building prompts for AI models, consider explicitly specifying or hinting that function calls be made in parallel. The following example of an AI prompt directs the model to use tools in parallel:

```text
When users ask for multiple pieces of information, always call functions in
parallel.

  Examples:
  - "Get weather for London and currency rate USD to EUR" → Call both functions
    simultaneously
  - "Compare cities A and B" → Call get_weather, get_population, get_distance in
    parallel
  - "Analyze multiple stocks" → Call get_stock_price for each stock in parallel

  Always prefer multiple specific function calls over single complex calls.
```

The following example shows a tool function description that hints at more efficient use through parallel execution:

```python
 async def get_weather(city: str) -> dict:
      """Get current weather for a single city.

      This function is optimized for parallel execution - call multiple times for different cities.

      Args:
          city: Name of the city, for example: 'London', 'New York'

      Returns:
          Weather data including temperature, conditions, humidity
      """
      await asyncio.sleep(2)  # Simulate API call
      return {"city": city, "temp": 72, "condition": "sunny"}
```

## Next steps

For more information on building Tools for agents and function calling, see [Function Tools](/tools-custom/function-tools/). For more detailed examples of tools that take advantage of parallel processing, see the samples in the [adk-python](https://github.com/google/adk-python/tree/main/contributing/samples/parallel_functions) repository.




