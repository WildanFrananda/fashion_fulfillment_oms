# Mandatory Multi-Service Ecosystem Pre-Reading & Cross-Audit Rule

Before planning, designing, or proposing any feature or architectural component in `fashion_fulfillment_oms`:

1. **MANDATORY CROSS-SERVICE AUDIT**: The AI agent MUST read `PRD.md`, `microservices_grpc_migration_plan.md`, and inspect all related microservices in `real_time_ecommerce_app` (`fleet_pulse`, `fleet_pulse_mobile`, `storefront`, `fashion_fulfillment_oms`).
2. **NO DUPLICATE SERVICE FEATURES**: The AI agent is strictly forbidden from proposing or building functionality inside OMS that already exists or belongs to another microservice.
   - Example: Direct driver WebSocket telemetry belongs to `fleet_pulse` (Elixir/Phoenix engine). OMS MUST NOT build driver WebSockets directly; OMS communicates with `fleet_pulse` via gRPC.
3. **PRE-ALIGNMENT REQUIREMENT**: Always align the inter-service communication boundary (gRPC, SSE, WebSockets) with the user before presenting implementation plans.
