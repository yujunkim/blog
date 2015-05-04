# encoding: UTF-8
require './converter'
class Tistory
  include Converter
  def initialize(post)
    @post = post
    @type = post.type
  end

  CATEGORY = {
    :tablo => 550175,
    :music_camp => 550815
  }

  def self.login
    puts "login Tistory"
    uri = URI('https://www.tistory.com/auth/login')

    http = Net::HTTP.new(uri.host, 443)
    http.use_ssl = true
    data = "loginId=yuzun.kim%40gmail.com&password=password" # erase password!
    headers = {}
    headers['Origin'] = 'http://www.tistory.com'
    headers['Accept-Encoding'] = 'gzip,deflate,sdch'
    headers['Accept-Language'] = 'ko-KR,ko;q=0.8,en-US;q=0.6,en;q=0.4'
    headers['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/35.0.1916.153 Safari/537.36'
    headers['Content-Type'] = 'application/x-www-form-urlencoded'
    headers['Accept'] = 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8'
    headers['Cache-Control'] = 'max-age=0'
    headers['Referer'] = 'http://www.tistory.com/'
    headers['Connection'] = 'keep-alive'
    resp, data = http.post(uri.path, data, headers )
    cookie = resp.to_hash["set-cookie"].join(";")
    puts "cookie => #{cookie}"
    cookie
  end

  def cookie
    @cookie ||= Tistory.login
  end

  def write_post(data)
    html = data[:html]
    title = data[:title]
    tags = data[:tags]
    traceback = "http://"
    slogan = title.gsub(" ","-")

    tistory_post_nokogiri = Nokogiri(open("http://yuzun.tistory.com/admin/entry/post/",
      "Referer" => "http://yuzun.tistory.com/admin/entry",
      "Cookie" => cookie).read)
    password = tistory_post_nokogiri.css("#password").attr('value').value
    uri = URI('http://yuzun.tistory.com/admin/entry/post/saveEntry.php')
    params = {
      "category" => CATEGORY[@type],
      "title" => title,
      "uselessMarginForEntry" => nil,
      "acceptComment" => 1,
      "acceptTrackback" => 1,
      "password" => password,
      "published" => 0,
      "visibility" => 2,
      "slogan" => slogan,
      "thumbnail" => nil,
      "isKorea" => true,
      "trackback" => traceback,
      "cclCommercial" => 0,
      "cclDerive" => 0,
      "id" => 0,
      "content" => html,
      "isNewEditor" => true,
      "tag" => tags,
      "location" => nil,
      "seq" => 0
    }

    req = Net::HTTP::Post.new(uri.path)
    req.set_form_data(params)
    req['Referer'] = "http://yuzun.tistory.com/admin/entry/post/"
    req['Cookie'] = cookie
    Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    @post.crawl_update = true
  end

  def update_post(data, post_id)
    html = data[:html]
    title = data[:title]
    tags = data[:tags]
    password = db_load(:tistory, *['passwords',post_id.to_s])
    traceback = "http://"
    slogan = title.gsub(" ","-")
    uri = URI('http://yuzun.tistory.com/admin/entry/post/saveEntry.php')

    params = {
      "category" => CATEGORY[@type],
      "title" => title,
      "uselessMarginForEntry" => nil,
      "acceptComment" => 1,
      "acceptTrackback" => 1,
      "password" => password,
      "published" => 0,
      "visibility" => 2,
      "slogan" => slogan,
      "thumbnail" => nil,
      "isKorea" => true,
      "trackback" => traceback,
      "cclCommercial" => 0,
      "cclDerive" => 0,
      "id" => post_id.to_i,
      "content" => html,
      "isNewEditor" => true,
      "tag" => tags,
      "location" => nil,
      "seq" => 0
    }

    req = Net::HTTP::Post.new(uri.path)
    req.set_form_data(params)
    req['Referer'] = "http://yuzun.tistory.com/admin/entry/post/"
    req['Cookie'] = cookie
    Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

  end
end
