# Mini-Games Design Document

## Overview

This document outlines the design for various mini-games that will be integrated into the gym tycoon game. These mini-games are designed to add variety, competitive elements, and additional rewards for players.

## Mini-Games

### 1. Basketball Shootout

*   **Name:** Basketball Shootout
*   **Concept:** A simple basketball shooting game where players try to score as many baskets as possible within a 60-second time limit. The distance to the basket increases with every 5 successful shots. The player controls the power and angle of the shot.
*   **Gameplay:**
    *   The player is presented with a basketball court with a marked shooting area.
    *   The player can control the power of the shot with a power bar and the angle with up and down inputs.
    *   The player can shoot by pressing a button.
    *   Each successful basket is counted.
    *   The distance to the basket increases every 5 successful shots.
    *   The game lasts for 60 seconds.
*   **Rewards:**
    *   In-game currency (based on score).
    *   Experience points.
    *   Special basketball-themed items (e.g., unique basketball skins, player titles) for top scores.
*   **UI/UX:**
    *   A clear timer in the corner of the screen.
    *   A score counter.
    *   A power bar to control the strength of the shot.
    *   A visual indicator of the shooting angle.
    *   A leaderboard to show top scores.
*   **Backend Connections**: `MiniGameSystem.StartBasketballGame`, `MiniGameSystem.EndBasketballGame`, `MiniGameSystem.GetBasketballLeaderboard`, `PlayerDataManager.addCurrency`, `PlayerDataManager.addExperience`, `PlayerDataManager.addReward`.
*   **Competitive**: Players can compete against each other for the highest score on a leaderboard.

### 2. Treadmill Endurance

*   **Name:** Treadmill Endurance
*   **Concept:** A speed and endurance challenge where players have to keep up with an increasing treadmill speed for as long as possible. The treadmill speed gradually increases over time.
*   **Gameplay:**
    *   The player is placed on a treadmill.
    *   The treadmill starts at a low speed and gradually increases over time.
    *   The player has to keep up with the speed by pressing a button repeatedly.
    *   If the player fails to keep up, they fall and the game ends.
    *   The game ends when the player falls or manually exits the game.
    *   The time the player was on the treadmill is recorded.
*   **Rewards:**
    *   In-game currency (based on time).
    *   Experience points.
    *   Special cardio-themed items (e.g., running shoes, sweatbands) for top times.
*   **UI/UX:**
    *   A clear timer showing how long the player has lasted.
    *   A speed indicator.
    *   A button prompt to show when the player needs to press the button.
    *   A leaderboard to show top times.
*   **Backend Connections**: `MiniGameSystem.StartTreadmillGame`, `MiniGameSystem.EndTreadmillGame`, `MiniGameSystem.GetTreadmillLeaderboard`, `PlayerDataManager.addCurrency`, `PlayerDataManager.addExperience`, `PlayerDataManager.addReward`.
*   **Competitive**: Players compete against each other for the longest time on a leaderboard.

### 3. Iron Will

*   **Name:** Iron Will
*   **Concept:** A strength-based mini-game where players try to lift a progressively heavier weight. The weight increases after each successful lift.
*   **Gameplay:**
    *   The player is presented with a weightlifting setup.
    *   The player has to lift the weight by pressing a button at the correct moment.
    *   Each successful lift increases the weight.
    *   If the player fails, the game ends.
    *   The game ends when the player fails or manually exits the game.
    *   The heaviest weight lifted is recorded.
*   **Rewards:**
    *   In-game currency (based on weight).
    *   Experience points.
    *   Special strength-themed items (e.g., weightlifting gloves, protein shake) for top weights.
*   **UI/UX:**
    *   A clear indicator of the current weight.
    *   A button prompt to show when the player needs to press the button.
    *   A leaderboard to show top weights.
*   **Backend Connections**: `MiniGameSystem.StartWeightliftingGame`, `MiniGameSystem.EndWeightliftingGame`, `MiniGameSystem.GetWeightliftingLeaderboard`, `PlayerDataManager.addCurrency`, `PlayerDataManager.addExperience`, `PlayerDataManager.addReward`.
*   **Competitive**: Players compete against each other for the heaviest weight lifted on a leaderboard.

### 4. Zen Master

*   **Name:** Zen Master
*   **Concept:** A balance and precision-based mini-game where players have to maintain a specific yoga pose for as long as possible.
*   **Gameplay:**
    *   The player is presented with a yoga mat.
    *   A specific yoga pose is shown to the player.
    *   The player has to maintain the pose by moving the mouse or the joystick.
    *   If the player fails to maintain the pose, the game ends.
    *   The game ends when the player fails or manually exits the game.
    *   The time the player maintained the pose is recorded.
*   **Rewards:**
    *   In-game currency (based on time).
    *   Experience points.
    *   Special flexibility-themed items (e.g., yoga pants, yoga mat) for top times.
*   **UI/UX:**
    *   A clear timer showing how long the player has maintained the pose.
    *   A visual indicator of the player's balance.
    *   A representation of the pose the player needs to maintain.
    *   A leaderboard to show top times.
*   **Backend Connections**: `MiniGameSystem.StartYogaGame`, `MiniGameSystem.EndYogaGame`, `MiniGameSystem.GetYogaLeaderboard`, `PlayerDataManager.addCurrency`, `PlayerDataManager.addExperience`, `PlayerDataManager.addReward`.
*   **Competitive**: Players compete against each other for the longest time maintaining the pose on a leaderboard.

### 5. Staff Challenge

*   **Name:** Staff Challenge
*   **Concept:** A mini game where players can challenge other players to compete with their staff to see whose is better.
*   **Gameplay:**
    *   The player can select a staff and challenge another player (or an NPC) to compare staff.
    *   The game will compare the staff's stats.
    *   The player with the best staff wins.
*   **Rewards**:
    *   In-game currency.
    *   Experience points.
    *   Special rewards for the staff.
*   **UI/UX**:
    *   A way to select a staff.
    *   A way to challenge a player (or an NPC).
    *   A result screen to show who won.
    *   An animation of the staff competing against each other.
*   **Backend Connection**: `MiniGameSystem.StartStaffChallenge`, `MiniGameSystem.EndStaffChallenge`, `StaffManager.GetStaffStats`, `PlayerDataManager.addCurrency`, `PlayerDataManager.addExperience`, `PlayerDataManager.addReward`.
*   **Competitive**: Players compete against each other to see whose staff is the best.

## General Information

*   **General Backend Connections**:
    *   `MiniGameSystem.GetAvailableGames`: Returns a list of all the available games.
*   **General UI/UX**:
    *   All the minigames will be accessed through a `Minigames Menu`.
    *   All minigames will be able to be played by both NPCs and players.
    *   Add a clear description on how to play in each mini game.
    *   Use a consistent and attractive art style.
    *   Use good animations to make the minigames feel more alive.
    *   Add sound effects to make the minigames feel more alive.
*   **General Rewards**: All the minigames will provide similar types of rewards. This will include in-game currency, experience and special rewards.