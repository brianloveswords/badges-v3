class Backpack < Sinatra::Base
  use Rack::MethodOverride
  set :version, "0.1"
  
  # version
  get '/' do
    @version = settings.version
    haml :index
  end

  post '/' do
    @version = settings.version
    
    @params = params
    @badges = get_user_badges(params["email"])
    
    haml :backpack
  end

  protected
  def get_user_badges email
    headers = {"From" => email, "Authentication" => "this_is_a_password"}
    badges = JSON.parse(Typhoeus::Request.get('http://hub.rembr.it/badges', :headers => headers).body)
  end
end

  
