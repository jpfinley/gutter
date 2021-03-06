Shoes.setup do
  gem 'twitter'
end
require 'twitter'
require 'yaml'
require 'lib/gutter'
require 'lib/gutter_ui'
require 'lib/notify'
require 'lib/tiny_url_support'

# this should go away
cache = File.join(LIB_DIR, "+data")
File.delete(cache) if File.exists?(cache)

class Twitter::Status
  def ==(other)
    self.id == other.id
  end
end

Shoes.app :title => 'Gutter', :width => 450, :scroll => false do
  extend GutterUI 
  extend Notify
  extend TinyURLSupport

  app.slot.scroll(false)

  background black
  stroke white

  ## -- setup
  gtter = Gutter.new
  while gtter.user.blank? || gtter.password.blank?
    gtter.user = ask('Please enter your Twitter Username:')
    gtter.password = ask('Please enter your Twitter Password:', :secret => true)
  end
  gtter.save
  @user = gtter.user
  @twit = Twitter::Base.new(gtter.user, gtter.password)

  send_tweet = lambda do
    @blag.border white
    @twit.post(tinify_urls_in_text(@tweet_text.text), :source => 'gutter')
    @tweet_text.text = ''
    timer(5) { @timeline.clear { draw_timeline } }
  end
  ## - end setup

  @timeline = stack :margin => [0,42,0,0] do
    para "loading"
  end

  flow :attach => Window, :top => 0, :left => 0, :height => 40, :width => width - gutter do # - header
    background '#202020'
    border dimgray
    flow :margin => [5,5,5,0] do
      @tweet_text = edit_line("", :width => width - 140 - gutter) do |e| 
        @counter.text =  140 - (e.text.size || 0)
      end
      @blag = stack :width => 40, :margin_left => 4, :margin_right => 4 do
        background '#303030'
        border dimgray
        inscription "blag", :margin => [4]*4, :stroke => white
        hover { @blag.border gray }
        leave { @blag.border dimgray }
        click { send_tweet.call }
        release { @blag.border gray }
      end
      image('http://toothrot.nfshost.com/gutter/icons/arrow_refresh.png', :click => lambda { @timeline.clear { draw_timeline } }, :margin => [5,5,5,5] )
      para "| ", :stroke => gray
      @counter = strong("140")
      para @counter, :stroke => white
    end
  end # - header

  keypress do |k|
    send_tweet.call if (k == :enter) || (k == "\n")
    @timeline.scroll_top += 3 if k == :up
    @timeline.scroll_top -= 3 if k == :down
  end


  @timeline.clear { draw_timeline }
  every(60*6) do
    @timeline.clear { draw_timeline }
  end

  every(1) do
    @timeline.style(:height => height - 45)
  end

end

