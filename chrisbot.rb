#!/usr/bin/env ruby

require 'googleajax'
require 'clipboard'
require 'skype'

# module GoogleAjax
#   class Search < Results
#     def self.animated(query, latitude, longitude, args = {})
#       args = { :sll => "#{latitude},#{longitude}" }.merge(args)
#       get(:local, query, args)
#     end
#   end
# end

class ChrisBot
  attr_accessor :last_question, :chat, :images

  def initialize(topic_includes = "cloudspace.com", min_size = 20, images=false)
    GoogleAjax.referer = "cloudspace.com"
    self.images = images

    # Get chat if it's doesn't exist
    if @chat.nil?
      @chat = Skype.chats.find{|c| c.members.size > min_size and c.topic.include? topic_includes }
      puts "Found skype chat"
    end

    raise 'No skype chat matching those parameters found' if @chat.nil?
  end

  # Results the url of the first google search result for the given term
  def get_first_google_result(term)
    begin
      if (self.images)
        result = GoogleAjax::Search.images(term, {imgtype: "animated"})[:results][0]
      else
        result = GoogleAjax::Search.web(term)[:results][0]
      end
      
      return nil if result.nil?
      return result[:unescaped_url]
    rescue
      nil
    end
  end

  # Gets the most recent quesiton out of a skype chat with the given params
  def get_most_recent_skype_question
    @chat.messages.reverse.each do |m|
      body = m.body
      last_char = body.strip.split('').last
    
      next if last_char != "?"

      return m
    end
  end

  def answer_last_skype_question
    # Get the most recent question in the cloudspace.com watercooler
    question = get_most_recent_skype_question

    # Dont answer if the question hasn't changed
    return if question.body == @last_question
    
    # Log
    puts question.user + ": " + question.body

    # Get the first search result fo rthat question
    first_search_result_url = get_first_google_result(question.body)

    if first_search_result_url.nil?
      puts "  No results found"
      return
    end

   puts first_search_result_url

    # Put that question into clipboard
    @chat.post first_search_result_url

    #Clipboard.copy first_search_result_url
    @last_question = question.body
  end

  def self.act_as_chris(topic_includes = "cloudspace.com", min_size = 20, images=true)
    bot = ChrisBot.new(topic_includes, min_size, true)

    while true do    
      bot.answer_last_skype_question
      sleep(1)
    end
  end
end

ChrisBot.act_as_chris
