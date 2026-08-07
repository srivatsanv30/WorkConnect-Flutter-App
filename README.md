# WorkConnect

Minimal Flutter starting point for the WorkConnect app.

## Folder structure

```
lib/
  main.dart              entry point
  core/                  theme, constants, shared config
  features/
    auth/                login/signup, profile
    jobs/                job posting, job list
    collaboration/       chat, file sharing, meeting links
    tracking/             milestones, task status
    ai/                  AI skill match, task breakdown, mentor
  shared/
    widgets/             reusable UI pieces
assets/
  images/
```

## First-time setup

This folder was hand-built (no Flutter SDK available where it was generated),
so you need to let Flutter regenerate the platform folders (android/, ios/, etc.)
and install packages:

```bash
cd workconnect
flutter create .
flutter pub get
flutter run
```

`flutter create .` is safe to run inside an existing project — it fills in
the missing platform scaffolding without touching your lib/ folder.

## Next steps

1. Stand up the Node.js + Express + MongoDB backend separately (suggest a
   sibling folder like `workconnect-backend/`, not inside this Flutter project).
2. Update `lib/core/constants.dart` with your backend's base URL.
3. Build out `features/auth` with real JWT/Google login calls.
4. Add `features/jobs/create_job_screen.dart` for the job posting form.
