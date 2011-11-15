
module ProtoRpc

  module Fields

    FIRST_RESERVED_FIELD_NUMBER = 19000
    LAST_RESERVED_FIELD_NUMBER = 19999

    MAX_FIELD_NUMBER = (2 ** 29) - 1

    class FieldDefinitionError < StandardError
    end

    class InvalidVariantError < FieldDefinitionError
    end

    class InvalidDefaultError < FieldDefinitionError
    end

    class InvalidNumberError < FieldDefinitionError
    end


    def self.define(message_class, type, name, number, 
                    required=false, repeated=false, default=nil)
      field_class = const_get("#{type.to_s.capitalize}Field")
      field_class.new(message_class, name, number, required, repeated, default)
    end


    class FieldArray < Array
      # = Array implementation that validates field values.
      def initialize(field_instance)
        @field = field_instance
      end

      def <<(value)
        raise 'todo(joe): ValidationError' unless @field.validates?(value)
        super(value)
      end

      def []=(nth, value)
        raise 'todo(joe): ValidationError' unless @field.validates?(value)
        super(nth, value)
      end

      def push(value)
        raise 'todo(joe): ValidationError' unless @field.validates?(value)
        super(value)
      end

      def unshift(value)
        raise 'todo(joe): ValidationError' unless @field.validates?(value)
        super(value)
      end

      def replace(value)
        raise 'todo(joe): ValidationError' unless @field.validates?(value)
        super(value)
      end
    end


    class Field
      

      attr_reader :message_class, :variant, :name, :number
      attr_reader :default_value, :repeated, :required, :default

      def initialize(message_class, name, number, required, repeated, default)
        @message_class = message_class

        # TODO(joe): add meaningful error messages here
        if not number.is_a?(Numeric) || 
            !(1 <= number) || 
            number >= MAX_FIELD_NUMBER || 
            (number >= FIRST_RESERVED_FIELD_NUMBER &&
             number <= LAST_RESERVED_FIELD_NUMBER)
          raise InvalidNumberError
        end
        
        raise FieldDefinitionError if repeated && required
        raise FieldDefinitionError if repeated && default != nil

        @name, @number = name, number
        @required, @repeated = required, repeated
        
        @default = default if default && validate_default(default)

        define_getter
        if repeated
          define_list_setter
        else
          define_setter
        end
      end

      def validates?(value)
        true
      end
      
      private

      def define_getter
        name, number, default = self.name, self.number, self.default
        @message_class.class_eval do 
          define_method(name) do 
            if @tags.has_key?(number)
              @tags[number]
            else
              default
            end
          end
        end
      end

      def define_setter
        field = self
        @message_class.class_eval do
          define_method("#{field.name}=") do |val|
            if val.nil?
              @tags.delete(field.number)
            elsif field.validates?(val)
              @tags[field.number] = val
            end
          end
        end
      end

    end

    class StringField < Field
    end

    class MessageField < Field
    end

  end
end
