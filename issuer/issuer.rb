class Issuer < Sinatra::Base
  use Rack::MethodOverride
  # settings
  set :version, "0.1"
  
  # routes
  get '/' do
    "Issuer #{settings.version}"
  end
end

