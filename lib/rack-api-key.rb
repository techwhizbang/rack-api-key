require "rack-api-key/version"

##
# RackApiKey is a middleware that relies on the client submitting requests
# with a header named "X-API-KEY" storing their private API key as the value. 
# The middleware will then intercept the request, read the value from the named 
# header and call the given "proc" used for API key lookup. The API key lookup 
# should only return a value if there is an exact match for the value stored in 
# the named API key header. 
# If such a API key exists, the middleware will pass the request onward and also 
# set a new value in the request representing the authenticated API key. Otherwise
# the middleware will return a HTTP status of 401, and a plain text message
# notifying the calling requestor that they are not authorized.
class RackApiKey

	##
	# ==== Options
	# * +:api_key_proc+ - **REQUIRED** A proc that is intended to lookup the API key in your datastore.
	# 										The given proc should take an argument, namely the value of the API key header.
	# 										There is no default value for this option and will raise a 
	# 										NotImplementedError if left unspecified.
	# * +:rack_api_key+ - A way to override the key's name set in the request
	#											on successful authentication. The default value is
	# 										"rack_api_key".
	# * +:header_key+ - A way to override the header's name used to store the API key.
	# 									The value given here should reflect how Rack interprets the
  #                   header. For example if the client passes "X-API-KEY" Rack
  #                   transforms interprets it as "HTTP_X_API_KEY". The default
  #                   value is "HTTP_X_API_KEY".
  # * +:url_restriction+ - A way to restrict specific URLs that should pass through
  #                        the rack-api-key middleware. In order to use pass an Array of Regex patterns.
  #                        If left unspecified all requests will pass through the rack-api-key
  #                        middleware.
	#
	# ==== Example
	#		use RackApiKey, 
	# 			:api_key_proc => Proc.new { |key| ApiKey.where(:key => key).first },
	# 			:rack_api_key => "authenticated.api.key",
	# 			:header_key => "HTTP_X_SECRET_API_KEY"
	def initialize(app, options = {})
		@app = app
		default_options = { 
												:header_key => "HTTP_X_API_KEY", 
											  :rack_api_key => "rack_api_key",
											  :api_key_proc => Proc.new { raise NotImplementedError.new("Caller must implement a way to lookup an API key.") },
                        :url_restriction => []
											}
		@options = default_options.merge(options)
	end

	def call(env)
    
    if @options[:url_restriction].nil? || @options[:url_restriction].empty?      
      process_request(env)
    else 
      request = Rack::Request.new(env)
      url_matches = @options[:url_restriction].select { |url_regex| request.fullpath.match(url_regex) }
      unless url_matches.empty?
        process_request(env)
      else
        @app.call(env)
      end
    end

  end

  ##
  # Sets the API key lookup value in the request. Intentionally left here
  # if anyone wants to change or override what does or does not get set 
  # in the request.
  def rack_api_key_request_setter(env, api_key_lookup_val)
  	env[@options[:rack_api_key]] = api_key_lookup_val
  end

  ##
  # Returns a 401 HTTP status code when an API key is not found or is not
  # authorized. Intentionally left here if anyone wants to override this
  # functionality, specifically change the format of the message or the 
  # media type.
	def unauthorized_api_key
    body_text = "The API key provided is not authorized."
    [401, {'Content-Type' => 'text/plain; charset=utf-8',
					 'Content-Length' => body_text.size.to_s}, [body_text]]
  end

  ##
  # Checks if the API key header value is present and the API key
  # that was returned from the API key proc is present.
  # Intentionally left here is anyone wants to override this functionality.
	def valid_api_key?(api_header_val, api_key_lookup_val)
    !api_header_val.nil? && api_header_val != "" && 
    !api_key_lookup_val.nil? && api_key_lookup_val != ""
  end

  private

  def process_request(env)
    api_header_val = env[@options[:header_key]]
    api_key_lookup_val = @options[:api_key_proc].call(api_header_val)

    if valid_api_key?(api_header_val, api_key_lookup_val)
      rack_api_key_request_setter(env, api_key_lookup_val)
      @app.call(env)
    else
      unauthorized_api_key
    end
  end

end