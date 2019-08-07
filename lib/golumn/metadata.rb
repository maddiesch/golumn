module Golumn
  class Metadata
    class << self
      attr_writer :application_name

      def application_name
        return @application_name unless @application_name.nil?

        if defined?(::Rails)
          @application_name = if ::Rails.application.class.responds_to?(:module_parent_name)
                                ::Rails.application.class.module_parent_name.underscore
                              else
                                ::Rails.application.class.parent_name
                              end
        else
          raise 'Must specify an application name `Golumn::Metadata.application_name = "my_app"`'
        end

        @application_name
      end

      attr_writer :environment

      def environment
        return @environment unless @environment.nil?

        if defined?(::Rails)
          @environment = ::Rails.env
        else
          raise 'Must specify an environment `Golumn::Metadata.environment = "production"`'
        end

        @environment
      end
    end
  end
end
