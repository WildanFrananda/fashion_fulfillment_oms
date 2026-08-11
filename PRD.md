# PRD: Same-Day Delivery Fulfillment Platform for Local Muslim Fashion E-Commerce

**Status:** Draft
**Owner:** Wildan
**Last updated:** 10 August 2026

---

## 1. Background & Problem Statement

Local Muslim-fashion boutiques and e-commerce platforms (hijab, gamis, koko, mukena, etc.) frequently receive orders from buyers who need the item **on the same day** — for a *kondangan*, *pengajian*, or last-minute event. Today this is handled manually: WhatsApp order confirmations, Excel/Google Sheets for tracking, and phone calls to couriers. This causes:

- No single source of truth for order status between the merchant's warehouse staff, courier, and buyer.
- No guarantee mechanism for same-day SLA — orders silently slip to next-day delivery.
- Returns/exchanges (common in fashion — size, color mismatch) are tracked manually, causing inventory discrepancies.
- Multiple boutiques/brands share the same operator team (common in Indonesian fashion aggregator/reseller networks), risking **data leakage** between competing brands (order volume, buyer data, courier routes).

## 2. Goal

Build a Rails-based **Order Management System (OMS)** that gives boutique warehouse staff a real-time operational screen to:
1. See incoming orders that require same-day fulfillment, prioritized by cutoff time.
2. Print shipping labels/AWB per order.
3. Track courier pickup → delivery status in real time.
4. Manage returns without leaking data across tenants (brands).

### 2.1 Goals
- Multi-tenant OMS where each merchant/brand's orders, couriers, and returns are fully isolated.
- Real-time order + courier status stream to the warehouse screen (no manual refresh).
- Enforced same-day cutoff logic (e.g., order before 12:00 → must ship before 15:00 same day).
- Printable shipping label generation per order.
- Return/exchange workflow tied back to inventory.

### 2.2 Non-Goals (v1)
- Not building a storefront/checkout — this system consumes orders from existing e-commerce/storefront (Shopify-like, custom Next.js store, or WhatsApp order bot) via webhook/API.
- Not building route optimization or in-house courier fleet management — integrates with existing courier/instant-delivery providers (Gojek/Grab instant, local kurir).
- Not handling payment reconciliation — assumes payment is already confirmed upstream.

---

## 3. Personas

| Persona | Description | Needs |
|---|---|---|
| **Warehouse Staff (Admin Gudang)** | Works inside one boutique's warehouse | Real-time order queue, print label, mark packed/picked up |
| **Merchant Owner** | Owns one brand/boutique, may manage multiple staff | Order visibility, SLA compliance report, return summary |
| **Operator (3rd-party/Reseller Network)** | Manages fulfillment ops for multiple brands simultaneously | Must switch between tenants without data bleeding between brands |
| **Courier** | Picks up and delivers package | Receives pickup notification, updates delivery status |
| **Buyer** | End customer who ordered | Receives same-day delivery status updates (out of scope for OMS UI, but status is the source of truth for downstream buyer notification) |

---

## 4. Core User Stories

1. As a **warehouse staff**, I want to see all orders due for same-day delivery sorted by cutoff time, so I can prioritize picking and packing.
2. As a **warehouse staff**, I want to print a shipping label directly from the order detail, so I don't need a separate system.
3. As a **merchant owner**, I want order and courier status to update live on the operational screen without refreshing, so my staff always has current information.
4. As an **operator managing multiple brands**, I want to be certain that switching to Brand A's dashboard never shows Brand B's orders, couriers, or buyer data.
5. As a **warehouse staff**, I want to register a return/exchange against an order, so inventory and refund status stay accurate.
6. As a **merchant owner**, I want to see how many orders missed the same-day SLA this week, so I can identify bottlenecks.

---

## 5. Functional Requirements

### 5.1 Order Intake
- Orders arrive via inbound webhook (`POST /api/v1/orders`) from the merchant's storefront/e-commerce system, authenticated with a per-merchant API key.
- Each order is tagged with `merchant_id` at creation — this is the tenancy boundary for everything downstream.
- System computes `same_day_cutoff_at` based on merchant-configurable cutoff rules (e.g., "orders before 12:00 WIB qualify for same-day").
- Orders failing the cutoff are automatically flagged `next_day` instead of blocking intake.

### 5.2 Order Queue (Operational Screen)
- Real-time queue view, grouped by SLA urgency: `Overdue`, `Due < 1 hour`, `Due today`, `Next-day`.
- Each order card shows: buyer name (masked/partial for privacy unless expanded), item summary, cutoff countdown, current status.
- Status pipeline: `received → packing → packed → picked_up → in_transit → delivered → (returned)`.
- Status changes pushed live to all connected warehouse staff of that merchant via WebSocket.

### 5.3 Shipping Label Printing
- Generate AWB/label as PDF per order (merchant logo, sender/receiver address, barcode/QR of tracking number).
- Support batch print for multiple selected orders (packing session).
- Reprint capability with audit log (who reprinted, when).

### 5.4 Courier Integration & Tracking
- Courier assignment: manual (staff selects courier) or auto (via 3rd-party instant courier API — Gojek/Grab-style).
- Inbound courier webhook updates order status (`picked_up`, `in_transit`, `delivered`, `failed`).
- All courier status changes are broadcast on the merchant's dedicated channel (see §6.3).

### 5.5 Returns Management
- Staff can initiate a return against a delivered order (reason: size, defect, wrong item, buyer cancellation).
- Return has its own state machine: `requested → picked_up_from_buyer → received_at_warehouse → inspected → resolved (refund/exchange)`.
- Returns are scoped to `merchant_id` — cannot be viewed or actioned by staff of another tenant.

### 5.6 Multi-Tenancy & Data Isolation
- Every domain table includes `merchant_id` as a mandatory, indexed column.
- Application-level tenant scoping enforced at the **repository layer** (see §6) — no cross-tenant query is structurally possible without explicitly passing a merchant context.
- Operators managing multiple brands authenticate once, then explicitly select an active tenant context (`current_merchant`) per session; UI displays the active brand prominently to avoid accidental cross-posting.
- WebSocket channels are namespaced per merchant (`merchant:orders:<merchant_id>`) — a staff member's socket only subscribes to channels for merchants they are authorized on.

### 5.7 SLA Reporting
- Dashboard: same-day fulfillment rate (%), average time-to-pickup, orders missed SLA (with reason tagging).
- Filterable by date range, per merchant only (no cross-merchant aggregate visible to merchant owners; only to platform-level super-admin).

---

## 6. System Architecture

### 6.1 Role of Rails
Rails serves as the **Order Management System (OMS)**:
- Ingesting orders from upstream storefronts.
- Managing order/courier/return state.
- Generating shipping labels.
- Streaming real-time updates to the warehouse operational screen via Action Cable.

This follows the project's established layered architecture (see `AGENTS.md`): **Controller → Service → Repository → Model**, with Sorbet strict typing across all layers, and `dry-container`/`dry-auto_inject` for dependency injection.

### 6.2 Multi-Tenancy Implementation
Approach: **shared database, shared schema, row-level isolation** (simplest to operate for a small team; revisit dedicated-schema-per-tenant only if a single brand's volume/compliance needs demand it).

- `ApplicationRecord`-level default scope is deliberately **not** used for tenant scoping (silent global scopes are a common source of accidental data leaks and make Sorbet typing harder to reason about).
- Instead, every repository method requires an explicit `merchant_id: Integer` parameter, enforced via Sorbet `sig`. This makes cross-tenant access a compile-time-visible mistake rather than a silent runtime bug.

```ruby
# typed: strict
module OrderRepositoryInterface
  extend T::Sig
  extend T::Helpers
  interface!

  sig { abstract.params(merchant_id: Integer, order_id: Integer).returns(T.nilable(Order)) }
  def find_by_id(merchant_id, order_id); end

  sig { abstract.params(merchant_id: Integer).returns(T::Array[Order]) }
  def due_today(merchant_id); end
end
```

- Every service that touches order/courier/return data requires `merchant_id` as part of its `call` signature — there is no code path to fetch data without it.
- API keys (inbound webhook) and staff sessions both resolve to a `merchant_id` at the authentication boundary (`Current.merchant`), and that value is what gets threaded through service calls — never taken from client-supplied params for authorization purposes.

### 6.3 Real-Time Streaming (Action Cable)

Channel naming convention: `merchant:orders:<merchant_id>`

- On order status change, courier status change, or return status change, the relevant service publishes to `MerchantOrdersChannel` scoped to that merchant's channel string.
- Warehouse staff's browser subscribes only to the channel(s) for merchants they are authorized on (resolved server-side at subscription time — the client cannot request an arbitrary `merchant_id`).

```ruby
# typed: strict
class MerchantOrdersChannel < ApplicationCable::Channel
  extend T::Sig

  sig { void }
  def subscribed
    merchant_id = T.let(current_staff.authorized_merchant_id, Integer)
    stream_from "merchant:orders:#{merchant_id}"
  end
end
```

```ruby
# typed: strict
module Orders
  class UpdateOrderStatusService < BaseService
    extend T::Sig
    include AutoInject['order_repository']

    sig { params(merchant_id: Integer, order_id: Integer, new_status: String).returns(BaseService::Result[Order]) }
    def call(merchant_id:, order_id:, new_status:)
      order = order_repository.find_by_id(merchant_id, order_id)
      return failure("Order not found") unless order

      order_repository.update_status(merchant_id, order_id, new_status)

      ActionCable.server.broadcast(
        "merchant:orders:#{merchant_id}",
        { order_id: order_id, status: new_status, updated_at: Time.current }
      )

      success(order)
    end
  end
end
```

- Subscription authorization is re-verified on every `subscribed` call (not cached client-side) to prevent stale-token cross-tenant leakage.

### 6.4 High-Level Data Model

```
Merchant
 ├── has_many :staff_users
 ├── has_many :orders
 ├── has_many :couriers (or courier_integrations)
 └── has_many :returns

Order
 ├── belongs_to :merchant
 ├── has_many :order_items
 ├── has_one  :shipping_label
 ├── has_one  :return (optional)
 └── attributes: status, same_day_cutoff_at, courier_assigned_at, delivered_at

Return
 ├── belongs_to :merchant
 ├── belongs_to :order
 └── attributes: reason, status, resolved_at

ShippingLabel
 ├── belongs_to :order
 └── attributes: awb_number, pdf_url, reprint_count
```

Every table above carries `merchant_id` (directly or via `order_id → merchant_id`), enforced with a `NOT NULL` DB constraint plus a composite index `(merchant_id, id)` on high-traffic tables (`orders`, `returns`) for query performance and to make tenant-scoped queries the natural/fast path.

### 6.5 Sorbet & Service Boundaries
Following `AGENTS.md` conventions already established for this codebase:
- All new services (`Orders::CreateOrderService`, `Orders::UpdateOrderStatusService`, `Returns::InitiateReturnService`, `Labels::GenerateShippingLabelService`, etc.) return `T::Struct` results, never raw `Hash`.
- All repositories implement an explicit interface with `override.` signatures.
- `merchant_id` is a first-class typed parameter (`Integer`) everywhere — never inferred implicitly.

---

## 7. API Surface (v1, indicative)

| Endpoint | Purpose | Auth |
|---|---|---|
| `POST /api/v1/orders` | Inbound order creation from storefront | Merchant API key |
| `POST /api/v1/webhooks/courier` | Inbound courier status updates | Courier provider signature |
| `GET /orders` | Warehouse queue view (HTML/Turbo or JSON) | Staff session, tenant-scoped |
| `POST /orders/:id/label` | Generate/print shipping label | Staff session |
| `PATCH /orders/:id/status` | Manual status update | Staff session |
| `POST /orders/:id/returns` | Initiate return | Staff session |
| `GET /reports/sla` | SLA dashboard data | Staff/owner session |
| `cable` (`merchant:orders:<merchant_id>`) | Real-time order/courier stream | Staff session, resolved server-side |

---

## 8. Success Metrics

- **Same-day fulfillment rate** ≥ 90% of eligible orders shipped within cutoff window.
- **Time from order-received to packed** median < 30 minutes during business hours.
- **Zero cross-tenant data incidents** (hard requirement, not a target — any incident is a P0).
- Reduction in manual WhatsApp/Excel-based order tracking (qualitative, via merchant feedback).

---

## 9. Risks & Open Questions

| Risk | Mitigation |
|---|---|
| Accidental cross-tenant data leak via a missed `merchant_id` scope | Enforce via Sorbet interface signatures + repository-layer tests that assert queries always filter by `merchant_id`; add a lint/CI check scanning for raw `Model.all`/`Model.find` calls outside repositories |
| Courier provider API instability/rate limits | Queue courier webhook processing via background job (Sidekiq) with retry/backoff, decoupled from the real-time broadcast path |
| Action Cable scaling with many concurrent warehouse staff across many merchants | Use Redis adapter for Action Cable from day one; monitor channel fan-out per merchant |
| Same-day cutoff rules vary by merchant (some may want per-item-category cutoffs, e.g. custom-tailored items excluded) | Model cutoff rule as merchant-configurable policy object rather than hardcoded constant |
| Label/AWB format differs per courier provider | Abstract label generation behind a `LabelGenerator` interface per courier, similar to repository pattern |

**Open questions to resolve before implementation:**
1. Which courier providers are prioritized for integration in v1 (Gojek/Grab instant vs. local last-mile)?
2. Does the storefront push orders via webhook, or does OMS need to poll/pull (depends on existing e-commerce stack)?
3. Do operators managing multiple brands need a unified cross-tenant summary view (super-admin only), or is per-tenant switching sufficient for v1?

---

## 10. Phased Rollout

**Phase 1 — Core OMS (MVP)**
- Order intake (webhook), tenant-scoped order queue, manual status updates, label printing (single courier provider), basic returns flow.

**Phase 2 — Real-Time Ops**
- Action Cable live streaming to warehouse screen, courier webhook integration, SLA countdown UI.

**Phase 3 — Reporting & Scale**
- SLA dashboard, multi-courier abstraction, background job hardening, multi-tenant operator UX polish.