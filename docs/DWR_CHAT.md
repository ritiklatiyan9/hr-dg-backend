# DWR chat and AI DWR agent

Replaces the Phase 4 voice-to-AI transcription flow (removed 2026-09-25). Read with
PHASE4_CONTRACTS.md for the canonical report, review, print and reminder rules,
which are unchanged. Migration `0039_dwr_chat.sql` is additive; voice tables stay
only so previously retained audio keeps being deleted by the worker.

## Model

- **My DWR Agent** — every employee's private chat (`group_id` NULL). Opening
  DWR shows this chat for the whole current month, grouped by work date; earlier
  months are one tap away.
- **DWR groups** — WhatsApp-style site groups. Members see each other's messages;
  group **admins** (a membership role, not a catalogue permission) edit group
  details, add/remove members and make or dismiss admins. The last admin cannot be
  demoted or removed; when the last admin leaves, the longest-standing member
  becomes admin.
- **Sources** — everything an employee writes on a work date (personal chat and all
  groups at that site) is the source of _that employee's own_ DWR for the date. The
  work date is the site's calendar date when the server accepts the message; clients
  never choose it.
- **Report** — the existing canonical `dwr_reports` row (`origin='chat'`), its
  immutable history, review, amendment and print. AI never submits or approves:
  the employee submits; independent reviewers decide.

Messages are typed with the phone's own keyboard, so its microphone key dictates
Hindi, English or Hinglish without any app audio capture or microphone permission.

## Preparation (AI agent)

1. Every message insert/edit/delete queues the author's `(site, employee, date)` job
   due 10 minutes later (quiet period). "Prepare now" (author, DWR group editor or an
   admin of a shared group) makes it due immediately; group admins/HR can prepare a
   whole group's day.
2. The worker claims due jobs with a 60 s lease (`FOR UPDATE SKIP LOCKED`), rechecks
   the author's current site membership and `my_dwr.create`, the report lock and
   daily budgets, and reads at most the day's first 200 messages.
3. The selected provider receives messages as untrusted JSON with a strict JSON
   Schema and no tools. OpenRouter is the default (`OPENROUTER_DWR_MODEL`, optional
   pinned `OPENROUTER_DWR_PROVIDER`) with `require_parameters` and
   `data_collection: deny`. Groq is opt-in with `DWR_AI_PROVIDER=groq`,
   `GROQ_API_KEY` and a strict-schema-compatible `GROQ_DWR_MODEL`. Output is re-validated
   (`dwrAgentDraft`), numbers must appear in the employee's words, and obvious
   injection text never reaches the model. Transcript, status, identity, site and
   date are server-owned.
4. The store succeeds only if the lease still holds, access remains and the message
   digest is unchanged (otherwise it re-queues). It never overwrites a submitted or
   approved report, and an automatic run never overwrites the author's own edits
   (an explicit request does). The first preparation sends a `dwr.prepared` inbox item.
5. Failures keep a cooldown (Retry-After honoured), at most 5 attempts per content
   version; budgets default to 24 calls/employee/day and 2,000/organization/day.

Without a configured or running agent, the employee sends **the chat itself** as the
report ("Use chat as report"); reviewers read the messages. The worker writes a
heartbeat every 30 s; clients show _online_ only when it is fresh (< 90 s).

## Permissions (managed per user in Users & module access)

| Key                                          | Default                               | Meaning                                                                |
| -------------------------------------------- | ------------------------------------- | ---------------------------------------------------------------------- |
| `my_dwr.view` / `create` / `edit` / `submit` | all roles, own                        | see own chats and DWRs; send; edit own messages and DWR drafts; submit |
| `my_dwr.delete` (new)                        | all roles, own                        | delete own messages                                                    |
| `dwr_groups.view` (new module)               | Super Admin, Admin, HR, Jr. HR (site) | oversee every group and its chats at the site, read-only               |
| `dwr_groups.create`                          | same                                  | create groups                                                          |
| `dwr_groups.edit`                            | same                                  | edit any group, members and admins; prepare members' DWRs              |
| `dwr_groups.delete`                          | Super Admin, Admin, HR (site)         | archive groups; remove any group message (moderation)                  |
| `dwr_review.*`                               | unchanged                             | reviewers also read the author's messages for that report              |

`dwr_groups` is site-scope only (team/own/organization rejected by policy). Deny
overrides per user, as for every module. Job titles grant nothing.

## Invariants enforced in the database

- RLS: personal messages are visible to the author and to reviewers of that
  employee; group messages to active members of live groups, DWR group overseers
  and reviewers of the author. Groups/members follow the same membership rule.
- Triggers: authors edit only with `my_dwr.edit`, delete with `my_dwr.delete`;
  moderators may only delete group messages; a submitted/approved DWR locks that
  day's messages (`REPORT_LOCKED`); every edit/delete stores the previous text in
  `dwr_message_history`. Members cannot promote themselves or re-admit people;
  archiving needs `dwr_groups.delete`; archived groups are read-only.
- Column grants limit runtime updates to message body/deletion, member role/state
  and group details. Worker functions (`dwr_agent_*`) are granted to `hr_worker`
  only; `hr_runtime` cannot claim jobs or store AI output.
- Names come from `app.dwr_people`, which returns display names only for people
  the viewer shares a visible group with, may review, or themselves.

## API (GraphQL, strict schemas)

`dwrChat(siteId, input)` views: `home`, `thread` (month, `before` cursor pages of
150, `since` change polling), `group`, `candidates` (minimal labels), `day`
(an employee's sources for a date) and `daySummary` (group admins/overseers).

`dwrCommand(siteId, operation, input)` adds `message` (idempotent client ID),
`editMessage`/`deleteMessage` (optimistic version), `markRead`, `prepare`
(`ai` queue or `chat` transcript-only draft), `prepareGroup`, `createGroup`
(idempotent client ID), `updateGroup` (version), `addMembers`, `removeMember`,
`setMemberRole`, `leaveGroup`, `archiveGroup` (version + reason). Membership changes
serialize per group. The voice REST endpoints were removed.

## Clients

- Flutter: DWR opens **My DWR Agent** for the month; chats list with unread counts;
  group chat, long-press copy/edit/delete, optimistic sends with retry, day
  separators with your DWR status, a one-line "today's DWR" bar, group info with
  admin actions, new group, report review/submit. Polls every 5 s while visible.
- HR panel (shadcn/ui): Chats (two-pane, oversight read-only), Reports (review with
  the day's chat sources), Groups (table, create, members/admins sheet, archive),
  Settings (deadline/reminders and live agent status). Every chat message shows
  its sender's name and initials avatar; the thread keeps names from already
  loaded pages when a change poll returns only newer messages.

## Limits and open decisions

Polling (not push) delivers chat updates; message retention and deleted-text
history follow business-record retention, which still needs an approved policy;
AI quality for real Hindi/Hinglish speech-to-text via phone keyboards, model choice
and budgets require an approved provider account and measurement before rollout.
