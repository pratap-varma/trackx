# Stage 17 AI Assistant Architecture

TrackX Stage 17 implements a secure, grounded, student-controlled AI Assistant.

## Key Layers

1. **Domain Models**:
   - `AiRequest`: Formulates query instructions, prompt metadata, and context.
   - `AiResponse`: Standardized outputs containing text, sources, suggested actions, and confidence levels.
   - `AiContext`: Selective snapshot of the student's on-device data.
   - `AiActionRecord`: Immutable log auditing suggested and completed AI actions.

2. **AI Provider Abstraction**:
   - `AiProvider` interface separates UI execution from network calls.
   - `GeminiAiProvider`: Client calling Gemini 1.5 Flash using secure keys.
   - `OfflineFallbackProvider`: Generates deterministic text responses locally using templates.

3. **Validation & Grounding**:
   - `AiActionValidator`: Prevents invalid action scheduling (e.g. past dates, timetable overlaps).
   - Local calculations are computed on-device (e.g. attendance ratios) and injected, preventing hallucinated calculations.
