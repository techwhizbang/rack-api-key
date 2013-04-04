# RackApiKey

RackApiKey is a middleware that relies on the client submitting requests
with a header named "X-API-KEY" storing their private API key as the value. 
The middleware will then intercept the request, read the value from the named 
header and call the given "proc" used for API key lookup. The API key lookup 
should only return a value if there is an exact match for the value stored in 
the named API key header. 
If such a API key exists, the middleware will pass the request onward and also 
set a new value in the request representing the authenticated API key. Otherwise
the middleware will return a HTTP status of 401, and a plain text message
notifying the calling requestor that they are not authorized.

## Installation

Add this line to your application's Gemfile:

    gem 'rack-api-key'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rack-api-key

## Usage

```ruby
		Rack::Builder.new do
		  map '/' do 
				use RackApiKey, :api_key_proc => Proc.new { |val| ApiKey.find(val) }
		    run lambda { |env| [200, {"Content-Type" => "text/html"}, "Testing Middleware"] }
		  end

		  map "/all-options" do
		  	use RackApiKey, 
		  		:api_key_proc => Proc.new { |val| ApiKey.find(val) },
		  		:rack_api_key => "account.api.key",
		  		:header_key => "HTTP_X_CUSTOM_API_HEADER"
		    run lambda { |env| [200, {"Content-Type" => "text/html"}, "Testing Middleware"] }
		  end
		end
```
