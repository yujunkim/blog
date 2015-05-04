# encoding: UTF-8
require 'google/api_client'
require 'google/api_client/client_secrets'
require 'google/api_client/auth/file_storage'
require 'google/api_client/auth/installed_app'
require "./oauth/oauth_util"
require './text_db'
require 'pry'

class Youtube
  CLIENT, YOUTUBE = get_authenticated_service
  NON_AUTH_CLIENT, NON_AUTH_YOUTUBE = get_service
  attr_accessor :playlist_id

  def initialize(post, date)
    @post = post
    @type = post.type
    @date = date

    @playlist_id = db_load(:youtube_playlist, *[@type, @date.to_s, "playlist_id"])

  end

  def title
    case @type
    when :tablo
      "[#{@date.strftime("%Y%m%d")}][꿈꾸라] 타블로와 꿈꾸는 라디오 선곡표"
    when :music_camp
      "[#{@date.strftime("%Y%m%d")}] 배철수의 음악캠프 선곡표"
    end
  end

  def description
    case @type
    when :tablo
      "[blog][#{@type}][#{@date.to_s}] 타블로와 꿈꾸는 라디오 선곡표"
    when :music_camp
      "[blog][#{@type}][#{@date.to_s}] 배철수의 음악캠프 선곡표"
    end
  end

  def initiate_playlist(title, description)
    res = CLIENT.execute!(
      :api_method => YOUTUBE.playlists.insert,
      :parameters => {
        :part => "snippet,status"
      },
      :body_object => {
        :snippet => {
          :title => title,
          :description => description
        },
        :status => {
          :privacyStatus => "public"
        }
      }
    )

    @playlist_id = res.data.id
    db_save(:youtube_playlist, *[@type, @date, "playlist_id", res.data.id])
  end

  def make_playlist(song_infos)
    unless @playlist_id
      initiate_playlist(title, description)
      song_infos.each do |song|
        query = "#{song[:title]} #{song[:artist]}"
        puts "youtube query to : #{query}"
        search_result = search(query).first
        if search_result
          title = search_result.snippet.title
          puts "             add : #{title}"
          add(search_result.id.videoId)
        end
      end
    end

    @playlist_id
  end

  def add(videoId)
    opt = {
      api_method: YOUTUBE.playlist_items.insert,
      parameters: {
        part: 'snippet'
      },
      body_object: {
        snippet: {
          playlistId: @playlist_id,
          resourceId: {
            videoId: videoId,
            kind: "youtube#video"
          }
        }
      }
    }
    CLIENT.execute!(opt)
  end

  def search(query)
    search_response = NON_AUTH_CLIENT.execute!(
      :api_method => NON_AUTH_YOUTUBE.search.list,
      :parameters => {
        :part => 'snippet',
        :q => query,
        :maxResults => 25,
        :type => 'video'
      }
    )

    return search_response.data.items
  end

  def self.crawl_playlist
    opt = {
      api_method: YOUTUBE.playlists.list,
      parameters: {
        part: 'snippet',
        mine: true,
        maxResult: 50
      }
    }

    res = CLIENT.execute!(opt)

    100.times do
      res.data.items.each do |item|
        scans = item.snippet.description.scan(/\[[^\[^\]]+\]/)
        next if scans.count != 3 || scans.first != "[blog]"
        type = scans[1][1 .. -2]
        date = scans[2][1 .. -2]
        puts "#{type}/ #{date} saved"
        db_save(:youtube_playlist, *[type, date, "playlist_id", item.id])
      end

      if res.next_page_token
        res = CLIENT.execute!(res.next_page)
      else
        break
      end
    end
  end
end
