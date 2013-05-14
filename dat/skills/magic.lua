------------------------------------------------------------------------------[[
-- Filename: magic.lua
--
-- Description: This file contains the definitions of all support skills.
-- Each support skill has a unique integer identifier
-- that is used as its key in the skills table below. Some skills are primarily
-- intended for characters to use while others are intended for enemies to use.
-- Normally, we do not want to share skills between characters and enemies as
-- character skills animate the sprites while enemy skills do not.
--
-- Skill IDs 10,001 through 20,000 are reserved for support skills.
--
-- Each skill entry requires the following data to be defined:
-- {name}: Text that defines the name of the skill
-- {description}: A brief (one sentence) description of the skill
--                (This field is required only for character skills and is optional for enemy skills)
-- {icon}: the skill icon filename
--                (This field is is optional)
-- {sp_required}: The number of skill points (SP) that are required to use the skill
--                (Zero is a valid value for this field, but a negative number is not)
-- {warmup_time}: The number of milliseconds that the actor using the skill must wait between
--                selecting the skill and executing it (a value of zero is valid).
-- {cooldown_time}: The number of milliseconds that the actor using the skill must wait after
--                  executing the skill before their stamina begins regenrating (zero is valid).
-- {target_type}: The type of target the skill affects, which may be an attack point, actor, or party.
--
-- Each skill entry requires a function called {BattleExecute} to be defined. This function implements the
-- execution of the skill in battle, buffing defense, causing status changes, playing sounds, and animating
-- sprites.
------------------------------------------------------------------------------]]

-- All support skills definitions are stored in this table
if (skills == nil) then
    skills = {}
end


--------------------------------------------------------------------------------
-- IDs 10,001 - 11,000 are reserved for character magic skills
--------------------------------------------------------------------------------

-------------------------------------------------------------
-- 10001 - 10099 - Natural skills, obtained through levelling
-------------------------------------------------------------
skills[10001] = {
    name = vt_system.Translate("Shield"),
    description = vt_system.Translate("Increases an ally's physical defense by a slight degree."),
    icon = "img/icons/magic/shield.png",
    sp_required = 3,
    warmup_time = 300,
    cooldown_time = 0,
    warmup_action_name = "magic_prepare",
    action_name = "magic_cast",
    target_type = vt_global.GameGlobal.GLOBAL_TARGET_ALLY,

    BattleExecute = function(user, target)
        target_actor = target:GetActor();
        local effect_duration = user:GetProtection() * 2000;
        if (effect_duration < 10000) then effect_duration = 10000 end
        target_actor:RegisterStatusChange(vt_global.GameGlobal.GLOBAL_STATUS_FORTITUDE_RAISE,
                                          vt_global.GameGlobal.GLOBAL_INTENSITY_POS_MODERATE,
                                          effect_duration);
        local Battle = ModeManager:GetTop();
        if (target_actor:GetSpriteHeight() > 250.0) then
            -- Big sprite version
            Battle:TriggerBattleParticleEffect("dat/effects/particles/shield_big_sprites.lua",
                target_actor:GetXLocation(), target_actor:GetYLocation() + 5);
        else
            Battle:TriggerBattleParticleEffect("dat/effects/particles/shield.lua",
                    target_actor:GetXLocation(), target_actor:GetYLocation() + 5);
        end
        AudioManager:PlaySound("snd/defence1_spell.ogg");
    end
}

skills[10002] = {
    name = vt_system.Translate("First Aid"),
    description = vt_system.Translate("Performs basic medical assistance, healing the target by a minor degree."),
    icon = "img/icons/magic/first_aid.png",
    sp_required = 4,
    warmup_time = 1500,
    cooldown_time = 200,
    warmup_action_name = "magic_prepare",
    action_name = "magic_cast",
    target_type = vt_global.GameGlobal.GLOBAL_TARGET_ALLY,

    BattleExecute = function(user, target)
        target_actor = target:GetActor();
        local hit_points = (user:GetVigor() * 3) +  vt_utils.RandomBoundedInteger(0, 15);
        target_actor:RegisterHealing(hit_points, true);
        AudioManager:PlaySound("snd/heal_spell.wav");
        local Battle = ModeManager:GetTop();
        Battle:TriggerBattleParticleEffect("dat/effects/particles/heal_particle.lua",
                target_actor:GetXLocation(), target_actor:GetYLocation() + 5);
    end,

    FieldExecute = function(target, instigator)
        target:AddHitPoints((instigator:GetVigor() * 5) + vt_utils.RandomBoundedInteger(0, 30));
        AudioManager:PlaySound("snd/heal_spell.wav");
    end
}

skills[10003] = {
    name = vt_system.Translate("Leader Call"),
    description = vt_system.Translate("Temporarily increases the strength of all allies."),
    icon = "img/icons/magic/leader_call.png",
    sp_required = 14,
    warmup_time = 4000,
    cooldown_time = 750,
    warmup_action_name = "magic_prepare",
    action_name = "magic_cast",
    target_type = vt_global.GameGlobal.GLOBAL_TARGET_ALL_ALLIES,

    BattleExecute = function(user, target)
        local index = 0;
        local effect_duration = user:GetVigor() * 3000;
        while true do
            target_actor = target:GetPartyActor(index);
            if (target_actor == nil) then
                break;
            end
            target_actor:RegisterStatusChange(vt_global.GameGlobal.GLOBAL_STATUS_STRENGTH_RAISE,
                        vt_global.GameGlobal.GLOBAL_INTENSITY_POS_LESSER,
                        effect_duration);
            index = index + 1;
        end
    end,
}

-------------------------------------------------------------
-- 10100 - 10199 - Shards skills, obtained through equipping shards to equipment
-------------------------------------------------------------

skills[10100] = {
    name = vt_system.Translate("Fire burst"),
    description = vt_system.Translate("Creates a small fire that burns an enemy."),
    icon = "img/icons/magic/fireball.png",
    sp_required = 7,
    warmup_time = 4000,
    cooldown_time = 750,
    warmup_action_name = "magic_prepare",
    action_name = "magic_cast",
    target_type = vt_global.GameGlobal.GLOBAL_TARGET_FOE,

    BattleExecute = function(user, target)
        target_actor = target:GetActor();
        if (vt_battle.CalculateStandardEvasion(target) == false) then
            -- TODO: Set fire elemental damage type based on character stats
            target_actor:RegisterDamage(vt_battle.CalculateMagicalDamageAdder(user, target, 30), target);
            -- trigger the fire effect slightly under the sprite to make it appear before it from the player's point of view.
            local Battle = ModeManager:GetTop();
            Battle:TriggerBattleParticleEffect("dat/effects/particles/fire_spell.lua",
                    target_actor:GetXLocation(), target_actor:GetYLocation() + 5);
            AudioManager:PlaySound("snd/fire1_spell.ogg");
        else
            target_actor:RegisterMiss(true);
        end
    end,
}

skills[10110] = {
    name = vt_system.Translate("Wave"),
    description = vt_system.Translate("Makes waves fall on an enemy."),
    --icon = "img/icons/magic/fireball.png",
    sp_required = 7,
    warmup_time = 4000,
    cooldown_time = 750,
    warmup_action_name = "magic_prepare",
    action_name = "magic_cast",
    target_type = vt_global.GameGlobal.GLOBAL_TARGET_FOE,

    BattleExecute = function(user, target)
        target_actor = target:GetActor();
        if (vt_battle.CalculateStandardEvasion(target) == false) then
            -- TODO: Set water elemental damage type based on character stats
            target_actor:RegisterDamage(vt_battle.CalculateMagicalDamageAdder(user, target, 45), target);
            -- trigger the fire effect slightly under the sprite to make it appear before it from the player's point of view.
            local Battle = ModeManager:GetTop();
            Battle:TriggerBattleParticleEffect("dat/effects/particles/wave_spell.lua",
                    target_actor:GetXLocation(), target_actor:GetYLocation() + 5);
            AudioManager:PlaySound("snd/wave1_spell.ogg");
        else
            target_actor:RegisterMiss(true);
        end
    end,
}
