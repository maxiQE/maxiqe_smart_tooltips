# MaxiQE informative tooltips

Do you want to actually understand how battles work? This mod gives you all the information you need, right in the tooltip.

## Key features

- View all character stats on the battlefields, even as they get modified by injury, morale effects, etc.
- View all enemy abilities, equipment and perks. No more surprises.
- Get information about the damage your attack could cause. Try to break your highscores!
- Get information about the chance of killing your enemy with an attack and planify your turns accordingly.
- View all factors that impact your chance of hitting your enemy.
- Get important warnings about immunities and dangerous abilities.

## Installation

To install the mod, download the zip file and put it into the games data folder, along with its dependencies:

- [Modern hooks](https://github.com/MSUTeam/Modern-Hooks/releases) ([Nexus mods link](https://www.nexusmods.com/battlebrothers/mods/685))
- [Modding standards and utilities](https://github.com/MSUTeam/MSU/releases) ([Nexus mods link](https://www.nexusmods.com/battlebrothers/mods/479))
- [Nested tooltips](https://github.com/MSUTeam/nested-tooltips/releases) (Not on Nexus mods)
- [Tooltip extension](https://www.nexusmods.com/battlebrothers/mods/536)

## Compatibility

1. This mod overwrites the default tactical tooltip function, to avoid interference. It it is not compatible with other tooltip mods.
1. This mod should be compatible with most other mods, unless they mess with the damage formula or do something extremely weird around it.

Please let me know about any issues you run into. I'll see if I can fix them.

# How it works

## Actor information

Actor information code is coming straight from the reforged mod.
Huge thanks to the authors of this mode for letting me reuse their code.

The code itself is fairly straightforward.
We just iterate over the relevant information and format it appropriately for display.

## Damage prediction

Damage prediction relies on a thorough rewritting of the damage formula from the base game.
It should be a perfect match, but let me know if you find any issues.

To compute the expected damage and the kill chance, I have tried the following approaches:

1. sum over all possible values of the armor and health rolls. This is too slow for all weapons with a wide damage spread.
1. do a Monte Carlo simulation: roll a large number of armor and health rolls, and compute their mean. This is fine but not very precise. This is used for mult-hit weapons and split-man since exact approaches are impossible.
1. sub-sampled sum. Instead of summing over all values, we compute a grid of values covering the range of possible values. This is relatively accurate and very fast.

Another critical thing is to only compute **once** the parameters modifying the damage formula (due to the attacker, target and skill)!
Computing this information is very slow.

Feel free to re-use this approach in your mod.

## Hit factors

Hit factor information is computed as in the base game, but with much more information.
My code is just an adaptation and refactoring starting from there.

# License

You have my permission to reuse any portion of this code for your own Battle Brothers modding endeavours.
