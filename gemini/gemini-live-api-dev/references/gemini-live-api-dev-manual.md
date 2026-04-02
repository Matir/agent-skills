# Gemini Live API Development Manual

## Overview
The Live API enables **low-latency, real-time voice and video interactions** with Gemini over WebSockets. It processes continuous streams of audio, video, or text to deliver immediate, human-like spoken responses.

### Key Capabilities
- **Bidirectional audio streaming** — real-time mic-to-speaker conversations
- **Video streaming** — send camera/screen frames alongside audio
- **Text input/output** — send and receive text within a live session
- **Audio transcriptions** — get text transcripts of both input and output audio
- **Voice Activity Detection (VAD)** — automatic interruption handling
- **Native audio** — thinking (with configurable `thinkingLevel`)
- **Function calling** — synchronous tool use
- **Google Search grounding** — ground responses in real-time search results
- **Session management** — context compression, session resumption, GoAway signals
- **Ephemeral tokens** — secure client-side authentication

## Models
- `gemini-3.1-flash-live-preview` — Optimized for low-latency, real-time dialogue. Native audio output, thinking (via `thinkingLevel`). 128k context window. **This is the recommended model for all Live API use cases.**

### Deprecated Models
- `gemini-2.5-flash-native-audio-preview-12-2025` — Migrate to `gemini-3.1-flash-live-preview`.
- `gemini-live-2.5-flash-preview` — Released June 17, 2025. Shutdown: December 9, 2025.
- `gemini-2.0-flash-live-001` — Released April 9, 2025. Shutdown: December 9, 2025.

## SDKs
- **Python**: `google-genai` — `uv pip install google-genai`
- **JavaScript/TypeScript**: `@google/genai` — `npm install @google/genai`

## Partner Integrations
- [LiveKit](https://docs.livekit.io/agents/models/realtime/plugins/gemini/)
- [Pipecat by Daily](https://docs.pipecat.ai/guides/features/gemini-live)
- [Fishjam by Software Mansion](https://docs.fishjam.io/tutorials/gemini-live-integration)
- [Vision Agents by Stream](https://visionagents.ai/integrations/gemini)
- [Voximplant](https://voximplant.com/products/gemini-client)
- [Firebase AI SDK](https://firebase.google.com/docs/ai-logic/live-api?api=dev)

## Audio Formats
- **Input**: Raw PCM, little-endian, 16-bit, mono. 16kHz native (will resample others). MIME type: `audio/pcm;rate=16000`
- **Output**: Raw PCM, little-endian, 16-bit, mono. 24kHz sample rate.

## Limitations
- **Response modality** — Only `TEXT` **or** `AUDIO` per session, not both
- **Audio-only session** — 15 min without compression
- **Audio+video session** — 2 min without compression
- **Connection lifetime** — ~10 min (use session resumption)
- **Context window** — 128k tokens (native audio) / 32k tokens (standard)
- **Async function calling** — Not yet supported; function calling is synchronous only.
- **Proactive audio** — Not yet supported in Gemini 3.1 Flash Live.
- **Affective dialogue** — Not yet supported in Gemini 3.1 Flash Live.
- **Code execution** — Not supported
- **URL context** — Not supported

## Migrating from Gemini 2.5 Flash Live
1. **Model string** — Update from `gemini-2.5-flash-native-audio-preview-12-2025` to `gemini-3.1-flash-live-preview`.
2. **Thinking configuration** — Use `thinkingLevel` (`minimal`, `low`, `medium`, `high`) instead of `thinkingBudget`.
3. **Server events** — Process **all** parts in each event (audio + transcript).
4. **Client content** — Use `send_realtime_input` for text during conversation.
5. **Turn coverage** — Defaults to `TURN_INCLUDES_AUDIO_ACTIVITY_AND_ALL_VIDEO`.

## Best Practices
1. **Use headphones** to prevent echo/self-interruption.
2. **Enable context window compression** for sessions > 15 minutes.
3. **Implement session resumption** for connection resets.
4. **Use ephemeral tokens** for client-side deployments.
5. **Use `send_realtime_input`** for all real-time user input.
6. **Send `audioStreamEnd`** when mic is paused.
7. **Clear audio playback queues** on interruption signals.
8. **Process all parts** in each server event.

## Documentation Lookup
- [Live API Overview](https://ai.google.dev/gemini-api/docs/live.md.txt)
- [Live API Capabilities Guide](https://ai.google.dev/gemini-api/docs/live-guide.md.txt)
- [Live API Tool Use](https://ai.google.dev/gemini-api/docs/live-tools.md.txt)
- [Session Management](https://ai.google.dev/gemini-api/docs/live-session.md.txt)
- [Ephemeral Tokens](https://ai.google.dev/gemini-api/docs/ephemeral-tokens.md.txt)
- [WebSockets API Reference](https://ai.google.dev/api/live.md.txt)
