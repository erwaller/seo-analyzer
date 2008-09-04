# seo_spec.rb
require 'rubygems'
require 'hpricot'
require 'open-uri'
require 'seo'

describe Seo do
	before :all do
		@seo = Seo.new Hpricot("	<html>
									<head>
										<!-- Blah -->
									</head>
									<body>
										<p>This is some text</p>
										<p><a href=\"#\" title=\"tooltip\">And more</a></p>
									</body>
								</html>	")
	end
	
	it "should show 2 p's from page" do
		@seo.page.search('p').length == 2
	end
	
	it "should show 1 p from page" do
		@seo.page.search('p').uniq.length == 1
	end
	
	it "should return all text within the body, but not within script or style tags" do
		@seo.getRawContent == "This is some text And more tooltip"
	end
	
end
