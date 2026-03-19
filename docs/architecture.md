# DreamLoop System Architecture

This document describes the architecture for DreamLoop MVP.

The goal is fast development and minimal infrastructure.

---

## Frontend

Flutter mobile application.

Responsibilities:

- UI rendering
- user interaction
- authentication flow
- decision submission
- story display

---

## Backend

Firebase managed services.

Components:

Firebase Authentication
Firestore Database
Firebase Cloud Messaging

---

## Authentication

Users sign in using:

- Apple Sign In
- Google Sign In

User accounts are stored in Firebase Auth.

---

## Database

Firestore stores application state.

Collections:

users
sessions
events
choices

---

## Sessions

A session represents a shared story between two users.

Session document fields:

session_id
user_ids
current_event
options
choices
story_history

---

## Real-Time Sync

Firestore listeners update both clients when:

- choices are submitted
- events change

---

## AI Story Engine

The AI engine generates story events.

Provider:

OpenAI API

The system sends prompts requesting a story event with choices.

The response returns structured JSON.

---

## Notifications

Firebase Cloud Messaging sends push notifications when:

- new story events appear
- partner submits choice
- story progresses