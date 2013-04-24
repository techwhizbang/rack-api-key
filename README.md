# RackApiKey

[![Build Status](https://travis-ci.org/techwhizbang/rack-api-key.png)](https://travis-ci.org/techwhizbang/rack-api-key)

RackApiKey is a middleware that relies on the client submitting requests
with a header named "X-API-KEY" storing their private API key as the value.
The middleware will then intercept the request, read the value from the named 
header and call the given "proc" used for API key lookup. The API key lookup 
should only return a value if there is an exact match for the value stored in 
the named API key header. 
If such an API key exists, the middleware will pass the request onward and also
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
use RackApiKey, :api_key_proc => Proc.new { |val| ApiKey.find(val) },
		  					:rack_api_key => "account.api.key",
		  					:header_key => "HTTP_X_CUSTOM_API_HEADER"
```

### :header_key
It's important to note that internally Rack actually mutates any given headers
and prefixes them with HTTP and subsequently underscores them. For example if an
API client passed "X-API-KEY" in the header, Rack would interpret that header
as "HTTP_X_API_KEY". "HTTP_X_API_KEY" is the default header. If you want to use
a different header you can specify it in the :header_key options Hash.

### :api_key_proc
This is required, there is no default behavior, and the middleware will not work
properly unless you specify a Proc that takes one argument.
The value the Proc receives will be the value set in the API header key.
Use anything you like to determine if the header value
is valid. If the value is invalid, the Proc should return nil, otherwise return
a value that will ultimately be set in the Rack env.

### :rack_api_key
This is the key that will be set in the Rack env with the return value of the
:api_key_proc.

### unauthorized_api_key method
This is a method that can be overridden with however you'd like to respond
when a request with an invalid or unauthorized API key is encountered. The default
behavior responds with a 401 plain/text message. I find it especially useful to
override this method and switch the response to JSON format.

### valid_api_key? method
This is another method that can be overridden if there are additional checks
and validations beyond the ones already provided. For instance the API key
may exist, but for some reason it was temporarily disabled. You could add a check
for that here.

### rack_api_key_request_setter method
The default behavior of this method will take the return value of the API key
proc and set it to the Rack env with the ke specified by :rack_api_key. You
may override this method if you prefer setting something else in the Rack env 
or perhaps nothing at all.

## Examples

```ruby
# Overridden to use the default behavior plus check if the api key is enabled.
def valid_api_key?(api_header_val, api_key_lookup_val)
  super && api_key_lookup_val.enabled?
end
```

```ruby
# Overridden to respond in JSON format. 
def unauthorized_api_key
 	body_text = {"error" => "blah blah blah"}.to_json
  [401, {'Content-Type' => 'application/json; charset=utf-8',
         'Content-Length' => body_text.size.to_s},
  [body_text]]
end
```

```ruby
# Overridden to set the Account attached to the API key instead.
def rack_api_key_request_setter(env, api_key_lookup_val)
  env[@options[:rack_api_key]] = api_key_lookup_val.account
end
```

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
