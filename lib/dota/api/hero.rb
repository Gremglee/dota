module Dota
  module API
    class Hero
      include Utilities::JsonMapped

      attr_reader :id, :name, :type, :params, :abilities, :internal_name

      def self.find(id)
        hero = mapping[id.to_s]
        hero ? new(id) : Dota::API::MissingHero.new(id)
      end

      def initialize(id)
        @id = id.to_s
        @internal_name = mapping[@id]['name']
        @name = mapping[@id]['human_name']
        @type = mapping[@id]['primary_attribute']
        @abilities = mapping[@id]['abilities']
        @params = mapping[@id]['params']
      end

      def image_url(type = :full)
        # Possible values for type:
        # :full - full quality horizontal portrait (256x114px, PNG)
        # :lg - large horizontal portrait (205x11px, PNG)
        # :sb - small horizontal portrait (59x33px, PNG)
        # :vert - full quality vertical portrait (234x272px, JPEG)

        "http://cdn.dota2.com/apps/dota2/images/heroes/#{internal_name}_#{type}.#{type == :vert ? 'jpg' : 'png'}"
      end

      def self.all
        @all ||= mapping.to_a.map { |id, item_json| new(id) }
      end
    end
  end
end
