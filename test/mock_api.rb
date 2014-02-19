module MockApi

  require 'hashie'

  ##
  # A mocked Api for use during testing
  # Uses ./test/fixtures/api_models.yml to respond to queries
  class Api < ActionController::TestCase

    class TestError < StandardError; end

    ##
    # eg. api.lot
    class Resource

      attr_reader :name

      def initialize(resource_name)
        @name = resource_name
      end

      def find(uuid)
        resource_cache[uuid] ||= Record.new(Registry.instance.find(name,uuid),uuid,name)
      end

      alias_method :with_uuid, :find

      ##
      # Receives a hash
      # :recieved => The arguments create expects to see (optional)
      # :returns  => The UUID of the returned resource, which should exist in the registry.
      def expect_create_with(options)
        recieved = options[:recieved]
        returned = Record.new(Registry.instance.find(name,options[:returns]),options[:returns],name)
        if recieved.present?
          self.expects(:create!).with(recieved).returns(returned)
        else
          self.expects(:create!).returns(returned)
        end
      end

      def create!(*args)
        raise Api::TestError, "Unexpected create! received with options #{args.inspect}"
      end

      private

      def resource_cache
        @resource_cache ||= Hash.new
      end

    end

    ##
    # An association proxy is a bit like a resource. In practice its a bit more complicated
    # than the mocked up version, as it doesn't end up at the same place as the base resource.
    # However, we don't really care about that here, as that's outside the scope of the tests.
    class Association < Resource
      def initialize(parent,resource_name,records)
        @name = resource_name
        @parent = parent
        @records = records.map {|uuid| Registry.instance.find(:"#{resource_name}",uuid)}
      end

      ##
      # Method missing first tries passing things on to the association array
      def method_missing(method_name,*args)
        return @records.send(:"#{method_name}",*args) if @records.respond_to?(:"#{method_name}")
        super
      end
    end

    ##
    # An instance of a resource
    class Record

      def initialize(record,uuid,model_name)
        @record = record
        @uuid = uuid
        @model_name = model_name
      end

      attr_reader :uuid, :model_name
      alias_method :id, :uuid

      def method_missing(method_name)
        lookup_attribute(method_name)||lookup_association(method_name)||super
      end

      ##
      # Used by rails to resolve urls
      def to_param
        uuid
      end

      private

      def attribute_cache
        @attribute_cache ||= Hash.new
      end

      def association_cache
        @association_cache ||= Hash.new
      end

      def lookup_attribute(attribute)
        attribute_cache[attribute] ||= @record[:attributes][attribute]
      end

      def lookup_association(association)
        return nil unless @record[:associations][association].present?
        association_cache[association] ||= Association.new(self,association.to_s.singularize,@record[:associations][association])
      end
    end

    def initialize(api_mock)
      @api = api_mock
      Registry.instance.each_resource do |resource|
        add_resource(resource)
      end
    end

    def add_resource(resource_name)
      Resource.new(resource_name).tap do |resource|
        @api.stubs(resource_name).returns(resource)
      end
    end

    ##
    # Mocks a user. Refactor to use the registry
    def mock_user(barcode,uuid)
      mock('user').tap do |user|
        user.stubs('uuid').returns(uuid)
        mock_user_shared(user,barcode)
      end
    end

    private

    def method_missing(method)
      @api.send(method)
    end

    def mock_user_shared(user,barcode)
      user_search = mock('user_search')
      user_search.stubs(:first).raises(StandardError,'There is an issue with the API connection to Sequencescape (["no resources found with that search criteria"])')
      user_search.stubs(:first).with(:swipecard_code => barcode).returns(user)
      @api.search.stubs(:find).with('e7e52730-956f-11e3-8255-44fb42fffecc').returns(user_search)
    end

  end

  def mock_api
    Api.new(mock('api')).tap do |mock|
      Sequencescape::Api.stubs(:new).returns(mock)
    end
  end

  class Registry

    include Singleton

    def registry
      @registry ||= Hashie::Mash.new(YAML.load(eval(ERB.new(File.read('./test/fixtures/api_models.yml')).src, nil, '../fixtures/api_models.yml')))
    end

    def each_resource
      registry.each {|resource,records| yield resource }
    end

    def find(resource,uuid)
      raise Api::TestError, "No resouce found for #{resource}" if registry[resource].nil?
      registry[resource][uuid] || raise(StandardError, "There is an issue with the API connection to Sequencescape (UUID does not exist)")
    end

  end


end
