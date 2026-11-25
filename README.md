# Task Management & Ticket Raising System

[![PHP Version](https://img.shields.io/badge/PHP-8.2%2B-777BB4?logo=php&logoColor=white)](https://www.php.net)
[![CodeIgniter](https://img.shields.io/badge/CodeIgniter-4.7.5-EF4223?logo=codeigniter&logoColor=white)](https://codeigniter.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-12%2B%20%2F%2018.1-4169E1?logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![Bootstrap](https://img.shields.io/badge/Bootstrap-5.3-7952B3?logo=bootstrap&logoColor=white)](https://getbootstrap.com)
[![Chart.js](https://img.shields.io/badge/Chart.js-4.4-FF6384?logo=chartdotjs&logoColor=white)](https://www.chartjs.org)
[![PHPUnit](https://img.shields.io/badge/Tests-23%20passed%20%7C%20165%20assertions-success)](https://phpunit.de)

**Task Management & Ticket Raising System** is a centralized, production-oriented enterprise web application that unifies **Software Product/Module Management**, **Hierarchical Task Tracking**, and **Client Support Ticket Raising & Triage**. Built with strict role-based access control (RBAC), daily progress updates with historical preservation, task dependency graph validation, role-tailored dashboards with real-time Chart.js visualizations, 10 detailed reports with CSV streaming exports, active Gmail SMTP email alerts, browser desktop push notifications, and secure client support ticket self-service with SHA-256 token authentication.

---

## Table of Contents

1. [Architecture & System Overview](#architecture--system-overview)
2. [Key Functional Modules](#key-functional-modules)
3. [Technology Stack & Requirements](#technology-stack--requirements)
4. [Step-by-Step Installation & Setup](#step-by-step-installation--setup)
5. [Database Schema & Migrations](#database-schema--migrations)
6. [Demo Accounts & Credentials](#demo-accounts--credentials)
7. [API Route Reference](#api-route-reference)
8. [Automated Testing Suite](#automated-testing-suite)
9. [Troubleshooting & PostgreSQL Notes](#troubleshooting--postgresql-notes)
10. [Production Deployment Considerations](#production-deployment-considerations)

---

## 1. Architecture & System Overview

Seldon follows an MVC + Service Layer architecture pattern for separation of concerns:

- **Presentation Layer (Views)**: Bootstrap 5 responsive layout, Bootstrap Icons, Chart.js for data visualizations, and vanilla JavaScript (`public/assets/js/app.js`) leveraging the Fetch API and CSRF protection.
- **Controller Layer (`app/Controllers`)**: Validates HTTP input, delegates business rules to domain services, and renders views or JSON API responses.
- **Middleware & Security Layer (`app/Filters`)**:
  - `AuthFilter`: Enforces session authentication and redirects unauthorized requests to `/login`.
  - `RoleFilter`: Restricts route groups based on role hierarchy (`admin`, `coordinator`, `developer`).
  - `RateLimitFilter`: Throttles brute force login attempts and public support ticket spam using IP-based request windows.
- **Domain Service Layer (`app/Services`)**:
  - `TaskService`: Manages task creation, module-product integrity, reassignment history, daily progress recording, status transitions, and circular dependency graph checks.
  - `TicketService`: Handles public ticket submission, SHA-256 token hashing, client lookup isolation, ticket triage, and ticket-to-task conversion.
  - `ReportService`: Calculates metrics for all 3 dashboards, executes 10 complex analytical queries, and streams CSV exports.
  - `AuditService`: Maintains immutable audit trail of actions across all entities.
- **Data Access Layer (`app/Models`)**: 14 CodeIgniter 4 models mapped to PostgreSQL 12+ relational tables.

---

## 2. Key Functional Modules

### 2.1 Role-Based Access Control (RBAC)
- **Admin**: Full system management (users, products, modules, statuses, tasks, tickets, reports, audit logs).
- **Coordinator**: Task creation, assignment, ticket triage, status changes (including formally closing tasks), and all reports.
- **Task Member / Developer**: View assigned tasks, record daily progress (0–100%), submit comments, mark task completed, and view tickets assigned to them.
- **Public Client**: Submit support tickets without an account, receive a 48-character secure token, check status, and reply to support staff.

### 2.2 Products & Hierarchical Modules
- Products represent software platforms (e.g. *Attendance Management System*, *Customer Relationship Management*, *Payroll Processing Platform*).
- Modules represent functional subsystems (e.g. *Email Notifications*, *Biometric Sync*, *Invoice Generation*).
- **Strict Validation**: A task or ticket can only be created with a module that belongs directly to the selected product. The UI dynamically populates modules via an AJAX endpoint when the product dropdown changes.

### 2.3 Task Lifecycle Management
- **Statuses**: `Created` &rarr; `Assigned` &rarr; `In Progress` &rarr; `Completed` &rarr; `Closed`.
- **Completed vs. Closed Distinction**:
  - `Completed`: Marked by the assigned developer when development/QA work is 100% finished.
  - `Closed`: Formally verified and accepted by an **Administrator** or **Coordinator**. Developers cannot close tasks.
- **Progress Tracking (0–100%)**:
  - Every update records: date, previous %, new %, work completed, remaining work, and blockers.
  - Historical records are preserved in `task_progress_updates` (never overwritten).
  - Updating progress automatically moves `Created`/`Assigned` tasks to `In Progress` (> 0%) or `Completed` (100%).

### 2.4 Task Dependencies & Graph Validation
- Tasks can declare prerequisites (`Task B depends on Task A`).
- **Circular Dependency Detection**: Breadth-First Search (BFS) graph traversal checks any new dependency. If adding a link causes an infinite cycle (A &rarr; B &rarr; A or A &rarr; B &rarr; C &rarr; A), the request is rejected with a validation error.
- **Blocker Warnings**: If a developer begins or completes a task whose prerequisites are not completed/closed, a blocker alert is raised.

### 2.5 Client Support Portal & Ticket-to-Task Conversion
- **Public Submission**: Clients submit tickets (`client_name`, `client_email`, `company`, `product`, `module`, `subject`, `description`, `priority`).
- **Secure Token Hashing**:
  - Generates a 48-character random token (`bin2hex(random_bytes(24))`).
  - Stores only `hash('sha256', $rawToken)` in PostgreSQL.
  - The client receives the raw token once. Internal database compromise never exposes client credentials.
- **Strict Comment Privacy**:
  - Internal notes (`is_internal = true`) are strictly visible to staff only.
  - Client lookup queries explicitly filter out internal notes.
- **Ticket to Task Conversion**:
  - Coordinators can convert a ticket to an internal engineering task in one click.
  - Links `linked_task_id`, automatically updates ticket status, and records an internal note. Duplicate conversion is prevented.

### 2.6 Active Notifications & Coordinator Awareness
- **Gmail SMTP Alerts**: Real-time branded HTML emails dispatched automatically to coordinators upon new ticket submission with priority color badges, client details, and a direct triage link.
- **Browser Desktop Push (Web Notification API)**: Dispatches native operating system desktop alerts (Windows Action Center / macOS Notifications) when a ticket is submitted, even if the user is in another tab.
- **In-App Toast & Audio Chime**: Synthesizes a two-tone alert chime via Web Audio API and displays live Bootstrap 5 floating toasts in the bottom-right corner.
- **Dynamic Live Badges**: Polling mechanism automatically updates the top navbar bell count, sidebar badge counter, and browser tab title `(count)`.
- **Diagnostic Endpoint**: Built-in test endpoint at `/api/notifications/test-email` to verify SMTP connectivity and credentials.

### 2.7 Reporting Engine (10 Reports + CSV Export)
1. **Daily Task Report**: Progress updates recorded on a specific date.
2. **Monthly Task Report**: Aggregated creation, completion, and closure rates by product per month.
3. **Employee Performance Report**: Workload, completion rate, overdue tasks, and total logged hours.
4. **Product Progress Report**: Total tasks, completion percentages, and estimated hours per product.
5. **Module-wise Task Report**: Breakdown of tasks across product modules.
6. **Task Status Distribution**: Visual counts and average progress per status.
7. **Overdue Task Report**: Identifies tasks past their due date that are not completed/closed with calculated days overdue.
8. **Task Assignment History Report**: Chronological log of assignments and reassignments with notes.
9. **Completed & Closed Task Report**: Tasks completed and closed with duration analysis.
10. **Support Ticket Report**: Ticket resolution metrics, assignee workload, and linked engineering tasks.

---

## 3. Technology Stack & Requirements

| Component | Minimum Version | Verified Version |
| :--- | :--- | :--- |
| **PHP** | 8.2.0+ | **8.2.12** |
| **PostgreSQL** | 12.0+ | **18.1** |
| **Composer** | 2.0+ | **2.10.3** |
| **CodeIgniter** | 4.4+ | **4.7.5** |
| **Bootstrap** | 5.3+ | **5.3.3** |
| **Chart.js** | 4.0+ | **4.4.2** |
| **PHPUnit** | 10.0+ | **10.5.66** |

### Required PHP Extensions
In your `php.ini`:
```ini
extension=intl
extension=mbstring
extension=pdo_pgsql
extension=pgsql
extension=zip
extension=openssl
extension=curl
```

---

## 4. Step-by-Step Installation & Setup

### Step 1: Clone Repository & Install Dependencies
```bash
git clone <repository_url> Seldon
cd Seldon
composer install --no-dev --optimize-autoloader
```

### Step 2: Configure PostgreSQL Databases
Create the application database and test database:
```sql
CREATE DATABASE seldon_db;
CREATE DATABASE seldon_db_test;
```

### Step 3: Configure Environment Variables
Copy `env` to `.env` and verify database credentials:
```ini
CI_ENVIRONMENT = development

app.baseURL = 'http://localhost:8080/'
app.forceGlobalSecureRequests = false

database.default.hostname = 127.0.0.1
database.default.database = seldon_db
database.default.username = postgres
database.default.password = postgres
database.default.DBDriver = Postgre
database.default.port     = 5432
database.default.charset  = utf8

database.tests.hostname = 127.0.0.1
database.tests.database = seldon_db_test
database.tests.username = postgres
database.tests.password = postgres
database.tests.DBDriver = Postgre
database.tests.port     = 5432
database.tests.charset  = utf8

# Email & Active SMTP Notifications
email.fromEmail = 'your-email@gmail.com'
email.fromName = 'Task & Ticket Support System'
email.protocol = 'smtp'
email.SMTPHost = 'smtp.gmail.com'
email.SMTPUser = 'your-email@gmail.com'
email.SMTPPass = 'your-16-character-google-app-password'
email.SMTPPort = 587
email.SMTPCrypto = 'tls'
email.mailType = 'html'

# Coordinator Notification Recipient
coordinator.notificationEmail = 'coordinator@example.com'
```

### Step 4: Run Migrations & Seeders
```bash
# Execute database schema migration (17 tables, foreign keys, indexes)
php spark migrate

# Seed roles, permissions, demo users, products, modules, statuses, tasks, and tickets
php spark db:seed MainSeeder
```

### Step 5: Start Development Server
```bash
php spark serve --port 8080
```
Open your browser at `http://localhost:8080`.

---

## 5. Database Schema & Migrations

The database includes 17 tables configured with strict foreign keys, cascade rules, check constraints, and performance indexes:

| Table | Description |
| :--- | :--- |
| `roles` | System roles (`admin`, `coordinator`, `developer`). |
| `permissions` | Granular capability definitions. |
| `role_permissions` | Pivot table mapping roles to permissions. |
| `users` | User accounts with bcrypt password hashes and role associations. |
| `products` | Top-level software platforms. |
| `modules` | Functional subsystems belonging to a specific product. |
| `task_statuses` | Status workflow with `is_completed` and `is_closed` flags. |
| `tasks` | Core task entity with estimate, actual hours, dates, and progress. |
| `task_assignments` | Immutable audit log of every assignment and reassignment. |
| `task_progress_updates` | Daily progress history (0–100%), accomplishments, and blockers. |
| `task_comments` | Discussion threads on tasks. |
| `task_dependencies` | Directed acyclic graph (DAG) of prerequisite relationships. |
| `support_tickets` | Client tickets with SHA-256 access token hashes and linked tasks. |
| `ticket_status_history` | Audit trail of ticket lifecycle transitions. |
| `ticket_comments` | Client messages and internal staff-only notes (`is_internal`). |
| `audit_logs` | Comprehensive security and administrative audit trail. |

---

## 6. Demo Accounts & Credentials

The database seeder pre-populates the following accounts for evaluation. The login screen (`/login`) also includes quick-fill buttons for each role:

| Role | Email | Password | Primary Capabilities |
| :--- | :--- | :--- | :--- |
| **Administrator** | `admin@seldon.local` | `Admin@123456` | Full system control, user & product management, reports |
| **Coordinator** | `coordinator@seldon.local` | `Coord@123456` | Task assignment, ticket triage, task closure, reports |
| **Developer (John)** | `john.dev@seldon.local` | `Dev@123456` | Daily progress updates (0–100%), task completion |
| **Developer (Jane)** | `jane.dev@seldon.local` | `Dev@123456` | Daily progress updates, QA reviews |
| **Developer (Bob)** | `bob.dev@seldon.local` | `Dev@123456` | Task progress updates, comments |

---

## 7. API Route Reference

### Authentication & Public Support
- `POST /api/auth/login` — Authenticate and receive user object.
- `POST /api/auth/logout` — Invalidate current session.
- `GET /api/auth/me` — Retrieve active authenticated user profile.
- `POST /api/public/tickets` — Submit a public support ticket (returns raw token).
- `GET /api/public/tickets/status?ticket_number=...&token=...` — Retrieve ticket status with token authentication.
- `GET /api/products/{id}/modules` — Retrieve active modules belonging to product.

### Tasks & Tickets
- `GET /api/tasks` — List tasks with filters (`product_id`, `status_id`, `assigned_to`, `priority`).
- `POST /api/tasks` — Create a new task (enforces module-product validation).
- `GET /api/tasks/{id}` — Get task details, assignment history, progress records, comments, dependencies.
- `POST /api/tasks/{id}/progress` — Record daily progress (0–100%) with blockers.
- `POST /api/tasks/{id}/assign` — Reassign task with audit notes.
- `POST /api/tasks/{id}/transition` — Transition task status (enforces closure authorization).
- `POST /api/tasks/{id}/comments` — Add comment to task.
- `GET /api/tickets` — List support tickets.
- `POST /api/tickets/{id}/assign` — Assign ticket to developer.
- `POST /api/tickets/{id}/transition` — Update ticket status (`Submitted`, `Assigned`, `In Progress`, `Resolved`, `Closed`).
- `POST /api/tickets/{id}/comments` — Add internal note or client response.

### Reports API (Admin & Coordinator)
- `GET /api/reports/dashboard` — Get dashboard metrics and chart series.
- `GET /api/reports/tasks` — Filtered task data.
- `GET /api/reports/employees` — Employee performance and workload statistics.
- `GET /api/reports/export?type=daily|monthly|employee|product|module|status|overdue|tickets` — Stream CSV file download.

---

## 8. Automated Testing Suite

The application includes an automated test suite executed with PHPUnit 10:

```bash
# Run all tests
vendor/bin/phpunit

# Run with detailed TestDox summary
vendor/bin/phpunit --testdox
```

### Test Coverage Highlights
- **`AuthenticationTest`**: Password hashing, admin account presence, role associations, and case-insensitive email lookup.
- **`TaskWorkflowTest`**:
  - Rejects modules not belonging to selected product.
  - Rejects progress updates `< 0` and `> 100`.
  - Preserves daily progress historical updates without overwriting.
  - Tracks reassignment history and previous assignee.
  - Distinguishes between `Completed` and `Closed` states; enforces that only Admin/Coordinator can close tasks.
  - Detects and prevents circular task dependencies using BFS cycle check.
  - Warns when prerequisite tasks are incomplete.
- **`SupportTicketTest`**:
  - Generates unique ticket numbers (`TCK-XXXX`) and 48-char tokens.
  - Verifies SHA-256 hash storage; raw token is never saved in the database.
  - Isolates client comments: clients cannot view internal staff notes.
  - Converts tickets to internal engineering tasks and prevents duplicate conversion.
- **`ReportAndMetricsTest`**:
  - Verifies dashboard metrics for Admin, Coordinator, and Developer roles.
  - Validates query execution for all 10 required business reports.
  - Tests CSV export generation and header formatting.
- **`RoleAccessControlTest`**:
  - Redirects unauthenticated requests from protected routes to `/login`.
  - Permits public access to `/support`, `/support/lookup`, and `/login`.
  - Enforces 403 / Access Denied when developers attempt to access Admin routes (`/users`, `/products`, `/statuses`).
  - Verifies Coordinator and Admin access permissions.

---

## 9. Troubleshooting & PostgreSQL Notes

1. **Client Encoding**: PostgreSQL requires `charset = 'utf8'` in `app/Config/Database.php` and `.env`. Do not use MySQL's `utf8mb4`.
2. **Boolean Evaluation**:
   PostgreSQL PDO returns boolean columns as `'t'` or `'f'` strings. In PHP, `boolval('f') === true`. The application uses the `isTrue()` helper (`in_array($val, [true, 't', 'true', '1', 1], true)`) to prevent falsy booleans from being evaluated as true.
3. **Database Connection in Test Mode**:
   When writing tests extending `CIUnitTestCase`, CodeIgniter switches models to the `'tests'` connection (`seldon_db_test`). Services use `$this->model->db` rather than `Database::connect()` to ensure database transactions operate on the active test connection.

---

## 10. Production Deployment Considerations

1. **Environment**: Set `CI_ENVIRONMENT = production` in `.env` to disable debug toolbars and error backtraces.
2. **Base URL & HTTPS**: Configure `app.baseURL = 'https://yourdomain.com/'` and enable `app.forceGlobalSecureRequests = true`.
3. **Web Server Document Root**: Configure Nginx or Apache to point the virtual host root to the `public/` directory (never the project root).
4. **Rate Limiting**: The `RateLimitFilter` is enabled on sensitive endpoints (15 requests/minute on login, 10 requests/minute on public tickets). Tune these thresholds in `app/Config/Filters.php` based on your expected traffic.
5. **Database Connection Pooling**: For high concurrency, configure PgBouncer in front of PostgreSQL.
