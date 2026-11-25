# TailorHub

Bangladesh custom tailoring and garments marketplace — first responsive Bengali frontend prototype.

## Current prototype
- Responsive Bengali storefront and clothing categories
- Sample product cards and customization form UI
- Manual body measurement form UI
- Customer login form UI
- Seller application form UI

## Database foundation
- Supabase PostgreSQL schema with Row Level Security policies
- Security migration that disables unsafe direct order writes
- Trusted database order-creation function that reads product prices from the database
- Seller order-status function with server-side ownership checks

Apply `supabase/schema.sql` first, then `supabase/migrations/002_security_hardening.sql` (see `SETUP.md`). These SQL files have not yet been executed against a live Supabase project or independently audited.

## Not connected yet
- Backend and database
- Secure authentication / OTP
- Real cart, checkout and order management
- bKash, Nagad or Rocket payment integration
- Seller approval workflow and Super Admin dashboard
- AI-assisted body measurement
- Delivery integration

## Important
This is a UI prototype only. Forms do not submit or store data and no real payments are accepted. Never place payment secrets in frontend code or a public repository. AI body measurements must be treated as estimates and verified before production.