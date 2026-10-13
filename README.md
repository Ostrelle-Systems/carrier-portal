# carrier-portal

Customer-facing dashboard for the Ostrelle Systems logistics platform. Lets carriers and shipping customers track shipments, view SLA status, and manage account settings.

**Stack:** TypeScript, Next.js, Prisma

## Prerequisites

- Node.js 24+
- PostgreSQL (or MySQL) instance for the app database

## Local setup

```bash
npm install
cp .env.example .env        # set DATABASE_URL and APP_SECRET
npm run build-db            # generate Prisma client + run migrations
npm run dev                 # starts dev server on :3000
npx prisma studio           # browse the database
```

## Production build

```bash
npm run build
npm start
```

## Testing

```bash
npm run test
npm run lint
```

## Related services

- `shipment-tracker` — source of truth for shipment status shown here
- `dispatch` — SLA data surfaced on the customer dashboard
