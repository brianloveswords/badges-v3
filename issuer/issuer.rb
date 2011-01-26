
class Issuer < Sinatra::Base
  use Rack::MethodOverride
  # settings
  set :version, "0.1"
  set :secret, 'badgegiver'
  # routes
  get '/' do; "Issuer #{settings.version}"; end

  # Providing identity
  get '/identity.json' do
    {:name => 'Test Issuer', :secret => encrypt(settings.secret)}.to_json
  end

  # register identity with the hub
  get '/register' do
    data = {:identity => 'http://issuer.rembr.it/identity.json', :phrase => settings.secret}
    Typhoeus::Request.post('http://hub.rembr.it/issuer/register', :params => data).body
  end
  
  protected
  def encrypt phrase
    Digest::SHA2.new(256).update(phrase).to_s
  end
end



