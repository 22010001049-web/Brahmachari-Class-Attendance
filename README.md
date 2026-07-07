# Brahmachari Class Attendance

A full-featured **Attendance Management System** built with **Flutter** and **Supabase**, designed to track and manage class attendance for Brahmacharis (students/disciples). The system supports real-time attendance marking, report generation, Excel/PDF export, and a statistics dashboard.

---

## ✨ Features

- 📋 **Attendance Marking** — Mark individual Brahmachari attendance per class session with timestamped arrivals
- ⏱️ **On-Time / Late Detection** — Automatically calculates status based on arrival vs session start time
- 🎓 **Speaker Management** — Add and manage class speakers/teachers
- 👥 **Brahmachari Management** — Maintain the full roster of students
- 📊 **Dashboard & Reports** — Visual attendance statistics with charts and filters
- 🔍 **Global Search** — Search across sessions, brahmacharis, and speakers
- 📤 **Excel Export** — Export attendance data as `.xlsx` spreadsheets
- 📄 **PDF Export** — Generate printable attendance reports as PDFs
- 💾 **Backup & Restore** — Data backup and import functionality
- 🌓 **Dark / Light Theme** — Persistent theme preference using SharedPreferences
- 🌐 **Web Deployment** — Deployable to Netlify or any static web host

---

## 🛠️ Tech Stack

| Layer       | Technology                     |
|-------------|-------------------------------|
| UI Framework | Flutter 3.x (Material 3)     |
| Backend     | Supabase (PostgreSQL + Auth)  |
| State       | Provider                       |
| Export      | `excel` + `pdf` packages       |
| Charts      | `fl_chart`                     |
| Storage     | Supabase Database              |
| Deployment  | Netlify (Flutter Web)         |

---

## 📦 Dependencies

```yaml
supabase_flutter: ^2.8.0
excel: ^4.0.0
pdf: ^3.11.1
fl_chart: ^0.69.2
provider: ^6.1.2
shared_preferences: ^2.3.0
file_picker: ^11.0.2
path_provider: ^2.1.0
intl: ^0.19.0
```

---

## 🚀 Installation & Setup

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.12.2 or later)
- A [Supabase](https://supabase.com) project with the required tables

### 1. Clone the Repository

```bash
git clone https://github.com/<your-username>/brahmachari-class-attendance.git
cd brahmachari-class-attendance
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Configure Supabase

This project reads Supabase credentials from **build-time environment variables** using `--dart-define`. No `.env` file is needed — do **not** hardcode secrets.

Required variables:
- `NEXT_PUBLIC_SUPABASE_URL` — Your Supabase project URL
- `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` — Your Supabase anon/publishable key

### 4. Set Up the Database

Run the migration SQL on your Supabase project:

```bash
# Using Supabase CLI
supabase db push
```

Or manually execute the files in `supabase/migrations/` and `supabase/schema.sql` in the Supabase SQL Editor.

---

## ▶️ Running Locally

### Web (recommended for development)

```bash
flutter run -d chrome \
  --dart-define=NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=your-anon-key
```

### Android / iOS

```bash
flutter run \
  --dart-define=NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=your-anon-key
```

---

## 🏗️ Build Commands

### Flutter Web (Production Build)

```bash
flutter build web --release \
  --dart-define=NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=your-anon-key
```

Output will be in `build/web/`.

### Android APK

```bash
flutter build apk --release \
  --dart-define=NEXT_PUBLIC_SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY=your-anon-key
```

---

## 🌐 Deployment (Netlify)

The project includes a `netlify.toml` for automatic builds. Set the following **environment variables** in your Netlify dashboard under *Site Settings → Environment Variables*:

| Variable | Value |
|---|---|
| `NEXT_PUBLIC_SUPABASE_URL` | `https://your-project.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` | `your-anon-key` |

Netlify will automatically run `flutter build web --release` on every push to `main`.

---

## 📁 Project Structure

```
lib/
├── config/         # Supabase config & URL strategy
├── data/           # Static data (initial brahmachari names)
├── models/         # Data models (Brahmachari, Class, Attendance, Speaker)
├── screens/        # All UI screens
├── services/       # Supabase, Excel, PDF, Backup services
└── widgets/        # Reusable widgets
supabase/
├── migrations/     # Database migration SQL files
└── schema.sql      # Full database schema
```

---

## 🔐 Security Notes

- **No secrets are committed** to this repository.
- All Supabase credentials are injected at **build time** via `--dart-define`.
- Row-Level Security (RLS) should be configured in Supabase for production use.

---

## 📜 License

This project is private. All rights reserved.

---

*Built with ❤️ using Flutter & Supabase*
