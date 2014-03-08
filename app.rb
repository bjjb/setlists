require 'bundler/setup'
require 'yaml'
require 'sinatra'
require 'haml'
require 'sass'
require 'redcarpet'
require 'coffee-script'

set :public_folder, File.dirname(__FILE__)

get "/" do
  haml :index
end

get "/style.css" do
  scss :style
end

get "/app.js" do
  coffee :app
end

get "/setlists.json" do
  Dir["setlists/*.yml"].map { |f| YAML.load(File.read(f)) }.to_json
end

get "/songs.json" do
  songs = Dir["songs/*.yml"].map { |f| YAML.load(File.read(f)) }
  songs.to_json
end

__END__
@@layout
!!!5
%html(lang="en")
  %head
    %meta(charset="UTF-8")
    %link(rel="stylesheet" href="/style.css")
    %title= @title
    %script(src="//cdnjs.cloudflare.com/ajax/libs/jquery/2.1.0/jquery.min.js")
    %script(src="//cdnjs.cloudflare.com/ajax/libs/mustache.js/0.7.2/mustache.min.js")
    %script(src="/app.js")
    = yield

@@index
%section#setlists
%section#songs

%section#songs

@@app
$ ->
  $.getJSON '/setlists.json',
    success: (data) ->
      console.log(data)

@@style
body {
  background-color: white;
  font-family: sans-serif;
  color: lighten(black, 0.1);
}
