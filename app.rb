require 'rubygems'
require 'singleton'
require 'hpricot'
require 'words'
require 'open-uri'
require 'sinatra'

get '/' do
  erb :index
end

get '/report' do
	@report = DSL.load('rules.rb', params[:url])
	erb :report
end


class Seo

	attr_reader :src

	def initialize (url)
		@url = url
		@src = open(url)
		@page = Hpricot(@src)
		#@url.freeze
		# @src.freeze
		#@page.freeze
	end
	
	def url
		String.new(@url)
	end
	
	# Since a lot of Hpricot operations destroy the page being operated
	# on, always use a disposable copy of @page for analyses
	def page
		@page
		# Marshal.load( Marshal.dump( @page ) )
	end

	### Main SEO Metrics

	def content_ratio
		self.raw_content.length / Float(self.src_length)
	end

	def top_keywords (amount = 15)
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
	
	def src_length
		@src.length
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



### The DSL

class DSL

	attr_reader :url, :src, :page, :report
	
	def initialize(url)
		@url = url
		@src = open(url)
		@page = Hpricot(@src)
		@report = Report.new
	end

	def self.load(filename, url)
		dsl = self.new(url)
		dsl.instance_eval(File.read(filename), filename)
		dsl.report
	end

	def group(title)
		@report.add_group(title)
		yield
	end

	def rule(title)
		@report.current_group.add_rule(title)
		yield
	end
	
	def recommend(text)
	  @report.current_group.add_recommendation(text)
	end
	
	def explain(text)
	  @report.current_rule.add_explanation(text)
	end

	def pass
		@report.current_rule.result = :pass
	end

	def warn
		@report.current_rule.result = :warn
	end

	def fail
		@report.current_rule.result = :fail
	end
end


### Structure for a report	###
### with groups of rules	###

class Report
	
	attr_reader :groups
	
	def initialize 
		@groups = []
	end
	
	def add_group (title)
		@groups << Group.new(title)
	end
	
	def current_group
		@groups.last
	end
	
	def current_rule
		current_group.rules.last
	end
end

class Group

	attr_reader :rules, :title, :recommendations
	
	def initialize (title)
		@title = title
		@rules = []
		@recommendations = []
	end
	
	def add_rule (title)
		@rules << Rule.new(title)
	end
	
	def add_recommendation (text)
	  @recommendations << Recommendation.new(text)
	end
end

class Rule
	
	attr_reader :title, :explanations
	attr_accessor :result
	
	# Result is one of :pass, :warn, :fail
	def initialize (title)
		@title = title
		@result = :fail	# assume the rule fails until we hear otherwise
		@explanations = []
	end
	
	def result= (result)
		@result = [:pass, :warn, :fail].include?(result) ? result : :fail
	end
	
	def add_explanation (text)
	  @explanations << Explanation.new(text)
	end
end

# TODO: Use inheritance to simplify rules/recommendations
class Recommendation
  
  attr_reader :text
  
  def initialize (text)
    @text = text
  end
end

class Explanation
  
  attr_reader :text
  
  def initialize (text)
    @text = text
  end
end
