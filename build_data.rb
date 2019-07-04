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
        ability_data[params["Ability#{index}"].to_s]['ID'].to_i
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

temp_hash = ability_data.map do |name, aparams|
  params = aparams.to_h
  attrs = {
    name: name,
    manacost: (params['AbilityManaCost'].split(' ').map(&:to_i) rescue nil),
    human_name: t(name)
  }
  [params['ID'], attrs]
end.to_h;nil

File.open('data/ability.json', 'w') do |f|
  f.write(JSON.pretty_generate(temp_hash))
end