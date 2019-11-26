require 'bundler/setup'
Bundler.require(:default)

###########################
## Get using Faraday gem ##
###########################

def get(url)
  faraday = Faraday.new(url) do |faraday|
    faraday.response :json
    faraday.adapter Faraday.default_adapter
  end

  response = faraday.get do |request|
    request.url(url)
  end
  response.body
end

##########################
## Get data from d2vpkg ##
##########################

d2_heroes_url        = 'https://raw.githubusercontent.com/dotabuff/d2vpkr/master/dota/scripts/npc/npc_heroes.json'
d2_abilities_url     = 'https://raw.githubusercontent.com/dotabuff/d2vpkr/master/dota/scripts/npc/npc_abilities.json'
d2_localization_url  = 'https://raw.githubusercontent.com/dotabuff/d2vpkr/master/dota/resource/localization/abilities_english.json'
heroes_data  = get(d2_heroes_url)['DOTAHeroes']
ability_data = get(d2_abilities_url)['DOTAAbilities']
@i18n_data    = get(d2_localization_url)['lang']['Tokens']

heroes_bad_keys = %w(Version npc_dota_hero_base npc_dota_hero_target_dummy)
abilities_bad_keys = %w(Version ability_base dota_base_ability attribute_bonus ability_deward)

BASE_HERO = heroes_data['npc_dota_hero_base'].dup

heroes_bad_keys.each { |bk| heroes_data.delete bk }
abilities_bad_keys.each { |bk| ability_data.delete bk }

#####################
## Build hero json ##
#####################

def format_params(params)
  {
    primary_attr: params['AttributePrimary'].gsub('DOTA_ATTRIBUTE_', '').slice(0, 3).downcase,
    attack_type: (params['AttackCapabilities'] == "DOTA_UNIT_CAP_MELEE_ATTACK" ? "Melee" : "Ranged"),
    roles: params['Role'].split(','),
    base_health: (params['StatusHealth'] || BASE_HERO['StatusHealth']).to_i,
    base_health_regen: (params['StatusHealthRegen'] || BASE_HERO['StatusHealthRegen']).to_i,
    base_mana: (params['StatusMana'] || BASE_HERO['StatusMana']).to_i,
    base_mana_regen: (params['StatusManaRegen'] || BASE_HERO['StatusManaRegen']).to_i,
    base_armor: (params['ArmorPhysical'] || BASE_HERO['ArmorPhysical']).to_i,
    base_mr: (params['MagicalResistance'] || BASE_HERO['MagicalResistance']).to_i,
    base_attack_min: (params['AttackDamageMin'] || BASE_HERO['AttackDamageMin']).to_i,
    base_attack_max: (params['AttackDamageMax'] || BASE_HERO['AttackDamageMax']).to_i,
    base_str: params['AttributeBaseStrength'].to_i,
    base_agi: params['AttributeBaseAgility'].to_i,
    base_int: params['AttributeBaseIntelligence'].to_i,
    str_gain: params['AttributeStrengthGain'].to_i,
    agi_gain: params['AttributeAgilityGain'].to_i,
    int_gain: params['AttributeIntelligenceGain'].to_i,
    attack_range: params['AttackRange'].to_i,
    projectile_speed: (params['ProjectileSpeed'] || BASE_HERO['ProjectileSpeed']).to_i,
    attack_rate: (params['AttackRate'] || BASE_HERO['AttackRate']).to_i,
    move_speed: params['MovementSpeed'].to_i,
    turn_rate: params['MovementTurnRate'].to_i,
    cm_enabled: (params['CMEnabled'] === "1" ? true : false),
    legs: (params['Legs'] || BASE_HERO['Legs']).to_i
  }
end

temp_hash = heroes_data.map do |name, params|
  primary_attrs = {
    'DOTA_ATTRIBUTE_AGILITY' => 'agility',
    'DOTA_ATTRIBUTE_STRENGTH' => 'strength',
    'DOTA_ATTRIBUTE_INTELLECT' => 'intelligence'
  }
  talent_start = params['AbilityTalentStart']&.to_i || 10
  abilities = (1..talent_start-1).map do |index|
    if params["Ability#{index}"].nil?
      nil
    else
      unless ['', 'generic_hidden'].include? params["Ability#{index}"]
        x = params["Ability#{index}"].to_s
        # case params["Ability#{index}"].to_s 
        #     when 'drow_ranger_multishot' then 'drow_ranger_trueshot'
        #     when 'pudge_eject' then 'pudge_dismember'
        #     when 'tiny_tree_grab' then 'tiny_tree_channel'
        #     when 'kunkka_torrent_storm' then 'kunkka_torrent'
        #     when 'riki_backstab' then 'riki_permanent_invisibility'
        #     else
        #       params["Ability#{index}"].to_s
        #     end
        if ability_data[x].nil?
          nil
        else
          ability_data[x]['ID'].to_i
        end
      end
    end
  end.compact.uniq
  attrs = {
    name: name.gsub('npc_dota_hero_', ''),
    human_name: params['workshop_guide_name'],
    primary_attribute: primary_attrs[params['AttributePrimary']],
    abilities: abilities,
    params: format_params(params)
  }
  [params['HeroID'], attrs]
end.to_h

File.open('data/hero.json', 'w') do |f|
  f.write(JSON.pretty_generate(temp_hash))
end

##########################
## Build abilities JSON ##
##########################

def t(key)
  @i18n_data["DOTA_Tooltip_ability_#{key}"]
end

@extra_strings = {
  'DOTA_ABILITY_BEHAVIOR_NONE' => "None",
  'DOTA_ABILITY_BEHAVIOR_PASSIVE' => "Passive",
  'DOTA_ABILITY_BEHAVIOR_UNIT_TARGET' => "Unit Target",
  'DOTA_ABILITY_BEHAVIOR_CHANNELLED' => "Channeled",
  'DOTA_ABILITY_BEHAVIOR_POINT' => "Point Target",
  'DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES' => "Root",
  'DOTA_ABILITY_BEHAVIOR_AOE' => "AOE",
  'DOTA_ABILITY_BEHAVIOR_NO_TARGET' => "No Target",
  'DOTA_ABILITY_BEHAVIOR_AUTOCAST' => "Autocast",
  'DOTA_ABILITY_BEHAVIOR_ATTACK' => "Attack Modifier",
  'DOTA_ABILITY_BEHAVIOR_IMMEDIATE' => "Instant Cast",
  'DAMAGE_TYPE_PHYSICAL' => "Physical",
  'DAMAGE_TYPE_MAGICAL' => "Magical",
  'DAMAGE_TYPE_PURE' => "Pure",
  'SPELL_IMMUNITY_ENEMIES_YES' => "Yes",
  'SPELL_IMMUNITY_ENEMIES_NO' => "No",
  'DOTA_ABILITY_BEHAVIOR_HIDDEN' => "Hidden"
}

@ignore_strings = [
  "DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES",
  "DOTA_ABILITY_BEHAVIOR_DONT_RESUME_ATTACK",
  "DOTA_ABILITY_BEHAVIOR_DONT_RESUME_MOVEMENT",
  "DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING",
  "DOTA_ABILITY_BEHAVIOR_TOGGLE",
  "DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE"
]

def format_behavior(str)
  str.split(' | ').map { |b| @extra_strings[b] unless @ignore_strings.include?(b) }.compact
rescue
  nil
end

temp_hash = ability_data.map do |name, aparams|
  params = aparams.to_h
  h_name = t(name)
  if h_name
    interpolations = h_name.scan /{s:\w*}/
    interpolations.each do |i|
      field = i[3..-2]
      value = if params['AbilitySpecial'].is_a?(Hash)
        params['AbilitySpecial'][field]
      else
        puts params['AbilitySpecial']
        puts field
        params['AbilitySpecial'].select{|f| f.first.first.to_s == field.to_s}.last[field] rescue params['AbilitySpecial'].first['value']
      end
      h_name = h_name.gsub(i, value.to_s)
    end
  else
    h_name = name
  end

  attrs = {
    name: name,
    manacost: (params['AbilityManaCost'].split(' ').map(&:to_i) rescue nil),
    cooldown: (params['AbilityCooldown'].split(' ').map(&:to_i) rescue nil),
    behavior: format_behavior(params['AbilityBehavior']),
    human_name: h_name
  }
  [params['ID'], attrs]
end.to_h;nil

temp_hash['99999'] = {
  name: 'base_talent_moremmr',
  human_name: 'Hero Talent',
  manacost: nil,
  cooldown: nil,
  behavior: nil
}

File.open('data/ability.json', 'w') do |f|
  f.write(JSON.pretty_generate(temp_hash))
end