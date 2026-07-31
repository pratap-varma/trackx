# AI Provider Abstraction

TrackX is provider-agnostic.

## Implementation Details
- `AiProvider` serves as the primary signature interface.
- Local compiler settings read `GEMINI_API_KEY` from environments using `--dart-define` compilation parameters, ensuring keys are never checked into git repos.
- If no key is found or offline is chosen, calls route immediately to local deterministic providers.
