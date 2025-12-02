if (!("TacticalTooltip" in ::ModMaxiTooltips)) {
    ::ModMaxiTooltips.TacticalTooltip <- {};
}

// local parameters = {
//     armor=armor,
//     min_damage=min_damage,
//     max_damage=max_damage,
//     guaranteed_damage=::Math.min(::Math.round(hit_info.DamageMinimum), ::Math.round(hit_info.DamageMinimum * defender_properties.DamageReceivedTotalMult)),
//     direct_damage_coefficient=hit_info.DamageDirect,
//     direct_damage_coefficient_multiplier=defender_properties.DamageReceivedDirectMult,
//     health_multiplier=properties.damageRegularMult * attacker_damage_mult * defender_properties.DamageReceivedRegularMult * target_damage_mult,
//     armor_multiplier=properties.DamageArmorMult * attacker_damage_mult * defender_properties.DamageReceivedArmorMult * target_damage_mult,
//     bodypart_damage_mult=bodypart_damage_mult
// }


// Inclusive range
local function range(a, b) {
    local res = [];
    for (local i = a; i <= b; i++) {
        res.push(i);
    }
    return res
}


local function linspace(a, b, n) {
    local step = 1. * (b - a) / (n-1);
    local res = []
    for (local idx = 0.; idx < n; idx++) {
        res.push(idx * step + a);
    }
    return res
}


// Use to represent uniform distributions
// Use range if n is big enough, or linspace
local function interval(a, b, n) {
    local range_len = b + 1 - a;
    if (n >= range_len) {
        return range(a, b);
    } else {
        return linspace(a, b, n);
    }
}


::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack <- function(attacker, target, skill, body_part_hit) {
        // Get information from attack
    local attacker_properties = skill.m.Container.buildPropertiesForUse(skill, target);

    local bodyPartDamageMult = attacker_properties.DamageAgainstMult[body_part_hit];

    

    local distance_to_target = attacker.getTile().getDistanceTo(target.getTile());

    local attacker_damage_mult = skill.isRanged() ? attacker_properties.RangedDamageMult : attacker_properties.MeleeDamageMult;
    attacker_damage_mult = attacker_damage_mult * attacker_properties.DamageTotalMult;
    
    local damageDirectCoefficient = ::Math.minf(1.0, attacker_properties.DamageDirectMult * (skill.m.DirectDamageMult + attacker_properties.DamageDirectAdd + (skill.isRanged() ? attacker_properties.DamageDirectRangedAdd : attacker_properties.DamageDirectMeleeAdd)));

    // // Unused in vanilla
    // assert(attacker_properties.DamageAdditionalWithEachTile == 0, "Expected properties.DamageAdditionalWithEachTile = 0 but got instead: " + attacker_properties.DamageAdditionalWithEachTile)

    local hit_info = clone ::Const.Tactical.HitInfo;
    hit_info.DamageRegular = 0;
    hit_info.DamageArmor = 0;
    hit_info.DamageDirect = damageDirectCoefficient;
    hit_info.DamageFatigue = ::Const.Combat.FatigueReceivedPerHit * attacker_properties.FatigueDealtPerHitMult;
    hit_info.DamageMinimum = attacker_properties.DamageMinimum;
    hit_info.BodyPart = body_part_hit;
    hit_info.BodyDamageMult = bodyPartDamageMult;
    hit_info.FatalityChanceMult = attacker_properties.FatalityChanceMult;
    // hit_info.Injuries = None;
    hit_info.InjuryThresholdMult = attacker_properties.ThresholdToInflictInjuryMult;
    hit_info.Tile = target.getTile();

    // adapted from _info.Container.onBeforeTargetHit(_info.Skill, _info.TargetEntity, hit_info);
    attacker.m.Skills.onBeforeTargetHit(skill, target, hit_info);

    local defender_properties = target.m.Skills.buildPropertiesForBeingHit(attacker, skill, hit_info);
    target.m.Items.onBeforeDamageReceived(attacker, skill, hit_info, defender_properties);
    
    if (target.m.CurrentProperties.IsImmuneToCriticals || target.m.CurrentProperties.IsImmuneToHeadshots)
    {
        hit_info.BodyDamageMult = 1.0;
    }

    local target_damage_mult = defender_properties.DamageReceivedTotalMult;

    // REMOVED A CONDITIONAL if (skill != null)
    target_damage_mult = target_damage_mult * (skill.isRanged() ? defender_properties.DamageReceivedRangedMult : defender_properties.DamageReceivedMeleeMult);

    local parameters = {
        armor=defender_properties.Armor[body_part_hit] * defender_properties.ArmorMult[body_part_hit],
        health=target.m.Hitpoints,
        min_damage=attacker_properties.DamageRegularMin,
        max_damage=attacker_properties.DamageRegularMax,
        guaranteed_damage=::Math.min(::Math.round(hit_info.DamageMinimum), ::Math.round(hit_info.DamageMinimum * defender_properties.DamageReceivedTotalMult)),
        direct_damage_coefficient=hit_info.DamageDirect,
        direct_damage_coefficient_multiplier=defender_properties.DamageReceivedDirectMult,
        health_multiplier=attacker_properties.DamageRegularMult * attacker_damage_mult * defender_properties.DamageReceivedRegularMult * target_damage_mult,
        armor_multiplier=attacker_properties.DamageArmorMult * attacker_damage_mult * defender_properties.DamageReceivedArmorMult * target_damage_mult,
        bodypart_damage_mult=hit_info.BodyDamageMult
    };

    return parameters
}

local default_parameters = {
    armor=100,
    health=100,
    min_damage=40,
    max_damage=80,
    guaranteed_damage=0,
    direct_damage_coefficient=0.4,
    direct_damage_coefficient_multiplier=1,
    health_multiplier=1,
    armor_multiplier=1,
    bodypart_damage_mult=1
}


::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll <- function(armor_roll, health_roll, parameters) {
    // ::MSU.Table.merge(parameters, default_parameters);
    
    local damageRegular = health_roll * parameters.health_multiplier;
    local damageArmor = armor_roll * parameters.armor_multiplier;

    local armor = 0;
    local armorDamage = 0;

    local damage_reduction_from_armor = 0;
    local armor_damage = 0;
    local health_damage_direct = 0;
    local health_damage_armor_break = 0;

    if (parameters.direct_damage_coefficient >= 1.0) {
        damage_reduction_from_armor = 0;
        health_damage_direct = ::Math.maxf(0.0, damageRegular - damage_reduction_from_armor);
    } else {
        armor = parameters.armor;
        armorDamage = ::Math.min(armor, damageArmor);
        armor = armor - armorDamage;
        armor_damage = ::Math.max(0, armorDamage);

        damage_reduction_from_armor = armor * ::Const.Combat.ArmorDirectDamageMitigationMult;
        health_damage_direct = ::Math.maxf(0.0, damageRegular * parameters.direct_damage_coefficient * parameters.direct_damage_coefficient_multiplier - damage_reduction_from_armor);

        health_damage_armor_break = 0
        if (armor <= 0)
        {
            health_damage_armor_break = ::Math.max(0, damageRegular * ::Math.maxf(0.0, 1.0 - parameters.direct_damage_coefficient * parameters.direct_damage_coefficient_multiplier) - armorDamage);
        }
    }

    local damage = health_damage_direct + health_damage_armor_break;

    damage *= parameters.bodypart_damage_mult;

    local guaranteed_damage = 0
    if (parameters.guaranteed_damage > 0 && parameters.guaranteed_damage > damage) {
        guaranteed_damage = parameters.guaranteed_damage;
        damage = guaranteed_damage;
        health_damage_direct = 0;
        health_damage_armor_break = 0;
    }
    damage = ::Math.max(0, ::Math.round(damage));

    damage = ::Math.min(damage, parameters.health);

    return {
        health_damage=damage,
        health_damage_direct=health_damage_direct,
        health_damage_armor_break=health_damage_armor_break,
        guaranteed_damage=guaranteed_damage,
        damage_reduction_from_armor=damage_reduction_from_armor,
        armor_damage=armor_damage
    }
}


::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__exact <- function(parameters) {
    local roll_array = range(parameters.min_damage, parameters.max_damage);
    local weight = 1. / roll_array.len();

    local health_damage=0;
    local health_damage_direct=0;
    local health_damage_armor_break=0;
    local guaranteed_damage=0;
    local damage_reduction_from_armor=0;
    local armor_damage=0;

    local proba_armor_destroy = 0;
    local kill_proba = 0;

    foreach (idx, armor_roll in roll_array) {
        foreach (jdx, health_roll in roll_array) {
            local res = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll(armor_roll, health_roll, parameters);
            local weight_armor = weight;
            local weight_health = weight;

            health_damage += weight_armor * weight_health * res.health_damage;
            health_damage_direct += weight_armor * weight_health * res.health_damage_direct;
            health_damage_armor_break += weight_armor * weight_health * res.health_damage_armor_break;
            guaranteed_damage += weight_armor * weight_health * res.guaranteed_damage;
            damage_reduction_from_armor += weight_armor * weight_health * res.damage_reduction_from_armor;
            armor_damage += weight_armor * weight_health * res.armor_damage;
            
            proba_armor_destroy += weight_armor * weight_health * (parameters.armor <= res.armor_damage).tofloat();
            kill_proba += weight_armor * weight_health * (parameters.health <= res.health_damage).tofloat();
        }
    }

    return {
        health_damage=health_damage,
        armor_damage=armor_damage,
        proba_armor_destroy=proba_armor_destroy,
        kill_proba=kill_proba
    }
}





::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__fast <- function(parameters) {
    local armor_roll_array = interval(parameters.min_damage, parameters.max_damage, 4);
    local weight_armor = 1. / armor_roll_array.len();

    local health_roll_array = interval(parameters.min_damage, parameters.max_damage, 11);
    local weight_health = 1. / health_roll_array.len();

    local health_damage=0;
    local health_damage_direct=0;
    local health_damage_armor_break=0;
    local guaranteed_damage=0;
    local damage_reduction_from_armor=0;
    local armor_damage=0;

    local proba_armor_destroy = 0;
    local kill_proba = 0;

    foreach (idx, armor_roll in armor_roll_array) {
        foreach (jdx, health_roll in health_roll_array) {
            local res = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll(armor_roll, health_roll, parameters);

            health_damage += weight_armor * weight_health * res.health_damage;
            health_damage_direct += weight_armor * weight_health * res.health_damage_direct;
            health_damage_armor_break += weight_armor * weight_health * res.health_damage_armor_break;
            guaranteed_damage += weight_armor * weight_health * res.guaranteed_damage;
            damage_reduction_from_armor += weight_armor * weight_health * res.damage_reduction_from_armor;
            armor_damage += weight_armor * weight_health * res.armor_damage;
            
            proba_armor_destroy += weight_armor * weight_health * (parameters.armor <= res.armor_damage).tofloat();
            kill_proba += weight_armor * weight_health * (parameters.health <= res.health_damage).tofloat();
        }
    }

    return {
        health_damage=health_damage,
        armor_damage=armor_damage,
        proba_armor_destroy=proba_armor_destroy,
        kill_proba=kill_proba
    }
}

// Analyze armor break from parameters
// Return
// - proba_armor_destroy: float
// - destroy_point: int or None
// - representation: list[tuple[proba: float, a: int, b: int]]
//   a list of probability and intervals to use to represent armor, for sampling
::ModMaxiTooltips.TacticalTooltip.armor_destroy_from_params <- function(parameters) {
    // Armor ignoring attack
    if (parameters.armor == 0 || parameters.direct_damage_coefficient >= 1.0) {
        // Note the double-min: we don't need to care about armor value at all
        return {
            proba_armor_destroy=0.,
            destroy_point=null,
            representation=[[1., parameters.min_damage, parameters.min_damage]]
        }
    }

    local max_damage = parameters.max_damage * parameters.armor_multiplier;

    // Armor destroy is impossible
    if (max_damage < parameters.armor) {
        return {
            proba_armor_destroy=0.,
            destroy_point=null,
            representation=[[1., parameters.min_damage, parameters.max_damage]]
        }
    }

    local min_damage = parameters.min_damage * parameters.armor_multiplier;

    // Armor destroy is certain
    if (min_damage >= parameters.armor) {
        return {
            proba_armor_destroy=1.,
            destroy_point=parameters.min_damage,
            representation=[[1., parameters.min_damage, parameters.max_damage]]
        }
    }

    // Find destroy_point
    local armor_roll_interval = range(parameters.min_damage, parameters.max_damage);
    local weight = 1./armor_roll_interval.len();
    local destroy_point;
    foreach (idx, armor_roll in armor_roll_interval) {
        if ((armor_roll * parameters.armor_multiplier) > parameters.armor) {
            destroy_point = armor_roll;
            break
        }
    }

    local proba_armor_destroy = (armor_roll_interval.len() - idx) * weight;
    local representation = [
        [1 - proba_armor_destroy, parameters.min_damage, destroy_point - 1],
        [proba_armor_destroy, destroy_point, parameters.max_damage]
    ]

    return {
        proba_armor_destroy=proba_armor_destroy,
        destroy_point=destroy_point,
        representation=representation
    }
}

::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__smartfast <- function(parameters) {
    local armor_destroy_res = ::ModMaxiTooltips.TacticalTooltip.armor_destroy_from_params(parameters);

    local armor_roll_array = [];
    local weight_armor_array = [];
    foreach (interval_info in armor_destroy_res.representation) {
        local proba = interval_info[0];
        local local_array = interval(interval_info[1], interval_info[2], 2);
        foreach (value in local_array) {
            armor_roll_array.push(value);
            weight_armor_array.push(proba * 1. / local_array.len())
        }
    }

    local health_roll_array = interval(parameters.min_damage, parameters.max_damage, 11);
    local weight_health = 1. / health_roll_array.len();

    local health_damage=0;
    local health_damage_direct=0;
    local health_damage_armor_break=0;
    local guaranteed_damage=0;
    local damage_reduction_from_armor=0;
    local armor_damage=0;

    local proba_armor_destroy = 0;
    local kill_proba = 0;

    foreach (idx, armor_roll in armor_roll_array) {
        local weight_armor = weight_armor_array[idx];
        foreach (jdx, health_roll in health_roll_array) {
            local res = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__with_roll(armor_roll, health_roll, parameters);

            health_damage += weight_armor * weight_health * res.health_damage;
            health_damage_direct += weight_armor * weight_health * res.health_damage_direct;
            health_damage_armor_break += weight_armor * weight_health * res.health_damage_armor_break;
            guaranteed_damage += weight_armor * weight_health * res.guaranteed_damage;
            damage_reduction_from_armor += weight_armor * weight_health * res.damage_reduction_from_armor;
            armor_damage += weight_armor * weight_health * res.armor_damage;
            
            proba_armor_destroy += weight_armor * weight_health * (parameters.armor <= res.armor_damage).tofloat();
            kill_proba += weight_armor * weight_health * (parameters.health <= res.health_damage).tofloat();
        }
    }

    return {
        health_damage=health_damage,
        armor_damage=armor_damage,
        proba_armor_destroy=proba_armor_destroy,
        kill_proba=kill_proba
    }
}



::ModMaxiTooltips.TacticalTooltip.attack_info_summary_from_parameters <- function(attacker, target, skill) {
    local parameters_head = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Head);
    local parameters_body = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Body);

    local summary_head = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__exact(parameters_head);
    local summary_body = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__exact(parameters_body);

    local properties = skill.m.Container.buildPropertiesForUse(skill, target);
    local head_hit_chance = properties.getHitchance(::Const.BodyPart.Head);

    local kill_proba = (head_hit_chance * summary_head.kill_proba + (100 - head_hit_chance) * summary_body.kill_proba);

    local ret = {
        head_hit_chance = head_hit_chance,
        kill_proba = kill_proba,

        target = {
            health = target.m.Hitpoints,
            body_armor = target.getArmor(::Const.BodyPart.Body),
            head_armor = target.getArmor(::Const.BodyPart.Head),
        }

        distribution_body_armor = {
            mean=summary_body.armor_damage,
            proba=summary_body.proba_armor_destroy
        },
        distribution_body_health = {
            mean=summary_body.health_damage,
            proba=summary_body.kill_proba
        },
        distribution_head_armor = {
            mean=summary_head.armor_damage,
            proba=summary_head.proba_armor_destroy
        },
        distribution_head_health = {
            mean=summary_head.health_damage,
            proba=summary_head.kill_proba
        },
    };

    return ret;
}



::ModMaxiTooltips.TacticalTooltip.attack_info_summary_from_parameters__fast <- function(attacker, target, skill) {
    local parameters_head = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Head);
    local parameters_body = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Body);

    local summary_head = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__fast(parameters_head);
    local summary_body = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__fast(parameters_body);

    local properties = skill.m.Container.buildPropertiesForUse(skill, target);
    local head_hit_chance = properties.getHitchance(::Const.BodyPart.Head);

    local kill_proba = (head_hit_chance * summary_head.kill_proba + (100 - head_hit_chance) * summary_body.kill_proba);

    local ret = {
        head_hit_chance = head_hit_chance,
        kill_proba = kill_proba,

        target = {
            health = target.m.Hitpoints,
            body_armor = target.getArmor(::Const.BodyPart.Body),
            head_armor = target.getArmor(::Const.BodyPart.Head),
        }

        distribution_body_armor = {
            mean=summary_body.armor_damage,
            proba=summary_body.proba_armor_destroy
        },
        distribution_body_health = {
            mean=summary_body.health_damage,
            proba=summary_body.kill_proba
        },
        distribution_head_armor = {
            mean=summary_head.armor_damage,
            proba=summary_head.proba_armor_destroy
        },
        distribution_head_health = {
            mean=summary_head.health_damage,
            proba=summary_head.kill_proba
        },
    };

    return ret;
}


::ModMaxiTooltips.TacticalTooltip.attack_info_summary_from_parameters__smartfast <- function(attacker, target, skill) {
    local parameters_head = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Head);
    local parameters_body = ::ModMaxiTooltips.TacticalTooltip.compute_parameters_from_attack(attacker, target, skill, ::Const.BodyPart.Body);

    local summary_head = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__smartfast(parameters_head);
    local summary_body = ::ModMaxiTooltips.TacticalTooltip.damage_from_parameters__summary__smartfast(parameters_body);

    local properties = skill.m.Container.buildPropertiesForUse(skill, target);
    local head_hit_chance = properties.getHitchance(::Const.BodyPart.Head);

    local kill_proba = (head_hit_chance * summary_head.kill_proba + (100 - head_hit_chance) * summary_body.kill_proba);

    local ret = {
        head_hit_chance = head_hit_chance,
        kill_proba = kill_proba,

        target = {
            health = target.m.Hitpoints,
            body_armor = target.getArmor(::Const.BodyPart.Body),
            head_armor = target.getArmor(::Const.BodyPart.Head),
        }

        distribution_body_armor = {
            mean=summary_body.armor_damage,
            proba=summary_body.proba_armor_destroy
        },
        distribution_body_health = {
            mean=summary_body.health_damage,
            proba=summary_body.kill_proba
        },
        distribution_head_armor = {
            mean=summary_head.armor_damage,
            proba=summary_head.proba_armor_destroy
        },
        distribution_head_health = {
            mean=summary_head.health_damage,
            proba=summary_head.kill_proba
        },
    };

    return ret;
}

