require 'hpricot'
require 'open-uri'
class HqueryController < ApplicationController
  def twitter
    params[:id] ||= "wycats"
    url = "#{params[:id]}.xml"
    url = "http://twitter.com/statuses/user_timeline/#{params[:id]}.xml" if not File.exists?(url)
    @tweets = Hpricot(open(url) {|f| f.read })/"status"
    @user   = (@tweets/"user").first
  end
  def search
    yahoo_boss_appid = "YOUR-APPID-HERE"
    params[:q] ||= "hquery"
    url = "http://boss.yahooapis.com/ysearch/web/v1/#{CGI.escape(params[:q])}?appid=#{yahoo_boss_appid}&count=10&start=#{params[:start].to_i * 10}&format=xml"
    @results = (Hpricot(open(url) {|f| f.read})/"result").collect do |result|
      {
        :title => (result/"title").text,
        :abstract => (result/"abstract").text + "<br /><cite></cite>",
        :clickurl => (result/"clickurl").text,
        :url => (result/"url").text.gsub(/^\w+\:\/\//, ''),
        :size => (result/"size").text,
        :cite => (result/"url").text.gsub(/^\w+\:\/\//, '') + " - " + "#{(result/"size").text.to_i / 1024}K "
      }
    end
  end
end
