# Scope Guard

## Tagline
Scope Guard helps teams track scope changes, protect margins, and keep client delivery transparent.

## Summary
Scope Guard is a responsive Flutter application that combines client management, request tracking, analytics, billing visibility, and team operations with Firebase-backed real-time data. The app supports mobile, tablet, and desktop/web layouts with adaptive navigation, Material 3 styling, and consistent reusable UI patterns.

## Live Web App
- Live web app: https://scope-guard-290a0.web.app/
- Example: https://scope-guard-290a0.web.app/

## GitHub Repository
- Repo: https://github.com/farhanbaeem-web/scope_guard

## Mission
Our mission is to help teams avoid scope creep and make client work predictable, profitable, and transparent. We provide fast visibility into requests, approvals, and outcomes so teams can decide with confidence.

## Vision
We envision a world where every team can measure scope impact in real time, communicate changes clearly, and automate approvals without friction. Scope Guard aims to become the standard layer between work requests and billable outcomes.

## Motive
Scope creep silently drains time and revenue. Many teams track requests in email threads or spreadsheets, which makes it hard to know what is in scope, what is pending approval, and what has real cost. Scope Guard centralizes the process and keeps a live record that prevents surprise work.

## Values
- Clarity: make scope status visible and understandable.
- Speed: reduce time from request to decision.
- Accountability: keep decision history and documentation in one place.
- Simplicity: a straightforward workflow that works on any device.
- Trust: ensure data access is scoped to each user.

## Audience
- Freelancers who need to keep client work aligned.
- Agencies managing multiple clients and approvals.
- Product teams tracking change requests across stakeholders.
- Account managers monitoring scope impact and margins.

## Use Cases
- Track incoming client requests and mark in-scope or out-of-scope.
- Create approval workflows for extra work before execution.
- Generate reports to communicate scope changes and revenue impact.
- Monitor risky clients and pending work from a single dashboard.
- Maintain a log of activity, decisions, and communication notes.

## Product Positioning
Scope Guard sits between project tracking and billing. It does not replace PM tools; instead, it captures scope decisions, change requests, and approvals that PM tools often miss.

## Key Differentiators
- Real-time, Firestore-based updates across all devices.
- Focused request lifecycle with in-scope toggles.
- Reporting built around out-of-scope visibility.
- Lightweight and fast UI across mobile and web.

## Feature Overview
- Dashboard with KPIs and quick actions.
- Clients list with filters, sorting, and risk flags.
- Client detail with KPIs, request list, and reports.
- Requests hub for all out-of-scope items across clients.
- Analytics hub and insights views.
- Reports hub and PDF generation workflow.
- Integrations management with connection status.
- Billing and subscription summaries.
- Activity feed and audit log.
- Notifications with read/unread management.
- Support tickets and FAQ.
- Settings, security, and data retention screens.

## UX Principles
- Minimal cognitive load.
- Clear status indicators and filters.
- Consistent spacing, typography, and elevation.
- Responsive layouts that avoid overflow.
- Subtle animations that respect reduced-motion settings.

## Architecture Summary
The project is organized by features and shared core utilities. Each feature owns its UI, data models, and service layer where needed. Real-time Firestore streams drive list screens via StreamBuilder.

## Project Structure
- lib/
  - app.dart
  - core/
    - platform/
    - routing/
    - theme/
    - utils/
  - features/
    - auth/
    - clients/
    - requests/
    - analytics/
    - reports/
    - billing/
    - integrations/
    - dashboard/
    - activity/
    - notifications/
    - exports/
    - support/
    - settings/
    - team/
  - shared/
    - widgets/

## Core Modules
- app.dart sets up MaterialApp.router and app-wide configuration.
- core/platform contains responsive layout helpers.
- core/routing contains go_router definitions and transitions.
- core/theme defines colors and typography.
- core/utils provides formatting, validation, and helper utilities.

## Data Model Overview
Data is stored per user under users/{uid}. Each sub-collection is scoped to the authenticated user, ensuring multi-tenant isolation.

## Firestore Structure
- users/{uid}
  - clients/{clientId}
    - requests/{requestId}
    - reports/{reportId}
    - contract/meta
    - communications/{noteId}
  - activity/{activityId}
  - notifications/{notificationId}
  - integrations/{integrationId}
  - exports/{exportId}
  - supportTickets/{ticketId}
  - settings/meta

## Example Client Fields
- name: string
- project: string
- contractType: string
- createdAt: timestamp
- risky: bool
- notes: string
- totalRequests: number
- outOfScopeCount: number

## Example Request Fields
- title: string
- description: string
- inScope: bool
- approvalStatus: string
- estimatedCost: number
- createdAt: timestamp

## Example Report Fields
- title: string
- outOfScopeCount: number
- totalExtra: number
- createdAt: timestamp

## Example Activity Fields
- title: string
- detail: string
- type: string (info, success, warning, danger)
- createdAt: timestamp
- clientId: string (optional)

## Example Notification Fields
- title: string
- body: string
- type: string (info, warning, danger)
- read: bool
- createdAt: timestamp

## Example Support Ticket Fields
- message: string
- status: string (open, closed)
- createdAt: timestamp

## Example Integration Fields
- name: string
- description: string
- connected: bool
- iconName: string
- color: int
- updatedAt: timestamp

## Example Export Fields
- title: string
- format: string (PDF, CSV, XLSX)
- status: string (processing, ready)
- includeCharts: bool
- downloadUrl: string
- createdAt: timestamp

## Example Settings Fields
- notifications.emailAlerts: bool
- notifications.pushAlerts: bool
- notifications.weeklySummary: bool
- security.twoFactor: bool
- appearance.darkMode: bool
- plan: string
- updatedAt: timestamp

## Authentication
Firebase Authentication is required for Firestore access. Anonymous Auth is used by default, and users can be upgraded to Email/Password accounts.

### Anonymous Auth (Default)
- Creates a temporary Firebase Auth user silently.
- Provides a real uid so data can be stored immediately.
- Best for trial onboarding and low-friction access.

### Limitations of Anonymous Accounts
- Losing the device or signing out can orphan the account.
- No multi-device login unless the account is upgraded.
- Not ideal for long-term or enterprise usage.

### Upgrade to Full Accounts
- Enable Email/Password provider in Firebase Auth.
- Use signup/login screens to create persistent users.
- Link anonymous users to a permanent credential to preserve data.

## Routing
Routing is managed by go_router with consistent transitions.

### Public Routes
- /splash
- /onboarding
- /login
- /signup
- /forgot
- /verify-email

### Authenticated Routes
- /
- /clients
- /requests
- /analytics
- /reports
- /integrations
- /billing
- /insights
- /profile
- /notifications
- /activity
- /support
- /exports
- /team
- /settings

### Client Routes
- /clients/add
- /clients/:id
- /clients/:id/requests/:requestId
- /clients/:id/requests/add
- /clients/:id/activity
- /clients/:id/notes
- /clients/:id/contract
- /clients/:id/reports

## Responsive Design
The UI adapts to screen size with defined breakpoints and a constrained content width. Mobile uses a drawer or bottom navigation, while desktop uses a sidebar layout.

### Guidelines
- Avoid fixed widths.
- Use Responsive helpers for spacing and radii.
- Use Wrap and Flexible layouts for chips and cards.
- Ensure scrollable containers for long content.

## Animations
Animations are subtle and used for:
- Page transitions (fade + slide).
- List item entry (staggered fade/slide).
- Empty state fade-ins.

Reduced-motion is respected via MediaQuery settings.

## UI Components
Reusable components standardize the experience:
- AppScaffold
- Sidebar and Drawer
- NavTile
- SectionHeader
- AppTextField
- EmptyState
- StatusPill
- RequestTile
- KPI cards
- Client cards

## Dashboard
The dashboard highlights totals, out-of-scope revenue, quick actions, and recent clients. It includes a get-started callout when no clients exist.

## Clients
The clients area supports search, sorting, and risk flags. It includes a detail view with KPIs, request list, and reports.

## Requests Hub
A unified list of out-of-scope requests across all clients. Includes filters, sorting, and total potential revenue.

## Analytics
Analytics provide KPI summaries and a breakdown of out-of-scope cost buckets. Insights and forecast screens extend the view.

## Reports
Reports hub is a landing page for generating client reports. Client detail allows PDF generation.

## Integrations
Integration cards show connection status and allow toggling. Filters and sorting help manage large lists.

## Billing
Billing screens show invoices, subscription details, and plan status.

## Activity
Activity logs show a timeline of changes. The audit view provides filtering and search.

## Notifications
Notifications are real-time, with read/unread support, filters, and bulk actions.

## Exports
Exports show status, format, and download options. The UI includes filters, search, and confirmation on deletion.

## Support
Support includes contact cards, FAQ, and a ticketing interface. Tickets are searchable and mutable in real time.

## Settings
Settings offer account preferences, notification controls, and security toggles. Changes are saved to Firestore and tracked with a dirty state.

## Error Handling
- Loading states use consistent spinners.
- Empty states show helpful calls to action.
- Error states provide context and retry actions where possible.

## Accessibility
- All buttons and icons include tooltips where appropriate.
- Touch targets follow Material guidance.
- Text contrast adheres to the theme palette.

## Security Notes
- Firestore rules should restrict access to users/{uid}.
- No cross-user data access is allowed by design.
- Sensitive actions prompt for confirmation.

## Firebase Setup
1) Create a Firebase project.
2) Enable Auth providers as needed.
3) Enable Firestore and configure rules.
4) Add platform configs to Android/iOS/Web.
5) Run FlutterFire to generate options.

## FlutterFire Setup
```
flutterfire configure
```

## Firestore Rules (Example)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Local Development
```
flutter pub get
flutter run -d chrome
```

## Web Build
```
flutter build web --release
```

## Testing
- Manual UI validation on multiple screen sizes.
- Ensure auth state updates routing.
- Validate Firestore rules in emulator if needed.

## Deployment Notes
- Web output is in build/web.
- Configure hosting via Firebase Hosting or any static host.
- Update environment configs per platform.

## Troubleshooting
- If routes redirect unexpectedly, verify auth state and email verification.
- If lists are empty, ensure Firestore data exists under the correct uid.
- If web build fails, confirm Flutter version and web config files.

## Roadmap
- Role-based permissions for teams.
- Advanced approvals and signatures.
- Multi-workspace support.
- PDF template customization.
- Enhanced analytics charts.

## Future Work Plan
Phase 1: Foundation
- Harden auth flows (account linking, session recovery, device transfer).
- Finalize Firestore rules, indexes, and data validation.
- Add automated tests for core flows and routing.

Phase 2: Workflow Depth
- Expand approvals (multi-step, comments, signatures).
- Add request templates at client level and bulk actions.
- Improve reporting exports with custom branding and layout.

Phase 3: Intelligence
- Add predictive insights and trend alerts.
- Expand analytics with cohort and client-level comparisons.
- Introduce anomaly detection for scope creep spikes.

Phase 4: Scale
- Multi-workspace and role-based permissions.
- Audit-grade logs with retention policies.
- Admin controls for integrations and data retention.

## Contribution Guidelines
- Keep files ASCII where possible.
- Use existing widgets and helpers for new UI.
- Avoid introducing extra state management unless necessary.
- Keep screens responsive and scrollable.

## License
Add your preferred license here.

## Contact
Provide a team email or support channel for contributors and users.
## Appendix: Additional Notes
- Detail line 001
- Detail line 002
- Detail line 003
- Detail line 004
- Detail line 005
- Detail line 006
- Detail line 007
- Detail line 008
