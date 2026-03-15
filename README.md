# UNIPASS — Digital Campus ID & Attendance System

> A full-stack mobile + backend application for university digital identity and attendance management.

![Flutter](https://img.shields.io/badge/Frontend-Flutter-02569B?style=flat-square&logo=flutter)
![Node.js](https://img.shields.io/badge/Backend-Node.js-339933?style=flat-square&logo=node.js)
![MySQL](https://img.shields.io/badge/Database-MySQL-4479A1?style=flat-square&logo=mysql)
![Express](https://img.shields.io/badge/API-Express.js-000000?style=flat-square&logo=express)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=flat-square)

---

## Overview

UNIPASS is a university digital campus ID and attendance system. Students and lecturers get a QR-code-based digital ID, and lecturers can generate time-limited attendance codes that students submit through the app. Admins manage all user accounts through a dedicated dashboard.

---

## Features

### All Users
- Login with role-based routing (Student / Lecturer / Admin)
- Auto-login using `SharedPreferences` session persistence
- Personal QR code containing encoded profile info
- Emergency contacts with one-tap calling

### Students
- View profile, department, and major
- Enroll in and unenroll from courses
- Submit attendance using a lecturer-issued code

### Lecturers
- View profile and manage courses (add/delete)
- Generate a **6-character attendance code** (valid for 15 minutes)
- View attendance records by course and date

### Admins
- Search users by ID
- Create new student/lecturer accounts
- Edit user info (name, department, major)
- Reset user passwords
- Delete users

---

## Architecture

```
┌─────────────────────────┐        ┌──────────────────────────┐
│   Flutter Mobile App     │◄──────►│    Node.js REST API      │
│   (lib/)                 │  HTTP  │    (Express.js)          │
└─────────────────────────┘        └────────────┬─────────────┘
                                                │
                                   ┌────────────▼─────────────┐
                                   │       MySQL Database      │
                                   └──────────────────────────┘
```

---

## Project Structure

```
unipass/
│
├── backend/                        # Node.js API server
│   ├── index.js                    # Entry point, middleware, route mounting
│   ├── db.js                       # MySQL connection pool (dotenv)
│   └── routes/
│       ├── auth.js                 # Register & Login
│       ├── student.js              # Profile, enroll, unenroll
│       ├── lecturer.js             # Profile, add/delete course
│       ├── attendance.js           # Generate code, submit, view, export
│       └── admin.js                # CRUD user management
│
└── lib/                            # Flutter app
    ├── main.dart                   # App entry point
    ├── services/
    │   └── api.dart                # HTTP client (GET/POST/PUT/DELETE)
    └── screens/
        ├── login_page.dart         # Login with role routing + auto-login
        ├── register_page.dart      # Self-registration (student/lecturer)
        ├── student_home.dart       # Student tabs: Profile, QR, Attendance, Emergency
        ├── lecturer_home.dart      # Lecturer tabs: Profile, QR, Generate, View, Emergency
        ├── admin_dashboard.dart    # Admin: search, edit, reset password, delete
        ├── create_user_page.dart   # Admin: create new user
        ├── edit_user_page.dart     # Admin: edit user details
        └── search_user_page.dart   # Admin: search user by ID
```

---

## API Endpoints

### Auth — `/api/auth`

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/register` | Register new student or lecturer |
| `POST` | `/login` | Login for all roles (student, lecturer, admin) |

### Student — `/api/student`

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/profile/:student_id` | Get profile + enrolled courses |
| `POST` | `/enroll` | Enroll in a course |
| `POST` | `/unenroll` | Unenroll from a course |

### Lecturer — `/api/lecturer`

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/profile/:lecturer_id` | Get profile + courses taught |
| `POST` | `/add-course` | Add a course |
| `POST` | `/delete-course` | Delete a course |

### Attendance — `/api/attendance`

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/generate` | Generate attendance code (15 min validity) |
| `POST` | `/submit` | Student submits attendance code |
| `GET` | `/view?course_id=&date=` | View attendance records |
| `GET` | `/export?course_id=&date=` | Export attendance to `.xlsx` |

### Admin — `/api/admin`

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/user/:id` | Get user by ID |
| `POST` | `/create-user` | Create new user |
| `PUT` | `/user/:id` | Update user fields |
| `PUT` | `/user/:id/reset-password` | Reset user password |
| `DELETE` | `/user/:id` | Delete user |

---

## Database Tables

| Table | Key Columns | Description |
|-------|------------|-------------|
| `users` | `id, name, password, role, major, department, photo_url` | All students & lecturers |
| `admins` | `admin_id, name, password` | Admin accounts (separate table) |
| `courses` | `course_id, course_name, lecturer_id` | Course registry |
| `enrollments` | `student_id, course_id` | Student-course mappings |
| `attendance_codes` | `course_id, code, created_by, valid_until` | Time-limited codes |
| `attendance` | `student_id, student_name, course_id, code_used, submitted_at` | Attendance records |

---

## App Screens

### Student (`StudentHome`)
| Tab | Content |
|-----|---------|
| Profile | Photo, name, ID, department, major, enrolled courses, enroll/unenroll |
| QR | Personal QR code with encoded ID, name, major, department |
| Attendance | Submit attendance code from lecturer |
| Emergency | University contacts with tap-to-call |

### Lecturer (`LecturerHome`)
| Tab | Content |
|-----|---------|
| Profile | Photo, name, ID, department, courses list, add/remove courses |
| QR | Personal QR code with encoded ID, name, department |
| Generate | Generate 6-char attendance code, display with 15-min timer |
| View | View attendance records by course + date |
| Emergency | University contacts with tap-to-call |

### Admin (`AdminDashboard`)
- Search user by ID
- View/edit user name, department, major
- Reset password
- Delete user (with confirmation dialog)
- Navigate to Create User page

---

## Getting Started

### Prerequisites
- Flutter SDK (3.x or higher)
- Node.js (18.x or higher)
- MySQL database

### Backend Setup

```bash
cd backend
npm install
```

Create a `.env` file:

```env
DB_HOST=your_db_host
DB_PORT=3306
DB_USER=your_db_user
DB_PASS=your_db_password
DB_NAME=unipass
PORT=3000
```

Run the server:

```bash
node index.js
```

### Flutter Setup

```bash
cd lib
flutter pub get
flutter run
```

>  **Important:** The API base URL in `api.dart` is set to `http://10.0.2.2:3000/api` (Android emulator localhost). Change this to your actual server IP when deploying to a real device.

---

## Dependencies

### Backend (`package.json`)

| Package | Purpose |
|---------|---------|
| `express` | Web framework |
| `mysql2` | MySQL client with Promise support |
| `dotenv` | Environment variable loading |
| `cors` | Cross-origin request support |
| `body-parser` | JSON request parsing |
| `exceljs` | Export attendance to `.xlsx` |

### Flutter (`pubspec.yaml`)

| Package | Purpose |
|---------|---------|
| `http` | HTTP requests to API |
| `qr_flutter` | QR code generation |
| `shared_preferences` | Session persistence (auto-login) |
| `url_launcher` | Tap-to-call emergency contacts |

---

## Known Limitations

- Passwords are stored in **plain text** — no hashing (e.g. bcrypt) implemented
- No JWT or token-based authentication; API endpoints are unprotected
- Hardcoded local admin fallback (`admin123` / `pass123`) in `login_page.dart`
- API base URL is hardcoded for Android emulator (`10.0.2.2`)
- Emergency phone numbers are placeholder (`+66 xxx xxx xxx`)
- Attendance code validity (15 min) is server-side only — no countdown shown in the app

---

## Future Improvements

-  Hash passwords with `bcrypt`
-  Add JWT authentication middleware to protect API routes
-  Make API base URL configurable (e.g., via `.env` or build flavor)
-  Show countdown timer on generated attendance codes
-  Add QR code scanner for attendance submission
-  Add push notifications for upcoming classes
-  Replace placeholder emergency numbers with real contacts

---

## Author

Developed as a Flutter + Node.js full-stack university project.
