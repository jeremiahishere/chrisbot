#!/usr/bin/env ruby

require 'googleajax'
require 'clipboard'
require 'skype'

# Results the url of the first google search result for the given term
def get_first_google_result(term)
  GoogleAjax.referer = "cloudspace.com"

  result = GoogleAjax::Search.web(term)[:results][0]

  return result[:unescaped_url]
end

# Gets the most recent quesiton out of a skype chat with the given params
def get_most_recent_skype_question(topic_includes = "cloudspace.com", min_size = 20)
  chat = Skype.chats.find{|c| c.members.size > min_size and c.topic.include? topic_includes }

  raise 'No skype chat matching those parameters found' if chat.nil?

  chat.messages.reverse.each do |m|
    body = m.body
    last_char = body.strip.split('').last
  
    next if last_char != "?"

    return body
  end
end


def acts_as_chris
  # Get the most recent question in the cloudspace.com watercooler
  question = get_most_recent_skype_question

  # Get the first search result fo rthat question
  first_search_result_url = get_first_google_result(question)

  # Put that question into clipboard
  Clipboard.copy first_search_result_url
end


acts_as_chris