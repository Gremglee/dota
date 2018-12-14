module Dota
  module API
    class Item
      include Utilities::JsonMapped

      attr_reader :id, :name, :internal_name, :cost

      def initialize(id)
        item_hash = mapping.to_a.select{ |i| i[1]["id"] == id }

        if !item_hash.empty?
          @internal_name = item_hash[0][0]
          @id = item_hash[0][1]["id"]
          @name = item_hash[0][1]["dname"]
          @cost = item_hash[0][1]["cost"]
        else
          @internal_name = 'empty'
          @id = 0
          @name = "Empty"
          @cost = 0
        end
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
