# encoding: UTF-8
module Converter
  def utf_uri(text)
    URI.encode(text)
  end

  def euc_uri(text)
    text_euc_uri = Iconv.iconv('EUC-KR','UTF-8', text).first
    CGI::escape(text_euc_uri)
  end

  def youtube_playlist(list_id)
    case @blog_type
    when :naver_blog
      "<div style=\"text-align: center;\" align=\"center\"><iframe width=\"853\" height=\"480\" src=\"//www.youtube.com/embed/videoseries?list=#{list_id}\" frameborder=\"0\" allowfullscreen=\"\" title=\"titles\" style=\"line-height: 1.5;\"></iframe></div>"
    when :tistory
      "<div class=\"yj-youtube\" style=\"text-align: center;\" align=\"center\" data-list=\"#{list_id}\"></div>"
    end
  end

  def append_js
    case @blog_type
    when :naver_blog
    when :tistory
      %{
        <script type="text/javascript">
        var youtubeWidth = 260;
        var youtubeHeight = 190;
        var UserAgent = navigator.userAgent;
        if (UserAgent.match(/iPhone|iPod|Android|Windows CE|BlackBerry|Symbian|Windows Phone|webOS|Opera Mini|Opera Mobi|POLARIS|IEMobile|lgtelecom|nokia|SonyEricsson/i) != null || UserAgent.match(/LG|SAMSUNG|Samsung/) != null)
        {
          $(".yj-web").hide()
        }
        else
        {
          $(".yj-app").hide()
          youtubeWidth=853;
          youtubeHeight=480;
        }
        var youtubes = document.body.getElementsByClassName("yj-youtube");
        len = youtubes.length
        for(i=0;i<len;i++){
          var youtube = youtubes[i]
          var list_id = youtube.attributes["data-list"].value
          if(youtube.childElementCount == 0) {
            var media=null;
            media = document.createElement('iframe');
            media.setAttribute('src','//www.youtube.com/embed/videoseries?list='+list_id+'&amp;__authenticIframe=true');
            media.setAttribute('width',youtubeWidth);
            media.setAttribute('height',youtubeHeight)
            youtube.appendChild(media);
          }
        }

        </script>
      }
    end
  end

  def music_box(mylist_seq)
    case @blog_type
    when :naver_blog
      "<div style=\"\" align=\"center\"><div id=\"se_object_140230897191430276\" class=\"__se_object\" s_type=\"attachment\" s_subtype=\"music_player\" jsonvalue=\"%7B%22url%22%3A%22http%3A%2F%2Fplayer.music.naver.com%2FnaverPlayer%2Fposting%2F#{mylist_seq}%2FBA%22%2C%22key%22%3A%22#{mylist_seq}%22%2C%22width%22%3A%22500%22%2C%22height%22%3A%22353%22%2C%22type%22%3A%22BA%22%2C%22posting_seq%22%3A%2216349163%22%2C%22thumbnailTitle%22%3A%22%22%7D\"></div><br></div>"
    when :tistory
      %{
        <p>&nbsp;</p><div class="yj-web" style="" align="center"><embed src="http://player.music.naver.com/naverPlayer/posting/#{mylist_seq}/BA" width="500" height="353"></div><p>&nbsp;</p>
        <p>&nbsp;</p>
        <div class="yj-app" style="" align="center"><iframe src="http://vertical.music.naver.com/audio/postingPlayer.nhn?mylist_seq=#{mylist_seq}" frameborder="0" class="_musicPlayer" height="505" style="height: 505px;"></iframe></div>
      }
    end
  end

  def img_tag(image_src, width=700)
    "<div style=\"\" align=\"center\"><img src=\"#{image_src}\" class=\"__se_object\" s_type=\"attachment\" s_subtype=\"image\" style=\"width: #{width}px; clear: both\" width=\"#{width}\" jsonvalue=\"%7B%7D\"></div>"
  end

  def data_tag(id, value)
    "<div id=\"yj-#{id}\" jsonvalue=\"#{value}\" style=\"display:none\"></div>"
  end
end
