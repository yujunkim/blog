# encoding: UTF-8
require 'date'
require './text_db'
require './converter'

class NaverMusic
  include Converter
  NAVER_QUERY_URL = "http://music.naver.com/search/search.nhn?query="
  def initialize(post, date)
    @post = post
    @type = post.type
    @date = date
  end

  def title
    case @type
    when :tablo
      "[#{@date.strftime("%Y%m%d")}][꿈꾸라] 타블로와 꿈꾸는 라디오 선곡표"
    when :music_camp
      "[#{@date.strftime("%Y%m%d")}] 배철수의 음악캠프 선곡표"
    end
  end

  def make_playlist(song_infos)
    @song_infos = song_infos
    mylist_nokogiri = Nokogiri(open('http://player.music.naver.com/mylist.nhn').read)

    mylist_seq = mylist_nokogiri.text.match('mylist_seq = [0-9]+').to_s[13 .. -1].to_i
    puts mylist_seq

    open("http://player.music.naver.com/mylist.nhn?m=insertMyListTemp&mylist_seq=#{mylist_seq}&trackid=,#{song_ids.join(',')}&title=#{ utf_uri(title) }&linkYn=N")
    uri = URI('http://player.music.naver.com/mylist.nhn')

    params = {
      "mylist_seq" => mylist_seq,
      "m" => "insertMyList",
      "title" => utf_uri(title),
      "ctype" => ctype,
      "site" => "B",
      "firstTrackId" => song_ids.first,
      "rad" => "BA",
      "linkYn" => "Y"
    }

    req = Net::HTTP::Post.new(uri.path)
    req.set_form_data(params)
    req['Cookie'] ='NNB=YLXBSFUGBOQFC; NB=HE2TGMRSGQYDSNRQ; npic=upzXgATKcNn+fj5aqUTduzajFPKrGT+8WdkN+r1/itHPZ2AReEvC/9j8+VAQeOS5CA==; stat_guestid=13694583493531q2mFP71; __gads=ID=75145ed6c8f18a93:T=1374249071:S=ALNI_MbE7KnhCOkb6JnTEEYI7KMwq6jsdQ; stat_yn=1; NNF=off; nid_tct=Pp8xbq5sjlGZzp73; visitcount|artist325=artist325; visitcount|sfire21=sfire21; visitcount|bookui87z=bookui87z; visitcount|ldt_CmI; BMR=s=1401847921753&r=http%3A%2F%2Fm.news.naver.com%2Fread.nhn%3Fmode%3DLSD%26mid%3Dsec%26sid1%3D102%26oid%3D421%26aid%3D0000855875&r2=https%3A%2F%2Fwww.facebook.com%2F; page_uid=dP5E5spyLPlssuY+VORsssssssV-017983; NID_AUT=nczV3VBx5Z1WkJV0zkz9bMl9ORwYwXVs/mIT1CJpLUar18pelvwVYDG195iv9AQqrY6xp7ImwO03qyDELvIK5xmsJj0I9sb85EuIUAIvPBPB6DerzKu2NYau1Y8uot6L; NID_SES=AAABTK7xhPDfjO4oEJTB+vOgDPZn9LtJtJhwi120kKzpWe9449swoMBHMDHYxysLkcsfdZV+CAITg0XGbQxbDCIeOhflp/m+GjLcgX6Sf54aEm1mp2sETD8MC/9PsvC0gBAOUxJn5261mR4IqVO2q4h6PUCuqSIMDLeuoHqIEoEeesTj688QVvzXb+6uQX67AumdXYZ4zT8fewJqYlohfXR4v9+GKqG5dw03uDUw0MSYo22ZuDL6c5M/oGN3KZSnT1BORPHp+6Sjft07LE7tBWM7edaVGxTkgAbdn0xTA6K2gTnGDXdJrFpi581AVB8MwD0PsxKrviAwD38dyyCK0G4d9fNZPIF2GsLaLQ4IN39Z3rCJFsih6YQ7lNnXmlYu6qSJCOFb3O7uPU37ocmnMLF3SH9t6ojjOSmONFTRqggLIxQNRVzix0czPVrfZHdFRPfklQ==; JSESSIONID=09CB3219B63DBF69E12627A1527D5AFE.jvm1'

    Net::HTTP.start(uri.hostname, uri.port) do |http|
      http.request(req)
    end

    mylist_seq
  end

  def song_ids
    @song_ids ||= _song_ids
  end

  def _song_ids
    song_ids = []
    @song_infos.each do |song|
      naver_url = "#{NAVER_QUERY_URL}#{song[:title]} #{song[:artist]}"
      puts "query to : #{naver_url}"
      naver_query_nokogiri = Nokogiri(open(URI.encode(naver_url)).read)

      trackdatas = naver_query_nokogiri.css(".tracklist_table ._tracklist_move").collect{|x| x.attr("trackdata")}
      trackdatas.shift
      popular_gauges = naver_query_nokogiri.css(".tracklist_table ._tracklist_move .popular em").collect{|x| x.text.to_i}
      tid_popular = {}
      trackdatas.each_with_index do |x, idx|
        tid = x.split("|").first
        tid_popular[tid] = if x.split("|")[2] == 'true'
          popular_gauges[idx] - idx
        else
          -10
        end
      end
      tid_popular = tid_popular.sort_by{|k,v| v}.reverse
      unless tid_popular.empty?
        next if tid_popular.first.last == -10
        song_ids << tid_popular.first.first unless tid_popular.empty?
      end
    end

    song_ids
  end

  def ctype
    case @type
    when :tablo
      "C07"
    when :music_camp
      "C02"
    else
      "C07"
    end
  end
end
