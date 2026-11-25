# TailorHub — implementation notes

## Current status
The repository contains a responsive Bengali storefront prototype in `index.html`.
The database foundation is defined in `supabase/schema.sql`.

## Database setup (Supabase)
1. Create a Supabase project (choose a free plan if available; no paid upgrade is required for this setup).
2. Open **SQL Editor** in the Supabase dashboard.
3. Paste and run `supabase/schema.sql`.
4. In Authentication settings, configure phone/email sign-in methods and test them before launch.
5. Keep database backups and review Row Level Security policies before real customer data is collected.

## Browser client setup
1. Copy `supabase-client.example.js` to `supabase-client.js`.
2. Add the project's Project URL and publishable/anon key.
3. Never expose the service_role key, payment gateway secret, or private API credentials in browser JavaScript.
4. Do not commit real keys to this public repository.

## Important limitations
- The current UI forms are demonstrations; they do not yet call Supabase.
- The SQL schema is a starting foundation, not a fully audited production backend.
- Payment gateway integrations require merchant onboarding, server-side callbacks, and provider approval.
- AI body measurement needs a separate validated service and customer consent; its output must remain an estimate and be verified by a tailor before production.
- Do not store customer body photos unless strictly needed, consented to, access-controlled, and protected by a retention policy.

## Planned implementation order
1. Connect authentication and customer profiles.
2. Connect catalog and product customization.
3. Build measurement save/verify workflow.
4. Implement cart, order creation, seller assignment and order history.
5. Build seller and admin management screens with server-enforced permissions.
6. Add delivery and payment providers only after merchant credentials and server-side integration are available.
