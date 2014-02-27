require 'net/http'
require 'active_support/all'

module FMS
  class Client

    attr_reader :host, :port, :base_params

    def initialize(options = {})
      raise ArgumentError, ":host option is required" unless options.include? :host

      defaults = {:auser => 'fms', :apswd => 'fms', :port => 1111}
      defaults.update(options)

      @host = defaults[:host]
      @port = defaults[:port]
      @base_params = {:auser => defaults[:auser], :apswd => defaults[:apswd]}
      @timeout = options[:timeout]
    end

    def method_missing(meth, *args)
      meth = ActiveSupport::Inflector.camelize(meth.to_s, false)
      if args.length == 1
        params = args[0]
      else
        params = {}
      end
      Response.new do_get(meth, camelize_params(params)).strip
    end

    private

    def do_get(action, params = {})
      url = build_url action, params
      http_client = HTTPClient.new @host, @port
      resp = http_client.get url, @timeout
      raise NoMethodError, "#{action.inspect} is not a valid API method" unless resp.code == "200"
      resp.body
    end

    def build_url(method, extra_params = {})
      params = URI.encode_www_form(@base_params.merge(extra_params))
      uri = URI.parse "http://#{@host}:#{@port}/admin/#{method}?#{params}"
      uri.request_uri
    end

    def camelize_params(params)
      cam_params = {}
      params.each_pair do |key, value|
        cam_params[ActiveSupport::Inflector.camelize(key.to_s, false)] = value
      end
      cam_params
    end

  end

  class HTTPClient

    def initialize(host, port)
      @host = host
      @port = port
    end

    def get(url, timeout)
      http = Net::HTTP.new @host, @port
      unless timeout.nil?
        http.read_timeout = timeout
        http.open_timeout = timeout
      end
      http.request Net::HTTP::Get.new(url)
    end

  end

  class Response < ActiveSupport::HashWithIndifferentAccess
    SUCCEED_CODE = 'NetConnection.Call.Success'

    def initialize(content)
      super(Hash.from_xml(content)) if content.present?
    end

    def level
      self[:result][:level]
    end

    def code
      self[:result][:code]
    end

    def timestamp
      self[:result][:timestamp]
    end

    def data
      self[:result][:data]
    end

    def succeed?
      code == SUCCEED_CODE
    end

  end

end
