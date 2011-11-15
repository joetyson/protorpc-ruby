require 'protorpc/fields'

module ProtoRpc

  class Message
    
    class << self

      def string_field(name, number, required=false, repeated=false)
        add_field(Fields.define(self, 'string', name, number, 
                                :required => required, repeated => :repeated))
      end

      def by_number
        @by_number ||= {}
      end

      def by_name
        @by_name ||= {}
      end

      def get_field_by_number(number)
        by_number[number]
      end

      def get_field_by_name(name)
        by_name[name]
      end


      private

      def add_field(field_instance)
        if get_field_by_number(field_instance.number) || 
            get_field_by_name(field_instance.name)
          raise
        end

        @by_name[field_instance.name] = field_instance
        @by_number[field_instance.number] = field_instance
      end
    end

    def initialize(data={})
      @tags = {}

      data.each do |name_or_number, value| 
        field = self.get_field(name_or_number)
        self.__send__("#{field.name}=", value)
      end
    end

    def initialized?
      fields.all? do |number, field|
        value = self[number]
        if !value && field.required
          raise 'todo(joe): ValidationError'
        else
          if field.nil && kind_of?(Fields::MessageField)
            if field.repeated
                value.each {|item| item.initialized? }
            else
              value.initialized?
            end
          end
        end
      end
      true
    end

    def fields
      self.class.by_number
    end

    def get_field(name_or_number)
      case name_or_number
      when Numeric
        self.class.get_field_by_number(name_or_number)
      when String
        self.class.get_field_by_name(name_or_number)
      end
    end

    def [](name_or_number)
      __send__(get_field(name_or_number).name)
    end

    def []=(name_or_number, value)
      __send__(get_field(name_or_number).name + '=', value)
    end

    def reset
      @tags.delete_if do |number, value|
        if value.is_a?(Fields::FieldArray)
          values.reset
          false
        else
          true
        end
      end
      self
    end
  end
end
