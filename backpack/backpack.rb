class Backpack < Sinatra::Base
  use Rack::MethodOverride
  set :version, "0.1"
  
  # version
  get '/' do
    @version = settings.version
    haml :index
  end
end

  
