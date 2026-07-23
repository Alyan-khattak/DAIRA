-- ============================================================
-- Daira Database Schema
-- Risk, fraud & underwriting engine for ROSCA committees
-- ============================================================
-- Run against the daira Postgres database:
--   psql -U daira -d daira -f schema.sql
-- ============================================================


-- ---------------- Extensions ----------------
-- uuid-ossp gives us uuid_generate_v4() for primary keys. UUIDs are
-- preferred over auto-increment integers for an API that external
-- platforms will integrate against -- they're globally unique, don't
-- leak row counts, and are safe to expose in URLs.
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";


-- ============================================================
-- 1. MEMBERS
-- ============================================================
-- A person in the system, independent of any committee they join.
-- One row per real human, identified by CNIC (national ID).
CREATE TABLE members (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name       VARCHAR(200)    NOT NULL,
    phone           VARCHAR(20),
    cnic            VARCHAR(15)     UNIQUE NOT NULL,   -- Pakistan national ID, natural key
    city            VARCHAR(100),
    date_of_birth   DATE,
    gender          VARCHAR(10),
    occupation      VARCHAR(100),
    monthly_income  DECIMAL(12, 2),                    -- feature for default model
    created_at      TIMESTAMP       DEFAULT NOW()
);

-- Fast lookup by CNIC since it's the real-world identifier people will
-- search by (e.g. "has this person defaulted before?").
CREATE INDEX idx_members_cnic ON members(cnic);


-- ============================================================
-- 2. COMMITTEES
-- ============================================================
-- A single ROSCA group. Defined by its contribution amount, frequency,
-- and number of rounds. The organizer is a member -- this FK lets us
-- query "how many committees does this person run?" which is a fraud signal.
CREATE TABLE committees (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    organizer_id        UUID            NOT NULL REFERENCES members(id),
    name                VARCHAR(200)    NOT NULL,
    contribution_amount DECIMAL(12, 2)  NOT NULL,      -- per-member per-round amount
    frequency           VARCHAR(20)     NOT NULL        -- weekly / monthly / bi-weekly
                        CHECK (frequency IN ('weekly', 'bi-weekly', 'monthly')),
    total_rounds        INTEGER         NOT NULL,
    total_members       INTEGER         NOT NULL,
    start_date          DATE            NOT NULL,
    end_date            DATE,
    status              VARCHAR(20)     DEFAULT 'active'
                        CHECK (status IN ('active', 'completed', 'defaulted', 'dissolved')),
    created_at          TIMESTAMP       DEFAULT NOW()
);

-- Query pattern: "show me all committees organized by member X"
CREATE INDEX idx_committees_organizer ON committees(organizer_id);


-- ============================================================
-- 3. MEMBERSHIPS (junction table: members <-> committees)
-- ============================================================
-- This is where the ML target variable lives. outcome is per-membership,
-- not per-member -- the same person can complete one committee and default
-- on another. payout_order determines when they receive the pot, which
-- directly affects their incentive to keep paying after collection.
CREATE TABLE memberships (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    member_id       UUID            NOT NULL REFERENCES members(id),
    committee_id    UUID            NOT NULL REFERENCES committees(id),
    payout_order    INTEGER         NOT NULL,          -- which round they collect the pot
    outcome         VARCHAR(20)                        -- ML target: null until resolved
                    CHECK (outcome IN (NULL, 'completed', 'defaulted', 'dropped_out')),
    status          VARCHAR(20)     DEFAULT 'active'
                    CHECK (status IN ('active', 'inactive', 'suspended')),
    joined_at       DATE            DEFAULT CURRENT_DATE,

    -- A member can only join the same committee once
    UNIQUE(member_id, committee_id)
);

CREATE INDEX idx_memberships_member ON memberships(member_id);
CREATE INDEX idx_memberships_committee ON memberships(committee_id);
-- Query pattern: "find all defaulted memberships" for training data extraction
CREATE INDEX idx_memberships_outcome ON memberships(outcome);


-- ============================================================
-- 4. CONTRIBUTION SCHEDULE (the plan)
-- ============================================================
-- Generated at committee creation time -- one row per member per round.
-- A 10-member, 10-round committee creates 100 rows here on day one.
-- This table is the "expectation"; payments table is the "reality".
CREATE TABLE contribution_schedule (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    membership_id   UUID            NOT NULL REFERENCES memberships(id),
    round_number    INTEGER         NOT NULL,
    due_date        DATE            NOT NULL,
    amount_due      DECIMAL(12, 2)  NOT NULL,

    -- Each membership has exactly one schedule entry per round
    UNIQUE(membership_id, round_number)
);

CREATE INDEX idx_schedule_membership ON contribution_schedule(membership_id);
-- Query pattern: "what's due this week?" for the payment tracking dashboard
CREATE INDEX idx_schedule_due_date ON contribution_schedule(due_date);


-- ============================================================
-- 5. PAYMENTS (the reality)
-- ============================================================
-- Links to contribution_schedule, NOT directly to membership. This is
-- deliberate: a schedule row with no matching payment row = missed payment.
-- That absence is the clearest signal for the default model.
CREATE TABLE payments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    schedule_id     UUID            UNIQUE NOT NULL REFERENCES contribution_schedule(id),
    amount_paid     DECIMAL(12, 2)  NOT NULL,
    paid_on         DATE            NOT NULL,
    payment_status  VARCHAR(20)     NOT NULL
                    CHECK (payment_status IN ('on_time', 'late', 'partial', 'missed')),
    days_late       INTEGER         DEFAULT 0,         -- 0 = on time, >0 = late by N days
    created_at      TIMESTAMP       DEFAULT NOW()
);

-- schedule_id is UNIQUE because each scheduled contribution can only be
-- paid once. If they pay partial and then top up, that's an update, not
-- a second row. This keeps the schedule-to-payment relationship strictly 1:1.

CREATE INDEX idx_payments_status ON payments(payment_status);


-- ============================================================
-- 6. MEMBER RELATIONSHIPS (graph edges for Phase 3 GNN)
-- ============================================================
-- Self-referencing many-to-many on members. Each row is an edge in the
-- social/trust network: "Member A and Member B are family."
-- The GNN will consume these as weighted edges with relationship_type
-- as an edge attribute.
CREATE TABLE member_relationships (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    member_a_id         UUID            NOT NULL REFERENCES members(id),
    member_b_id         UUID            NOT NULL REFERENCES members(id),
    relationship_type   VARCHAR(30)     NOT NULL
                        CHECK (relationship_type IN (
                            'family', 'friend', 'colleague',
                            'business_partner', 'neighbor'
                        )),
    trust_score         INTEGER         CHECK (trust_score BETWEEN 1 AND 10),

    -- Prevent duplicate edges: enforce a < b so the pair (A,B) can only
    -- exist once, not as both (A,B) and (B,A).
    CHECK (member_a_id < member_b_id),
    UNIQUE(member_a_id, member_b_id)
);

CREATE INDEX idx_relationships_a ON member_relationships(member_a_id);
CREATE INDEX idx_relationships_b ON member_relationships(member_b_id);


-- ============================================================
-- Useful queries for verification
-- ============================================================

-- Check a member's default history across all committees:
-- SELECT m.full_name, c.name AS committee, ms.outcome
-- FROM memberships ms
-- JOIN members m ON m.id = ms.member_id
-- JOIN committees c ON c.id = ms.committee_id
-- WHERE m.cnic = '3520212345678';

-- Find missed payments (schedule exists, no payment row):
-- SELECT cs.due_date, cs.amount_due, m.full_name
-- FROM contribution_schedule cs
-- JOIN memberships ms ON ms.id = cs.membership_id
-- JOIN members m ON m.id = ms.member_id
-- LEFT JOIN payments p ON p.schedule_id = cs.id
-- WHERE p.id IS NULL AND cs.due_date < CURRENT_DATE;

-- Network: find all connections for a given member:
-- SELECT
--     CASE WHEN mr.member_a_id = '<member_uuid>' THEN mr.member_b_id
--          ELSE mr.member_a_id END AS connected_member,
--     mr.relationship_type, mr.trust_score
-- FROM member_relationships mr
-- WHERE mr.member_a_id = '<member_uuid>' OR mr.member_b_id = '<member_uuid>';