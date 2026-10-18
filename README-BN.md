# FC Champions Community — Tournament Management Website

Premium black-and-gold, mobile-friendly website starter for managing multiple FC Mobile tournaments and seasons. It is built as a reusable tournament hub, not a single-event landing page.

## এই প্যাকেজে কী আছে

- `index.html` — website UI (Home, Tournament Hub, Fixtures & Results, Standings, Player Directory, Hall of Fame, Admin Login)
- `config.js` — Supabase project settings
- `schema.sql` — persistent database tables, approved-admin access and Row Level Security (RLS)
- `README-BN.md` — setup guide

## গুরুত্বপূর্ণ সত্য

শুধু HTML ফাইল GitHub Pages-এ রাখলে login বা persistent database তৈরি হয় না। তাই এখানে Supabase-এর free tier ব্যবহার করার ব্যবস্থা রাখা হয়েছে। Supabase-এ database ও authentication তৈরি করে GitHub Pages-এ ফাইল প্রকাশ করতে হবে। Free-tier limits/terms বদলাতে পারে। Custom `.com` domain বাধ্যতামূলক নয়; নিজের domain চাইলে আলাদা খরচ হতে পারে। এই starter-এর code এখনো আপনার হয়ে online publish করা হয়নি।

## ধাপ ১ — Supabase database তৈরি

1. https://supabase.com এ গিয়ে free project তৈরি করুন। Project region বেছে নিন এবং database password নিরাপদে রাখুন।
2. Project-এর **SQL Editor** খুলুন।
3. এই প্যাকেজের `schema.sql` পুরোটা paste করে **Run** করুন।
4. Supabase Project Settings → API (বা Connect/API settings) থেকে **Project URL** এবং **anon/public key** নিন।
5. `config.js` ফাইলে বসান:

```js
window.FCC_CONFIG = {
  SUPABASE_URL: "https://YOUR-PROJECT.supabase.co",
  SUPABASE_ANON_KEY: "YOUR_ANON_PUBLIC_KEY"
};
```

**কখনো `service_role` / secret key `config.js` বা website-এর অন্য browser code-এ দেবেন না।** এই website-এর নিরাপত্তা RLS policies-এর ওপর নির্ভর করে; `schema.sql` চালানোর আগে website public-এ দেবেন না।

## ধাপ ২ — প্রথম Owner Admin তৈরি

1. Supabase Dashboard → Authentication → Users-এ গিয়ে নিজের email দিয়ে user তৈরি করুন (Dashboard-এ “Add user”/“Invite user” অপশন থাকতে পারে)।
2. ওই user-এর UUID/ID কপি করুন।
3. Supabase SQL Editor-এ নিচের SQL চালান; `YOUR_AUTH_USER_UUID`-এর জায়গায় আপনার আসল UUID বসাবেন:

```sql
insert into public.admins (user_id, display_name, role)
values ('YOUR_AUTH_USER_UUID', 'Community Owner', 'owner');
```

4. Website-এ **Admin Login** দিয়ে সেই email/password-এ sign in করুন। শুধু authentication account থাকলেই admin হওয়া যাবে না—`admins` table-এ অনুমোদিত থাকতে হবে।

### নির্বাচিত Admin যোগ করা

1. অন্য Admin-এর account Supabase Authentication-এ তৈরি/invite করুন।
2. তার user UUID নিয়ে SQL Editor-এ চালান:

```sql
insert into public.admins (user_id, display_name, role)
values ('SELECTED_ADMIN_AUTH_UUID', 'Tournament Admin', 'admin');
```

Admin সরাতে owner হিসেবে SQL Editor-এ তার row delete করুন। শুধু বিশ্বস্ত ব্যক্তিকে access দেবেন। এই starter-এ admin-management UI নেই; নিরাপদভাবে Supabase Dashboard থেকেই Admin অনুমোদন করতে হবে।

## ধাপ ৩ — বিনামূল্যে GitHub Pages-এ প্রকাশ

1. GitHub account খুলুন বা sign in করুন: https://github.com
2. New repository তৈরি করুন; যেমন `fc-champions-community`। Public repository-তে `index.html`, `config.js`, `schema.sql` এবং `README-BN.md` upload করুন। (Database password বা service-role key কখনো commit করবেন না।)
3. Repository → **Settings → Pages** খুলুন। Build/Deploy source হিসেবে **Deploy from a branch** বেছে নিন, branch `main`, folder `/ (root)` করে Save করুন।
4. GitHub Pages যে URL দেখাবে সেটি খুলুন। প্রকাশ হতে কয়েক মিনিট লাগতে পারে।
5. `config.js`-এ Supabase URL/key ঠিক আছে কিনা দেখুন। GitHub Pages-এ `config.js` পরিবর্তন করলে সেই পরিবর্তন commit/push করতে হবে।

## কীভাবে ব্যবহার করবেন

- Admin Login: অনুমোদিত Admin sign in করবে।
- **New Tournament:** World Cup বা League format-এ নতুন Season/Tournament বানান। ভবিষ্যতের format বাড়ানোর জন্য database-এ `format` text ও `format_settings` JSONB field আছে। নতুন format-এর fixture/standings rules যোগ করতে code update লাগবে।
- **Add Player:** public player directory-তে display name, game username, UID, OVR যোগ করুন। ব্যক্তিগত email/phone এখানে যোগ করবেন না।
- **Add Match:** tournament, home/away player, group/stage ও date দিয়ে fixture বানান।
- **Score:** Admin ম্যাচের স্কোর নিজে update করবে। Completed score থেকে table points: Win 3, Draw 1, Loss 0 হিসেবে হিসাব হবে।
- **Hall of Fame:** champions table-এ champions/runner-up/third-place record যোগ করা যাবে database SQL Editor থেকে। এই starter-এ champion award করার UI নেই।

## বর্তমান starter-এর সীমাবদ্ধতা

এটি একটি কার্যকর প্রথম সংস্করণ/সফটওয়্যার starter, production-ready full management suite নয়। Login, admin permissions, persistent tournaments/players/matches এবং score updates Supabase সংযোগ ও SQL setup সম্পন্ন হলে কাজ করবে। এই সংস্করণে fixture auto-generation, group draw, player-to-tournament enrollment management, champion-award UI, CSV export, audit log, password reset UI ও admin-management screen এখনো তৈরি করা হয়নি। Standings-এ খেলোয়াড়ের পরিসংখ্যান ম্যাচে অংশ নেওয়া player-দের থেকে হিসাব হয়; advanced World Cup knockout automation এখনো নেই।

## Troubleshooting

- “Database is not configured yet” দেখালে `config.js`-এর URL/key ঠিক করুন।
- Login হলেও admin mode না এলে Auth user UUID `public.admins` table-এ আছে কি না দেখুন।
- Data read হচ্ছে কিন্তু save হচ্ছে না—`schema.sql` পুরোটা সফলভাবে run হয়েছে এবং RLS policies আছে কি না দেখুন।
- Browser console-এ Supabase error থাকলে error message পরীক্ষা করুন। কখনো secret/service_role key দিয়ে browser error “fix” করবেন না।
