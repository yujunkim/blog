# encoding: UTF-8
class MBC
  class NotUploaded < Exception ; end
  MBC_URL = "http://mini.imbc.com/manager/"
  def initialize(post)
    @post = post
    @type = post.type
  end

  def get_data(date)
    data = {}
    data[:song_infos] = song_infos(song_list_datas[date.to_s])
    data[:image_srcs] = get_images[date.to_s] || []
    data[:menu] = get_menu[date.wday]
    data
  end

  def song_infos(url)
    raise NotUploaded unless url
    url = MBC_URL + url

    song_list_nokogiri = Nokogiri::HTML(open(url).read.force_encoding('euc-kr'))
    song_list = song_list_nokogiri.css('.list_tb tbody tr').map do |x|
      {
        title: x.css('td p').text.strip,
        artist: x.css('.td_artist').text.strip
      }
    end
    song_list = song_list.select do |x|
      !x[:title].nil? && x[:title] != "" && !x[:artist].nil? && x[:artist] != ""
    end

    song_list
  end

  def song_list_datas
    def song_list_index_url(page=1)
      url = "SelectList.asp?PROG_CD="
      url +=case @type
      when :tablo
        "FM4U000001200"
      when :music_camp
        "RAMFM300"
      end
      url + "&PG=#{page}"
    end
    def _song_list_datas
      song_list_datas = {}
      10.times do |i|
        page = i+1
        song_list_page_nokogiri = Nokogiri::HTML(open(MBC_URL + song_list_index_url(page)).read)
        temp_song_list_data = {}
        song_list_page_nokogiri.css('.select_tb tr').each do |x|
          next if x.css('a').empty?
          date_s = x.css('td')[1].text.match(/20[0-9]+-[0-9]+-[0-9]+/).to_s
          temp_song_list_data[date_s] = x.css('a').attr('href').to_s
        end
        break if temp_song_list_data.empty?
        song_list_datas.merge!(temp_song_list_data)
      end
      song_list_datas
    end

    @song_list_datas ||= _song_list_datas
  end

  def get_images
    def _get_images
      image_hash = {}
      case @type
      when :tablo
        before_crawl = {}

        page = 1
        while
          page_url = "http://imbbs.imbc.com/list.mbc?bid=dreamradio08&page=#{page}"
          blonote_page = Nokogiri::HTML(open(page_url).read.force_encoding('euc-kr'))

          temp_crawl = {}
          blonote_page.css("[headers='bbs_img'] img").each do |img|
            onerror = img.attr("onerror")
            alt = img.attr("alt")
            img_src = nil
            img_src = onerror.match(/\'[^']+\'/).to_s[1 .. -2] if onerror
            date = nil
            date = (Date.parse(alt.split(' ').first).to_s rescue nil) if alt
            if img_src && date
              temp_crawl[date] ||= []
              temp_crawl[date] << img_src
            end
          end

          break if temp_crawl == before_crawl
          before_crawl = temp_crawl
          temp_crawl.each do |date, srcs|
            image_hash[date] ||= []
            image_hash[date] += srcs
          end
          page += 1
        end

        page = 1
        while
          page_url = "http://imbbs.imbc.com/list.mbc?bid=dreamradio05&page=#{page}"
          guest_page = Nokogiri::HTML(open(page_url).read.force_encoding('euc-kr'))

          temp_crawl = {}
          guest_page.css(".bbs_list_img .bbs_list_img img").each do |img|
            onerror = img.attr("onerror")
            alt = img.attr("alt")
            img_src = nil
            img_src = onerror.match(/\'[^']+\'/).to_s[1 .. -2] if onerror
            date = nil
            date = (Date.parse(alt.split(' ').first).to_s rescue nil) if alt
            if img_src && date
              temp_crawl[date] ||= []
              temp_crawl[date] << img_src
            end
          end

          break if temp_crawl == before_crawl
          before_crawl = temp_crawl
          temp_crawl.each do |date, srcs|
            image_hash[date] ||= []
            image_hash[date] += srcs
          end
          page += 1
        end
      end
      image_hash.each do |date, srcs|
        image_hash[date] = image_hash[date].uniq
      end

      image_hash
    end
    @get_images ||= _get_images
  end

  def get_menu
    def _get_menu
      menu = {}
      case @type
      when :tablo
        ""
      when :music_camp
        ment_nokogiri = Nokogiri::HTML(open("http://www.imbc.com/broad/radio/fm4u/musiccamp/mcamp_info/").read.force_encoding('euc-kr'))
        ment_nokogiri.css(".mainCon .menuIntro dl").each do |menu|
          dt = menu.css("dt").text
          dd = menu.css("dd").text
          day = dt.match(/\[[^\[^\]]\]/).to_s
          if day
            wday = case day
            when "[월]" then 1
            when "[화]" then 2
            when "[수]" then 3
            when "[목]" then 4
            when "[금]" then 5
            when "[토]" then 6
            when "[일]" then 0
            else
              -1
            end
            menu[wday] = [dt, dd]
          end
        end
      end
      menu
    end
    @get_menu ||= _get_menu
  end

end
