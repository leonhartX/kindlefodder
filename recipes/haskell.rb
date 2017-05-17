require_relative '../lib/kindlefodder.rb'

class Haskell < Kindlefodder

  def get_source_files
    start_url = 'http://learnyouahaskell.com/chapters'

    @start_doc = Nokogiri::HTML run_shell_command("curl -s -L #{start_url}")

    File.open("#{output_dir}/sections.yml", 'w') {|f|
      f.puts extract_sections.to_yaml
    }
  end

  # This method is for the ebook metadata.
  def document
    {
      'title' => 'Learn You a Haskell for Great Good',
      'cover' => nil,
      'masthead' => nil,
    }
  end


  def extract_sections
    @start_doc.css('.chapters>li>a').map do |o|
      title = o.inner_text

      $stderr.puts "#{title}"
      $stderr.puts "#{o[:href]}"

      FileUtils::mkdir_p "#{output_dir}/articles"

      {
        title: title,
        articles: [get_article(o[:href])]
      }
    end
  end

  def get_article(article_ref)
    article_html = run_shell_command "curl -s -L http://learnyouahaskell.com/#{article_ref}"

    article_doc = Nokogiri::HTML(article_html)

    article = article_doc.search('#content')
    article.search('div.footdiv').each &:remove

    title = article_doc.search('h1').text.strip
    $stderr.puts "- #{title}"

    article.search('img').each do |link|
      link[:src] = "http://learnyouahaskell.com/#{link[:src]}" unless link[:src] =~ /^http/
    end

    article_body = article.inner_html
    path = "articles/#{article_ref}.html"

    File.open("#{output_dir}/#{path}", 'w') do |f|
      f.puts article_body
    end

    {
      title: title,
      path: path,
      description: '',
      author: ''
    }
  end

end

# RUN IT! This pulls down the documentation and turns it into the Kindle ebook.

Haskell.generate
