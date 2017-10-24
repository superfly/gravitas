require 'sinatra'
require 'rbnacl/libsodium'
require 'rbnacl'
require 'base64'
require 'faraday'

default_key = ENV['GRAVITAS_KEY']
pad_pattern = /^([a-zA-Z0-9]+:)/
get '/:data' do
  key = request.env['HTTP_GRAVITAS_KEY']
  key = default_key if key.nil? || key == ""

  data = params[:data]
  data = begin
           Base64.urlsafe_decode64(data)
         rescue
           halt(404, "Not found: #{data}")
         end

  gravatar_path = secure_box(key).decrypt(data)

  gravatar = "https://www.gravatar.com/avatar#{gravatar_path}"
  puts "GET: #{gravatar_path}"

  resp = begin
           Faraday.get(gravatar)
         rescue
           halt(500, "Error getting gravatar: #{$!.message}")
         end

  status response.status

  resp.headers.each do |k,v|
    if k == "content-disposition"
      v = v.gsub(/filename="(.*)\.([^\.]*)"/, 'filename="' + params[:data] + '.\2"')
    end

    if /[a-f0-9]{32}/.match(v)
      # this header probably has md5s
      logger.debug "(nuking leaky header) #{k}: #{v}"
      v = nil
    end

    response.headers[k] = v if v
  end

  response.write(resp.body)
end

get '/avatar/:md5' do
  url = generate_avatar
  status 301
  response.headers['Location'] = url
  url
end
post '/avatar/:md5' do
  generate_avatar
end

def generate_avatar
  key = request.env["HTTP_AUTHORIZATION"]
  vkey = request.env["HTTP_GRAVITAS_KEY"]
  vkey = default_key if vkey.nil? || vkey == ""

  if key != vkey
    halt(401, 'Unauthorized')
  end

  path = params[:md5]
  if request.query_string != ""
    path = path + "?" + request.query_string
  end

  box = secure_box(key)

  param = Base64.urlsafe_encode64(box.encrypt(path)).sub(/=+$/, '')
  base_path = request.env['HTTP_X_FORWARDED_URI']
  if base_path && base_path != ""
    puts base_path
    pattern = /\A(.*)#{Regexp.escape("/avatar/#{params[:md5]}")}.*\z/i
    puts pattern.inspect
    base_path = base_path.sub(pattern, '\1')
  end

  request.scheme + "://#{request.host}#{base_path}/#{param}"
end

def secure_box(key)
  key = begin
          Base64.urlsafe_decode64(key)
        rescue
          halt(400, "Invalid key")
        end

  RbNaCl::SimpleBox.from_secret_key(key)
end
