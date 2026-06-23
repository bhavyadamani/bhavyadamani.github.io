---
layout: post
title: "Dataverse Storage Optimization — Lessons from the Trenches"
date: 2026-06-20
categories: [Dynamics 365, Power Platform, Dataverse]
tags: [dataverse, storage, d365, governance, optimization]
author: Bhavya Damani
---

# Dataverse Storage Optimization — Lessons from the Trenches

If you have worked on Dynamics 365 CE or Power Platform long enough, you already know how Dataverse storage quietly creeps up — until one fine day the admin centre starts shouting, finance starts asking questions, and someone in the leadership chain types the dreaded line: *"why are we paying so much for storage?"*

Over the last year I have run multiple Dataverse Storage Capacity Assessments across very different customers — banking, education, retail, BPO, manufacturing. The size of the environments varied, the industries varied, the maturity varied. But the **storage hot-spots were almost the same in every single case.**

This post is a brain-dump of those patterns. Not a vendor pitch. Not "buy more capacity." Just what I keep seeing on the ground, and what actually works to bring the numbers down.

## The usual suspects (you will see these 9 times out of 10)

Almost every assessment ends up flagging the same handful of tables. If you are doing your own internal review, start here:

### 1. Audit Size

This is the **single most common critical finding** in my reports. Audit is enabled at organisation level, then at entity level, then at field level — and nobody trims it. Years of changes pile up.

What I usually recommend:
- Decide what truly needs auditing (regulatory + investigation use cases)
- Disable audit on fields that change too often and have no business value (timestamps, system flags, derived fields)
- Use the bulk delete jobs to purge old audit records on a schedule
- Where retention is non-negotiable, look at the Long Term Retention feature — that was a game changer for one of my recent engagements

### 2. PrincipalObjectAccess (POA)

POA is the silent killer. It grows when you share records, when you use hierarchical security, or when ownership churns. I have seen POA single-handedly hold **45 GB+** in a mid-size customer.

Quick wins:
- Review security roles before sharing records manually
- Avoid sharing where a team would do the job
- For very large POA, raise a Microsoft support case — they can help identify and clean orphan rows

### 3. ActivityPointerBase

Every email, phone call, task, appointment ends up here. It just grows. Most organisations never archive activities older than 2–3 years even though nobody opens them.

Approach:
- Define an activity retention policy (1 year, 2 years, whatever fits)
- Bulk delete in batches (small batches, off-peak)
- For email body & attachments specifically — see point 5 below

### 4. Dataverse Search / Relevance Search index

A misunderstood one. People enable Dataverse Search on every entity "just in case" — and the index quietly consumes storage. 

What helps:
- Audit which entities are actually searched by users (the index is for *user* search, not your code)
- Remove entities from the index that nobody searches
- Re-index after cleanup

### 5. Attachments and the Email body trap

D365 stores attachments and large email bodies in Dataverse by default. For high-volume Customer Service environments this gets ugly fast.

The fix is almost always the same:
- Use SharePoint document management for attachments (native integration, well documented)
- For inbound email bodies, move to server-side sync with selective storage rules
- Consider Azure Blob storage for archival

### 6. Workflow / Plugin Trace / Async Operation logs

These are diagnostic tables. They should be small. When they are large, somebody left tracing on after a debugging session, or the org-level plugin trace setting is "All".

Action:
- Plugin Trace Log = `Exception` only (not `All`) in production
- Bulk delete old workflow logs on a weekly schedule
- Same for AsyncOperation rows where state is completed/succeeded

## A few patterns that surprised me

A few things I did NOT expect to see this often:

- **Conversation Transcript** tables ballooning in environments where Copilot or Customer Service is enabled. Worth a retention policy.
- **Trace Log Base** in environments where Managed Environment features are heavily used.
- Customers on **2.5 / 5 storage score** despite never having migrated bulk data — it was always the logs.

## The realistic optimisation playbook

If you only do five things, do these:

1. **Run an assessment first.** You cannot fix what you cannot see. Microsoft has tools, but even a simple Capacity report from the Power Platform Admin Center gives you the top tables.
2. **Tackle logs before data.** Audit, Plugin Trace, Workflow Log — these are easy wins and reversible.
3. **Get attachments out of Dataverse.** SharePoint integration is free and battle-tested.
4. **Treat security model and POA as a storage problem too.** Most teams treat them only as a security problem. It is both.
5. **Make retention a policy, not a project.** A clear retention statement ("activities older than 24 months are bulk-deleted monthly") is worth more than 10 cleanup scripts.

## What you should NOT do

A few "shortcuts" I keep seeing fail:

- Deleting records from the UI in bulk during business hours (kills performance, hits API limits)
- Disabling audit globally to "save space" (compliance team will wake up)
- Buying more capacity instead of fixing the cause (you will be back here in 6 months)
- Writing a custom archival solution before checking if Long Term Retention covers the scenario

## Closing thought

Storage optimisation is not glamorous work. It is not Copilot, it is not AI agents, it is not the slide deck headline. But it is exactly the kind of housekeeping that keeps a Dataverse environment healthy and your CFO calm.

If you are starting your own review, I would say: **pick one table, fix it end-to-end, measure the drop, then move to the next.** Trying to fix everything in one sprint usually ends in nothing being fixed.

Happy cleaning. And if you have your own war stories — share them. We are all dealing with the same beast.

---

*Posted on bhavyadamani.github.io · Views are my own.*