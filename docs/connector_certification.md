# Connector Certification Checklist

Standard verification gates for new official integrations.

## Validation Gates

- **API Scope Minimization**: Verify the integration uses only required read-only permissions.
- **Tenant Isolation**: Confirm that cross-tenant identifiers trigger exceptions.
- **Rate Limit Resilience**: Validate that the connector respects HTTP 429 status codes.
- **Data Schema Mapping**: Match incoming JSON objects to internal Course structures.
