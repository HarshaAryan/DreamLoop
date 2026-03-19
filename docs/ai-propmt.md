# DreamLoop AI Prompt Design

This document defines how AI generates story events.

---

## AI Prompt Template

The system sends a prompt requesting a story event.

Example prompt:

Generate a short fantasy adventure event for two players.

Return JSON in the following format:

{
event: "",
options: ["", "", ""]
}

---

## Example Output

{
event: "A glowing cave appears near your village.",
options: [
"Enter the cave",
"Camp outside",
"Send a drone inside"
]
}

---

## Story Style

Events should be:

- short
- imaginative
- slightly mysterious
- **highly dependent on memory** (every past action builds the future plot)
- **completely flexible** with no prefixed ending (can span 3-4 days)
- inclusive of deep emotional exchanges and bonding sessions

Tone should rotate between:

- cute
- adventurous
- mysterious
- spooky

---

## Event Length

Event descriptions should be between 1 and 3 sentences.

Options should be short actions.

---

## Choice Design

Each event must include exactly 3 choices.

Choices should represent different strategies and force players to reveal their real personalities. Mix:
- Adventure
- Horror/Risk
- Emotional empathy or sacrifice
- Hard psychological choices

Example:

attack the shadow (Aggressive)
offer it a memory (Emotional)
flee into the dark (Horror)