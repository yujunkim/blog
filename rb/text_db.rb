require 'json'

TABLE_NAME = [
  :naver_blog,
  :tistory,
  :youtube_playlist
]

def db_filename(name)
  "tdb/#{name}.tdb"
end

def db(name)
  return nil unless TABLE_NAME.include?(name)
  @db ||= {}
  @db[name] ||= (JSON.parse(File.open(db_filename(name)).read) rescue {})
end

def db_save(name, *args)
  temp = db(name)
  args.each_with_index do |arg, idx|
    arg = arg.to_s
    if idx == args.count - 2
      temp[arg] = args.last
      break
    else
      temp[arg] ||= {}
      temp = temp[arg]
    end
  end
  db_to_file(name)
end

def db_load(name, *args)
  temp = db(name)
  args.each do |arg|
    temp = temp.send(:[], arg.to_s)
  end
  temp
rescue
  nil
end

def db_to_file(name)
  f = File.open(db_filename(name),'w')
  f.write(db(name).to_json)
  f.close
end

def crawl(blog_type, crawl_type=nil)
  case blog_type
  when :naver_blog
    crawl_naver_blog
  when :tistory
    crawl_tistory(crawl_type)
  end
end

def crawl_naver_blog
  page = 1
  datas = []
  puts "------------------------------------------------------"
  while
    url = "http://blog.naver.com/PostList.nhn?from=postList&blogId=plmmoknn&currentPage=#{page}"
    puts "page : #{page}"
    n = Nokogiri(open(url).read.force_encoding('euc-kr'))
    before_count = datas.count
    puts "before_count : #{before_count}"
    temp_datas = n.css('#postListBody .post').map do |p|
      l = p.css(".post-top .url a").text.split('/').last
      [
        p.css('#yj-type').attr('jsonvalue').text,
        p.css('#yj-date').attr('jsonvalue').text,
        'post_id',
        l #p.css('#yj-log-no').attr('jsonvalue').text
      ]
    end
    temp_datas.each do |t|
      datas << t unless datas.include?(t)
    end
    puts "after_count : #{datas.count}"
    break if before_count == datas.count
    page += 1
  end

  datas.each do |data|
    db_save(:naver_blog, *data)
  end
end

def crawl_tistory(crawl_type = nil)
  def crawl_post_id(page)
    url = "http://yuzun.tistory.com/?page=#{page}"
    puts "page : #{page}"
    n = Nokogiri(open(url).read)
    temp_datas = []
    n.css('div.article').each_with_index do |p, idx|
      post_id = p.to_s.match(/entry[0-9]+/).to_s[5 .. -1]
      if p.css('#yj-type').empty? || p.css('#yj-date').empty?
        puts "#{post_id}'s yj type, yj date is nil"
        next
      end
      yj_type = p.css('#yj-type').attr('jsonvalue').text
      yj_date = p.css('#yj-date').attr('jsonvalue').text
      puts "save to #{yj_type} date: #{yj_date}, post_id: #{post_id}"
      temp_datas << [
        yj_type,
        yj_date,
        'post_id',
        post_id
      ]
    end
    temp_datas
  end

  def crawl_password(page)
    params = {
      "page" => page,
      "pageSize" => 15,
      "category" => -5,
      "sort" => "written",
      "order" => "desc",
      "searchKeyword" => nil,
      "searchType" => "all"
    }
    uri = URI("http://yuzun.tistory.com/admin/entry/list.php")

    req = Net::HTTP::Post.new(uri.path)
    req.set_form_data(params)
    req['Referer'] = "http://yuzun.tistory.com/admin/entry/"
    req['Cookie'] = Tistory.login

    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end
    res_nokogiri = Nokogiri("<div>" + JSON.parse(res.body)['data'] + "</div>")
    id2password = JSON.parse(res_nokogiri.css("#passwordList").attr("value").value)
    temp_datas = []
    res_nokogiri.css("#entryListTable tbody tr.entry").each do |n|
      id = n.attr("id").split("entry").last
      cid = n.css(".category span").attr("class").value.split(" ").select{|x| x.match("cid")}.first.split("cid").last
      cid = cid.to_i

      next if cid == 0

      puts "save to #{Tistory::CATEGORY.invert[cid]} id: #{id}, password: #{id2password[id]}"
      temp_datas << [
        'passwords',
        id,
        id2password[id]
      ]
    end
    temp_datas
  end

  datas = []
  case crawl_type
  when :first
    datas += crawl_post_id(1)
    datas += crawl_password(1)
  else
    [:crawl_post_id, :crawl_password].each do |method|
      page = 1
      while
        before_count = datas.count
        puts "before_count : #{before_count}"
        temp_datas = send(method, page)
        temp_datas.each do |t|
          datas << t unless datas.include?(t)
        end
        puts "after_count : #{datas.count}"
        break if before_count == datas.count
        page += 1
      end
    end
  end

  datas.each do |data|
    db_save(:tistory, *data)
  end

end
