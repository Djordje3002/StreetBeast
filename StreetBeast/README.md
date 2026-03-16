# Street Beast — Calisthenics Training App

## Product Structure
Street Beast is a calisthenics workout and competition app built around four core exercises. The app focuses on simple workouts, measurable progress, and friendly competition. Gamification elements such as XP, streaks, badges, and leaderboards motivate users to train consistently.

## Core Exercises
- Pull-ups
- Pushups
- Dips
- Muscle-ups

## Main Navigation
- Timer
- Progress
- Leaderboard
- Settings / Profile

## Onboarding Flow
The onboarding should be quick, motivating, and clear so users understand the app and start training immediately.

### Screen 1 — Welcome
Intro screen introducing the app.

Headline: Welcome to Street Beast

Short description: Street Beast helps you:
- track calisthenics workouts
- measure strength progress
- compete with other athletes

Primary button: Start

After tapping Start, the user chooses language (Serbian or English). No styling changes are required for the language choice screen.

### Screen 2 — Name
User enters their name or nickname.

Purpose: This name will appear on leaderboards and profile.

Input field: Name / nickname

Continue button.

### Screen 3 — Workout Level
Optional input.

Options:
- Beginner
- Intermediate
- Advanced

Used only for profile data and potential leaderboard filtering.

### Screen 4 — Current Max Strength
User inputs their maximum repetitions for the four core exercises.

Fields:
- Pull-ups max
- Pushups max
- Dips max
- Muscle-ups max

Purpose of these values:
- establish the user's starting strength level
- create a baseline for progress graphs
- place the user into leaderboards

After submitting these numbers the app should show positive feedback.

Example message: "You're already a beast. Let's get stronger."

User receives their first badge.

Example badge: Rookie Beast

This creates immediate motivation.

## Feature Walkthrough (3 Screens)
Instead of one explanation screen, the app presents three short slides, each highlighting one feature.

### Walkthrough Screen 1 — Workout Timer
Headline: Train with structured workouts.

Explanation: Start workouts with automatic timers that guide you through exercises and rest periods.

Visual concept: Workout timer counting down with exercises changing.

### Walkthrough Screen 2 — Track Progress
Headline: See your strength improve.

Explanation: Track max reps, workout volume, and XP with clear graphs and progress insights.

Visual concept: Graph rising over time.

### Walkthrough Screen 3 — Compete
Headline: Climb the leaderboard.

Explanation: Compare your max reps, XP, and dedication with other athletes.

Visual concept: Leaderboard ranking screen.

Final button: Enter Street Beast

## Main App Structure
Tab navigation with four tabs: Timer, Progress, Leaderboard, Settings / Profile.

### 1. Timer Tab
This is the most important feature of the app. The goal of this tab is to allow users to start workouts quickly.

Main layout: Large START WORKOUT button at the center. Below it, the user can choose a workout.

Examples:
- Beginner Workout
- Strength Builder
- Endurance Circuit
- Custom Workout

Workout Flow: User selects a workout.

Example structure:
- 5 rounds
- 10 pull-ups
- 20 pushups
- 15 dips
- 30 squats

Timer format example: 30 seconds work, 30 seconds rest.

During workout the screen shows:
- current exercise
- countdown timer
- next exercise preview

Example display:
PULL UPS
00:24
Next exercise: Pushups

Custom Workout Builder: Users can create and save their own workouts.

Options:
- choose exercises
- set repetitions or time
- set rest duration
- set number of rounds

Users can save workouts with a custom name. Example: Park Destroyer.

Workout Completion Screen: After finishing a workout the app shows a summary.

Displayed stats:
- total reps
- workout duration
- workout volume
- XP gained

Example: XP gained: 120. XP contributes to levels and leaderboards.

### 2. Progress Tab
Purpose: show clear improvement over time.

XP Graph: At the top of this screen there is an XP progression graph. This shows how the user's experience points grow over time and reflects consistency.

Strength Graphs: Track max reps across time.

Graphs for:
- Pull-ups
- Pushups
- Dips
- Muscle-ups

Performance Prediction: Based on recent workouts the app estimates future progress.

Example insight: "You are on track to reach 20 pull-ups in about 2 weeks." This can be based on a simple trend calculation.

Training Volume: Graph showing total reps completed per week.

Purpose: Visualize consistency and workload.

### 3. Leaderboard Tab
This section drives competition. There are three leaderboard categories.

Max Strength Leaderboard: Compares users based on their maximum reps.

Categories:
- Pull-ups
- Pushups
- Dips
- Muscle-ups

Example (Pull-ups leaderboard):
1 Marko — 32
2 Stefan — 29
3 Djordje — 26

XP Leaderboard: Ranks users based on total XP earned through workouts. Encourages frequent training.

Weekly Dedication: Ranks users by workouts completed in the current week.

Example:
1 Luka — 9 workouts
2 Nikola — 7 workouts
3 Djordje — 6 workouts

### 4. Settings / Profile
User profile contains identity, achievements, and progression.

Profile Information displays:
- name
- level
- total XP
- strength score

Example:
Djordje
Level 9
Strength Score: 740

Streak System: Tracks training consistency. Example: 6 day streak. If a day is missed the streak resets.

Achievements: Achievements unlock automatically.

Examples:
- First Workout
- First Muscle-up
- 100 Workouts Completed
- 30 Day Streak

Achievements appear with animations when unlocked.

Badges: Users earn badges for milestones.

Examples:
- Rookie Beast
- Pull-up Warrior
- Street Grinder
- Iron Discipline

Skill Tree: Visual progression tree representing calisthenics skills.

Example progression path:
Pull-ups
-> Chest-to-bar
-> Muscle-up

This shows long-term progression goals.
