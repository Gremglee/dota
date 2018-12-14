module Dota
  module API
    class Item
      require 'pry'
      include Utilities::JsonMapped

      attr_reader :id, :name, :internal_name

      def initialize(id)
        @internal_name = mapping.to_a.select{ |i| i[1]["id"] == id }[0][0]
        @id = mapping[@internal_name]["id"]
        @name = mapping[@internal_name]["dname"]
        @price = mapping[@internal_name]["cost"]
      end

      # Possible values for type:
      # :lg - 85x64 PNG image
      # :eg - 27x20 PNG image
      def image_url(type = :lg)
        filename = "#{internal_name.sub(/\Arecipe_/, '')}_#{type}.png"
        "http://cdn.dota2.com/apps/dota2/images/items/#{filename}"
      end
    end
  end
end
