#!/usr/bin/env ruby
# encoding: UTF-8
case ARGV.last
when "y"
  `rm oauth/oauth2-token.json`
end
require './post'

#Post.new(:tistory, :music_camp).post_all
#crawl_tistory
#Youtube.crawl_playlist
  #Post.new(:tistory, :tablo).posting(Date.today - 1)
  #Post.new(:tistory, :music_camp).posting(Date.today - 1)
#Post.new(:tistory, :tablo).post_during(Date.parse("2014-07-07"), Date.parse("2014-07-09"))
#Post.new(:tistory, :music_camp).post_during(Date.parse("2014-07-07"), Date.parse("2014-07-09"))
#


case ARGV.first
when "y"
  Post.new(:tistory, :music_camp).posting(Date.today - 2)
  Post.new(:tistory, :tablo).posting(Date.today - 2)
  Post.new(:tistory, :music_camp).posting(Date.today - 1)
  Post.new(:tistory, :tablo).posting(Date.today - 1)
when "t"
  Post.new(:tistory, :tablo).posting(Date.today)
when "m"
  Post.new(:tistory, :music_camp).posting(Date.today)
when 'ty'
  Post.new(:tistory, :tablo).posting(Date.today - 1)
when 'my'
  Post.new(:tistory, :music_camp).posting(Date.today - 1)
when "cn"
  crawl_naver_blog
when "ct"
  crawl_tistory
end

