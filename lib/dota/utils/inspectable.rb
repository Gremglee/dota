module Dota
  module Utilities
    #
    # When an exception is raised, in some cases `#inspect` is called on a huge
    # object graph to generate the message `"undefined method '...' for
    # <Dota::API::Match:0x...>"`. This can take several seconds, since
    # `Object#inspect` descends recursively into each instance variable.
    #
    # This mixin defines an alternative default implementation for `#inspect`,
    # which should be significantly faster than the default Ruby implementation
    # since it does not descend into the object.
    #
    module Inspectable
      # @return [String]
      def inspect
        if self.class.name.empty?
          "#<\#<Class:0x#{self.class.object_id.abs.to_s(16)}>"
        else
          "#<#{self.class.name}"
        end << ":0x#{object_id.abs.to_s(16)} ...>"
      end
    end
  end
end
