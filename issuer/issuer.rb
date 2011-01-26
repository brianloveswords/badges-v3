class Issuer < Sinatra::Base
  use Rack::MethodOverride
  # settings
  set :version, "0.1"
  
  # routes
  get '/' do; "Issuer #{settings.version}"; end

  # Providing identity
  get '/identity.json' do
    {:name => 'Test Issuer', :secret => encrypt('awesometown')}.to_json
  end

  protected
  def encrypt phrase
    Digest::SHA2.new(256).update(phrase).to_s
  end
end



