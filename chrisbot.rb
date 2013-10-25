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

  def parse_messages
    words = {}
    message = @chat.messages.last
    body = message.body.strip.downcase
    if(@current_message == body)
      return {}
    else 
      @current_message = body
      body.split.each do |word|
        word = word.gsub(/(\W|\d)/, "").strip
        unless(words.has_key?(word))
          words[word] = 0
        end
        words[word] += 1;
      end
      return words
    end
  end

  def at_least_one_match(messages, search_terms)
    search_terms.each do |term|
      if messages.has_key? term
        return true
      end
    end
    return false
  end

  def all_terms_match(messages, search_terms)
    search_terms.each do |term|
      if !messages.has_key? term
        return false
      end
    end
    return true
  end

  def already_ate(messages)
    search_terms = ["food", "lunch", "hungry"] # show if one of these matches
    stop_terms = ["i", "already", "ate", "lunch"] # don't show if all of the match

    if(at_least_one_match(messages, search_terms) && !all_terms_match(messages, stop_terms))
      @chat.post("I already ate lunch")
      puts "I already ate lunch"
    end
  end

  def self.act_as_chris(topic_includes = "cloudspace.com", min_size = 20)
    bot = ChrisBot.new(topic_includes, min_size)

    while true do    
      messages = bot.parse_messages
      puts messages unless messages.empty?
      bot.already_ate(messages)

      sleep(1)
    end
  end
end

ChrisBot.act_as_chris(topic_includes = "cloudspace.com", min_size = 0)
