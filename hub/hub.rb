class Hub < Sinatra::Base
  use Rack::MethodOverride
  # settings
  set :version, "0.1"
  
  # routes
  get '/' do
    "Hub #{settings.version}"
  end
end

