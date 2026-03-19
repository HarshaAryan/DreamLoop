# DreamLoop Story Engine Design

## Purpose

This document defines how the DreamLoop AI story engine should behave.

The story engine is responsible for generating interactive narrative events for two users.

The system must support long evolving stories that adapt to user choices.

The AI must not generate a fixed beginning-to-end story.

Instead, it must generate **incremental story events** that react to player actions.

---

# Core Story Philosophy

DreamLoop stories are **living narratives**, not fixed scripts.

A story is shaped entirely by the decisions made by the two players.

The AI should generate the next story moment based on:

- previous story events
- player choices
- emotional context
- world state

Stories should evolve organically.

---

# Story Duration

A single story session should last **multiple days**.

Typical story length:

- 3 to 4 days
- depending on user interactions

Each story contains multiple narrative moments.

Each moment is triggered when both players submit choices.

---

# Story Structure

A story consists of multiple **story moments**.

Each moment contains:

1. narrative description
2. three player choices
3. resulting emotional or environmental impact

Example moment:

Event:
"You discover a glowing cave hidden behind a waterfall."

Choices:
- Enter the cave
- Wait outside
- Send a drone inside

The next event depends on the choices.

---

# No Fixed Ending

Stories should not have predetermined endings.

The AI must dynamically create:

- new situations
- evolving conflicts
- emotional events
- environmental changes

The story may eventually conclude naturally, but it should not be pre-written.

---

# Player Memory System

Every action taken by the players must be stored.

This memory is used by the AI to generate future events.

Examples of stored memory:

- choices made
- relationships formed
- risks taken
- emotional decisions

Example memory record:

Player chose to trust a mysterious traveler.

Future story events may reference this.

---

# Story Memory Usage

The AI should receive the following context when generating events:

- previous events
- player choices
- session summary

Example prompt context:

Previous events:
Players rescued a dragon.
Players explored a cave.

Recent choices:
Players decided to trust a stranger.

The AI should incorporate this information.

---

# Emotional Events

Stories should include moments of emotional bonding.

Examples:

- watching the night sky
- sitting by a campfire
- helping a lost creature
- sharing memories

These events strengthen the emotional connection between players.

---

# Moral Choice Events

Some story events should test player values.

Examples:

- help a stranger or ignore them
- share resources or keep them
- save a creature or chase treasure

These moments reveal personality.

---

# Adventure Events

Adventure events include exploration and discovery.

Examples:

- hidden caves
- mysterious ruins
- abandoned cities
- secret portals

These maintain excitement.

---

# Horror and Mystery Events

Rare events should introduce tension.

Examples:

- haunted forests
- ghostly signals
- strange noises at night
- cursed artifacts

These moments should be rare but memorable.

---

# Tone Balance

Story events should follow this approximate distribution:

Cute / cozy moments: 35%
Adventure: 35%
Emotional bonding: 15%
Mystery: 10%
Horror: 5%

This keeps the story engaging without becoming too dark.

---

# Story Pacing

The story should gradually escalate in complexity.

Early stages:

- exploration
- discovery
- curiosity

Middle stages:

- deeper mysteries
- relationship building
- challenges

Later stages:

- major conflicts
- emotional decisions
- meaningful outcomes

---

# Event Length

Each event should be short and readable.

Maximum length:

1–3 sentences.

The event must be readable in a mobile notification context.

---

# Choice Design

Each event must contain exactly three choices.

Choices must represent different strategies.

Examples:

fight
negotiate
observe

Avoid obvious "correct" choices.

All choices should feel valid.

---

# Session Summary

After several events, the system should generate a session summary.

Example:

"After three days of exploration, you and your partner discovered an ancient temple and befriended a small dragon."

This summary can help the AI maintain story coherence.

---

# Replayability

Each pair of players should experience a unique story.

The combination of:

- AI generation
- player decisions
- stored memory

should ensure that no two sessions are identical.

---

# System Requirements

The story engine must support:

- incremental story generation
- context-aware prompts
- player memory storage
- multi-day narratives

The architecture must allow storing and retrieving story memory for each session.