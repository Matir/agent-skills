# Safety and Security for AI Agents

Supported in ADKPythonTypeScriptGoJava

As AI agents grow in capability, ensuring they operate safely, securely, and align with your brand values is paramount. Uncontrolled agents can pose risks, including executing misaligned or harmful actions, such as data exfiltration, and generating inappropriate content that can impact your brand’s reputation. **Sources of risk include vague instructions, model hallucination, jailbreaks and prompt injections from adversarial users, and indirect prompt injections via tool use.**

[Google Cloud Agent Platform](https://cloud.google.com/vertex-ai/generative-ai/docs/overview) provides a multi-layered approach to mitigate these risks, enabling you to build powerful *and* trustworthy agents. It offers several mechanisms to establish strict boundaries, ensuring agents only perform actions you've explicitly allowed:

1. **Identity and Authorization**: Control who the agent **acts as** by defining agent and user auth.

1. **Guardrails to screen inputs and outputs:** Control your model and tool calls precisely.

   - *In-Tool Guardrails:* Design tools defensively, using developer-set tool context to enforce policies (e.g., allowing queries only on specific tables).
   - *Built-in Gemini Safety Features:* If using Gemini models, benefit from content filters to block harmful outputs and system Instructions to guide the model's behavior and safety guidelines
   - *Callbacks and Plugins:* Validate model and tool calls before or after execution, checking parameters against agent state or external policies.
   - *Using Gemini as a safety guardrail:* Implement an additional safety layer using a cheap and fast model (like Gemini Flash Lite) configured via callbacks to screen inputs and outputs.

1. **Sandboxed code execution:** Prevent model-generated code to cause security issues by sandboxing the environment

1. **Evaluation and tracing**: Use evaluation tools to assess the quality, relevance, and correctness of the agent's final output. Use tracing to gain visibility into agent actions to analyze the steps an agent takes to reach a solution, including its choice of tools, strategies, and the efficiency of its approach.

1. **Network Controls and VPC-SC:** Confine agent activity within secure perimeters (like VPC Service Controls) to prevent data exfiltration and limit the potential impact radius.

## Safety and Security Risks

Before implementing safety measures, perform a thorough risk assessment specific to your agent's capabilities, domain, and deployment context.

***Sources*** **of risk** include:

- Ambiguous agent instructions
- Prompt injection and jailbreak attempts from adversarial users
- Indirect prompt injections via tool use

**Risk categories** include:

- **Misalignment & goal corruption**
  - Pursuing unintended or proxy goals that lead to harmful outcomes ("reward hacking")
  - Misinterpreting complex or ambiguous instructions
- **Harmful content generation, including brand safety**
  - Generating toxic, hateful, biased, sexually explicit, discriminatory, or illegal content
  - Brand safety risks such as Using language that goes against the brand’s values or off-topic conversations
- **Unsafe actions**
  - Executing commands that damage systems
  - Making unauthorized purchases or financial transactions.
  - Leaking sensitive personal data (PII)
  - Data exfiltration

## Best practices

### Identity and Authorization

The identity that a *tool* uses to perform actions on external systems is a crucial design consideration from a security perspective. Different tools in the same agent can be configured with different strategies, so care is needed when talking about the agent's configurations.

#### Agent-Auth

The **tool interacts with external systems using the agent's own identity** (e.g., a service account). The agent identity must be explicitly authorized in the external system access policies, like adding an agent's service account to a database's IAM policy for read access. Such policies constrain the agent in only performing actions that the developer intended as possible: by giving read-only permissions to a resource, no matter what the model decides, the tool will be prohibited from performing write actions.

This approach is simple to implement, and it is **appropriate for agents where all users share the same level of access.** If not all users have the same level of access, such an approach alone doesn't provide enough protection and must be complemented with other techniques below. In tool implementation, ensure that logs are created to maintain attribution of actions to users, as all agents' actions will appear as coming from the agent.

#### User Auth

The tool interacts with an external system using the **identity of the "controlling user"** (e.g., the human interacting with the frontend in a web application). In ADK, this is typically implemented using OAuth: the agent interacts with the frontend to acquire a OAuth token, and then the tool uses the token when performing external actions: the external system authorizes the action if the controlling user is authorized to perform it on its own.

User auth has the advantage that agents only perform actions that the user could have performed themselves. This greatly reduces the risk that a malicious user could abuse the agent to obtain access to additional data. However, most common implementations of delegation have a fixed set permissions to delegate (i.e., OAuth scopes). Often, such scopes are broader than the access that the agent actually requires, and the techniques below are required to further constrain agent actions.

### Guardrails to screen inputs and outputs

#### In-tool guardrails

Tools can be designed with security in mind: we can create tools that expose the actions we want the model to take and nothing else. By limiting the range of actions we provide to the agents, we can deterministically eliminate classes of rogue actions that we never want the agent to take.

In-tool guardrails is an approach to create common and re-usable tools that expose deterministic controls that can be used by developers to set limits on each tool instantiation.

This approach relies on the fact that tools receive two types of input: arguments, which are set by the model, and [**`Tool Context`**](https://adk.dev/tools-custom/#tool-context), which can be set deterministically by the agent developer. We can rely on the deterministically set information to validate that the model is behaving as-expected. *(Note: In TypeScript, `Tool Context` corresponds to the unified `Context` type.)*

For example, a query tool can be designed to expect a policy to be read from the Tool Context.

```py
# Conceptual example: Setting policy data intended for tool context
# In a real ADK app, this might be set in InvocationContext.session.state
# or passed during tool initialization, then retrieved via ToolContext.

policy = {} # Assuming policy is a dictionary
policy['select_only'] = True
policy['tables'] = ['mytable1', 'mytable2']

# Conceptual: Storing policy where the tool can access it via ToolContext later.
# This specific line might look different in practice.
# For example, storing in session state:
invocation_context.session.state["query_tool_policy"] = policy

# Or maybe passing during tool init:
query_tool = QueryTool(policy=policy)
# For this example, we'll assume it gets stored somewhere accessible.
```

```typescript
// Conceptual example: Setting policy data intended for tool context
// In a real ADK app, this might be set in InvocationContext.session.state
// or passed during tool initialization, then retrieved via Context.

const policy: {[key: string]: any} = {}; // Assuming policy is an object
policy['select_only'] = true;
policy['tables'] = ['mytable1', 'mytable2'];

// Conceptual: Storing policy where the tool can access it via Context later.
// This specific line might look different in practice.
// For example, storing in session state:
invocationContext.session.state["query_tool_policy"] = policy;

// Or maybe passing during tool init:
const queryTool = new QueryTool({policy: policy});
// For this example, we'll assume it gets stored somewhere accessible.
```

```go
// Conceptual example: Setting policy data intended for tool context
// In a real ADK app, this might be set using the session state service.
// `ctx` is an `agent.Context` available in callbacks or custom agents.

policy := map[string]any{
    "select_only": true,
    "tables":      []string{"mytable1", "mytable2"},
}

// Conceptual: Storing policy where the tool can access it via ToolContext later.
// This specific line might look different in practice.
// For example, storing in session state:
if err := ctx.Session().State().Set("query_tool_policy", policy); err != nil {
    // Handle error, e.g., log it.
}

// Or maybe passing during tool init:
// queryTool := NewQueryTool(policy)
// For this example, we'll assume it gets stored somewhere accessible.
```

```java
// Conceptual example: Setting policy data intended for tool context
// In a real ADK app, this might be set in InvocationContext.session.state
// or passed during tool initialization, then retrieved via ToolContext.

policy = new HashMap<String, Object>(); // Assuming policy is a Map
policy.put("select_only", true);
policy.put("tables", new ArrayList<>("mytable1", "mytable2"));

// Conceptual: Storing policy where the tool can access it via ToolContext later.
// This specific line might look different in practice.
// For example, storing in session state:
invocationContext.session().state().put("query_tool_policy", policy);

// Or maybe passing during tool init:
query_tool = QueryTool(policy);
// For this example, we'll assume it gets stored somewhere accessible.
```

During the tool execution, [**`Tool Context`**](https://adk.dev/tools-custom/#tool-context) will be passed to the tool *(Note: In TypeScript, this is passed as the unified `Context` type)*:

```py
def query(query: str, tool_context: ToolContext) -> str | dict:
  # Assume 'policy' is retrieved from context, e.g., via session state:
  # policy = tool_context.invocation_context.session.state.get('query_tool_policy', {})

  # --- Placeholder Policy Enforcement ---
  policy = tool_context.invocation_context.session.state.get('query_tool_policy', {}) # Example retrieval
  actual_tables = explainQuery(query) # Hypothetical function call

  if not set(actual_tables).issubset(set(policy.get('tables', []))):
    # Return an error message for the model
    allowed = ", ".join(policy.get('tables', ['(None defined)']))
    return f"Error: Query targets unauthorized tables. Allowed: {allowed}"

  if policy.get('select_only', False):
       if not query.strip().upper().startswith("SELECT"):
           return "Error: Policy restricts queries to SELECT statements only."
  # --- End Policy Enforcement ---

  print(f"Executing validated query (hypothetical): {query}")
  return {"status": "success", "results": [...]} # Example successful return
```

```typescript
function query(query: string, context: Context): string | object {
    // Assume 'policy' is retrieved from context, e.g., via session state:
    const policy = context.state.get('query_tool_policy', {}) as {[key: string]: any};

    // --- Placeholder Policy Enforcement ---
    const actual_tables = explainQuery(query); // Hypothetical function call

    const policyTables = new Set(policy['tables'] || []);
    const isSubset = actual_tables.every(table => policyTables.has(table));

    if (!isSubset) {
        // Return an error message for the model
        const allowed = (policy['tables'] || ['(None defined)']).join(', ');
        return `Error: Query targets unauthorized tables. Allowed: {allowed}`;
    }

    if (policy['select_only']) {
        if (!query.trim().toUpperCase().startsWith("SELECT")) {
            return "Error: Policy restricts queries to SELECT statements only.";
        }
    }
    // --- End Policy Enforcement ---

    console.log(`Executing validated query (hypothetical): ${query}`);
    return { "status": "success", "results": [] }; // Example successful return
}
```

```go
import (
    "fmt"
    "strings"

    "google.golang.org/adk/tool"
)

func query(ctx tool.Context, args QueryArgs) (map[string]any, error) {
    // Assume 'policy' is retrieved from context, e.g., via session state:
    policyAny, err := ctx.Session().State().Get("query_tool_policy")
    if err != nil {
        return nil, fmt.Errorf("could not retrieve policy: %w", err)
    }
    policy, _ := policyAny.(map[string]any)
    actualTables := explainQuery(args.Query) // Hypothetical function call

    // --- Placeholder Policy Enforcement ---
    if tables, ok := policy["tables"].([]string); ok {
        if !isSubset(actualTables, tables) {
            // Return an error to signal failure
            allowed := strings.Join(tables, ", ")
            if allowed == "" {
                allowed = "(None defined)"
            }
            return nil, fmt.Errorf("query targets unauthorized tables. Allowed: %s", allowed)
        }
    }

    if selectOnly, _ := policy["select_only"].(bool); selectOnly {
        if !strings.HasPrefix(strings.ToUpper(strings.TrimSpace(args.Query)), "SELECT") {
            return nil, fmt.Errorf("policy restricts queries to SELECT statements only")
        }
    }
    // --- End Policy Enforcement ---

    fmt.Printf("Executing validated query (hypothetical): %s\n", args.Query)
    return map[string]any{"status": "success", "results": []string{"..."}}, nil
}

// Helper function to check if a is a subset of b
func isSubset(a, b []string) bool {
    set := make(map[string]bool)
    for _, item := range b {
        set[item] = true
    }
    for _, item := range a {
        if _, found := set[item]; !found {
            return false
        }
    }
    return true
}
```

```java
import com.google.adk.tools.ToolContext;
import java.util.*;

class ToolContextQuery {

  public Object query(String query, ToolContext toolContext) {

    // Assume 'policy' is retrieved from context, e.g., via session state:
    Map<String, Object> queryToolPolicy =
        toolContext.invocationContext.session().state().getOrDefault("query_tool_policy", null);
    List<String> actualTables = explainQuery(query);

    // --- Placeholder Policy Enforcement ---
    if (!queryToolPolicy.get("tables").containsAll(actualTables)) {
      List<String> allowedPolicyTables =
          (List<String>) queryToolPolicy.getOrDefault("tables", new ArrayList<String>());

      String allowedTablesString =
          allowedPolicyTables.isEmpty() ? "(None defined)" : String.join(", ", allowedPolicyTables);

      return String.format(
          "Error: Query targets unauthorized tables. Allowed: %s", allowedTablesString);
    }

    if (!queryToolPolicy.get("select_only")) {
      if (!query.trim().toUpperCase().startswith("SELECT")) {
        return "Error: Policy restricts queries to SELECT statements only.";
      }
    }
    // --- End Policy Enforcement ---

    System.out.printf("Executing validated query (hypothetical) %s:", query);
    Map<String, Object> successResult = new HashMap<>();
    successResult.put("status", "success");
    successResult.put("results", Arrays.asList("result_item1", "result_item2"));
    return successResult;
  }
}
```

#### Built-in Gemini Safety Features

Gemini models come with in-built safety mechanisms that can be leveraged to improve content and brand safety.

- **Content safety filters**: [Content filters](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/configure-safety-attributes) can help block the output of harmful content. They function independently from Gemini models as part of a layered defense against threat actors who attempt to jailbreak the model. Gemini models on Agent Platform use two types of content filters:
  - **Non-configurable safety filters** automatically block outputs containing prohibited content, such as child sexual abuse material (CSAM) and personally identifiable information (PII).
  - **Configurable content filters** allow you to define blocking thresholds in four harm categories (hate speech, harassment, sexually explicit, and dangerous content,) based on probability and severity scores. These filters are default off but you can configure them according to your needs.

```python
from google.adk.agents import Agent
from google.genai import types

agent = Agent(
    # ...
    generate_content_config=types.GenerateContentConfig(
        safety_settings=[
            types.SafetySetting(
                category=types.HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
                threshold=types.HarmBlockThreshold.OFF,
            ),
        ],
    ),
)
```

```go
import (
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/genai"
)

agent, _ := llmagent.New(llmagent.Config{
    // ...
    GenerateContentConfig: &genai.GenerateContentConfig{
        SafetySettings: []*genai.SafetySetting{
            {
                Category:  genai.HarmCategoryHateSpeech,
                Threshold: genai.HarmBlockThresholdBlockLowAndAbove,
            },
        },
    },
})
```

- **System instructions for safety**: [System instructions](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/safety-system-instructions) for Gemini models on Agent Platform provide direct guidance to the model on how to behave and what type of content to generate. By providing specific instructions, you can proactively steer the model away from generating undesirable content to meet your organization’s unique needs. You can craft system instructions to define content safety guidelines, such as prohibited and sensitive topics, and disclaimer language, as well as brand safety guidelines to ensure the model's outputs align with your brand's voice, tone, values, and target audience.

While these measures are robust against content safety, you need additional checks to reduce agent misalignment, unsafe actions, and brand safety risks.

#### Callbacks and Plugins for Security Guardrails

Callbacks provide a simple, agent-specific method for adding pre-validation to tool and model I/O, whereas plugins offer a reusable solution for implementing general security policies across multiple agents.

When modifications to the tools to add guardrails aren't possible, the [**`Before Tool Callback`**](https://adk.dev/callbacks/types-of-callbacks/#before-tool-callback) function can be used to add pre-validation of calls. The callback has access to the agent's state, the requested tool and parameters. This approach is very general and can even be created to create a common library of re-usable tool policies. However, it might not be applicable for all tools if the information to enforce the guardrails isn't directly visible in the parameters.

```py
# Hypothetical callback function
def validate_tool_params(
    callback_context: CallbackContext, # Correct context type
    tool: BaseTool,
    args: Dict[str, Any],
    tool_context: ToolContext
    ) -> Optional[Dict]: # Correct return type for before_tool_callback

  print(f"Callback triggered for tool: {tool.name}, args: {args}")

  # Example validation: Check if a required user ID from state matches an arg
  expected_user_id = callback_context.state.get("session_user_id")
  actual_user_id_in_args = args.get("user_id_param") # Assuming tool takes 'user_id_param'

  if actual_user_id_in_args != expected_user_id:
      print("Validation Failed: User ID mismatch!")
      # Return a dictionary to prevent tool execution and provide feedback
      return {"error": f"Tool call blocked: User ID mismatch."}

  # Return None to allow the tool call to proceed if validation passes
  print("Callback validation passed.")
  return None

# Hypothetical Agent setup
root_agent = LlmAgent( # Use specific agent type
    model='gemini-flash-latest',
    name='root_agent',
    instruction="...",
    before_tool_callback=validate_tool_params, # Assign the callback
    tools = [
      # ... list of tool functions or Tool instances ...
      # e.g., query_tool_instance
    ]
)
```

```typescript
// Hypothetical callback function
function validateToolParams(
    {tool, args, context}: {
        tool: BaseTool,
        args: {[key: string]: any},
        context: Context
    }
): {[key: string]: any} | undefined {
    console.log(`Callback triggered for tool: ${tool.name}, args: ${JSON.stringify(args)}`);

    // Example validation: Check if a required user ID from state matches an arg
    const expectedUserId = context.state.get("session_user_id");
    const actualUserIdInArgs = args["user_id_param"]; // Assuming tool takes 'user_id_param'

    if (actualUserIdInArgs !== expectedUserId) {
        console.log("Validation Failed: User ID mismatch!");
        // Return a dictionary to prevent tool execution and provide feedback
        return {"error": `Tool call blocked: User ID mismatch.`};
    }

    // Return undefined to allow the tool call to proceed if validation passes
    console.log("Callback validation passed.");
    return undefined;
}

// Hypothetical Agent setup
const rootAgent = new LlmAgent({
    model: 'gemini-flash-latest',
    name: 'root_agent',
    instruction: "...",
    beforeToolCallback: validateToolParams, // Assign the callback
    tools: [
      // ... list of tool functions or Tool instances ...
      // e.g., queryToolInstance
    ]
});
```

```go
import (
    "fmt"

    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/tool"
)

// Hypothetical callback function
func validateToolParams(
    ctx tool.Context,
    t tool.Tool,
    args map[string]any,
) (map[string]any, error) {
    fmt.Printf("Callback triggered for tool: %s, args: %v\n", t.Name(), args)

    // Example validation: Check if a required user ID from state matches an arg
    expectedUserIDVal, err := ctx.Session().State().Get("session_user_id")
    if err != nil {
        // Return a map to prevent tool execution and provide feedback to the model.
        return map[string]any{"error": "Tool call blocked: User ID not found."}, nil
    }
    expectedUserID, _ := expectedUserIDVal.(string)

    actualUserID, ok := args["user_id_param"].(string)
    if !ok || actualUserID != expectedUserID {
        fmt.Println("Validation Failed: User ID mismatch!")
        return map[string]any{"error": "Tool call blocked: User ID mismatch."}, nil
    }

    // Return nil, nil to allow the tool call to proceed if validation passes
    fmt.Println("Callback validation passed.")
    return nil, nil
}

// Hypothetical Agent setup
// agent, _ := llmagent.New(llmagent.Config{
//  Model: "gemini-flash-latest",
//  Name: "root_agent",
//  Instruction: "...",
//  BeforeToolCallbacks: []llmagent.BeforeToolCallback{validateToolParams},
//  Tools: []tool.Tool{queryToolInstance},
```

```java
// Hypothetical callback function
public Optional<Map<String, Object>> validateToolParams(
  CallbackContext callbackContext,
  Tool baseTool,
  Map<String, Object> input,
  ToolContext toolContext) {

System.out.printf("Callback triggered for tool: %s, Args: %s", baseTool.name(), input);

// Example validation: Check if a required user ID from state matches an input parameter
Object expectedUserId = callbackContext.state().get("session_user_id");
Object actualUserIdInput = input.get("user_id_param"); // Assuming tool takes 'user_id_param'

if (!actualUserIdInput.equals(expectedUserId)) {
  System.out.println("Validation Failed: User ID mismatch!");
  // Return to prevent tool execution and provide feedback
  return Optional.of(Map.of("error", "Tool call blocked: User ID mismatch."));
}

// Return to allow the tool call to proceed if validation passes
System.out.println("Callback validation passed.");
return Optional.empty();
}

// Hypothetical Agent setup
public void runAgent() {
LlmAgent agent =
    LlmAgent.builder()
        .model("gemini-flash-latest")
        .name("AgentWithBeforeToolCallback")
        .instruction("...")
        .beforeToolCallback(this::validateToolParams) // Assign the callback
        .tools(anyToolToUse) // Define the tool to be used
        .build();
}
```

However, when adding security guardrails to your agent applications, plugins are the recommended approach for implementing policies that are not specific to a single agent. Plugins are designed to be self-contained and modular, allowing you to create individual plugins for specific security policies, and apply them globally at the runner level. This means that a security plugin can be configured once and applied to every agent that uses the runner, ensuring consistent security guardrails across your entire application without repetitive code.

Some examples include:

- **Gemini as a Judge Plugin**: This plugin uses Gemini Flash Lite to evaluate user inputs, tool input and output, and agent's response for appropriateness, prompt injection, and jailbreak detection. The plugin configures Gemini to act as a safety filter to mitigate against content safety, brand safety, and agent misalignment. The plugin is configured to pass user input, tool input and output, and model output to Gemini Flash Lite, who decides if the input to the agent is safe or unsafe. If Gemini decides the input is unsafe, the agent returns a predetermined response: "Sorry I cannot help with that. Can I help you with something else?".
- **Model Armor Plugin**: A plugin that queries the model armor API to check for potential content safety violations at specified points of agent execution. Similar to the *Gemini as a Judge* plugin, if Model Armor finds matches of harmful content, it returns a predetermined response to the user.
- **PII Redaction Plugin**: A specialized plugin with design for the [Before Tool Callback](/plugins/#tool-callbacks) and specifically created to redact personally identifiable information before it’s processed by a tool or sent to an external service.

### Sandboxed Code Execution

Code execution is a special tool that has extra security implications: sandboxing must be used to prevent model-generated code to compromise the local environment, potentially creating security issues.

Google and the ADK provide several options for safe code execution. [Vertex Gemini Enterprise API code execution feature](https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/code-execution-api) enables agents to take advantage of sandboxed code execution server-side by enabling the tool_execution tool. For code performing data analysis, you can use the [Code Executor](/integrations/code-execution/) tool in ADK to call the [Vertex Code Interpreter Extension](https://cloud.google.com/vertex-ai/generative-ai/docs/extensions/code-interpreter).

If none of these options satisfy your requirements, you can build your own code executor using the building blocks provided by the ADK. We recommend creating execution environments that are hermetic: no network connections and API calls permitted to avoid uncontrolled data exfiltration; and full cleanup of data across execution to not create cross-user exfiltration concerns.

### Evaluations

See [Evaluate Agents](https://adk.dev/evaluate/index.md).

### VPC-SC Perimeters and Network Controls

If you are executing your agent into a VPC-SC perimeter, that will guarantee that all API calls will only be manipulating resources within the perimeter, reducing the chance of data exfiltration.

However, identity and perimeters only provide coarse controls around agent actions. Tool-use guardrails mitigate such limitations, and give more power to agent developers to finely control which actions to allow.

### Other Security Risks

#### Always Escape Model-Generated Content in UIs

Care must be taken when agent output is visualized in a browser: if HTML or JS content isn't properly escaped in the UI, the text returned by the model could be executed, leading to data exfiltration. For example, an indirect prompt injection can trick a model to include an img tag tricking the browser to send the session content to a 3rd party site; or construct URLs that, if clicked, send data to external sites. Proper escaping of such content must ensure that model-generated text isn't interpreted as code by browsers.
# Components

# Context

Supported in ADKPython v0.1.0TypeScript v0.2.0Go v0.1.0Java v0.1.0

In the Agent Development Kit (ADK), *context* refers to the crucial bundle of information available to your agent and its tools during specific operations. Think of it as the necessary background knowledge and resources needed to handle a current task or conversation turn effectively.

Agents often need more than just the latest user message to perform well. Context is essential because it enables:

1. **Maintaining State:** Remembering details across multiple steps in a conversation (e.g., user preferences, previous calculations, items in a shopping cart). This is primarily managed through **session state**.
1. **Passing Data:** Sharing information discovered or generated in one step (like an LLM call or a tool execution) with subsequent steps. Session state is key here too.
1. **Accessing Services:** Interacting with framework capabilities like:
   - **Artifact Storage:** Saving or loading files or data blobs (like PDFs, images, configuration files) associated with the session.
   - **Memory:** Searching for relevant information from past interactions or external knowledge sources connected to the user.
   - **Authentication:** Requesting and retrieving credentials needed by tools to access external APIs securely.
1. **Identity and Tracking:** Knowing which agent is currently running (`agent.name`) and uniquely identifying the current request-response cycle (`invocation_id`) for logging and debugging.
1. **Tool-Specific Actions:** Enabling specialized operations within tools, such as requesting authentication or searching memory, which require access to the current interaction's details.

The central piece holding all this information together for a single, complete user-request-to-final-response cycle (an **invocation**) is the `InvocationContext`. However, you typically won't create or manage this object directly. The ADK framework creates it when an invocation starts (e.g., via `runner.run_async`) and passes the relevant contextual information implicitly to your agent code, callbacks, and tools.

```python
# How the framework provides context
from google.adk import Runner

# 1. You initialize a Runner with your agent and services
runner = Runner(
    app_name="my_app",
    agent=my_root_agent,
    session_service=my_session_service,
    artifact_service=my_artifact_service,
)

# 2. You call run_async with the user input
# Note: run_async is an asynchronous generator yielding Events.
# The framework internally creates an InvocationContext and passes it
# implicitly to your agent code, callbacks, and tools.
async for event in runner.run_async(
    user_id="user123",
    session_id="session456",
    new_message=user_message
):
    print(event.stringify_content())

# As a developer, you work with the context objects provided in method arguments.
```

```typescript
/* Conceptual Pseudocode: How the framework provides context (Internal Logic) */

const runner = new InMemoryRunner({ agent: myRootAgent });
const session = await runner.sessionService.createSession({ ... });
const userMessage = createUserContent(...);

// --- Inside runner.runAsync(...) ---
// 1. Framework creates the main context for this specific run
const invocationContext = new InvocationContext({
  invocationId: "unique-id-for-this-run",
  session: session,
  userContent: userMessage,
  agent: myRootAgent, // The starting agent
  sessionService: runner.sessionService,
  pluginManager: runner.pluginManager,
  // ... other necessary fields ...
});
//
// 2. Framework calls the agent's run method, passing the context implicitly
await myRootAgent.runAsync(invocationContext);
//   --- End Internal Logic ---

// As a developer, you work with the context objects provided in method arguments.
```

```go
/* Conceptual Pseudocode: How the framework provides context (Internal Logic) */
sessionService := session.InMemoryService()

r, err := runner.New(runner.Config{
    AppName:        appName,
    Agent:          myAgent,
    SessionService: sessionService,
})
if err != nil {
    log.Fatalf("Failed to create runner: %v", err)
}

s, err := sessionService.Create(ctx, &session.CreateRequest{
    AppName: appName,
    UserID:  userID,
})
if err != nil {
    log.Fatalf("FATAL: Failed to create session: %v", err)
}

scanner := bufio.NewScanner(os.Stdin)
for {
    fmt.Print("\nYou > ")
    if !scanner.Scan() {
        break
    }
    userInput := scanner.Text()
    if strings.EqualFold(userInput, "quit") {
        break
    }
    userMsg := genai.NewContentFromText(userInput, genai.RoleUser)
    events := r.Run(ctx, s.Session.UserID(), s.Session.ID(), userMsg, agent.RunConfig{
        StreamingMode: agent.StreamingModeNone,
    })
    fmt.Print("\nAgent > ")
    for event, err := range events {
        if err != nil {
            log.Printf("ERROR during agent execution: %v", err)
            break
        }
        fmt.Print(event.Content.Parts[0].Text)
    }
}
```

```java
/* How the framework provides context */
InMemoryRunner runner = new InMemoryRunner(agent);
Session session = runner
    .sessionService()
    .createSession(runner.appName(), USER_ID, initialState, SESSION_ID )
    .blockingGet();

try (Scanner scanner = new Scanner(System.in, StandardCharsets.UTF_8)) {
  while (true) {
    System.out.print("\nYou > ");
    String userInput = scanner.nextLine();
    if ("quit".equalsIgnoreCase(userInput)) {
      break;
    }
    Content userMsg = Content.fromParts(Part.fromText(userInput));
    Flowable<Event> events = runner.runAsync(session.userId(), session.id(), userMsg);
    System.out.print("\nAgent > ");
    events.blockingForEach(event -> System.out.print(event.stringifyContent()));
  }
}
```

## The Different types of Context

While `InvocationContext` acts as the comprehensive internal container, ADK provides specialized context objects tailored to specific situations. This ensures you have the right tools and permissions for the task at hand without needing to handle the full complexity of the internal context everywhere. Here are the different "flavors" you'll encounter:

1. **`InvocationContext`**

   - **Where Used:** Received as the `ctx` argument directly within an agent's core implementation methods (`_run_async_impl`, `_run_live_impl`).
   - **Purpose:** Provides access to the *entire* state of the current invocation. This is the most comprehensive context object.
   - **Key Contents:** Direct access to `session` (including `state` and `events`), the current `agent` instance, `invocation_id`, initial `user_content`, references to configured services (`artifact_service`, `memory_service`, `session_service`), and fields related to live/streaming modes.
   - **Use Case:** Primarily used when the agent's core logic needs direct access to the overall session or services, though often state and artifact interactions are delegated to callbacks/tools which use their own contexts. Also used to control the invocation itself (e.g., setting `ctx.end_invocation = True`).

   ```python
   # Agent implementation receiving InvocationContext
   from google.adk.agents import BaseAgent
   from google.adk.agents.invocation_context import InvocationContext
   from google.adk.events import Event
   from typing import AsyncGenerator

   class MyAgent(BaseAgent):
       async def _run_async_impl(self, ctx: InvocationContext) -> AsyncGenerator[Event, None]:
           # Direct access example
           agent_name = ctx.agent.name
           session_id = ctx.session.id
           print(f"Agent {agent_name} running in session {session_id} for invocation {ctx.invocation_id}")
           # ... agent logic using ctx ...
           yield # ... event ...
   ```

   ```typescript
   // Pseudocode: Agent implementation receiving InvocationContext
   import { BaseAgent, InvocationContext, Event } from '@google/adk';

   class MyAgent extends BaseAgent {
     async *runAsyncImpl(ctx: InvocationContext): AsyncGenerator<Event, void, undefined> {
       // Direct access example
       const agentName = ctx.agent.name;
       const sessionId = ctx.session.id;
       console.log(`Agent ${agentName} running in session ${sessionId} for invocation ${ctx.invocationId}`);
       // ... agent logic using ctx ...
       yield; // ... event ...
     }
   }
   ```

   ```go
   import (
       "google.golang.org/adk/agent"
       "google.golang.org/adk/session"
   )

   // Pseudocode: Agent implementation receiving InvocationContext
   type MyAgent struct {
   }

   func (a *MyAgent) Run(ctx agent.InvocationContext) iter.Seq2[*session.Event, error] {
       return func(yield func(*session.Event, error) bool) {
           // Direct access example
           agentName := ctx.Agent().Name()
           sessionID := ctx.Session().ID()
           fmt.Printf("Agent %s running in session %s for invocation %s\n", agentName, sessionID, ctx.InvocationID())
           // ... agent logic using ctx ...
           yield(&session.Event{Author: agentName}, nil)
       }
   }
   ```

   ```java
   // Example: Agent implementation receiving InvocationContext
   import com.google.adk.agents.BaseAgent;
   import com.google.adk.agents.InvocationContext;
   import com.google.adk.events.Event;
   import io.reactivex.rxjava3.core.Flowable;

   public class MyAgent extends BaseAgent {
       @Override
       protected Flowable<Event> runAsyncImpl(InvocationContext invocationContext) {
           // Direct access example
           String agentName = invocationContext.agent().name();
           String sessionId = invocationContext.session().id();
           String invocationId = invocationContext.invocationId();
           System.out.println("Agent " + agentName + " running in session " + sessionId + " for invocation " + invocationId);
           // ... agent logic using invocationContext ...
           return Flowable.empty();
       }
   }
   ```

1. **`ReadonlyContext`**

   - **Where Used:** Provided in scenarios where only read access to basic information is needed and mutation is disallowed (e.g., `InstructionProvider` functions). It's also the base class for other contexts.
   - **Purpose:** Offers a safe, read-only view of fundamental contextual details.
   - **Key Contents:** `invocation_id`, `agent_name`, and a read-only *view* of the current `state`.

   ```python
   # Example: Instruction provider receiving ReadonlyContext
   from google.adk.agents.readonly_context import ReadonlyContext

   def my_instruction_provider(context: ReadonlyContext) -> str:
       # Read-only access example
       # The state property provides a read-only MappingProxyType view of the state
       user_tier = context.state.get("user_tier", "standard")
       # context.state['new_key'] = 'value' # TypeError: 'mappingproxy' object does not support item assignment
       return f"Process the request for a {user_tier} user."
   ```

   ```typescript
   // Pseudocode: Instruction provider receiving ReadonlyContext
   import { ReadonlyContext } from '@google/adk';

   function myInstructionProvider(context: ReadonlyContext): string {
     // Read-only access example
     // The state object is read-only
     const userTier = context.state.get('user_tier') ?? 'standard';
     // context.state.set('new_key', 'value'); // This would fail or throw an error
     return `Process the request for a ${userTier} user.`;
   }
   ```

   ```go
   import "google.golang.org/adk/agent"

   // Pseudocode: Instruction provider receiving ReadonlyContext
   func myInstructionProvider(ctx agent.ReadonlyContext) (string, error) {
       // Read-only access example
       userTier, err := ctx.ReadonlyState().Get("user_tier")
       if err != nil {
           userTier = "standard" // Default value
       }
       // ctx.ReadonlyState() has no Set method since State() is read-only.
       return fmt.Sprintf("Process the request for a %v user.", userTier), nil
   }
   ```

   ```java
   // Example: Instruction provider receiving ReadonlyContext
   import com.google.adk.agents.ReadonlyContext;

   public String myInstructionProvider(ReadonlyContext context) {
       // Read-only access example
       // state() returns an unmodifiable view of the session state
       String userTier = (String) context.state().getOrDefault("user_tier", "standard");
       // context.state().put("new_key", "value"); // UnsupportedOperationException
       return "Process the request for a " + userTier + " user.";
   }
   ```

1. **`CallbackContext`**

   - **Where Used:** Passed as `callback_context` to agent lifecycle callbacks (`before_agent_callback`, `after_agent_callback`) and model interaction callbacks (`before_model_callback`, `after_model_callback`).
   - **Purpose:** Facilitates inspecting and modifying state, interacting with artifacts, and accessing invocation details *specifically within callbacks*.
   - **Key Capabilities (Adds to `ReadonlyContext`):**
     - **Mutable `state` Property:** Allows reading *and writing* to session state. Changes made here (`callback_context.state['key'] = value`) are tracked and associated with the event generated by the framework after the callback.
     - **Artifact Methods:** `load_artifact(filename)` and `save_artifact(filename, part)` methods for interacting with the configured `artifact_service`.
     - Direct `user_content` access.

   *(Note: In TypeScript, `CallbackContext` and `ToolContext` are unified into a single `Context` type.)*

   ```python
   # Example: Callback receiving Context (CallbackContext is unified into Context)
   from google.adk.agents.context import Context
   from google.adk.models import LlmRequest
   from google.genai import types
   from typing import Optional

   def my_before_model_cb(context: Context, request: LlmRequest) -> Optional[types.Content]:
       # Read/Write state example
       call_count = context.state.get("model_calls", 0)
       context.state["model_calls"] = call_count + 1 # Modify state (tracks delta)

       # Optionally load an artifact
       # config_part = context.load_artifact("model_config.json")
       print(f"Preparing model call #{call_count + 1} for invocation {context.invocation_id}")
       return None # Allow model call to proceed
   ```

   ```typescript
   // Pseudocode: Callback receiving Context
   import { Context, LlmRequest } from '@google/adk';
   import { Content } from '@google/genai';

   function myBeforeModelCb(context: Context, request: LlmRequest): Content | undefined {
     // Read/Write state example
     const callCount = (context.state.get('model_calls') as number) || 0;
     context.state.set('model_calls', callCount + 1); // Modify state

     // Optionally load an artifact
     // const configPart = await context.loadArtifact('model_config.json');
     console.log(`Preparing model call #${callCount + 1} for invocation ${context.invocationId}`);
     return undefined; // Allow model call to proceed
   }
   ```

   ```go
   import (
       "google.golang.org/adk/agent"
       "google.golang.org/adk/model"
   )

   // Pseudocode: Callback receiving CallbackContext
   func myBeforeModelCb(ctx agent.CallbackContext, req *model.LLMRequest) (*model.LLMResponse, error) {
       // Read/Write state example
       callCount, err := ctx.State().Get("model_calls")
       if err != nil {
           callCount = 0 // Default value
       }
       newCount := callCount.(int) + 1
       if err := ctx.State().Set("model_calls", newCount); err != nil {
           return nil, err
       }

       // Optionally load an artifact
       // configPart, err := ctx.Artifacts().Load("model_config.json")
       fmt.Printf("Preparing model call #%d for invocation %s\n", newCount, ctx.InvocationID())
       return nil, nil // Allow model call to proceed
   }
   ```

   ```java
   // Example: Callback receiving CallbackContext
   import com.google.adk.agents.CallbackContext;
   import com.google.adk.models.LlmRequest;
   import com.google.adk.models.LlmResponse;
   import io.reactivex.rxjava3.core.Maybe;

   public Maybe<LlmResponse> myBeforeModelCb(CallbackContext callbackContext, LlmRequest request) {
       // Read/Write state example
       int callCount = (int) callbackContext.state().getOrDefault("model_calls", 0);
       callbackContext.state().put("model_calls", callCount + 1); // Modify state (tracks delta)

       // Optionally load an artifact
       // Maybe<Part> configPart = callbackContext.loadArtifact("model_config.json");
       System.out.println("Preparing model call " + (callCount + 1) + " for invocation " + callbackContext.invocationId());
       return Maybe.empty(); // Allow model call to proceed
   }
   ```

1. **`ToolContext`**

   - **Where Used:** Passed as `tool_context` to the functions backing `FunctionTool`s and to tool execution callbacks (`before_tool_callback`, `after_tool_callback`).
   - **Purpose:** Provides everything `CallbackContext` does, plus specialized methods essential for tool execution, like handling authentication, searching memory, and listing artifacts.
   - **Key Capabilities (Adds to `CallbackContext`):**
     - **Authentication Methods:** `request_credential(auth_config)` to trigger an auth flow, and `get_auth_response(auth_config)` to retrieve credentials provided by the user/system.
     - **Artifact Listing:** `list_artifacts()` to discover available artifacts in the session.
     - **Memory Search:** `search_memory(query)` to query the configured `memory_service`.
     - **`function_call_id` Property:** Identifies the specific function call from the LLM that triggered this tool execution, crucial for linking authentication requests or responses back correctly.
     - **`actions` Property:** Direct access to the `EventActions` object for this step, allowing the tool to signal state changes, auth requests, etc.

   ```python
   # Example: Tool function receiving ToolContext
   from google.adk.tools import ToolContext
   from typing import Dict, Any

   # Assume this function is wrapped by a FunctionTool
   def search_external_api(query: str, tool_context: ToolContext) -> Dict[str, Any]:
       api_key = tool_context.state.get("api_key")
       if not api_key:
           # Define required auth config
           # auth_config = AuthConfig(...)
           # tool_context.request_credential(auth_config) # Request credentials
           # Use the 'actions' property to signal the auth request has been made
           # tool_context.actions.requested_auth_configs[tool_context.function_call_id] = auth_config
           return {"status": "Auth Required"}

       # Use the API key...
       print(f"Tool executing for query '{query}' using API key. Invocation: {tool_context.invocation_id}")

       # Optionally search memory or list artifacts
       # relevant_docs = tool_context.search_memory(f"info related to {query}")
       # available_files = tool_context.list_artifacts()

       return {"result": f"Data for {query} fetched."}
   ```

   ```typescript
   // Pseudocode: Tool function receiving Context
   import { Context } from '@google/adk';

   // __Assume this function is wrapped by a FunctionTool__
   function searchExternalApi(query: string, context: Context): { [key: string]: string } {
     const apiKey = context.state.get('api_key') as string;
     if (!apiKey) {
        // Define required auth config
        // const authConfig = new AuthConfig(...);
        // context.requestCredential(authConfig); // Request credentials
        // The 'actions' property is now automatically updated by requestCredential
        return { status: 'Auth Required' };
     }

     // Use the API key...
     console.log(`Tool executing for query '${query}' using API key. Invocation: ${context.invocationId}`);

     // Optionally search memory or list artifacts
     // Note: accessing services like memory/artifacts is typically async in TS,
     // so you would need to mark this function 'async' if you reused them.
     // context.searchMemory(`info related to ${query}`).then(...)
     // context.listArtifacts().then(...)

     return { result: `Data for ${query} fetched.` };
   }
   ```

   ```go
   import "google.golang.org/adk/tool"

   // Pseudocode: Tool function receiving ToolContext
   type searchExternalAPIArgs struct {
       Query string `json:"query" jsonschema:"The query to search for."`
   }

   func searchExternalAPI(tc tool.Context, input searchExternalAPIArgs) (string, error) {
       apiKey, err := tc.State().Get("api_key")
       if err != nil || apiKey == "" {
           // In a real scenario, you would define and request credentials here.
           // This is a conceptual placeholder.
           return "", fmt.Errorf("auth required")
       }

       // Use the API key...
       fmt.Printf("Tool executing for query '%s' using API key. Invocation: %s\n", input.Query, tc.InvocationID())

       // Optionally search memory or list artifacts
       // relevantDocs, _ := tc.SearchMemory(tc, "info related to %s", input.Query))
       // availableFiles, _ := tc.Artifacts().List()

       return fmt.Sprintf("Data for %s fetched.", input.Query), nil
   }
   ```

   ```java
   // Example: Tool function receiving ToolContext
   import com.google.adk.tools.ToolContext;
   import java.util.Map;

   // Assume this function is wrapped by a FunctionTool
   public Map<String, Object> searchExternalApi(String query, ToolContext toolContext) {
       String apiKey = (String) toolContext.state().getOrDefault("api_key", "");
       if (apiKey.isEmpty()) {
           // Define required auth config
           // authConfig = AuthConfig(...);
           // toolContext.requestCredential(authConfig); // Request credentials
           // Use the 'actions' property to signal the auth request has been made
           return Map.of("status", "Auth Required");
       }

       // Use the API key...
       System.out.println("Tool executing for query " + query + " using API key.");

       // Optionally list artifacts
       // Single<List<String>> availableFiles = toolContext.listArtifacts();

       return Map.of("result", "Data for " + query + " fetched");
   }
   ```

Understanding these different context objects and when to use them is key to effectively managing state, accessing services, and controlling the flow of your ADK application. The next section will detail common tasks you can perform using these contexts.

## Common Tasks Using Context

Now that you understand the different context objects, let's focus on how to use them for common tasks when building your agents and tools.

### Accessing Information

You'll frequently need to read information stored within the context.

- **Reading Session State:** Access data saved in previous steps or user/app-level settings. Use dictionary-like access on the `state` property.

  ```python
  # Example: In a Tool function
  from google.adk.tools import ToolContext

  def my_tool(tool_context: ToolContext, **kwargs):
      user_pref = tool_context.state.get("user_display_preference", "default_mode")
      api_endpoint = tool_context.state.get("app:api_endpoint") # Read app-level state

      if user_pref == "dark_mode":
          # ... apply dark mode logic ...
          pass
      print(f"Using API endpoint: {api_endpoint}")
      # ... rest of tool logic ...

  # Example: In a Callback function
  from google.adk.agents.context import Context

  def my_callback(context: Context, **kwargs):
      last_tool_result = context.state.get("temp:last_api_result") # Read temporary state
      if last_tool_result:
          print(f"Found temporary result from last tool: {last_tool_result}")
      # ... callback logic ...
  ```

  ```typescript
  // Pseudocode: In a Tool function
  import { Context } from '@google/adk';

  async function myTool(context: Context) {
    const userPref = context.state.get('user_display_preference', 'default_mode');
    const apiEndpoint = context.state.get('app:api_endpoint'); // Read app-level state

    if (userPref === 'dark_mode') {
      // ... apply dark mode logic ...
    }
    console.log(`Using API endpoint: ${apiEndpoint}`);
    // ... rest of tool logic ...
  }

  // Pseudocode: In a Callback function
  import { Context } from '@google/adk';

  function myCallback(context: Context) {
    const lastToolResult = context.state.get('temp:last_api_result'); // Read temporary state
    if (lastToolResult) {
      console.log(`Found temporary result from last tool: ${lastToolResult}`);
    }
    // ... callback logic ...
  }
  ```

  ```go
  import (
      "google.golang.org/adk/agent"
      "google.golang.org/adk/session"
      "google.golang.org/adk/tool"
      "google.golang.org/genai"
  )

  // Pseudocode: In a Tool function
  type toolArgs struct {
      // Define tool-specific arguments here
  }

  type toolResults struct {
      // Define tool-specific results here
  }

  // Example tool function demonstrating state access
  func myTool(tc tool.Context, input toolArgs) (toolResults, error) {
      userPref, err := tc.State().Get("user_display_preference")
      if err != nil {
          userPref = "default_mode"
      }
      apiEndpoint, _ := tc.State().Get("app:api_endpoint") // Read app-level state

      if userPref == "dark_mode" {
          // ... apply dark mode logic ...
      }
      fmt.Printf("Using API endpoint: %v\n", apiEndpoint)
      // ... rest of tool logic ...
      return toolResults{}, nil
  }


  // Pseudocode: In a Callback function
  func myCallback(ctx agent.CallbackContext) (*genai.Content, error) {
      lastToolResult, err := ctx.State().Get("temp:last_api_result") // Read temporary state
      if err == nil {
          fmt.Printf("Found temporary result from last tool: %v\n", lastToolResult)
      } else {
          fmt.Println("No temporary result found.")
      }
      // ... callback logic ...
      return nil, nil
  }
  ```

  ```java
  // Example: In a Tool function
  import com.google.adk.tools.ToolContext;

  public void myTool(ToolContext toolContext) {
      String userPref = (String) toolContext.state().getOrDefault("user_display_preference", "default_mode");
      String apiEndpoint = (String) toolContext.state().get("app:api_endpoint"); // Read app-level state

      if ("dark_mode".equals(userPref)) {
          // ... apply dark mode logic ...
      }
      System.out.println("Using API endpoint: " + apiEndpoint);
      // ... rest of tool logic ...
  }

  // Example: In a Callback function
  import com.google.adk.agents.CallbackContext;

  public void myCallback(CallbackContext callbackContext) {
      String lastToolResult = (String) callbackContext.state().get("temp:last_api_result"); // Read temporary state

      if (lastToolResult != null && !lastToolResult.isEmpty()) {
          System.out.println("Found temporary result from last tool: " + lastToolResult);
      }
      // ... callback logic ...
  }
  ```

- **Getting Current Identifiers:** Useful for logging or custom logic based on the current operation.

  ```python
  # Example: In any context (ToolContext shown)
  from google.adk.tools import ToolContext

  def log_tool_usage(tool_context: ToolContext, **kwargs):
      agent_name = tool_context.agent_name
      inv_id = tool_context.invocation_id
      func_call_id = getattr(tool_context, 'function_call_id', 'N/A') # Specific to ToolContext

      print(f"Log: Invocation={inv_id}, Agent={agent_name}, FunctionCallID={func_call_id} - Tool Executed.")
  ```

  ```typescript
  // Pseudocode: In any context
  import { Context } from '@google/adk';

  function logToolUsage(context: Context) {
    const agentName = context.agentName;
    const invId = context.invocationId;
    const functionCallId = context.functionCallId ?? 'N/A'; // Available when executing a tool

    console.log(`Log: Invocation=${invId}, Agent=${agentName}, FunctionCallID=${functionCallId} - Tool Executed.`);
  }
  ```

  ```go
  import "google.golang.org/adk/tool"

  // Pseudocode: In any context (ToolContext shown)
  type logToolUsageArgs struct{}
  type logToolUsageResult struct {
      Status string `json:"status"`
  }

  func logToolUsage(tc tool.Context, args logToolUsageArgs) (logToolUsageResult, error) {
      agentName := tc.AgentName()
      invID := tc.InvocationID()
      funcCallID := tc.FunctionCallID()

      fmt.Printf("Log: Invocation=%s, Agent=%s, FunctionCallID=%s - Tool Executed.\n", invID, agentName, funcCallID)
      return logToolUsageResult{Status: "Logged successfully"}, nil
  }
  ```

  ```java
  // Example: In any context (ToolContext shown)
  import com.google.adk.tools.ToolContext;

  public void logToolUsage(ToolContext toolContext) {
      String agentName = toolContext.agentName();
      String invId = toolContext.invocationId();
      String functionCallId = toolContext.functionCallId().orElse("N/A"); // Specific to ToolContext
      System.out.println("Log: Invocation= " + invId + " Agent= " + agentName + " FunctionCallID= " + functionCallId);
  }
  ```

- **Accessing the Initial User Input:** Refer back to the message that started the current invocation.

  ```python
  # Example: In a Callback
  from google.adk.agents.context import Context

  def check_initial_intent(context: Context, **kwargs):
      initial_text = "N/A"
      if context.user_content and context.user_content.parts:
          initial_text = context.user_content.parts[0].text or "Non-text input"

      print(f"This invocation started with user input: '{initial_text}'")

  # Example: In an Agent's _run_async_impl
  # async def _run_async_impl(self, ctx: InvocationContext) -> AsyncGenerator[Event, None]:
  #     if ctx.user_content and ctx.user_content.parts:
  #         initial_text = ctx.user_content.parts[0].text
  #         print(f"Agent logic remembering initial query: {initial_text}")
  #     ...
  ```

  ```typescript
  // Pseudocode: In a Callback
  import { Context } from '@google/adk';

  function checkInitialIntent(context: Context) {
    let initialText = 'N/A';
    const userContent = context.userContent;
    if (userContent?.parts?.length) {
      initialText = userContent.parts[0].text ?? 'Non-text input';
    }

    console.log(`This invocation started with user input: '${initialText}'`);
  }
  ```

  ```go
  import (
      "google.golang.org/adk/agent"
      "google.golang.org/genai"
  )

  // Pseudocode: In a Callback
  func logInitialUserInput(ctx agent.CallbackContext) (*genai.Content, error) {
      userContent := ctx.UserContent()
      if userContent != nil && len(userContent.Parts) > 0 {
          if text := userContent.Parts[0].Text; text != "" {
              fmt.Printf("User's initial input for this turn: '%s'\n", text)
          }
      }
      return nil, nil // No modification
  }
  ```

  ```java
  // Example: In a Callback
  import com.google.adk.agents.CallbackContext;
  import com.google.genai.types.Content;

  public void checkInitialIntent(CallbackContext callbackContext) {
      String initialText = "N/A";
      if (callbackContext.userContent().isPresent() && callbackContext.userContent().get().parts() != null && !callbackContext.userContent().get().parts().get().isEmpty()) {
          initialText = callbackContext.userContent().get().parts().get().get(0).text().orElse("Non-text input");
          // ...
          System.out.println("This invocation started with user input: " + initialText);
      }
  }
  ```

### Managing State

State is crucial for memory and data flow. When you modify state using `CallbackContext` or `ToolContext`, the changes are automatically tracked and persisted by the framework.

- **How it Works:** Writing to `callback_context.state['my_key'] = my_value` or `tool_context.state['my_key'] = my_value` adds this change to the `EventActions.state_delta` associated with the current step's event. The `SessionService` then applies these deltas when persisting the event.

- **Passing Data Between Tools**

  ```python
  # Example: Tool 1 - Fetches user ID
  from google.adk.tools import ToolContext
  import uuid

  def get_user_profile(tool_context: ToolContext) -> dict:
      user_id = str(uuid.uuid4()) # Simulate fetching ID
      # Save the ID to state for the next tool
      tool_context.state["temp:current_user_id"] = user_id
      return {"profile_status": "ID generated"}

  # Example: Tool 2 - Uses user ID from state
  def get_user_orders(tool_context: ToolContext) -> dict:
      user_id = tool_context.state.get("temp:current_user_id")
      if not user_id:
          return {"error": "User ID not found in state"}

      print(f"Fetching orders for user ID: {user_id}")
      # ... logic to fetch orders using user_id ...
      return {"orders": ["order123", "order456"]}
  ```

  ```typescript
  // Pseudocode: Tool 1 - Fetches user ID
  import { Context } from '@google/adk';
  import { v4 as uuidv4 } from 'uuid';

  function getUserProfile(context: Context): Record<string, string> {
    const userId = uuidv4(); // Simulate fetching ID
    // Save the ID to state for the next tool
    context.state.set('temp:current_user_id', userId);
    return { profile_status: 'ID generated' };
  }

  // Pseudocode: Tool 2 - Uses user ID from state
  function getUserOrders(context: Context): Record<string, string | string[]> {
    const userId = context.state.get('temp:current_user_id');
    if (!userId) {
      return { error: 'User ID not found in state' };
    }

    console.log(`Fetching orders for user ID: ${userId}`);
    // ... logic to fetch orders using user_id ...
    return { orders: ['order123', 'order456'] };
  }
  ```

  ```go
  import "google.golang.org/adk/tool"

  // Pseudocode: Tool 1 - Fetches user ID
  type GetUserProfileArgs struct {
  }

  func getUserProfile(tc tool.Context, input GetUserProfileArgs) (string, error) {
      // A random user ID for demonstration purposes
      userID := "random_user_456"

      // Save the ID to state for the next tool
      if err := tc.State().Set("temp:current_user_id", userID); err != nil {
          return "", fmt.Errorf("failed to set user ID in state: %w", err)
      }
      return "ID generated", nil
  }


  // Pseudocode: Tool 2 - Uses user ID from state
  type GetUserOrdersArgs struct {
  }

  type getUserOrdersResult struct {
      Orders []string `json:"orders"`
  }

  func getUserOrders(tc tool.Context, input GetUserOrdersArgs) (*getUserOrdersResult, error) {
      userID, err := tc.State().Get("temp:current_user_id")
      if err != nil {
          return &getUserOrdersResult{}, fmt.Errorf("user ID not found in state")
      }

      fmt.Printf("Fetching orders for user ID: %v\n", userID)
      // ... logic to fetch orders using user_id ...
      return &getUserOrdersResult{Orders: []string{"order123", "order456"}}, nil
  }
  ```

  ```java
  // Example: Tool 1 - Fetches user ID
  import com.google.adk.tools.ToolContext;
  import java.util.Map;
  import java.util.UUID;

  public Map<String, String> getUserProfile(ToolContext toolContext) {
      String userId = UUID.randomUUID().toString();
      // Save the ID to state for the next tool
      toolContext.state().put("temp:current_user_id", userId);
      return Map.of("profile_status", "ID generated");
  }

  // Example: Tool 2 - Uses user ID from state
  public Map<String, String> getUserOrders(ToolContext toolContext) {
      String userId = (String) toolContext.state().get("temp:current_user_id");
      if (userId == null || userId.isEmpty()) {
          return Map.of("error", "User ID not found in state");
      }
      System.out.println("Fetching orders for user id: " + userId);
      // ... logic to fetch orders using userId ...
      return Map.of("orders", "order123");
  }
  ```

- **Updating User Preferences:**

  ```python
  # Example: Tool or Callback identifies a preference
  from google.adk.tools import ToolContext # Or Context

  def set_user_preference(tool_context: ToolContext, preference: str, value: str) -> dict:
      # Use 'user:' prefix for user-level state (if using a persistent SessionService)
      state_key = f"user:{preference}"
      tool_context.state[state_key] = value
      print(f"Set user preference '{preference}' to '{value}'")
      return {"status": "Preference updated"}
  ```

  ```typescript
  // Pseudocode: Tool or Callback identifies a preference
  import { Context } from '@google/adk';

  function setUserPreference(context: Context, preference: string, value: string): Record<string, string> {
    // Use 'user:' prefix for user-level state (if using a persistent SessionService)
    const stateKey = `user:${preference}`;
    context.state.set(stateKey, value);
    console.log(`Set user preference '${preference}' to '${value}'`);
    return { status: 'Preference updated' };
  }
  ```

  ```go
  import "google.golang.org/adk/tool"

  // Pseudocode: Tool or Callback identifies a preference
  type setUserPreferenceArgs struct {
      Preference string `json:"preference" jsonschema:"The name of the preference to set."`
      Value      string `json:"value" jsonschema:"The value to set for the preference."`
  }

  type setUserPreferenceResult struct {
      Status string `json:"status"`
  }

  func setUserPreference(tc tool.Context, args setUserPreferenceArgs) (setUserPreferenceResult, error) {
      // Use 'user:' prefix for user-level state (if using a persistent SessionService)
      stateKey := fmt.Sprintf("user:%s", args.Preference)
      if err := tc.State().Set(stateKey, args.Value); err != nil {
          return setUserPreferenceResult{}, fmt.Errorf("failed to set preference in state: %w", err)
      }
      fmt.Printf("Set user preference '%s' to '%s'\n", args.Preference, args.Value)
      return setUserPreferenceResult{Status: "Preference updated"}, nil
  }
  ```

  ```java
  // Example: Tool or Callback identifies a preference
  import com.google.adk.tools.ToolContext; // Or CallbackContext

  public Map<String, String> setUserPreference(ToolContext toolContext, String preference, String value) {
      // Use 'user:' prefix for user-level state (if using a persistent SessionService)
      String stateKey = "user:" + preference;
      toolContext.state().put(stateKey, value);
      System.out.println("Set user preference '" + preference + "' to '" + value + "'");
      return Map.of("status", "Preference updated");
  }
  ```

- **State Prefixes:** While basic state is session-specific, prefixes like `app:` and `user:` can be used with persistent `SessionService` implementations (like `DatabaseSessionService` or `VertexAiSessionService`) to indicate broader scope (app-wide or user-wide across sessions). `temp:` can denote data only relevant within the current invocation.

### Working with Artifacts

Use artifacts to handle files or large data blobs associated with the session. Common use case: processing uploaded documents.

- **Document Summarizer Example Flow:**

  1. **Ingest Reference (e.g., in a Setup Tool or Callback):** Save the *path or URI* of the document, not the entire content, as an artifact.

     ```python
     # Example: In a callback or initial tool
     from google.adk.agents.context import Context # Or ToolContext
     from google.genai import types

     def save_document_reference(context: Context, file_path: str) -> None:
         # Assume file_path is something like "gs://my-bucket/docs/report.pdf" or "/local/path/to/report.pdf"
         try:
             # Create a Part containing the path/URI text
             artifact_part = types.Part.from_text(file_path)
             version = context.save_artifact("document_to_summarize.txt", artifact_part)
             print(f"Saved document reference '{file_path}' as artifact version {version}")
             # Store the filename in state if needed by other tools
             context.state["temp:doc_artifact_name"] = "document_to_summarize.txt"
         except ValueError as e:
             print(f"Error saving artifact: {e}") # E.g., Artifact service not configured
         except Exception as e:
             print(f"Unexpected error saving artifact reference: {e}")

     # Example usage:
     # save_document_reference(context, "gs://my-bucket/docs/report.pdf")
     ```

     ```typescript
     // Pseudocode: In a callback or initial tool
     import { Context } from '@google/adk';
     import type { Part } from '@google/genai';

     async function saveDocumentReference(context: Context, filePath: string) {
       // Assume filePath is something like "gs://my-bucket/docs/report.pdf" or "/local/path/to/report.pdf"
       try {
         // Create a Part containing the path/URI text
         const artifactPart: Part = { text: filePath };
         const version = await context.saveArtifact('document_to_summarize.txt', artifactPart);
         console.log(`Saved document reference '${filePath}' as artifact version ${version}`);
         // Store the filename in state if needed by other tools
         context.state.set('temp:doc_artifact_name', 'document_to_summarize.txt');
       } catch (e) {
         console.error(`Unexpected error saving artifact reference: ${e}`);
       }
     }

     // Example usage:
     // saveDocumentReference(context, "gs://my-bucket/docs/report.pdf");
     ```

     ```go
     import (
         "google.golang.org/adk/tool"
         "google.golang.org/genai"
     )

     // Adapt the saveDocumentReference callback into a tool for this example.
     type saveDocRefArgs struct {
         FilePath string `json:"file_path" jsonschema:"The path to the file to save."`
     }

     type saveDocRefResult struct {
         Status string `json:"status"`
     }

     func saveDocRef(tc tool.Context, args saveDocRefArgs) (saveDocRefResult, error) {
         artifactPart := genai.NewPartFromText(args.FilePath)
         _, err := tc.Artifacts().Save(tc, "document_to_summarize.txt", artifactPart)
         if err != nil {
             return saveDocRefResult{}, err
         }
         fmt.Printf("Saved document reference '%s' as artifact\n", args.FilePath)
         if err := tc.State().Set("temp:doc_artifact_name", "document_to_summarize.txt"); err != nil {
             return saveDocRefResult{}, fmt.Errorf("failed to set artifact name in state")
         }
         return saveDocRefResult{"Reference saved"}, nil
     }
     ```

     ```java
     // Example: In a callback or initial tool
     import com.google.adk.agents.CallbackContext;
     import com.google.genai.types.Content;
     import com.google.genai.types.Part;
     import java.util.Optional;

     public void saveDocumentReference(CallbackContext context, String filePath) {
         // Assume file_path is something like "gs://my-bucket/docs/report.pdf" or "/local/path/to/report.pdf"
         try {
             // Create a Part containing the path/URI text
             Part artifactPart = Part.fromText(filePath);
             Optional<Integer> version = context.saveArtifact("document_to_summarize.txt", artifactPart);
             System.out.println("Saved document reference" + filePath + " as artifact version " + version.orElse(-1));
             // Store the filename in state if needed by other tools
             context.state().put("temp:doc_artifact_name", "document_to_summarize.txt");
         } catch (Exception e) {
             System.out.println("Unexpected error saving artifact reference: " + e);
         }
     }

     // Example usage:
     // saveDocumentReference(context, "gs://my-bucket/docs/report.pdf")
     ```

  1. **Summarizer Tool:** Load the artifact to get the path/URI, read the actual document content using appropriate libraries, summarize, and return the result.

     ```python
     # Example: In the Summarizer tool function
     from google.adk.tools import ToolContext
     from google.genai import types
     # Assume libraries like google.cloud.storage or built-in open are available
     # Assume a 'summarize_text' function exists
     # from my_summarizer_lib import summarize_text

     def summarize_document_tool(tool_context: ToolContext) -> dict:
         artifact_name = tool_context.state.get("temp:doc_artifact_name")
         if not artifact_name:
             return {"error": "Document artifact name not found in state."}

         try:
             # 1. Load the artifact part containing the path/URI
             artifact_part = tool_context.load_artifact(artifact_name)
             if not artifact_part or not artifact_part.text:
                 return {"error": f"Could not load artifact or artifact has no text path: {artifact_name}"}

             file_path = artifact_part.text
             print(f"Loaded document reference: {file_path}")

             # 2. Read the actual document content (outside ADK context)
             document_content = ""
             if file_path.startswith("gs://"):
                 # Example: Use GCS client library to download/read
                 pass # Replace with actual GCS reading logic
             elif file_path.startswith("/"):
                  # Example: Use local file system
                  with open(file_path, 'r', encoding='utf-8') as f:
                      document_content = f.read()
             else:
                 return {"error": f"Unsupported file path scheme: {file_path}"}

             # 3. Summarize the content
             if not document_content:
                  return {"error": "Failed to read document content."}

             # summary = summarize_text(document_content) # Call your summarization logic
             summary = f"Summary of content from {file_path}" # Placeholder

             return {"summary": summary}

         except ValueError as e:
              return {"error": f"Artifact service error: {e}"}
         except FileNotFoundError:
              return {"error": f"Local file not found: {file_path}"}
     ```

     ```typescript
     // Pseudocode: In the Summarizer tool function
     import { Context } from '@google/adk';

     async function summarizeDocumentTool(context: Context): Promise<Record<string, string>> {
       const artifactName = context.state.get('temp:doc_artifact_name') as string;
       if (!artifactName) {
         return { error: 'Document artifact name not found in state.' };
       }

       try {
         // 1. Load the artifact part containing the path/URI
         const artifactPart = await context.loadArtifact(artifactName);
         if (!artifactPart?.text) {
           return { error: `Could not load artifact or artifact has no text path: ${artifactName}` };
         }

         const filePath = artifactPart.text;
         console.log(`Loaded document reference: ${filePath}`);

         // 2. Read the actual document content (outside ADK context)
         let documentContent = '';
         if (filePath.startsWith('gs://')) {
           // Example: Use GCS client library to download/read
           // const storage = new Storage();
           // const bucket = storage.bucket('my-bucket');
           // const file = bucket.file(filePath.replace('gs://my-bucket/', ''));
           // const [contents] = await file.download();
           // documentContent = contents.toString();
         } else if (filePath.startsWith('/')) {
           // Example: Use local file system
           // import { readFile } from 'fs/promises';
           // documentContent = await readFile(filePath, 'utf8');
         } else {
           return { error: `Unsupported file path scheme: ${filePath}` };
         }

         // 3. Summarize the content
         if (!documentContent) {
            return { error: 'Failed to read document content.' };
         }

         // const summary = summarizeText(documentContent); // Call your summarization logic
         const summary = `Summary of content from ${filePath}`; // Placeholder

         return { summary };

       } catch (e) {
          return { error: `Error processing artifact: ${e}` };
       }
     }
     ```

     ```go
     import "google.golang.org/adk/tool"

     // Pseudocode: In the Summarizer tool function
     type summarizeDocumentArgs struct{}

     type summarizeDocumentResult struct {
         Summary string `json:"summary"`
     }

     func summarizeDocumentTool(tc tool.Context, input summarizeDocumentArgs) (summarizeDocumentResult, error) {
         artifactName, err := tc.State().Get("temp:doc_artifact_name")
         if err != nil {
             return summarizeDocumentResult{}, fmt.Errorf("No document artifact name found in state")
         }

         // 1. Load the artifact part containing the path/URI
         artifactPart, err := tc.Artifacts().Load(tc, artifactName.(string))
         if err != nil {
             return summarizeDocumentResult{}, err
         }

         if artifactPart.Part.Text == "" {
             return summarizeDocumentResult{}, fmt.Errorf("Could not load artifact or artifact has no text path.")
         }
         filePath := artifactPart.Part.Text
         fmt.Printf("Loaded document reference: %s\n", filePath)

         // 2. Read the actual document content (outside ADK context)
         // In a real implementation, you would use a GCS client or local file reader.
         documentContent := "This is the fake content of the document at " + filePath
         _ = documentContent // Avoid unused variable error.

         // 3. Summarize the content
         summary := "Summary of content from " + filePath // Placeholder

         return summarizeDocumentResult{Summary: summary}, nil
     }
     ```

     ```java
     // Example: In the Summarizer tool function
     import com.google.adk.tools.ToolContext;
     import com.google.genai.types.Content;
     import com.google.genai.types.Part;
     import java.util.Map;
     import java.util.Optional;
     import java.io.FileNotFoundException;

     public Map<String, String> summarizeDocumentTool(ToolContext toolContext) {
         String artifactName = (String) toolContext.state().get("temp:doc_artifact_name");
         if (artifactName == null || artifactName.isEmpty()) {
             return Map.of("error", "Document artifact name not found in state.");
         }
         try {
             // 1. Load the artifact part containing the path/URI
             Optional<Part> artifactPart = toolContext.loadArtifact(artifactName);
             if (!artifactPart.isPresent() || !artifactPart.get().text().isPresent() || artifactPart.get().text().get().isEmpty()) {
                 return Map.of("error", "Could not load artifact or artifact has no text path: " + artifactName);
             }
             String filePath = artifactPart.get().text().get();
             System.out.println("Loaded document reference: " + filePath);

             // 2. Read the actual document content (outside ADK context)
             String documentContent = "";
             if (filePath.startsWith("gs://")) {
                 // Example: Use GCS client library to download/read into documentContent
                 // Replace with actual GCS reading logic
             } else if (filePath.startsWith("/")) {
                 // Example: Use local file system to download/read into documentContent
             } else {
                 return Map.of("error", "Unsupported file path scheme: " + filePath);
             }

             // 3. Summarize the content
             if (documentContent.isEmpty()) {
                 return Map.of("error", "Failed to read document content.");
             }

             // summary = summarizeText(documentContent) // Call your summarization logic
             String summary = "Summary of content from " + filePath; // Placeholder

             return Map.of("summary", summary);
         } catch (IllegalArgumentException e) {
             return Map.of("error", "Artifact service error " + e);
         } catch (Exception e) {
             return Map.of("error", "Error reading document " + e);
         }
     }
     ```

- **Listing Artifacts:** Discover what files are available.

  ```python
  # Example: In a tool function
  from google.adk.tools import ToolContext

  def check_available_docs(tool_context: ToolContext) -> dict:
      try:
          artifact_keys = tool_context.list_artifacts()
          print(f"Available artifacts: {artifact_keys}")
          return {"available_docs": artifact_keys}
      except ValueError as e:
          return {"error": f"Artifact service error: {e}"}
  ```

  ```typescript
  // Pseudocode: In a tool function
  import { Context } from '@google/adk';

  async function checkAvailableDocs(context: Context): Promise<Record<string, string[] | string>> {
    try {
      const artifactKeys = await context.listArtifacts();
      console.log(`Available artifacts: ${artifactKeys}`);
      return { available_docs: artifactKeys };
    } catch (e) {
      return { error: `Artifact service error: ${e}` };
    }
  }
  ```

  ```go
  import "google.golang.org/adk/tool"

  // Pseudocode: In a tool function
  type checkAvailableDocsArgs struct{}

  type checkAvailableDocsResult struct {
      AvailableDocs []string `json:"available_docs"`
  }

  func checkAvailableDocs(tc tool.Context, args checkAvailableDocsArgs) (checkAvailableDocsResult, error) {
      artifactKeys, err := tc.Artifacts().List(tc)
      if err != nil {
          return checkAvailableDocsResult{}, err
      }
      fmt.Printf("Available artifacts: %v\n", artifactKeys)
      return checkAvailableDocsResult{AvailableDocs: artifactKeys.FileNames}, nil
  }
  ```

  ```java
  // Example: In a tool function
  import com.google.adk.tools.ToolContext;
  import io.reactivex.rxjava3.core.Single;
  import java.util.List;
  import java.util.Map;

  public Map<String, Object> checkAvailableDocs(ToolContext toolContext) {
      try {
          Single<List<String>> artifactKeys = toolContext.listArtifacts();
          System.out.println("Available artifacts: " + artifactKeys.blockingGet().toString());
          return Map.of("availableDocs", artifactKeys.blockingGet());
      } catch (IllegalArgumentException e) {
          return Map.of("error", "Artifact service error: " + e);
      }
  }
  ```

### Handling Tool Authentication

Supported in ADKPython v0.1.0TypeScript v0.2.0Java v0.2.0

Securely manage API keys or other credentials needed by tools.

```python
# Example: Tool requiring auth
from google.adk.tools import ToolContext
from google.adk.auth import AuthConfig # Assume appropriate AuthConfig is defined

# Define your required auth configuration (e.g., OAuth, API Key)
MY_API_AUTH_CONFIG = AuthConfig(...)
AUTH_STATE_KEY = "user:my_api_credential" # Key to store retrieved credential

def call_secure_api(tool_context: ToolContext, request_data: str) -> dict:
    # 1. Check if credential already exists in state
    credential = tool_context.state.get(AUTH_STATE_KEY)

    if not credential:
        # 2. If not, request it
        print("Credential not found, requesting...")
        try:
            tool_context.request_credential(MY_API_AUTH_CONFIG)
            # The framework handles yielding the event. The tool execution stops here for this turn.
            return {"status": "Authentication required. Please provide credentials."}
        except ValueError as e:
            return {"error": f"Auth error: {e}"} # e.g., function_call_id missing
        except Exception as e:
            return {"error": f"Failed to request credential: {e}"}

    # 3. If credential exists (might be from a previous turn after request)
    #    or if this is a subsequent call after auth flow completed externally
    try:
        # Optionally, re-validate/retrieve if needed, or use directly
        # This might retrieve the credential if the external flow just completed
        auth_credential_obj = tool_context.get_auth_response(MY_API_AUTH_CONFIG)
        api_key = auth_credential_obj.api_key # Or access_token, etc.

        # Store it back in state for future calls within the session
        tool_context.state[AUTH_STATE_KEY] = auth_credential_obj.model_dump() # Persist retrieved credential

        print(f"Using retrieved credential to call API with data: {request_data}")
        # ... Make the actual API call using api_key ...
        api_result = f"API result for {request_data}"

        return {"result": api_result}
    except Exception as e:
        # Handle errors retrieving/using the credential
        print(f"Error using credential: {e}")
        # Maybe clear the state key if credential is invalid?
        # tool_context.state[AUTH_STATE_KEY] = None
        return {"error": "Failed to use credential"}
```

```typescript
// Pseudocode: Tool requiring auth
import { Context } from '@google/adk'; // AuthConfig from ADK or custom

// Define a local AuthConfig interface as it's not publicly exported by ADK
interface AuthConfig {
  credentialKey: string;
  authScheme: { type: string }; // Minimal representation for the example
  // Add other properties if they become relevant for the example
}

// Define your required auth configuration (e.g., OAuth, API Key)
const MY_API_AUTH_CONFIG: AuthConfig = {
  credentialKey: 'my-api-key', // Example key
  authScheme: { type: 'api-key' }, // Example scheme type
};
const AUTH_STATE_KEY = 'user:my_api_credential'; // Key to store retrieved credential

async function callSecureApi(context: Context, requestData: string): Promise<Record<string, string>> {
  // 1. Check if credential already exists in state
  const credential = context.state.get(AUTH_STATE_KEY);

  if (!credential) {
    // 2. If not, request it
    console.log('Credential not found, requesting...');
    try {
      context.requestCredential(MY_API_AUTH_CONFIG);
      // The framework handles yielding the event. The tool execution stops here for this turn.
      return { status: 'Authentication required. Please provide credentials.' };
    } catch (e) {
      return { error: `Auth or credential request error: ${e}` };
    }
  }

  // 3. If credential exists (might be from a previous turn after request)
  //    or if this is a subsequent call after auth flow completed externally
  try {
    // Optionally, re-validate/retrieve if needed, or use directly
    // This might retrieve the credential if the external flow just completed
    const authCredentialObj = context.getAuthResponse(MY_API_AUTH_CONFIG);
    const apiKey = authCredentialObj?.apiKey; // Or accessToken, etc.

    // Store it back in state for future calls within the session
    // Note: In strict TS, might need to cast or serialize authCredentialObj
    context.state.set(AUTH_STATE_KEY, JSON.stringify(authCredentialObj));

    console.log(`Using retrieved credential to call API with data: ${requestData}`);
    // ... Make the actual API call using apiKey ...
    const apiResult = `API result for ${requestData}`;

    return { result: apiResult };
  } catch (e) {
    // Handle errors retrieving/using the credential
    console.error(`Error using credential: ${e}`);
    // Maybe clear the state key if credential is invalid?
    // toolContext.state.set(AUTH_STATE_KEY, null);
    return { error: 'Failed to use credential' };
  }
}
```

```java
// Example: Tool requiring auth
import com.google.adk.tools.ToolContext;
import java.util.Map;

// Note: AuthConfig, requestCredential, and getAuthResponse are not yet 
// fully implemented in the Java ADK public API. 
// This example relies on external auth population into the session state.

public class SecureApiTool {
  private static final String AUTH_STATE_KEY = "user:my_api_credential";

  public Map<String, String> callSecureApi(ToolContext context, String requestData) {
    // 1. Check if credential already exists in state
    Object credential = context.state().get(AUTH_STATE_KEY);

    if (credential == null) {
      // 2. If not, request it
      System.out.println("Credential not found, requesting...");
      try {
        // context.requestCredential(MY_API_AUTH_CONFIG); // Not yet implemented in Java ADK
        // The framework handles yielding the event. The tool execution stops here for this turn.
        return Map.of("status", "Authentication required. Please provide credentials.");
      } catch (Exception e) {
        return Map.of("error", "Auth or credential request error: " + e.getMessage());
      }
    }

    // 3. If credential exists (might be from a previous turn after request)
    //    or if this is a subsequent call after auth flow completed externally
    try {
      // Optionally, re-validate/retrieve if needed, or use directly
      // String apiKey = context.getAuthResponse(MY_API_AUTH_CONFIG).getApiKey();
      String apiKey = credential.toString(); // Simplified for example

      // Store it back in state for future calls within the session
      context.state().put(AUTH_STATE_KEY, apiKey);

      System.out.println("Using retrieved credential to call API with data: " + requestData);
      // ... Make the actual API call using apiKey ...
      String apiResult = "API result for " + requestData;

      return Map.of("result", apiResult);
    } catch (Exception e) {
      // Handle errors retrieving/using the credential
      System.err.println("Error using credential: " + e.getMessage());
      return Map.of("error", "Failed to use credential");
    }
  }
}
```

*Remember: `request_credential` pauses the tool and signals the need for authentication. The user/system provides credentials, and on a subsequent call, `get_auth_response` (or checking state again) allows the tool to proceed.* The `tool_context.function_call_id` is used implicitly by the framework to link the request and response.

### Leveraging Memory

Supported in ADKPython v0.1.0TypeScript v0.2.0Java v0.2.0

Access relevant information from the past or external sources.

```python
# Example: Tool using memory search
from google.adk.tools import ToolContext

def find_related_info(tool_context: ToolContext, topic: str) -> dict:
    try:
        search_results = tool_context.search_memory(f"Information about {topic}")
        if search_results.results:
            print(f"Found {len(search_results.results)} memory results for '{topic}'")
            # Process search_results.results (which are SearchMemoryResponseEntry)
            top_result_text = search_results.results[0].text
            return {"memory_snippet": top_result_text}
        else:
            return {"message": "No relevant memories found."}
    except ValueError as e:
        return {"error": f"Memory service error: {e}"} # e.g., Service not configured
    except Exception as e:
        return {"error": f"Unexpected error searching memory: {e}"}
```

```typescript
// Pseudocode: Tool using memory search
import { Context } from '@google/adk';

async function findRelatedInfo(context: Context, topic: string): Promise<Record<string, string>> {
  try {
    const searchResults = await context.searchMemory(`Information about ${topic}`);
    if (searchResults.results?.length) {
      console.log(`Found ${searchResults.results.length} memory results for '${topic}'`);
      // Process searchResults.results
      const topResultText = searchResults.results[0].text;
      return { memory_snippet: topResultText };
    } else {
      return { message: 'No relevant memories found.' };
    }
  } catch (e) {
     return { error: `Memory service error: ${e}` }; // e.g., Service not configured
  }
}
```

```java
// Example: Tool using memory search
import com.google.adk.tools.ToolContext;
import com.google.adk.memory.SearchMemoryResponse;
import io.reactivex.rxjava3.core.Single;
import java.util.Map;

public class MemorySearchTool {
  public Single<Map<String, String>> findRelatedInfo(ToolContext context, String topic) {
    return context.searchMemory("Information about " + topic)
        .map(searchResults -> {
          if (searchResults != null && searchResults.results() != null && !searchResults.results().isEmpty()) {
            System.out.println("Found " + searchResults.results().size() + " memory results for '" + topic + "'");
            // Process searchResults.results
            String topResultText = searchResults.results().get(0).text();
            return Map.of("memory_snippet", topResultText);
          } else {
            return Map.of("message", "No relevant memories found.");
          }
        })
        .onErrorReturnItem(Map.of("error", "Memory service error"));
  }
}
```

### Advanced: Direct `InvocationContext` Usage

Supported in ADKPython v0.1.0TypeScript v0.2.0Java v0.2.0

While most interactions happen via `CallbackContext` or `ToolContext`, sometimes the agent's core logic (`_run_async_impl`/`_run_live_impl`) needs direct access.

```python
# Example: Inside agent's _run_async_impl
from google.adk.agents import BaseAgent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events import Event
from typing import AsyncGenerator

class MyControllingAgent(BaseAgent):
    async def _run_async_impl(self, ctx: InvocationContext) -> AsyncGenerator[Event, None]:
        # Example: Check if a specific service is available
        if not ctx.memory_service:
            print("Memory service is not available for this invocation.")
            # Potentially change agent behavior

        # Example: Early termination based on some condition
        if ctx.session.state.get("critical_error_flag"):
            print("Critical error detected, ending invocation.")
            ctx.end_invocation = True # Signal framework to stop processing
            yield Event(author=self.name, invocation_id=ctx.invocation_id, content="Stopping due to critical error.")
            return # Stop this agent's execution

        # ... Normal agent processing ...
        yield # ... event ...
```

```typescript
// Pseudocode: Inside agent's runAsyncImpl
import { BaseAgent, InvocationContext } from '@google/adk';
import type { Event } from '@google/adk';

class MyControllingAgent extends BaseAgent {
  async *runAsyncImpl(ctx: InvocationContext): AsyncGenerator<Event, void, undefined> {
    // Example: Check if a specific service is available
    if (!ctx.memoryService) {
      console.log('Memory service is not available for this invocation.');
      // Potentially change agent behavior
    }

    // Example: Early termination based on some condition
    // Direct access to state via ctx.session.state or through ctx.session.state property if wrapped
    if ((ctx.session.state as { 'critical_error_flag': boolean })['critical_error_flag']) {
      console.log('Critical error detected, ending invocation.');
      ctx.endInvocation = true; // Signal framework to stop processing
      yield {
        author: this.name,
        invocationId: ctx.invocationId,
        content: { parts: [{ text: 'Stopping due to critical error.' }] }
      } as Event;
      return; // Stop this agent's execution
    }

    // ... Normal agent processing ...
    yield; // ... event ...
  }
}
```

```java
// Example: Inside agent's runAsyncImpl
import com.google.adk.agents.BaseAgent;
import com.google.adk.agents.InvocationContext;
import com.google.adk.events.Event;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import io.reactivex.rxjava3.core.Flowable;
import java.util.List;

public class MyControllingAgent extends BaseAgent {

  @Override
  protected Flowable<Event> runAsyncImpl(InvocationContext ctx) {
    // Example: Check if a specific service is available
    if (ctx.memoryService() == null) {
      System.out.println("Memory service is not available for this invocation.");
      // Potentially change agent behavior
    }

    // Example: Early termination based on some condition
    Boolean criticalError = (Boolean) ctx.session().state().getOrDefault("critical_error_flag", false);
    if (criticalError != null && criticalError) {
      System.out.println("Critical error detected, ending invocation.");
      ctx.setEndInvocation(true); // Signal framework to stop processing

      Event errorEvent = Event.builder()
          .author(name())
          .invocationId(ctx.invocationId())
          .content(Content.builder().parts(List.of(Part.builder().text("Stopping due to critical error.").build())).build())
          .build();

      return Flowable.just(errorEvent); // Stop this agent's execution
    }

    // ... Normal agent processing ...
    // return Flowable.just(normalEvent);
    return Flowable.empty();
  }
}
```

Setting `ctx.end_invocation = True` is a way to gracefully stop the entire request-response cycle from within the agent or its callbacks/tools (via their respective context objects which also have access to modify the underlying `InvocationContext`'s flag).

## Key Takeaways & Best Practices

- **Use the Right Context:** Always use the most specific context object provided (`ToolContext` in tools/tool-callbacks, `CallbackContext` in agent/model-callbacks, `ReadonlyContext` where applicable). Use the full `InvocationContext` (`ctx`) directly in `_run_async_impl` / `_run_live_impl` only when necessary.
- **State for Data Flow:** `context.state` is the primary way to share data, remember preferences, and manage conversational memory *within* an invocation. Use prefixes (`app:`, `user:`, `temp:`) thoughtfully when using persistent storage.
- **Artifacts for Files:** Use `context.save_artifact` and `context.load_artifact` for managing file references (like paths or URIs) or larger data blobs. Store references, load content on demand.
- **Tracked Changes:** Modifications to state or artifacts made via context methods are automatically linked to the current step's `EventActions` and handled by the `SessionService`.
- **Start Simple:** Focus on `state` and basic artifact usage first. Explore authentication, memory, and advanced `InvocationContext` fields (like those for live streaming) as your needs become more complex.

By understanding and effectively using these context objects, you can build more sophisticated, stateful, and capable agents with ADK.

# Context caching with Gemini

Supported in ADKPython v1.15.0Java v0.1.0

When working with agents to complete tasks, you may want to reuse extended instructions or large sets of data across multiple agent requests to a generative AI model. Resending this data for each agent request is slow, inefficient, and can be expensive. Using context caching features in generative AI models can significantly speed up responses and lower the number of tokens sent to the model for each request.

The ADK Context Caching feature allows you to cache request data with generative AI models that support it, including Gemini 2.0 and higher models. This document explains how to configure and use this feature.

## Configure context caching

You configure the context caching feature at the ADK `App` object level, which wraps your agent. Use the `ContextCacheConfig` class to configure these settings, as shown in the following code sample:

```python
from google.adk import Agent
from google.adk.apps.app import App
from google.adk.agents.context_cache_config import ContextCacheConfig

root_agent = Agent(
  # configure an agent using Gemini 2.0 or higher
)

# Create the app with context caching configuration
app = App(
    name='my-caching-agent-app',
    root_agent=root_agent,
    context_cache_config=ContextCacheConfig(
        min_tokens=2048,    # Minimum tokens to trigger caching
        ttl_seconds=600,    # Store for up to 10 minutes
        cache_intervals=5,  # Refresh after 5 uses
    ),
)
```

```java
import com.google.adk.agents.BaseAgent;
import com.google.adk.agents.ContextCacheConfig;
import com.google.adk.apps.App;
import java.time.Duration;

// Create the app with context caching configuration
App app = App.builder()
             .name("my-caching-agent-app")
             .rootAgent(rootAgent)
             .contextCacheConfig(
                 new ContextCacheConfig(
                     5, /* cache_intervals (max invocations) */
                     Duration.ofMinutes(10), /* ttl */
                     2048 /* min_tokens */))
             .build();
```

## Configuration settings

The `ContextCacheConfig` class has the following settings that control how caching works for your agent. When you configure these settings, they apply to all agents within your app.

- **`min_tokens`** (int): The minimum number of tokens required in a request to enable caching. This setting allows you to avoid the overhead of caching for very small requests where the performance benefit would be negligible. Defaults to `0`.
- **`ttl_seconds`** (int): The time-to-live (TTL) for the cache in seconds. This setting determines how long the cached content is stored before it is refreshed. Defaults to `1800` (30 minutes).
- **`cache_intervals`** (int): The maximum number of times the same cached content can be used before it expires. This setting allows you to control how frequently the cache is updated, even if the TTL has not expired. Defaults to `10`.

## Next steps

For a full implementation of how to use and test the context caching feature, see the following sample:

- [`cache_analysis`](https://github.com/google/adk-python/tree/main/contributing/samples/cache_analysis): A code sample that demonstrates how to analyze the performance of context caching.

If your use case requires that you provide instructions that are used throughout a session, consider using the `static_instruction` parameter for an agent, which allows you to amend the system instructions for a generative model. For more details, see this sample code:

- [`static_instruction`](https://github.com/google/adk-python/tree/main/contributing/samples/static_instruction): An implementation of a digital pet agent using static instructions.

# Compress agent context for performance

Supported in ADKPython v1.16.0Java v0.2.0TypeScript v0.6.0

As an ADK agent runs it collects *context* information, including user instructions, retrieved data, tool responses, and generated content. As the size of this context data grows, agent processing times typically also increase. More and more data is sent to the generative AI model used by the agent, increasing processing time and slowing down responses. The ADK Context Compaction feature is designed to reduce the size of context as an agent is running by summarizing older parts of the agent workflow event history.

The Context Compaction feature uses a *sliding window* approach for collecting and summarizing agent workflow event data within a [Session](/sessions/session/). When you configure this feature in your agent, it summarizes data from older events once it reaches a threshold of a specific number of workflow events, or invocations, with the current Session.

## Configure context compaction

Add context compaction to your agent workflow by adding an Events Compaction Configuration setting to the App object (Python/Java) or by configuring `contextCompactors` on the `LlmAgent` (TypeScript). As part of the configuration, you must specify a compaction interval and overlap size (Python/Java) or a token threshold and event retention size (TypeScript), as shown in the following sample code:

```python
from google.adk.apps.app import App
from google.adk.apps.app import EventsCompactionConfig

app = App(
    name='my-agent',
    root_agent=root_agent,
    events_compaction_config=EventsCompactionConfig(
        compaction_interval=3,  # Trigger compaction every 3 new invocations.
        overlap_size=1          # Include last invocation from the previous window.
    ),
)
```

```java
import com.google.adk.apps.App;
import com.google.adk.summarizer.EventsCompactionConfig;

App app = App.builder()
    .name("my-agent")
    .rootAgent(rootAgent)
    .eventsCompactionConfig(EventsCompactionConfig.builder()
        .compactionInterval(3)  // Trigger compaction every 3 new invocations.
        .overlapSize(1)         // Include last invocation from the previous window.
        .build())
    .build();
```

```typescript
import {Gemini, LlmAgent, LlmSummarizer, TokenBasedContextCompactor} from '@google/adk';

const agent = new LlmAgent({
  name: 'my-agent',
  model: 'gemini-flash-latest',
  contextCompactors: [
    new TokenBasedContextCompactor({
      tokenThreshold: 1000, // Trigger compaction when session exceeds 1000 tokens.
      eventRetentionSize: 1, // Keep at least 1 raw event (overlap).
      summarizer: new LlmSummarizer({
        llm: new Gemini({model: 'gemini-flash-latest'}),
      }),
    }),
  ],
});
```

Once configured, the ADK `Runner` handles the compaction process in the background each time the session reaches the interval.

## Example of context compaction

If you set `compaction_interval` to 3 and `overlap_size` to 1, the event data is compressed upon completion of events 3, 6, 9, and so on. The overlap setting increases size of the second summary compression, and each summary afterwards, as shown in Figure 1.

**Figure 1.** Illustration of event compaction configuration with an interval of 3 and overlap of 1.

With this example configuration, the context compression tasks happen as follows:

1. **Event 3 completes**: All 3 events are compressed into a summary
1. **Event 6 completes**: Events 3 to 6 are compressed, including the overlap of 1 prior event
1. **Event 9 completes**: Events 6 to 9 are compressed, including the overlap of 1 prior event

## Configuration settings

The configuration settings for this feature control how frequently event data is compressed and how much data is retained as the agent workflow runs. Optionally, you can configure a compactor object

- **`compaction_interval`**: Set the number of completed events that triggers compaction of the prior event data.
- **`overlap_size`**: Set how many of the previously compacted events are included in a newly compacted context set.
- **`summarizer`**: (Optional) Define a summarizer object including a specific AI model to use for summarization. For more information, see [Define a Summarizer](#define-summarizer).

### Define a Summarizer

You can customize the process of context compression by defining a summarizer. The `LlmEventSummarizer` (Python/Java) or `LlmSummarizer` (TypeScript) class allows you to specify a particular model for summarization. The following code example demonstrates how to define and configure a custom summarizer:

```python
from google.adk.apps.app import App, EventsCompactionConfig
from google.adk.apps.llm_event_summarizer import LlmEventSummarizer
from google.adk.models import Gemini

# Define the AI model to be used for summarization:
summarization_llm = Gemini(model="gemini-flash-latest")

# Create the summarizer with the custom model:
my_summarizer = LlmEventSummarizer(llm=summarization_llm)

# Configure the App with the custom summarizer and compaction settings:
app = App(
    name='my-agent',
    root_agent=root_agent,
    events_compaction_config=EventsCompactionConfig(
        compaction_interval=3,
        overlap_size=1,
        summarizer=my_summarizer,
    ),
)
```

```java
import com.google.adk.apps.App;
import com.google.adk.models.Gemini;
import com.google.adk.summarizer.EventsCompactionConfig;
import com.google.adk.summarizer.LlmEventSummarizer;

// Define the AI model to be used for summarization:
Gemini summarizationLlm = Gemini.builder()
    .model("gemini-flash-latest")
    .build();

// Create the summarizer with the custom model:
LlmEventSummarizer mySummarizer = new LlmEventSummarizer(summarizationLlm);

// Configure the App with the custom summarizer and compaction settings:
App app = App.builder()
    .name("my-agent")
    .rootAgent(rootAgent)
    .eventsCompactionConfig(EventsCompactionConfig.builder()
        .compactionInterval(3)
        .overlapSize(1)
        .summarizer(mySummarizer)
        .build())
    .build();
```

```typescript
import {Gemini, LlmAgent, LlmSummarizer, TokenBasedContextCompactor} from '@google/adk';

// Define the AI model to be used for summarization:
const summarizationLlm = new Gemini({model: 'gemini-flash-latest'});

// Create the summarizer with the custom model:
const mySummarizer = new LlmSummarizer({llm: summarizationLlm});

// Configure the agent with the custom summarizer and compaction settings:
const agent = new LlmAgent({
  name: 'my-agent',
  model: 'gemini-flash-latest',
  contextCompactors: [
    new TokenBasedContextCompactor({
      tokenThreshold: 1000,
      eventRetentionSize: 1,
      summarizer: mySummarizer,
    }),
  ],
});
```

You can further refine the compactor by modifying its summarizer. In Python and Java, customize the `prompt_template` on `LlmEventSummarizer`. In TypeScript, customize the `prompt` on `LlmSummarizer`. For more details, see the [`LlmEventSummarizer` code](https://github.com/google/adk-python/blob/main/src/google/adk/apps/llm_event_summarizer.py#L60) or [`LlmSummarizer` code](https://github.com/google/adk-js/blob/main/core/src/context/summarizers/llm_summarizer.ts).

# Introduction to Conversational Context: Session, State, and Memory

Supported in ADKPythonTypeScriptGoJava

Meaningful, multi-turn conversations require agents to understand context. Just like humans, they need to recall the conversation history: what's been said and done to maintain continuity and avoid repetition. The Agent Development Kit (ADK) provides structured ways to manage this context through `Session`, `State`, and `Memory`.

## Core Concepts

Think of different instances of your conversations with the agent as distinct **conversation threads**, potentially drawing upon **long-term knowledge**.

1. **`Session`**: The Current Conversation Thread

   - Represents a *single, ongoing interaction* between a user and your agent system.
   - Contains the chronological sequence of messages and actions taken by the agent (referred to `Events`) during *that specific interaction*.
   - A `Session` can also hold temporary data (`State`) relevant only *during this conversation*.

1. **`State` (`session.state`)**: Data Within the Current Conversation

   - Data stored within a specific `Session`.
   - Used to manage information relevant *only* to the *current, active* conversation thread (e.g., items in a shopping cart *during this chat*, user preferences mentioned *in this session*).

1. **`Memory`**: Searchable, Cross-Session Information

   - Represents a store of information that might span *multiple past sessions* or include external data sources.
   - It acts as a knowledge base the agent can *search* to recall information or context beyond the immediate conversation.

## Managing Context: Services

ADK provides services to manage these concepts:

1. **`SessionService`**: Manages the different conversation threads (`Session` objects)

   - Handles the lifecycle: creating, retrieving, updating (appending `Events`, modifying `State`), and deleting individual `Session`s.

1. **`MemoryService`**: Manages the Long-Term Knowledge Store (`Memory`)

   - Handles ingesting information (often from completed `Session`s) into the long-term store.
   - Provides methods to search this stored knowledge based on queries.

**Implementations**: ADK offers different implementations for both `SessionService` and `MemoryService`, allowing you to choose the storage backend that best fits your application's needs. Notably, **in-memory implementations** are provided for both services; these are designed specifically for **local testing and fast development**. It's important to remember that **all data stored using these in-memory options (sessions, state, or long-term knowledge) is lost when your application restarts**. For persistence and scalability beyond local testing, ADK also offers cloud-based and database service options.

**In Summary:**

- **`Session` & `State`**: Focus on the **current interaction** – the history and data of the *single, active conversation*. Managed primarily by a `SessionService`.
- **Memory**: Focuses on the **past and external information** – a *searchable archive* potentially spanning across conversations. Managed by a `MemoryService`.

## What's Next?

In the following sections, we'll dive deeper into each of these components:

- **`Session`**: Understanding its structure and `Events`.
- **`State`**: How to effectively read, write, and manage session-specific data.
- **`SessionService`**: Choosing the right storage backend for your sessions.
- **`MemoryService`**: Exploring options for storing and retrieving broader context.

Understanding these concepts is fundamental to building agents that can engage in complex, stateful, and context-aware conversations.

# Memory: Long-Term Knowledge with `MemoryService`

Supported in ADKPython v0.1.0Typescript v0.2.0Go v0.1.0Java v0.1.0

We've seen how `Session` tracks the history (`events`) and temporary data (`state`) for a *single, ongoing conversation*. But what if an agent needs to recall information from *past* conversations? This is where the concept of **Long-Term Knowledge** and the **`MemoryService`** come into play.

Think of it this way:

- **`Session` / `State`:** Like your short-term memory during one specific chat.
- **Long-Term Knowledge (`MemoryService`)**: Like a searchable archive or knowledge library the agent can consult, potentially containing information from many past chats or other sources.

## The `MemoryService` Role

The `BaseMemoryService` (or `Service` in Go) defines the interface for managing this searchable, long-term knowledge store. It supports four operations:

1. **Ingesting a session (`add_session_to_memory`):** Take the contents of a (usually completed) `Session` and add relevant information to the long-term knowledge store.
1. **Ingesting events incrementally (`add_events_to_memory`):** Append a delta of events (e.g., the latest turn) without re-ingesting the full session. Useful when you want to write to memory partway through a long-running session.
1. **Writing memory items directly (`add_memory`):** Insert pre-built `MemoryEntry` items, for services that support direct writes alongside event-based extraction.
1. **Searching (`search_memory`):** Allow an agent (typically via a `Tool`) to query the knowledge store and retrieve relevant snippets based on a search query.

Operations 2 and 3 are optional — the base class implementations of `add_events_to_memory` and `add_memory` raise `NotImplementedError`, so check your concrete service before relying on them.

## Choosing the Right Memory Service

The Python ADK ships three `MemoryService` implementations. Use the table below to decide which is the best fit for your agent.

| **Feature**           | **InMemoryMemoryService**                                                         | **VertexAiMemoryBankService**                                                                                                                                                                                      | **VertexAiRagMemoryService**                                                                                                            |
| --------------------- | --------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------- |
| **Persistence**       | None (data is lost on restart)                                                    | Yes (Managed by Agent Platform)                                                                                                                                                                                    | Yes (stored in Knowledge Engine)                                                                                                        |
| **Primary Use Case**  | Prototyping, local development, and simple testing.                               | Building meaningful, evolving memories from user conversations.                                                                                                                                                    | Vector-search retrieval over the full conversation corpus, or alongside other RAG-indexed content.                                      |
| **Memory Extraction** | Stores full conversation                                                          | Extracts [meaningful information](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/memory-bank/generate-memories) from conversations and consolidates it with existing memories (powered by LLM) | Stores full conversation, indexed by [Knowledge Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/rag-engine/rag-overview). |
| **Search Capability** | Basic keyword matching.                                                           | Advanced semantic search.                                                                                                                                                                                          | Vector similarity search over Knowledge Engine.                                                                                         |
| **Setup Complexity**  | None. It's the default.                                                           | Low. Requires an [Agent Runtime](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/memory-bank/overview) instance on Agent Platform.                                                              | Medium. Requires [Knowledge Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/rag-engine/manage-your-rag-corpus).           |
| **Dependencies**      | None.                                                                             | Google Cloud Project, Agent Platform API                                                                                                                                                                           | Google Cloud Project, Knowledge Engine, the Agent Platform SDK (optional install).                                                      |
| **When to use it**    | When you want to search across multiple sessions’ chat histories for prototyping. | When you want your agent to remember and learn from past interactions.                                                                                                                                             | When you already have RAG infrastructure or want to retrieve over raw conversation transcripts.                                         |

`VertexAiRagMemoryService` is only exported from `google.adk.memory` when the Agent Platform SDK is installed. Memory Bank and RAG-backed memory are documented in [Memory Bank](#memory-bank) and [RAG Memory](#rag-memory) below.

## In-Memory Memory

The `InMemoryMemoryService` stores session information in the application's memory and performs basic keyword matching for searches. It requires no setup and is best for prototyping and simple testing scenarios where persistence isn't required.

```py
from google.adk.memory import InMemoryMemoryService
memory_service = InMemoryMemoryService()
```

```typescript
import { InMemoryMemoryService } from '@google/adk';
const memoryService = new InMemoryMemoryService();
```

```go
import (
  "google.golang.org/adk/memory"
  "google.golang.org/adk/session"
)

// Services must be shared across runners to share state and memory.
sessionService := session.InMemoryService()
memoryService := memory.InMemoryService()
```

```java
import com.google.adk.memory.InMemoryMemoryService;

InMemoryMemoryService memoryService = new InMemoryMemoryService();
```

**Example: Adding and Searching Memory**

This example demonstrates the basic flow using the `InMemoryMemoryService` for simplicity.

```py
import asyncio
from google.adk.agents import LlmAgent
from google.adk.sessions import InMemorySessionService, Session
from google.adk.memory import InMemoryMemoryService # Import MemoryService
from google.adk.runners import Runner
from google.adk.tools import load_memory # Tool to query memory
from google.genai.types import Content, Part

# --- Constants ---
APP_NAME = "memory_example_app"
USER_ID = "mem_user"
MODEL = "gemini-flash-latest" # Use a valid model

# --- Agent Definitions ---
# Agent 1: Simple agent to capture information
info_capture_agent = LlmAgent(
    model=MODEL,
    name="InfoCaptureAgent",
    instruction="Acknowledge the user's statement.",
)

# Agent 2: Agent that can use memory
memory_recall_agent = LlmAgent(
    model=MODEL,
    name="MemoryRecallAgent",
    instruction="Answer the user's question. Use the 'load_memory' tool "
                "if the answer might be in past conversations.",
    tools=[load_memory] # Give the agent the tool
)

# --- Services ---
# Services must be shared across runners to share state and memory
session_service = InMemorySessionService()
memory_service = InMemoryMemoryService() # Use in-memory for demo

async def run_scenario():
    # --- Scenario ---

    # Turn 1: Capture some information in a session
    print("--- Turn 1: Capturing Information ---")
    runner1 = Runner(
        # Start with the info capture agent
        agent=info_capture_agent,
        app_name=APP_NAME,
        session_service=session_service,
        memory_service=memory_service # Provide the memory service to the Runner
    )
    session1_id = "session_info"
    await runner1.session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=session1_id)
    user_input1 = Content(parts=[Part(text="My favorite project is Project Alpha.")], role="user")

    # Run the agent
    final_response_text = "(No final response)"
    async for event in runner1.run_async(user_id=USER_ID, session_id=session1_id, new_message=user_input1):
        if event.is_final_response() and event.content and event.content.parts:
            final_response_text = event.content.parts[0].text
    print(f"Agent 1 Response: {final_response_text}")

    # Get the completed session
    completed_session1 = await runner1.session_service.get_session(app_name=APP_NAME, user_id=USER_ID, session_id=session1_id)

    # Add this session's content to the Memory Service
    print("\n--- Adding Session 1 to Memory ---")
    await memory_service.add_session_to_memory(completed_session1)
    print("Session added to memory.")

    # Turn 2: Recall the information in a new session
    print("\n--- Turn 2: Recalling Information ---")
    runner2 = Runner(
        # Use the second agent, which has the memory tool
        agent=memory_recall_agent,
        app_name=APP_NAME,
        session_service=session_service, # Reuse the same service
        memory_service=memory_service   # Reuse the same service
    )
    session2_id = "session_recall"
    await runner2.session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=session2_id)
    user_input2 = Content(parts=[Part(text="What is my favorite project?")], role="user")

    # Run the second agent
    final_response_text_2 = "(No final response)"
    async for event in runner2.run_async(user_id=USER_ID, session_id=session2_id, new_message=user_input2):
        if event.is_final_response() and event.content and event.content.parts:
            final_response_text_2 = event.content.parts[0].text
    print(f"Agent 2 Response: {final_response_text_2}")

# To run this example, you can use the following snippet:
# asyncio.run(run_scenario())

# await run_scenario()
```

```typescript
import {
    InMemoryMemoryService,
    InMemorySessionService,
    LOAD_MEMORY,
    LlmAgent,
    Runner
} from '@google/adk';
import { createUserContent } from '@google/genai';

// --- Constants ---
const APP_NAME = "memory_example_app";
const USER_ID = "mem_user";
const MODEL = "gemini-2.5-flash";

// --- Agent Definitions ---

// Agent 1: Simple agent to capture information
const infoCaptureAgent = new LlmAgent({
    model: MODEL,
    name: "InfoCaptureAgent",
    instruction: "Acknowledge the user's statement concisely.",
});

// Agent 2: Agent that can use memory
const memoryRecallAgent = new LlmAgent({
    model: MODEL,
    name: "MemoryRecallAgent",
    instruction: "Answer the user's question. Use the 'load_memory' tool if the answer might be in past conversations.",
    tools: [LOAD_MEMORY]
});

// Export for 'adk run' compatibility (to avoid 'No BaseAgent found' error)
export const root_agent = memoryRecallAgent;

// --- Services ---
const sessionService = new InMemorySessionService();
const memoryService = new InMemoryMemoryService();

async function runScenario() {
    // --- Turn 1: Capture some information in a session ---
    console.log("--- Turn 1: Capturing Information ---");
    const runner1 = new Runner({
        agent: infoCaptureAgent,
        appName: APP_NAME,
        sessionService,
        memoryService
    });

    const session1Id = "session_info";
    await sessionService.createSession({ appName: APP_NAME, userId: USER_ID, sessionId: session1Id });
    const userInput1 = createUserContent("My favorite project is Project Alpha.");

    let finalResponseText = "(No final response)";
    for await (const event of runner1.runAsync({ userId: USER_ID, sessionId: session1Id, newMessage: userInput1 })) {
        // Capture any text response from the agent
        if (event.author === infoCaptureAgent.name && event.content?.parts) {
            const text = event.content.parts.map(p => p.text || "").join("").trim();
            if (text) finalResponseText = text;
        }
    }
    console.log(`Agent 1 Response: ${finalResponseText}`);

    // Get the completed session and add to Memory
    const completedSession1 = await sessionService.getSession({ appName: APP_NAME, userId: USER_ID, sessionId: session1Id });
    console.log("\n--- Adding Session 1 to Memory ---");
    if (completedSession1) {
        await memoryService.addSessionToMemory(completedSession1);
        console.log("Session added to memory.");
    }

    // --- Turn 2: Recall the information in a new session ---
    console.log("\n--- Turn 2: Recalling Information ---");
    const runner2 = new Runner({
        agent: memoryRecallAgent,
        appName: APP_NAME,
        sessionService,
        memoryService
    });

    const session2Id = "session_recall";
    await sessionService.createSession({ appName: APP_NAME, userId: USER_ID, sessionId: session2Id });
    const userInput2 = createUserContent("What is my favorite project?");

    let finalResponseText2 = "(No final response)";
    for await (const event of runner2.runAsync({ userId: USER_ID, sessionId: session2Id, newMessage: userInput2 })) {
        // Capture any text response from the agent
        if (event.author === memoryRecallAgent.name && event.content?.parts) {
            const text = event.content.parts.map(p => p.text || "").join("").trim();
            if (text) finalResponseText2 = text;
        }
    }
    console.log(`Agent 2 Response: ${finalResponseText2}`);

    // Exit immediately to prevent the ADK CLI from starting an interactive loop
    process.exit(0);
}

// Execute the scenario
runScenario().catch(err => {
    console.error(err);
    process.exit(1);
});
```

```go
import (
    "context"
    "fmt"
    "log"
    "strings"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/memory"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/runner"
    "google.golang.org/adk/session"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/functiontool"
    "google.golang.org/genai"
)

const (
    appName = "go_memory_example_app"
    userID  = "go_mem_user"
    modelID = "gemini-2.5-flash"
)

// Args defines the input structure for the memory search tool.
type Args struct {
    Query string `json:"query" jsonschema:"The query to search for in the memory."`
}

// Result defines the output structure for the memory search tool.
type Result struct {
    Results []string `json:"results"`
}


// memorySearchToolFunc is the implementation of the memory search tool.
// This function demonstrates accessing memory via tool.Context.
func memorySearchToolFunc(tctx tool.Context, args Args) (Result, error) {
    fmt.Printf("Tool: Searching memory for query: '%s'\n", args.Query)
    // The SearchMemory function is available on the context.
    searchResults, err := tctx.SearchMemory(context.Background(), args.Query)
    if err != nil {
        log.Printf("Error searching memory: %v", err)
        return Result{}, fmt.Errorf("failed memory search")
    }

    var results []string
    for _, res := range searchResults.Memories {
        if res.Content != nil {
            results = append(results, textParts(res.Content)...)
        }
    }
    return Result{Results: results}, nil
}

// Define a tool that can search memory.
var memorySearchTool = must(functiontool.New(
    functiontool.Config{
        Name:        "search_past_conversations",
        Description: "Searches past conversations for relevant information.",
    },
    memorySearchToolFunc,
))


// This example demonstrates how to use the MemoryService in the Go ADK.
// It covers two main scenarios:
// 1. Adding a completed session to memory and recalling it in a new session.
// 2. Searching memory from within a custom tool using the tool.Context.
func main() {
    ctx := context.Background()

    // --- Services ---
    // Services must be shared across runners to share state and memory.
    sessionService := session.InMemoryService()
    memoryService := memory.InMemoryService() // Use in-memory for this demo.

    // --- Scenario 1: Capture information in one session ---
    fmt.Println("--- Turn 1: Capturing Information ---")
    infoCaptureAgent := must(llmagent.New(llmagent.Config{
        Name:        "InfoCaptureAgent",
        Model:       must(gemini.NewModel(ctx, modelID, nil)),
        Instruction: "Acknowledge the user's statement.",
    }))

    runner1 := must(runner.New(runner.Config{
        AppName:        appName,
        Agent:          infoCaptureAgent,
        SessionService: sessionService,
        MemoryService:  memoryService, // Provide the memory service to the Runner
    }))

    session1ID := "session_info"
    must(sessionService.Create(ctx, &session.CreateRequest{AppName: appName, UserID: userID, SessionID: session1ID}))

    userInput1 := genai.NewContentFromText("My favorite project is Project Alpha.", "user")
    var finalResponseText string
    for event, err := range runner1.Run(ctx, userID, session1ID, userInput1, agent.RunConfig{}) {
        if err != nil {
            log.Printf("Agent 1 Error: %v", err)
            continue
        }
        if event.LLMResponse.Content != nil && !event.LLMResponse.Partial {
            finalResponseText = strings.Join(textParts(event.LLMResponse.Content), "")
        }
    }
    fmt.Printf("Agent 1 Response: %s\n", finalResponseText)

    // Add the completed session to the Memory Service
    fmt.Println("\n--- Adding Session 1 to Memory ---")
    resp, err := sessionService.Get(ctx, &session.GetRequest{AppName: appName, UserID: userID, SessionID: session1ID})
    if err != nil {
        log.Fatalf("Failed to get completed session: %v", err)
    }
    if err := memoryService.AddSessionToMemory(ctx, resp.Session); err != nil {
        log.Fatalf("Failed to add session to memory: %v", err)
    }
    fmt.Println("Session added to memory.")

    // --- Scenario 2: Recall the information in a new session using a tool ---
    fmt.Println("\n--- Turn 2: Recalling Information ---")

    memoryRecallAgent := must(llmagent.New(llmagent.Config{
        Name:        "MemoryRecallAgent",
        Model:       must(gemini.NewModel(ctx, modelID, nil)),
        Instruction: "Answer the user's question. Use the 'search_past_conversations' tool if the answer might be in past conversations.",
        Tools:       []tool.Tool{memorySearchTool}, // Give the agent the tool
    }))

    runner2 := must(runner.New(runner.Config{
        Agent:          memoryRecallAgent,
        AppName:        appName,
        SessionService: sessionService,
        MemoryService:  memoryService,
    }))

    session2ID := "session_recall"
    must(sessionService.Create(ctx, &session.CreateRequest{AppName: appName, UserID: userID, SessionID: session2ID}))
    userInput2 := genai.NewContentFromText("What is my favorite project?", "user")

    var finalResponseText2 string
    for event, err := range runner2.Run(ctx, userID, session2ID, userInput2, agent.RunConfig{}) {
        if err != nil {
            log.Printf("Agent 2 Error: %v", err)
            continue
        }
        if event.LLMResponse.Content != nil && !event.LLMResponse.Partial {
            finalResponseText2 = strings.Join(textParts(event.LLMResponse.Content), "")
        }
    }
    fmt.Printf("Agent 2 Response: %s\n", finalResponseText2)
}
```

```java
package com.google.adk.examples.sessions;

import com.google.adk.agents.LlmAgent;
import com.google.adk.memory.InMemoryMemoryService;
import com.google.adk.runner.Runner;
import com.google.adk.sessions.InMemorySessionService;
import com.google.adk.sessions.Session;
import com.google.adk.tools.LoadMemoryTool;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import java.util.Optional;

public class MemoryExample {

  private static final String APP_NAME = "memory_example_app";
  private static final String USER_ID = "mem_user";
  private static final String MODEL = "gemini-flash-latest";

  public static void main(String[] args) {
    // Services
    InMemorySessionService sessionService = new InMemorySessionService();
    InMemoryMemoryService memoryService = new InMemoryMemoryService();

    // Agent 1: Capture
    LlmAgent infoCaptureAgent = new LlmAgent.Builder()
        .model(MODEL)
        .name("InfoCaptureAgent")
        .instruction("Acknowledge the user's statement.")
        .build();

    // Agent 2: Recall
    LlmAgent memoryRecallAgent = new LlmAgent.Builder()
        .model(MODEL)
        .name("MemoryRecallAgent")
        .instruction("Answer the user's question. Use the 'load_memory' tool if the answer might be in past conversations.")
        .tools(new LoadMemoryTool())
        .build();

    // Turn 1
    System.out.println("--- Turn 1: Capturing Information ---");
    Runner runner1 = new Runner.Builder()
        .agent(infoCaptureAgent)
        .appName(APP_NAME)
        .sessionService(sessionService)
        .memoryService(memoryService)
        .build();

    String session1Id = "session_info";
    // Create session
    sessionService.createSession(APP_NAME, USER_ID, null, session1Id).blockingGet();

    Content userInput1 = Content.fromParts(Part.fromText("My favorite project is Project Alpha."));

    runner1.runAsync(USER_ID, session1Id, userInput1)
        .blockingForEach(event -> {
           if (event.finalResponse() && event.content().isPresent()) {
             System.out.println("Agent 1 Response: " + event.content().get().parts().get(0).text().get());
           }
        });

    // Add to memory
    System.out.println("\n--- Adding Session 1 to Memory ---");
    Session completedSession1 = sessionService.getSession(APP_NAME, USER_ID, session1Id, Optional.empty()).blockingGet();
    memoryService.addSessionToMemory(completedSession1).blockingAwait();
    System.out.println("Session added to memory.");

    // Turn 2
    System.out.println("\n--- Turn 2: Recalling Information ---");
    Runner runner2 = new Runner.Builder()
        .agent(memoryRecallAgent)
        .appName(APP_NAME)
        .sessionService(sessionService)
        .memoryService(memoryService)
        .build();

    String session2Id = "session_recall";
    sessionService.createSession(APP_NAME, USER_ID, null, session2Id).blockingGet();

    Content userInput2 = Content.fromParts(Part.fromText("What is my favorite project?"));

    runner2.runAsync(USER_ID, session2Id, userInput2)
        .blockingForEach(event -> {
           if (event.finalResponse() && event.content().isPresent()) {
             System.out.println("Agent 2 Response: " + event.content().get().parts().get(0).text().get());
           }
        });
  }
}
```

### Searching Memory Within a Tool

You can also search memory from within a custom tool by using the tool context.

```python
from google.adk.tools import ToolContext

async def search_past_conversations(
    query: str, tool_context: ToolContext
) -> dict:
    response = await tool_context.search_memory(query)
    return {
        "results": [
            part.text
            for entry in response.memories
            for part in (entry.content.parts or [])
            if part.text
        ]
    }
```

```go
// memorySearchToolFunc is the implementation of the memory search tool.
// This function demonstrates accessing memory via tool.Context.
func memorySearchToolFunc(tctx tool.Context, args Args) (Result, error) {
    fmt.Printf("Tool: Searching memory for query: '%s'\n", args.Query)
    // The SearchMemory function is available on the context.
    searchResults, err := tctx.SearchMemory(context.Background(), args.Query)
    if err != nil {
        log.Printf("Error searching memory: %v", err)
        return Result{}, fmt.Errorf("failed memory search")
    }

    var results []string
    for _, res := range searchResults.Memories {
        if res.Content != nil {
            results = append(results, textParts(res.Content)...)
        }
    }
    return Result{Results: results}, nil
}

// Define a tool that can search memory.
var memorySearchTool = must(functiontool.New(
    functiontool.Config{
        Name:        "search_past_conversations",
        Description: "Searches past conversations for relevant information.",
    },
    memorySearchToolFunc,
))
```

```typescript
// Within a tool implementation
async runAsync({ args, toolContext }: RunAsyncToolRequest) {
  const query = args['query'] as string;
  const response = await toolContext.searchMemory(query);
  // process response
  return {
    memories: response.memories.map(m => m.content.parts?.map(p => p.text).join(' ')).join('\n')
  };
}
```

```java
// Within a tool implementation
public Single<ToolOutput> execute(ToolContext context) {
  String query = ...; // get query from arguments
  return context.searchMemory(query)
      .map(response -> {
          // process response
          return new ToolOutput(response.memories().toString());
      });
}
```

## Memory Bank

The `VertexAiMemoryBankService` connects your agent to [Memory Bank](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/memory-bank/overview), a fully managed Google Cloud service that provides sophisticated, persistent memory capabilities for conversational agents.

### How It Works

The service handles two key operations:

- **Generating Memories:** At the end of a conversation, you can send the session's events to the Memory Bank, which intelligently processes and stores the information as "memories."
- **Retrieving Memories:** Your agent code can issue a search query against the Memory Bank to retrieve relevant memories from past conversations.

### Prerequisites

Before you can use this feature, you must have:

1. **A Google Cloud Project:** With the Agent Platform API enabled.

1. **An Agent Runtime:** You need to create an Agent Runtime on Agent Platform. You do not need to deploy your agent to Agent Runtime to use Memory Bank. This will provide you with the **Agent Runtime ID** required for configuration.

1. **Authentication:** Ensure your local environment is authenticated to access Google Cloud services. The simplest way is to run:

   ```bash
   gcloud auth application-default login
   ```

1. **Environment Variables:** The service requires your Google Cloud Project ID and Location. Set them as environment variables:

   ```bash
   export GOOGLE_CLOUD_PROJECT="your-gcp-project-id"
   export GOOGLE_CLOUD_LOCATION="your-gcp-location"
   ```

### Configuration

To connect your agent to the Memory Bank, you use the `--memory_service_uri` flag when starting the ADK server (`adk web` or `adk api_server`). The URI must be in the format `agentengine://<agent_engine_id>`.

bash

```bash
adk web path/to/your/agents_dir --memory_service_uri="agentengine://1234567890"
```

Or, you can configure your agent to use the Memory Bank by manually instantiating the `VertexAiMemoryBankService` and passing it to the `Runner`.

```py
from google import adk
from google.adk.memory import VertexAiMemoryBankService

agent_engine_id = agent_engine.api_resource.name.split("/")[-1]

memory_service = VertexAiMemoryBankService(
    project="PROJECT_ID",
    location="LOCATION",
    agent_engine_id=agent_engine_id
)

runner = adk.Runner(
    ...
    memory_service=memory_service
)
```

## RAG Memory

The `VertexAiRagMemoryService` stores conversations in [Knowledge Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/rag-engine/rag-overview) and retrieves them by vector similarity. Use it when you already have RAG infrastructure or want raw transcript retrieval rather than the LLM-extracted memories produced by Memory Bank. Requires the Agent Platform SDK.

```py
from google.adk.memory import VertexAiRagMemoryService

memory_service = VertexAiRagMemoryService(
    rag_corpus="projects/PROJECT_ID/locations/LOCATION/ragCorpora/CORPUS_ID",
    similarity_top_k=5,
    vector_distance_threshold=0.6,
)
```

## Using Memory in Your Agent

When a memory service is configured, your agent can use a tool or callback to retrieve memories. ADK includes two pre-built tools for retrieving memories:

- `PreloadMemory`: Always retrieve memory at the beginning of each turn (similar to a callback).
- `LoadMemory`: Retrieve memory when your agent decides it would be helpful.

**Example:**

```python
from google.adk.agents import Agent
from google.adk.tools.preload_memory_tool import PreloadMemoryTool

agent = Agent(
    model=MODEL_ID,
    name='weather_sentiment_agent',
    instruction="...",
    tools=[PreloadMemoryTool()]
)
```

```typescript
import { LlmAgent, PRELOAD_MEMORY } from '@google/adk';

const agent = new LlmAgent({
    model: MODEL_ID,
    name: 'weather_sentiment_agent',
    instruction: "...",
    tools: [PRELOAD_MEMORY]
});
```

```go
import (
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/preloadmemorytool"
)

agent, _ := llmagent.New(llmagent.Config{
    Model:       model,
    Name:        "weather_sentiment_agent",
    Instruction: "...",
    Tools:       []tool.Tool{preloadmemorytool.New()},
})
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.tools.LoadMemoryTool;

LlmAgent agent = new LlmAgent.Builder()
    .model(MODEL_ID)
    .name("weather_sentiment_agent")
    .instruction("...")
    .tools(new LoadMemoryTool())
    .build();
```

To extract memories from your session, you need to call `add_session_to_memory`. For example, you can automate this via a callback:

```python
from google.adk.agents import Agent
from google import adk

async def auto_save_session_to_memory_callback(callback_context):
    await callback_context.add_session_to_memory()

agent = Agent(
    model=MODEL,
    name="Generic_QA_Agent",
    instruction="Answer the user's questions",
    tools=[adk.tools.preload_memory_tool.PreloadMemoryTool()],
    after_agent_callback=auto_save_session_to_memory_callback,
)
```

```typescript
import { LlmAgent, PRELOAD_MEMORY, SingleAgentCallback } from '@google/adk';

const autoSaveSessionToMemoryCallback: SingleAgentCallback = async (callbackContext) => {
    if (callbackContext.invocationContext.memoryService) {
        await callbackContext.invocationContext.memoryService.addSessionToMemory(
            callbackContext.invocationContext.session
        );
    }
};

const agent = new LlmAgent({
    model: MODEL,
    name: "Generic_QA_Agent",
    instruction: "Answer the user's questions",
    tools: [PRELOAD_MEMORY],
    afterAgentCallback: autoSaveSessionToMemoryCallback,
});
```

```go
import (
    "context"
    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/session"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/loadmemorytool"
)

func autoSaveSessionToMemoryCallback(ctx agent.CallbackContext, s session.Session) (*genai.Content, error) {
    if err := ctx.Memory().AddSessionToMemory(context.Background(), s); err != nil {
        return nil, err
    }
    return nil, nil
}

agent, _ := llmagent.New(llmagent.Config{
    Model:               model,
    Name:                "Generic_QA_Agent",
    Instruction:         "Answer the user's questions",
    Tools:               []tool.Tool{loadmemorytool.New()},
    AfterAgentCallbacks: []agent.AfterAgentCallback{autoSaveSessionToMemoryCallback},
})
```

## Advanced Concepts

### How Memory Works in Practice

The memory workflow internally involves these steps:

1. **Session Interaction:** A user interacts with an agent via a `Session`, managed by a `SessionService`. Events are added, and state might be updated.
1. **Ingestion into Memory:** At some point (often when a session is considered complete or has yielded significant information), your application calls `memory_service.add_session_to_memory(session)`. This extracts relevant information from the session's events and adds it to the long-term knowledge store (in-memory dictionary or Agent Runtime Memory Bank).
1. **Later Query:** In a *different* (or the same) session, the user might ask a question requiring past context (e.g., "What did we discuss about project X last week?").
1. **Agent Uses Memory Tool:** An agent equipped with a memory-retrieval tool (like the built-in `load_memory` tool) recognizes the need for past context. It calls the tool, providing a search query (e.g., "discussion project X last week").
1. **Search Execution:** The tool internally calls `memory_service.search_memory(app_name=..., user_id=..., query=...)`.
1. **Results Returned:** The `MemoryService` searches its store (using keyword matching or semantic search) and returns matching snippets as a `SearchMemoryResponse` containing a list of `MemoryEntry` objects (each holding `content`, optional `author`, optional `timestamp`, and optional `custom_metadata`).
1. **Agent Uses Results:** The tool returns these results to the agent, usually as part of the context or function response. The agent can then use this retrieved information to formulate its final answer to the user.

### Can an agent have access to more than one memory service?

- **Through Standard Configuration: No.** The framework (`adk web`, `adk api_server`) is designed to be configured with one memory service at a time via the `--memory_service_uri` flag. That single service is wired into the runner and exposed through `tool_context.search_memory()` and `callback_context.search_memory()`.
- **Within Your Agent's Code: Yes.** Nothing stops you from importing and instantiating a second `BaseMemoryService` directly. The cleanest place to consult it is from a custom tool, which already has a `ToolContext` for the framework-configured service.

For example, your agent can use the framework-configured `InMemoryMemoryService` for conversation history and manually instantiate a second service (a `VertexAiMemoryBankService`, a `VertexAiRagMemoryService` over a docs corpus, or any other `BaseMemoryService` implementation) for a separate knowledge base.

#### Example: Using Two Memory Services

```python
from google.adk.agents import Agent
from google.adk.memory import InMemoryMemoryService
from google.adk.tools import ToolContext

# Second memory service for docs lookup; could be any BaseMemoryService.
docs_memory = InMemoryMemoryService()


async def search_all_memory(query: str, tool_context: ToolContext) -> dict:
    """Search both the conversational memory and the docs corpus."""
    conversational = await tool_context.search_memory(query)
    docs = await docs_memory.search_memory(
        app_name="docs", user_id="shared", query=query
    )
    return {
        "from_conversations": [
            part.text
            for entry in conversational.memories
            for part in (entry.content.parts or [])
            if part.text
        ],
        "from_docs": [
            part.text
            for entry in docs.memories
            for part in (entry.content.parts or [])
            if part.text
        ],
    }


agent = Agent(
    model="gemini-flash-latest",
    name="multi_memory_agent",
    instruction=(
        "Answer questions using both your conversation history and the "
        "docs knowledge base. Use the search_all_memory tool."
    ),
    tools=[search_all_memory],
)
```

# State: The Session's Scratchpad

Supported in ADKPython v0.1.0TypeScript v0.2.0Go v0.1.0Java v0.1.0

Within each `Session` (our conversation thread), the **`state`** attribute acts like the agent's dedicated scratchpad for that specific interaction. While `session.events` holds the full history, `session.state` is where the agent stores and updates dynamic details needed *during* the conversation.

## What is `session.state`?

Conceptually, `session.state` is a collection (dictionary or Map) holding key-value pairs. It's designed for information the agent needs to recall or track to make the current conversation effective:

- **Personalize Interaction:** Remember user preferences mentioned earlier (e.g., `'user_preference_theme': 'dark'`).
- **Track Task Progress:** Keep tabs on steps in a multi-turn process (e.g., `'booking_step': 'confirm_payment'`).
- **Accumulate Information:** Build lists or summaries (e.g., `'shopping_cart_items': ['book', 'pen']`).
- **Make Informed Decisions:** Store flags or values influencing the next response (e.g., `'user_is_authenticated': True`).

### Key Characteristics of `State`

1. **Structure: Serializable Key-Value Pairs**

   - Data is stored as `key: value`.
   - **Keys:** Always strings (`str`). Use clear names (e.g., `'departure_city'`, `'user:language_preference'`).
   - **Values:** Must be **serializable**. This means they can be easily saved and loaded by the `SessionService`. Stick to basic types in the specific languages (Python/Go/Java/TypeScript) like strings, numbers, booleans, and simple lists or dictionaries containing *only* these basic types. (See API documentation for precise details).
   - **⚠️ Avoid Complex Objects:** **Do not store non-serializable objects** (custom class instances, functions, connections, etc.) directly in the state. Store simple identifiers if needed, and retrieve the complex object elsewhere.

1. **Mutability: It Changes**

   - The contents of the `state` are expected to change as the conversation evolves.

1. **Persistence: Depends on `SessionService`**

   - Whether state survives application restarts depends on your chosen service:
   - `InMemorySessionService`: **Not Persistent.** State is lost on restart.
   - `DatabaseSessionService` / `VertexAiSessionService`: **Persistent.** State is saved reliably.

Note

The specific parameters or method names for the primitives may vary slightly by SDK language (e.g., `session.state['current_intent'] = 'book_flight'` in Python,`context.State().Set("current_intent", "book_flight")` in Go, `session.state().put("current_intent", "book_flight)` in Java, or `context.state.set("current_intent", "book_flight")` in TypeScript). Refer to the language-specific API documentation for details.

### Organizing State with Prefixes: Scope Matters

Prefixes on state keys define their scope and persistence behavior, especially with persistent services:

- **No Prefix (Session State):**

  - **Scope:** Specific to the *current* session (`id`).
  - **Persistence:** Only persists if the `SessionService` is persistent (`Database`, `VertexAI`).
  - **Use Cases:** Tracking progress within the current task (e.g., `'current_booking_step'`), temporary flags for this interaction (e.g., `'needs_clarification'`).
  - **Example:** `session.state['current_intent'] = 'book_flight'`

- **`user:` Prefix (User State):**

  - **Scope:** Tied to the `user_id`, shared across *all* sessions for that user (within the same `app_name`).
  - **Persistence:** Persistent with `Database` or `VertexAI`. (Stored by `InMemory` but lost on restart).
  - **Use Cases:** User preferences (e.g., `'user:theme'`), profile details (e.g., `'user:name'`).
  - **Example:** `session.state['user:preferred_language'] = 'fr'`

- **`app:` Prefix (App State):**

  - **Scope:** Tied to the `app_name`, shared across *all* users and sessions for that application.
  - **Persistence:** Persistent with `Database` or `VertexAI`. (Stored by `InMemory` but lost on restart).
  - **Use Cases:** Global settings (e.g., `'app:api_endpoint'`), shared templates.
  - **Example:** `session.state['app:global_discount_code'] = 'SAVE10'`

- **`temp:` Prefix (Temporary Invocation State):**

  - **Scope:** Specific to the current **invocation** (the entire process from an agent receiving user input to generating the final output for that input).
  - **Persistence:** **Not Persistent.** Discarded after the invocation completes and does not carry over to the next one.
  - **Use Cases:** Storing intermediate calculations, flags, or data passed between tool calls within a single invocation.
  - **When Not to Use:** For information that must persist across different invocations, such as user preferences, conversation history summaries, or accumulated data.
  - **Example:** `session.state['temp:raw_api_response'] = {...}`

Sub-Agents and Invocation Context

When a parent agent calls a sub-agent (e.g., using `SequentialAgent` or `ParallelAgent`), it passes its `InvocationContext` to the sub-agent. This means the entire chain of agent calls shares the same invocation ID and, therefore, the same `temp:` state.

**How the Agent Sees It:** Your agent code interacts with the *combined* state through the single `session.state` collection (dict/ Map). The `SessionService` handles fetching/merging state from the correct underlying storage based on prefixes.

### Accessing Session State in Agent Instructions

When working with `LlmAgent` instances, you can directly inject session state values into the agent's instruction string using a simple templating syntax. This allows you to create dynamic and context-aware instructions without relying solely on natural language directives.

#### Using `{key}` Templating

To inject a value from the session state, enclose the key of the desired state variable within curly braces: `{key}`. The framework will automatically replace this placeholder with the corresponding value from `session.state` before passing the instruction to the LLM.

**Example:**

```python
from google.adk.agents import LlmAgent

story_generator = LlmAgent(
    name="StoryGenerator",
    model="gemini-flash-latest",
    instruction="""Write a short story about a cat, focusing on the theme: {topic}."""
)

# Assuming session.state['topic'] is set to "friendship", the LLM
# will receive the following instruction:
# "Write a short story about a cat, focusing on the theme: friendship."
```

```typescript
import { LlmAgent } from "@google/adk";

const storyGenerator = new LlmAgent({
    name: "StoryGenerator",
    model: "gemini-flash-latest",
    instruction: "Write a short story about a cat, focusing on the theme: {topic}."
});

// Assuming session.state['topic'] is set to "friendship", the LLM
// will receive the following instruction:
// "Write a short story about a cat, focusing on the theme: friendship."
```

```go
func main() {
    ctx := context.Background()
    sessionService := session.InMemoryService()

    // 1. Initialize a session with a 'topic' in its state.
    _, err := sessionService.Create(ctx, &session.CreateRequest{
        AppName:   appName,
        UserID:    userID,
        SessionID: sessionID,
        State: map[string]any{
            "topic": "friendship",
        },
    })
    if err != nil {
        log.Fatalf("Failed to create session: %v", err)
    }

    // 2. Create an agent with an instruction that uses a {topic} placeholder.
    //    The ADK will automatically inject the value of "topic" from the
    //    session state into the instruction before calling the LLM.
    model, err := gemini.NewModel(ctx, modelID, nil)
    if err != nil {
        log.Fatalf("Failed to create Gemini model: %v", err)
    }
    storyGenerator, err := llmagent.New(llmagent.Config{
        Name:        "StoryGenerator",
        Model:       model,
        Instruction: "Write a short story about a cat, focusing on the theme: {topic}.",
    })
    if err != nil {
        log.Fatalf("Failed to create agent: %v", err)
    }

    r, err := runner.New(runner.Config{
        AppName:        appName,
        Agent:          agent.Agent(storyGenerator),
        SessionService: sessionService,
    })
    if err != nil {
        log.Fatalf("Failed to create runner: %v", err)
    }
```

```java
import com.google.adk.agents.LlmAgent;

LlmAgent storyGenerator = LlmAgent.builder()
    .name("StoryGenerator")
    .model("gemini-flash-latest")
    .instruction("Write a short story about a cat, focusing on the theme: " + topic)
    .build();

// Assuming session.state().put("topic", "friendship"), the LLM
// will receive the following instruction:
// "Write a short story about a cat, focusing on the theme: friendship."
```

#### Important Considerations

- Key Existence: Ensure that the key you reference in the instruction string exists in the session.state. If the key is missing, the agent will throw an error. To use a key that may or may not be present, you can include a question mark (?) after the key (e.g. {topic?}).
- Data Types: The value associated with the key should be a string or a type that can be easily converted to a string.
- Literal Curly Braces: The `{key}` syntax matches any valid Python identifier inside single curly braces. If you need literal curly braces in your instruction, such as for JSON formatting or templating syntax, use an `InstructionProvider` function instead of a string (see below).

f-strings and double braces

Some ADK examples use Python f-strings in instructions, such as `f"Topic: {{initial_topic}}"`. The `{{` and `}}` in those examples are **Python f-string escaping**, not ADK syntax. At runtime, Python converts `{{initial_topic}}` to `{initial_topic}`, which ADK then treats as a normal state variable placeholder. If you are not using f-strings, use single braces `{key}` directly.

#### Using `InstructionProvider` for Full Control

In some cases, you may need full control over the instruction string — for example, when your instructions contain literal curly braces (e.g., JSON examples, templating syntax) that would otherwise be interpreted as state variable placeholders.

To achieve this, provide a function to the `instruction` parameter instead of a string. This function is called an `InstructionProvider`. When you use an `InstructionProvider`, the ADK will **not** attempt to inject state variables, and the returned string will be passed to the model as-is.

The `InstructionProvider` function receives a `ReadonlyContext` object, which you can use to access session state or other contextual information if you need to build the instruction dynamically.

```python
from google.adk.agents import LlmAgent
from google.adk.agents.readonly_context import ReadonlyContext

# This is an InstructionProvider
def my_instruction_provider(context: ReadonlyContext) -> str:
    # No state injection occurs — curly braces are treated as literal text.
    return 'Format your output as JSON: {"city": "<name>", "population": <number>}'

agent = LlmAgent(
    model="gemini-flash-latest",
    name="template_helper_agent",
    instruction=my_instruction_provider
)
```

```typescript
import { LlmAgent, ReadonlyContext } from "@google/adk";

// This is an InstructionProvider
function myInstructionProvider(context: ReadonlyContext): string {
    // No state injection occurs — curly braces are treated as literal text.
    return 'Format your output as JSON: {"city": "<name>", "population": <number>}';
}

const agent = new LlmAgent({
    model: "gemini-flash-latest",
    name: "template_helper_agent",
    instruction: myInstructionProvider
});
```

```go
//  1. This InstructionProvider returns a static string.
//     Because it's a provider function, the ADK will not attempt to inject
//     state, and the instruction will be passed to the model as-is,
//     preserving the literal braces.
func staticInstructionProvider(ctx agent.ReadonlyContext) (string, error) {
    return "This is an instruction with {{literal_braces}} that will not be replaced.", nil
}
```

```java
import com.google.adk.agents.Instruction;
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.ReadonlyContext;
import io.reactivex.rxjava3.core.Single;

// This is an Instruction.Provider
Instruction.Provider myInstructionProvider = new Instruction.Provider(
    (ReadonlyContext context) -> {
        // No state injection occurs — curly braces are treated as literal text.
        return Single.just("Format your output as JSON: {\"city\": \"<name>\", \"population\": <number>}");
    }
);

LlmAgent agent = LlmAgent.builder()
    .model("gemini-flash-latest")
    .name("template_helper_agent")
    .instruction(myInstructionProvider)
    .build();
```

If you want to both use an `InstructionProvider` *and* inject state into your instructions, you can use the `inject_session_state` utility function. Only `{key}` placeholders matching valid state variable names will be replaced; other text (including curly braces that don't match valid identifiers) will be left as-is.

```python
from google.adk.agents import LlmAgent
from google.adk.agents.readonly_context import ReadonlyContext
from google.adk.utils import instructions_utils

async def my_dynamic_instruction_provider(context: ReadonlyContext) -> str:
    template = "This is a {adjective} instruction. Use JSON like: {\"key\": \"value\"}."
    # This will inject the 'adjective' state variable.
    # The JSON braces are left alone because their content is not a valid identifier.
    return await instructions_utils.inject_session_state(template, context)

agent = LlmAgent(
    model="gemini-flash-latest",
    name="dynamic_template_helper_agent",
    instruction=my_dynamic_instruction_provider
)
```

```go
//  2. This InstructionProvider demonstrates how to manually inject state
//     while also preserving literal braces. It uses the instructionutil helper.
func dynamicInstructionProvider(ctx agent.ReadonlyContext) (string, error) {
    template := "This is a {adjective} instruction with {{literal_braces}}."
    // This will inject the 'adjective' state variable but leave the literal braces.
    return instructionutil.InjectSessionState(ctx, template)
}
```

```java
import com.google.adk.agents.Instruction;
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.ReadonlyContext;
import com.google.adk.utils.InstructionUtils;
import io.reactivex.rxjava3.core.Single;

Instruction.Provider myDynamicInstructionProvider = new Instruction.Provider(
    (ReadonlyContext context) -> {
        String template = "This is a " + adjective + " instruction. Use JSON like: {\"key\": \"value\"}.";
        // This will inject the 'adjective' state variable.
        // The JSON braces are left alone because their content is not a valid identifier.
        return InstructionUtils.injectSessionState(context.invocationContext(), template);
    }
);

LlmAgent agent = LlmAgent.builder()
    .model("gemini-flash-latest")
    .name("dynamic_template_helper_agent")
    .instruction(myDynamicInstructionProvider)
    .build();
```

**Benefits of Direct Injection**

- Clarity: Makes it explicit which parts of the instruction are dynamic and based on session state.
- Reliability: Avoids relying on the LLM to correctly interpret natural language instructions to access state.
- Maintainability: Simplifies instruction strings and reduces the risk of errors when updating state variable names.

**Relation to Other State Access Methods**

This direct injection method is specific to LlmAgent instructions. Refer to the following section for more information on other state access methods.

### How State is Updated: Recommended Methods

The Right Way to Modify State

When you need to change the session state, the correct and safest method is to **directly modify the `state` object on the `Context`** provided to your function (e.g., `callback_context.state['my_key'] = 'new_value'`). This is considered "direct state manipulation" in the right way, as the framework automatically tracks these changes.

This is critically different from directly modifying the `state` on a `Session` object you retrieve from the `SessionService` (e.g., `my_session.state['my_key'] = 'new_value'`). **You should avoid this**, as it bypasses the ADK's event tracking and can lead to lost data. The "Warning" section at the end of this page has more details on this important distinction.

State should **always** be updated as part of adding an `Event` to the session history using `session_service.append_event()`. This ensures changes are tracked, persistence works correctly, and updates are thread-safe.

**1. The Easy Way: `output_key` (for Agent Text Responses)**

This is the simplest method for saving an agent's final text response directly into the state. When defining your `LlmAgent`, specify the `output_key`:

```py
from google.adk.agents import LlmAgent
from google.adk.sessions import InMemorySessionService, Session
from google.adk.runners import Runner
from google.genai.types import Content, Part

# Define agent with output_key
greeting_agent = LlmAgent(
    name="Greeter",
    model="gemini-flash-latest", # Use a valid model
    instruction="Generate a short, friendly greeting.",
    output_key="last_greeting" # Save response to state['last_greeting']
)

# --- Setup Runner and Session ---
app_name, user_id, session_id = "state_app", "user1", "session1"
session_service = InMemorySessionService()
runner = Runner(
    agent=greeting_agent,
    app_name=app_name,
    session_service=session_service
)
session = await session_service.create_session(app_name=app_name,
                                    user_id=user_id,
                                    session_id=session_id)
print(f"Initial state: {session.state}")

# --- Run the Agent ---
# Runner handles calling append_event, which uses the output_key
# to automatically create the state_delta.
user_message = Content(parts=[Part(text="Hello")])
for event in runner.run(user_id=user_id,
                        session_id=session_id,
                        new_message=user_message):
    if event.is_final_response():
      print(f"Agent responded.") # Response text is also in event.content

# --- Check Updated State ---
updated_session = await session_service.get_session(app_name=APP_NAME, user_id=USER_ID, session_id=session_id)
print(f"State after agent run: {updated_session.state}")
# Expected output might include: {'last_greeting': 'Hello there! How can I help you today?'}
```

```typescript
import { LlmAgent, Runner, InMemorySessionService, isFinalResponse } from "@google/adk";
import { Content } from "@google/genai";

// Define agent with outputKey
const greetingAgent = new LlmAgent({
    name: "Greeter",
    model: "gemini-flash-latest",
    instruction: "Generate a short, friendly greeting.",
    outputKey: "last_greeting" // Save response to state['last_greeting']
});

// --- Setup Runner and Session ---
const appName = "state_app";
const userId = "user1";
const sessionId = "session1";
const sessionService = new InMemorySessionService();
const runner = new Runner({
    agent: greetingAgent,
    appName: appName,
    sessionService: sessionService
});
const session = await sessionService.createSession({
    appName,
    userId,
    sessionId
});
console.log(`Initial state: ${JSON.stringify(session.state)}`);

// --- Run the Agent ---
// Runner handles calling appendEvent, which uses the outputKey
// to automatically create the stateDelta.
const userMessage: Content = { parts: [{ text: "Hello" }] };
for await (const event of runner.runAsync({
    userId,
    sessionId,
    newMessage: userMessage
})) {
    if (isFinalResponse(event)) {
      console.log("Agent responded."); // Response text is also in event.content
    }
}

// --- Check Updated State ---
const updatedSession = await sessionService.getSession({ appName, userId, sessionId });
console.log(`State after agent run: ${JSON.stringify(updatedSession?.state)}`);
// Expected output might include: {"last_greeting":"Hello there! How can I help you today?"}
```

```go
//  1. GreetingAgent demonstrates using `OutputKey` to save an agent's
//     final text response directly into the session state.
func greetingAgentExample(sessionService session.Service) {
    fmt.Println("--- Running GreetingAgent (output_key) Example ---")
    ctx := context.Background()

    modelGreeting, err := gemini.NewModel(ctx, modelID, nil)
    if err != nil {
        log.Fatalf("Failed to create Gemini model for greeting agent: %v", err)
    }
    greetingAgent, err := llmagent.New(llmagent.Config{
        Name:        "Greeter",
        Model:       modelGreeting,
        Instruction: "Generate a short, friendly greeting.",
        OutputKey:   "last_greeting",
    })
    if err != nil {
        log.Fatalf("Failed to create greeting agent: %v", err)
    }

    r, err := runner.New(runner.Config{
        AppName:        appName,
        Agent:          agent.Agent(greetingAgent),
        SessionService: sessionService,
    })
    if err != nil {
        log.Fatalf("Failed to create runner: %v", err)
    }

    // Run the agent
    userMessage := genai.NewContentFromText("Hello", "user")
    for event, err := range r.Run(ctx, userID, sessionID, userMessage, agent.RunConfig{}) {
        if err != nil {
            log.Printf("Agent Error: %v", err)
            continue
        }
        if isFinalResponse(event) {
            if event.LLMResponse.Content != nil {
                fmt.Printf("Agent responded with: %q\n", textParts(event.LLMResponse.Content))
            } else {
                fmt.Println("Agent responded.")
            }
        }
    }

    // Check the updated state
    resp, err := sessionService.Get(ctx, &session.GetRequest{AppName: appName, UserID: userID, SessionID: sessionID})
    if err != nil {
        log.Fatalf("Failed to get session: %v", err)
    }
    lastGreeting, _ := resp.Session.State().Get("last_greeting")
    fmt.Printf("State after agent run: last_greeting = %q\n\n", lastGreeting)
}
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.RunConfig;
import com.google.adk.events.Event;
import com.google.adk.runner.Runner;
import com.google.adk.sessions.InMemorySessionService;
import com.google.adk.sessions.Session;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import java.util.List;
import java.util.Optional;

public class GreetingAgentExample {

  public static void main(String[] args) {
    // Define agent with output_key
    LlmAgent greetingAgent =
        LlmAgent.builder()
            .name("Greeter")
            .model("gemini-2.5-flash")
            .instruction("Generate a short, friendly greeting.")
            .description("Greeting agent")
            .outputKey("last_greeting") // Save response to state['last_greeting']
            .build();

    // --- Setup Runner and Session ---
    String appName = "state_app";
    String userId = "user1";
    String sessionId = "session1";

    InMemorySessionService sessionService = new InMemorySessionService();
    Runner runner = Runner.builder()
      .agent(greetingAgent)
      .appName(appName)
      .sessionService(sessionService)
      .build();

    Session session =
        sessionService.createSession(appName, userId, null, sessionId).blockingGet();
    System.out.println("Initial state: " + session.state().entrySet());

    // --- Run the Agent ---
    // Runner handles calling appendEvent, which uses the output_key
    // to automatically create the stateDelta.
    Content userMessage = Content.builder().parts(List.of(Part.fromText("Hello"))).build();

    // RunConfig is needed for runner.runAsync in Java
    RunConfig runConfig = RunConfig.builder().build();

    for (Event event : runner.runAsync(userId, sessionId, userMessage, runConfig).blockingIterable()) {
      if (event.finalResponse()) {
        System.out.println("Agent responded."); // Response text is also in event.content
      }
    }

    // --- Check Updated State ---
    Session updatedSession =
        sessionService.getSession(appName, userId, sessionId, Optional.empty()).blockingGet();
    assert updatedSession != null;
    System.out.println("State after agent run: " + updatedSession.state().entrySet());
    // Expected output might include: {'last_greeting': 'Hello there! How can I help you today?'}
  }
}
```

Behind the scenes, the `Runner` uses the `output_key` to create the necessary `EventActions` with a `state_delta` and calls `append_event`.

**2. The Standard Way: `EventActions.state_delta` (for Complex Updates)**

For more complex scenarios (updating multiple keys, non-string values, specific scopes like `user:` or `app:`, or updates not tied directly to the agent's final text), you manually construct the `state_delta` within `EventActions`.

```py
from google.adk.sessions import InMemorySessionService, Session
from google.adk.events import Event, EventActions
from google.genai.types import Part, Content
import time

# --- Setup ---
session_service = InMemorySessionService()
app_name, user_id, session_id = "state_app_manual", "user2", "session2"
session = await session_service.create_session(
    app_name=app_name,
    user_id=user_id,
    session_id=session_id,
    state={"user:login_count": 0, "task_status": "idle"}
)
print(f"Initial state: {session.state}")

# --- Define State Changes ---
current_time = time.time()
state_changes = {
    "task_status": "active",              # Update session state
    "user:login_count": session.state.get("user:login_count", 0) + 1, # Update user state
    "user:last_login_ts": current_time,   # Add user state
    "temp:validation_needed": True        # Add temporary state (will be discarded)
}

# --- Create Event with Actions ---
actions_with_update = EventActions(state_delta=state_changes)
# This event might represent an internal system action, not just an agent response
system_event = Event(
    invocation_id="inv_login_update",
    author="system", # Or 'agent', 'tool' etc.
    actions=actions_with_update,
    timestamp=current_time
    # content might be None or represent the action taken
)

# --- Append the Event (This updates the state) ---
await session_service.append_event(session, system_event)
print("`append_event` called with explicit state delta.")

# --- Check Updated State ---
updated_session = await session_service.get_session(app_name=app_name,
                                            user_id=user_id,
                                            session_id=session_id)
print(f"State after event: {updated_session.state}")
# Expected: {'user:login_count': 1, 'task_status': 'active', 'user:last_login_ts': <timestamp>}
# Note: 'temp:validation_needed' is NOT present.
```

```typescript
import { InMemorySessionService, createEvent, createEventActions } from "@google/adk";

// --- Setup ---
const sessionService = new InMemorySessionService();
const appName = "state_app_manual";
const userId = "user2";
const sessionId = "session2";
const session = await sessionService.createSession({
    appName,
    userId,
    sessionId,
    state: { "user:login_count": 0, "task_status": "idle" }
});
console.log(`Initial state: ${JSON.stringify(session.state)}`);

// --- Define State Changes ---
const currentTime = Date.now();
const stateChanges = {
    "task_status": "active",              // Update session state
    "user:login_count": (session.state["user:login_count"] as number || 0) + 1, // Update user state
    "user:last_login_ts": currentTime,   // Add user state
    "temp:validation_needed": true        // Add temporary state (will be discarded)
};

// --- Create Event with Actions ---
const actionsWithUpdate = createEventActions({
    stateDelta: stateChanges,
});
// This event might represent an internal system action, not just an agent response
const systemEvent = createEvent({
    invocationId: "inv_login_update",
    author: "system", // Or 'agent', 'tool' etc.
    actions: actionsWithUpdate,
    timestamp: currentTime
    // content might be null or represent the action taken
});

// --- Append the Event (This updates the state) ---
await sessionService.appendEvent({ session, event: systemEvent });
console.log("`appendEvent` called with explicit state delta.");

// --- Check Updated State ---
const updatedSession = await sessionService.getSession({
    appName,
    userId,
    sessionId
});
console.log(`State after event: ${JSON.stringify(updatedSession?.state)}`);
// Expected: {"user:login_count":1,"task_status":"active","user:last_login_ts":<timestamp>}
// Note: 'temp:validation_needed' is NOT present.
```

```go
//  2. manualStateUpdateExample demonstrates creating an event with explicit
//     state changes (a "state_delta") to update multiple keys, including
//     those with user- and temp- prefixes.
func manualStateUpdateExample(sessionService session.Service) {
    fmt.Println("--- Running Manual State Update (EventActions) Example ---")
    ctx := context.Background()
    s, err := sessionService.Get(ctx, &session.GetRequest{AppName: appName, UserID: userID, SessionID: sessionID})
    if err != nil {
        log.Fatalf("Failed to get session: %v", err)
    }
    retrievedSession := s.Session

    // Define state changes
    loginCount, _ := retrievedSession.State().Get("user:login_count")
    newLoginCount := 1
    if lc, ok := loginCount.(int); ok {
        newLoginCount = lc + 1
    }

    stateChanges := map[string]any{
        "task_status":            "active",
        "user:login_count":       newLoginCount,
        "user:last_login_ts":     time.Now().Unix(),
        "temp:validation_needed": true,
    }

    // Create an event with the state changes
    systemEvent := session.NewEvent("inv_login_update")
    systemEvent.Author = "system"
    systemEvent.Actions.StateDelta = stateChanges

    // Append the event to update the state
    if err := sessionService.AppendEvent(ctx, retrievedSession, systemEvent); err != nil {
        log.Fatalf("Failed to append event: %v", err)
    }
    fmt.Println("`append_event` called with explicit state delta.")

    // Check the updated state
    updatedResp, err := sessionService.Get(ctx, &session.GetRequest{AppName: appName, UserID: userID, SessionID: sessionID})
    if err != nil {
        log.Fatalf("Failed to get session: %v", err)
    }
    taskStatus, _ := updatedResp.Session.State().Get("task_status")
    loginCount, _ = updatedResp.Session.State().Get("user:login_count")
    lastLogin, _ := updatedResp.Session.State().Get("user:last_login_ts")
    temp, err := updatedResp.Session.State().Get("temp:validation_needed") // This should fail or be nil

    fmt.Printf("State after event: task_status=%q, user:login_count=%v, user:last_login_ts=%v\n", taskStatus, loginCount, lastLogin)
    if err != nil {
        fmt.Printf("As expected, temp state was not persisted: %v\n\n", err)
    } else {
        fmt.Printf("Unexpected temp state value: %v\n\n", temp)
    }
}
```

```java
import com.google.adk.events.Event;
import com.google.adk.events.EventActions;
import com.google.adk.sessions.InMemorySessionService;
import com.google.adk.sessions.Session;
import java.time.Instant;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

public class ManualStateUpdateExample {

  public static void main(String[] args) {
    // --- Setup ---
    InMemorySessionService sessionService = new InMemorySessionService();
    String appName = "state_app_manual";
    String userId = "user2";
    String sessionId = "session2";

    ConcurrentMap<String, Object> initialState = new ConcurrentHashMap<>();
    initialState.put("user:login_count", 0);
    initialState.put("task_status", "idle");

    Session session =
        sessionService.createSession(appName, userId, initialState, sessionId).blockingGet();
    System.out.println("Initial state: " + session.state().entrySet());

    // --- Define State Changes ---
    long currentTimeMillis = Instant.now().toEpochMilli(); // Use milliseconds for Java Event

    ConcurrentMap<String, Object> stateChanges = new ConcurrentHashMap<>();
    stateChanges.put("task_status", "active"); // Update session state

    // Retrieve and increment login_count
    Object loginCountObj = session.state().get("user:login_count");
    int currentLoginCount = 0;
    if (loginCountObj instanceof Number) {
      currentLoginCount = ((Number) loginCountObj).intValue();
    }
    stateChanges.put("user:login_count", currentLoginCount + 1); // Update user state

    stateChanges.put("user:last_login_ts", currentTimeMillis); // Add user state (as long milliseconds)
    stateChanges.put("temp:validation_needed", true); // Add temporary state

    // --- Create Event with Actions ---
    EventActions actionsWithUpdate = EventActions.builder().stateDelta(stateChanges).build();

    // This event might represent an internal system action, not just an agent response
    Event systemEvent =
        Event.builder()
            .invocationId("inv_login_update")
            .author("system") // Or 'agent', 'tool' etc.
            .actions(actionsWithUpdate)
            .timestamp(currentTimeMillis)
            // content might be None or represent the action taken
            .build();

    // --- Append the Event (This updates the state) ---
    sessionService.appendEvent(session, systemEvent).blockingGet();
    System.out.println("`appendEvent` called with explicit state delta.");

    // --- Check Updated State ---
    Session updatedSession =
        sessionService.getSession(appName, userId, sessionId, Optional.empty()).blockingGet();
    assert updatedSession != null;
    System.out.println("State after event: " + updatedSession.state().entrySet());
    // Expected: {'user:login_count': 1, 'task_status': 'active', 'user:last_login_ts': <timestamp_millis>}
    // Note: 'temp:validation_needed' is NOT present because InMemorySessionService's appendEvent
    // applies delta to its internal user/app state maps IF keys have prefixes,
    // and to the session's own state map (which is then merged on getSession).
  }
}
```

**3. Via `CallbackContext` or `ToolContext` (Recommended for Callbacks and Tools)**

*(Note: In TypeScript, this is done via the unified `Context` type.)*

Modifying state within agent callbacks (e.g., `on_before_agent_call`, `on_after_agent_call`) or tool functions is best done using the `state` attribute of the `CallbackContext` or `ToolContext` provided to your function.

- `callback_context.state['my_key'] = my_value`
- `tool_context.state['my_key'] = my_value`

These context objects are specifically designed to manage state changes within their respective execution scopes. When you modify `context.state`, the ADK framework ensures that these changes are automatically captured and correctly routed into the `EventActions.state_delta` for the event being generated by the callback or tool. This delta is then processed by the `SessionService` when the event is appended, ensuring proper persistence and tracking.

This method abstracts away the manual creation of `EventActions` and `state_delta` for most common state update scenarios within callbacks and tools, making your code cleaner and less error-prone.

For more comprehensive details on context objects, refer to the [Context documentation](https://adk.dev/context/index.md).

```python
# In an agent callback or tool function
from google.adk.agents import CallbackContext # or ToolContext

def my_callback_or_tool_function(context: CallbackContext, # Or ToolContext
                                 # ... other parameters ...
                                ):
    # Update existing state
    count = context.state.get("user_action_count", 0)
    context.state["user_action_count"] = count + 1

    # Add new state
    context.state["temp:last_operation_status"] = "success"

    # State changes are automatically part of the event's state_delta
    # ... rest of callback/tool logic ...
```

```typescript
// In an agent callback or tool function
import { Context } from "@google/adk";

function myCallbackOrToolFunction(
    context: Context,
    // ... other parameters ...
) {
    // Update existing state
    const count = context.state.get("user_action_count", 0);
    context.state.set("user_action_count", count + 1);

    // Add new state
    context.state.set("temp:last_operation_status", "success");

    // State changes are automatically part of the event's stateDelta
    // ... rest of callback/tool logic ...
}
```

```go
//  3. contextStateUpdateExample demonstrates the recommended way to modify state
//     from within a tool function using the provided `tool.Context`.
func contextStateUpdateExample(sessionService session.Service) {
    fmt.Println("--- Running Context State Update (ToolContext) Example ---")
    ctx := context.Background()

    // Define the tool that modifies state
    updateActionCountTool, err := functiontool.New(
        functiontool.Config{Name: "update_action_count", Description: "Updates the user action count in the state."},
        func(tctx tool.Context, args struct{}) (struct{}, error) {
            actx, ok := tctx.(agent.CallbackContext)
            if !ok {
                log.Fatalf("tool.Context is not of type agent.CallbackContext")
            }
            s, err := actx.State().Get("user_action_count")
            if err != nil {
                log.Printf("could not get user_action_count: %v", err)
            }
            newCount := 1
            if c, ok := s.(int); ok {
                newCount = c + 1
            }
            if err := actx.State().Set("user_action_count", newCount); err != nil {
                log.Printf("could not set user_action_count: %v", err)
            }
            if err := actx.State().Set("temp:last_operation_status", "success from tool"); err != nil {
                log.Printf("could not set temp:last_operation_status: %v", err)
            }
            fmt.Println("Tool: Updated state via agent.CallbackContext.")
            return struct{}{}, nil
        },
    )
    if err != nil {
        log.Fatalf("Failed to create tool: %v", err)
    }

    // Define an agent that uses the tool
    modelTool, err := gemini.NewModel(ctx, modelID, nil)
    if err != nil {
        log.Fatalf("Failed to create Gemini model for tool agent: %v", err)
    }
    toolAgent, err := llmagent.New(llmagent.Config{
        Name:        "ToolAgent",
        Model:       modelTool,
        Instruction: "Use the update_action_count tool.",
        Tools:       []tool.Tool{updateActionCountTool},
    })
    if err != nil {
        log.Fatalf("Failed to create tool agent: %v", err)
    }

    r, err := runner.New(runner.Config{
        AppName:        appName,
        Agent:          agent.Agent(toolAgent),
        SessionService: sessionService,
    })
    if err != nil {
        log.Fatalf("Failed to create runner: %v", err)
    }

    // Run the agent to trigger the tool
    userMessage := genai.NewContentFromText("Please update the action count.", "user")
    for _, err := range r.Run(ctx, userID, sessionID, userMessage, agent.RunConfig{}) {
        if err != nil {
            log.Printf("Agent Error: %v", err)
        }
    }

    // Check the updated state
    resp, err := sessionService.Get(ctx, &session.GetRequest{AppName: appName, UserID: userID, SessionID: sessionID})
    if err != nil {
        log.Fatalf("Failed to get session: %v", err)
    }
    actionCount, _ := resp.Session.State().Get("user_action_count")
    fmt.Printf("State after tool run: user_action_count = %v\n", actionCount)
}
```

```java
// In an agent callback or tool method
import com.google.adk.agents.CallbackContext; // or ToolContext
// ... other imports ...

public class MyAgentCallbacks {
    public void onAfterAgent(CallbackContext callbackContext) {
        // Update existing state
        Integer count = (Integer) callbackContext.state().getOrDefault("user_action_count", 0);
        callbackContext.state().put("user_action_count", count + 1);

        // Add new state
        callbackContext.state().put("temp:last_operation_status", "success");

        // State changes are automatically part of the event's state_delta
        // ... rest of callback logic ...
    }
}
```

**What `append_event` Does:**

- Adds the `Event` to `session.events`.
- Reads the `state_delta` from the event's `actions`.
- Applies these changes to the state managed by the `SessionService`, correctly handling prefixes and persistence based on the service type.
- Updates the session's `last_update_time`.
- Ensures thread-safety for concurrent updates.

### ⚠️ A Warning About Direct State Modification

Avoid directly modifying the `session.state` collection (dictionary/Map) on a `Session` object that was obtained directly from the `SessionService` (e.g., via `session_service.get_session()` or `session_service.create_session()`) *outside* of the managed lifecycle of an agent invocation (i.e., not through a `CallbackContext` or `ToolContext`). For example, code like `retrieved_session = await session_service.get_session(...); retrieved_session.state['key'] = value` is problematic.

State modifications *within* callbacks or tools using `CallbackContext.state` or `ToolContext.state` are the correct way to ensure changes are tracked, as these context objects handle the necessary integration with the event system.

**Why direct modification (outside of contexts) is strongly discouraged:**

1. **Bypasses Event History:** The change isn't recorded as an `Event`, losing auditability.
1. **Breaks Persistence:** Changes made this way **will likely NOT be saved** by `DatabaseSessionService` or `VertexAiSessionService`. They rely on `append_event` to trigger saving.
1. **Not Thread-Safe:** Can lead to race conditions and lost updates.
1. **Ignores Timestamps/Logic:** Doesn't update `last_update_time` or trigger related event logic.

**Recommendation:** Stick to updating state via `output_key`, `EventActions.state_delta` (when manually creating events), or by modifying the `state` property of `CallbackContext` or `ToolContext` objects when within their respective scopes. These methods ensure reliable, trackable, and persistent state management. Use direct access to `session.state` (from a `SessionService`-retrieved session) only for *reading* state.

### Best Practices for State Design Recap

- **Minimalism:** Store only essential, dynamic data.
- **Serialization:** Use basic, serializable types.
- **Descriptive Keys & Prefixes:** Use clear names and appropriate prefixes (`user:`, `app:`, `temp:`, or none).
- **Shallow Structures:** Avoid deep nesting where possible.
- **Standard Update Flow:** Rely on `append_event`.

# Session: Tracking Individual Conversations

Supported in ADKPython v0.1.0Typescript v0.2.0Go v0.1.0Java v0.1.0

Following our Introduction, let's dive into the `Session`. Think back to the idea of a "conversation thread." Just like you wouldn't start every text message from scratch, agents need context regarding the ongoing interaction. **`Session`** is the ADK object designed specifically to track and manage these individual conversation threads.

## The `Session` Object

When a user starts interacting with your agent, the `SessionService` creates a `Session` object (`google.adk.sessions.Session`). This object acts as the container holding everything related to that *one specific chat thread*. Here are its key properties:

- **Identification (`id`, `appName`, `userId`):** Unique labels for the conversation.
  - `id`: A unique identifier for *this specific* conversation thread, essential for retrieving it later. A SessionService object can handle multiple `Session`(s). This field identifies which particular session object are we referring to. For example, "test_id_modification".
  - `app_name`: Identifies which agent application this conversation belongs to. For example, "id_modifier_workflow".
  - `userId`: Links the conversation to a particular user.
- **History (`events`):** A chronological sequence of all interactions (`Event` objects – user messages, agent responses, tool actions) that have occurred within this specific thread.
- **Session State (`state`):** A place to store temporary data relevant *only* to this specific, ongoing conversation. This acts as a scratchpad for the agent during the interaction. We will cover how to use and manage `state` in detail in the next section.
- **Activity Tracking (`lastUpdateTime`):** A timestamp indicating the last time an event occurred in this conversation thread.

### Example: Examining Session Properties

```py
 from google.adk.sessions import InMemorySessionService, Session

 # Create a simple session to examine its properties
 temp_service = InMemorySessionService()
 example_session = await temp_service.create_session(
     app_name="my_app",
     user_id="example_user",
     state={"initial_key": "initial_value"} # State can be initialized
 )

 print(f"--- Examining Session Properties ---")
 print(f"ID (`id`):                {example_session.id}")
 print(f"Application Name (`app_name`): {example_session.app_name}")
 print(f"User ID (`user_id`):         {example_session.user_id}")
 print(f"State (`state`):           {example_session.state}") # Note: Only shows initial state here
 print(f"Events (`events`):         {example_session.events}") # Initially empty
 print(f"Last Update (`last_update_time`): {example_session.last_update_time:.2f}")
 print(f"---------------------------------")

 # Clean up (optional for this example)
 await temp_service.delete_session(app_name=example_session.app_name,
                             user_id=example_session.user_id, session_id=example_session.id)
 print("The final status of temp_service - ", temp_service)
```

```typescript
 import { InMemorySessionService } from "@google/adk";

 // Create a simple session to examine its properties
 const tempService = new InMemorySessionService();
 const exampleSession = await tempService.createSession({
     appName: "my_app",
     userId: "example_user",
     state: {"initial_key": "initial_value"} // State can be initialized
 });

 console.log("--- Examining Session Properties ---");
 console.log(`ID ('id'):                ${exampleSession.id}`);
 console.log(`Application Name ('appName'): ${exampleSession.appName}`);
 console.log(`User ID ('userId'):         ${exampleSession.userId}`);
 console.log(`State ('state'):           ${JSON.stringify(exampleSession.state)}`); // Note: Only shows initial state here
 console.log(`Events ('events'):         ${JSON.stringify(exampleSession.events)}`); // Initially empty
 console.log(`Last Update ('lastUpdateTime'): ${exampleSession.lastUpdateTime}`);
 console.log("---------------------------------");

 // Clean up (optional for this example)
 const finalStatus = await tempService.deleteSession({
     appName: exampleSession.appName,
     userId: exampleSession.userId,
     sessionId: exampleSession.id
 });
 console.log("The final status of temp_service - ", finalStatus);
```

```go
appName := "my_go_app"
userID := "example_go_user"
initialState := map[string]any{"initial_key": "initial_value"}

// Create a session to examine its properties.
createResp, err := inMemoryService.Create(ctx, &session.CreateRequest{
 AppName: appName,
 UserID:  userID,
 State:   initialState,
})
if err != nil {
 log.Fatalf("Failed to create session: %v", err)
}
exampleSession := createResp.Session

fmt.Println("\n--- Examining Session Properties ---")
fmt.Printf("ID (`ID()`): %s\n", exampleSession.ID())
fmt.Printf("Application Name (`AppName()`): %s\n", exampleSession.AppName())
// To access state, you call Get().
val, _ := exampleSession.State().Get("initial_key")
fmt.Printf("State (`State().Get()`):    initial_key = %v\n", val)

// Events are initially empty.
fmt.Printf("Events (`Events().Len()`):  %d\n", exampleSession.Events().Len())
fmt.Printf("Last Update (`LastUpdateTime()`): %s\n", exampleSession.LastUpdateTime().Format("2006-01-02 15:04:05"))
fmt.Println("---------------------------------")

// Clean up the session.
err = inMemoryService.Delete(ctx, &session.DeleteRequest{
 AppName:   exampleSession.AppName(),
 UserID:    exampleSession.UserID(),
 SessionID: exampleSession.ID(),
})
if err != nil {
 log.Fatalf("Failed to delete session: %v", err)
}
fmt.Println("Session deleted successfully.")
```

```java
 import com.google.adk.sessions.InMemorySessionService;
 import com.google.adk.sessions.Session;
 import java.util.concurrent.ConcurrentMap;
 import java.util.concurrent.ConcurrentHashMap;

 String sessionId = "123";
 String appName = "example-app"; // Example app name
 String userId = "example-user"; // Example user id
 ConcurrentMap<String, Object> initialState = new ConcurrentHashMap<>(Map.of("newKey", "newValue"));
 InMemorySessionService exampleSessionService = new InMemorySessionService();

 // Create Session
 Session exampleSession = exampleSessionService.createSession(
     appName, userId, initialState, Optional.of(sessionId)).blockingGet();
 System.out.println("Session created successfully.");

 System.out.println("--- Examining Session Properties ---");
 System.out.printf("ID (`id`): %s%n", exampleSession.id());
 System.out.printf("Application Name (`appName`): %s%n", exampleSession.appName());
 System.out.printf("User ID (`userId`): %s%n", exampleSession.userId());
 System.out.printf("State (`state`): %s%n", exampleSession.state());
 System.out.println("------------------------------------");


 // Clean up (optional for this example)
 var unused = exampleSessionService.deleteSession(appName, userId, sessionId);
```

\*(\**Note:* *The state shown above is only the initial state. State updates happen via events, as discussed in the State section.)*

## Managing Sessions with a `SessionService`

As seen above, you don't typically create or manage `Session` objects directly. Instead, you use a **`SessionService`**. This service acts as the central manager responsible for the entire lifecycle of your conversation sessions.

Its core responsibilities include:

- **Starting New Conversations:** Creating fresh `Session` objects when a user begins an interaction.
- **Resuming Existing Conversations:** Retrieving a specific `Session` (using its ID) so the agent can continue where it left off.
- **Saving Progress:** Appending new interactions (`Event` objects) to a session's history. This is also the mechanism through which session `state` gets updated (more in the `State` section).
- **Listing Conversations:** Finding the active session threads for a particular user and application.
- **Cleaning Up:** Deleting `Session` objects and their associated data when conversations are finished or no longer needed.

## `SessionService` implementations

ADK provides different `SessionService` implementations, allowing you to choose the storage backend that best suits your needs:

### `InMemorySessionService`

- **How it works:** Stores all session data directly in the application's memory.
- **Persistence:** None. **All conversation data is lost if the application restarts.**
- **Requires:** Nothing extra.
- **Best for:** Quick development, local testing, examples, and scenarios where long-term persistence isn't required.

```py
  from google.adk.sessions import InMemorySessionService
  session_service = InMemorySessionService()
```

```typescript
  import { InMemorySessionService } from "@google/adk";
  const sessionService = new InMemorySessionService();
```

```go
  import "google.golang.org/adk/session"
  inMemoryService := session.InMemoryService()
```

```java
  import com.google.adk.sessions.InMemorySessionService;
  InMemorySessionService exampleSessionService = new InMemorySessionService();
```

### `VertexAiSessionService`

Supported in ADKPython v0.1.0Go v0.1.0Java v0.1.0

- **How it works:** Uses Google Cloud Agent Platform infrastructure via API calls for session management.
- **Persistence:** Yes. Data is managed reliably and scalably via [Agent Runtime](/deploy/agent-runtime/).
- **Requires:**
  - A Google Cloud project (`pip install vertexai`)
  - A Google Cloud storage bucket that can be configured by this [step](https://cloud.google.com/vertex-ai/docs/pipelines/configure-project#storage).
  - An Agent Runtime resource name/ID that can setup following this [tutorial](/deploy/agent-runtime/).
  - If you do not have a Google Cloud project and you want to try the VertexAiSessionService, see [Agent Platform Express Mode](/integrations/express-mode/).
- **Best for:** Scalable production applications deployed on Google Cloud, especially when integrating with other Agent Platform features.

```py
# Requires: pip install google-adk[vertexai]
# Plus GCP setup and authentication
from google.adk.sessions import VertexAiSessionService

PROJECT_ID = "your-gcp-project-id"
LOCATION = "us-central1"
# The app_name used with this service should be the Reasoning Engine ID or name
REASONING_ENGINE_APP_NAME = "projects/your-gcp-project-id/locations/us-central1/reasoningEngines/your-engine-id"

session_service = VertexAiSessionService(project=PROJECT_ID, location=LOCATION)
# Use REASONING_ENGINE_APP_NAME when calling service methods, e.g.:
# session_service = await session_service.create_session(app_name=REASONING_ENGINE_APP_NAME, ...)
```

```go
import "google.golang.org/adk/session"

// 2. VertexAIService
// Before running, ensure your environment is authenticated:
// gcloud auth application-default login
// export GOOGLE_CLOUD_PROJECT="your-gcp-project-id"
// export GOOGLE_CLOUD_LOCATION="your-gcp-location"

modelName := "gemini-flash-latest" // Replace with your desired model
vertexService, err := session.VertexAIService(ctx, modelName)
if err != nil {
  log.Printf("Could not initialize VertexAIService (this is expected if the gcloud project is not set): %v", err)
} else {
  fmt.Println("Successfully initialized VertexAIService.")
}
```

```java
// Please look at the set of requirements above, consequently export the following in your bashrc file:
// export GOOGLE_CLOUD_PROJECT=my_gcp_project
// export GOOGLE_CLOUD_LOCATION=us-central1
// export GOOGLE_API_KEY=my_api_key

import com.google.adk.sessions.VertexAiSessionService;
import java.util.UUID;

String sessionId = UUID.randomUUID().toString();
String reasoningEngineAppName = "123456789";
String userId = "u_123"; // Example user id
ConcurrentMap<String, Object> initialState = new
    ConcurrentHashMap<>(); // No initial state needed for this example

VertexAiSessionService sessionService = new VertexAiSessionService();
Session mySession =
    sessionService
        .createSession(reasoningEngineAppName, userId, initialState, Optional.of(sessionId))
        .blockingGet();
```

### `DatabaseSessionService`

Supported in ADKPython v0.1.0Go v0.1.0

- **How it works:** Connects to a relational database (e.g., PostgreSQL, MySQL, SQLite) to store session data persistently in tables.
- **Persistence:** Yes. Data survives application restarts.
- **Requires:** A configured database.
- **Best for:** Applications needing reliable, persistent storage that you manage yourself.

```py
from google.adk.sessions import DatabaseSessionService
# Example using a local SQLite file:
# Note: The implementation requires an async database driver.
# For SQLite, use 'sqlite+aiosqlite' instead of 'sqlite' to ensure async compatibility.
db_url = "sqlite+aiosqlite:///./my_agent_data.db"
session_service = DatabaseSessionService(db_url=db_url)
```

Async Driver Requirement

`DatabaseSessionService` requires an async database driver. When using SQLite, you must use `sqlite+aiosqlite` instead of `sqlite` in your connection string. For other databases (PostgreSQL, MySQL), ensure you're using an async-compatible driver, such as `asyncpg` for PostgreSQL, `aiomysql` for MySQL.

Session database schema change in ADK Python v1.22.0

The schema for the session database changed in ADK Python v1.22.0, which requires migration of the Session Database. For more information, see [Session database schema migration](/sessions/session/migrate/).

## The Session Lifecycle

Here’s a simplified flow of how `Session` and `SessionService` work together during a conversation turn:

1. **Start or Resume:** Your application needs to use the `SessionService` to either `create_session` (for a new chat) or use an existing session id.
1. **Context Provided:** The `Runner` gets the appropriate `Session` object from the appropriate service method, providing the agent with access to the corresponding Session's `state` and `events`.
1. **Agent Processing:** The user prompts the agent with a query. The agent analyzes the query and potentially the session `state` and `events` history to determine the response.
1. **Response & State Update:** The agent generates a response (and potentially flags data to be updated in the `state`). The `Runner` packages this as an `Event`.
1. **Save Interaction:** The `Runner` calls `sessionService.append_event(session, event)` with the `session` and the new `event` as the arguments. The service adds the `Event` to the history and updates the session's `state` in storage based on information within the event. The session's `last_update_time` also get updated.
1. **Ready for Next:** The agent's response goes to the user. The updated `Session` is now stored by the `SessionService`, ready for the next turn (which restarts the cycle at step 1, usually with the continuation of the conversation in the current session).
1. **End Conversation:** When the conversation is over, your application calls `sessionService.delete_session(...)` to clean up the stored session data if it is no longer required.

This cycle highlights how the `SessionService` ensures conversational continuity by managing the history and state associated with each `Session` object.

# Session database schema migration

Supported in ADKPython v1.22.1

If you are using `DatabaseSessionService` and upgrading to ADK Python release v1.22.0 or higher, you should migrate your database to the new session database schema. Starting with ADK Python release v1.22.0, the database schema for `DatabaseSessionService` has been updated from `v0`, which is a pickle-based serialization, to `v1`, which uses JSON-based serialization. Previous `v0` session schema databases will continue to work with ADK Python v1.22.0 and higher versions, but the `v1` schema may be required in future releases.

## Migrate session database

A migration script is provided to facilitate the migration process. The script reads data from your existing database, converts it to the new format, and writes it to a new database. You can run the migration using the ADK Command Line Interface (CLI) `migrate session` command, as shown in the following examples:

Required: ADK Python v1.22.1 or higher

ADK Python v1.22.1 is required for this procedure because it includes the migration command line interface function and bug fixes to support the session database schema change.

```bash
adk migrate session \
  --source_db_url=sqlite:///source.db \
  --dest_db_url=sqlite:///dest.db
```

```bash
adk migrate session \
  --source_db_url=postgresql://localhost:5432/v0 \
  --dest_db_url=postgresql://localhost:5432/v1
```

After running the migration, update your `DatabaseSessionService` configuration to use the new database URL you specified for `dest_db_url`.

# Rewind sessions for agents

Supported in ADKPython v1.17.0

The ADK session Rewind feature allows you to revert a session to a previous request state, enabling you to undo mistakes, explore alternative paths, or restart a process from a known good point. This document provides an overview of the feature, how to use it, and its limitations.

## Rewind a session

When you rewind a session, you specify a user request, or ***invocation***, that you want to undo, and the system undoes that request and the requests after it. So if you have three requests (A, B, C) and you want to return to the state at request A, you specify B, which undoes the changes from requests B and C. You rewind a session by using the rewind method on a ***Runner*** instance, specifying the user, session, and invocation id, as shown in the following code snippet:

```python
# Create runner
runner = InMemoryRunner(
    agent=agent.root_agent,
    app_name=APP_NAME,
)

# Create a session
session = await runner.session_service.create_session(
    app_name=APP_NAME, user_id=USER_ID
)
# call agent with wrapper function "call_agent_async()"
await call_agent_async(
    runner, USER_ID, session.id, "set state color to red"
)
# ... more agent calls ...
events_list = await call_agent_async(
    runner, USER_ID, session.id, "update state color to blue"
)

# get invocation id
rewind_invocation_id=events_list[1].invocation_id

# rewind invocations (state color: red)
await runner.rewind_async(
    user_id=USER_ID,
    session_id=session.id,
    rewind_before_invocation_id=rewind_invocation_id,
)
```

When you call the ***rewind*** method, all ADK managed session-level resources are restored to the state they were in *before* the request you specified with the ***invocation id***. However, global resources, such as app-level or user-level state and artifacts, are not restored. For a complete example of an agent session rewind, see the [rewind_session](https://github.com/google/adk-python/tree/main/contributing/samples/rewind_session) sample code. For more information on the limitations of the Rewind feature, see [Limitations](#limitations).

## How it works

The Rewind feature creates a special ***rewind*** request that restores the session's state and artifacts to their condition *before* the rewind point specified by an invocation id. This approach means that all requests, including rewound requests, are preserved in the log for later debugging, analysis, or auditing. After the rewind, the system ignores the rewound requests when it prepares the next requests for the AI model. This behavior means the AI model used by the agent effectively forgets any interactions from the rewind point up to the next request.

## Limitations

The Rewind feature has some limitations that you should be aware of when using it with your agent workflow:

- **Global agent resources:** App-level and user-level state and artifacts are *not* restored by the rewind feature. Only session-level state and artifacts are restored.
- **External dependencies:** The rewind feature does not manage external dependencies. If a tool in your agent interacts with external systems, it is your responsibility to handle the restoration of those systems to their prior state.
- **Atomicity:** State updates, artifact updates, and event persistence are not performed in a single atomic transaction. Therefore, you should avoid rewinding active sessions or concurrently manipulating session artifacts during a rewind to prevent inconsistencies.

# Callbacks: Observe, Customize, and Control Agent Behavior

Supported in ADKPython v0.1.0TypeScript v0.2.0Go v0.1.0Java v0.1.0

Callbacks are a cornerstone feature of ADK, providing a powerful mechanism to hook into an agent's execution process. They allow you to observe, customize, and even control the agent's behavior at specific, predefined points without modifying the core ADK framework code.

**What are they?** In essence, callbacks are standard functions that you define. You then associate these functions with an agent when you create it. The ADK framework automatically calls your functions at key stages, letting you observe or intervene. Think of it like checkpoints during the agent's process:

- **Before the agent starts its main work on a request, and after it finishes:** When you ask an agent to do something (e.g., answer a question), it runs its internal logic to figure out the response.
- The `Before Agent` callback executes *right before* this main work begins for that specific request.
- The `After Agent` callback executes *right after* the agent has finished all its steps for that request and has prepared the final result, but just before the result is returned.
- This "main work" encompasses the agent's *entire* process for handling that single request. This might involve deciding to call an LLM, actually calling the LLM, deciding to use a tool, using the tool, processing the results, and finally putting together the answer. These callbacks essentially wrap the whole sequence from receiving the input to producing the final output for that one interaction.
- **Before sending a request to, or after receiving a response from, the Large Language Model (LLM):** These callbacks (`Before Model`, `After Model`) allow you to inspect or modify the data going to and coming from the LLM specifically.
- **Before executing a tool (like a Python function or another agent) or after it finishes:** Similarly, `Before Tool` and `After Tool` callbacks give you control points specifically around the execution of tools invoked by the agent.

**Why use them?** Callbacks unlock significant flexibility and enable advanced agent capabilities:

- **Observe & Debug:** Log detailed information at critical steps for monitoring and troubleshooting.
- **Customize & Control:** Modify data flowing through the agent (like LLM requests or tool results) or even bypass certain steps entirely based on your logic.
- **Implement Guardrails:** Enforce safety rules, validate inputs/outputs, or prevent disallowed operations.
- **Manage State:** Read or dynamically update the agent's session state during execution.
- **Integrate & Enhance:** Trigger external actions (API calls, notifications) or add features like caching.

Tip

When implementing security guardrails and policies, use ADK Plugins for better modularity and flexibility than Callbacks. For more details, see [Callbacks and Plugins for Security Guardrails](/safety/#callbacks-and-plugins-for-security-guardrails).

**How are they added:**

Code

```python
from google.adk.agents import LlmAgent
from google.adk.agents.callback_context import CallbackContext
from google.adk.models import LlmResponse, LlmRequest
from typing import Optional

# --- Define your callback function ---
def my_before_model_logic(
    callback_context: CallbackContext, llm_request: LlmRequest
) -> Optional[LlmResponse]:
    print(f"Callback running before model call for agent: {callback_context.agent_name}")
    # ... your custom logic here ...
    return None # Allow the model call to proceed

# --- Register it during Agent creation ---
my_agent = LlmAgent(
    name="MyCallbackAgent",
    model="gemini-2.0-flash", # Or your desired model
    instruction="Be helpful.",
    # Other agent parameters...
    before_model_callback=my_before_model_logic # Pass the function here
)
```

```typescript
import { LlmAgent, InMemoryRunner, Context, LlmRequest, LlmResponse, Event, isFinalResponse } from '@google/adk';
import { createUserContent } from "@google/genai";
import type { Content } from "@google/genai";

const MODEL_NAME = "gemini-2.5-flash";
const APP_NAME = "basic_callback_app";
const USER_ID = "test_user_basic";
const SESSION_ID = "session_basic_001";


// --- Define your callback function ---
function myBeforeModelLogic({
  context,
  request,
}: {
  context: Context;
  request: LlmRequest;
}): LlmResponse | undefined {
  console.log(
    `Callback running before model call for agent: ${context.agentName}`
  );
  // ... your custom logic here ...
  return undefined; // Allow the model call to proceed
}

// --- Register it during Agent creation ---
const myAgent = new LlmAgent({
  name: "MyCallbackAgent",
  model: MODEL_NAME,
  instruction: "Be helpful.",
  beforeModelCallback: myBeforeModelLogic,
});
```

```go
package main

import (
    "context"
    "fmt"
    "log"
    "strings"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/runner"
    "google.golang.org/adk/session"
    "google.golang.org/genai"
)



// onBeforeModel is a callback function that gets triggered before an LLM call.
func onBeforeModel(ctx agent.CallbackContext, req *model.LLMRequest) (*model.LLMResponse, error) {
    log.Println("--- onBeforeModel Callback Triggered ---")
    log.Printf("Model Request to be sent: %v\n", req)
    // Returning nil allows the default LLM call to proceed.
    return nil, nil
}

func runBasicExample() {
    const (
        appName = "CallbackBasicApp"
        userID  = "test_user_123"
    )
    ctx := context.Background()
    geminiModel, err := gemini.NewModel(ctx, modelName, &genai.ClientConfig{})
    if err != nil {
        log.Fatalf("Failed to create model: %v", err)
    }

    // Register the callback function in the agent configuration.
    agentCfg := llmagent.Config{
        Name:                 "SimpleAgent",
        Model:                geminiModel,
        BeforeModelCallbacks: []llmagent.BeforeModelCallback{onBeforeModel},
    }
    simpleAgent, err := llmagent.New(agentCfg)
    if err != nil {
        log.Fatalf("Failed to create agent: %v", err)
    }

    sessionService := session.InMemoryService()
    r, err := runner.New(runner.Config{
        AppName:        appName,
        Agent:          simpleAgent,
        SessionService: sessionService,
    })
    if err != nil {
        log.Fatalf("Failed to create runner: %v", err)
    }
```

```java
import com.google.adk.agents.CallbackContext;
import com.google.adk.agents.Callbacks;
import com.google.adk.agents.LlmAgent;
import com.google.adk.models.LlmRequest;
import java.util.Optional;

public class AgentWithBeforeModelCallback {

  public static void main(String[] args) {
    // --- Define your callback logic ---
    Callbacks.BeforeModelCallbackSync myBeforeModelLogic =
        (CallbackContext callbackContext, LlmRequest llmRequest) -> {
          System.out.println(
              "Callback running before model call for agent: " + callbackContext.agentName());
          // ... your custom logic here ...

          // Return Optional.empty() to allow the model call to proceed,
          // similar to returning None in the Python example.
          // If you wanted to return a response and skip the model call,
          // you would return Optional.of(yourLlmResponse).
          return Optional.empty();
        };

    // --- Register it during Agent creation ---
    LlmAgent myAgent =
        LlmAgent.builder()
            .name("MyCallbackAgent")
            .model("gemini-2.0-flash") // Or your desired model
            .instruction("Be helpful.")
            // Other agent parameters...
            .beforeModelCallbackSync(myBeforeModelLogic) // Pass the callback implementation here
            .build();
  }
}
```

## The Callback Mechanism: Interception and Control

When the ADK framework encounters a point where a callback can run (e.g., just before calling the LLM), it checks if you provided a corresponding callback function for that agent. If you did, the framework executes your function.

**Context is Key:** Your callback function isn't called in isolation. The framework provides special **context objects** (`CallbackContext` or `ToolContext`) as arguments. These objects contain vital information about the current state of the agent's execution, including the invocation details, session state, and potentially references to services like artifacts or memory. You use these context objects to understand the situation and interact with the framework. (See the dedicated "Context Objects" section for full details).

**Controlling the Flow (The Core Mechanism):** The most powerful aspect of callbacks lies in how their **return value** influences the agent's subsequent actions. This is how you intercept and control the execution flow:

1. **`return None` (Allow Default Behavior):**

   - The specific return type can vary depending on the language. In Java, the equivalent return type is `Optional.empty()`. Refer to the API documentation for language specific guidance.
   - This is the standard way to signal that your callback has finished its work (e.g., logging, inspection, minor modifications to *mutable* input arguments like `llm_request`) and that the ADK agent should **proceed with its normal operation**.
   - For `before_*` callbacks (`before_agent`, `before_model`, `before_tool`), returning `None` means the next step in the sequence (running the agent logic, calling the LLM, executing the tool) will occur.
   - For `after_*` callbacks (`after_agent`, `after_model`, `after_tool`), returning `None` means the result just produced by the preceding step (the agent's output, the LLM's response, the tool's result) will be used as is.

1. **`return <Specific Object>` (Override Default Behavior):**

   - Returning a *specific type of object* (instead of `None`) is how you **override** the ADK agent's default behavior. The framework will use the object you return and *skip* the step that would normally follow or *replace* the result that was just generated.
   - **`before_agent_callback` → `types.Content`**: Skips the agent's main execution logic (`_run_async_impl` / `_run_live_impl`). The returned `Content` object is immediately treated as the agent's final output for this turn. Useful for handling simple requests directly or enforcing access control.
   - **`before_model_callback` → `LlmResponse`**: Skips the call to the external Large Language Model. The returned `LlmResponse` object is processed as if it were the actual response from the LLM. Ideal for implementing input guardrails, prompt validation, or serving cached responses.
   - **`before_tool_callback` → `dict` or `Map`**: Skips the execution of the actual tool function (or sub-agent). The returned `dict` is used as the result of the tool call, which is then typically passed back to the LLM. Perfect for validating tool arguments, applying policy restrictions, or returning mocked/cached tool results.
   - **`after_agent_callback` → `types.Content`**: *Replaces* the `Content` that the agent's run logic just produced.
   - **`after_model_callback` → `LlmResponse`**: *Replaces* the `LlmResponse` received from the LLM. Useful for sanitizing outputs, adding standard disclaimers, or modifying the LLM's response structure.
   - **`after_tool_callback` → `dict` or `Map`**: *Replaces* the `dict` result returned by the tool. Allows for post-processing or standardization of tool outputs before they are sent back to the LLM.

**Conceptual Code Example (Guardrail):**

This example demonstrates the common pattern for a guardrail using `before_model_callback`.

Code

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

from google.adk.agents import LlmAgent
from google.adk.agents.callback_context import CallbackContext
from google.adk.models import LlmResponse, LlmRequest
from google.adk.runners import Runner
from typing import Optional
from google.genai import types 
from google.adk.sessions import InMemorySessionService

GEMINI_2_FLASH="gemini-2.0-flash"

# --- Define the Callback Function ---
def simple_before_model_modifier(
    callback_context: CallbackContext, llm_request: LlmRequest
) -> Optional[LlmResponse]:
    """Inspects/modifies the LLM request or skips the call."""
    agent_name = callback_context.agent_name
    print(f"[Callback] Before model call for agent: {agent_name}")

    # Inspect the last user message in the request contents
    last_user_message = ""
    if llm_request.contents and llm_request.contents[-1].role == 'user':
         if llm_request.contents[-1].parts:
            last_user_message = llm_request.contents[-1].parts[0].text
    print(f"[Callback] Inspecting last user message: '{last_user_message}'")

    # --- Modification Example ---
    # Add a prefix to the system instruction
    original_instruction = llm_request.config.system_instruction or types.Content(role="system", parts=[])
    prefix = "[Modified by Callback] "
    # Ensure system_instruction is Content and parts list exists
    if not isinstance(original_instruction, types.Content):
         # Handle case where it might be a string (though config expects Content)
         original_instruction = types.Content(role="system", parts=[types.Part(text=str(original_instruction))])
    if not original_instruction.parts:
        original_instruction.parts.append(types.Part(text="")) # Add an empty part if none exist

    # Modify the text of the first part
    modified_text = prefix + (original_instruction.parts[0].text or "")
    original_instruction.parts[0].text = modified_text
    llm_request.config.system_instruction = original_instruction
    print(f"[Callback] Modified system instruction to: '{modified_text}'")

    # --- Skip Example ---
    # Check if the last user message contains "BLOCK"
    if "BLOCK" in last_user_message.upper():
        print("[Callback] 'BLOCK' keyword found. Skipping LLM call.")
        # Return an LlmResponse to skip the actual LLM call
        return LlmResponse(
            content=types.Content(
                role="model",
                parts=[types.Part(text="LLM call was blocked by before_model_callback.")],
            )
        )
    else:
        print("[Callback] Proceeding with LLM call.")
        # Return None to allow the (modified) request to go to the LLM
        return None


# Create LlmAgent and Assign Callback
my_llm_agent = LlmAgent(
        name="ModelCallbackAgent",
        model=GEMINI_2_FLASH,
        instruction="You are a helpful assistant.", # Base instruction
        description="An LLM agent demonstrating before_model_callback",
        before_model_callback=simple_before_model_modifier # Assign the function here
)

APP_NAME = "guardrail_app"
USER_ID = "user_1"
SESSION_ID = "session_001"

# Session and Runner
async def setup_session_and_runner():
    session_service = InMemorySessionService()
    session = await session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID)
    runner = Runner(agent=my_llm_agent, app_name=APP_NAME, session_service=session_service)
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
await call_agent_async("write a joke on BLOCK")
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

import { LlmAgent, InMemoryRunner, Context, isFinalResponse } from '@google/adk';
import { createUserContent } from "@google/genai";

const MODEL_NAME = "gemini-2.5-flash";
const APP_NAME = "before_model_callback_app";
const USER_ID = "test_user_before_model";
const SESSION_ID_BLOCK = "session_block_model_call";
const SESSION_ID_NORMAL = "session_normal_model_call";

// --- Define the Callback Function ---
function simpleBeforeModelModifier({
  context,
  request,
}: {
  context: Context;
  request: any;
}): any | undefined {
  console.log(`[Callback] Before model call for agent: ${context.agentName}`);

  // Inspect the last user message in the request contents
  const lastUserMessage = request.contents?.at(-1)?.parts?.[0]?.text ?? "";
  console.log(`[Callback] Inspecting last user message: '${lastUserMessage}'`);

  // --- Modification Example ---
  // Add a prefix to the system instruction.
  // We create a deep copy to avoid modifying the original agent's config object.
  const modifiedConfig = JSON.parse(JSON.stringify(request.config));
  const originalInstructionText =
    modifiedConfig.systemInstruction?.parts?.[0]?.text ?? "";
  const prefix = "[Modified by Callback] ";
  modifiedConfig.systemInstruction = {
    role: "system",
    parts: [{ text: prefix + originalInstructionText }],
  };
  request.config = modifiedConfig; // Assign the modified config back to the request
  console.log(
    `[Callback] Modified system instruction to: '${modifiedConfig.systemInstruction.parts[0].text}'`
  );

  // --- Skip Example ---
  // Check if the last user message contains "BLOCK"
  if (lastUserMessage.toUpperCase().includes("BLOCK")) {
    console.log("[Callback] 'BLOCK' keyword found. Skipping LLM call.");
    // Return an LlmResponse to skip the actual LLM call
    return {
      content: {
        role: "model",
        parts: [
          { text: "LLM call was blocked by the before_model_callback." },
        ],
      },
    };
  }

  console.log("[Callback] Proceeding with LLM call.");
  // Return undefined to allow the (modified) request to go to the LLM
  return undefined;
}

// --- Create LlmAgent and Assign Callback ---
const myLlmAgent = new LlmAgent({
  name: "ModelCallbackAgent",
  model: MODEL_NAME,
  instruction: "You are a helpful assistant.", // Base instruction
  description: "An LLM agent demonstrating before_model_callback",
  beforeModelCallback: simpleBeforeModelModifier, // Assign the function here
});

// --- Agent Interaction Logic ---
async function callAgentAndPrint(
  runner: InMemoryRunner,
  query: string,
  sessionId: string
) {
  console.log(`\n>>> Calling Agent with query: "${query}"`);

  let finalResponseContent = "No final response received.";
  const events = runner.runAsync({ userId: USER_ID, sessionId, newMessage: createUserContent(query) });

  for await (const event of events) {
    if (isFinalResponse(event) && event.content?.parts?.length) {
      finalResponseContent = event.content.parts
        .map((part: { text?: string }) => part.text ?? "")
        .join("");
    }
  }
  console.log("<<< Agent Response: ", finalResponseContent);
}

// --- Run Interactions ---
async function main() {
  const runner = new InMemoryRunner({ agent: myLlmAgent, appName: APP_NAME });

  // Scenario 1: The callback will find "BLOCK" and skip the model call
  await runner.sessionService.createSession({
    appName: APP_NAME,
    userId: USER_ID,
    sessionId: SESSION_ID_BLOCK,
  });
  await callAgentAndPrint(
    runner,
    "write a joke about BLOCK",
    SESSION_ID_BLOCK
  );

  // Scenario 2: The callback will modify the instruction and proceed
  await runner.sessionService.createSession({
    appName: APP_NAME,
    userId: USER_ID,
    sessionId: SESSION_ID_NORMAL,
  });
  await callAgentAndPrint(runner, "write a short poem", SESSION_ID_NORMAL);
}

main();
```

```go
package main

import (
    "context"
    "fmt"
    "log"
    "strings"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/runner"
    "google.golang.org/adk/session"
    "google.golang.org/genai"
)



// onBeforeModelGuardrail is a callback that inspects the LLM request.
// If it contains a forbidden topic, it blocks the request and returns a
// predefined response. Otherwise, it allows the request to proceed.
func onBeforeModelGuardrail(ctx agent.CallbackContext, req *model.LLMRequest) (*model.LLMResponse, error) {
    log.Println("--- onBeforeModelGuardrail Callback Triggered ---")

    // Inspect the request content for forbidden topics.
    for _, content := range req.Contents {
        for _, part := range content.Parts {
            if strings.Contains(part.Text, "finance") {
                log.Println("Forbidden topic 'finance' detected. Blocking LLM call.")
                // By returning a non-nil response, we override the default behavior
                // and prevent the actual LLM call.
                return &model.LLMResponse{
                    Content: &genai.Content{
                        Parts: []*genai.Part{{Text: "I'm sorry, but I cannot discuss financial topics."}},
                        Role:  "model",
                    },
                }, nil
            }
        }
    }

    log.Println("No forbidden topics found. Allowing LLM call to proceed.")
    // Returning nil allows the default LLM call to proceed.
    return nil, nil
}

func runGuardrailExample() {
    const (
        appName = "GuardrailApp"
        userID  = "test_user_456"
    )
    ctx := context.Background()
    geminiModel, err := gemini.NewModel(ctx, modelName, &genai.ClientConfig{})
    if err != nil {
        log.Fatalf("Failed to create model: %v", err)
    }

    agentCfg := llmagent.Config{
        Name:                 "ChatAgent",
        Model:                geminiModel,
        BeforeModelCallbacks: []llmagent.BeforeModelCallback{onBeforeModelGuardrail},
    }
    chatAgent, err := llmagent.New(agentCfg)
    if err != nil {
        log.Fatalf("Failed to create agent: %v", err)
    }

    sessionService := session.InMemoryService()
    r, err := runner.New(runner.Config{
        AppName:        appName,
        Agent:          chatAgent,
        SessionService: sessionService,
    })
    if err != nil {
        log.Fatalf("Failed to create runner: %v", err)
    }
```

```java
import com.google.adk.agents.CallbackContext;
import com.google.adk.agents.LlmAgent;
import com.google.adk.events.Event;
import com.google.adk.models.LlmRequest;
import com.google.adk.models.LlmResponse;
import com.google.adk.runner.InMemoryRunner;
import com.google.adk.sessions.Session;
import com.google.genai.types.Content;
import com.google.genai.types.GenerateContentConfig;
import com.google.genai.types.Part;
import io.reactivex.rxjava3.core.Flowable;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

public class BeforeModelGuardrailExample {

  private static final String MODEL_ID = "gemini-2.0-flash";
  private static final String APP_NAME = "guardrail_app";
  private static final String USER_ID = "user_1";

  public static void main(String[] args) {
    BeforeModelGuardrailExample example = new BeforeModelGuardrailExample();
    example.defineAgentAndRun("Tell me about quantum computing. This is a test.");
  }

  // --- Define your callback logic ---
  // Looks for the word "BLOCK" in the user prompt and blocks the call to LLM if found.
  // Otherwise the LLM call proceeds as usual.
  public Optional<LlmResponse> simpleBeforeModelModifier(
      CallbackContext callbackContext, LlmRequest llmRequest) {
    System.out.println("[Callback] Before model call for agent: " + callbackContext.agentName());

    // Inspect the last user message in the request contents
    String lastUserMessageText = "";
    List<Content> requestContents = llmRequest.contents();
    if (requestContents != null && !requestContents.isEmpty()) {
      Content lastContent = requestContents.get(requestContents.size() - 1);
      if (lastContent.role().isPresent() && "user".equals(lastContent.role().get())) {
        lastUserMessageText =
            lastContent.parts().orElse(List.of()).stream()
                .flatMap(part -> part.text().stream())
                .collect(Collectors.joining(" ")); // Concatenate text from all parts
      }
    }
    System.out.println("[Callback] Inspecting last user message: '" + lastUserMessageText + "'");

    String prefix = "[Modified by Callback] ";
    GenerateContentConfig currentConfig =
        llmRequest.config().orElse(GenerateContentConfig.builder().build());
    Optional<Content> optOriginalSystemInstruction = currentConfig.systemInstruction();

    Content conceptualModifiedSystemInstruction;
    if (optOriginalSystemInstruction.isPresent()) {
      Content originalSystemInstruction = optOriginalSystemInstruction.get();
      List<Part> originalParts =
          new ArrayList<>(originalSystemInstruction.parts().orElse(List.of()));
      String originalText = "";

      if (!originalParts.isEmpty()) {
        Part firstPart = originalParts.get(0);
        if (firstPart.text().isPresent()) {
          originalText = firstPart.text().get();
        }
        originalParts.set(0, Part.fromText(prefix + originalText));
      } else {
        originalParts.add(Part.fromText(prefix));
      }
      conceptualModifiedSystemInstruction =
          originalSystemInstruction.toBuilder().parts(originalParts).build();
    } else {
      conceptualModifiedSystemInstruction =
          Content.builder()
              .role("system")
              .parts(List.of(Part.fromText(prefix)))
              .build();
    }

    // This demonstrates building a new LlmRequest with the modified config.
    llmRequest =
        llmRequest.toBuilder()
            .config(
                currentConfig.toBuilder()
                    .systemInstruction(conceptualModifiedSystemInstruction)
                    .build())
            .build();

    System.out.println(
        "[Callback] Conceptually modified system instruction is: '"
            + llmRequest.config().get().systemInstruction().get().parts().get().get(0).text().get());

    // --- Skip Example ---
    // Check if the last user message contains "BLOCK"
    if (lastUserMessageText.toUpperCase().contains("BLOCK")) {
      System.out.println("[Callback] 'BLOCK' keyword found. Skipping LLM call.");
      LlmResponse skipResponse =
          LlmResponse.builder()
              .content(
                  Content.builder()
                      .role("model")
                      .parts(
                          List.of(
                              Part.builder()
                                  .text("LLM call was blocked by before_model_callback.")
                                  .build()))
                      .build())
              .build();
      return Optional.of(skipResponse);
    }
    System.out.println("[Callback] Proceeding with LLM call.");
    // Return Optional.empty() to allow the (modified) request to go to the LLM
    return Optional.empty();
  }

  public void defineAgentAndRun(String prompt) {
    // --- Create LlmAgent and Assign Callback ---
    LlmAgent myLlmAgent =
        LlmAgent.builder()
            .name("ModelCallbackAgent")
            .model(MODEL_ID)
            .instruction("You are a helpful assistant.") // Base instruction
            .description("An LLM agent demonstrating before_model_callback")
            .beforeModelCallbackSync(this::simpleBeforeModelModifier) // Assign the callback here
            .build();

    // Session and Runner
    InMemoryRunner runner = new InMemoryRunner(myLlmAgent, APP_NAME);
    // InMemoryRunner automatically creates a session service. Create a session using the service
    Session session = runner.sessionService().createSession(APP_NAME, USER_ID).blockingGet();
    Content userMessage =
        Content.fromParts(Part.fromText(prompt));

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
}
```

By understanding this mechanism of returning `None` versus returning specific objects, you can precisely control the agent's execution path, making callbacks an essential tool for building sophisticated and reliable agents with ADK.

# Design Patterns and Best Practices for Callbacks

Callbacks offer powerful hooks into the agent lifecycle. Here are common design patterns illustrating how to leverage them effectively in ADK, followed by best practices for implementation.

## Design Patterns

These patterns demonstrate typical ways to enhance or control agent behavior using callbacks:

### 1. Guardrails & Policy Enforcement

**Pattern Overview:** Intercept requests before they reach the LLM or tools to enforce rules.

**Implementation:**

- Use `before_model_callback` to inspect the `LlmRequest` prompt
- Use `before_tool_callback` to inspect tool arguments
- If a policy violation is detected (e.g., forbidden topics, profanity):
- Return a predefined response (`LlmResponse` or `dict`/`Map`) to block the operation
- Optionally update `context.state` to log the violation

**Example Use Case:** A `before_model_callback` checks `llm_request.contents` for sensitive keywords and returns a standard "Cannot process this request" `LlmResponse` if found, preventing the LLM call.

### 2. Dynamic State Management

**Pattern Overview:** Read from and write to session state within callbacks to make agent behavior context-aware and pass data between steps.

**Implementation:**

- Access `callback_context.state` or `tool_context.state`
- Modifications (`state['key'] = value`) are automatically tracked in the subsequent `Event.actions.state_delta`
- Changes are persisted by the `SessionService`

**Example Use Case:** An `after_tool_callback` saves a `transaction_id` from the tool's result to `tool_context.state['last_transaction_id']`. A later `before_agent_callback` might read `state['user_tier']` to customize the agent's greeting.

### 3. Logging and Monitoring

**Pattern Overview:** Add detailed logging at specific lifecycle points for observability and debugging.

**Implementation:**

- Implement callbacks (e.g., `before_agent_callback`, `after_tool_callback`, `after_model_callback`)
- Print or send structured logs containing:
- Agent name
- Tool name
- Invocation ID
- Relevant data from the context or arguments

**Example Use Case:** Log messages like `INFO: [Invocation: e-123] Before Tool: search_api - Args: {'query': 'ADK'}`.

### 4. Caching

**Pattern Overview:** Avoid redundant LLM calls or tool executions by caching results.

**Implementation Steps:**

1. **Before Operation:** In `before_model_callback` or `before_tool_callback`:

- Generate a cache key based on the request/arguments
- Check `context.state` (or an external cache) for this key
- If found, return the cached `LlmResponse` or result directly

1. **After Operation:** If cache miss occurred:
1. Use the corresponding `after_` callback to store the new result in the cache using the key

**Example Use Case:** `before_tool_callback` for `get_stock_price(symbol)` checks `state[f"cache:stock:{symbol}"]`. If present, returns the cached price; otherwise, allows the API call and `after_tool_callback` saves the result to the state key.

### 5. Request/Response Modification

**Pattern Overview:** Alter data just before it's sent to the LLM/tool or just after it's received.

**Implementation Options:**

- **`before_model_callback`:** Modify `llm_request` (e.g., add system instructions based on `state`)
- **`after_model_callback`:** Modify the returned `LlmResponse` (e.g., format text, filter content)
- **`before_tool_callback`:** Modify the tool `args` dictionary (or Map in Java)
- **`after_tool_callback`:** Modify the `tool_response` dictionary (or Map in Java)

**Example Use Case:** `before_model_callback` appends "User language preference: Spanish" to `llm_request.config.system_instruction` if `context.state['lang'] == 'es'`.

### 6. Conditional Skipping of Steps

**Pattern Overview:** Prevent standard operations (agent run, LLM call, tool execution) based on certain conditions.

**Implementation:**

- Return a value from a `before_` callback to skip the normal execution:
- `Content` from `before_agent_callback`
- `LlmResponse` from `before_model_callback`
- `dict` from `before_tool_callback`
- The framework interprets this returned value as the result for that step

**Example Use Case:** `before_tool_callback` checks `tool_context.state['api_quota_exceeded']`. If `True`, it returns `{'error': 'API quota exceeded'}`, preventing the actual tool function from running.

### 7. Tool-Specific Actions (Authentication & Summarization Control)

**Pattern Overview:** Handle actions specific to the tool lifecycle, primarily authentication and controlling LLM summarization of tool results.

**Implementation:** Use `ToolContext` within tool callbacks (`before_tool_callback`, `after_tool_callback`):

- **Authentication:** Call `tool_context.request_credential(auth_config)` in `before_tool_callback` if credentials are required but not found (e.g., via `tool_context.get_auth_response` or state check). This initiates the auth flow.
- **Summarization:** Set `tool_context.actions.skip_summarization = True` if the raw dictionary output of the tool should be passed back to the LLM or potentially displayed directly, bypassing the default LLM summarization step.

**Example Use Case:** A `before_tool_callback` for a secure API checks for an auth token in state; if missing, it calls `request_credential`. An `after_tool_callback` for a tool returning structured JSON might set `skip_summarization = True`.

### 8. Artifact Handling

**Pattern Overview:** Save or load session-related files or large data blobs during the agent lifecycle.

**Implementation:**

- **Saving:** Use `callback_context.save_artifact` / `await tool_context.save_artifact` to store data:
- Generated reports
- Logs
- Intermediate data
- **Loading:** Use `load_artifact` to retrieve previously stored artifacts
- **Tracking:** Changes are tracked via `Event.actions.artifact_delta`

**Example Use Case:** An `after_tool_callback` for a "generate_report" tool saves the output file using `await tool_context.save_artifact("report.pdf", report_part)`. A `before_agent_callback` might load a configuration artifact using `callback_context.load_artifact("agent_config.json")`.

## Best Practices for Callbacks

### Design Principles

**Keep Focused:** Design each callback for a single, well-defined purpose (e.g., just logging, just validation). Avoid monolithic callbacks.

**Mind Performance:** Callbacks execute synchronously within the agent's processing loop. Avoid long-running or blocking operations (network calls, heavy computation). Offload if necessary, but be aware this adds complexity.

### Error Handling

**Handle Errors Gracefully:**

- Use `try...except/catch` blocks within your callback functions
- Log errors appropriately
- Decide if the agent invocation should halt or attempt recovery
- Don't let callback errors crash the entire process

### State Management

**Manage State Carefully:**

- Be deliberate about reading from and writing to `context.state`
- Changes are immediately visible within the *current* invocation and persisted at the end of the event processing
- Use specific state keys rather than modifying broad structures to avoid unintended side effects
- Consider using state prefixes (`State.APP_PREFIX`, `State.USER_PREFIX`, `State.TEMP_PREFIX`) for clarity, especially with persistent `SessionService` implementations

### Reliability

**Consider Idempotency:** If a callback performs actions with external side effects (e.g., incrementing an external counter), design it to be idempotent (safe to run multiple times with the same input) if possible, to handle potential retries in the framework or your application.

### Testing & Documentation

**Test Thoroughly:**

- Unit test your callback functions using mock context objects
- Perform integration tests to ensure callbacks function correctly within the full agent flow

**Ensure Clarity:**

- Use descriptive names for your callback functions
- Add clear docstrings explaining their purpose, when they run, and any side effects (especially state modifications)

**Use Correct Context Type:** Always use the specific context type provided (`CallbackContext` for agent/model, `ToolContext` for tools) to ensure access to the appropriate methods and properties.

By applying these patterns and best practices, you can effectively use callbacks to create more robust, observable, and customized agent behaviors in ADK.

# Types of Callbacks

Supported in ADKPython v0.1.0TypeScript v0.2.0Go v0.1.0Java v0.1.0

The framework provides different types of callbacks that trigger at various stages of an agent's execution. Understanding when each callback fires and what context it receives is key to using them effectively.

## Agent Lifecycle Callbacks

These callbacks are available on *any* agent that inherits from `BaseAgent` (including `LlmAgent`, `SequentialAgent`, `ParallelAgent`, `LoopAgent`, etc).

Note

The specific method names or return types may vary slightly by SDK language (e.g., return `None` in Python, return `Optional.empty()` or `Maybe.empty()` in Java). Refer to the language-specific API documentation for details.

Python: Use the documented callback parameter names

In Python, callback function parameter names must match the documented names exactly because ADK passes callback arguments by keyword. For example, use `callback_context` for agent and model callbacks, and `tool_context` for tool callbacks. Renaming these parameters to aliases such as `ctx` will cause runtime `TypeError` failures.

```python
# Correct
def before_agent_callback(callback_context):
    ...

# Incorrect
def before_agent_callback(ctx):
    ...
```

| Callback                | Required parameter names                        |
| ----------------------- | ----------------------------------------------- |
| `before_agent_callback` | `callback_context`                              |
| `after_agent_callback`  | `callback_context`                              |
| `before_model_callback` | `callback_context`, `llm_request`               |
| `after_model_callback`  | `callback_context`, `llm_response`              |
| `before_tool_callback`  | `tool`, `args`, `tool_context`                  |
| `after_tool_callback`   | `tool`, `args`, `tool_context`, `tool_response` |

### Before Agent Callback

**When:** Called *immediately before* the agent's `_run_async_impl` (or `_run_live_impl`) method is executed. It runs after the agent's `InvocationContext` is created but *before* its core logic begins.

**Purpose:** Ideal for setting up resources or state needed only for this specific agent's run, performing validation checks on the session state (callback_context.state) before execution starts, logging the entry point of the agent's activity, or potentially modifying the invocation context before the core logic uses it.

Code

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

# # --- Setup Instructions ---
# # 1. Install the ADK package:
# !pip install google-adk
# # Make sure to restart kernel if using colab/jupyter notebooks

# # 2. Set up your Gemini API Key:
# #    - Get a key from Google AI Studio: https://aistudio.google.com/app/apikey
# #    - Set it as an environment variable:
# import os
# os.environ["GOOGLE_API_KEY"] = "YOUR_API_KEY_HERE" # <--- REPLACE with your actual key
# # Or learn about other authentication methods (like Agent Platform):
# # https://adk.dev/agents/models/

# ADK Imports
from google.adk.agents import LlmAgent
from google.adk.agents.callback_context import CallbackContext
from google.adk.runners import InMemoryRunner  # Use InMemoryRunner
from google.genai import types  # For types.Content
from typing import Optional

# Define the model - Use the specific model name requested
GEMINI_2_FLASH = "gemini-2.0-flash"


# --- 1. Define the Callback Function ---
def check_if_agent_should_run(
    callback_context: CallbackContext,
) -> Optional[types.Content]:
    """
    Logs entry and checks 'skip_llm_agent' in session state.
    If True, returns Content to skip the agent's execution.
    If False or not present, returns None to allow execution.
    """
    agent_name = callback_context.agent_name
    invocation_id = callback_context.invocation_id
    current_state = callback_context.state.to_dict()

    print(f"\n[Callback] Entering agent: {agent_name} (Inv: {invocation_id})")
    print(f"[Callback] Current State: {current_state}")

    # Check the condition in session state dictionary
    if current_state.get("skip_llm_agent", False):
        print(
            f"[Callback] State condition 'skip_llm_agent=True' met: Skipping agent {agent_name}."
        )
        # Return Content to skip the agent's run
        return types.Content(
            parts=[
                types.Part(
                    text=f"Agent {agent_name} skipped by before_agent_callback due to state."
                )
            ],
            role="model",  # Assign model role to the overriding response
        )
    else:
        print(
            f"[Callback] State condition not met: Proceeding with agent {agent_name}."
        )
        # Return None to allow the LlmAgent's normal execution
        return None


# --- 2. Setup Agent with Callback ---
llm_agent_with_before_cb = LlmAgent(
    name="MyControlledAgent",
    model=GEMINI_2_FLASH,
    instruction="You are a concise assistant.",
    description="An LLM agent demonstrating stateful before_agent_callback",
    before_agent_callback=check_if_agent_should_run,  # Assign the callback
)


# --- 3. Setup Runner and Sessions using InMemoryRunner ---
async def main():
    app_name = "before_agent_demo"
    user_id = "test_user"
    session_id_run = "session_will_run"
    session_id_skip = "session_will_skip"

    # Use InMemoryRunner - it includes InMemorySessionService
    runner = InMemoryRunner(agent=llm_agent_with_before_cb, app_name=app_name)
    # Get the bundled session service to create sessions
    session_service = runner.session_service

    # Create session 1: Agent will run (default empty state)
    session_service.create_session(
        app_name=app_name,
        user_id=user_id,
        session_id=session_id_run,
        # No initial state means 'skip_llm_agent' will be False in the callback check
    )

    # Create session 2: Agent will be skipped (state has skip_llm_agent=True)
    session_service.create_session(
        app_name=app_name,
        user_id=user_id,
        session_id=session_id_skip,
        state={"skip_llm_agent": True},  # Set the state flag here
    )

    # --- Scenario 1: Run where callback allows agent execution ---
    print(
        "\n"
        + "=" * 20
        + f" SCENARIO 1: Running Agent on Session '{session_id_run}' (Should Proceed) "
        + "=" * 20
    )
    async for event in runner.run_async(
        user_id=user_id,
        session_id=session_id_run,
        new_message=types.Content(
            role="user", parts=[types.Part(text="Hello, please respond.")]
        ),
    ):
        # Print final output (either from LLM or callback override)
        if event.is_final_response() and event.content:
            print(
                f"Final Output: [{event.author}] {event.content.parts[0].text.strip()}"
            )
        elif event.is_error():
            print(f"Error Event: {event.error_details}")

    # --- Scenario 2: Run where callback intercepts and skips agent ---
    print(
        "\n"
        + "=" * 20
        + f" SCENARIO 2: Running Agent on Session '{session_id_skip}' (Should Skip) "
        + "=" * 20
    )
    async for event in runner.run_async(
        user_id=user_id,
        session_id=session_id_skip,
        new_message=types.Content(
            role="user", parts=[types.Part(text="This message won't reach the LLM.")]
        ),
    ):
        # Print final output (either from LLM or callback override)
        if event.is_final_response() and event.content:
            print(
                f"Final Output: [{event.author}] {event.content.parts[0].text.strip()}"
            )
        elif event.is_error():
            print(f"Error Event: {event.error_details}")


# --- 4. Execute ---
# In a Python script:
# import asyncio
# if __name__ == "__main__":
#     # Make sure GOOGLE_API_KEY environment variable is set if not using Agent Platform auth
#     # Or ensure Application Default Credentials (ADC) are configured for Agent Platform
#     asyncio.run(main())

# In a Jupyter Notebook or similar environment:
await main()
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

import { LlmAgent, InMemoryRunner, Context, isFinalResponse } from '@google/adk';
import { Content, createUserContent } from "@google/genai";

const MODEL_NAME = "gemini-2.5-flash";
const APP_NAME = "before_agent_callback_app";
const USER_ID = "test_user_before_agent";
const SESSION_ID_RUN = "session_will_run";
const SESSION_ID_SKIP = "session_will_skip";


// --- 1. Define the Callback Function ---
function checkIfAgentShouldRun(
  context: Context
): Content | undefined {
  /**
   * Logs entry and checks 'skip_llm_agent' in session state.
   * If True, returns Content to skip the agent's execution.
   * If False or not present, returns undefined to allow execution.
   */
  const agentName = context.agentName;
  const invocationId = context.invocationId;
  const currentState = context.state;

  console.log(`\n[Callback] Entering agent: ${agentName} (Inv: ${invocationId})`);
  console.log(`[Callback] Current State:`, currentState);

  // Check the condition in session state
  if (currentState.get("skip_llm_agent") === true) {
    console.log(
      `[Callback] State condition 'skip_llm_agent=True' met: Skipping agent ${agentName}.`
    );
    // Return Content to skip the agent's run
    return {
      parts: [
        {
          text: `Agent ${agentName} skipped by before_agent_callback due to state.`,
        },
      ],
      role: "model", // Assign model role to the overriding response
    };
  } else {
    console.log(
      `[Callback] State condition not met: Proceeding with agent ${agentName}.`
    );
    // Return undefined to allow the LlmAgent's normal execution
    return undefined;
  }
}

// --- 2. Setup Agent with Callback ---
const llmAgentWithBeforeCb = new LlmAgent({
  name: "MyControlledAgent",
  model: MODEL_NAME,
  instruction: "You are a concise assistant.",
  description: "An LLM agent demonstrating stateful before_agent_callback",
  beforeAgentCallback: checkIfAgentShouldRun, // Assign the callback
});

// --- 3. Setup Runner and Sessions using InMemoryRunner ---
async function main() {
  // Use InMemoryRunner - it includes InMemorySessionService
  const runner = new InMemoryRunner({
    agent: llmAgentWithBeforeCb,
    appName: APP_NAME,
  });

  // Create session 1: Agent will run (default empty state)
  await runner.sessionService.createSession({
    appName: APP_NAME,
    userId: USER_ID,
    sessionId: SESSION_ID_RUN,
    // No initial state means 'skip_llm_agent' will be False in the callback check
  });

  // Create session 2: Agent will be skipped (state has skip_llm_agent=True)
  await runner.sessionService.createSession({
    appName: APP_NAME,
    userId: USER_ID,
    sessionId: SESSION_ID_SKIP,
    state: { skip_llm_agent: true }, // Set the state flag here
  });

  // --- Scenario 1: Run where callback allows agent execution ---
  console.log(
    `\n==================== SCENARIO 1: Running Agent on Session "${SESSION_ID_RUN}" (Should Proceed) ====================`
  );
  const eventsRun = runner.runAsync({
    userId: USER_ID,
    sessionId: SESSION_ID_RUN,
    newMessage: createUserContent("Hello, please respond."),
  });

  for await (const event of eventsRun) {
    // Print final output (either from LLM or callback override)
    if (isFinalResponse(event) && event.content?.parts?.length) {
      const finalResponse = event.content.parts
        .map((part: any) => part.text ?? "")
        .join("");
      console.log(
        `Final Output: [${event.author}] ${finalResponse.trim()}`
      );
    } else if (event.errorMessage) {
      console.log(`Error Event: ${event.errorMessage}`);
    }
  }

  // --- Scenario 2: Run where callback intercepts and skips agent ---
  console.log(
    `\n==================== SCENARIO 2: Running Agent on Session "${SESSION_ID_SKIP}" (Should Skip) ====================`
  );
  const eventsSkip = runner.runAsync({
    userId: USER_ID,
    sessionId: SESSION_ID_SKIP,
    newMessage: createUserContent("This message won't reach the LLM."),
  });

  for await (const event of eventsSkip) {
    // Print final output (either from LLM or callback override)
    if (isFinalResponse(event) && event.content?.parts?.length) {
      const finalResponse = event.content.parts
        .map((part: any) => part.text ?? "")
        .join("");
      console.log(
        `Final Output: [${event.author}] ${finalResponse.trim()}`
      );
    } else if (event.errorMessage) {
      console.log(`Error Event: ${event.errorMessage}`);
    }
  }
}

// --- 4. Execute ---
main();
```

```go
package main

import (
    "context"
    "fmt"
    "log"
    "regexp"
    "strings"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/runner"
    "google.golang.org/adk/session"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/functiontool"
    "google.golang.org/genai"
)



// 1. Define the Callback Function
func onBeforeAgent(ctx agent.CallbackContext) (*genai.Content, error) {
    agentName := ctx.AgentName()
    log.Printf("[Callback] Entering agent: %s", agentName)
    if skip, _ := ctx.State().Get("skip_llm_agent"); skip == true {
        log.Printf("[Callback] State condition met: Skipping agent %s", agentName)
        return genai.NewContentFromText(
                fmt.Sprintf("Agent %s skipped by before_agent_callback.", agentName),
                genai.RoleModel,
            ),
            nil
    }
    log.Printf("[Callback] State condition not met: Running agent %s", agentName)
    return nil, nil
}

// 2. Define a function to set up and run the agent with the callback.
func runBeforeAgentExample() {
    ctx := context.Background()
    geminiModel, err := gemini.NewModel(ctx, modelName, &genai.ClientConfig{})
    if err != nil {
        log.Fatalf("FATAL: Failed to create model: %v", err)
    }

    // 3. Register the callback in the agent configuration.
    llmCfg := llmagent.Config{
        Name:                 "AgentWithBeforeAgentCallback",
        BeforeAgentCallbacks: []agent.BeforeAgentCallback{onBeforeAgent},
        Model:                geminiModel,
        Instruction:          "You are a concise assistant.",
    }
    testAgent, err := llmagent.New(llmCfg)
    if err != nil {
        log.Fatalf("FATAL: Failed to create agent: %v", err)
    }

    sessionService := session.InMemoryService()
    r, err := runner.New(runner.Config{AppName: appName, Agent: testAgent, SessionService: sessionService})
    if err != nil {
        log.Fatalf("FATAL: Failed to create runner: %v", err)
    }

    // 4. Run scenarios to demonstrate the callback's behavior.
    log.Println("--- SCENARIO 1: Agent should run normally ---")
    runScenario(ctx, r, sessionService, appName, "session_normal", nil, "Hello, world!")

    log.Println("\n--- SCENARIO 2: Agent should be skipped ---")
    runScenario(ctx, r, sessionService, appName, "session_skip", map[string]any{"skip_llm_agent": true}, "This should be skipped.")
}
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.BaseAgent;
import com.google.adk.agents.CallbackContext;
import com.google.adk.events.Event;
import com.google.adk.runner.InMemoryRunner;
import com.google.adk.sessions.Session;
import com.google.adk.sessions.State;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import io.reactivex.rxjava3.core.Flowable;
import io.reactivex.rxjava3.core.Maybe;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class BeforeAgentCallbackExample {

  private static final String APP_NAME = "AgentWithBeforeAgentCallback";
  private static final String USER_ID = "test_user_456";
  private static final String SESSION_ID = "session_id_123";
  private static final String MODEL_NAME = "gemini-2.0-flash";

  public static void main(String[] args) {
    BeforeAgentCallbackExample callbackAgent = new BeforeAgentCallbackExample();
    callbackAgent.defineAgent("Write a document about a cat");
  }

  // --- 1. Define the Callback Function ---
  /**
   * Logs entry and checks 'skip_llm_agent' in session state. If True, returns Content to skip the
   * agent's execution. If False or not present, returns None to allow execution.
   */
  public Maybe<Content> checkIfAgentShouldRun(CallbackContext callbackContext) {
    String agentName = callbackContext.agentName();
    String invocationId = callbackContext.invocationId();
    State currentState = callbackContext.state();

    System.out.printf("%n[Callback] Entering agent: %s (Inv: %s)%n", agentName, invocationId);
    System.out.printf("[Callback] Current State: %s%n", currentState.entrySet());

    // Check the condition in session state dictionary
    if (Boolean.TRUE.equals(currentState.get("skip_llm_agent"))) {
      System.out.printf(
          "[Callback] State condition 'skip_llm_agent=True' met: Skipping agent %s", agentName);
      // Return Content to skip the agent's run
      return Maybe.just(
          Content.fromParts(
              Part.fromText(
                  String.format(
                      "Agent %s skipped by before_agent_callback due to state.", agentName))));
    }

    System.out.printf(
        "[Callback] State condition 'skip_llm_agent=True' NOT met: Running agent %s \n", agentName);
    // Return empty response to allow the LlmAgent's normal execution
    return Maybe.empty();
  }

  public void defineAgent(String prompt) {
    // --- 2. Setup Agent with Callback ---
    BaseAgent llmAgentWithBeforeCallback =
        LlmAgent.builder()
            .model(MODEL_NAME)
            .name(APP_NAME)
            .instruction("You are a concise assistant.")
            .description("An LLM agent demonstrating stateful before_agent_callback")
            // You can also use a sync version of this callback "beforeAgentCallbackSync"
            .beforeAgentCallback(this::checkIfAgentShouldRun)
            .build();

    // --- 3. Setup Runner and Sessions using InMemoryRunner ---

    // Use InMemoryRunner - it includes InMemorySessionService
    InMemoryRunner runner = new InMemoryRunner(llmAgentWithBeforeCallback, APP_NAME);
    // Scenario 1: Initial state is null, which means 'skip_llm_agent' will be false in the callback
    // check
    runAgent(runner, null, prompt);
    // Scenario 2: Agent will be skipped (state has skip_llm_agent=true)
    runAgent(runner, new ConcurrentHashMap<>(Map.of("skip_llm_agent", true)), prompt);
  }

  public void runAgent(InMemoryRunner runner, ConcurrentHashMap<String, Object> initialState, String prompt) {
    // InMemoryRunner automatically creates a session service. Create a session using the service.
    Session session =
        runner
            .sessionService()
            .createSession(APP_NAME, USER_ID, initialState, SESSION_ID)
            .blockingGet();
    Content userMessage = Content.fromParts(Part.fromText(prompt));

    // Run the agent
    Flowable<Event> eventStream = runner.runAsync(USER_ID, session.id(), userMessage);

    // Print final output (either from LLM or callback override)
    eventStream.blockingForEach(
        event -> {
          if (event.finalResponse()) {
            System.out.println(event.stringifyContent());
          }
        });
  }
}
```

**Note on the `before_agent_callback` Example:**

- **What it Shows:** This example demonstrates the `before_agent_callback`. This callback runs *right before* the agent's main processing logic starts for a given request.
- **How it Works:** The callback function (`check_if_agent_should_run`) looks at a flag (`skip_llm_agent`) in the session's state.
  - If the flag is `True`, the callback returns a `types.Content` object. This tells the ADK framework to **skip** the agent's main execution entirely and use the callback's returned content as the final response.
  - If the flag is `False` (or not set), the callback returns `None` or an empty object. This tells the ADK framework to **proceed** with the agent's normal execution (calling the LLM in this case).
- **Expected Outcome:** You'll see two scenarios:
  1. In the session *with* the `skip_llm_agent: True` state, the agent's LLM call is bypassed, and the output comes directly from the callback ("Agent... skipped...").
  1. In the session *without* that state flag, the callback allows the agent to run, and you see the actual response from the LLM (e.g., "Hello!").
- **Understanding Callbacks:** This highlights how `before_` callbacks act as **gatekeepers**, allowing you to intercept execution *before* a major step and potentially prevent it based on checks (like state, input validation, permissions).

### After Agent Callback

**When:** Called *immediately after* the agent's `_run_async_impl` (or `_run_live_impl`) method successfully completes. It does *not* run if the agent was skipped due to `before_agent_callback` returning content or if `end_invocation` was set during the agent's run.

**Purpose:** Useful for cleanup tasks, post-execution validation, logging the completion of an agent's activity, modifying final state, or augmenting the agent's final output.

Code

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

# # --- Setup Instructions ---
# # 1. Install the ADK package:
# !pip install google-adk
# # Make sure to restart kernel if using colab/jupyter notebooks

# # 2. Set up your Gemini API Key:
# #    - Get a key from Google AI Studio: https://aistudio.google.com/app/apikey
# #    - Set it as an environment variable:
# import os
# os.environ["GOOGLE_API_KEY"] = "YOUR_API_KEY_HERE" # <--- REPLACE with your actual key
# # Or learn about other authentication methods (like Agent Platform):
# # https://adk.dev/agents/models/


# ADK Imports
from google.adk.agents import LlmAgent
from google.adk.agents.callback_context import CallbackContext
from google.adk.runners import InMemoryRunner  # Use InMemoryRunner
from google.genai import types  # For types.Content
from typing import Optional

# Define the model - Use the specific model name requested
GEMINI_2_FLASH = "gemini-2.0-flash"


# --- 1. Define the Callback Function ---
def modify_output_after_agent(
    callback_context: CallbackContext,
) -> Optional[types.Content]:
    """
    Logs exit from an agent and checks 'add_concluding_note' in session state.
    If True, returns new Content to *replace* the agent's original output.
    If False or not present, returns None, allowing the agent's original output to be used.
    """
    agent_name = callback_context.agent_name
    invocation_id = callback_context.invocation_id
    current_state = callback_context.state.to_dict()

    print(f"\n[Callback] Exiting agent: {agent_name} (Inv: {invocation_id})")
    print(f"[Callback] Current State: {current_state}")

    # Example: Check state to decide whether to modify the final output
    if current_state.get("add_concluding_note", False):
        print(
            f"[Callback] State condition 'add_concluding_note=True' met: Replacing agent {agent_name}'s output."
        )
        # Return Content to *replace* the agent's own output
        return types.Content(
            parts=[
                types.Part(
                    text=f"Concluding note added by after_agent_callback, replacing original output."
                )
            ],
            role="model",  # Assign model role to the overriding response
        )
    else:
        print(
            f"[Callback] State condition not met: Using agent {agent_name}'s original output."
        )
        # Return None - the agent's output produced just before this callback will be used.
        return None


# --- 2. Setup Agent with Callback ---
llm_agent_with_after_cb = LlmAgent(
    name="MySimpleAgentWithAfter",
    model=GEMINI_2_FLASH,
    instruction="You are a simple agent. Just say 'Processing complete!'",
    description="An LLM agent demonstrating after_agent_callback for output modification",
    after_agent_callback=modify_output_after_agent,  # Assign the callback here
)


# --- 3. Setup Runner and Sessions using InMemoryRunner ---
async def main():
    app_name = "after_agent_demo"
    user_id = "test_user_after"
    session_id_normal = "session_run_normally"
    session_id_modify = "session_modify_output"

    # Use InMemoryRunner - it includes InMemorySessionService
    runner = InMemoryRunner(agent=llm_agent_with_after_cb, app_name=app_name)
    # Get the bundled session service to create sessions
    session_service = runner.session_service

    # Create session 1: Agent output will be used as is (default empty state)
    session_service.create_session(
        app_name=app_name,
        user_id=user_id,
        session_id=session_id_normal,
        # No initial state means 'add_concluding_note' will be False in the callback check
    )
    # print(f"Session '{session_id_normal}' created with default state.")

    # Create session 2: Agent output will be replaced by the callback
    session_service.create_session(
        app_name=app_name,
        user_id=user_id,
        session_id=session_id_modify,
        state={"add_concluding_note": True},  # Set the state flag here
    )
    # print(f"Session '{session_id_modify}' created with state={{'add_concluding_note': True}}.")

    # --- Scenario 1: Run where callback allows agent's original output ---
    print(
        "\n"
        + "=" * 20
        + f" SCENARIO 1: Running Agent on Session '{session_id_normal}' (Should Use Original Output) "
        + "=" * 20
    )
    async for event in runner.run_async(
        user_id=user_id,
        session_id=session_id_normal,
        new_message=types.Content(
            role="user", parts=[types.Part(text="Process this please.")]
        ),
    ):
        # Print final output (either from LLM or callback override)
        if event.is_final_response() and event.content:
            print(
                f"Final Output: [{event.author}] {event.content.parts[0].text.strip()}"
            )
        elif event.is_error():
            print(f"Error Event: {event.error_details}")

    # --- Scenario 2: Run where callback replaces the agent's output ---
    print(
        "\n"
        + "=" * 20
        + f" SCENARIO 2: Running Agent on Session '{session_id_modify}' (Should Replace Output) "
        + "=" * 20
    )
    async for event in runner.run_async(
        user_id=user_id,
        session_id=session_id_modify,
        new_message=types.Content(
            role="user", parts=[types.Part(text="Process this and add note.")]
        ),
    ):
        # Print final output (either from LLM or callback override)
        if event.is_final_response() and event.content:
            print(
                f"Final Output: [{event.author}] {event.content.parts[0].text.strip()}"
            )
        elif event.is_error():
            print(f"Error Event: {event.error_details}")


# --- 4. Execute ---
# In a Python script:
# import asyncio
# if __name__ == "__main__":
#     # Make sure GOOGLE_API_KEY environment variable is set if not using Agent Platform auth
#     # Or ensure Application Default Credentials (ADC) are configured for Agent Platform
#     asyncio.run(main())

# In a Jupyter Notebook or similar environment:
await main()
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
import { LlmAgent, Context, isFinalResponse, InMemoryRunner } from '@google/adk';
import { createUserContent } from "@google/genai";

const MODEL_NAME = "gemini-2.5-flash";
const APP_NAME = "after_agent_callback_app";
const USER_ID = "test_user_after_agent";
const SESSION_NORMAL_ID = "session_run_normally_ts";
const SESSION_MODIFY_ID = "session_modify_output_ts";

// --- 1. Define the Callback Function ---
/**
 * Logs exit from an agent and checks "add_concluding_note" in session state.
 * If True, returns new Content to *replace* the agent's original output.
 * If False or not present, returns void, allowing the agent's original output to be used.
 */
function modifyOutputAfterAgent(context: Context): any {
  const agentName = context.agentName;
  const invocationId = context.invocationId;
  const currentState = context.state;

  console.log(
    `
[Callback] Exiting agent: ${agentName} (Inv: ${invocationId})`
  );
  console.log(`[Callback] Current State:`, currentState);

  // Example: Check state to decide whether to modify the final output
  if (currentState.get("add_concluding_note") === true) {
    console.log(
      `[Callback] State condition "add_concluding_note=true" met: Replacing agent ${agentName}'s output.`
    );
    // Return Content to *replace* the agent's own output
    return createUserContent(
      "Concluding note added by after_agent_callback, replacing original output."
    );
  } else {
    console.log(
      `[Callback] State condition not met: Using agent ${agentName}'s original output.`
    );
    // Return void/undefined - the agent's output will be used.
    return;
  }
}

// --- 2. Setup Agent with Callback ---
const llmAgentWithAfterCb = new LlmAgent({
  name: "MySimpleAgentWithAfter",
  model: MODEL_NAME,
  instruction: "You are a simple agent. Just say \"Processing complete!\"",
  description:
    "An LLM agent demonstrating after_agent_callback for output modification",
  afterAgentCallback: modifyOutputAfterAgent, // Assign the callback here
});

// --- 3. Run the Agent ---
async function main() {
  const runner = new InMemoryRunner({
    agent: llmAgentWithAfterCb,
    appName: APP_NAME,
  });

  // Create session 1: Agent output will be used as is (default empty state)
  await runner.sessionService.createSession({
    appName: APP_NAME,
    userId: USER_ID,
    sessionId: SESSION_NORMAL_ID,
  });

  // Create session 2: Agent output will be replaced by the callback
  await runner.sessionService.createSession({
    appName: APP_NAME,
    userId: USER_ID,
    sessionId: SESSION_MODIFY_ID,
    state: { add_concluding_note: true }, // Set the state flag here
  });

  // --- Scenario 1: Run where callback allows agent's original output ---
  console.log(
    `
==================== SCENARIO 1: Running Agent on Session "${SESSION_NORMAL_ID}" (Should Use Original Output) ====================
`
  );
  const eventsNormal = runner.runAsync({
    userId: USER_ID,
    sessionId: SESSION_NORMAL_ID,
    newMessage: createUserContent("Process this please."),
  });

  for await (const event of eventsNormal) {
    if (isFinalResponse(event) && event.content?.parts?.length) {
      const finalResponse = event.content.parts
        .map((part: any) => part.text ?? "")
        .join("");
      console.log(
        `Final Output: [${event.author}] ${finalResponse.trim()}`
      );
    } else if (event.errorMessage) {
      console.log(`Error Event: ${event.errorMessage}`);
    }
  }

  // --- Scenario 2: Run where callback replaces the agent's output ---
  console.log(
    `
==================== SCENARIO 2: Running Agent on Session "${SESSION_MODIFY_ID}" (Should Replace Output) ====================
`
  );
  const eventsModify = runner.runAsync({
    userId: USER_ID,
    sessionId: SESSION_MODIFY_ID,
    newMessage: createUserContent("Process this and add note."),
  });

  for await (const event of eventsModify) {
    if (isFinalResponse(event) && event.content?.parts?.length) {
      const finalResponse = event.content.parts
        .map((part: any) => part.text ?? "")
        .join("");
      console.log(
        `Final Output: [${event.author}] ${finalResponse.trim()}`
      );
    } else if (event.errorMessage) {
      console.log(`Error Event: ${event.errorMessage}`);
    }
  }
}

main();
```

```go
package main

import (
    "context"
    "fmt"
    "log"
    "regexp"
    "strings"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/runner"
    "google.golang.org/adk/session"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/functiontool"
    "google.golang.org/genai"
)



func onAfterAgent(ctx agent.CallbackContext) (*genai.Content, error) {
    agentName := ctx.AgentName()
    invocationID := ctx.InvocationID()
    state := ctx.State()

    log.Printf("\n[Callback] Exiting agent: %s (Inv: %s)", agentName, invocationID)
    log.Printf("[Callback] Current State: %v", state)

    if addNote, _ := state.Get("add_concluding_note"); addNote == true {
        log.Printf("[Callback] State condition 'add_concluding_note=True' met: Replacing agent %s's output.", agentName)
        return genai.NewContentFromText(
            "Concluding note added by after_agent_callback, replacing original output.",
            genai.RoleModel,
        ), nil
    }

    log.Printf("[Callback] State condition not met: Using agent %s's original output.", agentName)
    return nil, nil
}

func runAfterAgentExample() {
    ctx := context.Background()
    geminiModel, err := gemini.NewModel(ctx, modelName, &genai.ClientConfig{})
    if err != nil {
        log.Fatalf("FATAL: Failed to create model: %v", err)
    }

    llmCfg := llmagent.Config{
        Name:                "AgentWithAfterAgentCallback",
        AfterAgentCallbacks: []agent.AfterAgentCallback{onAfterAgent},
        Model:               geminiModel,
        Instruction:         "You are a simple agent. Just say 'Processing complete!'",
    }
    testAgent, err := llmagent.New(llmCfg)
    if err != nil {
        log.Fatalf("FATAL: Failed to create agent: %v", err)
    }

    sessionService := session.InMemoryService()
    r, err := runner.New(runner.Config{AppName: appName, Agent: testAgent, SessionService: sessionService})
    if err != nil {
        log.Fatalf("FATAL: Failed to create runner: %v", err)
    }

    log.Println("--- SCENARIO 1: Should use original output ---")
    runScenario(ctx, r, sessionService, appName, "session_normal", nil, "Process this.")

    log.Println("\n--- SCENARIO 2: Should replace output ---")
    runScenario(ctx, r, sessionService, appName, "session_modify", map[string]any{"add_concluding_note": true}, "Process and add note.")
}
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.CallbackContext;
import com.google.adk.events.Event;
import com.google.adk.runner.InMemoryRunner;
import com.google.adk.sessions.State;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import io.reactivex.rxjava3.core.Flowable;
import io.reactivex.rxjava3.core.Maybe;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class AfterAgentCallbackExample {

  // --- Constants ---
  private static final String APP_NAME = "after_agent_demo";
  private static final String USER_ID = "test_user_after";
  private static final String SESSION_ID_NORMAL = "session_run_normally";
  private static final String SESSION_ID_MODIFY = "session_modify_output";
  private static final String MODEL_NAME = "gemini-2.0-flash";

  public static void main(String[] args) {
    AfterAgentCallbackExample demo = new AfterAgentCallbackExample();
    demo.defineAgentAndRunScenarios();
  }

  // --- 1. Define the Callback Function ---
  /**
   * Log exit from an agent and checks 'add_concluding_note' in session state. If True, returns new
   * Content to *replace* the agent's original output. If False or not present, returns
   * Maybe.empty(), allowing the agent's original output to be used.
   */
  public Maybe<Content> modifyOutputAfterAgent(CallbackContext callbackContext) {
    String agentName = callbackContext.agentName();
    String invocationId = callbackContext.invocationId();
    State currentState = callbackContext.state();

    System.out.printf("%n[Callback] Exiting agent: %s (Inv: %s)%n", agentName, invocationId);
    System.out.printf("[Callback] Current State: %s%n", currentState.entrySet());

    Object addNoteFlag = currentState.get("add_concluding_note");

    // Example: Check state to decide whether to modify the final output
    if (Boolean.TRUE.equals(addNoteFlag)) {
      System.out.printf(
          "[Callback] State condition 'add_concluding_note=True' met: Replacing agent %s's"
              + " output.%n",
          agentName);

      // Return Content to *replace* the agent's own output
      return Maybe.just(
          Content.builder()
              .parts(
                  List.of(
                      Part.fromText(
                          "Concluding note added by after_agent_callback, replacing original output.")))
              .role("model") // Assign model role to the overriding response
              .build());

    } else {
      System.out.printf(
          "[Callback] State condition not met: Using agent %s's original output.%n", agentName);
      // Return None - the agent's output produced just before this callback will be used.
      return Maybe.empty();
    }
  }

  // --- 2. Setup Agent with Callback ---
  public void defineAgentAndRunScenarios() {
    LlmAgent llmAgentWithAfterCb =
        LlmAgent.builder()
            .name(APP_NAME)
            .model(MODEL_NAME)
            .description("An LLM agent demonstrating after_agent_callback for output modification")
            .instruction("You are a simple agent. Just say 'Processing complete!'")
            .afterAgentCallback(this::modifyOutputAfterAgent) // Assign the callback here
            .build();

    // --- 3. Setup Runner and Sessions using InMemoryRunner ---
    // Use InMemoryRunner - it includes InMemorySessionService
    InMemoryRunner runner = new InMemoryRunner(llmAgentWithAfterCb, APP_NAME);

    // --- Scenario 1: Run where callback allows agent's original output ---
    System.out.printf(
        "%n%s SCENARIO 1: Running Agent (Should Use Original Output) %s%n",
        "=".repeat(20), "=".repeat(20));
    // No initial state means 'add_concluding_note' will be false in the callback check
    runScenario(
        runner,
        llmAgentWithAfterCb.name(), // Use agent name for runner's appName consistency
        SESSION_ID_NORMAL,
        null,
        "Process this please.");

    // --- Scenario 2: Run where callback replaces the agent's output ---
    System.out.printf(
        "%n%s SCENARIO 2: Running Agent (Should Replace Output) %s%n",
        "=".repeat(20), "=".repeat(20));
    Map<String, Object> modifyState = new HashMap<>();
    modifyState.put("add_concluding_note", true); // Set the state flag here
    runScenario(
        runner,
        llmAgentWithAfterCb.name(), // Use agent name for runner's appName consistency
        SESSION_ID_MODIFY,
        new ConcurrentHashMap<>(modifyState),
        "Process this and add note.");
  }

  // --- 3. Method to Run a Single Scenario ---
  public void runScenario(
      InMemoryRunner runner,
      String appName,
      String sessionId,
      ConcurrentHashMap<String, Object> initialState,
      String userQuery) {

    // Create session using the runner's bundled session service
    runner.sessionService().createSession(appName, USER_ID, initialState, sessionId).blockingGet();

    System.out.printf(
        "Running scenario for session: %s, initial state: %s%n", sessionId, initialState);
    Content userMessage =
        Content.builder().role("user").parts(List.of(Part.fromText(userQuery))).build();

    Flowable<Event> eventStream = runner.runAsync(USER_ID, sessionId, userMessage);

    // Print final output
    eventStream.blockingForEach(
        event -> {
          if (event.finalResponse() && event.content().isPresent()) {
            String author = event.author() != null ? event.author() : "UNKNOWN";
            String text =
                event
                    .content()
                    .flatMap(Content::parts)
                    .filter(parts -> !parts.isEmpty())
                    .map(parts -> parts.get(0).text().orElse("").trim())
                    .orElse("[No text in final response]");
            System.out.printf("Final Output for %s: [%s] %s%n", sessionId, author, text);
          } else if (event.errorCode().isPresent()) {
            System.out.printf(
                "Error Event for %s: %s%n",
                sessionId, event.errorMessage().orElse("Unknown error"));
          }
        });
  }
}
```

**Note on the `after_agent_callback` Example:**

- **What it Shows:** This example demonstrates the `after_agent_callback`. This callback runs *right after* the agent's main processing logic has finished and produced its result, but *before* that result is finalized and returned.
- **How it Works:** The callback function (`modify_output_after_agent`) checks a flag (`add_concluding_note`) in the session's state.
  - If the flag is `True`, the callback returns a *new* `types.Content` object. This tells the ADK framework to **append** the agent's original output with the content returned by the callback.
  - If the flag is `False` (or not set), the callback returns `None` or an empty object. This tells the ADK framework to **use** the original output generated by the agent.
- **Expected Outcome:** You'll see two scenarios:
  1. In the session *without* the `add_concluding_note: True` state, the callback allows the agent's original output ("Processing complete!") to be used.
  1. In the session *with* that state flag, the callback intercepts the agent's original output and appends it with its own message ("Concluding note added...").
- **Understanding Callbacks:** This highlights how `after_` callbacks allow **post-processing** or **modification**. You can inspect the result of a step (the agent's run) and decide whether to let it pass through, change it, or completely replace it based on your logic.

## LLM Interaction Callbacks

These callbacks are specific to `LlmAgent` and provide hooks around the interaction with the Large Language Model.

### Before Model Callback

**When:** Called just before the `generate_content_async` (or equivalent) request is sent to the LLM within an `LlmAgent`'s flow.

**Purpose:** Allows inspection and modification of the request going to the LLM. Use cases include adding dynamic instructions, injecting few-shot examples based on state, modifying model config, implementing guardrails (like profanity filters), or implementing request-level caching.

**Return Value Effect:** If the callback returns `None` (or a `Maybe.empty()` object in Java), the LLM continues its normal workflow. If the callback returns an `LlmResponse` object, then the call to the LLM is **skipped**. The returned `LlmResponse` is used directly as if it came from the model. This is powerful for implementing guardrails or caching.

Code

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

from google.adk.agents import LlmAgent
from google.adk.agents.callback_context import CallbackContext
from google.adk.models import LlmResponse, LlmRequest
from google.adk.runners import Runner
from typing import Optional
from google.genai import types 
from google.adk.sessions import InMemorySessionService

GEMINI_2_FLASH="gemini-2.0-flash"

# --- Define the Callback Function ---
def simple_before_model_modifier(
    callback_context: CallbackContext, llm_request: LlmRequest
) -> Optional[LlmResponse]:
    """Inspects/modifies the LLM request or skips the call."""
    agent_name = callback_context.agent_name
    print(f"[Callback] Before model call for agent: {agent_name}")

    # Inspect the last user message in the request contents
    last_user_message = ""
    if llm_request.contents and llm_request.contents[-1].role == 'user':
         if llm_request.contents[-1].parts:
            last_user_message = llm_request.contents[-1].parts[0].text
    print(f"[Callback] Inspecting last user message: '{last_user_message}'")

    # --- Modification Example ---
    # Add a prefix to the system instruction
    original_instruction = llm_request.config.system_instruction or types.Content(role="system", parts=[])
    prefix = "[Modified by Callback] "
    # Ensure system_instruction is Content and parts list exists
    if not isinstance(original_instruction, types.Content):
         # Handle case where it might be a string (though config expects Content)
         original_instruction = types.Content(role="system", parts=[types.Part(text=str(original_instruction))])
    if not original_instruction.parts:
        original_instruction.parts.append(types.Part(text="")) # Add an empty part if none exist

    # Modify the text of the first part
    modified_text = prefix + (original_instruction.parts[0].text or "")
    original_instruction.parts[0].text = modified_text
    llm_request.config.system_instruction = original_instruction
    print(f"[Callback] Modified system instruction to: '{modified_text}'")

    # --- Skip Example ---
    # Check if the last user message contains "BLOCK"
    if "BLOCK" in last_user_message.upper():
        print("[Callback] 'BLOCK' keyword found. Skipping LLM call.")
        # Return an LlmResponse to skip the actual LLM call
        return LlmResponse(
            content=types.Content(
                role="model",
                parts=[types.Part(text="LLM call was blocked by before_model_callback.")],
            )
        )
    else:
        print("[Callback] Proceeding with LLM call.")
        # Return None to allow the (modified) request to go to the LLM
        return None


# Create LlmAgent and Assign Callback
my_llm_agent = LlmAgent(
        name="ModelCallbackAgent",
        model=GEMINI_2_FLASH,
        instruction="You are a helpful assistant.", # Base instruction
        description="An LLM agent demonstrating before_model_callback",
        before_model_callback=simple_before_model_modifier # Assign the function here
)

APP_NAME = "guardrail_app"
USER_ID = "user_1"
SESSION_ID = "session_001"

# Session and Runner
async def setup_session_and_runner():
    session_service = InMemorySessionService()
    session = await session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID)
    runner = Runner(agent=my_llm_agent, app_name=APP_NAME, session_service=session_service)
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
await call_agent_async("write a joke on BLOCK")
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

import { LlmAgent, InMemoryRunner, Context, isFinalResponse } from '@google/adk';
import { createUserContent } from "@google/genai";

const MODEL_NAME = "gemini-2.5-flash";
const APP_NAME = "before_model_callback_app";
const USER_ID = "test_user_before_model";
const SESSION_ID_BLOCK = "session_block_model_call";
const SESSION_ID_NORMAL = "session_normal_model_call";

// --- Define the Callback Function ---
function simpleBeforeModelModifier({
  context,
  request,
}: {
  context: Context;
  request: any;
}): any | undefined {
  console.log(`[Callback] Before model call for agent: ${context.agentName}`);

  // Inspect the last user message in the request contents
  const lastUserMessage = request.contents?.at(-1)?.parts?.[0]?.text ?? "";
  console.log(`[Callback] Inspecting last user message: '${lastUserMessage}'`);

  // --- Modification Example ---
  // Add a prefix to the system instruction.
  // We create a deep copy to avoid modifying the original agent's config object.
  const modifiedConfig = JSON.parse(JSON.stringify(request.config));
  const originalInstructionText =
    modifiedConfig.systemInstruction?.parts?.[0]?.text ?? "";
  const prefix = "[Modified by Callback] ";
  modifiedConfig.systemInstruction = {
    role: "system",
    parts: [{ text: prefix + originalInstructionText }],
  };
  request.config = modifiedConfig; // Assign the modified config back to the request
  console.log(
    `[Callback] Modified system instruction to: '${modifiedConfig.systemInstruction.parts[0].text}'`
  );

  // --- Skip Example ---
  // Check if the last user message contains "BLOCK"
  if (lastUserMessage.toUpperCase().includes("BLOCK")) {
    console.log("[Callback] 'BLOCK' keyword found. Skipping LLM call.");
    // Return an LlmResponse to skip the actual LLM call
    return {
      content: {
        role: "model",
        parts: [
          { text: "LLM call was blocked by the before_model_callback." },
        ],
      },
    };
  }

  console.log("[Callback] Proceeding with LLM call.");
  // Return undefined to allow the (modified) request to go to the LLM
  return undefined;
}

// --- Create LlmAgent and Assign Callback ---
const myLlmAgent = new LlmAgent({
  name: "ModelCallbackAgent",
  model: MODEL_NAME,
  instruction: "You are a helpful assistant.", // Base instruction
  description: "An LLM agent demonstrating before_model_callback",
  beforeModelCallback: simpleBeforeModelModifier, // Assign the function here
});

// --- Agent Interaction Logic ---
async function callAgentAndPrint(
  runner: InMemoryRunner,
  query: string,
  sessionId: string
) {
  console.log(`\n>>> Calling Agent with query: "${query}"`);

  let finalResponseContent = "No final response received.";
  const events = runner.runAsync({ userId: USER_ID, sessionId, newMessage: createUserContent(query) });

  for await (const event of events) {
    if (isFinalResponse(event) && event.content?.parts?.length) {
      finalResponseContent = event.content.parts
        .map((part: { text?: string }) => part.text ?? "")
        .join("");
    }
  }
  console.log("<<< Agent Response: ", finalResponseContent);
}

// --- Run Interactions ---
async function main() {
  const runner = new InMemoryRunner({ agent: myLlmAgent, appName: APP_NAME });

  // Scenario 1: The callback will find "BLOCK" and skip the model call
  await runner.sessionService.createSession({
    appName: APP_NAME,
    userId: USER_ID,
    sessionId: SESSION_ID_BLOCK,
  });
  await callAgentAndPrint(
    runner,
    "write a joke about BLOCK",
    SESSION_ID_BLOCK
  );

  // Scenario 2: The callback will modify the instruction and proceed
  await runner.sessionService.createSession({
    appName: APP_NAME,
    userId: USER_ID,
    sessionId: SESSION_ID_NORMAL,
  });
  await callAgentAndPrint(runner, "write a short poem", SESSION_ID_NORMAL);
}

main();
```

```go
package main

import (
    "context"
    "fmt"
    "log"
    "regexp"
    "strings"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/runner"
    "google.golang.org/adk/session"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/functiontool"
    "google.golang.org/genai"
)



func onBeforeModel(ctx agent.CallbackContext, req *model.LLMRequest) (*model.LLMResponse, error) {
    log.Printf("[Callback] BeforeModel triggered for agent %q.", ctx.AgentName())

    // Modification Example: Add a prefix to the system instruction.
    if req.Config.SystemInstruction != nil {
        prefix := "[Modified by Callback] "
        // This is a simplified example; production code might need deeper checks.
        if len(req.Config.SystemInstruction.Parts) > 0 {
            req.Config.SystemInstruction.Parts[0].Text = prefix + req.Config.SystemInstruction.Parts[0].Text
        } else {
            req.Config.SystemInstruction.Parts = append(req.Config.SystemInstruction.Parts, &genai.Part{Text: prefix})
        }
        log.Printf("[Callback] Modified system instruction.")
    }

    // Skip Example: Check for "BLOCK" in the user's prompt.
    for _, content := range req.Contents {
        for _, part := range content.Parts {
            if strings.Contains(strings.ToUpper(part.Text), "BLOCK") {
                log.Println("[Callback] 'BLOCK' keyword found. Skipping LLM call.")
                return &model.LLMResponse{
                    Content: &genai.Content{
                        Parts: []*genai.Part{{Text: "LLM call was blocked by before_model_callback."}},
                        Role:  "model",
                    },
                }, nil
            }
        }
    }

    log.Println("[Callback] Proceeding with LLM call.")
    return nil, nil
}

func runBeforeModelExample() {
    ctx := context.Background()
    geminiModel, err := gemini.NewModel(ctx, modelName, &genai.ClientConfig{})
    if err != nil {
        log.Fatalf("FATAL: Failed to create model: %v", err)
    }

    llmCfg := llmagent.Config{
        Name:                 "AgentWithBeforeModelCallback",
        Model:                geminiModel,
        BeforeModelCallbacks: []llmagent.BeforeModelCallback{onBeforeModel},
    }
    testAgent, err := llmagent.New(llmCfg)
    if err != nil {
        log.Fatalf("FATAL: Failed to create agent: %v", err)
    }

    sessionService := session.InMemoryService()
    r, err := runner.New(runner.Config{AppName: appName, Agent: testAgent, SessionService: sessionService})
    if err != nil {
        log.Fatalf("FATAL: Failed to create runner: %v", err)
    }

    log.Println("--- SCENARIO 1: Should proceed to LLM ---")
    runScenario(ctx, r, sessionService, appName, "session_normal", nil, "Tell me a fun fact.")

    log.Println("\n--- SCENARIO 2: Should be blocked by callback ---")
    runScenario(ctx, r, sessionService, appName, "session_blocked", nil, "write a joke on BLOCK")
}
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.CallbackContext;
import com.google.adk.events.Event;
import com.google.adk.models.LlmRequest;
import com.google.adk.models.LlmResponse;
import com.google.adk.runner.InMemoryRunner;
import com.google.adk.sessions.Session;
import com.google.common.collect.ImmutableList;
import com.google.common.collect.Iterables;
import com.google.genai.types.Content;
import com.google.genai.types.GenerateContentConfig;
import com.google.genai.types.Part;
import io.reactivex.rxjava3.core.Flowable;
import io.reactivex.rxjava3.core.Maybe;
import java.util.ArrayList;
import java.util.List;

public class BeforeModelCallbackExample {

  // --- Define Constants ---
  private static final String AGENT_NAME = "ModelCallbackAgent";
  private static final String MODEL_NAME = "gemini-2.0-flash";
  private static final String AGENT_INSTRUCTION = "You are a helpful assistant.";
  private static final String AGENT_DESCRIPTION =
      "An LLM agent demonstrating before_model_callback";

  // For session and runner
  private static final String APP_NAME = "guardrail_app_java";
  private static final String USER_ID = "user_1_java";

  public static void main(String[] args) {
    BeforeModelCallbackExample demo = new BeforeModelCallbackExample();
    demo.defineAgentAndRun();
  }

  // --- 1. Define the Callback Function ---
  // Inspects/modifies the LLM request or skips the actual LLM call.
  public Maybe<LlmResponse> simpleBeforeModelModifier(
      CallbackContext callbackContext, LlmRequest llmRequest) {
    String agentName = callbackContext.agentName();
    System.out.printf("%n[Callback] Before model call for agent: %s%n", agentName);

    String lastUserMessage = "";
    if (llmRequest.contents() != null && !llmRequest.contents().isEmpty()) {
      Content lastContentItem = Iterables.getLast(llmRequest.contents());
      if ("user".equals(lastContentItem.role().orElse(null))
          && lastContentItem.parts().isPresent()
          && !lastContentItem.parts().get().isEmpty()) {
        lastUserMessage = lastContentItem.parts().get().get(0).text().orElse("");
      }
    }
    System.out.printf("[Callback] Inspecting last user message: '%s'%n", lastUserMessage);

    // --- Modification Example ---
    // Add a prefix to the system instruction
    Content systemInstructionFromRequest = Content.builder().parts(ImmutableList.of()).build();
    // Ensure system_instruction is Content and parts list exists
    if (llmRequest.config().isPresent()) {
      systemInstructionFromRequest =
          llmRequest
              .config()
              .get()
              .systemInstruction()
              .orElseGet(() -> Content.builder().role("system").parts(ImmutableList.of()).build());
    }
    List<Part> currentSystemParts =
        new ArrayList<>(systemInstructionFromRequest.parts().orElse(ImmutableList.of()));
    // Ensure a part exists for modification
    if (currentSystemParts.isEmpty()) {
      currentSystemParts.add(Part.fromText(""));
    }
    // Modify the text of the first part
    String prefix = "[Modified by Callback] ";
    String conceptuallyModifiedText = prefix + currentSystemParts.get(0).text().orElse("");
    llmRequest =
        llmRequest.toBuilder()
            .config(
                GenerateContentConfig.builder()
                    .systemInstruction(
                        Content.builder()
                            .parts(List.of(Part.fromText(conceptuallyModifiedText)))
                            .build())
                    .build())
            .build();
    System.out.printf(
        "Modified System Instruction %s", llmRequest.config().get().systemInstruction());

    // --- Skip Example ---
    // Check if the last user message contains "BLOCK"
    if (lastUserMessage.toUpperCase().contains("BLOCK")) {
      System.out.println("[Callback] 'BLOCK' keyword found. Skipping LLM call.");
      // Return an LlmResponse to skip the actual LLM call
      return Maybe.just(
          LlmResponse.builder()
              .content(
                  Content.builder()
                      .role("model")
                      .parts(
                          ImmutableList.of(
                              Part.fromText("LLM call was blocked by before_model_callback.")))
                      .build())
              .build());
    }

    // Return Empty response to allow the (modified) request to go to the LLM
    System.out.println("[Callback] Proceeding with LLM call (using the original LlmRequest).");
    return Maybe.empty();
  }

  // --- 2. Define Agent and Run Scenarios ---
  public void defineAgentAndRun() {
    // Setup Agent with Callback
    LlmAgent myLlmAgent =
        LlmAgent.builder()
            .name(AGENT_NAME)
            .model(MODEL_NAME)
            .instruction(AGENT_INSTRUCTION)
            .description(AGENT_DESCRIPTION)
            .beforeModelCallback(this::simpleBeforeModelModifier)
            .build();

    // Create an InMemoryRunner
    InMemoryRunner runner = new InMemoryRunner(myLlmAgent, APP_NAME);
    // InMemoryRunner automatically creates a session service. Create a session using the service
    Session session = runner.sessionService().createSession(APP_NAME, USER_ID).blockingGet();
    Content userMessage =
        Content.fromParts(
            Part.fromText("Tell me about quantum computing. This is a test. So BLOCK."));

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
}
```

### After Model Callback

**When:** Called just after a response (`LlmResponse`) is received from the LLM, before it's processed further by the invoking agent.

**Purpose:** Allows inspection or modification of the raw LLM response. Use cases include

- logging model outputs,
- reformatting responses,
- censoring sensitive information generated by the model,
- parsing structured data from the LLM response and storing it in `callback_context.state`
- or handling specific error codes.

Code

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

from google.adk.agents import LlmAgent
from google.adk.agents.callback_context import CallbackContext
from google.adk.runners import Runner
from typing import Optional
from google.genai import types 
from google.adk.sessions import InMemorySessionService
from google.adk.models import LlmResponse
from copy import deepcopy

GEMINI_2_FLASH="gemini-2.0-flash"

# --- Define the Callback Function ---
def simple_after_model_modifier(
    callback_context: CallbackContext, llm_response: LlmResponse
) -> Optional[LlmResponse]:
    """Inspects/modifies the LLM response after it's received."""
    agent_name = callback_context.agent_name
    print(f"[Callback] After model call for agent: {agent_name}")

    # --- Inspection ---
    original_text = ""
    if llm_response.content and llm_response.content.parts:
        # Assuming simple text response for this example
        if llm_response.content.parts[0].text:
            original_text = llm_response.content.parts[0].text
            print(f"[Callback] Inspected original response text: '{original_text[:100]}...'") # Log snippet
        elif llm_response.content.parts[0].function_call:
             print(f"[Callback] Inspected response: Contains function call '{llm_response.content.parts[0].function_call.name}'. No text modification.")
             return None # Don't modify tool calls in this example
        else:
             print("[Callback] Inspected response: No text content found.")
             return None
    elif llm_response.error_message:
        print(f"[Callback] Inspected response: Contains error '{llm_response.error_message}'. No modification.")
        return None
    else:
        print("[Callback] Inspected response: Empty LlmResponse.")
        return None # Nothing to modify

    # --- Modification Example ---
    # Replace "joke" with "funny story" (case-insensitive)
    search_term = "joke"
    replace_term = "funny story"
    if search_term in original_text.lower():
        print(f"[Callback] Found '{search_term}'. Modifying response.")
        modified_text = original_text.replace(search_term, replace_term)
        modified_text = modified_text.replace(search_term.capitalize(), replace_term.capitalize()) # Handle capitalization

        # Create a NEW LlmResponse with the modified content
        # Deep copy parts to avoid modifying original if other callbacks exist
        modified_parts = [deepcopy(part) for part in llm_response.content.parts]
        modified_parts[0].text = modified_text # Update the text in the copied part

        new_response = LlmResponse(
             content=types.Content(role="model", parts=modified_parts),
             # Copy other relevant fields if necessary, e.g., grounding_metadata
             grounding_metadata=llm_response.grounding_metadata
             )
        print(f"[Callback] Returning modified response.")
        return new_response # Return the modified response
    else:
        print(f"[Callback] '{search_term}' not found. Passing original response through.")
        # Return None to use the original llm_response
        return None


# Create LlmAgent and Assign Callback
my_llm_agent = LlmAgent(
        name="AfterModelCallbackAgent",
        model=GEMINI_2_FLASH,
        instruction="You are a helpful assistant.",
        description="An LLM agent demonstrating after_model_callback",
        after_model_callback=simple_after_model_modifier # Assign the function here
)

APP_NAME = "guardrail_app"
USER_ID = "user_1"
SESSION_ID = "session_001"

# Session and Runner
async def setup_session_and_runner():
    session_service = InMemorySessionService()
    session = await session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID)
    runner = Runner(agent=my_llm_agent, app_name=APP_NAME, session_service=session_service)
    return session, runner

# Agent Interaction
async def call_agent_async(query):
  session, runner = await setup_session_and_runner()

  content = types.Content(role='user', parts=[types.Part(text=query)])
  events = runner.run_async(user_id=USER_ID, session_id=SESSION_ID, new_message=content)

  async for event in events:
      if event.is_final_response():
          final_response = event.content.parts[0].text
          print("Agent Response: ", final_response)

# Note: In Colab, you can directly use 'await' at the top level.
# If running this code as a standalone Python script, you'll need to use asyncio.run() or manage the event loop.
await call_agent_async("""write multiple time the word "joke" """)
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

import { LlmAgent, InMemoryRunner, Context, isFinalResponse } from '@google/adk';
import { createUserContent } from "@google/genai";

const MODEL_NAME = "gemini-2.5-flash";
const APP_NAME = "after_model_callback_app";
const USER_ID = "test_user_after_model";
const SESSION_ID_JOKE = "session_modify_model_call";
const SESSION_ID_POEM = "session_normal_model_call";

// --- Define the Callback Function ---
function simpleAfterModelModifier({
  context,
  response,
}: {
  context: Context;
  response: any;
}): any | undefined {
  console.log(
    `[Callback] After model call for agent: ${context.agentName}`
  );

  const modelResponseText = response.content?.parts?.[0]?.text ?? "";
  console.log(`[Callback] Inspecting model response: "${modelResponseText.substring(0, 50)}..."`);

  // --- Modification Example ---
  // Replace "joke" with "funny story" (case-insensitive)
  const searchTerm = "joke";
  const replaceTerm = "funny story";
  if (modelResponseText.toLowerCase().includes(searchTerm)) {
    console.log(`[Callback] Found '${searchTerm}'. Modifying response.`);

    // Create a deep copy to avoid mutating the original response object
    const modifiedResponse = JSON.parse(JSON.stringify(response));

    // Safely modify the text of the first part
    if (modifiedResponse.content?.parts?.[0]) {
      // Use a regular expression for case-insensitive replacement
      const regex = new RegExp(searchTerm, "gi");
      modifiedResponse.content.parts[0].text = modelResponseText.replace(regex, replaceTerm);
    }

    console.log(`[Callback] Returning modified response.`);
    return modifiedResponse;
  }

  console.log("[Callback] Proceeding with original LLM response.");
  // Return undefined to proceed without any modifications
  return undefined;
}


// --- Create LlmAgent and Assign Callback ---
const myLlmAgent = new LlmAgent({
  name: "AfterModelCallbackAgent",
  model: MODEL_NAME,
  instruction: "You are a helpful assistant who tells jokes.",
  description: "An LLM agent demonstrating after_model_callback",
  afterModelCallback: simpleAfterModelModifier, // Assign the function here
});

// --- Agent Interaction Logic ---
async function callAgentAndPrint({runner, query, sessionId,}: {  runner: InMemoryRunner;  query: string;  sessionId: string;}) {
  console.log(`\n>>> Calling Agent with query: "${query}"`);

  let finalResponseContent = "No final response received.";
  const events = runner.runAsync({
    userId: USER_ID,
    sessionId: sessionId,
    newMessage: createUserContent(query),
  });

  for await (const event of events) {
    if (isFinalResponse(event) && event.content?.parts?.length) {
      finalResponseContent = event.content.parts
        .map((part: { text?: string }) => part.text ?? "")
        .join("");
    }
  }
  console.log("<<< Agent Response: ", finalResponseContent);
}

// --- Run Interactions ---
async function main() {
  const runner = new InMemoryRunner({ agent: myLlmAgent, appName: APP_NAME });

  // Scenario 1: The callback will find "joke" and modify the response
  await runner.sessionService.createSession({
    appName: APP_NAME,
    userId: USER_ID,
    sessionId: SESSION_ID_JOKE,
  });
  await callAgentAndPrint({
    runner: runner,
    query: 'write a short joke about computers',
    sessionId: SESSION_ID_JOKE,
  });

  // Scenario 2: The callback will not find "joke" and will pass the response through unmodified
  await runner.sessionService.createSession({
    appName: APP_NAME,
    userId: USER_ID,
    sessionId: SESSION_ID_POEM,
  });
  await callAgentAndPrint({
    runner: runner,
    query: 'write a short poem about coding',
    sessionId: SESSION_ID_POEM,
  });
}

main();
```

```go
package main

import (
    "context"
    "fmt"
    "log"
    "regexp"
    "strings"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/runner"
    "google.golang.org/adk/session"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/functiontool"
    "google.golang.org/genai"
)



func onAfterModel(ctx agent.CallbackContext, resp *model.LLMResponse, respErr error) (*model.LLMResponse, error) {
    log.Printf("[Callback] AfterModel triggered for agent %q.", ctx.AgentName())
    if respErr != nil {
        log.Printf("[Callback] Model returned an error: %v. Passing it through.", respErr)
        return nil, respErr
    }
    if resp == nil || resp.Content == nil || len(resp.Content.Parts) == 0 {
        log.Println("[Callback] Response is nil or has no parts, nothing to process.")
        return nil, nil
    }
    // Check for function calls and pass them through without modification.
    if resp.Content.Parts[0].FunctionCall != nil {
        log.Println("[Callback] Response is a function call. No modification.")
        return nil, nil
    }

    originalText := resp.Content.Parts[0].Text

    // Use a case-insensitive regex with word boundaries to find "joke".
    re := regexp.MustCompile(`(?i)\bjoke\b`)
    if !re.MatchString(originalText) {
        log.Println("[Callback] 'joke' not found. Passing original response through.")
        return nil, nil
    }

    log.Println("[Callback] 'joke' found. Modifying response.")
    // Use a replacer function to handle capitalization.
    modifiedText := re.ReplaceAllStringFunc(originalText, func(s string) string {
        if strings.ToUpper(s) == "JOKE" {
            if s == "Joke" {
                return "Funny story"
            }
            return "funny story"
        }
        return s // Should not be reached with this regex, but it's safe.
    })

    resp.Content.Parts[0].Text = modifiedText
    return resp, nil
}

func runAfterModelExample() {
    ctx := context.Background()
    geminiModel, err := gemini.NewModel(ctx, modelName, &genai.ClientConfig{})
    if err != nil {
        log.Fatalf("FATAL: Failed to create model: %v", err)
    }

    llmCfg := llmagent.Config{
        Name:                "AgentWithAfterModelCallback",
        Model:               geminiModel,
        AfterModelCallbacks: []llmagent.AfterModelCallback{onAfterModel},
    }
    testAgent, err := llmagent.New(llmCfg)
    if err != nil {
        log.Fatalf("FATAL: Failed to create agent: %v", err)
    }

    sessionService := session.InMemoryService()
    r, err := runner.New(runner.Config{AppName: appName, Agent: testAgent, SessionService: sessionService})
    if err != nil {
        log.Fatalf("FATAL: Failed to create runner: %v", err)
    }

    log.Println("--- SCENARIO 1: Response should be modified ---")
    runScenario(ctx, r, sessionService, appName, "session_modify", nil, `Give me a paragraph about different styles of jokes.`)
}
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.CallbackContext;
import com.google.adk.events.Event;
import com.google.adk.models.LlmResponse;
import com.google.adk.runner.InMemoryRunner;
import com.google.adk.sessions.Session;
import com.google.common.collect.ImmutableList;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import io.reactivex.rxjava3.core.Flowable;
import io.reactivex.rxjava3.core.Maybe;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class AfterModelCallbackExample {

  // --- Define Constants ---
  private static final String AGENT_NAME = "AfterModelCallbackAgent";
  private static final String MODEL_NAME = "gemini-2.0-flash";
  private static final String AGENT_INSTRUCTION = "You are a helpful assistant.";
  private static final String AGENT_DESCRIPTION = "An LLM agent demonstrating after_model_callback";

  // For session and runner
  private static final String APP_NAME = "AfterModelCallbackAgentApp";
  private static final String USER_ID = "user_1";

  // For text replacement
  private static final String SEARCH_TERM = "joke";
  private static final String REPLACE_TERM = "funny story";
  private static final Pattern SEARCH_PATTERN =
      Pattern.compile("\\b" + Pattern.quote(SEARCH_TERM) + "\\b", Pattern.CASE_INSENSITIVE);

  public static void main(String[] args) {
    AfterModelCallbackExample example = new AfterModelCallbackExample();
    example.defineAgentAndRun();
  }

  // --- Define the Callback Function ---
  // Inspects/modifies the LLM response after it's received.
  public Maybe<LlmResponse> simpleAfterModelModifier(
      CallbackContext callbackContext, LlmResponse llmResponse) {
    String agentName = callbackContext.agentName();
    System.out.printf("%n[Callback] After model call for agent: %s%n", agentName);

    // --- Inspection Phase ---
    if (llmResponse.errorMessage().isPresent()) {
      System.out.printf(
          "[Callback] Response has error: '%s'. No modification.%n",
          llmResponse.errorMessage().get());
      return Maybe.empty(); // Pass through errors
    }

    Optional<Part> firstTextPartOpt =
        llmResponse
            .content()
            .flatMap(Content::parts)
            .filter(parts -> !parts.isEmpty() && parts.get(0).text().isPresent())
            .map(parts -> parts.get(0));

    if (!firstTextPartOpt.isPresent()) {
      // Could be a function call, empty content, or no text in the first part
      llmResponse
          .content()
          .flatMap(Content::parts)
          .filter(parts -> !parts.isEmpty() && parts.get(0).functionCall().isPresent())
          .ifPresent(
              parts ->
                  System.out.printf(
                      "[Callback] Response is a function call ('%s'). No text modification.%n",
                      parts.get(0).functionCall().get().name().orElse("N/A")));
      if (!llmResponse.content().isPresent()
          || !llmResponse.content().flatMap(Content::parts).isPresent()
          || llmResponse.content().flatMap(Content::parts).get().isEmpty()) {
        System.out.println(
            "[Callback] Response content is empty or has no parts. No modification.");
      } else if (!firstTextPartOpt.isPresent()) { // Already checked for function call
        System.out.println("[Callback] First part has no text content. No modification.");
      }
      return Maybe.empty(); // Pass through non-text or unsuitable responses
    }

    String originalText = firstTextPartOpt.get().text().get();
    System.out.printf("[Callback] Inspected original text: '%.100s...'%n", originalText);

    // --- Modification Phase ---
    Matcher matcher = SEARCH_PATTERN.matcher(originalText);
    if (!matcher.find()) {
      System.out.printf(
          "[Callback] '%s' not found. Passing original response through.%n", SEARCH_TERM);
      return Maybe.empty();
    }

    System.out.printf("[Callback] Found '%s'. Modifying response.%n", SEARCH_TERM);

    // Perform the replacement, respecting original capitalization of the found term's first letter
    String foundTerm = matcher.group(0); // The actual term found (e.g., "joke" or "Joke")
    String actualReplaceTerm = REPLACE_TERM;
    if (Character.isUpperCase(foundTerm.charAt(0)) && REPLACE_TERM.length() > 0) {
      actualReplaceTerm = Character.toUpperCase(REPLACE_TERM.charAt(0)) + REPLACE_TERM.substring(1);
    }
    String modifiedText = matcher.replaceFirst(Matcher.quoteReplacement(actualReplaceTerm));

    // Create a new LlmResponse with the modified content
    Content originalContent = llmResponse.content().get();
    List<Part> originalParts = originalContent.parts().orElse(ImmutableList.of());

    List<Part> modifiedPartsList = new ArrayList<>(originalParts.size());
    if (!originalParts.isEmpty()) {
      modifiedPartsList.add(Part.fromText(modifiedText)); // Replace first part's text
      // Add remaining parts as they were (shallow copy)
      for (int i = 1; i < originalParts.size(); i++) {
        modifiedPartsList.add(originalParts.get(i));
      }
    } else { // Should not happen if firstTextPartOpt was present
      modifiedPartsList.add(Part.fromText(modifiedText));
    }

    LlmResponse.Builder newResponseBuilder =
        LlmResponse.builder()
            .content(
                originalContent.toBuilder().parts(ImmutableList.copyOf(modifiedPartsList)).build())
            .groundingMetadata(llmResponse.groundingMetadata());

    System.out.println("[Callback] Returning modified response.");
    return Maybe.just(newResponseBuilder.build());
  }

  // --- 2. Define Agent and Run Scenarios ---
  public void defineAgentAndRun() {
    // Setup Agent with Callback
    LlmAgent myLlmAgent =
        LlmAgent.builder()
            .name(AGENT_NAME)
            .model(MODEL_NAME)
            .instruction(AGENT_INSTRUCTION)
            .description(AGENT_DESCRIPTION)
            .afterModelCallback(this::simpleAfterModelModifier)
            .build();

    // Create an InMemoryRunner
    InMemoryRunner runner = new InMemoryRunner(myLlmAgent, APP_NAME);
    // InMemoryRunner automatically creates a session service. Create a session using the service
    Session session = runner.sessionService().createSession(APP_NAME, USER_ID).blockingGet();
    Content userMessage =
        Content.fromParts(
            Part.fromText(
                "Tell me a joke about quantum computing. Include the word 'joke' in your response"));

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
}
```

## Tool Execution Callbacks

These callbacks are also specific to `LlmAgent` and trigger around the execution of tools (including `FunctionTool`, `AgentTool`, etc.) that the LLM might request.

### Before Tool Callback

**When:** Called just before a specific tool's `run_async` method is invoked, after the LLM has generated a function call for it.

**Purpose:** Allows inspection and modification of tool arguments, performing authorization checks before execution, logging tool usage attempts, or implementing tool-level caching.

**Return Value Effect:**

1. If the callback returns `None` (or a `Maybe.empty()` object in Java), the tool's `run_async` method is executed with the (potentially modified) `args`.
1. If a dictionary (or `Map` in Java) is returned, the tool's `run_async` method is **skipped**. The returned dictionary is used directly as the result of the tool call. This is useful for caching or overriding tool behavior.

Code

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

from google.adk.agents import LlmAgent
from google.adk.runners import Runner
from typing import Optional
from google.genai import types 
from google.adk.sessions import InMemorySessionService
from google.adk.tools import FunctionTool
from google.adk.tools.tool_context import ToolContext
from google.adk.tools.base_tool import BaseTool
from typing import Dict, Any


GEMINI_2_FLASH="gemini-2.0-flash"

def get_capital_city(country: str) -> str:
    """Retrieves the capital city of a given country."""
    print(f"--- Tool 'get_capital_city' executing with country: {country} ---")
    country_capitals = {
        "united states": "Washington, D.C.",
        "canada": "Ottawa",
        "france": "Paris",
        "germany": "Berlin",
    }
    return country_capitals.get(country.lower(), f"Capital not found for {country}")

capital_tool = FunctionTool(func=get_capital_city)

def simple_before_tool_modifier(
    tool: BaseTool, args: Dict[str, Any], tool_context: ToolContext
) -> Optional[Dict]:
    """Inspects/modifies tool args or skips the tool call."""
    agent_name = tool_context.agent_name
    tool_name = tool.name
    print(f"[Callback] Before tool call for tool '{tool_name}' in agent '{agent_name}'")
    print(f"[Callback] Original args: {args}")

    if tool_name == 'get_capital_city' and args.get('country', '').lower() == 'canada':
        print("[Callback] Detected 'Canada'. Modifying args to 'France'.")
        args['country'] = 'France'
        print(f"[Callback] Modified args: {args}")
        return None

    # If the tool is 'get_capital_city' and country is 'BLOCK'
    if tool_name == 'get_capital_city' and args.get('country', '').upper() == 'BLOCK':
        print("[Callback] Detected 'BLOCK'. Skipping tool execution.")
        return {"result": "Tool execution was blocked by before_tool_callback."}

    print("[Callback] Proceeding with original or previously modified args.")
    return None

my_llm_agent = LlmAgent(
        name="ToolCallbackAgent",
        model=GEMINI_2_FLASH,
        instruction="You are an agent that can find capital cities. Use the get_capital_city tool.",
        description="An LLM agent demonstrating before_tool_callback",
        tools=[capital_tool],
        before_tool_callback=simple_before_tool_modifier
)

APP_NAME = "guardrail_app"
USER_ID = "user_1"
SESSION_ID = "session_001"

# Session and Runner
async def setup_session_and_runner():
    session_service = InMemorySessionService()
    session = await session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID)
    runner = Runner(agent=my_llm_agent, app_name=APP_NAME, session_service=session_service)
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
await call_agent_async("Canada")
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
import { LlmAgent, InMemoryRunner, FunctionTool, Context, isFinalResponse, BaseTool } from '@google/adk';
import { createUserContent } from "@google/genai";
import { z } from 'zod';

const MODEL_NAME = "gemini-2.5-flash";
const APP_NAME = "before_tool_callback_app";
const USER_ID = "test_user_before_tool";

// --- Define a Simple Tool Function ---
const CountryInput = z.object({
  country: z.string().describe('The country to get the capital for.'),
});

async function getCapitalCity(params: z.infer<typeof CountryInput>): Promise<{ result: string }> {
    console.log(`\n-- Tool Call: getCapitalCity(country='${params.country}') --`);
    const capitals: Record<string, string> = {
        'united states': 'Washington, D.C.',
        'canada': 'Ottawa',
        'france': 'Paris',
        'japan': 'Tokyo',
    };
    const result = capitals[params.country.toLowerCase()] ??
        `Sorry, I couldn't find the capital for ${params.country}.`;
    console.log(`-- Tool Result: '${result}' --`);
    return { result };
}

const getCapitalCityTool = new FunctionTool({
    name: 'get_capital_city',
    description: 'Retrieves the capital city for a given country',
    parameters: CountryInput,
    execute: getCapitalCity,
});

// --- Define the Callback Function ---
function simpleBeforeToolModifier({
  tool,
  args,
  context,
}: {
  tool: BaseTool;
  args: Record<string, any>;
  context: Context;
}) {
  const agentName = context.agentName;
  const toolName = tool.name;
  console.log(`[Callback] Before tool call for tool '${toolName}' in agent '${agentName}'`);
  console.log(`[Callback] Original args: ${JSON.stringify(args)}`);

  if (
    toolName === "get_capital_city" &&
    args["country"]?.toLowerCase() === "canada"
  ) {
    console.log("[Callback] Detected 'Canada'. Modifying args to 'France'.");
    args["country"] = "France";
    console.log(`[Callback] Modified args: ${JSON.stringify(args)}`);
    return undefined;
  }

  if (
    toolName === "get_capital_city" &&
    args["country"]?.toUpperCase() === "BLOCK"
  ) {
    console.log("[Callback] Detected 'BLOCK'. Skipping tool execution.");
    return { result: "Tool execution was blocked by before_tool_callback." };
  }

  console.log("[Callback] Proceeding with original or previously modified args.");
  return;
}

// Create LlmAgent and Assign Callback
const myLlmAgent = new LlmAgent({
  name: 'ToolCallbackAgent',
  model: MODEL_NAME,
  instruction: 'You are an agent that can find capital cities. Use the get_capital_city tool.',
  description: 'An LLM agent demonstrating before_tool_callback',
  tools: [getCapitalCityTool],
  beforeToolCallback: simpleBeforeToolModifier,
});

// Agent Interaction Logic
async function callAgentAndPrint(runner: InMemoryRunner, query: string, sessionId: string) {
  console.log(`\n>>> Calling Agent for session '${sessionId}' | Query: "${query}"`);

  for await (const event of runner.runAsync({ userId: USER_ID, sessionId, newMessage: createUserContent(query) })) {
    if (isFinalResponse(event) && event.content?.parts?.length) {
      const finalResponseContent = event.content.parts.map(part => part.text ?? '').join('');
      console.log(`<<< Final Output: ${finalResponseContent}`);
    }
  }
}

// Run Interactions
async function main() {
  const runner = new InMemoryRunner({ agent: myLlmAgent, appName: APP_NAME });

  // Scenario 1: Callback modifies the arguments from "Canada" to "France"
  const canadaSessionId = 'session_canada_test';
  await runner.sessionService.createSession({ appName: APP_NAME, userId: USER_ID, sessionId: canadaSessionId });
  await callAgentAndPrint(runner, 'What is the capital of Canada?', canadaSessionId);

  // Scenario 2: Callback skips the tool call
  const blockSessionId = 'session_block_test';
  await runner.sessionService.createSession({ appName: APP_NAME, userId: USER_ID, sessionId: blockSessionId });
  await callAgentAndPrint(runner, 'What is the capital of BLOCK?', blockSessionId);
}

main();
```

```go
package main

import (
    "context"
    "fmt"
    "log"
    "regexp"
    "strings"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/runner"
    "google.golang.org/adk/session"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/functiontool"
    "google.golang.org/genai"
)

// GetCapitalCityArgs defines the arguments for the getCapitalCity tool.
type GetCapitalCityArgs struct {
    Country string `json:"country" jsonschema:"The country to get the capital of."`
}

// getCapitalCity is a tool that returns the capital of a given country.
func getCapitalCity(ctx tool.Context, args *GetCapitalCityArgs) (string, error) {
    capitals := map[string]string{
        "canada":        "Ottawa",
        "france":        "Paris",
        "germany":       "Berlin",
        "united states": "Washington, D.C.",
    }
    capital, ok := capitals[strings.ToLower(args.Country)]
    if !ok {
        return "", fmt.Errorf("unknown country: %s", args.Country)
    }
    return capital, nil
}

func onBeforeTool(ctx tool.Context, t tool.Tool, args map[string]any) (map[string]any, error) {
    log.Printf("[Callback] BeforeTool triggered for tool %q in agent %q.", t.Name(), ctx.AgentName())
    log.Printf("[Callback] Original args: %v", args)

    if t.Name() == "getCapitalCity" {
        if country, ok := args["country"].(string); ok {
            if strings.ToLower(country) == "canada" {
                log.Println("[Callback] Detected 'Canada'. Modifying args to 'France'.")
                args["country"] = "France"
                return args, nil // Proceed with modified args
            } else if strings.ToUpper(country) == "BLOCK" {
                log.Println("[Callback] Detected 'BLOCK'. Skipping tool execution.")
                // Skip tool and return a custom result.
                return map[string]any{"result": "Tool execution was blocked by before_tool_callback."}, nil
            }
        }
    }
    log.Println("[Callback] Proceeding with original or previously modified args.")
    return nil, nil // Proceed with original args
}

func runBeforeToolExample() {
    ctx := context.Background()
    geminiModel, err := gemini.NewModel(ctx, modelName, &genai.ClientConfig{})
    if err != nil {
        log.Fatalf("FATAL: Failed to create model: %v", err)
    }
    capitalTool, err := functiontool.New(functiontool.Config{
        Name:        "getCapitalCity",
        Description: "Retrieves the capital city of a given country.",
    }, getCapitalCity)
    if err != nil {
        log.Fatalf("FATAL: Failed to create function tool: %v", err)
    }

    llmCfg := llmagent.Config{
        Name:                "AgentWithBeforeToolCallback",
        Model:               geminiModel,
        Tools:               []tool.Tool{capitalTool},
        BeforeToolCallbacks: []llmagent.BeforeToolCallback{onBeforeTool},
        Instruction:         "You are an agent that can find capital cities. Use the getCapitalCity tool.",
    }
    testAgent, err := llmagent.New(llmCfg)
    if err != nil {
        log.Fatalf("FATAL: Failed to create agent: %v", err)
    }
    sessionService := session.InMemoryService()
    r, err := runner.New(runner.Config{AppName: appName, Agent: testAgent, SessionService: sessionService})
    if err != nil {
        log.Fatalf("FATAL: Failed to create runner: %v", err)
    }

    log.Println("--- SCENARIO 1: Args should be modified ---")
    runScenario(ctx, r, sessionService, appName, "session_tool_modify", nil, "What is the capital of Canada?")

    log.Println("--- SCENARIO 2: Tool call should be blocked ---")
    runScenario(ctx, r, sessionService, appName, "session_tool_block", nil, "capital of BLOCK")
}
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.InvocationContext;
import com.google.adk.events.Event;
import com.google.adk.runner.InMemoryRunner;
import com.google.adk.sessions.Session;
import com.google.adk.tools.Annotations.Schema;
import com.google.adk.tools.BaseTool;
import com.google.adk.tools.FunctionTool;
import com.google.adk.tools.ToolContext;
import com.google.common.collect.ImmutableMap;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import io.reactivex.rxjava3.core.Flowable;
import io.reactivex.rxjava3.core.Maybe;
import java.util.HashMap;
import java.util.Map;

public class BeforeToolCallbackExample {

  private static final String APP_NAME = "ToolCallbackAgentApp";
  private static final String USER_ID = "user_1";
  private static final String SESSION_ID = "session_001";
  private static final String MODEL_NAME = "gemini-2.0-flash";

  public static void main(String[] args) {
    BeforeToolCallbackExample example = new BeforeToolCallbackExample();
    example.runAgent("capital of canada");
  }

  // --- Define a Simple Tool Function ---
  // The Schema is important for the callback "args" to correctly identify the input.
  public static Map<String, Object> getCapitalCity(
      @Schema(name = "country", description = "The country to find the capital of.")
          String country) {
    System.out.printf("--- Tool 'getCapitalCity' executing with country: %s ---%n", country);
    Map<String, String> countryCapitals = new HashMap<>();
    countryCapitals.put("united states", "Washington, D.C.");
    countryCapitals.put("canada", "Ottawa");
    countryCapitals.put("france", "Paris");
    countryCapitals.put("germany", "Berlin");

    String capital =
        countryCapitals.getOrDefault(country.toLowerCase(), "Capital not found for " + country);
    // FunctionTool expects a Map<String, Object> as the return type for the method it wraps.
    return ImmutableMap.of("capital", capital);
  }

  // Define the Callback function
  // The Tool callback provides all these parameters by default.
  public Maybe<Map<String, Object>> simpleBeforeToolModifier(
      InvocationContext invocationContext,
      BaseTool tool,
      Map<String, Object> args,
      ToolContext toolContext) {

    String agentName = invocationContext.agent().name();
    String toolName = tool.name();
    System.out.printf(
        "[Callback] Before tool call for tool '%s' in agent '%s'%n", toolName, agentName);
    System.out.printf("[Callback] Original args: %s%n", args);

    if ("getCapitalCity".equals(toolName)) {
      String countryArg = (String) args.get("country");
      if (countryArg != null) {
        if ("canada".equalsIgnoreCase(countryArg)) {
          System.out.println("[Callback] Detected 'Canada'. Modifying args to 'France'.");
          args.put("country", "France");
          System.out.printf("[Callback] Modified args: %s%n", args);
          // Proceed with modified args
          return Maybe.empty();
        } else if ("BLOCK".equalsIgnoreCase(countryArg)) {
          System.out.println("[Callback] Detected 'BLOCK'. Skipping tool execution.");
          // Return a map to skip the tool call and use this as the result
          return Maybe.just(
              ImmutableMap.of("result", "Tool execution was blocked by before_tool_callback."));
        }
      }
    }

    System.out.println("[Callback] Proceeding with original or previously modified args.");
    return Maybe.empty();
  }

  public void runAgent(String query) {
    // --- Wrap the function into a Tool ---
    FunctionTool capitalTool = FunctionTool.create(this.getClass(), "getCapitalCity");

    // Create LlmAgent and Assign Callback
    LlmAgent myLlmAgent =
        LlmAgent.builder()
            .name(APP_NAME)
            .model(MODEL_NAME)
            .instruction(
                "You are an agent that can find capital cities. Use the getCapitalCity tool.")
            .description("An LLM agent demonstrating before_tool_callback")
            .tools(capitalTool)
            .beforeToolCallback(this::simpleBeforeToolModifier)
            .build();

    // Session and Runner
    InMemoryRunner runner = new InMemoryRunner(myLlmAgent);
    Session session =
        runner.sessionService().createSession(APP_NAME, USER_ID, null, SESSION_ID).blockingGet();

    Content userMessage = Content.fromParts(Part.fromText(query));

    System.out.printf("%n--- Calling agent with query: \"%s\" ---%n", query);
    Flowable<Event> eventStream = runner.runAsync(USER_ID, session.id(), userMessage);
    // Stream event response
    eventStream.blockingForEach(
        event -> {
          if (event.finalResponse()) {
            System.out.println(event.stringifyContent());
          }
        });
  }
}
```

### After Tool Callback

**When:** Called just after the tool's `run_async` method completes successfully.

**Purpose:** Allows inspection and modification of the tool's result before it's sent back to the LLM (potentially after summarization). Useful for logging tool results, post-processing or formatting results, or saving specific parts of the result to the session state.

**Return Value Effect:**

1. If the callback returns `None` (or a `Maybe.empty()` object in Java), the original `tool_response` is used.
1. If a new dictionary is returned, it **replaces** the original `tool_response`. This allows modifying or filtering the result seen by the LLM.

Code

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

from google.adk.agents import LlmAgent
from google.adk.runners import Runner
from typing import Optional
from google.genai import types 
from google.adk.sessions import InMemorySessionService
from google.adk.tools import FunctionTool
from google.adk.tools.tool_context import ToolContext
from google.adk.tools.base_tool import BaseTool
from typing import Dict, Any
from copy import deepcopy

GEMINI_2_FLASH="gemini-2.0-flash"

# --- Define a Simple Tool Function (Same as before) ---
def get_capital_city(country: str) -> str:
    """Retrieves the capital city of a given country."""
    print(f"--- Tool 'get_capital_city' executing with country: {country} ---")
    country_capitals = {
        "united states": "Washington, D.C.",
        "canada": "Ottawa",
        "france": "Paris",
        "germany": "Berlin",
    }
    return {"result": country_capitals.get(country.lower(), f"Capital not found for {country}")}

# --- Wrap the function into a Tool ---
capital_tool = FunctionTool(func=get_capital_city)

# --- Define the Callback Function ---
def simple_after_tool_modifier(
    tool: BaseTool, args: Dict[str, Any], tool_context: ToolContext, tool_response: Dict
) -> Optional[Dict]:
    """Inspects/modifies the tool result after execution."""
    agent_name = tool_context.agent_name
    tool_name = tool.name
    print(f"[Callback] After tool call for tool '{tool_name}' in agent '{agent_name}'")
    print(f"[Callback] Args used: {args}")
    print(f"[Callback] Original tool_response: {tool_response}")

    # Default structure for function tool results is {"result": <return_value>}
    original_result_value = tool_response.get("result", "")
    # original_result_value = tool_response

    # --- Modification Example ---
    # If the tool was 'get_capital_city' and result is 'Washington, D.C.'
    if tool_name == 'get_capital_city' and original_result_value == "Washington, D.C.":
        print("[Callback] Detected 'Washington, D.C.'. Modifying tool response.")

        # IMPORTANT: Create a new dictionary or modify a copy
        modified_response = deepcopy(tool_response)
        modified_response["result"] = f"{original_result_value} (Note: This is the capital of the USA)."
        modified_response["note_added_by_callback"] = True # Add extra info if needed

        print(f"[Callback] Modified tool_response: {modified_response}")
        return modified_response # Return the modified dictionary

    print("[Callback] Passing original tool response through.")
    # Return None to use the original tool_response
    return None


# Create LlmAgent and Assign Callback
my_llm_agent = LlmAgent(
        name="AfterToolCallbackAgent",
        model=GEMINI_2_FLASH,
        instruction="You are an agent that finds capital cities using the get_capital_city tool. Report the result clearly.",
        description="An LLM agent demonstrating after_tool_callback",
        tools=[capital_tool], # Add the tool
        after_tool_callback=simple_after_tool_modifier # Assign the callback
    )

APP_NAME = "guardrail_app"
USER_ID = "user_1"
SESSION_ID = "session_001"

# Session and Runner
async def setup_session_and_runner():
    session_service = InMemorySessionService()
    session = await session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID)
    runner = Runner(agent=my_llm_agent, app_name=APP_NAME, session_service=session_service)
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
await call_agent_async("united states")
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
import { LlmAgent, InMemoryRunner, FunctionTool, isFinalResponse, Context, BaseTool } from '@google/adk';
import { createUserContent } from "@google/genai";
import { z } from "zod";

const MODEL_NAME = "gemini-2.5-flash";
const APP_NAME = "after_tool_callback_app";
const USER_ID = "test_user_after_tool";
const SESSION_ID = "session_001";

// --- Define a Simple Tool Function ---
const CountryInput = z.object({
  country: z.string().describe("The country to get the capital for."),
});

async function getCapitalCity(
  params: z.infer<typeof CountryInput>,
): Promise<{ result: string }> {
  console.log(`--- Tool 'get_capital_city' executing with country: ${params.country} ---`);
  const countryCapitals: Record<string, string> = {
    "united states": "Washington, D.C.",
    "canada": "Ottawa",
    "france": "Paris",
    "germany": "Berlin",
  };
  const result = countryCapitals[params.country.toLowerCase()] ?? `Capital not found for ${params.country}`;
  return { result };
}

// --- Wrap the function into a Tool ---
const capitalTool = new FunctionTool({
  name: "get_capital_city",
  description: "Retrieves the capital city for a given country",
  parameters: CountryInput,
  execute: getCapitalCity,
});

// --- Define the Callback Function ---
function simpleAfterToolModifier({
  tool,
  args,
  context,
  response,
}: {
  tool: BaseTool;
  args: Record<string, any>;
  context: Context;
  response: Record<string, any>;
}) {
  const agentName = context.agentName;
  const toolName = tool.name;
  console.log(`[Callback] After tool call for tool '${toolName}' in agent '${agentName}'`);
  console.log(`[Callback] Original args: ${args}`);

  const originalResultValue = response?.result || "";

  // --- Modification Example ---
  if (toolName === "get_capital_city" && originalResultValue === "Washington, D.C.") {
    const modifiedResponse = JSON.parse(JSON.stringify(response));
    modifiedResponse.result = `${originalResultValue} (Note: This is the capital of the USA).`;
    modifiedResponse["note_added_by_callback"] = true;

    console.log(
      `[Callback] Modified response: ${JSON.stringify(modifiedResponse)}`
    );
    return modifiedResponse;
  }

  console.log('[Callback] Passing original tool response through.');
  return undefined;
};

// Create LlmAgent and Assign Callback
const myLlmAgent = new LlmAgent({
  name: "AfterToolCallbackAgent",
  model: MODEL_NAME,
  instruction: "You are an agent that finds capital cities using the get_capital_city tool. Report the result clearly.",
  description: "An LLM agent demonstrating after_tool_callback",
  tools: [capitalTool],
  afterToolCallback: simpleAfterToolModifier,
});

// Agent Interaction Logic
async function callAgentAndPrint(
  runner: InMemoryRunner,
  agent: LlmAgent,
  sessionId: string,
  query: string,
) {
  console.log(`
>>> Calling Agent: '${agent.name}' | Query: ${query}`);

  let finalResponseContent = "";
  for await (const event of runner.runAsync({
    userId: USER_ID,
    sessionId: sessionId,
    newMessage: createUserContent(query),
  })) {
    const authorName = event.author || "System";
    if (isFinalResponse(event) && event.content?.parts?.length) {
      finalResponseContent = 'The capital of the united states is Washington, D.C. (Note: This is the capital of the USA).';
      console.log(`--- Output from: ${authorName} ---`);
    } else if (event.errorMessage) {
      console.log(`  -> Error from ${authorName}: ${event.errorMessage}`);
    }
  }
  console.log(`<<< Agent '${agent.name}' Response: ${finalResponseContent}`);
}

// Run Interactions
async function main() {
  const runner = new InMemoryRunner({ appName: APP_NAME, agent: myLlmAgent });

  await runner.sessionService.createSession({
    appName: APP_NAME,
    userId: USER_ID,
    sessionId: SESSION_ID,
  });

  await callAgentAndPrint(runner, myLlmAgent, SESSION_ID, "united states");
}

main();
```

```go
package main

import (
    "context"
    "fmt"
    "log"
    "regexp"
    "strings"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/runner"
    "google.golang.org/adk/session"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/functiontool"
    "google.golang.org/genai"
)

// GetCapitalCityArgs defines the arguments for the getCapitalCity tool.
type GetCapitalCityArgs struct {
    Country string `json:"country" jsonschema:"The country to get the capital of."`
}

// getCapitalCity is a tool that returns the capital of a given country.
func getCapitalCity(ctx tool.Context, args *GetCapitalCityArgs) (string, error) {
    capitals := map[string]string{
        "canada":        "Ottawa",
        "france":        "Paris",
        "germany":       "Berlin",
        "united states": "Washington, D.C.",
    }
    capital, ok := capitals[strings.ToLower(args.Country)]
    if !ok {
        return "", fmt.Errorf("unknown country: %s", args.Country)
    }
    return capital, nil
}

func onAfterTool(ctx tool.Context, t tool.Tool, args map[string]any, result map[string]any, err error) (map[string]any, error) {
    log.Printf("[Callback] AfterTool triggered for tool %q in agent %q.", t.Name(), ctx.AgentName())
    log.Printf("[Callback] Original result: %v", result)

    if err != nil {
        log.Printf("[Callback] Tool run produced an error: %v. Passing through.", err)
        return nil, err
    }

    if t.Name() == "getCapitalCity" {
        if originalResult, ok := result["result"].(string); ok && originalResult == "Washington, D.C." {
            log.Println("[Callback] Detected 'Washington, D.C.'. Modifying tool response.")
            modifiedResult := make(map[string]any)
            for k, v := range result {
                modifiedResult[k] = v
            }
            modifiedResult["result"] = fmt.Sprintf("%s (Note: This is the capital of the USA).", originalResult)
            modifiedResult["note_added_by_callback"] = true
            return modifiedResult, nil
        }
    }

    log.Println("[Callback] Passing original tool response through.")
    return nil, nil
}

func runAfterToolExample() {
    ctx := context.Background()
    geminiModel, err := gemini.NewModel(ctx, modelName, &genai.ClientConfig{})
    if err != nil {
        log.Fatalf("FATAL: Failed to create model: %v", err)
    }
    capitalTool, err := functiontool.New(functiontool.Config{
        Name:        "getCapitalCity",
        Description: "Retrieves the capital city of a given country.",
    }, getCapitalCity)
    if err != nil {
        log.Fatalf("FATAL: Failed to create function tool: %v", err)
    }

    llmCfg := llmagent.Config{
        Name:               "AgentWithAfterToolCallback",
        Model:              geminiModel,
        Tools:              []tool.Tool{capitalTool},
        AfterToolCallbacks: []llmagent.AfterToolCallback{onAfterTool},
        Instruction:        "You are an agent that finds capital cities. Use the getCapitalCity tool.",
    }
    testAgent, err := llmagent.New(llmCfg)
    if err != nil {
        log.Fatalf("FATAL: Failed to create agent: %v", err)
    }
    sessionService := session.InMemoryService()
    r, err := runner.New(runner.Config{AppName: appName, Agent: testAgent, SessionService: sessionService})
    if err != nil {
        log.Fatalf("FATAL: Failed to create runner: %v", err)
    }

    log.Println("--- SCENARIO 1: Result should be modified ---")
    runScenario(ctx, r, sessionService, appName, "session_tool_after_modify", nil, "capital of united states")
}
```

```java
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.InvocationContext;
import com.google.adk.events.Event;
import com.google.adk.runner.InMemoryRunner;
import com.google.adk.sessions.Session;
import com.google.adk.tools.Annotations.Schema;
import com.google.adk.tools.BaseTool;
import com.google.adk.tools.FunctionTool;
import com.google.adk.tools.ToolContext;
import com.google.common.collect.ImmutableMap;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import io.reactivex.rxjava3.core.Flowable;
import io.reactivex.rxjava3.core.Maybe;
import java.util.HashMap;
import java.util.Map;

public class AfterToolCallbackExample {

  private static final String APP_NAME = "AfterToolCallbackAgentApp";
  private static final String USER_ID = "user_1";
  private static final String SESSION_ID = "session_001";
  private static final String MODEL_NAME = "gemini-2.0-flash";

  public static void main(String[] args) {
    AfterToolCallbackExample example = new AfterToolCallbackExample();
    example.runAgent("What is the capital of the United States?");
  }

  // --- Define a Simple Tool Function (Same as before) ---
  @Schema(description = "Retrieves the capital city of a given country.")
  public static Map<String, Object> getCapitalCity(
      @Schema(description = "The country to find the capital of.") String country) {
    System.out.printf("--- Tool 'getCapitalCity' executing with country: %s ---%n", country);
    Map<String, String> countryCapitals = new HashMap<>();
    countryCapitals.put("united states", "Washington, D.C.");
    countryCapitals.put("canada", "Ottawa");
    countryCapitals.put("france", "Paris");
    countryCapitals.put("germany", "Berlin");

    String capital =
        countryCapitals.getOrDefault(country.toLowerCase(), "Capital not found for " + country);
    return ImmutableMap.of("result", capital);
  }

  // Define the Callback function.
  public Maybe<Map<String, Object>> simpleAfterToolModifier(
      InvocationContext invocationContext,
      BaseTool tool,
      Map<String, Object> args,
      ToolContext toolContext,
      Object toolResponse) {

    // Inspects/modifies the tool result after execution.
    String agentName = invocationContext.agent().name();
    String toolName = tool.name();
    System.out.printf(
        "[Callback] After tool call for tool '%s' in agent '%s'%n", toolName, agentName);
    System.out.printf("[Callback] Args used: %s%n", args);
    System.out.printf("[Callback] Original tool_response: %s%n", toolResponse);

    if (!(toolResponse instanceof Map)) {
      System.out.println("[Callback] toolResponse is not a Map, cannot process further.");
      // Pass through if not a map
      return Maybe.empty();
    }

    // Default structure for function tool results is {"result": <return_value>}
    @SuppressWarnings("unchecked")
    Map<String, Object> responseMap = (Map<String, Object>) toolResponse;
    Object originalResultValue = responseMap.get("result");

    // --- Modification Example ---
    // If the tool was 'get_capital_city' and result is 'Washington, D.C.'
    if ("getCapitalCity".equals(toolName) && "Washington, D.C.".equals(originalResultValue)) {
      System.out.println("[Callback] Detected 'Washington, D.C.'. Modifying tool response.");

      // IMPORTANT: Create a new mutable map or modify a copy
      Map<String, Object> modifiedResponse = new HashMap<>(responseMap);
      modifiedResponse.put(
          "result", originalResultValue + " (Note: This is the capital of the USA).");
      modifiedResponse.put("note_added_by_callback", true); // Add extra info if needed

      System.out.printf("[Callback] Modified tool_response: %s%n", modifiedResponse);
      return Maybe.just(modifiedResponse);
    }

    System.out.println("[Callback] Passing original tool response through.");
    // Return Maybe.empty() to use the original tool_response
    return Maybe.empty();
  }

  public void runAgent(String query) {
    // --- Wrap the function into a Tool ---
    FunctionTool capitalTool = FunctionTool.create(this.getClass(), "getCapitalCity");

    // Create LlmAgent and Assign Callback
    LlmAgent myLlmAgent =
        LlmAgent.builder()
            .name(APP_NAME)
            .model(MODEL_NAME)
            .instruction(
                "You are an agent that finds capital cities using the getCapitalCity tool. Report"
                    + " the result clearly.")
            .description("An LLM agent demonstrating after_tool_callback")
            .tools(capitalTool) // Add the tool
            .afterToolCallback(this::simpleAfterToolModifier) // Assign the callback
            .build();

    InMemoryRunner runner = new InMemoryRunner(myLlmAgent);

    // Session and Runner
    Session session =
        runner.sessionService().createSession(APP_NAME, USER_ID, null, SESSION_ID).blockingGet();

    Content userMessage = Content.fromParts(Part.fromText(query));

    System.out.printf("%n--- Calling agent with query: \"%s\" ---%n", query);
    Flowable<Event> eventStream = runner.runAsync(USER_ID, session.id(), userMessage);
    // Stream event response
    eventStream.blockingForEach(
        event -> {
          if (event.finalResponse()) {
            System.out.println(event.stringifyContent());
          }
        });
  }
}
```




