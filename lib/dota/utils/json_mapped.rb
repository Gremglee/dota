module Dota
  module Utilities
    module JsonMapped
      def self.included(base)
        base.extend ClassMethods

        base.class_eval do
          def mapping
            self.class.mapping
          end
        end
      end

      module ClassMethods
        def mapping
          @mapping ||= begin
            filename = "#{name.split("::").last.downcase}.json"
            path = File.join(Dota.root, "data", filename)
            YAML.load_file(path).freeze
          end
        end

        def all
          @all ||= mapping.to_a.map { |item_json| new(item_json[1]["id"]) }
        end
      end
    end
  end
end
