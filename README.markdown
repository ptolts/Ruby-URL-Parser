Usage
=====

Parse a url
-----
	text = "http://www.watchseries-online.com:80/bar/foo.html#qux?s=bob%27s+burgers&search={"
	url = Entrity::URL::Parsed.new(text)
	url.scheme
	=> 'http'
	url.host
	=> 'www.watchseries-online.com'
	url.port
	=> '80'
	url.path
	=> '/bar/foo.html'
	url.fragment
	=> 'qux'
	url.data
	=> 's=bob%27s+burgers&search='
	
Compare two urls
-----
By default, nil values are treated as matches and url strings are normalized (if need be). Turn off default by setting ignore_nil to false in the params.
	
	url1 = 'http://www.foo.com/bar/baz/qux.html'
	url2 = '/bar/../baz/qux.html?gravy=train'
	Entrity::URL::Parsed.urls_identical?(url1, url2)
	=> true
	Entrity::URL::Parsed.urls_identical?(url1, url2, false)
	=> false

If one url is relative and the other is not, then the relative url will by default attempt to normalize against the absolute url. Turn off default by setting normalize to false in the params.

	url1 = 'http://www.foo.com/bar/baz/qux.html'
	url2 = 'qux.html'
	Entrity::URL::Parsed.urls_identical?(url1, url2)
	=> true
	Entrity::URL::Parsed.urls_identical?(url1, url2, true, false)
	=> false

Notes
-----
Whereas I find the Ruby core class URI is not too useful for parsing URLs, I put this together.
The fields @scheme, @host, @port, @path, @fragment, @data are all mutable.