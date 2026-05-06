# Agents

Supported in ADKPythonTypeScriptGoJava

In Agent Development Kit (ADK), an **Agent** is a self-contained execution unit designed to act autonomously to achieve specific goals. Agents can perform tasks, interact with users, utilize external tools, and coordinate with other agents.

The foundation for all agents in ADK is the `BaseAgent` class. It serves as the fundamental blueprint. To create functional agents, you typically extend `BaseAgent` in one of three main ways, catering to different needs – from intelligent reasoning to structured process control.

## Core Agent Categories

ADK provides distinct agent categories to build sophisticated applications:

1. [**LLM Agents (`LlmAgent`, `Agent`)**](https://adk.dev/agents/llm-agents/index.md): These agents utilize Large Language Models (LLMs) as their core engine to understand natural language, reason, plan, generate responses, and dynamically decide how to proceed or which tools to use, making them ideal for flexible, language-centric tasks. [Learn more about LLM Agents...](https://adk.dev/agents/llm-agents/index.md)
1. [**Workflow Agents (`SequentialAgent`, `ParallelAgent`, `LoopAgent`)**](https://adk.dev/agents/workflow-agents/index.md): These specialized agents control the execution flow of other agents in predefined, deterministic patterns (sequence, parallel, or loop) without using an LLM for the flow control itself, perfect for structured processes needing predictable execution. [Explore Workflow Agents...](https://adk.dev/agents/workflow-agents/index.md)
1. [**Custom Agents**](https://adk.dev/agents/custom-agents/index.md): Created by extending `BaseAgent` directly, these agents allow you to implement unique operational logic, specific control flows, or specialized integrations not covered by the standard types, catering to highly tailored application requirements. [Discover how to build Custom Agents...](https://adk.dev/agents/custom-agents/index.md)

## Choosing the Right Agent Type

The following table provides a high-level comparison to help distinguish between the agent types. As you explore each type in more detail in the subsequent sections, these distinctions will become clearer.

| Feature              | LLM Agent (`LlmAgent`)            | Workflow Agent                              | Custom Agent (`BaseAgent` subclass)       |
| -------------------- | --------------------------------- | ------------------------------------------- | ----------------------------------------- |
| **Primary Function** | Reasoning, Generation, Tool Use   | Controlling Agent Execution Flow            | Implementing Unique Logic/Integrations    |
| **Core Engine**      | Large Language Model (LLM)        | Predefined Logic (Sequence, Parallel, Loop) | Custom Code                               |
| **Determinism**      | Non-deterministic (Flexible)      | Deterministic (Predictable)                 | Can be either, based on implementation    |
| **Primary Use**      | Language tasks, Dynamic decisions | Structured processes, Orchestration         | Tailored requirements, Specific workflows |

## Agents Working Together: Multi-Agent Systems

While each agent type serves a distinct purpose, the true power often comes from combining them. Complex applications frequently employ [multi-agent architectures](https://adk.dev/agents/multi-agents/index.md) where:

- **LLM Agents** handle intelligent, language-based task execution.
- **Workflow Agents** manage the overall process flow using standard patterns.
- **Custom Agents** provide specialized capabilities or rules needed for unique integrations.

Understanding these core types is the first step toward building sophisticated, capable AI applications with ADK.

## Extend Agent Capabilities

Beyond the core agent types, ADK allows you to significantly expand what your agents can do through several key mechanisms:

- [**AI Models**](/agents/models/): Swap the underlying intelligence of your agents by integrating with different generative AI models from Google and other providers.
- [**Artifacts**](/artifacts/): Enable agents to create and manage persistent outputs like files, code, or documents that exist beyond the conversation lifecycle.
- [**Pre-built tools and integrations**](/integrations/): Equip your agents with a wide array tools, plugins, and other integrations to interact with the world, including web sites, MCP tools, applications, databases, programming interfaces, and more.
- [**Custom tools**](/tools-custom/): Create your own, task-specific tools for solving specific problems with precision and control.
- [**Plugins**](/plugins/): Integrate complex, pre-packaged behaviors and third-party services directly into your agent's workflow.
- [**Skills**](/skills/): Use prebuilt or custom [Agent Skills](https://agentskills.io/) to extend agent capabilities in a way that works efficiently inside AI context window limits.
- [**Callbacks**](/callbacks/): Hook into specific events during an agent's execution lifecycle to add logging, monitoring, or custom side-effects without altering core agent logic.

## Next Steps

Now that you have an overview of the different agent types available in ADK, dive deeper into how they work and how to use them effectively:

- [**LLM Agents:**](https://adk.dev/agents/llm-agents/index.md) Explore how to configure agents powered by large language models, including setting instructions, providing tools, and enabling advanced features like planning and code execution.
- [**Workflow Agents:**](https://adk.dev/agents/workflow-agents/index.md) Learn how to orchestrate tasks using `SequentialAgent`, `ParallelAgent`, and `LoopAgent` for structured and predictable processes.
- [**Custom Agents:**](https://adk.dev/agents/custom-agents/index.md) Discover the principles of extending `BaseAgent` to build agents with unique logic and integrations tailored to your specific needs.
- [**Multi-Agents:**](https://adk.dev/agents/multi-agents/index.md) Understand how to combine different agent types to create sophisticated, collaborative systems capable of tackling complex problems.
- [**Agent Routing:**](https://adk.dev/agents/routing/index.md) Dynamically select between multiple agents at runtime using router functions for fallback, A/B testing, and auto-routing.
- [**Models:**](/agents/models/) Learn about the different LLM integrations available and how to select the right model for your agents.




# Custom agents

Supported in ADKPython v0.1.0Typescript v0.2.0Go v0.1.0Java v0.1.0

Custom agents provide the ultimate flexibility in ADK, allowing you to define **arbitrary orchestration logic** by inheriting directly from `BaseAgent` and implementing your own control flow. This goes beyond the predefined patterns of `SequentialAgent`, `LoopAgent`, and `ParallelAgent`, enabling you to build highly specific and complex agentic workflows.

Advanced Concept

Building custom agents by directly implementing `_run_async_impl` (or its equivalent in other languages) provides powerful control but is more complex than using the predefined `LlmAgent` or standard `WorkflowAgent` types. We recommend understanding those foundational agent types first before tackling custom orchestration logic.

## Introduction: Beyond Predefined Workflows

### What is a Custom Agent?

A Custom Agent is essentially any class you create that inherits from `google.adk.agents.BaseAgent` and implements its core execution logic within the `_run_async_impl` asynchronous method. You have complete control over how this method calls other agents (sub-agents), manages state, and handles events.

Note

The specific method name for implementing an agent's core asynchronous logic may vary slightly by SDK language (e.g., `runAsyncImpl` in Java, `_run_async_impl` in Python, or `runAsyncImpl` in TypeScript). Refer to the language-specific API documentation for details.

### Why Use Them?

While the standard [Workflow Agents](https://adk.dev/agents/workflow-agents/index.md) (`SequentialAgent`, `LoopAgent`, `ParallelAgent`) cover common orchestration patterns, you'll need a Custom agent when your requirements include:

- **Conditional Logic:** Executing different sub-agents or taking different paths based on runtime conditions or the results of previous steps.
- **Complex State Management:** Implementing intricate logic for maintaining and updating state throughout the workflow beyond simple sequential passing.
- **External Integrations:** Incorporating calls to external APIs, databases, or custom libraries directly within the orchestration flow control.
- **Dynamic Agent Selection:** Choosing which sub-agent(s) to run next based on dynamic evaluation of the situation or input.
- **Unique Workflow Patterns:** Implementing orchestration logic that doesn't fit the standard sequential, parallel, or loop structures.

## Implementing Custom Logic:

The core of any custom agent is the method where you define its unique asynchronous behavior. This method allows you to orchestrate sub-agents and manage the flow of execution.

The heart of any custom agent is the `_run_async_impl` method. This is where you define its unique behavior.

- **Signature:** `async def _run_async_impl(self, ctx: InvocationContext) -> AsyncGenerator[Event, None]:`
- **Asynchronous Generator:** It must be an `async def` function and return an `AsyncGenerator`. This allows it to `yield` events produced by sub-agents or its own logic back to the runner.
- **`ctx` (InvocationContext):** Provides access to crucial runtime information, most importantly `ctx.session.state`, which is the primary way to share data between steps orchestrated by your custom agent.

The heart of any custom agent is the `runAsyncImpl` method. This is where you define its unique behavior.

- **Signature:** `async* runAsyncImpl(ctx: InvocationContext): AsyncGenerator<Event, void, undefined>`
- **Asynchronous Generator:** It must be an `async` generator function (`async*`).
- **`ctx` (InvocationContext):** Provides access to crucial runtime information, most importantly `ctx.session.state`, which is the primary way to share data between steps orchestrated by your custom agent.

In Go, you implement the `Run` method as part of a struct that satisfies the `agent.Agent` interface. The actual logic is typically a method on your custom agent struct.

- **Signature:** `Run(ctx agent.InvocationContext) iter.Seq2[*session.Event, error]`
- **Iterator:** The `Run` method returns an iterator (`iter.Seq2`) that yields events and errors. This is the standard way to handle streaming results from an agent's execution.
- **`ctx` (InvocationContext):** The `agent.InvocationContext` provides access to the session, including state, and other crucial runtime information.
- **Session State:** You can access the session state through `ctx.Session().State()`.

The heart of any custom agent is the `runAsyncImpl` method, which you override from `BaseAgent`.

- **Signature:** `protected Flowable<Event> runAsyncImpl(InvocationContext ctx)`
- **Reactive Stream (`Flowable`):** It must return an `io.reactivex.rxjava3.core.Flowable<Event>`. This `Flowable` represents a stream of events that will be produced by the custom agent's logic, often by combining or transforming multiple `Flowable` from sub-agents.
- **`ctx` (InvocationContext):** Provides access to crucial runtime information, most importantly `ctx.session().state()`, which is a `java.util.concurrent.ConcurrentMap<String, Object>`. This is the primary way to share data between steps orchestrated by your custom agent.

**Key Capabilities within the Core Asynchronous Method:**

1. **Calling Sub-Agents:** You invoke sub-agents (which are typically stored as instance attributes like `self.my_llm_agent`) using their `run_async` method and yield their events:

   ```python
   async for event in self.some_sub_agent.run_async(ctx):
       # Optionally inspect or log the event
       yield event # Pass the event up
   ```

1. **Managing State:** Read from and write to the session state dictionary (`ctx.session.state`) to pass data between sub-agent calls or make decisions:

   ```python
   # Read data set by a previous agent
   previous_result = ctx.session.state.get("some_key")

   # Make a decision based on state
   if previous_result == "some_value":
       # ... call a specific sub-agent ...
   else:
       # ... call another sub-agent ...

   # Store a result for a later step (often done via a sub-agent's output_key)
   # ctx.session.state["my_custom_result"] = "calculated_value"
   ```

1. **Implementing Control Flow:** Use standard Python constructs (`if`/`elif`/`else`, `for`/`while` loops, `try`/`except`) to create sophisticated, conditional, or iterative workflows involving your sub-agents.

1. **Calling Sub-Agents:** You invoke sub-agents (which are typically stored as instance properties like `this.myLlmAgent`) using their `run` method and yield their events:

   ```typescript
   for await (const event of this.someSubAgent.runAsync(ctx)) {
       // Optionally inspect or log the event
       yield event; // Pass the event up to the runner
   }
   ```

1. **Managing State:** Read from and write to the session state object (`ctx.session.state`) to pass data between sub-agent calls or make decisions:

   ```typescript
   // Read data set by a previous agent
   const previousResult = ctx.session.state['some_key'];

   // Make a decision based on state
   if (previousResult === 'some_value') {
     // ... call a specific sub-agent ...
   } else {
     // ... call another sub-agent ...
   }

   // Store a result for a later step (often done via a sub-agent's outputKey)
   // ctx.session.state['my_custom_result'] = 'calculated_value';
   ```

1. **Implementing Control Flow:** Use standard TypeScript/JavaScript constructs (`if`/`else`, `for`/`while` loops, `try`/`catch`) to create sophisticated, conditional, or iterative workflows involving your sub-agents.

1. **Calling Sub-Agents:** You invoke sub-agents by calling their `Run` method.

   ```go
   // Example: Running one sub-agent and yielding its events
   for event, err := range someSubAgent.Run(ctx) {
       if err != nil {
           // Handle or propagate the error
           return
       }
       // Yield the event up to the caller
       if !yield(event, nil) {
         return
       }
   }
   ```

1. **Managing State:** Read from and write to the session state to pass data between sub-agent calls or make decisions.

   ```go
   // The `ctx` (`agent.InvocationContext`) is passed directly to your agent's `Run` function.
   // Read data set by a previous agent
   previousResult, err := ctx.Session().State().Get("some_key")
   if err != nil {
       // Handle cases where the key might not exist yet
   }

   // Make a decision based on state
   if val, ok := previousResult.(string); ok && val == "some_value" {
       // ... call a specific sub-agent ...
   } else {
       // ... call another sub-agent ...
   }

   // Store a result for a later step
   if err := ctx.Session().State().Set("my_custom_result", "calculated_value"); err != nil {
       // Handle error
   }
   ```

1. **Implementing Control Flow:** Use standard Go constructs (`if`/`else`, `for`/`switch` loops, goroutines, channels) to create sophisticated, conditional, or iterative workflows involving your sub-agents.

1. **Calling Sub-Agents:** You invoke sub-agents (which are typically stored as instance attributes or objects) using their asynchronous run method and return their event streams:

   You typically chain `Flowable`s from sub-agents using RxJava operators like `concatWith`, `flatMapPublisher`, or `concatArray`.

   ```java
   // Example: Running one sub-agent
   // return someSubAgent.runAsync(ctx);

   // Example: Running sub-agents sequentially
   Flowable<Event> firstAgentEvents = someSubAgent1.runAsync(ctx)
       .doOnNext(event -> System.out.println("Event from agent 1: " + event.id()));

   Flowable<Event> secondAgentEvents = Flowable.defer(() ->
       someSubAgent2.runAsync(ctx)
           .doOnNext(event -> System.out.println("Event from agent 2: " + event.id()))
   );

   return firstAgentEvents.concatWith(secondAgentEvents);
   ```

   The `Flowable.defer()` is often used for subsequent stages if their execution depends on the completion or state after prior stages.

1. **Managing State:** Read from and write to the session state to pass data between sub-agent calls or make decisions. The session state is a `java.util.concurrent.ConcurrentMap<String, Object>` obtained via `ctx.session().state()`.

   ```java
   // Read data set by a previous agent
   Object previousResult = ctx.session().state().get("some_key");

   // Make a decision based on state
   if ("some_value".equals(previousResult)) {
       // ... logic to include a specific sub-agent's Flowable ...
   } else {
       // ... logic to include another sub-agent's Flowable ...
   }

   // Store a result for a later step (often done via a sub-agent's output_key)
   // ctx.session().state().put("my_custom_result", "calculated_value");
   ```

1. **Implementing Control Flow:** Use standard language constructs (`if`/`else`, loops, `try`/`catch`) combined with reactive operators (RxJava) to create sophisticated workflows.

   - **Conditional:** `Flowable.defer()` to choose which `Flowable` to subscribe to based on a condition, or `filter()` if you're filtering events within a stream.
   - **Iterative:** Operators like `repeat()`, `retry()`, or by structuring your `Flowable` chain to recursively call parts of itself based on conditions (often managed with `flatMapPublisher` or `concatMap`).

## Managing Sub-Agents and State

Typically, a custom agent orchestrates other agents (like `LlmAgent`, `LoopAgent`, etc.).

- **Initialization:** You usually pass instances of these sub-agents into your custom agent's constructor and store them as instance fields/attributes (e.g., `this.story_generator = story_generator_instance` or `self.story_generator = story_generator_instance`). This makes them accessible within the custom agent's core asynchronous execution logic (such as: `_run_async_impl` method).
- **Sub Agents List:** When initializing the `BaseAgent` using it's `super()` constructor, you should pass a `sub agents` list. This list tells the ADK framework about the agents that are part of this custom agent's immediate hierarchy. It's important for framework features like lifecycle management, introspection, and potentially future routing capabilities, even if your core execution logic (`_run_async_impl`) calls the agents directly via `self.xxx_agent`. Include the agents that your custom logic directly invokes at the top level.
- **State:** As mentioned, `ctx.session.state` is the standard way sub-agents (especially `LlmAgent`s using `output key`) communicate results back to the orchestrator and how the orchestrator passes necessary inputs down.

## Design Pattern Example: `StoryFlowAgent`

Let's illustrate the power of custom agents with an example pattern: a multi-stage content generation workflow with conditional logic.

**Goal:** Create a system that generates a story, iteratively refines it through critique and revision, performs final checks, and crucially, *regenerates the story if the final tone check fails*.

**Why Custom?** The core requirement driving the need for a custom agent here is the **conditional regeneration based on the tone check**. Standard workflow agents don't have built-in conditional branching based on the outcome of a sub-agent's task. We need custom logic (`if tone == "negative": ...`) within the orchestrator.

______________________________________________________________________

### Part 1: Simplified custom agent Initialization

We define the `StoryFlowAgent` inheriting from `BaseAgent`. In `__init__`, we store the necessary sub-agents (passed in) as instance attributes and tell the `BaseAgent` framework about the top-level agents this custom agent will directly orchestrate.

```python
class StoryFlowAgent(BaseAgent):
    """
    Custom agent for a story generation and refinement workflow.

    This agent orchestrates a sequence of LLM agents to generate a story,
    critique it, revise it, check grammar and tone, and potentially
    regenerate the story if the tone is negative.
    """

    # --- Field Declarations for Pydantic ---
    # Declare the agents passed during initialization as class attributes with type hints
    story_generator: LlmAgent
    critic: LlmAgent
    reviser: LlmAgent
    grammar_check: LlmAgent
    tone_check: LlmAgent

    loop_agent: LoopAgent
    sequential_agent: SequentialAgent

    # model_config allows setting Pydantic configurations if needed, e.g., arbitrary_types_allowed
    model_config = {"arbitrary_types_allowed": True}

    def __init__(
        self,
        name: str,
        story_generator: LlmAgent,
        critic: LlmAgent,
        reviser: LlmAgent,
        grammar_check: LlmAgent,
        tone_check: LlmAgent,
    ):
        """
        Initializes the StoryFlowAgent.

        Args:
            name: The name of the agent.
            story_generator: An LlmAgent to generate the initial story.
            critic: An LlmAgent to critique the story.
            reviser: An LlmAgent to revise the story based on criticism.
            grammar_check: An LlmAgent to check the grammar.
            tone_check: An LlmAgent to analyze the tone.
        """
        # Create internal agents *before* calling super().__init__
        loop_agent = LoopAgent(
            name="CriticReviserLoop", sub_agents=[critic, reviser], max_iterations=2
        )
        sequential_agent = SequentialAgent(
            name="PostProcessing", sub_agents=[grammar_check, tone_check]
        )

        # Define the sub_agents list for the framework
        sub_agents_list = [
            story_generator,
            loop_agent,
            sequential_agent,
        ]

        # Pydantic will validate and assign them based on the class annotations.
        super().__init__(
            name=name,
            story_generator=story_generator,
            critic=critic,
            reviser=reviser,
            grammar_check=grammar_check,
            tone_check=tone_check,
            loop_agent=loop_agent,
            sequential_agent=sequential_agent,
            sub_agents=sub_agents_list, # Pass the sub_agents list directly
        )
```

We define the `StoryFlowAgent` by extending `BaseAgent`. In its constructor, we:

1. Create any internal composite agents (like `LoopAgent` or `SequentialAgent`).
1. Pass the list of all top-level sub-agents to the `super()` constructor.
1. Store the sub-agents (passed in or created internally) as instance properties (e.g., `this.storyGenerator`) so they can be accessed in the custom `runImpl` logic.

```typescript
class StoryFlowAgent extends BaseAgent {
  // --- Property Declarations for TypeScript ---
  private storyGenerator: LlmAgent;
  private critic: LlmAgent;
  private reviser: LlmAgent;
  private grammarCheck: LlmAgent;
  private toneCheck: LlmAgent;

  private loopAgent: LoopAgent;
  private sequentialAgent: SequentialAgent;

  constructor(
    name: string,
    storyGenerator: LlmAgent,
    critic: LlmAgent,
    reviser: LlmAgent,
    grammarCheck: LlmAgent,
    toneCheck: LlmAgent
  ) {
    // Create internal composite agents
    const loopAgent = new LoopAgent({
      name: "CriticReviserLoop",
      subAgents: [critic, reviser],
      maxIterations: 2,
    });

    const sequentialAgent = new SequentialAgent({
      name: "PostProcessing",
      subAgents: [grammarCheck, toneCheck],
    });

    // Define the sub-agents for the framework to know about
    const subAgentsList = [
      storyGenerator,
      loopAgent,
      sequentialAgent,
    ];

    // Call the parent constructor
    super({
      name,
      subAgents: subAgentsList,
    });

    // Assign agents to class properties for use in the custom run logic
    this.storyGenerator = storyGenerator;
    this.critic = critic;
    this.reviser = reviser;
    this.grammarCheck = grammarCheck;
    this.toneCheck = toneCheck;
    this.loopAgent = loopAgent;
    this.sequentialAgent = sequentialAgent;
  }
```

We define the `StoryFlowAgent` struct and a constructor. In the constructor, we store the necessary sub-agents and tell the `BaseAgent` framework about the top-level agents this custom agent will directly orchestrate.

```go
// StoryFlowAgent is a custom agent that orchestrates a story generation workflow.
// It encapsulates the logic of running sub-agents in a specific sequence.
type StoryFlowAgent struct {
    storyGenerator     agent.Agent
    revisionLoopAgent  agent.Agent
    postProcessorAgent agent.Agent
}

// NewStoryFlowAgent creates and configures the entire custom agent workflow.
// It takes individual LLM agents as input and internally creates the necessary
// workflow agents (loop, sequential), returning the final orchestrator agent.
func NewStoryFlowAgent(
    storyGenerator,
    critic,
    reviser,
    grammarCheck,
    toneCheck agent.Agent,
) (agent.Agent, error) {
    loopAgent, err := loopagent.New(loopagent.Config{
        MaxIterations: 2,
        AgentConfig: agent.Config{
            Name:      "CriticReviserLoop",
            SubAgents: []agent.Agent{critic, reviser},
        },
    })
    if err != nil {
        return nil, fmt.Errorf("failed to create loop agent: %w", err)
    }

    sequentialAgent, err := sequentialagent.New(sequentialagent.Config{
        AgentConfig: agent.Config{
            Name:      "PostProcessing",
            SubAgents: []agent.Agent{grammarCheck, toneCheck},
        },
    })
    if err != nil {
        return nil, fmt.Errorf("failed to create sequential agent: %w", err)
    }

    // The StoryFlowAgent struct holds the agents needed for the Run method.
    orchestrator := &StoryFlowAgent{
        storyGenerator:     storyGenerator,
        revisionLoopAgent:  loopAgent,
        postProcessorAgent: sequentialAgent,
    }

    // agent.New creates the final agent, wiring up the Run method.
    return agent.New(agent.Config{
        Name:        "StoryFlowAgent",
        Description: "Orchestrates story generation, critique, revision, and checks.",
        SubAgents:   []agent.Agent{storyGenerator, loopAgent, sequentialAgent},
        Run:         orchestrator.Run,
    })
}
```

We define the `StoryFlowAgentExample` by extending `BaseAgent`. In its **constructor**, we store the necessary sub-agent instances (passed as parameters) as instance fields. These top-level sub-agents, which this custom agent will directly orchestrate, are also passed to the `super` constructor of `BaseAgent` as a list.

```java
private final LlmAgent storyGenerator;
private final LoopAgent loopAgent;
private final SequentialAgent sequentialAgent;

public StoryFlowAgentExample(
    String name, LlmAgent storyGenerator, LoopAgent loopAgent, SequentialAgent sequentialAgent) {
  super(
      name,
      "Orchestrates story generation, critique, revision, and checks.",
      List.of(storyGenerator, loopAgent, sequentialAgent),
      null,
      null);

  this.storyGenerator = storyGenerator;
  this.loopAgent = loopAgent;
  this.sequentialAgent = sequentialAgent;
}
```

______________________________________________________________________

### Part 2: Defining the Custom Execution Logic

This method orchestrates the sub-agents using standard Python async/await and control flow.

```python
@override
async def _run_async_impl(
    self, ctx: InvocationContext
) -> AsyncGenerator[Event, None]:
    """
    Implements the custom orchestration logic for the story workflow.
    Uses the instance attributes assigned by Pydantic (e.g., self.story_generator).
    """
    logger.info(f"[{self.name}] Starting story generation workflow.")

    # 1. Initial Story Generation
    logger.info(f"[{self.name}] Running StoryGenerator...")
    async for event in self.story_generator.run_async(ctx):
        logger.info(f"[{self.name}] Event from StoryGenerator: {event.model_dump_json(indent=2, exclude_none=True)}")
        yield event

    # Check if story was generated before proceeding
    if "current_story" not in ctx.session.state or not ctx.session.state["current_story"]:
         logger.error(f"[{self.name}] Failed to generate initial story. Aborting workflow.")
         return # Stop processing if initial story failed

    logger.info(f"[{self.name}] Story state after generator: {ctx.session.state.get('current_story')}")


    # 2. Critic-Reviser Loop
    logger.info(f"[{self.name}] Running CriticReviserLoop...")
    # Use the loop_agent instance attribute assigned during init
    async for event in self.loop_agent.run_async(ctx):
        logger.info(f"[{self.name}] Event from CriticReviserLoop: {event.model_dump_json(indent=2, exclude_none=True)}")
        yield event

    logger.info(f"[{self.name}] Story state after loop: {ctx.session.state.get('current_story')}")

    # 3. Sequential Post-Processing (Grammar and Tone Check)
    logger.info(f"[{self.name}] Running PostProcessing...")
    # Use the sequential_agent instance attribute assigned during init
    async for event in self.sequential_agent.run_async(ctx):
        logger.info(f"[{self.name}] Event from PostProcessing: {event.model_dump_json(indent=2, exclude_none=True)}")
        yield event

    # 4. Tone-Based Conditional Logic
    tone_check_result = ctx.session.state.get("tone_check_result")
    logger.info(f"[{self.name}] Tone check result: {tone_check_result}")

    if tone_check_result == "negative":
        logger.info(f"[{self.name}] Tone is negative. Regenerating story...")
        async for event in self.story_generator.run_async(ctx):
            logger.info(f"[{self.name}] Event from StoryGenerator (Regen): {event.model_dump_json(indent=2, exclude_none=True)}")
            yield event
    else:
        logger.info(f"[{self.name}] Tone is not negative. Keeping current story.")
        pass

    logger.info(f"[{self.name}] Workflow finished.")
```

**Explanation of Logic:**

1. The initial `story_generator` runs. Its output is expected to be in `ctx.session.state["current_story"]`.
1. The `loop_agent` runs, which internally calls the `critic` and `reviser` sequentially for `max_iterations` times. They read/write `current_story` and `criticism` from/to the state.
1. The `sequential_agent` runs, calling `grammar_check` then `tone_check`, reading `current_story` and writing `grammar_suggestions` and `tone_check_result` to the state.
1. **Custom Part:** The `if` statement checks the `tone_check_result` from the state. If it's "negative", the `story_generator` is called *again*, overwriting the `current_story` in the state. Otherwise, the flow ends.

The `runImpl` method orchestrates the sub-agents using standard TypeScript `async`/`await` and control flow. The `runLiveImpl` is also added to handle live streaming scenarios.

```typescript
// Implements the custom orchestration logic for the story workflow.
async* runLiveImpl(ctx: InvocationContext): AsyncGenerator<Event, void, undefined> {
  yield* this.runAsyncImpl(ctx);
}

// Implements the custom orchestration logic for the story workflow.
async* runAsyncImpl(ctx: InvocationContext): AsyncGenerator<Event, void, undefined> {
  console.log(`[${this.name}] Starting story generation workflow.`);

  // 1. Initial Story Generation
  console.log(`[${this.name}] Running StoryGenerator...`);
  for await (const event of this.storyGenerator.runAsync(ctx)) {
    console.log(`[${this.name}] Event from StoryGenerator: ${JSON.stringify(event, null, 2)}`);
    yield event;
  }

  // Check if the story was generated before proceeding
  if (!ctx.session.state["current_story"]) {
    console.error(`[${this.name}] Failed to generate initial story. Aborting workflow.`);
    return; // Stop processing
  }
  console.log(`[${this.name}] Story state after generator: ${ctx.session.state['current_story']}`);

  // 2. Critic-Reviser Loop
  console.log(`[${this.name}] Running CriticReviserLoop...`);
  for await (const event of this.loopAgent.runAsync(ctx)) {
    console.log(`[${this.name}] Event from CriticReviserLoop: ${JSON.stringify(event, null, 2)}`);
    yield event;
  }
  console.log(`[${this.name}] Story state after loop: ${ctx.session.state['current_story']}`);

  // 3. Sequential Post-Processing (Grammar and Tone Check)
  console.log(`[${this.name}] Running PostProcessing...`);
  for await (const event of this.sequentialAgent.runAsync(ctx)) {
    console.log(`[${this.name}] Event from PostProcessing: ${JSON.stringify(event, null, 2)}`);
    yield event;
  }

  // 4. Tone-Based Conditional Logic
  const toneCheckResult = ctx.session.state["tone_check_result"] as string;
  console.log(`[${this.name}] Tone check result: ${toneCheckResult}`);

  if (toneCheckResult === "negative") {
    console.log(`[${this.name}] Tone is negative. Regenerating story...`);
    for await (const event of this.storyGenerator.runAsync(ctx)) {
      console.log(`[${this.name}] Event from StoryGenerator (Regen): ${JSON.stringify(event, null, 2)}`);
      yield event;
    }
  } else {
    console.log(`[${this.name}] Tone is not negative. Keeping current story.`);
  }

  console.log(`[${this.name}] Workflow finished.`);
}
```

**Explanation of Logic:**

1. The initial `storyGenerator` runs. Its output is expected to be in `ctx.session.state['current_story']`.
1. The `loopAgent` runs, which internally calls the `critic` and `reviser` sequentially for `maxIterations` times. They read/write `current_story` and `criticism` from/to the state.
1. The `sequentialAgent` runs, calling `grammarCheck` then `toneCheck`, reading `current_story` and writing `grammar_suggestions` and `tone_check_result` to the state.
1. **Custom Part:** The `if` statement checks the `tone_check_result` from the state. If it's "negative", the `storyGenerator` is called *again*, overwriting the `current_story` in the state. Otherwise, the flow ends.

The `Run` method orchestrates the sub-agents by calling their respective `Run` methods in a loop and yielding their events.

```go
// Run defines the custom execution logic for the StoryFlowAgent.
func (s *StoryFlowAgent) Run(ctx agent.InvocationContext) iter.Seq2[*session.Event, error] {
    return func(yield func(*session.Event, error) bool) {
        // Stage 1: Initial Story Generation
        for event, err := range s.storyGenerator.Run(ctx) {
            if err != nil {
                yield(nil, fmt.Errorf("story generator failed: %w", err))
                return
            }
            if !yield(event, nil) {
                return
            }
        }

        // Check if story was generated before proceeding
        currentStory, err := ctx.Session().State().Get("current_story")
        if err != nil || currentStory == "" {
            log.Println("Failed to generate initial story. Aborting workflow.")
            return
        }

        // Stage 2: Critic-Reviser Loop
        for event, err := range s.revisionLoopAgent.Run(ctx) {
            if err != nil {
                yield(nil, fmt.Errorf("loop agent failed: %w", err))
                return
            }
            if !yield(event, nil) {
                return
            }
        }

        // Stage 3: Post-Processing
        for event, err := range s.postProcessorAgent.Run(ctx) {
            if err != nil {
                yield(nil, fmt.Errorf("sequential agent failed: %w", err))
                return
            }
            if !yield(event, nil) {
                return
            }
        }

        // Stage 4: Conditional Regeneration
        toneResult, err := ctx.Session().State().Get("tone_check_result")
        if err != nil {
            log.Printf("Could not read tone_check_result from state: %v. Assuming tone is not negative.", err)
            return
        }

        if tone, ok := toneResult.(string); ok && tone == "negative" {
            log.Println("Tone is negative. Regenerating story...")
            for event, err := range s.storyGenerator.Run(ctx) {
                if err != nil {
                    yield(nil, fmt.Errorf("story regeneration failed: %w", err))
                    return
                }
                if !yield(event, nil) {
                    return
                }
            }
        } else {
            log.Println("Tone is not negative. Keeping current story.")
        }
    }
}
```

**Explanation of Logic:**

1. The initial `storyGenerator` runs. Its output is expected to be in the session state under the key `"current_story"`.
1. The `revisionLoopAgent` runs, which internally calls the `critic` and `reviser` sequentially for `max_iterations` times. They read/write `current_story` and `criticism` from/to the state.
1. The `postProcessorAgent` runs, calling `grammar_check` then `tone_check`, reading `current_story` and writing `grammar_suggestions` and `tone_check_result` to the state.
1. **Custom Part:** The code checks the `tone_check_result` from the state. If it's "negative", the `story_generator` is called *again*, overwriting the `current_story` in the state. Otherwise, the flow ends.

The `runAsyncImpl` method orchestrates the sub-agents using RxJava's Flowable streams and operators for asynchronous control flow.

```java
@Override
protected Flowable<Event> runAsyncImpl(InvocationContext invocationContext) {
  // Implements the custom orchestration logic for the story workflow.
  // Uses the instance attributes assigned by Pydantic (e.g., self.story_generator).
  logger.log(Level.INFO, () -> String.format("[%s] Starting story generation workflow.", name()));

  // Stage 1. Initial Story Generation
  Flowable<Event> storyGenFlow = runStage(storyGenerator, invocationContext, "StoryGenerator");

  // Stage 2: Critic-Reviser Loop (runs after story generation completes)
  Flowable<Event> criticReviserFlow = Flowable.defer(() -> {
    if (!isStoryGenerated(invocationContext)) {
      logger.log(Level.SEVERE,() ->
          String.format("[%s] Failed to generate initial story. Aborting after StoryGenerator.",
              name()));
      return Flowable.empty(); // Stop further processing if no story
    }
      logger.log(Level.INFO, () ->
          String.format("[%s] Story state after generator: %s",
              name(), invocationContext.session().state().get("current_story")));
      return runStage(loopAgent, invocationContext, "CriticReviserLoop");
  });

  // Stage 3: Post-Processing (runs after critic-reviser loop completes)
  Flowable<Event> postProcessingFlow = Flowable.defer(() -> {
    logger.log(Level.INFO, () ->
        String.format("[%s] Story state after loop: %s",
            name(), invocationContext.session().state().get("current_story")));
    return runStage(sequentialAgent, invocationContext, "PostProcessing");
  });

  // Stage 4: Conditional Regeneration (runs after post-processing completes)
  Flowable<Event> conditionalRegenFlow = Flowable.defer(() -> {
    String toneCheckResult = (String) invocationContext.session().state().get("tone_check_result");
    logger.log(Level.INFO, () -> String.format("[%s] Tone check result: %s", name(), toneCheckResult));

    if ("negative".equalsIgnoreCase(toneCheckResult)) {
      logger.log(Level.INFO, () ->
          String.format("[%s] Tone is negative. Regenerating story...", name()));
      return runStage(storyGenerator, invocationContext, "StoryGenerator (Regen)");
    } else {
      logger.log(Level.INFO, () ->
          String.format("[%s] Tone is not negative. Keeping current story.", name()));
      return Flowable.empty(); // No regeneration needed
    }
  });

  return Flowable.concatArray(storyGenFlow, criticReviserFlow, postProcessingFlow, conditionalRegenFlow)
      .doOnComplete(() -> logger.log(Level.INFO, () -> String.format("[%s] Workflow finished.", name())));
}

// Helper method for a single agent run stage with logging
private Flowable<Event> runStage(BaseAgent agentToRun, InvocationContext ctx, String stageName) {
  logger.log(Level.INFO, () -> String.format("[%s] Running %s...", name(), stageName));
  return agentToRun
      .runAsync(ctx)
      .doOnNext(event ->
          logger.log(Level.INFO,() ->
              String.format("[%s] Event from %s: %s", name(), stageName, event.toJson())))
      .doOnError(err ->
          logger.log(Level.SEVERE,
              String.format("[%s] Error in %s", name(), stageName), err))
      .doOnComplete(() ->
          logger.log(Level.INFO, () ->
              String.format("[%s] %s finished.", name(), stageName)));
}
```

**Explanation of Logic:**

1. The initial `storyGenerator.runAsync(invocationContext)` Flowable is executed. Its output is expected to be in `invocationContext.session().state().get("current_story")`.
1. The `loopAgent's` Flowable runs next (due to `Flowable.concatArray` and `Flowable.defer`). The LoopAgent internally calls the `critic` and `reviser` sub-agents sequentially for up to `maxIterations`. They read/write `current_story` and `criticism` from/to the state.
1. Then, the `sequentialAgent's` Flowable executes. It calls the `grammar_check` then `tone_check`, reading `current_story` and writing `grammar_suggestions` and `tone_check_result` to the state.
1. **Custom Part:** After the sequentialAgent completes, logic within a `Flowable.defer` checks the "tone_check_result" from `invocationContext.session().state()`. If it's "negative", the `storyGenerator` Flowable is *conditionally concatenated* and executed again, overwriting "current_story". Otherwise, an empty Flowable is used, and the overall workflow proceeds to completion.

______________________________________________________________________

### Part 3: Defining the LLM Sub-Agents

These are standard `LlmAgent` definitions, responsible for specific tasks. Their `output key` parameter is crucial for placing results into the `session.state` where other agents or the custom orchestrator can access them.

Direct State Injection in Instructions

Notice the `story_generator`'s instruction. The `{var}` syntax is a placeholder. Before the instruction is sent to the LLM, the ADK framework automatically replaces (Example:`{topic}`) with the value of `session.state['topic']`. This is the recommended way to provide context to an agent, using templating in the instructions. For more details, see the [State documentation](https://adk.dev/sessions/state/#accessing-session-state-in-agent-instructions).

```python
GEMINI_2_FLASH = "gemini-flash-latest" # Define model constant
# --- Define the individual LLM agents ---
story_generator = LlmAgent(
    name="StoryGenerator",
    model=GEMINI_2_FLASH,
    instruction="""You are a story writer. Write a short story (around 100 words), on the following topic: {topic}""",
    input_schema=None,
    output_key="current_story",  # Key for storing output in session state
)

critic = LlmAgent(
    name="Critic",
    model=GEMINI_2_FLASH,
    instruction="""You are a story critic. Review the story provided: {{current_story}}. Provide 1-2 sentences of constructive criticism
on how to improve it. Focus on plot or character.""",
    input_schema=None,
    output_key="criticism",  # Key for storing criticism in session state
)

reviser = LlmAgent(
    name="Reviser",
    model=GEMINI_2_FLASH,
    instruction="""You are a story reviser. Revise the story provided: {{current_story}}, based on the criticism in
{{criticism}}. Output only the revised story.""",
    input_schema=None,
    output_key="current_story",  # Overwrites the original story
)

grammar_check = LlmAgent(
    name="GrammarCheck",
    model=GEMINI_2_FLASH,
    instruction="""You are a grammar checker. Check the grammar of the story provided: {current_story}. Output only the suggested
corrections as a list, or output 'Grammar is good!' if there are no errors.""",
    input_schema=None,
    output_key="grammar_suggestions",
)

tone_check = LlmAgent(
    name="ToneCheck",
    model=GEMINI_2_FLASH,
    instruction="""You are a tone analyzer. Analyze the tone of the story provided: {current_story}. Output only one word: 'positive' if
the tone is generally positive, 'negative' if the tone is generally negative, or 'neutral'
otherwise.""",
    input_schema=None,
    output_key="tone_check_result", # This agent's output determines the conditional flow
)
```

```typescript
// --- Define the individual LLM agents ---
const storyGenerator = new LlmAgent({
    name: "StoryGenerator",
    model: GEMINI_MODEL,
    instruction: `You are a story writer. Write a short story (around 100 words), on the following topic: {topic}`,
    outputKey: "current_story",
});

const critic = new LlmAgent({
    name: "Critic",
    model: GEMINI_MODEL,
    instruction: `You are a story critic. Review the story provided: {{current_story}}. Provide 1-2 sentences of constructive criticism
on how to improve it. Focus on plot or character.`,
    outputKey: "criticism",
});

const reviser = new LlmAgent({
    name: "Reviser",
    model: GEMINI_MODEL,
    instruction: `You are a story reviser. Revise the story provided: {{current_story}}, based on the criticism in
{{criticism}}. Output only the revised story.`,
    outputKey: "current_story", // Overwrites the original story
});

const grammarCheck = new LlmAgent({
    name: "GrammarCheck",
    model: GEMINI_MODEL,
    instruction: `You are a grammar checker. Check the grammar of the story provided: {current_story}. Output only the suggested
corrections as a list, or output 'Grammar is good!' if there are no errors.`,
    outputKey: "grammar_suggestions",
});

const toneCheck = new LlmAgent({
    name: "ToneCheck",
    model: GEMINI_MODEL,
    instruction: `You are a tone analyzer. Analyze the tone of the story provided: {current_story}. Output only one word: 'positive' if
the tone is generally positive, 'negative' if the tone is generally negative, or 'neutral'
otherwise.`,
    outputKey: "tone_check_result",
});
```

```go
// --- Define the individual LLM agents ---
storyGenerator, err := llmagent.New(llmagent.Config{
    Name:        "StoryGenerator",
    Model:       model,
    Description: "Generates the initial story.",
    Instruction: "You are a story writer. Write a short story (around 100 words) about a cat, based on the topic: {topic}",
    OutputKey:   "current_story",
})
if err != nil {
    log.Fatalf("Failed to create StoryGenerator agent: %v", err)
}

critic, err := llmagent.New(llmagent.Config{
    Name:        "Critic",
    Model:       model,
    Description: "Critiques the story.",
    Instruction: "You are a story critic. Review the story: {current_story}. Provide 1-2 sentences of constructive criticism on how to improve it. Focus on plot or character.",
    OutputKey:   "criticism",
})
if err != nil {
    log.Fatalf("Failed to create Critic agent: %v", err)
}

reviser, err := llmagent.New(llmagent.Config{
    Name:        "Reviser",
    Model:       model,
    Description: "Revises the story based on criticism.",
    Instruction: "You are a story reviser. Revise the story: {current_story}, based on the criticism: {criticism}. Output only the revised story.",
    OutputKey:   "current_story",
})
if err != nil {
    log.Fatalf("Failed to create Reviser agent: %v", err)
}

grammarCheck, err := llmagent.New(llmagent.Config{
    Name:        "GrammarCheck",
    Model:       model,
    Description: "Checks grammar and suggests corrections.",
    Instruction: "You are a grammar checker. Check the grammar of the story: {current_story}. Output only the suggested corrections as a list, or output 'Grammar is good!' if there are no errors.",
    OutputKey:   "grammar_suggestions",
})
if err != nil {
    log.Fatalf("Failed to create GrammarCheck agent: %v", err)
}

toneCheck, err := llmagent.New(llmagent.Config{
    Name:        "ToneCheck",
    Model:       model,
    Description: "Analyzes the tone of the story.",
    Instruction: "You are a tone analyzer. Analyze the tone of the story: {current_story}. Output only one word: 'positive' if the tone is generally positive, 'negative' if the tone is generally negative, or 'neutral' otherwise.",
    OutputKey:   "tone_check_result",
})
if err != nil {
    log.Fatalf("Failed to create ToneCheck agent: %v", err)
}
```

```java
// --- Define the individual LLM agents ---
LlmAgent storyGenerator =
    LlmAgent.builder()
        .name("StoryGenerator")
        .model(MODEL_NAME)
        .description("Generates the initial story.")
        .instruction(
            """
          You are a story writer. Write a short story (around 100 words) about a cat,
          based on the topic: {topic}
          """)
        .inputSchema(null)
        .outputKey("current_story") // Key for storing output in session state
        .build();

LlmAgent critic =
    LlmAgent.builder()
        .name("Critic")
        .model(MODEL_NAME)
        .description("Critiques the story.")
        .instruction(
            """
          You are a story critic. Review the story: {current_story}. Provide 1-2 sentences of constructive criticism
          on how to improve it. Focus on plot or character.
          """)
        .inputSchema(null)
        .outputKey("criticism") // Key for storing criticism in session state
        .build();

LlmAgent reviser =
    LlmAgent.builder()
        .name("Reviser")
        .model(MODEL_NAME)
        .description("Revises the story based on criticism.")
        .instruction(
            """
          You are a story reviser. Revise the story: {current_story}, based on the criticism: {criticism}. Output only the revised story.
          """)
        .inputSchema(null)
        .outputKey("current_story") // Overwrites the original story
        .build();

LlmAgent grammarCheck =
    LlmAgent.builder()
        .name("GrammarCheck")
        .model(MODEL_NAME)
        .description("Checks grammar and suggests corrections.")
        .instruction(
            """
           You are a grammar checker. Check the grammar of the story: {current_story}. Output only the suggested
           corrections as a list, or output 'Grammar is good!' if there are no errors.
           """)
        .outputKey("grammar_suggestions")
        .build();

LlmAgent toneCheck =
    LlmAgent.builder()
        .name("ToneCheck")
        .model(MODEL_NAME)
        .description("Analyzes the tone of the story.")
        .instruction(
            """
          You are a tone analyzer. Analyze the tone of the story: {current_story}. Output only one word: 'positive' if
          the tone is generally positive, 'negative' if the tone is generally negative, or 'neutral'
          otherwise.
          """)
        .outputKey("tone_check_result") // This agent's output determines the conditional flow
        .build();

LoopAgent loopAgent =
    LoopAgent.builder()
        .name("CriticReviserLoop")
        .description("Iteratively critiques and revises the story.")
        .subAgents(critic, reviser)
        .maxIterations(2)
        .build();

SequentialAgent sequentialAgent =
    SequentialAgent.builder()
        .name("PostProcessing")
        .description("Performs grammar and tone checks sequentially.")
        .subAgents(grammarCheck, toneCheck)
        .build();
```

______________________________________________________________________

### Part 4: Instantiating and Running the custom agent

Finally, you instantiate your `StoryFlowAgent` and use the `Runner` as usual.

```python
# --- Create the custom agent instance ---
story_flow_agent = StoryFlowAgent(
    name="StoryFlowAgent",
    story_generator=story_generator,
    critic=critic,
    reviser=reviser,
    grammar_check=grammar_check,
    tone_check=tone_check,
)

INITIAL_STATE = {"topic": "a brave kitten exploring a haunted house"}

# --- Setup Runner and Session ---
async def setup_session_and_runner():
    session_service = InMemorySessionService()
    session = await session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID, state=INITIAL_STATE)
    logger.info(f"Initial session state: {session.state}")
    runner = Runner(
        agent=story_flow_agent, # Pass the custom orchestrator agent
        app_name=APP_NAME,
        session_service=session_service
    )
    return session_service, runner

# --- Function to Interact with the Agent ---
async def call_agent_async(user_input_topic: str):
    """
    Sends a new topic to the agent (overwriting the initial one if needed)
    and runs the workflow.
    """

    session_service, runner = await setup_session_and_runner()

    current_session = session_service.sessions[APP_NAME][USER_ID][SESSION_ID]
    current_session.state["topic"] = user_input_topic
    logger.info(f"Updated session state topic to: {user_input_topic}")

    content = types.Content(role='user', parts=[types.Part(text=f"Generate a story about the preset topic.")])
    events = runner.run_async(user_id=USER_ID, session_id=SESSION_ID, new_message=content)

    final_response = "No final response captured."
    async for event in events:
        if event.is_final_response() and event.content and event.content.parts:
            logger.info(f"Potential final response from [{event.author}]: {event.content.parts[0].text}")
            final_response = event.content.parts[0].text

    print("\n--- Agent Interaction Result ---")
    print("Agent Final Response: ", final_response)

    final_session = await session_service.get_session(app_name=APP_NAME, 
                                                user_id=USER_ID, 
                                                session_id=SESSION_ID)
    print("Final Session State:")
    import json
    print(json.dumps(final_session.state, indent=2))
    print("-------------------------------\n")

# --- Run the Agent ---
# Note: In Colab, you can directly use 'await' at the top level.
# If running this code as a standalone Python script, you'll need to use asyncio.run() or manage the event loop.
await call_agent_async("a lonely robot finding a friend in a junkyard")
```

```typescript
// --- Create the custom agent instance ---
const storyFlowAgent = new StoryFlowAgent(
    "StoryFlowAgent",
    storyGenerator,
    critic,
    reviser,
    grammarCheck,
    toneCheck
);

const INITIAL_STATE = { "topic": "a brave kitten exploring a haunted house" };

// --- Setup Runner and Session ---
async function setupRunnerAndSession() {
  const runner = new InMemoryRunner({
    agent: storyFlowAgent,
    appName: APP_NAME,
  });
  const session = await runner.sessionService.createSession({
    appName: APP_NAME,
    userId: USER_ID,
    sessionId: SESSION_ID,
    state: INITIAL_STATE,
  });
  console.log(`Initial session state: ${JSON.stringify(session.state, null, 2)}`);
  return runner;
}

// --- Function to Interact with the Agent ---
async function callAgent(runner: InMemoryRunner, userInputTopic: string) {
  const currentSession = await runner.sessionService.getSession({
      appName: APP_NAME,
      userId: USER_ID,
      sessionId: SESSION_ID
  });

  if (!currentSession) {
      return;
  }
  // Update the state with the new topic for this run
  currentSession.state["topic"] = userInputTopic;
  console.log(`Updated session state topic to: ${userInputTopic}`);

  let finalResponse = "No final response captured.";
  for await (const event of runner.runAsync({
    userId: USER_ID,
    sessionId: SESSION_ID,
    newMessage: createUserContent(`Generate a story about: ${userInputTopic}`)
  })) {
    if (isFinalResponse(event) && event.content?.parts?.length) {
      console.log(`Potential final response from [${event.author}]: ${event.content.parts.map(part => part.text ?? '').join('')}`);
      finalResponse = event.content.parts.map(part => part.text ?? '').join('');
    }
  }

  const finalSession = await runner.sessionService.getSession({
    appName: APP_NAME,
    userId: USER_ID,
    sessionId: SESSION_ID
  });

  console.log("\n--- Agent Interaction Result ---");
  console.log("Agent Final Response: ", finalResponse);
  console.log("Final Session State:");
  console.log(JSON.stringify(finalSession?.state, null, 2));
  console.log("-------------------------------\n");
}

// --- Run the Agent ---
async function main() {
  const runner = await setupRunnerAndSession();
  await callAgent(runner, "a lonely robot finding a friend in a junkyard");
}

main();
```

```go
    // Instantiate the custom agent, which encapsulates the workflow agents.
    storyFlowAgent, err := NewStoryFlowAgent(
        storyGenerator,
        critic,
        reviser,
        grammarCheck,
        toneCheck,
    )
    if err != nil {
        log.Fatalf("Failed to create story flow agent: %v", err)
    }

    // --- Run the Agent ---
    sessionService := session.InMemoryService()
    initialState := map[string]any{
        "topic": "a brave kitten exploring a haunted house",
    }
    sessionInstance, err := sessionService.Create(ctx, &session.CreateRequest{
        AppName: appName,
        UserID:  userID,
        State:   initialState,
    })
    if err != nil {
        log.Fatalf("Failed to create session: %v", err)
    }

    userTopic := "a lonely robot finding a friend in a junkyard"

    r, err := runner.New(runner.Config{
        AppName:        appName,
        Agent:          storyFlowAgent,
        SessionService: sessionService,
    })
    if err != nil {
        log.Fatalf("Failed to create runner: %v", err)
    }

    input := genai.NewContentFromText("Generate a story about: "+userTopic, genai.RoleUser)
    events := r.Run(ctx, userID, sessionInstance.Session.ID(), input, agent.RunConfig{
        StreamingMode: agent.StreamingModeSSE,
    })

    var finalResponse string
    for event, err := range events {
        if err != nil {
            log.Fatalf("An error occurred during agent execution: %v", err)
        }

        for _, part := range event.Content.Parts {
            // Accumulate text from all parts of the final response.
            finalResponse += part.Text
        }
    }

    fmt.Println("\n--- Agent Interaction Result ---")
    fmt.Println("Agent Final Response: " + finalResponse)

    finalSession, err := sessionService.Get(ctx, &session.GetRequest{
        UserID:    userID,
        AppName:   appName,
        SessionID: sessionInstance.Session.ID(),
    })

    if err != nil {
        log.Fatalf("Failed to retrieve final session: %v", err)
    }

    fmt.Println("Final Session State:", finalSession.Session.State())
}
```

```java
// --- Function to Interact with the Agent ---
// Sends a new topic to the agent (overwriting the initial one if needed)
// and runs the workflow.
public static void runAgent(StoryFlowAgentExample agent, String userTopic) {
  // --- Setup Runner and Session ---
  InMemoryRunner runner = new InMemoryRunner(agent);

  Map<String, Object> initialState = new HashMap<>();
  initialState.put("topic", "a brave kitten exploring a haunted house");

  Session session =
      runner
          .sessionService()
          .createSession(APP_NAME, USER_ID, new ConcurrentHashMap<>(initialState), SESSION_ID)
          .blockingGet();
  logger.log(Level.INFO, () -> String.format("Initial session state: %s", session.state()));

  session.state().put("topic", userTopic); // Update the state in the retrieved session
  logger.log(Level.INFO, () -> String.format("Updated session state topic to: %s", userTopic));

  Content userMessage = Content.fromParts(Part.fromText("Generate a story about: " + userTopic));
  // Use the modified session object for the run
  Flowable<Event> eventStream = runner.runAsync(USER_ID, session.id(), userMessage);

  final String[] finalResponse = {"No final response captured."};
  eventStream.blockingForEach(
      event -> {
        if (event.finalResponse() && event.content().isPresent()) {
          String author = event.author() != null ? event.author() : "UNKNOWN_AUTHOR";
          Optional<String> textOpt =
              event
                  .content()
                  .flatMap(Content::parts)
                  .filter(parts -> !parts.isEmpty())
                  .map(parts -> parts.get(0).text().orElse(""));

          logger.log(Level.INFO, () ->
              String.format("Potential final response from [%s]: %s", author, textOpt.orElse("N/A")));
          textOpt.ifPresent(text -> finalResponse[0] = text);
        }
      });

  System.out.println("\n--- Agent Interaction Result ---");
  System.out.println("Agent Final Response: " + finalResponse[0]);

  // Retrieve session again to see the final state after the run
  Session finalSession =
      runner
          .sessionService()
          .getSession(APP_NAME, USER_ID, SESSION_ID, Optional.empty())
          .blockingGet();

  assert finalSession != null;
  System.out.println("Final Session State:" + finalSession.state());
  System.out.println("-------------------------------\n");
}
```

*(Note: The full runnable code, including imports and execution logic, can be found linked below.)*

______________________________________________________________________

## Full Code Example

Storyflow Agent

```python
# Full runnable code for the StoryFlowAgent example
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

import logging
from typing import AsyncGenerator
from typing_extensions import override

from google.adk.agents import LlmAgent, BaseAgent, LoopAgent, SequentialAgent
from google.adk.agents.invocation_context import InvocationContext
from google.genai import types
from google.adk.sessions import InMemorySessionService
from google.adk.runners import Runner
from google.adk.events import Event
from pydantic import BaseModel, Field

# --- Constants ---
APP_NAME = "story_app"
USER_ID = "12345"
SESSION_ID = "123344"
GEMINI_2_FLASH = "gemini-2.0-flash"

# --- Configure Logging ---
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# --- Custom Orchestrator Agent ---
class StoryFlowAgent(BaseAgent):
    """
    Custom agent for a story generation and refinement workflow.

    This agent orchestrates a sequence of LLM agents to generate a story,
    critique it, revise it, check grammar and tone, and potentially
    regenerate the story if the tone is negative.
    """

    # --- Field Declarations for Pydantic ---
    # Declare the agents passed during initialization as class attributes with type hints
    story_generator: LlmAgent
    critic: LlmAgent
    reviser: LlmAgent
    grammar_check: LlmAgent
    tone_check: LlmAgent

    loop_agent: LoopAgent
    sequential_agent: SequentialAgent

    # model_config allows setting Pydantic configurations if needed, e.g., arbitrary_types_allowed
    model_config = {"arbitrary_types_allowed": True}

    def __init__(
        self,
        name: str,
        story_generator: LlmAgent,
        critic: LlmAgent,
        reviser: LlmAgent,
        grammar_check: LlmAgent,
        tone_check: LlmAgent,
    ):
        """
        Initializes the StoryFlowAgent.

        Args:
            name: The name of the agent.
            story_generator: An LlmAgent to generate the initial story.
            critic: An LlmAgent to critique the story.
            reviser: An LlmAgent to revise the story based on criticism.
            grammar_check: An LlmAgent to check the grammar.
            tone_check: An LlmAgent to analyze the tone.
        """
        # Create internal agents *before* calling super().__init__
        loop_agent = LoopAgent(
            name="CriticReviserLoop", sub_agents=[critic, reviser], max_iterations=2
        )
        sequential_agent = SequentialAgent(
            name="PostProcessing", sub_agents=[grammar_check, tone_check]
        )

        # Define the sub_agents list for the framework
        sub_agents_list = [
            story_generator,
            loop_agent,
            sequential_agent,
        ]

        # Pydantic will validate and assign them based on the class annotations.
        super().__init__(
            name=name,
            story_generator=story_generator,
            critic=critic,
            reviser=reviser,
            grammar_check=grammar_check,
            tone_check=tone_check,
            loop_agent=loop_agent,
            sequential_agent=sequential_agent,
            sub_agents=sub_agents_list, # Pass the sub_agents list directly
        )

    @override
    async def _run_async_impl(
        self, ctx: InvocationContext
    ) -> AsyncGenerator[Event, None]:
        """
        Implements the custom orchestration logic for the story workflow.
        Uses the instance attributes assigned by Pydantic (e.g., self.story_generator).
        """
        logger.info(f"[{self.name}] Starting story generation workflow.")

        # 1. Initial Story Generation
        logger.info(f"[{self.name}] Running StoryGenerator...")
        async for event in self.story_generator.run_async(ctx):
            logger.info(f"[{self.name}] Event from StoryGenerator: {event.model_dump_json(indent=2, exclude_none=True)}")
            yield event

        # Check if story was generated before proceeding
        if "current_story" not in ctx.session.state or not ctx.session.state["current_story"]:
             logger.error(f"[{self.name}] Failed to generate initial story. Aborting workflow.")
             return # Stop processing if initial story failed

        logger.info(f"[{self.name}] Story state after generator: {ctx.session.state.get('current_story')}")


        # 2. Critic-Reviser Loop
        logger.info(f"[{self.name}] Running CriticReviserLoop...")
        # Use the loop_agent instance attribute assigned during init
        async for event in self.loop_agent.run_async(ctx):
            logger.info(f"[{self.name}] Event from CriticReviserLoop: {event.model_dump_json(indent=2, exclude_none=True)}")
            yield event

        logger.info(f"[{self.name}] Story state after loop: {ctx.session.state.get('current_story')}")

        # 3. Sequential Post-Processing (Grammar and Tone Check)
        logger.info(f"[{self.name}] Running PostProcessing...")
        # Use the sequential_agent instance attribute assigned during init
        async for event in self.sequential_agent.run_async(ctx):
            logger.info(f"[{self.name}] Event from PostProcessing: {event.model_dump_json(indent=2, exclude_none=True)}")
            yield event

        # 4. Tone-Based Conditional Logic
        tone_check_result = ctx.session.state.get("tone_check_result")
        logger.info(f"[{self.name}] Tone check result: {tone_check_result}")

        if tone_check_result == "negative":
            logger.info(f"[{self.name}] Tone is negative. Regenerating story...")
            async for event in self.story_generator.run_async(ctx):
                logger.info(f"[{self.name}] Event from StoryGenerator (Regen): {event.model_dump_json(indent=2, exclude_none=True)}")
                yield event
        else:
            logger.info(f"[{self.name}] Tone is not negative. Keeping current story.")
            pass

        logger.info(f"[{self.name}] Workflow finished.")

# --- Define the individual LLM agents ---
story_generator = LlmAgent(
    name="StoryGenerator",
    model=GEMINI_2_FLASH,
    instruction="""You are a story writer. Write a short story (around 100 words), on the following topic: {topic}""",
    input_schema=None,
    output_key="current_story",  # Key for storing output in session state
)

critic = LlmAgent(
    name="Critic",
    model=GEMINI_2_FLASH,
    instruction="""You are a story critic. Review the story provided: {{current_story}}. Provide 1-2 sentences of constructive criticism
on how to improve it. Focus on plot or character.""",
    input_schema=None,
    output_key="criticism",  # Key for storing criticism in session state
)

reviser = LlmAgent(
    name="Reviser",
    model=GEMINI_2_FLASH,
    instruction="""You are a story reviser. Revise the story provided: {{current_story}}, based on the criticism in
{{criticism}}. Output only the revised story.""",
    input_schema=None,
    output_key="current_story",  # Overwrites the original story
)

grammar_check = LlmAgent(
    name="GrammarCheck",
    model=GEMINI_2_FLASH,
    instruction="""You are a grammar checker. Check the grammar of the story provided: {current_story}. Output only the suggested
corrections as a list, or output 'Grammar is good!' if there are no errors.""",
    input_schema=None,
    output_key="grammar_suggestions",
)

tone_check = LlmAgent(
    name="ToneCheck",
    model=GEMINI_2_FLASH,
    instruction="""You are a tone analyzer. Analyze the tone of the story provided: {current_story}. Output only one word: 'positive' if
the tone is generally positive, 'negative' if the tone is generally negative, or 'neutral'
otherwise.""",
    input_schema=None,
    output_key="tone_check_result", # This agent's output determines the conditional flow
)

# --- Create the custom agent instance ---
story_flow_agent = StoryFlowAgent(
    name="StoryFlowAgent",
    story_generator=story_generator,
    critic=critic,
    reviser=reviser,
    grammar_check=grammar_check,
    tone_check=tone_check,
)

INITIAL_STATE = {"topic": "a brave kitten exploring a haunted house"}

# --- Setup Runner and Session ---
async def setup_session_and_runner():
    session_service = InMemorySessionService()
    session = await session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID, state=INITIAL_STATE)
    logger.info(f"Initial session state: {session.state}")
    runner = Runner(
        agent=story_flow_agent, # Pass the custom orchestrator agent
        app_name=APP_NAME,
        session_service=session_service
    )
    return session_service, runner

# --- Function to Interact with the Agent ---
async def call_agent_async(user_input_topic: str):
    """
    Sends a new topic to the agent (overwriting the initial one if needed)
    and runs the workflow.
    """

    session_service, runner = await setup_session_and_runner()

    current_session = session_service.sessions[APP_NAME][USER_ID][SESSION_ID]
    current_session.state["topic"] = user_input_topic
    logger.info(f"Updated session state topic to: {user_input_topic}")

    content = types.Content(role='user', parts=[types.Part(text=f"Generate a story about the preset topic.")])
    events = runner.run_async(user_id=USER_ID, session_id=SESSION_ID, new_message=content)

    final_response = "No final response captured."
    async for event in events:
        if event.is_final_response() and event.content and event.content.parts:
            logger.info(f"Potential final response from [{event.author}]: {event.content.parts[0].text}")
            final_response = event.content.parts[0].text

    print("\n--- Agent Interaction Result ---")
    print("Agent Final Response: ", final_response)

    final_session = await session_service.get_session(app_name=APP_NAME, 
                                                user_id=USER_ID, 
                                                session_id=SESSION_ID)
    print("Final Session State:")
    import json
    print(json.dumps(final_session.state, indent=2))
    print("-------------------------------\n")

# --- Run the Agent ---
# Note: In Colab, you can directly use 'await' at the top level.
# If running this code as a standalone Python script, you'll need to use asyncio.run() or manage the event loop.
await call_agent_async("a lonely robot finding a friend in a junkyard")
```

```typescript
// Full runnable code for the StoryFlowAgent example

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

import { LlmAgent, BaseAgent, LoopAgent, SequentialAgent, InMemoryRunner, InvocationContext, Event, isFinalResponse } from '@google/adk';
import { createUserContent } from "@google/genai";

// --- Constants ---
const APP_NAME = "story_app_ts";
const USER_ID = "12345";
const SESSION_ID = "123344_ts";
const GEMINI_MODEL = "gemini-2.5-flash";

// --- Custom Orchestrator Agent ---
class StoryFlowAgent extends BaseAgent {
  // --- Property Declarations for TypeScript ---
  private storyGenerator: LlmAgent;
  private critic: LlmAgent;
  private reviser: LlmAgent;
  private grammarCheck: LlmAgent;
  private toneCheck: LlmAgent;

  private loopAgent: LoopAgent;
  private sequentialAgent: SequentialAgent;

  constructor(
    name: string,
    storyGenerator: LlmAgent,
    critic: LlmAgent,
    reviser: LlmAgent,
    grammarCheck: LlmAgent,
    toneCheck: LlmAgent
  ) {
    // Create internal composite agents
    const loopAgent = new LoopAgent({
      name: "CriticReviserLoop",
      subAgents: [critic, reviser],
      maxIterations: 2,
    });

    const sequentialAgent = new SequentialAgent({
      name: "PostProcessing",
      subAgents: [grammarCheck, toneCheck],
    });

    // Define the sub-agents for the framework to know about
    const subAgentsList = [
      storyGenerator,
      loopAgent,
      sequentialAgent,
    ];

    // Call the parent constructor
    super({
      name,
      subAgents: subAgentsList,
    });

    // Assign agents to class properties for use in the custom run logic
    this.storyGenerator = storyGenerator;
    this.critic = critic;
    this.reviser = reviser;
    this.grammarCheck = grammarCheck;
    this.toneCheck = toneCheck;
    this.loopAgent = loopAgent;
    this.sequentialAgent = sequentialAgent;
  }

  // Implements the custom orchestration logic for the story workflow.
  async* runLiveImpl(ctx: InvocationContext): AsyncGenerator<Event, void, undefined> {
    yield* this.runAsyncImpl(ctx);
  }

  // Implements the custom orchestration logic for the story workflow.
  async* runAsyncImpl(ctx: InvocationContext): AsyncGenerator<Event, void, undefined> {
    console.log(`[${this.name}] Starting story generation workflow.`);

    // 1. Initial Story Generation
    console.log(`[${this.name}] Running StoryGenerator...`);
    for await (const event of this.storyGenerator.runAsync(ctx)) {
      console.log(`[${this.name}] Event from StoryGenerator: ${JSON.stringify(event, null, 2)}`);
      yield event;
    }

    // Check if the story was generated before proceeding
    if (!ctx.session.state["current_story"]) {
      console.error(`[${this.name}] Failed to generate initial story. Aborting workflow.`);
      return; // Stop processing
    }
    console.log(`[${this.name}] Story state after generator: ${ctx.session.state['current_story']}`);

    // 2. Critic-Reviser Loop
    console.log(`[${this.name}] Running CriticReviserLoop...`);
    for await (const event of this.loopAgent.runAsync(ctx)) {
      console.log(`[${this.name}] Event from CriticReviserLoop: ${JSON.stringify(event, null, 2)}`);
      yield event;
    }
    console.log(`[${this.name}] Story state after loop: ${ctx.session.state['current_story']}`);

    // 3. Sequential Post-Processing (Grammar and Tone Check)
    console.log(`[${this.name}] Running PostProcessing...`);
    for await (const event of this.sequentialAgent.runAsync(ctx)) {
      console.log(`[${this.name}] Event from PostProcessing: ${JSON.stringify(event, null, 2)}`);
      yield event;
    }

    // 4. Tone-Based Conditional Logic
    const toneCheckResult = ctx.session.state["tone_check_result"] as string;
    console.log(`[${this.name}] Tone check result: ${toneCheckResult}`);

    if (toneCheckResult === "negative") {
      console.log(`[${this.name}] Tone is negative. Regenerating story...`);
      for await (const event of this.storyGenerator.runAsync(ctx)) {
        console.log(`[${this.name}] Event from StoryGenerator (Regen): ${JSON.stringify(event, null, 2)}`);
        yield event;
      }
    } else {
      console.log(`[${this.name}] Tone is not negative. Keeping current story.`);
    }

    console.log(`[${this.name}] Workflow finished.`);
  }
}

// --- Define the individual LLM agents ---
const storyGenerator = new LlmAgent({
    name: "StoryGenerator",
    model: GEMINI_MODEL,
    instruction: `You are a story writer. Write a short story (around 100 words), on the following topic: {topic}`,
    outputKey: "current_story",
});

const critic = new LlmAgent({
    name: "Critic",
    model: GEMINI_MODEL,
    instruction: `You are a story critic. Review the story provided: {{current_story}}. Provide 1-2 sentences of constructive criticism
on how to improve it. Focus on plot or character.`,
    outputKey: "criticism",
});

const reviser = new LlmAgent({
    name: "Reviser",
    model: GEMINI_MODEL,
    instruction: `You are a story reviser. Revise the story provided: {{current_story}}, based on the criticism in
{{criticism}}. Output only the revised story.`,
    outputKey: "current_story", // Overwrites the original story
});

const grammarCheck = new LlmAgent({
    name: "GrammarCheck",
    model: GEMINI_MODEL,
    instruction: `You are a grammar checker. Check the grammar of the story provided: {current_story}. Output only the suggested
corrections as a list, or output 'Grammar is good!' if there are no errors.`,
    outputKey: "grammar_suggestions",
});

const toneCheck = new LlmAgent({
    name: "ToneCheck",
    model: GEMINI_MODEL,
    instruction: `You are a tone analyzer. Analyze the tone of the story provided: {current_story}. Output only one word: 'positive' if
the tone is generally positive, 'negative' if the tone is generally negative, or 'neutral'
otherwise.`,
    outputKey: "tone_check_result",
});

// --- Create the custom agent instance ---
const storyFlowAgent = new StoryFlowAgent(
    "StoryFlowAgent",
    storyGenerator,
    critic,
    reviser,
    grammarCheck,
    toneCheck
);

const INITIAL_STATE = { "topic": "a brave kitten exploring a haunted house" };

// --- Setup Runner and Session ---
async function setupRunnerAndSession() {
  const runner = new InMemoryRunner({
    agent: storyFlowAgent,
    appName: APP_NAME,
  });
  const session = await runner.sessionService.createSession({
    appName: APP_NAME,
    userId: USER_ID,
    sessionId: SESSION_ID,
    state: INITIAL_STATE,
  });
  console.log(`Initial session state: ${JSON.stringify(session.state, null, 2)}`);
  return runner;
}

// --- Function to Interact with the Agent ---
async function callAgent(runner: InMemoryRunner, userInputTopic: string) {
  const currentSession = await runner.sessionService.getSession({
      appName: APP_NAME,
      userId: USER_ID,
      sessionId: SESSION_ID
  });

  if (!currentSession) {
      return;
  }
  // Update the state with the new topic for this run
  currentSession.state["topic"] = userInputTopic;
  console.log(`Updated session state topic to: ${userInputTopic}`);

  let finalResponse = "No final response captured.";
  for await (const event of runner.runAsync({
    userId: USER_ID,
    sessionId: SESSION_ID,
    newMessage: createUserContent(`Generate a story about: ${userInputTopic}`)
  })) {
    if (isFinalResponse(event) && event.content?.parts?.length) {
      console.log(`Potential final response from [${event.author}]: ${event.content.parts.map(part => part.text ?? '').join('')}`);
      finalResponse = event.content.parts.map(part => part.text ?? '').join('');
    }
  }

  const finalSession = await runner.sessionService.getSession({
    appName: APP_NAME,
    userId: USER_ID,
    sessionId: SESSION_ID
  });

  console.log("\n--- Agent Interaction Result ---");
  console.log("Agent Final Response: ", finalResponse);
  console.log("Final Session State:");
  console.log(JSON.stringify(finalSession?.state, null, 2));
  console.log("-------------------------------\n");
}

// --- Run the Agent ---
async function main() {
  const runner = await setupRunnerAndSession();
  await callAgent(runner, "a lonely robot finding a friend in a junkyard");
}

main();
```

```go
# Full runnable code for the StoryFlowAgent example
package main

import (
    "context"
    "fmt"
    "iter"
    "log"

    "google.golang.org/adk/agent/workflowagents/loopagent"
    "google.golang.org/adk/agent/workflowagents/sequentialagent"

    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model/gemini"
    "google.golang.org/adk/runner"
    "google.golang.org/adk/session"
    "google.golang.org/genai"
)

// StoryFlowAgent is a custom agent that orchestrates a story generation workflow.
// It encapsulates the logic of running sub-agents in a specific sequence.
type StoryFlowAgent struct {
    storyGenerator     agent.Agent
    revisionLoopAgent  agent.Agent
    postProcessorAgent agent.Agent
}

// NewStoryFlowAgent creates and configures the entire custom agent workflow.
// It takes individual LLM agents as input and internally creates the necessary
// workflow agents (loop, sequential), returning the final orchestrator agent.
func NewStoryFlowAgent(
    storyGenerator,
    critic,
    reviser,
    grammarCheck,
    toneCheck agent.Agent,
) (agent.Agent, error) {
    loopAgent, err := loopagent.New(loopagent.Config{
        MaxIterations: 2,
        AgentConfig: agent.Config{
            Name:      "CriticReviserLoop",
            SubAgents: []agent.Agent{critic, reviser},
        },
    })
    if err != nil {
        return nil, fmt.Errorf("failed to create loop agent: %w", err)
    }

    sequentialAgent, err := sequentialagent.New(sequentialagent.Config{
        AgentConfig: agent.Config{
            Name:      "PostProcessing",
            SubAgents: []agent.Agent{grammarCheck, toneCheck},
        },
    })
    if err != nil {
        return nil, fmt.Errorf("failed to create sequential agent: %w", err)
    }

    // The StoryFlowAgent struct holds the agents needed for the Run method.
    orchestrator := &StoryFlowAgent{
        storyGenerator:     storyGenerator,
        revisionLoopAgent:  loopAgent,
        postProcessorAgent: sequentialAgent,
    }

    // agent.New creates the final agent, wiring up the Run method.
    return agent.New(agent.Config{
        Name:        "StoryFlowAgent",
        Description: "Orchestrates story generation, critique, revision, and checks.",
        SubAgents:   []agent.Agent{storyGenerator, loopAgent, sequentialAgent},
        Run:         orchestrator.Run,
    })
}


// Run defines the custom execution logic for the StoryFlowAgent.
func (s *StoryFlowAgent) Run(ctx agent.InvocationContext) iter.Seq2[*session.Event, error] {
    return func(yield func(*session.Event, error) bool) {
        // Stage 1: Initial Story Generation
        for event, err := range s.storyGenerator.Run(ctx) {
            if err != nil {
                yield(nil, fmt.Errorf("story generator failed: %w", err))
                return
            }
            if !yield(event, nil) {
                return
            }
        }

        // Check if story was generated before proceeding
        currentStory, err := ctx.Session().State().Get("current_story")
        if err != nil || currentStory == "" {
            log.Println("Failed to generate initial story. Aborting workflow.")
            return
        }

        // Stage 2: Critic-Reviser Loop
        for event, err := range s.revisionLoopAgent.Run(ctx) {
            if err != nil {
                yield(nil, fmt.Errorf("loop agent failed: %w", err))
                return
            }
            if !yield(event, nil) {
                return
            }
        }

        // Stage 3: Post-Processing
        for event, err := range s.postProcessorAgent.Run(ctx) {
            if err != nil {
                yield(nil, fmt.Errorf("sequential agent failed: %w", err))
                return
            }
            if !yield(event, nil) {
                return
            }
        }

        // Stage 4: Conditional Regeneration
        toneResult, err := ctx.Session().State().Get("tone_check_result")
        if err != nil {
            log.Printf("Could not read tone_check_result from state: %v. Assuming tone is not negative.", err)
            return
        }

        if tone, ok := toneResult.(string); ok && tone == "negative" {
            log.Println("Tone is negative. Regenerating story...")
            for event, err := range s.storyGenerator.Run(ctx) {
                if err != nil {
                    yield(nil, fmt.Errorf("story regeneration failed: %w", err))
                    return
                }
                if !yield(event, nil) {
                    return
                }
            }
        } else {
            log.Println("Tone is not negative. Keeping current story.")
        }
    }
}


const (
    modelName = "gemini-2.0-flash"
    appName   = "story_app"
    userID    = "user_12345"
)

func main() {
    ctx := context.Background()
    model, err := gemini.NewModel(ctx, modelName, &genai.ClientConfig{})
    if err != nil {
        log.Fatalf("Failed to create model: %v", err)
    }

    // --- Define the individual LLM agents ---
    storyGenerator, err := llmagent.New(llmagent.Config{
        Name:        "StoryGenerator",
        Model:       model,
        Description: "Generates the initial story.",
        Instruction: "You are a story writer. Write a short story (around 100 words) about a cat, based on the topic: {topic}",
        OutputKey:   "current_story",
    })
    if err != nil {
        log.Fatalf("Failed to create StoryGenerator agent: %v", err)
    }

    critic, err := llmagent.New(llmagent.Config{
        Name:        "Critic",
        Model:       model,
        Description: "Critiques the story.",
        Instruction: "You are a story critic. Review the story: {current_story}. Provide 1-2 sentences of constructive criticism on how to improve it. Focus on plot or character.",
        OutputKey:   "criticism",
    })
    if err != nil {
        log.Fatalf("Failed to create Critic agent: %v", err)
    }

    reviser, err := llmagent.New(llmagent.Config{
        Name:        "Reviser",
        Model:       model,
        Description: "Revises the story based on criticism.",
        Instruction: "You are a story reviser. Revise the story: {current_story}, based on the criticism: {criticism}. Output only the revised story.",
        OutputKey:   "current_story",
    })
    if err != nil {
        log.Fatalf("Failed to create Reviser agent: %v", err)
    }

    grammarCheck, err := llmagent.New(llmagent.Config{
        Name:        "GrammarCheck",
        Model:       model,
        Description: "Checks grammar and suggests corrections.",
        Instruction: "You are a grammar checker. Check the grammar of the story: {current_story}. Output only the suggested corrections as a list, or output 'Grammar is good!' if there are no errors.",
        OutputKey:   "grammar_suggestions",
    })
    if err != nil {
        log.Fatalf("Failed to create GrammarCheck agent: %v", err)
    }

    toneCheck, err := llmagent.New(llmagent.Config{
        Name:        "ToneCheck",
        Model:       model,
        Description: "Analyzes the tone of the story.",
        Instruction: "You are a tone analyzer. Analyze the tone of the story: {current_story}. Output only one word: 'positive' if the tone is generally positive, 'negative' if the tone is generally negative, or 'neutral' otherwise.",
        OutputKey:   "tone_check_result",
    })
    if err != nil {
        log.Fatalf("Failed to create ToneCheck agent: %v", err)
    }

    // Instantiate the custom agent, which encapsulates the workflow agents.
    storyFlowAgent, err := NewStoryFlowAgent(
        storyGenerator,
        critic,
        reviser,
        grammarCheck,
        toneCheck,
    )
    if err != nil {
        log.Fatalf("Failed to create story flow agent: %v", err)
    }

    // --- Run the Agent ---
    sessionService := session.InMemoryService()
    initialState := map[string]any{
        "topic": "a brave kitten exploring a haunted house",
    }
    sessionInstance, err := sessionService.Create(ctx, &session.CreateRequest{
        AppName: appName,
        UserID:  userID,
        State:   initialState,
    })
    if err != nil {
        log.Fatalf("Failed to create session: %v", err)
    }

    userTopic := "a lonely robot finding a friend in a junkyard"

    r, err := runner.New(runner.Config{
        AppName:        appName,
        Agent:          storyFlowAgent,
        SessionService: sessionService,
    })
    if err != nil {
        log.Fatalf("Failed to create runner: %v", err)
    }

    input := genai.NewContentFromText("Generate a story about: "+userTopic, genai.RoleUser)
    events := r.Run(ctx, userID, sessionInstance.Session.ID(), input, agent.RunConfig{
        StreamingMode: agent.StreamingModeSSE,
    })

    var finalResponse string
    for event, err := range events {
        if err != nil {
            log.Fatalf("An error occurred during agent execution: %v", err)
        }

        for _, part := range event.Content.Parts {
            // Accumulate text from all parts of the final response.
            finalResponse += part.Text
        }
    }

    fmt.Println("\n--- Agent Interaction Result ---")
    fmt.Println("Agent Final Response: " + finalResponse)

    finalSession, err := sessionService.Get(ctx, &session.GetRequest{
        UserID:    userID,
        AppName:   appName,
        SessionID: sessionInstance.Session.ID(),
    })

    if err != nil {
        log.Fatalf("Failed to retrieve final session: %v", err)
    }

    fmt.Println("Final Session State:", finalSession.Session.State())
}
```

```java
# Full runnable code for the StoryFlowAgent example

import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.BaseAgent;
import com.google.adk.agents.InvocationContext;
import com.google.adk.agents.LoopAgent;
import com.google.adk.agents.SequentialAgent;
import com.google.adk.events.Event;
import com.google.adk.runner.InMemoryRunner;
import com.google.adk.sessions.Session;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import io.reactivex.rxjava3.core.Flowable;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.logging.Level;
import java.util.logging.Logger;

public class StoryFlowAgentExample extends BaseAgent {

  // --- Constants ---
  private static final String APP_NAME = "story_app";
  private static final String USER_ID = "user_12345";
  private static final String SESSION_ID = "session_123344";
  private static final String MODEL_NAME = "gemini-2.0-flash"; // Ensure this model is available

  private static final Logger logger = Logger.getLogger(StoryFlowAgentExample.class.getName());

  private final LlmAgent storyGenerator;
  private final LoopAgent loopAgent;
  private final SequentialAgent sequentialAgent;

  public StoryFlowAgentExample(
      String name, LlmAgent storyGenerator, LoopAgent loopAgent, SequentialAgent sequentialAgent) {
    super(
        name,
        "Orchestrates story generation, critique, revision, and checks.",
        List.of(storyGenerator, loopAgent, sequentialAgent),
        null,
        null);

    this.storyGenerator = storyGenerator;
    this.loopAgent = loopAgent;
    this.sequentialAgent = sequentialAgent;
  }

  public static void main(String[] args) {

    // --- Define the individual LLM agents ---
    LlmAgent storyGenerator =
        LlmAgent.builder()
            .name("StoryGenerator")
            .model(MODEL_NAME)
            .description("Generates the initial story.")
            .instruction(
                """
              You are a story writer. Write a short story (around 100 words) about a cat,
              based on the topic: {topic}
              """)
            .inputSchema(null)
            .outputKey("current_story") // Key for storing output in session state
            .build();

    LlmAgent critic =
        LlmAgent.builder()
            .name("Critic")
            .model(MODEL_NAME)
            .description("Critiques the story.")
            .instruction(
                """
              You are a story critic. Review the story: {current_story}. Provide 1-2 sentences of constructive criticism
              on how to improve it. Focus on plot or character.
              """)
            .inputSchema(null)
            .outputKey("criticism") // Key for storing criticism in session state
            .build();

    LlmAgent reviser =
        LlmAgent.builder()
            .name("Reviser")
            .model(MODEL_NAME)
            .description("Revises the story based on criticism.")
            .instruction(
                """
              You are a story reviser. Revise the story: {current_story}, based on the criticism: {criticism}. Output only the revised story.
              """)
            .inputSchema(null)
            .outputKey("current_story") // Overwrites the original story
            .build();

    LlmAgent grammarCheck =
        LlmAgent.builder()
            .name("GrammarCheck")
            .model(MODEL_NAME)
            .description("Checks grammar and suggests corrections.")
            .instruction(
                """
               You are a grammar checker. Check the grammar of the story: {current_story}. Output only the suggested
               corrections as a list, or output 'Grammar is good!' if there are no errors.
               """)
            .outputKey("grammar_suggestions")
            .build();

    LlmAgent toneCheck =
        LlmAgent.builder()
            .name("ToneCheck")
            .model(MODEL_NAME)
            .description("Analyzes the tone of the story.")
            .instruction(
                """
              You are a tone analyzer. Analyze the tone of the story: {current_story}. Output only one word: 'positive' if
              the tone is generally positive, 'negative' if the tone is generally negative, or 'neutral'
              otherwise.
              """)
            .outputKey("tone_check_result") // This agent's output determines the conditional flow
            .build();

    LoopAgent loopAgent =
        LoopAgent.builder()
            .name("CriticReviserLoop")
            .description("Iteratively critiques and revises the story.")
            .subAgents(critic, reviser)
            .maxIterations(2)
            .build();

    SequentialAgent sequentialAgent =
        SequentialAgent.builder()
            .name("PostProcessing")
            .description("Performs grammar and tone checks sequentially.")
            .subAgents(grammarCheck, toneCheck)
            .build();


    StoryFlowAgentExample storyFlowAgentExample =
        new StoryFlowAgentExample(APP_NAME, storyGenerator, loopAgent, sequentialAgent);

    // --- Run the Agent ---
    runAgent(storyFlowAgentExample, "a lonely robot finding a friend in a junkyard");
  }

  // --- Function to Interact with the Agent ---
  // Sends a new topic to the agent (overwriting the initial one if needed)
  // and runs the workflow.
  public static void runAgent(StoryFlowAgentExample agent, String userTopic) {
    // --- Setup Runner and Session ---
    InMemoryRunner runner = new InMemoryRunner(agent);

    Map<String, Object> initialState = new HashMap<>();
    initialState.put("topic", "a brave kitten exploring a haunted house");

    Session session =
        runner
            .sessionService()
            .createSession(APP_NAME, USER_ID, new ConcurrentHashMap<>(initialState), SESSION_ID)
            .blockingGet();
    logger.log(Level.INFO, () -> String.format("Initial session state: %s", session.state()));

    session.state().put("topic", userTopic); // Update the state in the retrieved session
    logger.log(Level.INFO, () -> String.format("Updated session state topic to: %s", userTopic));

    Content userMessage = Content.fromParts(Part.fromText("Generate a story about: " + userTopic));
    // Use the modified session object for the run
    Flowable<Event> eventStream = runner.runAsync(USER_ID, session.id(), userMessage);

    final String[] finalResponse = {"No final response captured."};
    eventStream.blockingForEach(
        event -> {
          if (event.finalResponse() && event.content().isPresent()) {
            String author = event.author() != null ? event.author() : "UNKNOWN_AUTHOR";
            Optional<String> textOpt =
                event
                    .content()
                    .flatMap(Content::parts)
                    .filter(parts -> !parts.isEmpty())
                    .map(parts -> parts.get(0).text().orElse(""));

            logger.log(Level.INFO, () ->
                String.format("Potential final response from [%s]: %s", author, textOpt.orElse("N/A")));
            textOpt.ifPresent(text -> finalResponse[0] = text);
          }
        });

    System.out.println("\n--- Agent Interaction Result ---");
    System.out.println("Agent Final Response: " + finalResponse[0]);

    // Retrieve session again to see the final state after the run
    Session finalSession =
        runner
            .sessionService()
            .getSession(APP_NAME, USER_ID, SESSION_ID, Optional.empty())
            .blockingGet();

    assert finalSession != null;
    System.out.println("Final Session State:" + finalSession.state());
    System.out.println("-------------------------------\n");
  }

  private boolean isStoryGenerated(InvocationContext ctx) {
    Object currentStoryObj = ctx.session().state().get("current_story");
    return currentStoryObj != null && !String.valueOf(currentStoryObj).isEmpty();
  }

  @Override
  protected Flowable<Event> runAsyncImpl(InvocationContext invocationContext) {
    // Implements the custom orchestration logic for the story workflow.
    // Uses the instance attributes assigned by Pydantic (e.g., self.story_generator).
    logger.log(Level.INFO, () -> String.format("[%s] Starting story generation workflow.", name()));

    // Stage 1. Initial Story Generation
    Flowable<Event> storyGenFlow = runStage(storyGenerator, invocationContext, "StoryGenerator");

    // Stage 2: Critic-Reviser Loop (runs after story generation completes)
    Flowable<Event> criticReviserFlow = Flowable.defer(() -> {
      if (!isStoryGenerated(invocationContext)) {
        logger.log(Level.SEVERE,() ->
            String.format("[%s] Failed to generate initial story. Aborting after StoryGenerator.",
                name()));
        return Flowable.empty(); // Stop further processing if no story
      }
        logger.log(Level.INFO, () ->
            String.format("[%s] Story state after generator: %s",
                name(), invocationContext.session().state().get("current_story")));
        return runStage(loopAgent, invocationContext, "CriticReviserLoop");
    });

    // Stage 3: Post-Processing (runs after critic-reviser loop completes)
    Flowable<Event> postProcessingFlow = Flowable.defer(() -> {
      logger.log(Level.INFO, () ->
          String.format("[%s] Story state after loop: %s",
              name(), invocationContext.session().state().get("current_story")));
      return runStage(sequentialAgent, invocationContext, "PostProcessing");
    });

    // Stage 4: Conditional Regeneration (runs after post-processing completes)
    Flowable<Event> conditionalRegenFlow = Flowable.defer(() -> {
      String toneCheckResult = (String) invocationContext.session().state().get("tone_check_result");
      logger.log(Level.INFO, () -> String.format("[%s] Tone check result: %s", name(), toneCheckResult));

      if ("negative".equalsIgnoreCase(toneCheckResult)) {
        logger.log(Level.INFO, () ->
            String.format("[%s] Tone is negative. Regenerating story...", name()));
        return runStage(storyGenerator, invocationContext, "StoryGenerator (Regen)");
      } else {
        logger.log(Level.INFO, () ->
            String.format("[%s] Tone is not negative. Keeping current story.", name()));
        return Flowable.empty(); // No regeneration needed
      }
    });

    return Flowable.concatArray(storyGenFlow, criticReviserFlow, postProcessingFlow, conditionalRegenFlow)
        .doOnComplete(() -> logger.log(Level.INFO, () -> String.format("[%s] Workflow finished.", name())));
  }

  // Helper method for a single agent run stage with logging
  private Flowable<Event> runStage(BaseAgent agentToRun, InvocationContext ctx, String stageName) {
    logger.log(Level.INFO, () -> String.format("[%s] Running %s...", name(), stageName));
    return agentToRun
        .runAsync(ctx)
        .doOnNext(event ->
            logger.log(Level.INFO,() ->
                String.format("[%s] Event from %s: %s", name(), stageName, event.toJson())))
        .doOnError(err ->
            logger.log(Level.SEVERE,
                String.format("[%s] Error in %s", name(), stageName), err))
        .doOnComplete(() ->
            logger.log(Level.INFO, () ->
                String.format("[%s] %s finished.", name(), stageName)));
  }

  @Override
  protected Flowable<Event> runLiveImpl(InvocationContext invocationContext) {
    return Flowable.error(new UnsupportedOperationException("runLive not implemented."));
  }
}
```

# LLM Agent

Supported in ADK Python v0.1.0 Typescript v0.2.0 Go v0.1.0 Java v0.1.0

The `LlmAgent` (often aliased simply as `Agent`) is a core component in ADK, acting as the "thinking" part of your application. It leverages the power of a Large Language Model (LLM) for reasoning, understanding natural language, making decisions, generating responses, and interacting with tools.

Unlike deterministic [Workflow Agents](https://adk.dev/agents/workflow-agents/index.md) that follow predefined execution paths, `LlmAgent` behavior is non-deterministic. It uses the LLM to interpret instructions and context, deciding dynamically how to proceed, which tools to use (if any), or whether to transfer control to another agent.

Building an effective `LlmAgent` involves defining its identity, clearly guiding its behavior through instructions, and equipping it with the necessary tools and capabilities.

## Defining the Agent's Identity and Purpose

First, you need to establish what the agent *is* and what it's *for*.

- **`name` (Required):** Every agent needs a unique string identifier. This `name` is crucial for internal operations, especially in multi-agent systems where agents need to refer to or delegate tasks to each other. Choose a descriptive name that reflects the agent's function (e.g., `customer_support_router`, `billing_inquiry_agent`). Avoid reserved names like `user`.
- **`description` (Optional, Recommended for Multi-Agent):** Provide a concise summary of the agent's capabilities. This description is primarily used by *other* LLM agents to determine if they should route a task to this agent. Make it specific enough to differentiate it from peers (e.g., "Handles inquiries about current billing statements," not just "Billing agent").
- **`model` (Required):** Specify the underlying LLM that will power this agent's reasoning. This is a string identifier like `"gemini-flash-latest"`. The choice of model impacts the agent's capabilities, cost, and performance. See the [Models](/agents/models/) page for available options and considerations.

```python
# Example: Defining the basic identity
capital_agent = LlmAgent(
    model="gemini-flash-latest",
    name="capital_agent",
    description="Answers user questions about the capital city of a given country."
    # instruction and tools will be added next
)
```

```typescript
// Example: Defining the basic identity
const capitalAgent = new LlmAgent({
    model: 'gemini-flash-latest',
    name: 'capital_agent',
    description: 'Answers user questions about the capital city of a given country.',
    // instruction and tools will be added next
});
```

```go
// Example: Defining the basic identity
agent, err := llmagent.New(llmagent.Config{
    Name:        "capital_agent",
    Model:       model,
    Description: "Answers user questions about the capital city of a given country.",
    // instruction and tools will be added next
})
```

```java
// Example: Defining the basic identity
LlmAgent capitalAgent =
    LlmAgent.builder()
        .model("gemini-flash-latest")
        .name("capital_agent")
        .description("Answers user questions about the capital city of a given country.")
        // instruction and tools will be added next
        .build();
```

## Guiding the Agent: Instructions (`instruction`)

The `instruction` parameter is arguably the most critical for shaping an `LlmAgent`'s behavior. It's a string (or a function returning a string) that tells the agent:

- Its core task or goal.
- Its personality or persona (e.g., "You are a helpful assistant," "You are a witty pirate").
- Constraints on its behavior (e.g., "Only answer questions about X," "Never reveal Y").
- How and when to use its `tools`. You should explain the purpose of each tool and the circumstances under which it should be called, supplementing any descriptions within the tool itself.
- The desired format for its output (e.g., "Respond in JSON," "Provide a bulleted list").

**Tips for Effective Instructions:**

- **Be Clear and Specific:** Avoid ambiguity. Clearly state the desired actions and outcomes.
- **Use Markdown:** Improve readability for complex instructions using headings, lists, etc.
- **Provide Examples (Few-Shot):** For complex tasks or specific output formats, include examples directly in the instruction.
- **Guide Tool Use:** Don't just list tools; explain *when* and *why* the agent should use them.

**State:**

- The instruction is a string template, you can use the `{var}` syntax to insert dynamic values into the instruction.
- `{var}` is used to insert the value of the state variable named var.
- `{artifact.var}` is used to insert the text content of the artifact named var.
- If the state variable or artifact does not exist, the agent will raise an error. If you want to ignore the error, you can append a `?` to the variable name as in `{var?}`.

```python
# Example: Adding instructions
capital_agent = LlmAgent(
    model="gemini-flash-latest",
    name="capital_agent",
    description="Answers user questions about the capital city of a given country.",
    instruction="""You are an agent that provides the capital city of a country.
When a user asks for the capital of a country:
1. Identify the country name from the user's query.
2. Use the `get_capital_city` tool to find the capital.
3. Respond clearly to the user, stating the capital city.
Example Query: "What's the capital of {country}?"
Example Response: "The capital of France is Paris."
""",
    # tools will be added next
)
```

```typescript
// Example: Adding instructions
const capitalAgent = new LlmAgent({
    model: 'gemini-flash-latest',
    name: 'capital_agent',
    description: 'Answers user questions about the capital city of a given country.',
    instruction: `You are an agent that provides the capital city of a country.
        When a user asks for the capital of a country:
        1. Identify the country name from the user's query.
        2. Use the \`getCapitalCity\` tool to find the capital.
        3. Respond clearly to the user, stating the capital city.
        Example Query: "What's the capital of {country}?"
        Example Response: "The capital of France is Paris."
        `,
    // tools will be added next
});
```

```go
    // Example: Adding instructions
    agent, err := llmagent.New(llmagent.Config{
        Name:        "capital_agent",
        Model:       model,
        Description: "Answers user questions about the capital city of a given country.",
        Instruction: `You are an agent that provides the capital city of a country.
When a user asks for the capital of a country:
1. Identify the country name from the user's query.
2. Use the 'get_capital_city' tool to find the capital.
3. Respond clearly to the user, stating the capital city.
Example Query: "What's the capital of {country}?"
Example Response: "The capital of France is Paris."`,
        // tools will be added next
    })
```

```java
// Example: Adding instructions
LlmAgent capitalAgent =
    LlmAgent.builder()
        .model("gemini-flash-latest")
        .name("capital_agent")
        .description("Answers user questions about the capital city of a given country.")
        .instruction(
            """
            You are an agent that provides the capital city of a country.
            When a user asks for the capital of a country:
            1. Identify the country name from the user's query.
            2. Use the `get_capital_city` tool to find the capital.
            3. Respond clearly to the user, stating the capital city.
            Example Query: "What's the capital of {country}?"
            Example Response: "The capital of France is Paris."
            """)
        // tools will be added next
        .build();
```

*(Note: For instructions that apply to* all *agents in a system, consider using `global_instruction` on the root agent, detailed further in the [Multi-Agents](https://adk.dev/agents/multi-agents/index.md) section.)*

## Equipping the Agent: Tools (`tools`)

Tools give your `LlmAgent` capabilities beyond the LLM's built-in knowledge or reasoning. They allow the agent to interact with the outside world, perform calculations, fetch real-time data, or execute specific actions.

- **`tools` (Optional):** Provide a list of tools the agent can use. Each item in the list can be:
  - A native function or method (wrapped as a `FunctionTool`). Python ADK automatically wraps the native function into a `FunctionTool` whereas, you must explicitly wrap your Java methods using `FunctionTool.create(...)`
  - An instance of a class inheriting from `BaseTool`.
  - An instance of another agent (`AgentTool`, enabling agent-to-agent delegation - see [Multi-Agents](https://adk.dev/agents/multi-agents/index.md)).

The LLM uses the function/tool names, descriptions (from docstrings or the `description` field), and parameter schemas to decide which tool to call based on the conversation and its instructions.

```python
# Define a tool function
def get_capital_city(country: str) -> str:
  """Retrieves the capital city for a given country."""
  # Replace with actual logic (e.g., API call, database lookup)
  capitals = {"france": "Paris", "japan": "Tokyo", "canada": "Ottawa"}
  return capitals.get(country.lower(), f"Sorry, I don't know the capital of {country}.")

# Add the tool to the agent
capital_agent = LlmAgent(
    model="gemini-flash-latest",
    name="capital_agent",
    description="Answers user questions about the capital city of a given country.",
    instruction="""You are an agent that provides the capital city of a country... (previous instruction text)""",
    tools=[get_capital_city] # Provide the function directly
)
```

```typescript
import {z} from 'zod';
import { LlmAgent, FunctionTool } from '@google/adk';

// Define the schema for the tool's input parameters
const getCapitalCityParamsSchema = z.object({
    country: z.string().describe('The country to get capital for.'),
});

// Define the tool function itself
async function getCapitalCity(params: z.infer<typeof getCapitalCityParamsSchema>): Promise<{ capitalCity: string }> {
const capitals: Record<string, string> = {
    'france': 'Paris',
    'japan': 'Tokyo',
    'canada': 'Ottawa',
};
const result = capitals[params.country.toLowerCase()] ??
    `Sorry, I don't know the capital of ${params.country}.`;
return {capitalCity: result}; // Tools must return an object
}

// Create an instance of the FunctionTool
const getCapitalCityTool = new FunctionTool({
    name: 'getCapitalCity',
    description: 'Retrieves the capital city for a given country.',
    parameters: getCapitalCityParamsSchema,
    execute: getCapitalCity,
});

// Add the tool to the agent
const capitalAgent = new LlmAgent({
    model: 'gemini-flash-latest',
    name: 'capitalAgent',
    description: 'Answers user questions about the capital city of a given country.',
    instruction: 'You are an agent that provides the capital city of a country...', // Note: the full instruction is omitted for brevity
    tools: [getCapitalCityTool], // Provide the FunctionTool instance in an array
});
```

```go
// Define a tool function
type getCapitalCityArgs struct {
    Country string `json:"country" jsonschema:"The country to get the capital of."`
}
getCapitalCity := func(ctx tool.Context, args getCapitalCityArgs) (map[string]any, error) {
    // Replace with actual logic (e.g., API call, database lookup)
    capitals := map[string]string{"france": "Paris", "japan": "Tokyo", "canada": "Ottawa"}
    capital, ok := capitals[strings.ToLower(args.Country)]
    if !ok {
        return nil, fmt.Errorf("Sorry, I don't know the capital of %s.", args.Country)
    }
    return map[string]any{"result": capital}, nil
}

// Add the tool to the agent
capitalTool, err := functiontool.New(
    functiontool.Config{
        Name:        "get_capital_city",
        Description: "Retrieves the capital city for a given country.",
    },
    getCapitalCity,
)
if err != nil {
    log.Fatal(err)
}
agent, err := llmagent.New(llmagent.Config{
    Name:        "capital_agent",
    Model:       model,
    Description: "Answers user questions about the capital city of a given country.",
    Instruction: "You are an agent that provides the capital city of a country... (previous instruction text)",
    Tools:       []tool.Tool{capitalTool},
})
```

```java
// Define a tool function
// Retrieves the capital city of a given country.
public static Map<String, Object> getCapitalCity(
        @Schema(name = "country", description = "The country to get capital for")
        String country) {
  // Replace with actual logic (e.g., API call, database lookup)
  Map<String, String> countryCapitals = new HashMap<>();
  countryCapitals.put("canada", "Ottawa");
  countryCapitals.put("france", "Paris");
  countryCapitals.put("japan", "Tokyo");

  String result =
          countryCapitals.getOrDefault(
                  country.toLowerCase(), "Sorry, I couldn't find the capital for " + country + ".");
  return Map.of("result", result); // Tools must return a Map
}

// Add the tool to the agent
FunctionTool capitalTool = FunctionTool.create(experiment.getClass(), "getCapitalCity");
LlmAgent capitalAgent =
    LlmAgent.builder()
        .model("gemini-flash-latest")
        .name("capital_agent")
        .description("Answers user questions about the capital city of a given country.")
        .instruction("You are an agent that provides the capital city of a country... (previous instruction text)")
        .tools(capitalTool) // Provide the function wrapped as a FunctionTool
        .build();
```

Learn more about Tools in [Custom Tools](/tools-custom/).

## Advanced Configuration & Control

Beyond the core parameters, `LlmAgent` offers several options for finer control:

### Fine-Tuning LLM Generation (`generate_content_config`)

You can adjust how the underlying LLM generates responses using `generate_content_config`.

- **`generate_content_config` (Optional):** Pass an instance of [`google.genai.types.GenerateContentConfig`](https://googleapis.github.io/python-genai/genai.html#genai.types.GenerateContentConfig) to control parameters like `temperature` (randomness), `max_output_tokens` (response length), `top_p`, `top_k`, and safety settings.

```python
from google.genai import types

agent = LlmAgent(
    # ... other params
    generate_content_config=types.GenerateContentConfig(
        temperature=0.2, # More deterministic output
        max_output_tokens=250,
        safety_settings=[
            types.SafetySetting(
                category=types.HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
                threshold=types.HarmBlockThreshold.BLOCK_LOW_AND_ABOVE,
            )
        ]
    )
)
```

```typescript
import { GenerateContentConfig } from '@google/genai';

const generateContentConfig: GenerateContentConfig = {
    temperature: 0.2, // More deterministic output
    maxOutputTokens: 250,
};

const agent = new LlmAgent({
    // ... other params
    generateContentConfig,
});
```

```go
import "google.golang.org/genai"

temperature := float32(0.2)
agent, err := llmagent.New(llmagent.Config{
    Name:  "gen_config_agent",
    Model: model,
    GenerateContentConfig: &genai.GenerateContentConfig{
        Temperature:     &temperature,
        MaxOutputTokens: 250,
    },
})
```

```java
import com.google.genai.types.GenerateContentConfig;

LlmAgent agent =
    LlmAgent.builder()
        // ... other params
        .generateContentConfig(GenerateContentConfig.builder()
            .temperature(0.2F) // More deterministic output
            .maxOutputTokens(250)
            .build())
        .build();
```

### Structuring Data (`input_schema`, `output_schema`, `output_key`)

For scenarios requiring structured data exchange with an `LLM Agent`, the ADK provides mechanisms to define expected input and desired output formats using schema definitions.

- **`input_schema` (Optional):** Define a schema representing the expected input structure. If set, the user message content passed to this agent *must* be a JSON string conforming to this schema. Your instructions should guide the user or preceding agent accordingly.
- **`output_schema` (Optional):** Define a schema representing the desired output structure. If set, the agent's final response *must* be a JSON string conforming to this schema.

Warning: Using `output_schema` with `tools`

Using `output_schema` with `tools` in the same LLM request is only supported by specific models, including [Gemini 3.0](https://ai.google.dev/gemini-api/docs/function-calling?example=meeting#structured-output). For other models, workarounds using [function tools](https://github.com/google/adk-python/blob/main/src/google/adk/flows/llm_flows/_output_schema_processor.py)) in ADK may not work reliably. In such cases, consider using sub-agents that handle output formatting separately.

- **`output_key` (Optional):** Provide a string key. If set, the text content of the agent's *final* response will be automatically saved to the session's state dictionary under this key. This is useful for passing results between agents or steps in a workflow.
  - In Python, this might look like: `session.state[output_key] = agent_response_text`
  - In Java: `session.state().put(outputKey, agentResponseText)`
  - In Golang, within a callback handler: `ctx.State().Set(output_key, agentResponseText)`

The input and output schema is typically a `Pydantic` BaseModel.

```python
from pydantic import BaseModel, Field

class CapitalOutput(BaseModel):
    capital: str = Field(description="The capital of the country.")

structured_capital_agent = LlmAgent(
    # ... name, model, description
    instruction="""You are a Capital Information Agent. Given a country, respond ONLY with a JSON object containing the capital. Format: {"capital": "capital_name"}""",
    output_schema=CapitalOutput, # Enforce JSON output
    output_key="found_capital"  # Store result in state['found_capital']
    # Cannot use tools=[get_capital_city] effectively here
)
```

```typescript
import {z} from 'zod';
import { Schema, Type } from '@google/genai';

// Define the schema for the output
const CapitalOutputSchema: Schema = {
    type: Type.OBJECT,
    properties: {
        capital: {
            type: Type.STRING,
            description: 'The capital of the country.',
        },
    },
    required: ['capital'],
};

// Create the LlmAgent instance
const structuredCapitalAgent = new LlmAgent({
    // ... name, model, description
    instruction: `You are a Capital Information Agent. Given a country, respond ONLY with a JSON object containing the capital. Format: {"capital": "capital_name"}`,
    outputSchema: CapitalOutputSchema, // Enforce JSON output
    outputKey: 'found_capital', // Store result in state['found_capital']
    // Cannot use tools effectively here
});
```

The input and output schema is a `google.genai.types.Schema` object.

```go
capitalOutput := &genai.Schema{
    Type:        genai.TypeObject,
    Description: "Schema for capital city information.",
    Properties: map[string]*genai.Schema{
        "capital": {
            Type:        genai.TypeString,
            Description: "The capital city of the country.",
        },
    },
}

agent, err := llmagent.New(llmagent.Config{
    Name:         "structured_capital_agent",
    Model:        model,
    Description:  "Provides capital information in a structured format.",
    Instruction:  `You are a Capital Information Agent. Given a country, respond ONLY with a JSON object containing the capital. Format: {"capital": "capital_name"}`,
    OutputSchema: capitalOutput,
    OutputKey:    "found_capital",
    // Cannot use the capitalTool tool effectively here
})
```

The input and output schema is a `google.genai.types.Schema` object.

```java
private static final Schema CAPITAL_OUTPUT =
    Schema.builder()
        .type("OBJECT")
        .description("Schema for capital city information.")
        .properties(
            Map.of(
                "capital",
                Schema.builder()
                    .type("STRING")
                    .description("The capital city of the country.")
                    .build()))
        .build();

LlmAgent structuredCapitalAgent =
    LlmAgent.builder()
        // ... name, model, description
        .instruction(
                "You are a Capital Information Agent. Given a country, respond ONLY with a JSON object containing the capital. Format: {\"capital\": \"capital_name\"}")
        .outputSchema(CAPITAL_OUTPUT) // Enforce JSON output
        .outputKey("found_capital") // Store result in state.get("found_capital")
        // Cannot use tools(getCapitalCity) effectively here
        .build();
```

### Managing Context (`include_contents`)

Control whether the agent receives the prior conversation history.

- **`include_contents` (Optional, Default: `'default'`):** Determines if the `contents` (history) are sent to the LLM.
  - `'default'`: The agent receives the relevant conversation history.
  - `'none'`: The agent receives no prior `contents`. It operates based solely on its current instruction and any input provided in the *current* turn (useful for stateless tasks or enforcing specific contexts).

```python
stateless_agent = LlmAgent(
    # ... other params
    include_contents='none'
)
```

```typescript
const statelessAgent = new LlmAgent({
    // ... other params
    includeContents: 'none',
});
```

```go
import "google.golang.org/adk/agent/llmagent"

agent, err := llmagent.New(llmagent.Config{
    Name:            "stateless_agent",
    Model:           model,
    IncludeContents: llmagent.IncludeContentsNone,
})
```

```java
import com.google.adk.agents.LlmAgent.IncludeContents;

LlmAgent statelessAgent =
    LlmAgent.builder()
        // ... other params
        .includeContents(IncludeContents.NONE)
        .build();
```

### Planner

Supported in ADKPython v0.1.0

**`planner` (Optional):** Assign a `BasePlanner` instance to enable multi-step reasoning and planning before execution. There are two main planners:

- **`BuiltInPlanner`:** Leverages the model's built-in planning capabilities (e.g., Gemini's thinking feature). See [Gemini Thinking](https://ai.google.dev/gemini-api/docs/thinking) for details and examples.

  Here, the `thinking_budget` parameter guides the model on the number of thinking tokens to use when generating a response. The `include_thoughts` parameter controls whether the model should include its raw thoughts and internal reasoning process in the response.

  ```python
  from google.adk import Agent
  from google.adk.planners import BuiltInPlanner
  from google.genai import types

  my_agent = Agent(
      model="gemini-flash-latest",
      planner=BuiltInPlanner(
          thinking_config=types.ThinkingConfig(
              include_thoughts=True,
              thinking_budget=1024,
          )
      ),
      # ... your tools here
  )
  ```

- **`PlanReActPlanner`:** This planner instructs the model to follow a specific structure in its output: first create a plan, then execute actions (like calling tools), and provide reasoning for its steps. *It's particularly useful for models that don't have a built-in "thinking" feature*.

  ```python
  from google.adk import Agent
  from google.adk.planners import PlanReActPlanner

  my_agent = Agent(
      model="gemini-flash-latest",
      planner=PlanReActPlanner(),
      # ... your tools here
  )
  ```

  The agent's response will follow a structured format:

  ```text
  [user]: ai news
  [google_search_agent]: /*PLANNING*/
  1. Perform a Google search for "latest AI news" to get current updates and headlines related to artificial intelligence.
  2. Synthesize the information from the search results to provide a summary of recent AI news.

  /*ACTION*/
  /*REASONING*/
  The search results provide a comprehensive overview of recent AI news, covering various aspects like company developments, research breakthroughs, and applications. I have enough information to answer the user's request.

  /*FINAL_ANSWER*/
  Here's a summary of recent AI news:
  ....
  ```

Example for using built-in-planner:

```python
from dotenv import load_dotenv


import asyncio
import os

from google.genai import types
from google.adk.agents.llm_agent import LlmAgent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.adk.artifacts.in_memory_artifact_service import InMemoryArtifactService # Optional
from google.adk.planners import BasePlanner, BuiltInPlanner, PlanReActPlanner
from google.adk.models import LlmRequest

from google.genai.types import ThinkingConfig
from google.genai.types import GenerateContentConfig

import datetime
from zoneinfo import ZoneInfo

APP_NAME = "weather_app"
USER_ID = "1234"
SESSION_ID = "session1234"

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


def get_current_time(city: str) -> dict:
    """Returns the current time in a specified city.

    Args:
        city (str): The name of the city for which to retrieve the current time.

    Returns:
        dict: status and result or error msg.
    """

    if city.lower() == "new york":
        tz_identifier = "America/New_York"
    else:
        return {
            "status": "error",
            "error_message": (
                f"Sorry, I don't have timezone information for {city}."
            ),
        }

    tz = ZoneInfo(tz_identifier)
    now = datetime.datetime.now(tz)
    report = (
        f'The current time in {city} is {now.strftime("%Y-%m-%d %H:%M:%S %Z%z")}'
    )
    return {"status": "success", "report": report}

# Step 1: Create a ThinkingConfig
thinking_config = ThinkingConfig(
    include_thoughts=True,   # Ask the model to include its thoughts in the response
    thinking_budget=256      # Limit the 'thinking' to 256 tokens (adjust as needed)
)
print("ThinkingConfig:", thinking_config)

# Step 2: Instantiate BuiltInPlanner
planner = BuiltInPlanner(
    thinking_config=thinking_config
)
print("BuiltInPlanner created.")

# Step 3: Wrap the planner in an LlmAgent
agent = LlmAgent(
    model="gemini-2.5-pro-preview-03-25",  # Set your model name
    name="weather_and_time_agent",
    instruction="You are an agent that returns time and weather",
    planner=planner,
    tools=[get_weather, get_current_time]
)

# Session and Runner
session_service = InMemorySessionService()
session = session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID)
runner = Runner(agent=agent, app_name=APP_NAME, session_service=session_service)

# Agent Interaction
def call_agent(query):
    content = types.Content(role='user', parts=[types.Part(text=query)])
    events = runner.run(user_id=USER_ID, session_id=SESSION_ID, new_message=content)

    for event in events:
        print(f"\nDEBUG EVENT: {event}\n")
        if event.is_final_response() and event.content:
            final_answer = event.content.parts[0].text.strip()
            print("\n🟢 FINAL ANSWER\n", final_answer, "\n")

call_agent("If it's raining in New York right now, what is the current temperature?")
```

### Code Execution

Supported in ADKPython v0.1.0Java v0.1.0

- **`code_executor` (Optional):** Provide a `BaseCodeExecutor` instance to allow the agent to execute code blocks found in the LLM's response. For more information, see [Code Execution with Gemini API](/integrations/code-execution/).

````python
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

## Putting It Together: Example

Code

Here's the complete basic `capital_agent`:

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

# --- Full example code demonstrating LlmAgent with Tools vs. Output Schema ---
import json # Needed for pretty printing dicts
import asyncio 

from google.adk.agents import LlmAgent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types
from pydantic import BaseModel, Field

# --- 1. Define Constants ---
APP_NAME = "agent_comparison_app"
USER_ID = "test_user_456"
SESSION_ID_TOOL_AGENT = "session_tool_agent_xyz"
SESSION_ID_SCHEMA_AGENT = "session_schema_agent_xyz"
MODEL_NAME = "gemini-2.0-flash"

# --- 2. Define Schemas ---

# Input schema used by both agents
class CountryInput(BaseModel):
    country: str = Field(description="The country to get information about.")

# Output schema ONLY for the second agent
class CapitalInfoOutput(BaseModel):
    capital: str = Field(description="The capital city of the country.")
    # Note: Population is illustrative; the LLM will infer or estimate this
    # as it cannot use tools when output_schema is set.
    population_estimate: str = Field(description="An estimated population of the capital city.")

# --- 3. Define the Tool (Only for the first agent) ---
def get_capital_city(country: str) -> str:
    """Retrieves the capital city of a given country."""
    print(f"\n-- Tool Call: get_capital_city(country='{country}') --")
    country_capitals = {
        "united states": "Washington, D.C.",
        "canada": "Ottawa",
        "france": "Paris",
        "japan": "Tokyo",
    }
    result = country_capitals.get(country.lower(), f"Sorry, I couldn't find the capital for {country}.")
    print(f"-- Tool Result: '{result}' --")
    return result

# --- 4. Configure Agents ---

# Agent 1: Uses a tool and output_key
capital_agent_with_tool = LlmAgent(
    model=MODEL_NAME,
    name="capital_agent_tool",
    description="Retrieves the capital city using a specific tool.",
    instruction="""You are a helpful agent that provides the capital city of a country using a tool.
The user will provide the country name in a JSON format like {"country": "country_name"}.
1. Extract the country name.
2. Use the `get_capital_city` tool to find the capital.
3. Respond clearly to the user, stating the capital city found by the tool.
""",
    tools=[get_capital_city],
    input_schema=CountryInput,
    output_key="capital_tool_result", # Store final text response
)

# Agent 2: Uses output_schema (NO tools possible)
structured_info_agent_schema = LlmAgent(
    model=MODEL_NAME,
    name="structured_info_agent_schema",
    description="Provides capital and estimated population in a specific JSON format.",
    instruction=f"""You are an agent that provides country information.
The user will provide the country name in a JSON format like {{"country": "country_name"}}.
Respond ONLY with a JSON object matching this exact schema:
{json.dumps(CapitalInfoOutput.model_json_schema(), indent=2)}
Use your knowledge to determine the capital and estimate the population. Do not use any tools.
""",
    # *** NO tools parameter here - using output_schema prevents tool use ***
    input_schema=CountryInput,
    output_schema=CapitalInfoOutput, # Enforce JSON output structure
    output_key="structured_info_result", # Store final JSON response
)

# --- 5. Set up Session Management and Runners ---
session_service = InMemorySessionService()

# Create a runner for EACH agent
capital_runner = Runner(
    agent=capital_agent_with_tool,
    app_name=APP_NAME,
    session_service=session_service
)
structured_runner = Runner(
    agent=structured_info_agent_schema,
    app_name=APP_NAME,
    session_service=session_service
)

# --- 6. Define Agent Interaction Logic ---
async def call_agent_and_print(
    runner_instance: Runner,
    agent_instance: LlmAgent,
    session_id: str,
    query_json: str
):
    """Sends a query to the specified agent/runner and prints results."""
    print(f"\n>>> Calling Agent: '{agent_instance.name}' | Query: {query_json}")

    user_content = types.Content(role='user', parts=[types.Part(text=query_json)])

    final_response_content = "No final response received."
    async for event in runner_instance.run_async(user_id=USER_ID, session_id=session_id, new_message=user_content):
        # print(f"Event: {event.type}, Author: {event.author}") # Uncomment for detailed logging
        if event.is_final_response() and event.content and event.content.parts:
            # For output_schema, the content is the JSON string itself
            final_response_content = event.content.parts[0].text

    print(f"<<< Agent '{agent_instance.name}' Response: {final_response_content}")

    current_session = await session_service.get_session(app_name=APP_NAME,
                                                  user_id=USER_ID,
                                                  session_id=session_id)
    stored_output = current_session.state.get(agent_instance.output_key)

    # Pretty print if the stored output looks like JSON (likely from output_schema)
    print(f"--- Session State ['{agent_instance.output_key}']: ", end="")
    try:
        # Attempt to parse and pretty print if it's JSON
        parsed_output = json.loads(stored_output)
        print(json.dumps(parsed_output, indent=2))
    except (json.JSONDecodeError, TypeError):
         # Otherwise, print as string
        print(stored_output)
    print("-" * 30)


# --- 7. Run Interactions ---
async def main():
    # Create separate sessions for clarity, though not strictly necessary if context is managed
    print("--- Creating Sessions ---")
    await session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID_TOOL_AGENT)
    await session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID_SCHEMA_AGENT)

    print("--- Testing Agent with Tool ---")
    await call_agent_and_print(capital_runner, capital_agent_with_tool, SESSION_ID_TOOL_AGENT, '{"country": "France"}')
    await call_agent_and_print(capital_runner, capital_agent_with_tool, SESSION_ID_TOOL_AGENT, '{"country": "Canada"}')

    print("\n\n--- Testing Agent with Output Schema (No Tool Use) ---")
    await call_agent_and_print(structured_runner, structured_info_agent_schema, SESSION_ID_SCHEMA_AGENT, '{"country": "France"}')
    await call_agent_and_print(structured_runner, structured_info_agent_schema, SESSION_ID_SCHEMA_AGENT, '{"country": "Japan"}')

# --- Run the Agent ---
# Note: In Colab, you can directly use 'await' at the top level.
# If running this code as a standalone Python script, you'll need to use asyncio.run() or manage the event loop.
if __name__ == "__main__":
    asyncio.run(main())
```

```javascript
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

import { LlmAgent, FunctionTool, InMemoryRunner, isFinalResponse } from '@google/adk';
import { createUserContent, Schema, Type } from '@google/genai';
import type { Part } from '@google/genai';
 import { z } from 'zod';

// --- 1. Define Constants ---
const APP_NAME = "capital_app_ts";
const USER_ID = "test_user_789";
const SESSION_ID_TOOL_AGENT = "session_tool_agent_ts";
const SESSION_ID_SCHEMA_AGENT = "session_schema_agent_ts";
const MODEL_NAME = "gemini-2.5-flash"; // Using flash for speed

// --- 2. Define Schemas ---

// A. Schema for the Tool's parameters (using Zod)
const CountryInput = z.object({
    country: z.string().describe('The country to get the capital for.'),
});

// B. Output schema ONLY for the second agent (using ADK's Schema type)
const CapitalInfoOutputSchema: Schema = {
    type: Type.OBJECT,
    description: "Schema for capital city information.",
    properties: {
        capital: {
            type: Type.STRING,
            description: "The capital city of the country."
        },
        population_estimate: {
            type: Type.STRING,
            description: "An estimated population of the capital city."
        },
    },
    required: ["capital", "population_estimate"],
};


// --- 3. Define the Tool (Only for the first agent) ---
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
    return { result: result }; // Tools must return an object
}

// --- 4. Configure Agents ---

// Agent 1: Uses a tool and outputKey
const getCapitalCityTool = new FunctionTool({
    name: 'get_capital_city',
    description: 'Retrieves the capital city for a given country',
    parameters: CountryInput,
    execute: getCapitalCity,
});

const capitalAgentWithTool = new LlmAgent({
    model: MODEL_NAME,
    name: 'capital_agent_tool',
    description: 'Retrieves the capital city using a specific tool.',
    instruction: `You are a helpful agent that provides the capital city of a country using a tool.
The user will provide the country name in a JSON format like {"country": "country_name"}.
1. Extract the country name.
2. Use the \`get_capital_city\` tool to find the capital.
3. Respond with a JSON object with the key 'capital' and the value as the capital city.
`,
    tools: [getCapitalCityTool],
    outputKey: "capital_tool_result", // Store final text response
});

// Agent 2: Uses outputSchema (NO tools possible)
const structuredInfoAgentSchema = new LlmAgent({
    model: MODEL_NAME,
    name: 'structured_info_agent_schema',
    description: 'Provides capital and estimated population in a specific JSON format.',
    instruction: `You are an agent that provides country information.
The user will provide the country name in a JSON format like {"country": "country_name"}.
Respond ONLY with a JSON object matching this exact schema:
${JSON.stringify(CapitalInfoOutputSchema, null, 2)}
Use your knowledge to determine the capital and estimate the population. Do not use any tools.
`,
    // *** NO tools parameter here - using outputSchema prevents tool use ***
    outputSchema: CapitalInfoOutputSchema,
    outputKey: "structured_info_result",
});


// --- 5. Define Agent Interaction Logic ---
async function callAgentAndPrint(
    runner: InMemoryRunner,
    agent: LlmAgent,
    sessionId: string,
    queryJson: string
) {
    console.log(`\n>>> Calling Agent: '${agent.name}' | Query: ${queryJson}`);
    const message = createUserContent(queryJson);

    let finalResponseContent = "No final response received.";
    for await (const event of runner.runAsync({ userId: USER_ID, sessionId: sessionId, newMessage: message })) {
        if (isFinalResponse(event) && event.content?.parts?.length) {
            finalResponseContent = event.content.parts.map((part: Part) => part.text ?? '').join('');
        }
    }
    console.log(`<<< Agent '${agent.name}' Response: ${finalResponseContent}`);

    // Check the session state
    const currentSession = await runner.sessionService.getSession({ appName: APP_NAME, userId: USER_ID, sessionId: sessionId });
    if (!currentSession) {
        console.log(`--- Session not found: ${sessionId} ---`);
        return;
    }
    const storedOutput = currentSession.state[agent.outputKey!];

    console.log(`--- Session State ['${agent.outputKey}']: `);
    try {
        // Attempt to parse and pretty print if it's JSON
        const parsedOutput = JSON.parse(storedOutput as string);
        console.log(JSON.stringify(parsedOutput, null, 2));
    } catch (e) {
        // Otherwise, print as a string
        console.log(storedOutput);
    }
    console.log("-".repeat(30));
}

// --- 6. Run Interactions ---
async function main() {
    // Set up runners for each agent
    const capitalRunner = new InMemoryRunner({ appName: APP_NAME, agent: capitalAgentWithTool });
    const structuredRunner = new InMemoryRunner({ appName: APP_NAME, agent: structuredInfoAgentSchema });

    // Create sessions
    console.log("--- Creating Sessions ---");
    await capitalRunner.sessionService.createSession({ appName: APP_NAME, userId: USER_ID, sessionId: SESSION_ID_TOOL_AGENT });
    await structuredRunner.sessionService.createSession({ appName: APP_NAME, userId: USER_ID, sessionId: SESSION_ID_SCHEMA_AGENT });

    console.log("\n--- Testing Agent with Tool ---");
    await callAgentAndPrint(capitalRunner, capitalAgentWithTool, SESSION_ID_TOOL_AGENT, '{"country": "France"}');
    await callAgentAndPrint(capitalRunner, capitalAgentWithTool, SESSION_ID_TOOL_AGENT, '{"country": "Canada"}');

    console.log("\n\n--- Testing Agent with Output Schema (No Tool Use) ---");
    await callAgentAndPrint(structuredRunner, structuredInfoAgentSchema, SESSION_ID_SCHEMA_AGENT, '{"country": "France"}');
    await callAgentAndPrint(structuredRunner, structuredInfoAgentSchema, SESSION_ID_SCHEMA_AGENT, '{"country": "Japan"}');
}

main();
```

```go
package main

import (
    "context"
    "encoding/json"
    "errors"
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

// --- Main Runnable Example ---

const (
    modelName = "gemini-2.0-flash"
    appName   = "agent_comparison_app"
    userID    = "test_user_456"
)

type getCapitalCityArgs struct {
    Country string `json:"country" jsonschema:"The country to get the capital of."`
}

// getCapitalCity retrieves the capital city of a given country.
func getCapitalCity(ctx tool.Context, args getCapitalCityArgs) (map[string]any, error) {
    fmt.Printf("\n-- Tool Call: getCapitalCity(country='%s') --\n", args.Country)
    capitals := map[string]string{
        "united states": "Washington, D.C.",
        "canada":        "Ottawa",
        "france":        "Paris",
        "japan":         "Tokyo",
    }
    capital, ok := capitals[strings.ToLower(args.Country)]
    if !ok {
        result := fmt.Sprintf("Sorry, I couldn't find the capital for %s.", args.Country)
        fmt.Printf("-- Tool Result: '%s' --\n", result)
        return nil, errors.New(result)
    }
    fmt.Printf("-- Tool Result: '%s' --\n", capital)
    return map[string]any{"result": capital}, nil
}

// callAgent is a helper function to execute an agent with a given prompt and handle its output.
func callAgent(ctx context.Context, a agent.Agent, outputKey string, prompt string) {
    fmt.Printf("\n>>> Calling Agent: '%s' | Query: %s\n", a.Name(), prompt)
    // Create an in-memory session service to manage agent state.
    sessionService := session.InMemoryService()

    // Create a new session for the agent interaction.
    sessionCreateResponse, err := sessionService.Create(ctx, &session.CreateRequest{
        AppName: appName,
        UserID:  userID,
    })
    if err != nil {
        log.Fatalf("Failed to create the session service: %v", err)
    }

    session := sessionCreateResponse.Session

    // Configure the runner with the application name, agent, and session service.
    config := runner.Config{
        AppName:        appName,
        Agent:          a,
        SessionService: sessionService,
    }

    // Create a new runner instance.
    r, err := runner.New(config)
    if err != nil {
        log.Fatalf("Failed to create the runner: %v", err)
    }

    // Prepare the user's message to send to the agent.
    sessionID := session.ID()
    userMsg := &genai.Content{
        Parts: []*genai.Part{
            genai.NewPartFromText(prompt),
        },
        Role: string(genai.RoleUser),
    }

    // Run the agent and process the streaming events.
    for event, err := range r.Run(ctx, userID, sessionID, userMsg, agent.RunConfig{
        StreamingMode: agent.StreamingModeSSE,
    }) {
        if err != nil {
            fmt.Printf("\nAGENT_ERROR: %v\n", err)
        } else if event.Partial {
            // Print partial responses as they are received.
            for _, p := range event.Content.Parts {
                fmt.Print(p.Text)
            }
        }
    }

    // After the run, check if there's an expected output key in the session state.
    if outputKey != "" {
        storedOutput, error := session.State().Get(outputKey)
        if error == nil {
            // Pretty-print the stored output if it's a JSON string.
            fmt.Printf("\n--- Session State ['%s']: ", outputKey)
            storedString, isString := storedOutput.(string)
            if isString {
                var prettyJSON map[string]interface{}
                if err := json.Unmarshal([]byte(storedString), &prettyJSON); err == nil {
                    indentedJSON, err := json.MarshalIndent(prettyJSON, "", "  ")
                    if err == nil {
                        fmt.Println(string(indentedJSON))
                    } else {
                        fmt.Println(storedString)
                    }
                } else {
                    fmt.Println(storedString)
                }
            } else {
                fmt.Println(storedOutput)
            }
            fmt.Println(strings.Repeat("-", 30))
        }
    }
}

func main() {
    ctx := context.Background()

    model, err := gemini.NewModel(ctx, modelName, &genai.ClientConfig{})
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

    countryInputSchema := &genai.Schema{
        Type:        genai.TypeObject,
        Description: "Input for specifying a country.",
        Properties: map[string]*genai.Schema{
            "country": {
                Type:        genai.TypeString,
                Description: "The country to get information about.",
            },
        },
        Required: []string{"country"},
    }

    capitalAgentWithTool, err := llmagent.New(llmagent.Config{
        Name:        "capital_agent_tool",
        Model:       model,
        Description: "Retrieves the capital city using a specific tool.",
        Instruction: `You are a helpful agent that provides the capital city of a country using a tool.
The user will provide the country name in a JSON format like {"country": "country_name"}.
1. Extract the country name.
2. Use the 'get_capital_city' tool to find the capital.
3. Respond clearly to the user, stating the capital city found by the tool.`,
        Tools:       []tool.Tool{capitalTool},
        InputSchema: countryInputSchema,
        OutputKey:   "capital_tool_result",
    })
    if err != nil {
        log.Fatalf("Failed to create capital agent with tool: %v", err)
    }

    capitalInfoOutputSchema := &genai.Schema{
        Type:        genai.TypeObject,
        Description: "Schema for capital city information.",
        Properties: map[string]*genai.Schema{
            "capital": {
                Type:        genai.TypeString,
                Description: "The capital city of the country.",
            },
            "population_estimate": {
                Type:        genai.TypeString,
                Description: "An estimated population of the capital city.",
            },
        },
        Required: []string{"capital", "population_estimate"},
    }
    schemaJSON, _ := json.Marshal(capitalInfoOutputSchema)
    structuredInfoAgentSchema, err := llmagent.New(llmagent.Config{
        Name:        "structured_info_agent_schema",
        Model:       model,
        Description: "Provides capital and estimated population in a specific JSON format.",
        Instruction: fmt.Sprintf(`You are an agent that provides country information.
The user will provide the country name in a JSON format like {"country": "country_name"}.
Respond ONLY with a JSON object matching this exact schema:
%s
Use your knowledge to determine the capital and estimate the population. Do not use any tools.`, string(schemaJSON)),
        InputSchema:  countryInputSchema,
        OutputSchema: capitalInfoOutputSchema,
        OutputKey:    "structured_info_result",
    })
    if err != nil {
        log.Fatalf("Failed to create structured info agent: %v", err)
    }

    fmt.Println("--- Testing Agent with Tool ---")
    callAgent(ctx, capitalAgentWithTool, "capital_tool_result", `{"country": "France"}`)
    callAgent(ctx, capitalAgentWithTool, "capital_tool_result", `{"country": "Canada"}`)

    fmt.Println("\n\n--- Testing Agent with Output Schema (No Tool Use) ---")
    callAgent(ctx, structuredInfoAgentSchema, "structured_info_result", `{"country": "France"}`)
    callAgent(ctx, structuredInfoAgentSchema, "structured_info_result", `{"country": "Japan"}`)
}
```

```java
// --- Full example code demonstrating LlmAgent with Tools vs. Output Schema ---

import com.google.adk.agents.LlmAgent;
import com.google.adk.events.Event;
import com.google.adk.runner.Runner;
import com.google.adk.sessions.InMemorySessionService;
import com.google.adk.sessions.Session;
import com.google.adk.tools.Annotations;
import com.google.adk.tools.FunctionTool;
import com.google.genai.types.Content;
import com.google.genai.types.Part;
import com.google.genai.types.Schema;
import io.reactivex.rxjava3.core.Flowable;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

public class LlmAgentExample {

  // --- 1. Define Constants ---
  private static final String MODEL_NAME = "gemini-2.0-flash";
  private static final String APP_NAME = "capital_agent_tool";
  private static final String USER_ID = "test_user_456";
  private static final String SESSION_ID_TOOL_AGENT = "session_tool_agent_xyz";
  private static final String SESSION_ID_SCHEMA_AGENT = "session_schema_agent_xyz";

  // --- 2. Define Schemas ---

  // Input schema used by both agents
  private static final Schema COUNTRY_INPUT_SCHEMA =
      Schema.builder()
          .type("OBJECT")
          .description("Input for specifying a country.")
          .properties(
              Map.of(
                  "country",
                  Schema.builder()
                      .type("STRING")
                      .description("The country to get information about.")
                      .build()))
          .required(List.of("country"))
          .build();

  // Output schema ONLY for the second agent
  private static final Schema CAPITAL_INFO_OUTPUT_SCHEMA =
      Schema.builder()
          .type("OBJECT")
          .description("Schema for capital city information.")
          .properties(
              Map.of(
                  "capital",
                  Schema.builder()
                      .type("STRING")
                      .description("The capital city of the country.")
                      .build(),
                  "population_estimate",
                  Schema.builder()
                      .type("STRING")
                      .description("An estimated population of the capital city.")
                      .build()))
          .required(List.of("capital", "population_estimate"))
          .build();

  // --- 3. Define the Tool (Only for the first agent) ---
  // Retrieves the capital city of a given country.
  public static Map<String, Object> getCapitalCity(
      @Annotations.Schema(name = "country", description = "The country to get capital for")
      String country) {
    System.out.printf("%n-- Tool Call: getCapitalCity(country='%s') --%n", country);
    Map<String, String> countryCapitals = new HashMap<>();
    countryCapitals.put("united states", "Washington, D.C.");
    countryCapitals.put("canada", "Ottawa");
    countryCapitals.put("france", "Paris");
    countryCapitals.put("japan", "Tokyo");

    String result =
        countryCapitals.getOrDefault(
            country.toLowerCase(), "Sorry, I couldn't find the capital for " + country + ".");
    System.out.printf("-- Tool Result: '%s' --%n", result);
    return Map.of("result", result); // Tools must return a Map
  }

  public static void main(String[] args){
    LlmAgentExample agentExample = new LlmAgentExample();
    FunctionTool capitalTool = FunctionTool.create(agentExample.getClass(), "getCapitalCity");

    // --- 4. Configure Agents ---

    // Agent 1: Uses a tool and output_key
    LlmAgent capitalAgentWithTool =
        LlmAgent.builder()
            .model(MODEL_NAME)
            .name("capital_agent_tool")
            .description("Retrieves the capital city using a specific tool.")
            .instruction(
              """
              You are a helpful agent that provides the capital city of a country using a tool.
              1. Extract the country name.
              2. Use the `get_capital_city` tool to find the capital.
              3. Respond clearly to the user, stating the capital city found by the tool.
              """)
            .tools(capitalTool)
            .inputSchema(COUNTRY_INPUT_SCHEMA)
            .outputKey("capital_tool_result") // Store final text response
            .build();

    // Agent 2: Uses an output schema
    LlmAgent structuredInfoAgentSchema =
        LlmAgent.builder()
            .model(MODEL_NAME)
            .name("structured_info_agent_schema")
            .description("Provides capital and estimated population in a specific JSON format.")
            .instruction(
                String.format("""
                You are an agent that provides country information.
                Respond ONLY with a JSON object matching this exact schema: %s
                Use your knowledge to determine the capital and estimate the population. Do not use any tools.
                """, CAPITAL_INFO_OUTPUT_SCHEMA.toJson()))
            // *** NO tools parameter here - using output_schema prevents tool use ***
            .inputSchema(COUNTRY_INPUT_SCHEMA)
            .outputSchema(CAPITAL_INFO_OUTPUT_SCHEMA) // Enforce JSON output structure
            .outputKey("structured_info_result") // Store final JSON response
            .build();

    // --- 5. Set up Session Management and Runners ---
    InMemorySessionService sessionService = new InMemorySessionService();

    sessionService.createSession(APP_NAME, USER_ID, null, SESSION_ID_TOOL_AGENT).blockingGet();
    sessionService.createSession(APP_NAME, USER_ID, null, SESSION_ID_SCHEMA_AGENT).blockingGet();

    Runner capitalRunner = new Runner(capitalAgentWithTool, APP_NAME, null, sessionService);
    Runner structuredRunner = new Runner(structuredInfoAgentSchema, APP_NAME, null, sessionService);

    // --- 6. Run Interactions ---
    System.out.println("--- Testing Agent with Tool ---");
    agentExample.callAgentAndPrint(
        capitalRunner, capitalAgentWithTool, SESSION_ID_TOOL_AGENT, "{\"country\": \"France\"}");
    agentExample.callAgentAndPrint(
        capitalRunner, capitalAgentWithTool, SESSION_ID_TOOL_AGENT, "{\"country\": \"Canada\"}");

    System.out.println("\n\n--- Testing Agent with Output Schema (No Tool Use) ---");
    agentExample.callAgentAndPrint(
        structuredRunner,
        structuredInfoAgentSchema,
        SESSION_ID_SCHEMA_AGENT,
        "{\"country\": \"France\"}");
    agentExample.callAgentAndPrint(
        structuredRunner,
        structuredInfoAgentSchema,
        SESSION_ID_SCHEMA_AGENT,
        "{\"country\": \"Japan\"}");
  }

  // --- 7. Define Agent Interaction Logic ---
  public void callAgentAndPrint(Runner runner, LlmAgent agent, String sessionId, String queryJson) {
    System.out.printf(
        "%n>>> Calling Agent: '%s' | Session: '%s' | Query: %s%n",
        agent.name(), sessionId, queryJson);

    Content userContent = Content.fromParts(Part.fromText(queryJson));
    final String[] finalResponseContent = {"No final response received."};
    Flowable<Event> eventStream = runner.runAsync(USER_ID, sessionId, userContent);

    // Stream event response
    eventStream.blockingForEach(event -> {
          if (event.finalResponse() && event.content().isPresent()) {
            event
                .content()
                .get()
                .parts()
                .flatMap(parts -> parts.isEmpty() ? Optional.empty() : Optional.of(parts.get(0)))
                .flatMap(Part::text)
                .ifPresent(text -> finalResponseContent[0] = text);
          }
        });

    System.out.printf("<<< Agent '%s' Response: %s%n", agent.name(), finalResponseContent[0]);

    // Retrieve the session again to get the updated state
    Session updatedSession =
        runner
            .sessionService()
            .getSession(APP_NAME, USER_ID, sessionId, Optional.empty())
            .blockingGet();

    if (updatedSession != null && agent.outputKey().isPresent()) {
      // Print to verify if the stored output looks like JSON (likely from output_schema)
      System.out.printf("--- Session State ['%s']: ", agent.outputKey().get());
      }
  }
}
```

*(This example demonstrates the core concepts. More complex agents might incorporate schemas, context control, planning, etc.)*

## Related Concepts (Deferred Topics)

While this page covers the core configuration of `LlmAgent`, several related concepts provide more advanced control and are detailed elsewhere:

- **Callbacks:** Intercepting execution points (before/after model calls, before/after tool calls) using `before_model_callback`, `after_model_callback`, etc. See [Callbacks](https://adk.dev/callbacks/types-of-callbacks/index.md).
- **Multi-Agent Control:** Advanced strategies for agent interaction, including planning (`planner`), controlling agent transfer (`disallow_transfer_to_parent`, `disallow_transfer_to_peers`), and system-wide instructions (`global_instruction`). See [Multi-Agents](https://adk.dev/agents/multi-agents/index.md).

# Multi-Agent Systems in ADK

Supported in ADKPython v0.1.0Typescript v0.2.0Go v0.1.0Java v0.1.0

As agentic applications grow in complexity, structuring them as a single, monolithic agent can become challenging to develop, maintain, and reason about. The Agent Development Kit (ADK) supports building sophisticated applications by composing multiple, distinct `BaseAgent` instances into a **Multi-Agent System (MAS)**.

In ADK, a multi-agent system is an application where different agents, often forming a hierarchy, collaborate or coordinate to achieve a larger goal. Structuring your application this way offers significant advantages, including enhanced modularity, specialization, reusability, maintainability, and the ability to define structured control flows using dedicated workflow agents.

You can compose various types of agents derived from `BaseAgent` to build these systems:

- **LLM Agents:** Agents powered by large language models. (See [LLM Agents](https://adk.dev/agents/llm-agents/index.md))
- **Workflow Agents:** Specialized agents (`SequentialAgent`, `ParallelAgent`, `LoopAgent`) designed to manage the execution flow of their sub-agents. (See [Workflow Agents](https://adk.dev/agents/workflow-agents/index.md))
- **Custom agents:** Your own agents inheriting from `BaseAgent` with specialized, non-LLM logic. (See [Custom Agents](https://adk.dev/agents/custom-agents/index.md))

The following sections detail the core ADK primitives—such as agent hierarchy, workflow agents, and interaction mechanisms—that enable you to construct and manage these multi-agent systems effectively.

## 1. ADK Primitives for Agent Composition

ADK provides core building blocks—primitives—that enable you to structure and manage interactions within your multi-agent system.

Note

The specific parameters or method names for the primitives may vary slightly by SDK language (e.g., `sub_agents` in Python, `subAgents` in Java). Refer to the language-specific API documentation for details.

### 1.1. Agent Hierarchy (Parent agent, Sub Agents)

The foundation for structuring multi-agent systems is the parent-child relationship defined in `BaseAgent`.

- **Establishing Hierarchy:** You create a tree structure by passing a list of agent instances to the `sub_agents` argument when initializing a parent agent. ADK automatically sets the `parent_agent` attribute on each child agent during initialization.
- **Single Parent Rule:** An agent instance can only be added as a sub-agent once. Attempting to assign a second parent will result in a `ValueError`.
- **Importance:** This hierarchy defines the scope for [Workflow Agents](#workflow-agents-as-orchestrators) and influences the potential targets for LLM-Driven Delegation. You can navigate the hierarchy using `agent.parent_agent` or find descendants using `agent.find_agent(name)`.

```python
# Conceptual Example: Defining Hierarchy
from google.adk.agents import LlmAgent, BaseAgent


# Define individual agents
greeter = LlmAgent(name="Greeter", model="gemini-flash-latest")
task_doer = BaseAgent(name="TaskExecutor") # Custom non-LLM agent


# Create parent agent and assign children via sub_agents
coordinator = LlmAgent(
    name="Coordinator",
    model="gemini-flash-latest",
    description="I coordinate greetings and tasks.",
    sub_agents=[ # Assign sub_agents here
        greeter,
        task_doer
    ]
)


# Framework automatically sets:
# assert greeter.parent_agent == coordinator
# assert task_doer.parent_agent == coordinator
```

```typescript
// Conceptual Example: Defining Hierarchy
import { LlmAgent, BaseAgent, InvocationContext } from '@google/adk';
import type { Event, createEventActions } from '@google/adk';

class TaskExecutorAgent extends BaseAgent {
  async *runAsyncImpl(context: InvocationContext): AsyncGenerator<Event, void, void> {
    yield {
      id: 'event-1',
      invocationId: context.invocationId,
      author: this.name,
      content: { parts: [{ text: 'Task completed!' }] },
      actions: createEventActions(),
      timestamp: Date.now(),
    };
  }
  async *runLiveImpl(context: InvocationContext): AsyncGenerator<Event, void, void> {
    this.runAsyncImpl(context);
  }
}

// Define individual agents
const greeter = new LlmAgent({name: 'Greeter', model: 'gemini-flash-latest'});
const taskDoer = new TaskExecutorAgent({name: 'TaskExecutor'}); // Custom non-LLM agent

// Create parent agent and assign children via subAgents
const coordinator = new LlmAgent({
    name: 'Coordinator',
    model: 'gemini-flash-latest',
    description: 'I coordinate greetings and tasks.',
    subAgents: [ // Assign subAgents here
        greeter,
        taskDoer
    ],
});

// Framework automatically sets:
// console.assert(greeter.parentAgent === coordinator);
// console.assert(taskDoer.parentAgent === coordinator);
```

```go
import (
    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
)

// Conceptual Example: Defining Hierarchy
// Define individual agents
greeter, _ := llmagent.New(llmagent.Config{Name: "Greeter", Model: m})
taskDoer, _ := agent.New(agent.Config{Name: "TaskExecutor"}) // Custom non-LLM agent

// Create parent agent and assign children via sub_agents
coordinator, _ := llmagent.New(llmagent.Config{
    Name:        "Coordinator",
    Model:       m,
    Description: "I coordinate greetings and tasks.",
    SubAgents:   []agent.Agent{greeter, taskDoer}, // Assign sub_agents here
})
```

```java
// Conceptual Example: Defining Hierarchy
import com.google.adk.agents.SequentialAgent;
import com.google.adk.agents.LlmAgent;


// Define individual agents
LlmAgent greeter = LlmAgent.builder().name("Greeter").model("gemini-flash-latest").build();
SequentialAgent taskDoer = SequentialAgent.builder().name("TaskExecutor").subAgents(...).build(); // Sequential Agent


// Create parent agent and assign sub_agents
LlmAgent coordinator = LlmAgent.builder()
    .name("Coordinator")
    .model("gemini-flash-latest")
    .description("I coordinate greetings and tasks")
    .subAgents(greeter, taskDoer) // Assign sub_agents here
    .build();


// Framework automatically sets:
// assert greeter.parentAgent().equals(coordinator);
// assert taskDoer.parentAgent().equals(coordinator);
```

### 1.2. Workflow Agents as Orchestrators

ADK includes specialized agents derived from `BaseAgent` that don't perform tasks themselves but orchestrate the execution flow of their `sub_agents`.

- **[`SequentialAgent`](https://adk.dev/agents/workflow-agents/sequential-agents/index.md):** Executes its `sub_agents` one after another in the order they are listed.
  - **Context:** Passes the *same* [`InvocationContext`](https://adk.dev/runtime/index.md) sequentially, allowing agents to easily pass results via shared state.

```python
# Conceptual Example: Sequential Pipeline
from google.adk.agents import SequentialAgent, LlmAgent

step1 = LlmAgent(name="Step1_Fetch", output_key="data") # Saves output to state['data']
step2 = LlmAgent(name="Step2_Process", instruction="Process data from {data}.")

pipeline = SequentialAgent(name="MyPipeline", sub_agents=[step1, step2])
# When pipeline runs, Step2 can access the state['data'] set by Step1.
```

```typescript
// Conceptual Example: Sequential Pipeline
import { SequentialAgent, LlmAgent } from '@google/adk';

const step1 = new LlmAgent({name: 'Step1_Fetch', outputKey: 'data'}); // Saves output to state['data']
const step2 = new LlmAgent({name: 'Step2_Process', instruction: 'Process data from {data}.'});

const pipeline = new SequentialAgent({name: 'MyPipeline', subAgents: [step1, step2]});
// When pipeline runs, Step2 can access the state['data'] set by Step1.
```

```go
import (
    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/agent/workflowagents/sequentialagent"
)

// Conceptual Example: Sequential Pipeline
step1, _ := llmagent.New(llmagent.Config{Name: "Step1_Fetch", OutputKey: "data", Model: m}) // Saves output to state["data"]
step2, _ := llmagent.New(llmagent.Config{Name: "Step2_Process", Instruction: "Process data from {data}.", Model: m})

pipeline, _ := sequentialagent.New(sequentialagent.Config{
    AgentConfig: agent.Config{Name: "MyPipeline", SubAgents: []agent.Agent{step1, step2}},
})
// When pipeline runs, Step2 can access the state["data"] set by Step1.
```

```java
// Conceptual Example: Sequential Pipeline
import com.google.adk.agents.SequentialAgent;
import com.google.adk.agents.LlmAgent;

LlmAgent step1 = LlmAgent.builder().name("Step1_Fetch").outputKey("data").build(); // Saves output to state.get("data")
LlmAgent step2 = LlmAgent.builder().name("Step2_Process").instruction("Process data from {data}.").build();

SequentialAgent pipeline = SequentialAgent.builder().name("MyPipeline").subAgents(step1, step2).build();
// When pipeline runs, Step2 can access the state.get("data") set by Step1.
```

- **[`ParallelAgent`](https://adk.dev/agents/workflow-agents/parallel-agents/index.md):** Executes its `sub_agents` in parallel. Events from sub-agents may be interleaved.
  - **Context:** Modifies the `InvocationContext.branch` for each child agent (e.g., `ParentBranch.ChildName`), providing a distinct contextual path which can be useful for isolating history in some memory implementations.
  - **State:** Despite different branches, all parallel children access the *same shared* `session.state`, enabling them to read initial state and write results (use distinct keys to avoid race conditions).

```python
# Conceptual Example: Parallel Execution
from google.adk.agents import ParallelAgent, LlmAgent

fetch_weather = LlmAgent(name="WeatherFetcher", output_key="weather")
fetch_news = LlmAgent(name="NewsFetcher", output_key="news")

gatherer = ParallelAgent(name="InfoGatherer", sub_agents=[fetch_weather, fetch_news])
# When gatherer runs, WeatherFetcher and NewsFetcher run concurrently.
# A subsequent agent could read state['weather'] and state['news'].
```

```typescript
// Conceptual Example: Parallel Execution
import { ParallelAgent, LlmAgent } from '@google/adk';

const fetchWeather = new LlmAgent({name: 'WeatherFetcher', outputKey: 'weather'});
const fetchNews = new LlmAgent({name: 'NewsFetcher', outputKey: 'news'});

const gatherer = new ParallelAgent({name: 'InfoGatherer', subAgents: [fetchWeather, fetchNews]});
// When gatherer runs, WeatherFetcher and NewsFetcher run concurrently.
// A subsequent agent could read state['weather'] and state['news'].
```

```go
import (
    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/agent/workflowagents/parallelagent"
)

// Conceptual Example: Parallel Execution
fetchWeather, _ := llmagent.New(llmagent.Config{Name: "WeatherFetcher", OutputKey: "weather", Model: m})
fetchNews, _ := llmagent.New(llmagent.Config{Name: "NewsFetcher", OutputKey: "news", Model: m})

gatherer, _ := parallelagent.New(parallelagent.Config{
    AgentConfig: agent.Config{Name: "InfoGatherer", SubAgents: []agent.Agent{fetchWeather, fetchNews}},
})
// When gatherer runs, WeatherFetcher and NewsFetcher run concurrently.
// A subsequent agent could read state["weather"] and state["news"].
```

```java
// Conceptual Example: Parallel Execution
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.ParallelAgent;


LlmAgent fetchWeather = LlmAgent.builder()
    .name("WeatherFetcher")
    .outputKey("weather")
    .build();


LlmAgent fetchNews = LlmAgent.builder()
    .name("NewsFetcher")
    .instruction("news")
    .build();


ParallelAgent gatherer = ParallelAgent.builder()
    .name("InfoGatherer")
    .subAgents(fetchWeather, fetchNews)
    .build();


// When gatherer runs, WeatherFetcher and NewsFetcher run concurrently.
// A subsequent agent could read state['weather'] and state['news'].
```

- **[`LoopAgent`](https://adk.dev/agents/workflow-agents/loop-agents/index.md):** Executes its `sub_agents` sequentially in a loop.
  - **Termination:** The loop stops if the optional `max_iterations` is reached, or if any sub-agent returns an [`Event`](https://adk.dev/events/index.md) with `escalate=True` in its Event Actions.
  - **Context & State:** Passes the *same* `InvocationContext` in each iteration, allowing state changes (e.g., counters, flags) to persist across loops.

```python
# Conceptual Example: Loop with Condition
from google.adk.agents import LoopAgent, LlmAgent, BaseAgent
from google.adk.events import Event, EventActions
from google.adk.agents.invocation_context import InvocationContext
from typing import AsyncGenerator

class CheckCondition(BaseAgent): # Custom agent to check state
    async def _run_async_impl(self, ctx: InvocationContext) -> AsyncGenerator[Event, None]:
        status = ctx.session.state.get("status", "pending")
        is_done = (status == "completed")
        yield Event(author=self.name, actions=EventActions(escalate=is_done)) # Escalate if done

process_step = LlmAgent(name="ProcessingStep") # Agent that might update state['status']

poller = LoopAgent(
    name="StatusPoller",
    max_iterations=10,
    sub_agents=[process_step, CheckCondition(name="Checker")]
)
# When poller runs, it executes process_step then Checker repeatedly
# until Checker escalates (state['status'] == 'completed') or 10 iterations pass.
```

```typescript
// Conceptual Example: Loop with Condition
import { LoopAgent, LlmAgent, BaseAgent, InvocationContext } from '@google/adk';
import type { Event, createEventActions, EventActions } from '@google/adk';

class CheckConditionAgent extends BaseAgent { // Custom agent to check state
    async *runAsyncImpl(ctx: InvocationContext): AsyncGenerator<Event> {
        const status = ctx.session.state['status'] || 'pending';
        const isDone = status === 'completed';
        yield createEvent({ author: 'check_condition', actions: createEventActions({ escalate: isDone }) });
    }

    async *runLiveImpl(ctx: InvocationContext): AsyncGenerator<Event> {
        // This is not implemented.
    }
};

const processStep = new LlmAgent({name: 'ProcessingStep'}); // Agent that might update state['status']

const poller = new LoopAgent({
    name: 'StatusPoller',
    maxIterations: 10,
    // Executes its sub_agents sequentially in a loop
    subAgents: [processStep, new CheckConditionAgent ({name: 'Checker'})]
});
// When poller runs, it executes processStep then Checker repeatedly
// until Checker escalates (state['status'] === 'completed') or 10 iterations pass.
```

```go
import (
    "iter"
    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/agent/workflowagents/loopagent"
    "google.golang.org/adk/session"
)

// Conceptual Example: Loop with Condition
// Custom agent to check state
checkCondition, _ := agent.New(agent.Config{
    Name: "Checker",
    Run: func(ctx agent.InvocationContext) iter.Seq2[*session.Event, error] {
        return func(yield func(*session.Event, error) bool) {
            status, err := ctx.Session().State().Get("status")
            // If "status" is not in the state, default to "pending".
            // This is idiomatic Go for handling a potential error on lookup.
            if err != nil {
                status = "pending"
            }
            isDone := status == "completed"
            yield(&session.Event{Author: "Checker", Actions: session.EventActions{Escalate: isDone}}, nil)
        }
    },
})

processStep, _ := llmagent.New(llmagent.Config{Name: "ProcessingStep", Model: m}) // Agent that might update state["status"]

poller, _ := loopagent.New(loopagent.Config{
    MaxIterations: 10,
    AgentConfig:   agent.Config{Name: "StatusPoller", SubAgents: []agent.Agent{processStep, checkCondition}},
})
// When poller runs, it executes processStep then Checker repeatedly
// until Checker escalates (state["status"] == "completed") or 10 iterations pass.
```

````

```java
// Conceptual Example: Loop with Condition
// Custom agent to check state and potentially escalate
public static class CheckConditionAgent extends BaseAgent {
  public CheckConditionAgent(String name, String description) {
    super(name, description, List.of(), null, null);
  }


  @Override
  protected Flowable<Event> runAsyncImpl(InvocationContext ctx) {
    String status = (String) ctx.session().state().getOrDefault("status", "pending");
    boolean isDone = "completed".equalsIgnoreCase(status);

    // Emit an event that signals to escalate (exit the loop) if the condition is met.
    // If not done, the escalate flag will be false or absent, and the loop continues.
    Event checkEvent = Event.builder()
            .author(name())
            .id(Event.generateEventId()) // Important to give events unique IDs
            .actions(EventActions.builder().escalate(isDone).build()) // Escalate if done
            .build();
    return Flowable.just(checkEvent);
  }
}


// Agent that might update state.put("status")
LlmAgent processingStepAgent = LlmAgent.builder().name("ProcessingStep").build();
// Custom agent instance for checking the condition
CheckConditionAgent conditionCheckerAgent = new CheckConditionAgent(
    "ConditionChecker",
    "Checks if the status is 'completed'."
);
LoopAgent poller = LoopAgent.builder().name("StatusPoller").maxIterations(10).subAgents(processingStepAgent, conditionCheckerAgent).build();
// When poller runs, it executes processingStepAgent then conditionCheckerAgent repeatedly
// until Checker escalates (state.get("status") == "completed") or 10 iterations pass.
````

### 1.3. Interaction & Communication Mechanisms

Agents within a system often need to exchange data or trigger actions in one another. ADK facilitates this through:

#### a) Shared Session State (`session.state`)

The most fundamental way for agents operating within the same invocation (and thus sharing the same [`Session`](/sessions/session/) object via the `InvocationContext`) to communicate passively.

- **Mechanism:** One agent (or its tool/callback) writes a value (`context.state['data_key'] = processed_data`), and a subsequent agent reads it (`data = context.state.get('data_key')`). State changes are tracked via [`CallbackContext`](https://adk.dev/callbacks/index.md).
- **Convenience:** The `output_key` property on [`LlmAgent`](https://adk.dev/agents/llm-agents/index.md) automatically saves the agent's final response text (or structured output) to the specified state key.
- **Nature:** Asynchronous, passive communication. Ideal for pipelines orchestrated by `SequentialAgent` or passing data across `LoopAgent` iterations.
- **See Also:** [State Management](https://adk.dev/sessions/state/index.md)

Invocation Context and `temp:` State

When a parent agent invokes a sub-agent, it passes the same `InvocationContext`. This means they share the same temporary (`temp:`) state, which is ideal for passing data that is only relevant for the current turn.

```python
# Conceptual Example: Using output_key and reading state
from google.adk.agents import LlmAgent, SequentialAgent


agent_A = LlmAgent(name="AgentA", instruction="Find the capital of France.", output_key="capital_city")
agent_B = LlmAgent(name="AgentB", instruction="Tell me about the city stored in {capital_city}.")


pipeline = SequentialAgent(name="CityInfo", sub_agents=[agent_A, agent_B])
# AgentA runs, saves "Paris" to state['capital_city'].
# AgentB runs, its instruction processor reads state['capital_city'] to get "Paris".
```

```typescript
// Conceptual Example: Using outputKey and reading state
import { LlmAgent, SequentialAgent } from '@google/adk';

const agentA = new LlmAgent({name: 'AgentA', instruction: 'Find the capital of France.', outputKey: 'capital_city'});
const agentB = new LlmAgent({name: 'AgentB', instruction: 'Tell me about the city stored in {capital_city}.'});

const pipeline = new SequentialAgent({name: 'CityInfo', subAgents: [agentA, agentB]});
// AgentA runs, saves "Paris" to state['capital_city'].
// AgentB runs, its instruction processor reads state['capital_city'] to get "Paris".
```

```go
import (
    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/agent/workflowagents/sequentialagent"
)

// Conceptual Example: Using output_key and reading state
agentA, _ := llmagent.New(llmagent.Config{Name: "AgentA", Instruction: "Find the capital of France.", OutputKey: "capital_city", Model: m})
agentB, _ := llmagent.New(llmagent.Config{Name: "AgentB", Instruction: "Tell me about the city stored in {capital_city}.", Model: m})

pipeline2, _ := sequentialagent.New(sequentialagent.Config{
    AgentConfig: agent.Config{Name: "CityInfo", SubAgents: []agent.Agent{agentA, agentB}},
})
// AgentA runs, saves "Paris" to state["capital_city"].
// AgentB runs, its instruction processor reads state["capital_city"] to get "Paris".
```

```java
// Conceptual Example: Using outputKey and reading state
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.SequentialAgent;


LlmAgent agentA = LlmAgent.builder()
    .name("AgentA")
    .instruction("Find the capital of France.")
    .outputKey("capital_city")
    .build();


LlmAgent agentB = LlmAgent.builder()
    .name("AgentB")
    .instruction("Tell me about the city stored in {capital_city}.")
    .outputKey("capital_city")
    .build();


SequentialAgent pipeline = SequentialAgent.builder().name("CityInfo").subAgents(agentA, agentB).build();
// AgentA runs, saves "Paris" to state('capital_city').
// AgentB runs, its instruction processor reads state.get("capital_city") to get "Paris".
```

#### b) LLM-Driven Delegation (Agent Transfer)

Leverages an [`LlmAgent`](https://adk.dev/agents/llm-agents/index.md)'s understanding to dynamically route tasks to other suitable agents within the hierarchy.

- **Mechanism:** The agent's LLM generates a specific function call: `transfer_to_agent(agent_name='target_agent_name')`.
- **Handling:** The `AutoFlow`, used by default when sub-agents are present or transfer isn't disallowed, intercepts this call. It identifies the target agent using `root_agent.find_agent()` and updates the `InvocationContext` to switch execution focus.
- **Requires:** The calling `LlmAgent` needs clear `instructions` on when to transfer, and potential target agents need distinct `description`s for the LLM to make informed decisions. Transfer scope (parent, sub-agent, siblings) can be configured on the `LlmAgent`.
- **Nature:** Dynamic, flexible routing based on LLM interpretation.

```python
# Conceptual Setup: LLM Transfer
from google.adk.agents import LlmAgent


booking_agent = LlmAgent(name="Booker", description="Handles flight and hotel bookings.")
info_agent = LlmAgent(name="Info", description="Provides general information and answers questions.")


coordinator = LlmAgent(
    name="Coordinator",
    model="gemini-flash-latest",
    instruction="You are an assistant. Delegate booking tasks to Booker and info requests to Info.",
    description="Main coordinator.",
    # AutoFlow is typically used implicitly here
    sub_agents=[booking_agent, info_agent]
)
# If coordinator receives "Book a flight", its LLM should generate:
# FunctionCall(name='transfer_to_agent', args={'agent_name': 'Booker'})
# ADK framework then routes execution to booking_agent.
```

```typescript
// Conceptual Setup: LLM Transfer
import { LlmAgent } from '@google/adk';

const bookingAgent = new LlmAgent({name: 'Booker', description: 'Handles flight and hotel bookings.'});
const infoAgent = new LlmAgent({name: 'Info', description: 'Provides general information and answers questions.'});

const coordinator = new LlmAgent({
    name: 'Coordinator',
    model: 'gemini-flash-latest',
    instruction: 'You are an assistant. Delegate booking tasks to Booker and info requests to Info.',
    description: 'Main coordinator.',
    // AutoFlow is typically used implicitly here
    subAgents: [bookingAgent, infoAgent]
});
// If coordinator receives "Book a flight", its LLM should generate:
// {functionCall: {name: 'transfer_to_agent', args: {agent_name: 'Booker'}}}
// ADK framework then routes execution to bookingAgent.
```

```go
import (
    "google.golang.org/adk/agent/llmagent"
)

// Conceptual Setup: LLM Transfer
bookingAgent, _ := llmagent.New(llmagent.Config{Name: "Booker", Description: "Handles flight and hotel bookings.", Model: m})
infoAgent, _ := llmagent.New(llmagent.Config{Name: "Info", Description: "Provides general information and answers questions.", Model: m})

coordinator, _ = llmagent.New(llmagent.Config{
    Name:        "Coordinator",
    Model:       m,
    Instruction: "You are an assistant. Delegate booking tasks to Booker and info requests to Info.",
    Description: "Main coordinator.",
    SubAgents:   []agent.Agent{bookingAgent, infoAgent},
})

// If coordinator receives "Book a flight", its LLM should generate:
// FunctionCall{Name: "transfer_to_agent", Args: map[string]any{"agent_name": "Booker"}}
// ADK framework then routes execution to bookingAgent.
```

```java
// Conceptual Setup: LLM Transfer
import com.google.adk.agents.LlmAgent;


LlmAgent bookingAgent = LlmAgent.builder()
    .name("Booker")
    .description("Handles flight and hotel bookings.")
    .build();


LlmAgent infoAgent = LlmAgent.builder()
    .name("Info")
    .description("Provides general information and answers questions.")
    .build();


// Define the coordinator agent
LlmAgent coordinator = LlmAgent.builder()
    .name("Coordinator")
    .model("gemini-flash-latest") // Or your desired model
    .instruction("You are an assistant. Delegate booking tasks to Booker and info requests to Info.")
    .description("Main coordinator.")
    // AutoFlow will be used by default (implicitly) because subAgents are present
    // and transfer is not disallowed.
    .subAgents(bookingAgent, infoAgent)
    .build();

// If coordinator receives "Book a flight", its LLM should generate:
// FunctionCall.builder.name("transferToAgent").args(ImmutableMap.of("agent_name", "Booker")).build()
// ADK framework then routes execution to bookingAgent.
```

#### c) Explicit Invocation (`AgentTool`)

Allows an [`LlmAgent`](https://adk.dev/agents/llm-agents/index.md) to treat another `BaseAgent` instance as a callable function or [Tool](/tools-custom/).

- **Mechanism:** Wrap the target agent instance in `AgentTool` and include it in the parent `LlmAgent`'s `tools` list. `AgentTool` generates a corresponding function declaration for the LLM.
- **Handling:** When the parent LLM generates a function call targeting the `AgentTool`, the framework executes `AgentTool.run_async`. This method runs the target agent, captures its final response, forwards any state/artifact changes back to the parent's context, and returns the response as the tool's result.
- **Nature:** Synchronous (within the parent's flow), explicit, controlled invocation like any other tool.
- **(Note:** `AgentTool` needs to be imported and used explicitly).

```python
# Conceptual Setup: Agent as a Tool
from google.adk.agents import LlmAgent, BaseAgent
from google.adk.tools import agent_tool
from pydantic import BaseModel


# Define a target agent (could be LlmAgent or custom BaseAgent)
class ImageGeneratorAgent(BaseAgent): # Example custom agent
    name: str = "ImageGen"
    description: str = "Generates an image based on a prompt."
    # ... internal logic ...
    async def _run_async_impl(self, ctx): # Simplified run logic
        prompt = ctx.session.state.get("image_prompt", "default prompt")
        # ... generate image bytes ...
        image_bytes = b"..."
        yield Event(author=self.name, content=types.Content(parts=[types.Part.from_bytes(image_bytes, "image/png")]))


image_agent = ImageGeneratorAgent()
image_tool = agent_tool.AgentTool(agent=image_agent) # Wrap the agent


# Parent agent uses the AgentTool
artist_agent = LlmAgent(
    name="Artist",
    model="gemini-flash-latest",
    instruction="Create a prompt and use the ImageGen tool to generate the image.",
    tools=[image_tool] # Include the AgentTool
)
# Artist LLM generates a prompt, then calls:
# FunctionCall(name='ImageGen', args={'image_prompt': 'a cat wearing a hat'})
# Framework calls image_tool.run_async(...), which runs ImageGeneratorAgent.
# The resulting image Part is returned to the Artist agent as the tool result.
```

```typescript
// Conceptual Setup: Agent as a Tool
import { LlmAgent, BaseAgent, AgentTool, InvocationContext } from '@google/adk';
import type { Part, createEvent, Event } from '@google/genai';

// Define a target agent (could be LlmAgent or custom BaseAgent)
class ImageGeneratorAgent extends BaseAgent { // Example custom agent
    constructor() {
        super({name: 'ImageGen', description: 'Generates an image based on a prompt.'});
    }
    // ... internal logic ...
    async *runAsyncImpl(ctx: InvocationContext): AsyncGenerator<Event> { // Simplified run logic
        const prompt = ctx.session.state['image_prompt'] || 'default prompt';
        // ... generate image bytes ...
        const imageBytes = new Uint8Array(); // placeholder
        const imagePart: Part = {inlineData: {data: Buffer.from(imageBytes).toString('base64'), mimeType: 'image/png'}};
        yield createEvent({content: {parts: [imagePart]}});
    }

    async *runLiveImpl(ctx: InvocationContext): AsyncGenerator<Event, void, void> {
        // Not implemented for this agent.
    }
}

const imageAgent = new ImageGeneratorAgent();
const imageTool = new AgentTool({agent: imageAgent}); // Wrap the agent

// Parent agent uses the AgentTool
const artistAgent = new LlmAgent({
    name: 'Artist',
    model: 'gemini-flash-latest',
    instruction: 'Create a prompt and use the ImageGen tool to generate the image.',
    tools: [imageTool] // Include the AgentTool
});
// Artist LLM generates a prompt, then calls:
// {functionCall: {name: 'ImageGen', args: {image_prompt: 'a cat wearing a hat'}}}
// Framework calls imageTool.runAsync(...), which runs ImageGeneratorAgent.
// The resulting image Part is returned to the Artist agent as the tool result.
```

```go
import (
    "fmt"
    "iter"
    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/model"
    "google.golang.org/adk/session"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/agenttool"
    "google.golang.org/genai"
)

// Conceptual Setup: Agent as a Tool
// Define a target agent (could be LlmAgent or custom BaseAgent)
imageAgent, _ := agent.New(agent.Config{
    Name:        "ImageGen",
    Description: "Generates an image based on a prompt.",
    Run: func(ctx agent.InvocationContext) iter.Seq2[*session.Event, error] {
        return func(yield func(*session.Event, error) bool) {
            prompt, _ := ctx.Session().State().Get("image_prompt")
            fmt.Printf("Generating image for prompt: %v\n", prompt)
            imageBytes := []byte("...") // Simulate image bytes
            yield(&session.Event{
                Author: "ImageGen",
                LLMResponse: model.LLMResponse{
                    Content: &genai.Content{
                        Parts: []*genai.Part{genai.NewPartFromBytes(imageBytes, "image/png")},
                    },
                },
            }, nil)
        }
    },
})

// Wrap the agent
imageTool := agenttool.New(imageAgent, nil)

// Now imageTool can be used as a tool by other agents.

// Parent agent uses the AgentTool
artistAgent, _ := llmagent.New(llmagent.Config{
    Name:        "Artist",
    Model:       m,
    Instruction: "Create a prompt and use the ImageGen tool to generate the image.",
    Tools:       []tool.Tool{imageTool}, // Include the AgentTool
})
// Artist LLM generates a prompt, then calls:
// FunctionCall{Name: "ImageGen", Args: map[string]any{"image_prompt": "a cat wearing a hat"}}
// Framework calls imageTool.Run(...), which runs ImageGeneratorAgent.
// The resulting image Part is returned to the Artist agent as the tool result.
```

```java
// Conceptual Setup: Agent as a Tool
import com.google.adk.agents.BaseAgent;
import com.google.adk.agents.LlmAgent;
import com.google.adk.tools.AgentTool;

// Example custom agent (could be LlmAgent or custom BaseAgent)
public class ImageGeneratorAgent extends BaseAgent  {


  public ImageGeneratorAgent(String name, String description) {
    super(name, description, List.of(), null, null);
  }


  // ... internal logic ...
  @Override
  protected Flowable<Event> runAsyncImpl(InvocationContext invocationContext) { // Simplified run logic
    invocationContext.session().state().get("image_prompt");
    // Generate image bytes
    // ...


    Event responseEvent = Event.builder()
        .author(this.name())
        .content(Content.fromParts(Part.fromText("...")))
        .build();


    return Flowable.just(responseEvent);
  }


  @Override
  protected Flowable<Event> runLiveImpl(InvocationContext invocationContext) {
    return null;
  }
}

// Wrap the agent using AgentTool
ImageGeneratorAgent imageAgent = new ImageGeneratorAgent("image_agent", "generates images");
AgentTool imageTool = AgentTool.create(imageAgent);


// Parent agent uses the AgentTool
LlmAgent artistAgent = LlmAgent.builder()
        .name("Artist")
        .model("gemini-flash-latest")
        .instruction(
                "You are an artist. Create a detailed prompt for an image and then " +
                        "use the 'ImageGen' tool to generate the image. " +
                        "The 'ImageGen' tool expects a single string argument named 'request' " +
                        "containing the image prompt. The tool will return a JSON string in its " +
                        "'result' field, containing 'image_base64', 'mime_type', and 'status'."
        )
        .description("An agent that can create images using a generation tool.")
        .tools(imageTool) // Include the AgentTool
        .build();


// Artist LLM generates a prompt, then calls:
// FunctionCall(name='ImageGen', args={'imagePrompt': 'a cat wearing a hat'})
// Framework calls imageTool.runAsync(...), which runs ImageGeneratorAgent.
// The resulting image Part is returned to the Artist agent as the tool result.
```

These primitives provide the flexibility to design multi-agent interactions ranging from tightly coupled sequential workflows to dynamic, LLM-driven delegation networks.

## 2. Common Multi-Agent Patterns using ADK Primitives

By combining ADK's composition primitives, you can implement various established patterns for multi-agent collaboration.

### Coordinator/Dispatcher Pattern

- **Structure:** A central [`LlmAgent`](https://adk.dev/agents/llm-agents/index.md) (Coordinator) manages several specialized `sub_agents`.
- **Goal:** Route incoming requests to the appropriate specialist agent.
- **ADK Primitives Used:**
  - **Hierarchy:** Coordinator has specialists listed in `sub_agents`.
  - **Interaction:** Primarily uses **LLM-Driven Delegation** (requires clear `description`s on sub-agents and appropriate `instruction` on Coordinator) or **Explicit Invocation (`AgentTool`)** (Coordinator includes `AgentTool`-wrapped specialists in its `tools`).

```python
# Conceptual Code: Coordinator using LLM Transfer
from google.adk.agents import LlmAgent


billing_agent = LlmAgent(name="Billing", description="Handles billing inquiries.")
support_agent = LlmAgent(name="Support", description="Handles technical support requests.")


coordinator = LlmAgent(
    name="HelpDeskCoordinator",
    model="gemini-flash-latest",
    instruction="Route user requests: Use Billing agent for payment issues, Support agent for technical problems.",
    description="Main help desk router.",
    # allow_transfer=True is often implicit with sub_agents in AutoFlow
    sub_agents=[billing_agent, support_agent]
)
# User asks "My payment failed" -> Coordinator's LLM should call transfer_to_agent(agent_name='Billing')
# User asks "I can't log in" -> Coordinator's LLM should call transfer_to_agent(agent_name='Support')
```

```typescript
// Conceptual Code: Coordinator using LLM Transfer
import { LlmAgent } from '@google/adk';

const billingAgent = new LlmAgent({name: 'Billing', description: 'Handles billing inquiries.'});
const supportAgent = new LlmAgent({name: 'Support', description: 'Handles technical support requests.'});

const coordinator = new LlmAgent({
    name: 'HelpDeskCoordinator',
    model: 'gemini-flash-latest',
    instruction: 'Route user requests: Use Billing agent for payment issues, Support agent for technical problems.',
    description: 'Main help desk router.',
    // allowTransfer=true is often implicit with subAgents in AutoFlow
    subAgents: [billingAgent, supportAgent]
});
// User asks "My payment failed" -> Coordinator's LLM should call {functionCall: {name: 'transfer_to_agent', args: {agent_name: 'Billing'}}}
// User asks "I can't log in" -> Coordinator's LLM should call {functionCall: {name: 'transfer_to_agent', args: {agent_name: 'Support'}}}
```

```go
import (
    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
)

// Conceptual Code: Coordinator using LLM Transfer
billingAgent, _ := llmagent.New(llmagent.Config{Name: "Billing", Description: "Handles billing inquiries.", Model: m})
supportAgent, _ := llmagent.New(llmagent.Config{Name: "Support", Description: "Handles technical support requests.", Model: m})

coordinator, _ := llmagent.New(llmagent.Config{
    Name:        "HelpDeskCoordinator",
    Model:       m,
    Instruction: "Route user requests: Use Billing agent for payment issues, Support agent for technical problems.",
    Description: "Main help desk router.",
    SubAgents:   []agent.Agent{billingAgent, supportAgent},
})
// User asks "My payment failed" -> Coordinator's LLM should call transfer_to_agent(agent_name='Billing')
// User asks "I can't log in" -> Coordinator's LLM should call transfer_to_agent(agent_name='Support')
```

```java
// Conceptual Code: Coordinator using LLM Transfer
import com.google.adk.agents.LlmAgent;

LlmAgent billingAgent = LlmAgent.builder()
    .name("Billing")
    .description("Handles billing inquiries and payment issues.")
    .build();

LlmAgent supportAgent = LlmAgent.builder()
    .name("Support")
    .description("Handles technical support requests and login problems.")
    .build();

LlmAgent coordinator = LlmAgent.builder()
    .name("HelpDeskCoordinator")
    .model("gemini-flash-latest")
    .instruction("Route user requests: Use Billing agent for payment issues, Support agent for technical problems.")
    .description("Main help desk router.")
    .subAgents(billingAgent, supportAgent)
    // Agent transfer is implicit with sub agents in the Autoflow, unless specified
    // using .disallowTransferToParent or disallowTransferToPeers
    .build();

// User asks "My payment failed" -> Coordinator's LLM should call
// transferToAgent(agentName='Billing')
// User asks "I can't log in" -> Coordinator's LLM should call
// transferToAgent(agentName='Support')
```

### Sequential Pipeline Pattern

- **Structure:** A [`SequentialAgent`](https://adk.dev/agents/workflow-agents/sequential-agents/index.md) contains `sub_agents` executed in a fixed order.
- **Goal:** Implement a multistep process where the output of one-step feeds into the next.
- **ADK Primitives Used:**
  - **Workflow:** `SequentialAgent` defines the order.
  - **Communication:** Primarily uses **Shared Session State**. Earlier agents write results (often via `output_key`), later agents read those results from `context.state`.

```python
# Conceptual Code: Sequential Data Pipeline
from google.adk.agents import SequentialAgent, LlmAgent


validator = LlmAgent(name="ValidateInput", instruction="Validate the input.", output_key="validation_status")
processor = LlmAgent(name="ProcessData", instruction="Process data if {validation_status} is 'valid'.", output_key="result")
reporter = LlmAgent(name="ReportResult", instruction="Report the result from {result}.")


data_pipeline = SequentialAgent(
    name="DataPipeline",
    sub_agents=[validator, processor, reporter]
)
# validator runs -> saves to state['validation_status']
# processor runs -> reads state['validation_status'], saves to state['result']
# reporter runs -> reads state['result']
```

```typescript
// Conceptual Code: Sequential Data Pipeline
import { SequentialAgent, LlmAgent } from '@google/adk';

const validator = new LlmAgent({name: 'ValidateInput', instruction: 'Validate the input.', outputKey: 'validation_status'});
const processor = new LlmAgent({name: 'ProcessData', instruction: 'Process data if {validation_status} is "valid".', outputKey: 'result'});
const reporter = new LlmAgent({name: 'ReportResult', instruction: 'Report the result from {result}.'});

const dataPipeline = new SequentialAgent({
    name: 'DataPipeline',
    subAgents: [validator, processor, reporter]
});
// validator runs -> saves to state['validation_status']
// processor runs -> reads state['validation_status'], saves to state['result']
// reporter runs -> reads state['result']
```

```go
import (
    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/agent/workflowagents/sequentialagent"
)

// Conceptual Code: Sequential Data Pipeline
validator, _ := llmagent.New(llmagent.Config{Name: "ValidateInput", Instruction: "Validate the input.", OutputKey: "validation_status", Model: m})
processor, _ := llmagent.New(llmagent.Config{Name: "ProcessData", Instruction: "Process data if {validation_status} is 'valid'.", OutputKey: "result", Model: m})
reporter, _ := llmagent.New(llmagent.Config{Name: "ReportResult", Instruction: "Report the result from {result}.", Model: m})

dataPipeline, _ := sequentialagent.New(sequentialagent.Config{
    AgentConfig: agent.Config{Name: "DataPipeline", SubAgents: []agent.Agent{validator, processor, reporter}},
})
// validator runs -> saves to state["validation_status"]
// processor runs -> reads state["validation_status"], saves to state["result"]
// reporter runs -> reads state["result"]
```

```java
// Conceptual Code: Sequential Data Pipeline
import com.google.adk.agents.SequentialAgent;


LlmAgent validator = LlmAgent.builder()
    .name("ValidateInput")
    .instruction("Validate the input")
    .outputKey("validation_status") // Saves its main text output to session.state["validation_status"]
    .build();


LlmAgent processor = LlmAgent.builder()
    .name("ProcessData")
    .instruction("Process data if {validation_status} is 'valid'")
    .outputKey("result") // Saves its main text output to session.state["result"]
    .build();


LlmAgent reporter = LlmAgent.builder()
    .name("ReportResult")
    .instruction("Report the result from {result}")
    .build();


SequentialAgent dataPipeline = SequentialAgent.builder()
    .name("DataPipeline")
    .subAgents(validator, processor, reporter)
    .build();


// validator runs -> saves to state['validation_status']
// processor runs -> reads state['validation_status'], saves to state['result']
// reporter runs -> reads state['result']
```

### Parallel Fan-Out/Gather Pattern

- **Structure:** A [`ParallelAgent`](https://adk.dev/agents/workflow-agents/parallel-agents/index.md) runs multiple `sub_agents` concurrently, often followed by a later agent (in a `SequentialAgent`) that aggregates results.
- **Goal:** Execute independent tasks simultaneously to reduce latency, then combine their outputs.
- **ADK Primitives Used:**
  - **Workflow:** `ParallelAgent` for concurrent execution (Fan-Out). Often nested within a `SequentialAgent` to handle the subsequent aggregation step (Gather).
  - **Communication:** Sub-agents write results to distinct keys in **Shared Session State**. The subsequent "Gather" agent reads multiple state keys.

```python
# Conceptual Code: Parallel Information Gathering
from google.adk.agents import SequentialAgent, ParallelAgent, LlmAgent


fetch_api1 = LlmAgent(name="API1Fetcher", instruction="Fetch data from API 1.", output_key="api1_data")
fetch_api2 = LlmAgent(name="API2Fetcher", instruction="Fetch data from API 2.", output_key="api2_data")


gather_concurrently = ParallelAgent(
    name="ConcurrentFetch",
    sub_agents=[fetch_api1, fetch_api2]
)


synthesizer = LlmAgent(
    name="Synthesizer",
    instruction="Combine results from {api1_data} and {api2_data}."
)


overall_workflow = SequentialAgent(
    name="FetchAndSynthesize",
    sub_agents=[gather_concurrently, synthesizer] # Run parallel fetch, then synthesize
)
# fetch_api1 and fetch_api2 run concurrently, saving to state.
# synthesizer runs afterwards, reading state['api1_data'] and state['api2_data'].
```

```typescript
// Conceptual Code: Parallel Information Gathering
import { SequentialAgent, ParallelAgent, LlmAgent } from '@google/adk';

const fetchApi1 = new LlmAgent({name: 'API1Fetcher', instruction: 'Fetch data from API 1.', outputKey: 'api1_data'});
const fetchApi2 = new LlmAgent({name: 'API2Fetcher', instruction: 'Fetch data from API 2.', outputKey: 'api2_data'});

const gatherConcurrently = new ParallelAgent({
    name: 'ConcurrentFetch',
    subAgents: [fetchApi1, fetchApi2]
});

const synthesizer = new LlmAgent({
    name: 'Synthesizer',
    instruction: 'Combine results from {api1_data} and {api2_data}.'
});

const overallWorkflow = new SequentialAgent({
    name: 'FetchAndSynthesize',
    subAgents: [gatherConcurrently, synthesizer] // Run parallel fetch, then synthesize
});
// fetchApi1 and fetchApi2 run concurrently, saving to state.
// synthesizer runs afterwards, reading state['api1_data'] and state['api2_data'].
```

```go
import (
    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/agent/workflowagents/parallelagent"
    "google.golang.org/adk/agent/workflowagents/sequentialagent"
)

// Conceptual Code: Parallel Information Gathering
fetchAPI1, _ := llmagent.New(llmagent.Config{Name: "API1Fetcher", Instruction: "Fetch data from API 1.", OutputKey: "api1_data", Model: m})
fetchAPI2, _ := llmagent.New(llmagent.Config{Name: "API2Fetcher", Instruction: "Fetch data from API 2.", OutputKey: "api2_data", Model: m})

gatherConcurrently, _ := parallelagent.New(parallelagent.Config{
    AgentConfig: agent.Config{Name: "ConcurrentFetch", SubAgents: []agent.Agent{fetchAPI1, fetchAPI2}},
})

synthesizer, _ := llmagent.New(llmagent.Config{Name: "Synthesizer", Instruction: "Combine results from {api1_data} and {api2_data}.", Model: m})

overallWorkflow, _ := sequentialagent.New(sequentialagent.Config{
    AgentConfig: agent.Config{Name: "FetchAndSynthesize", SubAgents: []agent.Agent{gatherConcurrently, synthesizer}},
})
// fetch_api1 and fetch_api2 run concurrently, saving to state.
// synthesizer runs afterwards, reading state["api1_data"] and state["api2_data"].
```

```java
// Conceptual Code: Parallel Information Gathering
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.ParallelAgent;
import com.google.adk.agents.SequentialAgent;

LlmAgent fetchApi1 = LlmAgent.builder()
    .name("API1Fetcher")
    .instruction("Fetch data from API 1.")
    .outputKey("api1_data")
    .build();

LlmAgent fetchApi2 = LlmAgent.builder()
    .name("API2Fetcher")
    .instruction("Fetch data from API 2.")
    .outputKey("api2_data")
    .build();

ParallelAgent gatherConcurrently = ParallelAgent.builder()
    .name("ConcurrentFetcher")
    .subAgents(fetchApi2, fetchApi1)
    .build();

LlmAgent synthesizer = LlmAgent.builder()
    .name("Synthesizer")
    .instruction("Combine results from {api1_data} and {api2_data}.")
    .build();

SequentialAgent overallWorfklow = SequentialAgent.builder()
    .name("FetchAndSynthesize") // Run parallel fetch, then synthesize
    .subAgents(gatherConcurrently, synthesizer)
    .build();

// fetch_api1 and fetch_api2 run concurrently, saving to state.
// synthesizer runs afterwards, reading state['api1_data'] and state['api2_data'].
```

### Hierarchical Task Decomposition

- **Structure:** A multi-level tree of agents where higher-level agents break down complex goals and delegate sub-tasks to lower-level agents.
- **Goal:** Solve complex problems by recursively breaking them down into simpler, executable steps.
- **ADK Primitives Used:**
  - **Hierarchy:** Multi-level `parent_agent`/`sub_agents` structure.
  - **Interaction:** Primarily **LLM-Driven Delegation** or **Explicit Invocation (`AgentTool`)** used by parent agents to assign tasks to subagents. Results are returned up the hierarchy (via tool responses or state).

```python
# Conceptual Code: Hierarchical Research Task
from google.adk.agents import LlmAgent
from google.adk.tools import agent_tool


# Low-level tool-like agents
web_searcher = LlmAgent(name="WebSearch", description="Performs web searches for facts.")
summarizer = LlmAgent(name="Summarizer", description="Summarizes text.")


# Mid-level agent combining tools
research_assistant = LlmAgent(
    name="ResearchAssistant",
    model="gemini-flash-latest",
    description="Finds and summarizes information on a topic.",
    tools=[agent_tool.AgentTool(agent=web_searcher), agent_tool.AgentTool(agent=summarizer)]
)


# High-level agent delegating research
report_writer = LlmAgent(
    name="ReportWriter",
    model="gemini-flash-latest",
    instruction="Write a report on topic X. Use the ResearchAssistant to gather information.",
    tools=[agent_tool.AgentTool(agent=research_assistant)]
    # Alternatively, could use LLM Transfer if research_assistant is a sub_agent
)
# User interacts with ReportWriter.
# ReportWriter calls ResearchAssistant tool.
# ResearchAssistant calls WebSearch and Summarizer tools.
# Results flow back up.
```

```typescript
// Conceptual Code: Hierarchical Research Task
import { LlmAgent, AgentTool } from '@google/adk';

// Low-level tool-like agents
const webSearcher = new LlmAgent({name: 'WebSearch', description: 'Performs web searches for facts.'});
const summarizer = new LlmAgent({name: 'Summarizer', description: 'Summarizes text.'});

// Mid-level agent combining tools
const researchAssistant = new LlmAgent({
    name: 'ResearchAssistant',
    model: 'gemini-flash-latest',
    description: 'Finds and summarizes information on a topic.',
    tools: [new AgentTool({agent: webSearcher}), new AgentTool({agent: summarizer})]
});

// High-level agent delegating research
const reportWriter = new LlmAgent({
    name: 'ReportWriter',
    model: 'gemini-flash-latest',
    instruction: 'Write a report on topic X. Use the ResearchAssistant to gather information.',
    tools: [new AgentTool({agent: researchAssistant})]
    // Alternatively, could use LLM Transfer if researchAssistant is a subAgent
});
// User interacts with ReportWriter.
// ReportWriter calls ResearchAssistant tool.
// ResearchAssistant calls WebSearch and Summarizer tools.
// Results flow back up.
```

```go
import (
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/tool"
    "google.golang.org/adk/tool/agenttool"
)

// Conceptual Code: Hierarchical Research Task
// Low-level tool-like agents
webSearcher, _ := llmagent.New(llmagent.Config{Name: "WebSearch", Description: "Performs web searches for facts.", Model: m})
summarizer, _ := llmagent.New(llmagent.Config{Name: "Summarizer", Description: "Summarizes text.", Model: m})

// Mid-level agent combining tools
webSearcherTool := agenttool.New(webSearcher, nil)
summarizerTool := agenttool.New(summarizer, nil)
researchAssistant, _ := llmagent.New(llmagent.Config{
    Name:        "ResearchAssistant",
    Model:       m,
    Description: "Finds and summarizes information on a topic.",
    Tools:       []tool.Tool{webSearcherTool, summarizerTool},
})

// High-level agent delegating research
researchAssistantTool := agenttool.New(researchAssistant, nil)
reportWriter, _ := llmagent.New(llmagent.Config{
    Name:        "ReportWriter",
    Model:       m,
    Instruction: "Write a report on topic X. Use the ResearchAssistant to gather information.",
    Tools:       []tool.Tool{researchAssistantTool},
})
// User interacts with ReportWriter.
// ReportWriter calls ResearchAssistant tool.
// ResearchAssistant calls WebSearch and Summarizer tools.
// Results flow back up.
```

```java
// Conceptual Code: Hierarchical Research Task
import com.google.adk.agents.LlmAgent;
import com.google.adk.tools.AgentTool;


// Low-level tool-like agents
LlmAgent webSearcher = LlmAgent.builder()
    .name("WebSearch")
    .description("Performs web searches for facts.")
    .build();


LlmAgent summarizer = LlmAgent.builder()
    .name("Summarizer")
    .description("Summarizes text.")
    .build();


// Mid-level agent combining tools
LlmAgent researchAssistant = LlmAgent.builder()
    .name("ResearchAssistant")
    .model("gemini-flash-latest")
    .description("Finds and summarizes information on a topic.")
    .tools(AgentTool.create(webSearcher), AgentTool.create(summarizer))
    .build();


// High-level agent delegating research
LlmAgent reportWriter = LlmAgent.builder()
    .name("ReportWriter")
    .model("gemini-flash-latest")
    .instruction("Write a report on topic X. Use the ResearchAssistant to gather information.")
    .tools(AgentTool.create(researchAssistant))
    // Alternatively, could use LLM Transfer if research_assistant is a subAgent
    .build();


// User interacts with ReportWriter.
// ReportWriter calls ResearchAssistant tool.
// ResearchAssistant calls WebSearch and Summarizer tools.
// Results flow back up.
```

### Review/Critique Pattern (Generator-Critic)

- **Structure:** Typically involves two agents within a [`SequentialAgent`](https://adk.dev/agents/workflow-agents/sequential-agents/index.md): a Generator and a Critic/Reviewer.
- **Goal:** Improve the quality or validity of generated output by having a dedicated agent review it.
- **ADK Primitives Used:**
  - **Workflow:** `SequentialAgent` ensures generation happens before review.
  - **Communication:** **Shared Session State** (Generator uses `output_key` to save output; Reviewer reads that state key). The Reviewer might save its feedback to another state key for subsequent steps.

```python
# Conceptual Code: Generator-Critic
from google.adk.agents import SequentialAgent, LlmAgent


generator = LlmAgent(
    name="DraftWriter",
    instruction="Write a short paragraph about subject X.",
    output_key="draft_text"
)


reviewer = LlmAgent(
    name="FactChecker",
    instruction="Review the text in {draft_text} for factual accuracy. Output 'valid' or 'invalid' with reasons.",
    output_key="review_status"
)


# Optional: Further steps based on review_status


review_pipeline = SequentialAgent(
    name="WriteAndReview",
    sub_agents=[generator, reviewer]
)
# generator runs -> saves draft to state['draft_text']
# reviewer runs -> reads state['draft_text'], saves status to state['review_status']
```

```typescript
// Conceptual Code: Generator-Critic
import { SequentialAgent, LlmAgent } from '@google/adk';

const generator = new LlmAgent({
    name: 'DraftWriter',
    instruction: 'Write a short paragraph about subject X.',
    outputKey: 'draft_text'
});

const reviewer = new LlmAgent({
    name: 'FactChecker',
    instruction: 'Review the text in {draft_text} for factual accuracy. Output "valid" or "invalid" with reasons.',
    outputKey: 'review_status'
});

// Optional: Further steps based on review_status

const reviewPipeline = new SequentialAgent({
    name: 'WriteAndReview',
    subAgents: [generator, reviewer]
});
// generator runs -> saves draft to state['draft_text']
// reviewer runs -> reads state['draft_text'], saves status to state['review_status']
```

```go
import (
    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/agent/workflowagents/sequentialagent"
)

// Conceptual Code: Generator-Critic
generator, _ := llmagent.New(llmagent.Config{
    Name:        "DraftWriter",
    Instruction: "Write a short paragraph about subject X.",
    OutputKey:   "draft_text",
    Model:       m,
})

reviewer, _ := llmagent.New(llmagent.Config{
    Name:        "FactChecker",
    Instruction: "Review the text in {draft_text} for factual accuracy. Output 'valid' or 'invalid' with reasons.",
    OutputKey:   "review_status",
    Model:       m,
})

reviewPipeline, _ := sequentialagent.New(sequentialagent.Config{
    AgentConfig: agent.Config{Name: "WriteAndReview", SubAgents: []agent.Agent{generator, reviewer}},
})
// generator runs -> saves draft to state["draft_text"]
// reviewer runs -> reads state["draft_text"], saves status to state["review_status"]
```

```java
// Conceptual Code: Generator-Critic
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.SequentialAgent;


LlmAgent generator = LlmAgent.builder()
    .name("DraftWriter")
    .instruction("Write a short paragraph about subject X.")
    .outputKey("draft_text")
    .build();


LlmAgent reviewer = LlmAgent.builder()
    .name("FactChecker")
    .instruction("Review the text in {draft_text} for factual accuracy. Output 'valid' or 'invalid' with reasons.")
    .outputKey("review_status")
    .build();


// Optional: Further steps based on review_status


SequentialAgent reviewPipeline = SequentialAgent.builder()
    .name("WriteAndReview")
    .subAgents(generator, reviewer)
    .build();


// generator runs -> saves draft to state['draft_text']
// reviewer runs -> reads state['draft_text'], saves status to state['review_status']
```

### Iterative Refinement Pattern

- **Structure:** Uses a [`LoopAgent`](https://adk.dev/agents/workflow-agents/loop-agents/index.md) containing one or more agents that work on a task over multiple iterations.
- **Goal:** Progressively improve a result (e.g., code, text, plan) stored in the session state until a quality threshold is met or a maximum number of iterations is reached.
- **ADK Primitives Used:**
  - **Workflow:** `LoopAgent` manages the repetition.
  - **Communication:** **Shared Session State** is essential for agents to read the previous iteration's output and save the refined version.
  - **Termination:** The loop typically ends based on `max_iterations` or a dedicated checking agent setting `escalate=True` in the `Event Actions` when the result is satisfactory.

```python
# Conceptual Code: Iterative Code Refinement
from google.adk.agents import LoopAgent, LlmAgent, BaseAgent
from google.adk.events import Event, EventActions
from google.adk.agents.invocation_context import InvocationContext
from typing import AsyncGenerator


# Agent to generate/refine code based on state['current_code'] and state['requirements']
code_refiner = LlmAgent(
    name="CodeRefiner",
    instruction="Read state['current_code'] (if exists) and state['requirements']. Generate/refine Python code to meet requirements. Save to state['current_code'].",
    output_key="current_code" # Overwrites previous code in state
)


# Agent to check if the code meets quality standards
quality_checker = LlmAgent(
    name="QualityChecker",
    instruction="Evaluate the code in state['current_code'] against state['requirements']. Output 'pass' or 'fail'.",
    output_key="quality_status"
)


# Custom agent to check the status and escalate if 'pass'
class CheckStatusAndEscalate(BaseAgent):
    async def _run_async_impl(self, ctx: InvocationContext) -> AsyncGenerator[Event, None]:
        status = ctx.session.state.get("quality_status", "fail")
        should_stop = (status == "pass")
        yield Event(author=self.name, actions=EventActions(escalate=should_stop))


refinement_loop = LoopAgent(
    name="CodeRefinementLoop",
    max_iterations=5,
    sub_agents=[code_refiner, quality_checker, CheckStatusAndEscalate(name="StopChecker")]
)
# Loop runs: Refiner -> Checker -> StopChecker
# State['current_code'] is updated each iteration.
# Loop stops if QualityChecker outputs 'pass' (leading to StopChecker escalating) or after 5 iterations.
```

```typescript
// Conceptual Code: Iterative Code Refinement
import { LoopAgent, LlmAgent, BaseAgent, InvocationContext } from '@google/adk';
import type { Event, createEvent, createEventActions } from '@google/genai';

// Agent to generate/refine code based on state['current_code'] and state['requirements']
const codeRefiner = new LlmAgent({
    name: 'CodeRefiner',
    instruction: 'Read state["current_code"] (if exists) and state["requirements"]. Generate/refine Typescript code to meet requirements. Save to state["current_code"].',
    outputKey: 'current_code' // Overwrites previous code in state
});

// Agent to check if the code meets quality standards
const qualityChecker = new LlmAgent({
    name: 'QualityChecker',
    instruction: 'Evaluate the code in state["current_code"] against state["requirements"]. Output "pass" or "fail".',
    outputKey: 'quality_status'
});

// Custom agent to check the status and escalate if 'pass'
class CheckStatusAndEscalate extends BaseAgent {
    async *runAsyncImpl(ctx: InvocationContext): AsyncGenerator<Event> {
        const status = ctx.session.state.quality_status;
        const shouldStop = status === 'pass';
        if (shouldStop) {
            yield createEvent({
                author: 'StopChecker',
                actions: createEventActions(),
            });
        }
    }

    async *runLiveImpl(ctx: InvocationContext): AsyncGenerator<Event> {
        // This agent doesn't have a live implementation
        yield createEvent({ author: 'StopChecker' });
    }
}

// Loop runs: Refiner -> Checker -> StopChecker
// State['current_code'] is updated each iteration.
// Loop stops if QualityChecker outputs 'pass' (leading to StopChecker escalating) or after 5 iterations.
const refinementLoop = new LoopAgent({
    name: 'CodeRefinementLoop',
    maxIterations: 5,
    subAgents: [codeRefiner, qualityChecker, new CheckStatusAndEscalate({name: 'StopChecker'})]
});
```

```go
import (
    "iter"
    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/agent/workflowagents/loopagent"
    "google.golang.org/adk/session"
)

// Conceptual Code: Iterative Code Refinement
codeRefiner, _ := llmagent.New(llmagent.Config{
    Name:        "CodeRefiner",
    Instruction: "Read state['current_code'] (if exists) and state['requirements']. Generate/refine Python code to meet requirements. Save to state['current_code'].",
    OutputKey:   "current_code",
    Model:       m,
})

qualityChecker, _ := llmagent.New(llmagent.Config{
    Name:        "QualityChecker",
    Instruction: "Evaluate the code in state['current_code'] against state['requirements']. Output 'pass' or 'fail'.",
    OutputKey:   "quality_status",
    Model:       m,
})

checkStatusAndEscalate, _ := agent.New(agent.Config{
    Name: "StopChecker",
    Run: func(ctx agent.InvocationContext) iter.Seq2[*session.Event, error] {
        return func(yield func(*session.Event, error) bool) {
            status, _ := ctx.Session().State().Get("quality_status")
            shouldStop := status == "pass"
            yield(&session.Event{Author: "StopChecker", Actions: session.EventActions{Escalate: shouldStop}}, nil)
        }
    },
})

refinementLoop, _ := loopagent.New(loopagent.Config{
    MaxIterations: 5,
    AgentConfig:   agent.Config{Name: "CodeRefinementLoop", SubAgents: []agent.Agent{codeRefiner, qualityChecker, checkStatusAndEscalate}},
})
// Loop runs: Refiner -> Checker -> StopChecker
// State["current_code"] is updated each iteration.
// Loop stops if QualityChecker outputs 'pass' (leading to StopChecker escalating) or after 5 iterations.
```

```java
// Conceptual Code: Iterative Code Refinement
import com.google.adk.agents.BaseAgent;
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.LoopAgent;
import com.google.adk.events.Event;
import com.google.adk.events.EventActions;
import com.google.adk.agents.InvocationContext;
import io.reactivex.rxjava3.core.Flowable;
import java.util.List;


// Agent to generate/refine code based on state['current_code'] and state['requirements']
LlmAgent codeRefiner = LlmAgent.builder()
    .name("CodeRefiner")
    .instruction("Read state['current_code'] (if exists) and state['requirements']. Generate/refine Java code to meet requirements. Save to state['current_code'].")
    .outputKey("current_code") // Overwrites previous code in state
    .build();


// Agent to check if the code meets quality standards
LlmAgent qualityChecker = LlmAgent.builder()
    .name("QualityChecker")
    .instruction("Evaluate the code in state['current_code'] against state['requirements']. Output 'pass' or 'fail'.")
    .outputKey("quality_status")
    .build();


BaseAgent checkStatusAndEscalate = new BaseAgent(
    "StopChecker","Checks quality_status and escalates if 'pass'.", List.of(), null, null) {


  @Override
  protected Flowable<Event> runAsyncImpl(InvocationContext invocationContext) {
    String status = (String) invocationContext.session().state().getOrDefault("quality_status", "fail");
    boolean shouldStop = "pass".equals(status);


    EventActions actions = EventActions.builder().escalate(shouldStop).build();
    Event event = Event.builder()
        .author(this.name())
        .actions(actions)
        .build();
    return Flowable.just(event);
  }
};


LoopAgent refinementLoop = LoopAgent.builder()
    .name("CodeRefinementLoop")
    .maxIterations(5)
    .subAgents(codeRefiner, qualityChecker, checkStatusAndEscalate)
    .build();


// Loop runs: Refiner -> Checker -> StopChecker
// State['current_code'] is updated each iteration.
// Loop stops if QualityChecker outputs 'pass' (leading to StopChecker escalating) or after 5
// iterations.
```

### Human-in-the-Loop Pattern

- **Structure:** Integrates human intervention points within an agent workflow.
- **Goal:** Allow for human oversight, approval, correction, or tasks that AI cannot perform.
- **ADK Primitives Used (Conceptual):**
  - **Interaction:** Can be implemented using a custom **Tool** that pauses execution and sends a request to an external system (e.g., a UI, ticketing system) waiting for human input. The tool then returns the human's response to the agent.
  - **Workflow:** Could use **LLM-Driven Delegation** (`transfer_to_agent`) targeting a conceptual "Human Agent" that triggers the external workflow, or use the custom tool within an `LlmAgent`.
  - **State/Callbacks:** State can hold task details for the human; callbacks can manage the interaction flow.
  - **Note:** ADK doesn't have a built-in "Human Agent" type, so this requires custom integration.

```python
# Conceptual Code: Using a Tool for Human Approval
from google.adk.agents import LlmAgent, SequentialAgent
from google.adk.tools import FunctionTool


# --- Assume external_approval_tool exists ---
# This tool would:
# 1. Take details (e.g., request_id, amount, reason).
# 2. Send these details to a human review system (e.g., via API).
# 3. Poll or wait for the human response (approved/rejected).
# 4. Return the human's decision.
# async def external_approval_tool(amount: float, reason: str) -> str: ...
approval_tool = FunctionTool(func=external_approval_tool)


# Agent that prepares the request
prepare_request = LlmAgent(
    name="PrepareApproval",
    instruction="Prepare the approval request details based on user input. Store amount and reason in state.",
    # ... likely sets state['approval_amount'] and state['approval_reason'] ...
)


# Agent that calls the human approval tool
request_approval = LlmAgent(
    name="RequestHumanApproval",
    instruction="Use the external_approval_tool with amount from state['approval_amount'] and reason from state['approval_reason'].",
    tools=[approval_tool],
    output_key="human_decision"
)


# Agent that proceeds based on human decision
process_decision = LlmAgent(
    name="ProcessDecision",
    instruction="Check {human_decision}. If 'approved', proceed. If 'rejected', inform user."
)


approval_workflow = SequentialAgent(
    name="HumanApprovalWorkflow",
    sub_agents=[prepare_request, request_approval, process_decision]
)
```

```typescript
// Conceptual Code: Using a Tool for Human Approval
import { LlmAgent, SequentialAgent, FunctionTool } from '@google/adk';
import { z } from 'zod';

// --- Assume externalApprovalTool exists ---
// This tool would:
// 1. Take details (e.g., request_id, amount, reason).
// 2. Send these details to a human review system (e.g., via API).
// 3. Poll or wait for the human response (approved/rejected).
// 4. Return the human's decision.
async function externalApprovalTool(params: {amount: number, reason: string}): Promise<{decision: string}> {
  // ... implementation to call external system
  return {decision: 'approved'}; // or 'rejected'
}

const approvalTool = new FunctionTool({
  name: 'external_approval_tool',
  description: 'Sends a request for human approval.',
  parameters: z.object({
    amount: z.number(),
    reason: z.string(),
  }),
  execute: externalApprovalTool,
});


// Agent that prepares the request
const prepareRequest = new LlmAgent({
    name: 'PrepareApproval',
    instruction: 'Prepare the approval request details based on user input. Store amount and reason in state.',
    // ... likely sets state['approval_amount'] and state['approval_reason'] ...
});

// Agent that calls the human approval tool
const requestApproval = new LlmAgent({
    name: 'RequestHumanApproval',
    instruction: 'Use the external_approval_tool with amount from state["approval_amount"] and reason from state["approval_reason"].',
    tools: [approvalTool],
    outputKey: 'human_decision'
});

// Agent that proceeds based on human decision
const processDecision = new LlmAgent({
    name: 'ProcessDecision',
    instruction: 'Check {human_decision}. If "approved", proceed. If "rejected", inform user.'
});

const approvalWorkflow = new SequentialAgent({
    name: 'HumanApprovalWorkflow',
    subAgents: [prepareRequest, requestApproval, processDecision]
});
```

```go
import (
    "google.golang.org/adk/agent"
    "google.golang.org/adk/agent/llmagent"
    "google.golang.org/adk/agent/workflowagents/sequentialagent"
    "google.golang.org/adk/tool"
)

// Conceptual Code: Using a Tool for Human Approval
// --- Assume externalApprovalTool exists ---
// func externalApprovalTool(amount float64, reason string) (string, error) { ... }
type externalApprovalToolArgs struct {
    Amount float64 `json:"amount" jsonschema:"The amount for which approval is requested."`
    Reason string  `json:"reason" jsonschema:"The reason for the approval request."`
}
var externalApprovalTool func(tool.Context, externalApprovalToolArgs) (string, error)
approvalTool, _ := functiontool.New(
    functiontool.Config{
        Name:        "external_approval_tool",
        Description: "Sends a request for human approval.",
    },
    externalApprovalTool,
)

prepareRequest, _ := llmagent.New(llmagent.Config{
    Name:        "PrepareApproval",
    Instruction: "Prepare the approval request details based on user input. Store amount and reason in state.",
    Model:       m,
})

requestApproval, _ := llmagent.New(llmagent.Config{
    Name:        "RequestHumanApproval",
    Instruction: "Use the external_approval_tool with amount from state['approval_amount'] and reason from state['approval_reason'].",
    Tools:       []tool.Tool{approvalTool},
    OutputKey:   "human_decision",
    Model:       m,
})

processDecision, _ := llmagent.New(llmagent.Config{
    Name:        "ProcessDecision",
    Instruction: "Check {human_decision}. If 'approved', proceed. If 'rejected', inform user.",
    Model:       m,
})

approvalWorkflow, _ := sequentialagent.New(sequentialagent.Config{
    AgentConfig: agent.Config{Name: "HumanApprovalWorkflow", SubAgents: []agent.Agent{prepareRequest, requestApproval, processDecision}},
})
```

```java
// Conceptual Code: Using a Tool for Human Approval
import com.google.adk.agents.LlmAgent;
import com.google.adk.agents.SequentialAgent;
import com.google.adk.tools.FunctionTool;


// --- Assume external_approval_tool exists ---
// This tool would:
// 1. Take details (e.g., request_id, amount, reason).
// 2. Send these details to a human review system (e.g., via API).
// 3. Poll or wait for the human response (approved/rejected).
// 4. Return the human's decision.
// public boolean externalApprovalTool(float amount, String reason) { ... }
FunctionTool approvalTool = FunctionTool.create(externalApprovalTool);


// Agent that prepares the request
LlmAgent prepareRequest = LlmAgent.builder()
    .name("PrepareApproval")
    .instruction("Prepare the approval request details based on user input. Store amount and reason in state.")
    // ... likely sets state['approval_amount'] and state['approval_reason'] ...
    .build();


// Agent that calls the human approval tool
LlmAgent requestApproval = LlmAgent.builder()
    .name("RequestHumanApproval")
    .instruction("Use the external_approval_tool with amount from state['approval_amount'] and reason from state['approval_reason'].")
    .tools(approvalTool)
    .outputKey("human_decision")
    .build();


// Agent that proceeds based on human decision
LlmAgent processDecision = LlmAgent.builder()
    .name("ProcessDecision")
    .instruction("Check {human_decision}. If 'approved', proceed. If 'rejected', inform user.")
    .build();


SequentialAgent approvalWorkflow = SequentialAgent.builder()
    .name("HumanApprovalWorkflow")
    .subAgents(prepareRequest, requestApproval, processDecision)
    .build();
```

#### Human in the Loop with Policy

A more advanced and structured way to implement Human-in-the-Loop is by using a `PolicyEngine`. This approach allows you to define policies that can trigger a confirmation step from a user before a tool is executed. The `SecurityPlugin` intercepts a tool call, consults the `PolicyEngine`, and if the policy dictates, it will automatically request user confirmation. This pattern is more robust for enforcing governance and security rules.

Here's how it works:

1. **`SecurityPlugin`**: You add this plugin to your `Runner`. It acts as an interceptor for all tool calls.
1. **`BasePolicyEngine`**: You create a custom class that implements this interface. Its `evaluate()` method contains your logic to decide if a tool call needs confirmation.
1. **`PolicyOutcome.CONFIRM`**: When your `evaluate()` method returns this outcome, the `SecurityPlugin` pauses the tool execution and generates a special `FunctionCall` using `getAskUserConfirmationFunctionCalls`.
1. **Application Handling**: Your application code receives this special function call and presents the confirmation request to the user.
1. **User Confirmation**: Once the user confirms, your application sends a `FunctionResponse` back to the agent, which allows the `SecurityPlugin` to proceed with the original tool execution.

TypeScript Recommended Pattern

The Policy-based pattern is the recommended approach for implementing Human-in-the-Loop workflows in TypeScript. Support in other ADK languages is planned for future releases.

A conceptual example of using a `CustomPolicyEngine` to require user confirmation before executing any tool is shown below.

```typescript
const rootAgent = new LlmAgent({
  name: 'weather_time_agent',
  model: 'gemini-flash-latest',
  description:
      'Agent to answer questions about the time and weather in a city.',
  instruction:
      'You are a helpful agent who can answer user questions about the time and weather in a city.',
  tools: [getWeatherTool],
});

class CustomPolicyEngine implements BasePolicyEngine {
  async evaluate(_context: ToolCallPolicyContext): Promise<PolicyCheckResult> {
    // Default permissive implementation
    return Promise.resolve({
      outcome: PolicyOutcome.CONFIRM,
      reason: 'Needs confirmation for tool call',
    });
  }
}

const runner = new InMemoryRunner({
    agent: rootAgent,
    appName,
    plugins: [new SecurityPlugin({policyEngine: new CustomPolicyEngine()})]
});
```

You can find the full code sample [here](https://github.com/google/adk-docs/blob/main/examples/typescript/snippets/agents/workflow-agents/hitl_confirmation_agent.ts).

### Combining Patterns

These patterns provide starting points for structuring your multi-agent systems. You can mix and match them as needed to create the most effective architecture for your specific application.

# Route between agents

Supported in ADKTypeScript v1.0.0Experimental

Experimental

Agent routing is experimental and may change in future releases. We welcome your [feedback](https://github.com/google/adk-js/issues/new?template=feature_request.md)!

When building agents for different tasks, you can define a routing function that selects which one handles each invocation at runtime. `RoutedAgent` provides this capability, enabling agent fallback on error, A/B testing, planning modes, and auto-routing by input complexity. If the selected agent fails before producing any output, the routing function is called again with error context so it can select a fallback.

`RoutedAgent` is different from [workflow agents](https://adk.dev/agents/workflow-agents/index.md) like `SequentialAgent` or `ParallelAgent`, which orchestrate multiple agents in a fixed pattern, and from [LLM-driven delegation](https://adk.dev/agents/multi-agents/#b-llm-driven-delegation-agent-transfer), where the LLM decides which agent to hand off to. With `RoutedAgent`, you write an explicit routing function that selects **one** agent per invocation. For model-level routing, see [Model routing](https://adk.dev/agents/models/routing/index.md).

## How routing works

Both `RoutedAgent` and [`RoutedLlm`](https://adk.dev/agents/models/routing/index.md) are powered by a shared routing utility that handles selection and failover.

The router function receives the map of available agents and the current context, and returns the key of the agent to run. It can be synchronous or async:

```typescript
type AgentRouter = (
  agents: Readonly<Record<string, BaseAgent>>,
  context: InvocationContext,
  errorContext?: { failedKeys: ReadonlySet<string>; lastError: unknown },
) => Promise<string | undefined> | string | undefined;
```

**The `agents` parameter** accepts either a `Record<string, BaseAgent>` with explicit keys, or an array of agents. If an array is provided, each agent's `name` property is used as its key.

**Failover behavior:**

- The router is first called without `errorContext` to make the initial selection.
- If the selected agent throws an error **before yielding any events**, the router is called again with `errorContext` containing `failedKeys` and `lastError`.
- If the selected agent throws an error **after yielding events**, the error propagates directly without retry, because partial results have already been emitted.
- A key that has already been tried cannot be re-selected. If the router returns a previously failed key, the error propagates.
- If the router returns `undefined`, routing stops and the last error is thrown.

## Basic usage

Create multiple agents, define a router function that returns a key, and wrap them in a `RoutedAgent`. The following example routes between two agents based on an external configuration value that can change between invocations:

```typescript
import { LlmAgent, RoutedAgent, InMemoryRunner } from '@google/adk';

const agentA = new LlmAgent({
  name: 'agent_a',
  model: 'gemini-flash-latest',
  instruction: 'You are Agent A. Always identify yourself as Agent A.',
});

const agentB = new LlmAgent({
  name: 'agent_b',
  model: 'gemini-flash-latest',
  instruction: 'You are Agent B. Always identify yourself as Agent B.',
});

// External configuration that can change at runtime
const config = { selectedAgent: 'agent_a' };

const routedAgent = new RoutedAgent({
  name: 'my_routed_agent',
  agents: { agent_a: agentA, agent_b: agentB },
  router: () => config.selectedAgent,
});

const runner = new InMemoryRunner({
  agent: routedAgent,
  appName: 'my_app',
});

const session = await runner.sessionService.createSession({
  appName: 'my_app',
  userId: 'user_1',
});

const run = runner.runAsync({
  userId: 'user_1',
  sessionId: session.id,
  newMessage: { role: 'user', parts: [{ text: 'Who are you?' }] },
});

for await (const event of run) {
  if (event.content?.parts?.[0]?.text) {
    console.log(event.content.parts[0].text);
  }
}
```

Change `config.selectedAgent` to `'agent_b'` before the next invocation to route to a different agent.

## Fallback on error

When an agent fails, the router is called again with `errorContext` so it can select a fallback. Failover only applies if the agent fails before yielding any events (see [How routing works](#how-routing-works)). The following example checks `errorContext.failedKeys` to avoid re-selecting the failed agent:

```typescript
import {
  BaseAgent,
  InvocationContext,
  LlmAgent,
  RoutedAgent,
} from '@google/adk';

const primaryAgent = new LlmAgent({
  name: 'primary',
  model: 'gemini-flash-latest',
  instruction: 'You are the primary agent.',
});

const fallbackAgent = new LlmAgent({
  name: 'fallback',
  model: 'gemini-pro-latest',
  instruction: 'You are the fallback agent.',
});

const router = (
  agents: Readonly<Record<string, BaseAgent>>,
  context: InvocationContext,
  // errorContext is provided when a previously selected agent fails
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

const routedAgent = new RoutedAgent({
  name: 'my_routed_agent',
  agents: { primary: primaryAgent, fallback: fallbackAgent },
  router,
});
```

## Planning mode

A router can read any external state to select between agents with different instructions, models, and tools. This lets you implement a planning mode where the agent switches behavior dynamically. For example, a basic agent might have read and write tools, while a planning agent is restricted to read-only access and uses a more powerful model for analysis.

The following example shows a different `RoutedAgent` configuration. See [basic usage](#basic-usage) for the full runner setup.

```typescript
import {
  FunctionTool,
  LlmAgent,
  RoutedAgent,
} from '@google/adk';
import { z } from 'zod';

const readFileTool = new FunctionTool({
  name: 'read_file',
  description: 'Reads content from a file.',
  parameters: z.object({ filePath: z.string() }),
  execute: (args) => ({ content: `Contents of ${args.filePath}` }),
});

const writeFileTool = new FunctionTool({
  name: 'write_file',
  description: 'Writes content to a file.',
  parameters: z.object({ filePath: z.string(), content: z.string() }),
  execute: (args) => ({ result: `Wrote to ${args.filePath}` }),
});

const basicAgent = new LlmAgent({
  name: 'basic',
  model: 'gemini-flash-latest',
  instruction: 'You are a basic assistant. Use tools to help the user.',
  tools: [readFileTool, writeFileTool],
});

const planningAgent = new LlmAgent({
  name: 'planning',
  model: 'gemini-flash-latest',
  instruction: 'You are a planning expert. Analyze carefully. You can only read files.',
  tools: [readFileTool],
});

// Toggle this to switch between basic and planning agents
let planningMode = false;

const routedAgent = new RoutedAgent({
  name: 'my_routed_agent',
  agents: { basic: basicAgent, planning: planningAgent },
  router: () => (planningMode ? 'planning' : 'basic'),
});
```

Set `planningMode = true` before an invocation to route to the planning agent with its restricted tool set and different instructions.

## Auto-routing by complexity

The router function can call a lightweight classifier model to categorize input and route to different agents accordingly. Because the router can be async, you can make LLM calls inside it before selecting an agent.

The following example shows a different `RoutedAgent` configuration. See [basic usage](#basic-usage) for the full runner setup.

```typescript
import {
  BaseAgent,
  Gemini,
  InvocationContext,
  LlmAgent,
  RoutedAgent,
} from '@google/adk';

const simpleAgent = new LlmAgent({
  name: 'simple',
  model: 'gemini-flash-latest',
  instruction: 'You are a simple assistant for basic questions.',
});

const complexAgent = new LlmAgent({
  name: 'complex',
  model: 'gemini-pro-latest',
  instruction: 'You are an expert assistant for complex analysis.',
});

// Lightweight model to classify input complexity
const classifierModel = new Gemini({ model: 'gemini-flash-latest' });

const router = async (
  agents: Readonly<Record<string, BaseAgent>>,
  context: InvocationContext,
) => {
  // Extract the user's input text
  const text = context.userContent?.parts?.[0]?.text || '';
  if (!text) return 'simple';

  const prompt =
    `Classify this request as 'simple' or 'complex'. ` +
    `Reply with ONLY that word.\nRequest: "${text}"`;

  const generator = classifierModel.generateContentAsync({
    contents: [{ role: 'user', parts: [{ text: prompt }] }],
    toolsDict: {},
    liveConnectConfig: {},
  });

  let classification = '';
  for await (const resp of generator) {
    if (resp.content?.parts?.[0]?.text) {
      classification += resp.content.parts[0].text;
    }
  }

  return classification.toLowerCase().includes('complex')
    ? 'complex'
    : 'simple';
};

const routedAgent = new RoutedAgent({
  name: 'my_routed_agent',
  agents: { simple: simpleAgent, complex: complexAgent },
  router,
});
```




