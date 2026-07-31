# AI Usage & Cost Controls

TrackX implements client-side rate limits to prevent budget or API quota over-use.

## Usage Quotas
- Limit: max 20 daily requests, 300 monthly requests.
- Tracked locally via `SharedPreferences`.
- Resets automatically at local midnight.
- Standard fallback details are provided when quotas are exceeded.
