# TailorHub — implementation notes

## Current status
The repository contains a responsive Bengali storefront prototype in `index.html`.
The database foundation is defined in `supabase/schema.sql`.

## Database setup (Supabase)
1. Create a Supabase project (choose a free plan if available; no paid upgrade is required for this setup).
2. Open **SQL Editor** in the Supabase dashboard.
3. Paste and run `supabase/schema.sql`.
4. Then paste and run `supabase/migrations/002_security_hardening.sql`.
5. In Authentication settings, configure phone/email sign-in methods and test them before launch.
6. Keep database backups and review Row Level Security policies before real customer data is collected.

## Browser client setup
1. Copy `supabase-client.example.js` to `supabase-client.js`.
2. Add the project's Project URL and publishable/anon key.
3. Never expose the service_role key, payment gateway secret, or private API credentials in browser JavaScript.
4. Do not commit real keys to this public repository.

## Important limitations
- Login/signup, manual measurement saving, and seller application forms are wired to Supabase Auth/Database in `app.js` once the local config is added. Product customization is only saved in the browser; the real cart and checkout are not implemented.
- The SQL schema is a starting foundation, not a fully audited production backend.
- Payment gateway integrations require merchant onboarding, server-side callbacks, and provider approval.
- AI body measurement needs a separate validated service and customer consent; its output must remain an estimate and be verified by a tailor before production.
- Do not store customer body photos unless strictly needed, consented to, access-controlled, and protected by a retention policy.

## Planned implementation order
1. Test authentication, customer profiles, measurement saving, and seller applications.
2. Connect the catalog and product customization to database records.
3. Build measurement review/verification and customer account screens.
4. Implement cart, checkout, order history, and seller assignment using the secure order function.
5. Build seller and admin management screens with server-enforced permissions.
6. Add delivery and payment providers only after merchant credentials and server-side integration are available.
