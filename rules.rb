group "Headers/Title" do
  rule "Exactly one h1" do
	  explain "The <code>h1</code> tag is the most semantically important heading element."
		h1s = page.search('h1')
		pass if h1s.length == 1
	end
	
	rule "No more than 70 characters in page title" do
	  explain "Titles shouldn't be that long ... duhh"
		title = page.search('head title').text
		pass if title.length <= 70
	end
	
	rule "h1 similiar to title" do
	  jaccard_coef = my_jaccard(page.at('h1').inner_text, page.at('title').inner_text)
	  explain "You'll be happy to know that the jaccard coefficient (well sort of) for you title and h1 is #{jaccard_coef}"
	  pass if jaccard_coef > 0.5
	end
	
	recommend "At least one H2" do
	  pass if page.search('h2').length > 0
	end
end

group "Hyperlinks" do
	rule "No more than 100 unique links per page" do
		pass if page.search('a').uniq_elements.length <= 100
	end
	
	# rule "All hyperlinks should have title tag" do
	# 	pass if page.search('a').length == page.search('a[@title]').length
	# end
end

group "Keywords" do
	# info "Top 15 keywords" do
	# end
end

group "URL" do
	rule "Pathname depth no greater than 4" do
		path = URI::parse(url).path
		pass if path.scan(/\/[^#\/]+/).length <= 4
	end
	
	recommend "No more than 2 query params" do
	  explain "Hello"
		query = url.split('?', 2)[1]
		pass if query == nil or CGI.parse(query).length <= 2
	end
	
	# recommend "Use hyphens in url to seperate words (not underscores)" do
	# end
end

group "Meta tags" do
	rule "No more than 250 characters in the meta description" do
		:pass
	end
	
	# info "~150 chars will appear in search result"
	# end
end

group "Page Statistics" do
	rule "Page weight should be no more than 150kb" do
		explain "Google doesn't like really heavy pages.. I guess"
		explain "What would another paragraph look like"
		pass if src.size <= 150000
	end
	
	# info "Markup to Content Ratio" do
	# end
end

