module Raddocs
  class App < Sinatra::Base
    set :haml, :format => :html5
    set :root, File.join(File.dirname(__FILE__), "..")

    get "/" do
      index = JSON.parse(File.read("#{docs_dir}/index.json"))
      haml :index, :locals => { :index => index }
    end

    get "/custom-css/*" do
      file = "#{docs_dir}/styles/#{params[:splat][0]}"

      if !File.exists?(file)
        raise Sinatra::NotFound
      end

      content_type :css
      File.read(file)
    end

    get "/*" do
      file = "#{docs_dir}/#{params[:splat][0]}.json"

      if !File.exists?(file)
        raise Sinatra::NotFound
      end

      file_content = File.read(file)

      example = JSON.parse(file_content)
      example["parameters"] = Parameters.new(example["parameters"]).parse

      if request.xhr?
        haml :example, :locals => {:example => example}, :layout => false
      else
        index = JSON.parse(File.read("#{docs_dir}/index.json"))
        haml :example, :locals => { :index => index, :example => example }
      end
    end

    not_found do
      "Example does not exist"
    end

    helpers do
      def link_to(name, link)
        %{<a href="#{request.env["SCRIPT_NAME"]}#{link}">#{name}</a>}
      end

      def url_location
        request.env["SCRIPT_NAME"]
      end

      def api_name
        Raddocs.configuration.api_name
      end

      def css_files
        files = ["#{url_location}/codemirror.css", "#{url_location}/application.css"]

        if Raddocs.configuration.include_bootstrap
          files << "#{url_location}/bootstrap.css"
        end

        Dir.glob(File.join(docs_dir, "styles", "*.css")).each do |css_file|
          basename = Pathname.new(css_file).basename
          files << "#{url_location}/custom-css/#{basename}"
        end

        files.concat Array(Raddocs.configuration.external_css)

        files
      end

      def sort_rest_actions(array)
        new_array = []
        ["GET", "POST", "PUT", "DELETE"].reverse.each do |a|
          while word = array.find { |x| x["description"] =~ /#{a}/i }
            array.delete(word)
            new_array.unshift(word)
          end
        end
        new_array + array
      end
    end

    def docs_dir
      Raddocs.configuration.docs_dir
    end
  end
end
