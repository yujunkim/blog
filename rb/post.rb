# encoding: UTF-8
require 'open-uri'
require 'net/http'
require 'nokogiri'
require 'iconv'
require 'cgi'
require 'json'
require 'date'
require 'pry'
require 'date'
require './text_db'
require './converter'
require './mbc'
require './naver_music'
require './youtube'
require './naver_blog'
require './tistory'

class Post
  include Converter
  SUPPORT_TYPE = [:tablo,:music_camp]
  SUPPORT_BLOG = [:naver_blog, :tistory]

  attr_reader :blog_type, :type
  attr_accessor :crawl_update

  def initialize(blog_type, type)
    @type = type
    @mbc = MBC.new(self)
    #@blog_type = :naver_blog
    @blog_type = blog_type
  end

  def blog
    def _blog
      case @blog_type
      when :naver_blog
        NaverBlog.new(self)
      when :tistory
        Tistory.new(self)
      end
    end
    @blog ||= _blog
  end

  def tags(addon=[])
    common_tags = []
    specific_tags = case @type
    when :tablo
      ["타블로","꿈꾸라","라디오","선곡표","바로듣기","타블로와 꿈꾸는 라디오"]
    when :music_camp
      ["배철수","음악캠프","라디오","선곡표","바로듣기","배철수의 음악캠프"]
    else
      []
    end
    (common_tags + specific_tags + addon).join(',')
  end


  def title(date)
    case @type
    when :tablo
      "[꿈꾸라] 타블로와 꿈꾸는 라디오 선곡표 #{date.strftime("%Y%m%d")}"
    when :music_camp
      "배철수의 음악캠프 선곡표 #{date.strftime("%Y%m%d")}"
    end
  end

  def before_contents(post_data = {})
    case @type
    when :tablo
      []
      #["<div style=\"\" align=\"center\"><p>타타타타타ㅏㅌ타으블로</p></div><div style=\"\" align=\"center\"><p></p></div>"]
    when :music_camp
      menu = post_data[:menu]
      if menu
        [
          "<div style=\"\" align=\"center\"><p><b>#{menu[0]}</b></p></div>",
          "<div style=\"\" align=\"center\"><p>#{menu[1]}</p></div>"
        ]
      else
        []
      end
    else
      []
    end
  end

  def after_contents(post_data = {})
    case @type
    when :tablo
      []
    when :music_camp
      [img_tag("http://www.paxmusic.co.kr/html/images/2105950.jpg", 500) ]
    else
      []
    end
  end

  def post_during(sdate, edate)
    @mbc.song_list_datas.keys.reverse.each do |date_s|
      if date_s >= sdate.to_s && date_s <= edate.to_s
        date = Date.parse(date_s)
        posting(date, false)
      end
    end

    crawl(@blog_type) if @crawl_update
  end

  def post_all
    @mbc.song_list_datas.keys.reverse.each do |date_s|
      date = Date.parse(date_s)
      posting(date, false)
    end

    crawl(@blog_type) if @crawl_update
  end

  def posting(date, last_posting = true)
    data = @mbc.get_data(date)
    song_infos = data[:song_infos]

    data[:naver_music_playlist_id] = NaverMusic.new(self, date).make_playlist(song_infos)
    data[:youtube_playlist_id] = Youtube.new(self, date).make_playlist(song_infos)
    data[:html] = get_html(date, data)
    data[:title] = title(date)
    data[:tags] = tags
    data[:date] = date

    post_id = db_load(@blog_type, *[@type, date.to_s, "post_id"])
    if post_id
      puts "#{date.to_s} // update to post_id : #{post_id}"
      blog.update_post(data, post_id)
    else
      puts "#{date.to_s} // write new post"
      blog.write_post(data)
    end

    crawl(@blog_type, :first) if last_posting && @crawl_update
  end

  def get_html(date, post_data={})
    naver_music_playlist_id = post_data[:naver_music_playlist_id]
    youtube_playlist_id = post_data[:youtube_playlist_id]
    image_srcs = post_data[:image_srcs]
    imgs = image_srcs.map {|image_src| img_tag(image_src)}

    html = ""
    html += before_contents(post_data).join("<p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p>")
    html += "<p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p>"
    html += youtube_playlist(youtube_playlist_id)
    html += "<p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p>"
    html += music_box(naver_music_playlist_id)
    html += "<p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p>"
    html += imgs.join("<p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p>")
    html += "<p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p>"
    html += after_contents(post_data).join("<p>&nbsp;</p><p>&nbsp;</p><p>&nbsp;</p>")

    html += data_tag('date', date.to_s)
    html += data_tag('type', @type)
    html += append_js
    html
  end


end
