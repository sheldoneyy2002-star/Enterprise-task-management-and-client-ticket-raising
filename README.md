# Enterprise-task-management-and-client-ticket-raising
Enterprise task management and client ticket raising web app built with CodeIgniter 4 and PostgreSQL. Features hierarchical product/module tracking, RBAC, daily progress logging with DAG dependency checks, public ticket self-service with SHA-256 tokens, active Gmail SMTP email alerts, and desktop push notifications.

Task Management & Ticket Raising System is a centralized enterprise web application that unifies Software Product/Module Management, Hierarchical Task Tracking, and Client Support Ticket Raising & Triage.

🚀 Key Highlights & Modules
Public Client Ticket Raising: Clients submit issues with priority tagging and receive a secure 48-character SHA-256 token to track progress without logging in.
Active Coordinator Alerts:
Gmail SMTP Alerts: Immediate HTML email notifications dispatched to coordinators with color-coded priority badges and direct triage links.
Browser Desktop Push: Real-time OS notifications (Windows Action Center / Mac) via the Web Notification API and synthesized audio chime.
Live Counters: Dynamic navbar bell, sidebar badges, and browser tab title updates.
Hierarchical Tasks & Graph Validation: Strict product/module scoping and BFS-driven circular dependency prevention.
Daily Progress Logging: Historical preservation of progress updates (0–100%), blockers, and logged hours.
10 Analytical Reports: Full reporting engine with CSV streaming exports and role-tailored dashboards.
Diagnostic Verification Endpoint: Built-in /api/notifications/test-email to verify SMTP connectivity and credentials.
🛠️ Tech Stack
Backend: PHP 8.2+, CodeIgniter 4.7.5
Database: PostgreSQL (12+ / 18.1)
Frontend: Bootstrap 5.3, Bootstrap Icons, Chart.js 4.4, Vanilla JavaScript
Email: Native CodeIgniter Email Service (Gmail SMTP / TLS 587)
