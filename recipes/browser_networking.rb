require_relative '../lib/kindlefodder.rb'

class BrowserNetworking < Kindlefodder

  def get_source_files
    start_url = 'http://chimera.labs.oreilly.com/books/1230000000545/index.html'

    @start_doc = Nokogiri::HTML run_shell_command("curl -s -L #{start_url}")

    File.open("#{output_dir}/sections.yml", 'w') {|f|
      f.puts extract_sections.to_yaml
    }
  end

  # This method is for the ebook metadata.
  def document
    {
      'title' => 'High Performance Browser Networking',
      'cover' => nil,
      'masthead' => nil,
    }
  end


  def extract_sections
    @start_doc.search('span.preface>a,span.chapter>a').map do |o|
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
    article_html = run_shell_command "curl -s -L http://chimera.labs.oreilly.com/books/1230000000545/#{article_ref}"

    article_doc = Nokogiri::HTML(article_html)

    article = article_doc.search('section.preface,section.chapter')

    title = article_doc.search('section>div.titlepage h2.title').text.strip
    $stderr.puts "- #{title}"

    article_body = article.inner_html
    article_body = title unless article_body.strip.length > 0

    path = "articles/#{article_ref}"

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

BrowserNetworking.generate
