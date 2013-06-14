template "Rails3" do
  software_name "Ruby"

  build do
    task :bundle
    task :assets
  end
end
