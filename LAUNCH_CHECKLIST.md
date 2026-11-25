# TailorHub — launch checklist

This checklist separates code already present from actions that require the project owner's accounts, choices, or credentials.

## Present in this repository
- Responsive Bengali storefront prototype (index.html).
- Initial Supabase schema and Row Level Security policies (supabase/schema.sql).
- Security hardening migration (supabase/migrations/002_security_hardening.sql).
- Example browser configuration (supabase-client.example.js).
- Setup instructions (SETUP.md).

## Must be completed before real customers or orders
- [ ] Create a Supabase project and run the schema, then the security migration, in that order.
- [ ] Test SQL execution and every RLS policy using customer, seller, and admin test accounts.
- [ ] Configure authentication (phone/email verification, password reset, session handling).
- [ ] Connect the storefront forms and product catalog to Supabase; current forms are demo-only.
- [ ] Build customer account, measurement save/edit, cart, checkout, and order-history screens.
- [ ] Build seller application, approval, product management, and order-workflow screens.
- [ ] Build a protected Super Admin dashboard and secure initial admin provisioning.
- [ ] Configure image storage with private access rules and upload limits.
- [ ] Decide delivery fees, service areas, return/cancellation rules, seller commission, and terms/privacy notices.
- [ ] Add payment provider onboarding and server-side payment initiation/callback verification for bKash/Nagad/Rocket. Do not mark payments paid from browser code.
- [ ] Test order creation, concurrent stock/price changes, permissions, error handling, and backups.
- [ ] Deploy the site and configure a domain, HTTPS, monitoring, and production environment variables.

## Important implementation notes
- The trusted create_customer_order database function calculates item prices from active database products and does not accept a browser-provided total. It currently sets delivery fee to zero; define a real delivery-fee policy before launch.
- The order function currently expects one seller per order. Mixed-seller carts must be split into separate orders or handled by a future marketplace checkout design.
- AI body measurement is not implemented. It needs a validated model/service, explicit customer consent, image privacy and retention controls, and tailor/customer verification.
- No payment provider, SMS OTP provider, delivery company, AI measurement service, or paid hosting has been connected.
- Never commit Supabase service-role keys, payment secrets, SMS credentials, or private tokens. Use server-side secrets only.
- The SQL has not been executed against a live Supabase project or professionally security-audited. Treat it as development groundwork, not production approval.