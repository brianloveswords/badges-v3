class Backpack < Sinatra::Base
  use Rack::MethodOverride
  set :version, "0.1"
  
  # version
  get '/' do; "Backpack #{settings.version}"; end
end

  
