require 'net/http'
require 'active_support'

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
    end

    def method_missing(meth, *args)
      meth = ActiveSupport::Inflector.camelize(meth.to_s, false)
      if args.length == 1
        params = args[0]
      else
        params = {}
      end
      do_get(meth, camelize_params(params))
    end

    private 

    def do_get(action, params = {})
      Net::HTTP.get(build_url(action, params))
    end
    
    def build_url(method, extra_params = {})
      url = URI("http://#{@host}:#{@port}/admin/#{method}")
      url.query = URI.encode_www_form(@base_params.merge(extra_params))
      url
    end

    def camelize_params(params)
      cam_params = {}
      params.each_pair do |key, value|
        cam_params[ActiveSupport::Inflector.camelize(key.to_s, false)] = value
      end
      cam_params
    end

  end
end