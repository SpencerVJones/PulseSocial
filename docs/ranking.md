# Pulse Feed Ranking V1

This document defines the first non-chronological ranking model for the Pulse feed.

## Goal

Move the default feed from a simple reverse-chronological list to a lightweight ranking system that is:

- deterministic
- explainable
- cheap enough to evolve
- compatible with client-side or backend-side computation

## Entity Model

Ranking applies to feed items, not only original posts.

- Original posts are rankable feed items
- Reposts are separate feed items
- Reposts keep a reference to the original post
- The original content and the repost event can score differently

This allows the system to reflect both content quality and distribution behavior.

## Ranking Inputs

The initial score is a weighted combination of four features:

1. Recency
2. Relationship strength
3. Engagement velocity
4. Circle affinity

## Proposed Score

```text
score =
  (recencyWeight * recencyScore) +
  (relationshipWeight * relationshipScore) +
  (engagementWeight * engagementScore) +
  (circleWeight * circleAffinityScore)
```

Initial default weights:

```text
recencyWeight = 0.40
relationshipWeight = 0.25
engagementWeight = 0.20
circleWeight = 0.15
```

These values are intentionally simple. They are a baseline, not a final tuned model.

## Feature Definitions

### 1. Recency Score

Recency should decay smoothly over time instead of dropping off in hard buckets.

Example direction:

```text
recencyScore = exp(-ageInHours / decayConstant)
```

This preserves freshness while still letting strong posts survive longer than a strict chronological feed would allow.

### 2. Relationship Score

Relationship strength estimates how relevant the actor is to the viewer.

Candidate signals:

- follows each other
- prior likes
- prior comments
- repeat profile visits
- direct interaction frequency

The first version can stay simple:

```text
relationshipScore = normalized interaction count over last N days
```

### 3. Engagement Velocity Score

This measures how quickly a post is gaining traction, not just total engagement.

Candidate signals:

- likes per hour
- comments per hour
- reposts per hour
- early reaction rate

This avoids overvaluing old posts that accumulated engagement slowly over time.

### 4. Circle Affinity Score

Pulse already has circles. The ranking model should reflect whether the viewer consistently engages with a given circle.

Candidate signals:

- likes in that circle
- comments in that circle
- posts created in that circle
- dwell time on circle content

This helps make community-specific content feel more relevant.

## Tie-Breaking

Sorting should remain stable and deterministic.

Use:

1. `score` descending
2. `createdAt` descending
3. `postId` descending

Using `createdAt + postId` avoids unstable ordering for items with equal scores.

## Computation Strategy

Two valid approaches:

### Option A: Backend Precompute

- Compute features and score in a backend job or Cloud Function
- Persist the final score onto the feed item
- Client reads already-ranked items

Pros:

- cheaper client logic
- easier consistency across devices
- better for larger scale

Cons:

- more backend complexity
- more write amplification

### Option B: Client-Side Compute

- Read raw feature fields
- Compute score in the app
- Sort locally before rendering

Pros:

- easier to iterate early
- no ranking backend required

Cons:

- more client complexity
- potential cross-device inconsistencies if the feature snapshot differs

Recommended near-term path:

- start with client-side ranking for iteration speed
- move to backend precompute once feed scale or experimentation demands it

## Reposts

Reposts are not treated as the same row as the original post.

- A repost is a separate feed entity
- It references the original post
- It can rank based on:
  - repost recency
  - relationship to the reposter
  - performance of the original content

This keeps the timeline model explicit and easier to reason about.

## Debuggability

For development builds, the app should expose a simple debug view showing:

- final score
- per-feature contribution
- item age
- rank position

That makes ranking changes testable instead of guesswork.

## Versioning

This document describes `ranking_v1`.

Future versions should:

- keep old logic documented
- track weight changes
- document rollout behavior behind feature flags or experiments
