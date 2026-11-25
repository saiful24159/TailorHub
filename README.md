# TailorHub

Bangladesh custom tailoring and garments marketplace — first responsive Bengali frontend prototype.

## Current prototype
- Responsive Bengali storefront and clothing categories
- Sample product cards and customization form UI
- Manual body measurement form UI
- Supabase email/password signup and login UI (requires project config)
- Manual measurement form connected to Supabase
- Seller application form connected to Supabase (pending admin approval)
- Local product customization preference storage

## Database foundation
- Supabase PostgreSQL schema with Row Level Security policies
- Security migration that disables unsafe direct order writes
- Trusted database order-creation function that reads product prices from the database
- Seller order-status function with server-side ownership checks

Apply `supabase/schema.sql` first, then `supabase/migrations/002_security_hardening.sql` (see `SETUP.md`). These SQL files have not yet been executed against a live Supabase project or independently audited.

## Not connected yet
- Live Supabase project connection and verified production database
- Phone OTP / SMS authentication
- Real cart, checkout and order management
- bKash, Nagad or Rocket payment integration
- Seller approval workflow and Super Admin dashboard
- AI-assisted body measurement
- Delivery integration

## Important
This is a UI prototype only. Forms do not submit or store data and no real payments are accepted. Never place payment secrets in frontend code or a public repository. AI body measurements must be treated as estimates and verified before production.