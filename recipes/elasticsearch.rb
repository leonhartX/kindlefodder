require_relative '../lib/kindlefodder.rb'

class Elasticsearch < Kindlefodder

  def get_source_files
    start_url = 'https://www.elastic.co/guide/en/elasticsearch/guide/current/index.html'

    @start_doc = Nokogiri::HTML run_shell_command("curl -s -L #{start_url}")

    File.open("#{output_dir}/sections.yml", 'w') {|f|
      f.puts extract_sections.to_yaml
    }
  end

  # This method is for the ebook metadata.
  def document
    {
      'title' => 'Elasticsearch: The Definitive Guide',
      'cover' => nil,
      'masthead' => nil,
    }
  end


  def extract_sections
    @start_doc.search('ul.toc li a').map do |o|
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
    article_html = run_shell_command "curl -s -L https://www.elastic.co/guide/en/elasticsearch/guide/current/#{article_ref}"

    article_doc = Nokogiri::HTML(article_html)

    article = article_doc.search('div.preface,div.section,div.part,div.chapter')
    article.search('a.edit_me').each &:remove

    title = article_doc.search('.title').text.strip
    $stderr.puts "- #{title}"

    article.search('img').each do |link|
      if link[:src] =~ /^images/
        link[:src] = "https://www.elastic.co/guide/en/elasticsearch/guide/current/#{link[:src]}"
      end
    end

    article.search('br').each do |br|
      if br.next && br.next.name == 'br'
        br.remove
      end
    end

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

Elasticsearch.generate
