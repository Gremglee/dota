module Dota
  module API
    class Hero
      include Utilities::Mapped

      attr_reader :id, :name, :type, :params

      def self.find(id)
        hero = mapping[id]
        hero ? new(id) : Dota::API::MissingHero.new(id)
      end

      def initialize(id)
        @id = id
        @internal_name = mapping[id][0]
        @name = mapping[id][1]
        @type = mapping[id][2]
        # loads odota json with all heroes attributes
        @params = params_mapping[id.to_s]
      end

      def image_url(type = :full)
        # Possible values for type:
        # :full - full quality horizontal portrait (256x114px, PNG)
        # :lg - large horizontal portrait (205x11px, PNG)
        # :sb - small horizontal portrait (59x33px, PNG)
        # :vert - full quality vertical portrait (234x272px, JPEG)

        "http://cdn.dota2.com/apps/dota2/images/heroes/#{internal_name}_#{type}.#{type == :vert ? 'jpg' : 'png'}"
      end

      private
      attr_reader :internal_name

      def params_mapping
        begin
          filename = "hero_attributes.json"
          path = File.join(Dota.root, "data", filename)
          YAML.load_file(path).freeze
        end
      end
    end
  end
end
