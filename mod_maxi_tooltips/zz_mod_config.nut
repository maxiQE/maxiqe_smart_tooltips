local tacticalTooltipPage = ::ModMaxiTooltips.Mod.ModSettings.addPage("Settings");

// Settings inherited from Reforged
// tacticalTooltipPage.addDivider( "actor_information_divider" );
tacticalTooltipPage.addTitle( "actor_information_title", "Actor information" );
tacticalTooltipPage.addEnumSetting("TacticalTooltip_Attributes", "All", ["All", "AI Only", "Player Only", "None"], "Show Attributes", "Show attributes such as Melee Skill, Melee Defense etc. for entities in the Tactical Tooltip.");
tacticalTooltipPage.addEnumSetting("TacticalTooltip_Effects", "All", ["All", "AI Only", "Player Only", "None"], "Show Effects", "Show status effects for entities in the Tactical Tooltip.");
tacticalTooltipPage.addEnumSetting("TacticalTooltip_Perks", "All", ["All", "AI Only", "Player Only", "None"], "Show Perks", "Show perks for entities in the Tactical Tooltip.");
tacticalTooltipPage.addEnumSetting("TacticalTooltip_EquippedItems", "All", ["All", "AI Only", "Player Only", "None"], "Show Equipped Items", "Show equipped items for entities in the Tactical Tooltip.");
tacticalTooltipPage.addEnumSetting("TacticalTooltip_BagItems", "All", ["All", "AI Only", "Player Only", "None"], "Show Bag Items", "Show items in bag for entities in the Tactical Tooltip.");
tacticalTooltipPage.addEnumSetting("TacticalTooltip_ActiveSkills", "All", ["All", "AI Only", "Player Only", "None"], "Show Active Skills", "Show all the usable active skills for entities in the Tactical Tooltip.");

tacticalTooltipPage.addRangeSetting("CollapseEffectsWhenX", 5, 0, 20, 1, "Collapse Effects When", "While the number of effects is below this value all effects display their icon and use a separate line. Otherwise they combine into a single block of text in order to save space.");
tacticalTooltipPage.addRangeSetting("CollapsePerksWhenX", 5, 0, 20, 1, "Collapse Perks When", "While the number of perks is below this value all perks display their icon and use a separate line. Otherwise they combine into a single block of text in order to save space.");
tacticalTooltipPage.addRangeSetting("CollapseActivesWhenX", 5, 0, 20, 1, "Collapse Actives When", "While the number of active skills is below this value they display their icon and use a separate line. Otherwise they combine into a single block of text in order to save space.");
tacticalTooltipPage.addBooleanSetting("TacticalTooltip_CollapseAsText", false, "Collapse as Text", "If enabled, then skills collapse using their names as text, otherwise they collapse using their icons.");
tacticalTooltipPage.addBooleanSetting("ShowStatusPerkAndEffect", true, "Show Status Perk And Effect", "Some Perks are also Status Effects. Usually their Effect is hidden until some condition is fulfilled. When this setting is enabled, these perks show up in the Perks category even when they show up under Effects (e.g. when their effect is active). When disabled, when they appear under Effects, they will be hidden from the Perks category. This can help save space on the tooltip.");
tacticalTooltipPage.addBooleanSetting("HeaderForEmptyCategories", false, "Show Header for empty categories");

// New settings: damage preview
tacticalTooltipPage.addDivider( "damage_preview_divider" );
tacticalTooltipPage.addTitle( "damage_preview_title", "Damage preview" );
tacticalTooltipPage.addBooleanSetting("clip_health_damage", false, "Clip damage to enemy health", "When this is activated, damage prediction is clipped at enemy health.");
tacticalTooltipPage.addBooleanSetting("clip_armor_damage", true, "Clip damage to enemy armor", "When this is activated, damage prediction is clipped at enemy armor.");
tacticalTooltipPage.addBooleanSetting("show_calculation_time", false, "Show calculation time", "Show calculation time (in ms) for damage estimation.");

tacticalTooltipPage.addRangeSetting("num_samples_total", 500, 50, 1000, 10, "Total calculation cost", "Decrease this number if the tooltips are lagging. Increase it if you want more precise results.");
tacticalTooltipPage.addRangeSetting("num_samples_monte_carlo", 500, 50, 5000, 50, "Monte-Carlo calculation cost", "This parameter is only used for split-man and multi-hit attacks! Decrease this number if the tooltips are lagging. Increase it if you want more precise results.");
tacticalTooltipPage.addRangeSetting("num_samples_armor", 10, 5, 20, 1, "Armor damage calculation cost", "Don't touch this unless you know what you are doing ;-)");

if (::ModMaxiTooltips.Mod.Debug.isEnabled()) {
    tacticalTooltipPage.addDivider( "damage_debug_divider" );
    local button__test__damage_estimation = tacticalTooltipPage.addButtonSetting("test__damage_estimation", "", "Run test__damage_estimation");
    button__test__damage_estimation.addCallback(function(_data = null){
        ::ModMaxiTooltips.TacticalTooltip.test__damage_estimation();
    });
    local button__bench__damage_estimation = tacticalTooltipPage.addButtonSetting("bench__damage_estimation", "", "Run bench__damage_estimation");
    button__bench__damage_estimation.addCallback(function(_data = null){
        ::ModMaxiTooltips.TacticalTooltip.bench__damage_estimation();
    });
}

// New settings: hit factors
tacticalTooltipPage.addDivider( "hit_factors_divider" );
tacticalTooltipPage.addTitle( "hit_factors_title", "Damage preview" );
tacticalTooltipPage.addBooleanSetting("show_original_hitfactors", false, "Show vanilla hit factors", "Show vanilla hit factors instead of informative hit factors.");
