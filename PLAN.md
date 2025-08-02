context
@weapon_tiers.json 
Here's the change to make: populate the starting items for Ranger and Mage from this JSON file.

Make it so when you pick up weapons now you can't pick them up with the E key anymore, and you're just set for weapons because we'll give them as rewards later. 

Regarding how the teirs work, we'll make it so that every second loop will be more like a weapon. 

In terms of order, it'll go:
1. Weapon
2. Stats
3. Armor
4. Stats
5. Weapon

repeating

This is kind of broken up into 3 pieces of work.
1. Updating the starting items
2. Making sure you can't pick up weapons anymore with the E key
3. Updating the existing reward system to follow that pattern 

Your goal is to write the code for this.
How confident are you 0-100 in writing this code with the current information?But first lets scope this out, is anything about this unclear to you about the requirements?Have any questions about this task before we start?@new_hero_screen.dart 
...

# Weapon System Overhaul Plan

## Notes
- Three main subtasks: update starting items, disable weapon pickup, update reward system order.
- Starting weapons for each class (ranger, mage) are specified in weapon_tiers.json under "starting".
- Weapon pickup with the E key should be disabled; weapons are now only given as rewards.
- Reward order should be: 1. Weapon, 2. Stats, 3. Armor, 4. Stats, 5. Weapon, then repeat.
- Outstanding clarifications needed from user:
  - Should mages receive weapon rewards (JSON has empty arrays), or skip weapon rewards in the cycle?
  - Should weapons still spawn on# Weapon System Overhaul Plan

## Notes
- Three main subtasks: update starting items, disable weapon pickup, update reward system order.
- Starting weapons for each class (ranger, mage) are specified in weapon_tiers.json under "starting".
- Weapon pickup with the E key should be disabled; weapons are now only given as rewards.
- Reward order should be: 1. Weapon, 2. Stats, 3. Armor, 4. Stats, 5. Weapon, then repeat.
- Outstanding clarifications needed from user:
  - Should mages receive weapon rewards (JSON has empty arrays), or skip weapon rewards in the cycle?
  - Should weapons still spawn on the ground but be unpickupable, or not spawn at all?
  - Should the new reward cycle fully replace the current stat-only rewards, or be integrated alongside them?

## Task List
- [ ] Update starting items for ranger and mage from weapon_tiers.json
- [ ] Disable picking up weapons with the E key
- [ ] Update the reward system to follow the new reward order

## Current Goal
Update starting items for ranger and mage; weapons should not spawn on the ground (or be unpickupable).
  - Should the new reward cycle fully replace the current stat-only rewards, or be integrated alongside them?

## Task List
- [ ] Update starting items for ranger and mage from weapon_tiers.json
- [ ] Disable picking up weapons with the E key
- [ ] Update the reward system to follow the new reward order

## Current Goal
Update starting items for ranger and mage
