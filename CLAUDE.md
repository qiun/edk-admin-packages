# EDK Admin Packages - Claude Code Instructions

## Project Overview

Rails 8.1 monolithic web app for managing EDK (Ekstremalna Droga Krzyżowa) package logistics — ordering, distributing, and shipping packages for the annual EDK event across Poland.

### Tech Stack
- **Backend**: Ruby on Rails 8.1.1, PostgreSQL
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS v4, TailAdmin dashboard template
- **Auth**: Devise 4.9 | **Authorization**: Pundit 2.3 | **Pagination**: Pagy 9.3
- **JS**: importmap-rails (no Node.js bundler)
- **Shipping**: aPaczka API (Faraday) | **Payments**: Przelewy24
- **PDF**: Prawn + Prawn::Table
- **Testing**: RSpec, FactoryBot, Shoulda Matchers
- **Linting**: RuboCop (rails-omakase)
- **Deployment**: Docker, Kamal, Kubernetes, Thruster

### Application Namespaces
| Namespace | Path | Description |
|-----------|------|-------------|
| Admin | `/admin` | Full system administration — editions, orders, shipments, donations |
| Warehouse | `/warehouse` | Warehouse shipment management |
| Leader | `/leader` | Regional leaders — area groups, regions, allocations, payments, transfers |
| Public | `/` | Public donation pages |

### Key Domain Models
- **Edition** — annual event edition (central config entity)
- **User** — multi-role (admin, warehouse, leader) via Devise
- **AreaGroup** — district managed by a leader (`leader_id` FK → User)
- **Region** — sub-area within AreaGroup for a specific Edition
- **RegionAllocation** — package allocation per region
- **Order** — leader's package order (pending → confirmed → shipped → delivered/cancelled)
- **Payment** — payment tracking (pending → completed/failed)
- **Shipment** — aPaczka shipment (pending → processing → shipped → delivered/error)
- **Donation** — public donations with own shipment flow

## Git

- Two remotes: `origin` (GitHub) and `gitlab` (GitLab)
- After every commit, always push to both remotes:
  ```
  git push origin main && git push gitlab main:master
  ```
- GitLab uses `master` branch (mapped from local `main`)

## Commands

```bash
bin/dev                              # Start dev server (Rails + Tailwind watcher)
bin/rails tailwindcss:build          # One-time Tailwind build
bundle exec rspec                    # Run all tests
bundle exec rspec spec/models/       # Run model specs only
bin/rubocop                          # Run linter
bin/rubocop -a                       # Auto-fix safe violations
```

## Code Conventions

- **Language**: All UI text in Polish (hardcoded, not full I18n). Translations for status badges in `config/locales/pl.yml`
- **Views**: ERB templates. Admin views use modern Tailwind utilities. Leader views use TailAdmin legacy classes (`bg-primary`, `border-stroke`, `dark:bg-boxdark`) aliased in `app/assets/tailwind/application.css`
- **Services**: organized by external API in `app/services/` (e.g. `apaczka/`, `przelewy24/`)
- **Status badges**: `status_badge(status, context)` with contexts `:order`, `:payment`, `:shipment`
- **Linting**: RuboCop rails-omakase config (`.rubocop.yml`)

## Key Files

- `app/assets/tailwind/application.css` — Tailwind CSS v4 theme (colors, shadows, breakpoints + TailAdmin legacy aliases)
- `config/routes.rb` — all routes, 4 namespaces
- `app/helpers/application_helper.rb` — `status_badge` helper
- `app/services/apaczka/client.rb` — aPaczka API client
- `config/locales/pl.yml` — Polish translations

## Known Gotchas

- TailAdmin legacy color classes (`bg-primary`, `border-stroke`, `dark:bg-boxdark`) must be aliased in Tailwind v4 `@theme` block — otherwise buttons/borders invisible
- PG sequence out of sync after manual inserts: `SELECT setval('table_id_seq', (SELECT COALESCE(MAX(id), 0) FROM table))`
- `bin/rails runner` with `!` methods in inline strings — write to tmp file first, then `bin/rails runner tmp/script.rb`
