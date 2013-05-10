require 'spec_helper'

describe RackApiKey do
  include Rack::Test::Methods

  class Account; end

  class ApiKey

    attr_reader :value

    def initialize(value)
      @value = value
    end

    def self.find(value)
      nil
    end

    def account
      Account.new
    end

  end

  # simple test app for the middleware test
  def app

    Rack::Builder.new do
      map '/' do 
        use RackApiKey, :api_key_proc => Proc.new { |val| ApiKey.find(val) }
        run lambda { |env| [200, {"Content-Type" => "text/html"}, "Testing Middleware"] }
      end

      map "/no-api-proc" do
        use RackApiKey
        run lambda { |env| [200, {"Content-Type" => "text/html"}, "Testing Middleware"] }
      end

      map "/all-options" do
        use RackApiKey,
          :api_key_proc => Proc.new { |val| ApiKey.find(val) },
          :rack_api_key => "account.api.key",
          :header_key => "HTTP_X_CUSTOM_API_HEADER"
        run lambda { |env| [200, {"Content-Type" => "text/html"}, "Testing Middleware"] }
      end

      map "/url-restricted" do
        use RackApiKey,
          :api_key_proc => Proc.new { |val| ApiKey.find(val) },
          :url_restriction => [/url-restricted\/foo/]
        run lambda { |env| [200, {"Content-Type" => "text/html"}, "Testing Middleware"] }
      end

      map '/url-exclusion' do
        use RackApiKey,
          :api_key_proc => Proc.new { |val| ApiKey.find(val) },
          :url_exclusion => [/url-exclusion\/foo/]
        run lambda { |env| [200, { 'Content-Type' => 'text/html' }, 'Testing Middleware'] }
      end

    end

  end

  context "when using the predefined default middleware options" do

    it 'attempts to find the ApiKey with the header value' do
      ApiKey.should_receive(:find).with("SECRET API KEY")
      get "/", {}, "HTTP_X_API_KEY" => "SECRET API KEY"
    end

    it 'responds with a 200 upon successful authorization' do
      ApiKey.stub(:find).and_return(ApiKey.new("SECRET API KEY"))
      get "/", {}, "HTTP_X_API_KEY" => "SECRET API KEY"
      last_response.ok?.should be_true
    end

    it 'responds with a 401 when the ApiKey is not found' do
      ApiKey.stub(:find).and_return(nil)
      get "/", {}, "HTTP_X_API_KEY" => "SECRET API KEY"
      last_response.status.should == 401
    end

    it 'responds with a 401 when the header is not set' do
      header("HTTP_X_API_KEY", nil)
      get "/"
      last_response.status.should == 401
    end

    it 'responds with a JSON formatted error message' do
      header("HTTP_X_API_KEY", nil)
      get "/"
      last_response.body.should == "The API key provided is not authorized."
    end

    it 'sets the api key in the env' do
      ApiKey.stub(:find).and_return(api_key = ApiKey.new("SECRET API KEY"))
      get "/", {}, "HTTP_X_API_KEY" => "SECRET API KEY"
      last_request.env['rack_api_key'].should == api_key
    end

  end

  context "when the API key lookup proc is not provided" do

    it 'raises an error' do
      expect { get "/no-api-proc", {}, {} }.to raise_error(NotImplementedError, "Caller must implement a way to lookup an API key.")
    end

  end

  context "when all the options are specified" do

    it 'attempts to find the ApiKey with the header value' do
      ApiKey.should_receive(:find).with("SECRET API KEY")
      get "/all-options", {}, "HTTP_X_CUSTOM_API_HEADER" => "SECRET API KEY"
    end

    it 'responds with a 200 upon successful authorization' do
      ApiKey.stub(:find).and_return(ApiKey.new("SECRET API KEY"))
      get "/all-options", {}, "HTTP_X_CUSTOM_API_HEADER" => "SECRET API KEY"
      last_response.ok?.should be_true
    end

    it 'sets the api key in the env' do
      ApiKey.stub(:find).and_return(api_key = ApiKey.new("SECRET API KEY"))
      get "/all-options", {}, "HTTP_X_CUSTOM_API_HEADER" => "SECRET API KEY"
      last_request.env['account.api.key'].should == api_key
    end

  end

  context "when URL restriction is used" do

    context "and the requesting URL matches the restricted list" do

      it 'attempts to find the ApiKey with the header value' do
        ApiKey.should_receive(:find).with("SECRET API KEY")
        get "/url-restricted/foo", {}, "HTTP_X_API_KEY" => "SECRET API KEY"
      end

      it 'responds with a 200 upon successful authorization' do
        ApiKey.stub(:find).and_return(ApiKey.new("SECRET API KEY"))
        get "/url-restricted/foo", {}, "HTTP_X_API_KEY" => "SECRET API KEY"
        last_response.ok?.should be_true
      end

      it 'responds with a 401 when the header is not set' do
        header("HTTP_X_API_KEY", nil)
        get "/url-restricted/foo"
        last_response.status.should == 401
      end

    end

    context "and the requesting URL is not in the restricted list" do

      it 'does not attempt to find the ApiKey with the header value' do
        ApiKey.should_not_receive(:find).with("SECRET API KEY")
        get "/url-restricted/bar"
      end

      it 'responds with a 200 without the header set' do
        get "/url-restricted/bar"
        last_response.ok?.should be_true
      end

    end

  end

  context 'when URL exclusion is used' do

    context 'and the requesting URL matches the excluded list' do

      it 'does not attempt to find the ApiKey with the header value' do
        ApiKey.should_not_receive(:find)
        get '/url-exclusion/foo'
      end

      it 'responds with a 200 without the header set' do
        get '/url-exclusion/foo'
        last_response.should be_ok
      end

    end

    context 'and the requesting URL is not in the exclusion list' do

      it 'attempts to find the ApiKey with the header value' do
        ApiKey.should_receive(:find).with('SECRET API KEY')
        get '/url-exclusion/bar', {}, 'HTTP_X_API_KEY' => 'SECRET API KEY'
      end

      it 'responds with a 200 upon successful authorization' do
        ApiKey.stub(:find).and_return(ApiKey.new('SECRET API KEY'))
        get '/url-exclusion/bar', {}, 'HTTP_X_API_KEY' => 'SECRET API KEY'
        last_response.should be_ok
      end

      it 'responds with a 401 when the header is not set' do
        header('HTTP_X_API_KEY', nil)
        get '/url-exclusion/bar'
        last_response.status.should eq 401
      end

    end

  end
end