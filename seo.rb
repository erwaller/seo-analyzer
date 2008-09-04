class Seo

	def initialize (url)
		@url = url
		@url.freeze
		@content = open(url)
		@content.freeze
		@page = Hpricot(@content)
		@page.freeze
	end
	
	# Since a lot of Hpricot operations destroy the page being operated
	# on, always use a disposable copy of @page for analyses
	def page
		Marshal.load( Marshal.dump( @page ) )
	end

	### Main SEO Metrics

	def get_content_ratio
		self.raw_content.length / Float(self.page.to_s.length)
	end

	def get_top_keywords (amount = 15)
		rankKeywords[0..(amount-1)]
	end

	def rank_keywords
		page = self.page
		keywords = {}
		keywords.default = 0
		
		# Grab weighted keywords from elevated tags like: H1, strong, em, a
		# Each instance of a keyword will be counted once under it's highest
		# weighted parent tag
		tags = Words::KEYWORD_WEIGHTS.sort {|a,b| b[1] <=> a[1]}
		tags.each do |arr|
			tag = arr[0]
			weight = arr[1]
			page.search(tag).remove.uniq_elements.keywords.each do |keyword|
				keywords[keyword] += weight
			end
		end
		# probably want only unique instances of an element -- if there are two links with same wording and link that doesn't count
		
		keywords = keywords.sort {|a,b| b[1] <=> a[1]} 
		keywords.collect {|item| item[0]}
	end


	### Helpers

	def raw_content
		page = self.page
		
		# Remove style and script tags
		page.search('script').remove
		page.search('style').remove
		
		# Extract alt, title and summary tags
		attrText = ' '
		['alt', 'title', 'summary'].each do |attr|
			page.search('[@'+attr+']') do |elem|
				attrText << elem[attr] << ' '
			end
		end
		
		page.search('body').text + attrText
		
	end

end


### Monkey-patched helpers

class Hpricot::Elements
	# Returns the keywords from an element collection
	# It's useful to be able to say page.search('h2').keywords
	def keywords
		keywords = self.collect { |elem|
			elem.inner_text.downcase.scan(/[a-z][\w-]+/i).find_all{ |item| 
				item.length >= 3 && !Words::COMMON_WORDS[item]
			}
		}
		keywords.flatten
	end
	
	def uniq_elements
		lookup = {}
		Hpricot::Elements.new self.select { |elem|
			lookup_str = elem.inner_text.strip.gsub(/\s+/, ' ').downcase
			if lookup[lookup_str] then
				col = Hpricot::Elements[elem]
				col.remove
				false
			else
				lookup[lookup_str] = 1
				true
			end
		}
	end
end



