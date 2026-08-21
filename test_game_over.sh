#!/bin/bash
sed -i 's/func take_damage(amount: float):/func take_damage(amount: float):\n\tprint("Core taking damage! amount: ", amount, ", current hp: ", hp)/g' project/scripts/CoreBuilding.gd
sed -i 's/gm.change_state(gm.GameState.GAME_OVER)/print("GAME OVER TRIGGERED")\n\t\tgm.change_state(gm.GameState.GAME_OVER)/g' project/scripts/CoreBuilding.gd
