#!/usr/bin/env ruby

require 'googleajax'
require 'clipboard'

def acts_as_chris(term)
  GoogleAjax.referer = "cloudspace.com"

  result = GoogleAjax::Search.web(term)[:results][0]

  Clipboard.copy result[:unescaped_url]
end

query = ARGV[0]
raise 'No query argument provided' if query.nil?

acts_as_chris(query)