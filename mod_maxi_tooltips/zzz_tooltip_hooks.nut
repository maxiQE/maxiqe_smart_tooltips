::ModMaxiTooltips.ModHook.hook("scripts/entity/tactical/actor", function(q) {

	q.getTooltip = @(__original) function( _targetedWithSkill = null )
	{
        return ::ModMaxiTooltips.TacticalTooltip.actorTooltipHook(this, _targetedWithSkill);
	}

});

::ModMaxiTooltips.ModHook.hook("scripts/entity/tactical/player", function(q) {

	q.getTooltip = @(__original) function( _targetedWithSkill = null )
	{
        return ::ModMaxiTooltips.TacticalTooltip.actorTooltipHook(this, _targetedWithSkill);
	}

});

::ModMaxiTooltips.ModHook.hook("scripts/skills/skill", function(q) {

    q.getHitFactors = @(__original) function(tile) {
		if (ModMaxiTooltips.Mod.ModSettings.getSetting("show_original_hitfactors").getValue()) {
            return __original(this, tile)
        } else {
			return ::ModMaxiTooltips.TacticalTooltip.getHitFactors(this, tile)
		}
    }

});

