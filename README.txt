TRAFFIC BUDDY — SUPABASE VEHICLE DOCUMENT VAULT

Included files
- index.html: Traffic Buddy frontend connected to Supabase Auth, Postgres and private Storage.
- Traffic_Buddy_Supabase_Setup.sql: database tables, Row Level Security policies, private storage bucket and new-user profile trigger.

SETUP (one-time)
1. Open https://supabase.com/dashboard and select the Traffic Buddy project.
2. Go to SQL Editor -> New query.
3. Open Traffic_Buddy_Supabase_Setup.sql, copy the entire file into the editor, and click Run.
4. In Supabase Dashboard -> Authentication -> URL Configuration, add your deployed website URL to Site URL / Redirect URLs as appropriate.
5. In Authentication -> Providers -> Email, choose whether email confirmation is required. If enabled, users must confirm their email before signing in.
6. Deploy index.html using your static host (for example, your existing hosting provider). Keep the Supabase URL and publishable/anon key in the frontend only; NEVER put a service_role/secret key in HTML.
7. Test: create an account, confirm email if prompted, log in, add a vehicle, upload a PDF/image, sign out, and log in again. Confirm the vehicle/document remains listed. Test with a second account to verify it cannot see the first account's files.

FEATURES
- Email/password signup and login through Supabase Auth.
- Vehicle records stored in public.vehicles.
- Documents stored privately in the vehicle-documents Storage bucket; metadata stored in public.vehicle_documents.
- Supports motorcycles/bikes, scooters, cars, auto-rickshaws, taxis, vans, buses, trucks/lorries, tippers/dumpers, goods carriers, tractors/trailers, construction equipment, emergency vehicles, and other road vehicles.
- Upload supports PDF/JPG/PNG/WEBP up to 10 MB.
- Row Level Security policies scope database rows and storage paths to the signed-in user.

IMPORTANT
- This frontend currently points to the Supabase project configured at the top of index.html. The publishable/anon key is intended for browser use only when Row Level Security is correctly configured. Never expose a Supabase service_role or secret key.
- This app stores user-uploaded documents; treat them as sensitive personal data. Use HTTPS hosting, strong account passwords, and verify RLS with two separate test accounts before production use.
- This is a private document vault, not an official DigiLocker or government verification service.
