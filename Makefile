test:
	echo http://127.0.0.1:4000/ | pbcopy
	bundle exec jekyll clean
	bundle exec jekyll serve
