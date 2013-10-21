#!/usr/bin/env ruby

require 'googleajax'
require 'skype'
require 'open-uri'

class ChrisBot
  attr_accessor :last_question, :chat

  def initialize(topic_includes = "cloudspace.com", min_size = 20)
    GoogleAjax.referer = "cloudspace.com"

    # Get chat if it's doesn't exist
    if @chat.nil?
      @chat = Skype.chats.find{|c| c.members.size > min_size and c.topic.include? topic_includes }
      puts "Found skype chat"
    end

    raise 'No skype chat matching those parameters found' if @chat.nil?
  end

  # Results the url of the first google search result for the given term
  def get_first_google_result(term, type)
    begin
      case type
        when :animated_image
          puts "Image serach for #{term}"
          result = GoogleAjax::Search.images(term, {imgtype: "animated", safe: "active"})[:results].sample(1)[0]
          result = result[:unescaped_url] if !result.nil?
        when :map 
          puts "Map for #{term}"
          result = "https://www.google.com/maps/preview#!q=" + URI::encode(term)
        else
          puts "Web serach for #{term}"
          result = GoogleAjax::Search.web(term)[:results][0]
          result = result[:unescaped_url] if !result.nil?
      end
      
      return nil if result.nil?
      
      result
    rescue
      nil
    end
  end

  # Gets the most recent quesiton out of a skype chat with the given params
  def get_most_recent_skype_question
    @chat.messages.reverse.each do |m|
      body = m.body.strip

      if body.split('').last == "?"
        return {body: body, user: m.user, type: :question}
      
      elsif body[0..3] == "map-"
        return {body: body[4..-1], user: m.user, type: :map}

      elsif body[0..4] == "map -"
        return {body: body[5..-1], user: m.user, type: :map}

      elsif body[0..3] == "gif-"
        return {body: body[4..-1], user: m.user, type: :animated_image}

      elsif body[0..4] == "gif -"
        return {body: body[5..-1], user: m.user, type: :animated_image}
      end

      next
    end
  end

  def answer_last_skype_question
    # Get the most recent question in the cloudspace.com watercooler
    question = get_most_recent_skype_question
    body = question[:body]
    user = question[:user]
    type = question[:type]

    # Dont answer if the question hasn't changed
    return if body == @last_question

    # Log
    puts "#{user}: #{body}"

    # Get the first search result fo rthat question
    first_search_result_url = get_first_google_result(body, type)

    @last_question = body

    if first_search_result_url.nil?
      puts "  No results found"
      return
    end

     puts first_search_result_url

    # Put that question into clipboard
    case type
      when :animated_image
        @chat.post first_search_result_url + " (bot selected gif, proceed with caution)"
      else
        @chat.post first_search_result_url
    end
  end

  def self.act_as_chris(topic_includes = "cloudspace.com", min_size = 20)
    bot = ChrisBot.new(topic_includes, min_size)

    while true do    
      bot.answer_last_skype_question
      sleep(1)
    end
  end
end

ChrisBot.act_as_chris(topic_includes = "Bot Test", min_size = 0)
