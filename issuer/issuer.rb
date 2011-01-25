class Issuer < Sinatra::Base
  use Rack::MethodOverride
  # settings
  set :version, "0.1"
  
  # routes
  get '/' {"Issuer #{settings.version}"}
end

