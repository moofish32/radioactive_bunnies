module RadioactiveBunnies
  module Ext
    class Util
      class << self
        def constantize!(const_name)
          const_name.split('::').inject(Object) do |fqcn, namespace_to_find|
            fqcn.const_get(namespace_to_find)
          end
        end

        def constantize(const_name)
          constantize!(const_name) rescue nil
        end
      end
    end
  end
end
