#
# Makes a module behave as a factory.
#
# A module that extends FactoryModule gets a method #new(klass_name, *args):
# this finds the class corresponding to klass_name and creates it with *args as
# arguments.
#
# if +klass_name+ is a class, it's used directly.  Otherwise, it's converted to
# a class, and can be in underscored form (mysql_doc_source) or namespace form
# (FileSources::WordDoc); the name is interpreted relative to the extending
# module's namespace. (So, in the example below, :file_doc_source,
# FileDocSource, DocSource::
#
# Example. Given:
#
#     module DocSource
#       extend FactoryModule
#     end
#
#     # ... elsewhere ...
#     module DocSource
#       # load docs from file
#       class FileDocSource
#         def initialize filename
#           #...
#         end
#       end
#
#       # load docs from web
#       class MySqlDocSource
#         def initialize host, port, user, password
#           # ...
#         end
#       end
#     end
#
# Then:
#     DocSource.new :file_doc_source, '/tmp/foo.doc'    # => returns DocSource::FileDocSource
#     DocSource.new :MySqlDocSource,  'localhost', 6666 # => returns DocSource::MySqlDocSource
#
#
module FactoryModule
  def self.extended base
    base.class_eval do

      def self.new klass_name, *args
        FactoryModule.get_class(self, klass_name).new(*args)
      end

      def self.from_hash plan
        return plan unless plan.is_a?(Hash)
        klass_name = (plan[:type] || plan['type']) or raise "Fat, drunk, and stupid is no way to go through life, son. You need a plan: #{plan.inspect}"
        FactoryModule.get_class(self, klass_name).from_hash(plan)
      end

      def self.create plan
        case
        # when plan.class.ancestors.include? self
        when plan.is_a?(Hash)
          klass_name = plan[:type] || plan['type']
          FactoryModule.get_class(self, klass_name).new(plan)
        when plan.is_a?(Symbol)
          klass_name = plan
          FactoryModule.get_class(self, klass_name).new()
        else plan
        end
      end
    end
  end


  FACTORY_CLASSES = {}
  def self.get_class scope, klass_name
    return FACTORY_CLASSES[ [scope, klass_name] ] if FACTORY_CLASSES[ [scope, klass_name] ]
    if klass_name.is_a? Class
      klass = klass_name
    else
      klass = scope.find_const(klass_name.to_s.camelize)
    end
    # find_const from wukong/extensions/module via extlib
    FACTORY_CLASSES[ [scope, klass_name] ] = klass
  end

end
