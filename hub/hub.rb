class Hub < Sinatra::Base
  use Rack::MethodOverride
  # settings
  set :version, "0.1"
  set :db_path, "http://127.0.0.1:5984"
  
  # routes
  get '/' do; "Hub #{settings.version}"; end
  
  post '/issuer/register' do
    path_to_identity = params['identity']
    secret_phrase = encrypt(params['phrase'])
    contents = JSON.parse(Typhoeus::Request.get(path_to_identity).body)
    
    unless contents['secret'] == secret_phrase
      headers = {'Content-Type' => 'text/plain'}
      body = {:error => "phrase_mismatch", "reason" => "The phrase submitted does not match the identity file."}.to_json
      return [403, headers, body]
    end
    
    # contents['name']
    # store that sucker in the database
  end
  
  protected
  def encrypt phrase
    Digest::SHA2.new(256).update(phrase).to_s
  end
end

