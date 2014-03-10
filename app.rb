require 'bundler/setup'
require 'yaml'
require 'sinatra'
require 'haml'
require 'sass'
require 'redcarpet'
require 'coffee-script'

set :public_folder, File.dirname(__FILE__)

configure do
  mime_type :appcache, 'text/cache-manifest'
end

set :redcarpet, Redcarpet::Markdown.new(Redcarpet::Render::HTML)

get "/" do
  haml :index
end

get "/style.css" do
  scss :style
end

get "/app.js" do
  coffee :app
end

get "/index.appcache" do
  timestamp = Digest::SHA1.hexdigest(File.mtime(File.dirname(__FILE__)).to_s)
  <<-APPCACHE
CACHE MANIFEST
# #{timestamp}
/
/style.css
/app.js
/data.json
//fonts.googleapis.com/css?family=Erica+One|Bangers|Indie+Flower
//cdnjs.cloudflare.com/ajax/libs/jquery/2.1.0/jquery.min.js
//cdnjs.cloudflare.com/ajax/libs/mustache.js/0.7.2/mustache.min.js
//cdnjs.cloudflare.com/ajax/libs/marked/0.3.1/marked.min.js
//themes.googleusercontent.com/static/fonts/bangers/v5/-VDbvoqMKwrRd8bOBvze3ALUuEpTyoUstqEm5AMlJo4.woff
//themes.googleusercontent.com/static/fonts/ericaone/v4/7ct8ELB1awBkUBGJHiNceLO3LdcAZYWl9Si6vvxL-qU.woff
//themes.googleusercontent.com/static/fonts/indieflower/v5/10JVD_humAd5zP2yrFqw6qRDOzjiPcYnFooOUGCOsRk.woff
  APPCACHE
end

get "/data.json" do
  setlists = Dir["setlists/*.yml"].map { |f| YAML.load(File.read(f)) }
  songs = Dir["songs/*.yml"].each_with_object({}) do |f, h|
    h[File.basename(f, ".yml")] = YAML.load(File.read(f))
  end
  { setlists: setlists, songs: songs }.to_json
end

__END__
@@layout
!!!5
%html(lang="en" manifest="/index.appcache")
  %head
    %meta(charset="UTF-8")
    %meta(name="viewport" content="width=device-width, user-scalable=no")
    %meta(name="apple-mobile-web-app-capable" content="yes")
    %link(rel="stylesheet" href="/style.css")
    %link(href='//fonts.googleapis.com/css?family=Erica+One|Bangers|Indie+Flower' rel='stylesheet')
    %title= @title
    %script(src="//cdnjs.cloudflare.com/ajax/libs/jquery/2.1.0/jquery.min.js")
    %script(src="//cdnjs.cloudflare.com/ajax/libs/mustache.js/0.7.2/mustache.min.js")
    %script(src="//cdnjs.cloudflare.com/ajax/libs/marked/0.3.1/marked.min.js")
    %script(src="/app.js")
    = yield

@@index
%section#setlists
%section#setlist
%section#song

@@app
marked.setOptions(breaks: true)
setlists = setlist = songs = song = null

setlistsTempl = """
  <ul class='setlists'>
    {{#.}}
    <li>
      <a href="{{date}}" data-date="{{date}}">
        <time>{{date}}</time>
        {{name}}
      </a>
    </li>
    {{/.}}
  </ul>
"""

setlistTempl = """
  <article class='setlist' id='{{date}}'>
    <ul class='songs'>
      {{#songs}}
        <li>
          <a href="{{id}}" data-id="{{id}}">{{name}}</a>
        </li>
      {{/songs}}
    </ul>
  </article>
"""

songTempl = """
  <article class='song' id={{id}}'>
    <blockquote>
      {{{lyrics}}}
    </blockquote>
  </article>
"""

render = (data) ->
  {setlists, songs} = data
  for own id, song of songs
    song.id = id
    song.lyrics = marked(song.lyrics)
  for setlist in setlists
    setlist.songs = setlist.songs.map((id) -> songs[id])
  $('#setlists').html(Mustache.render(setlistsTempl, setlists))
  location.hash = '#setlists'
  false

renderSetlist = (e) ->
  e.preventDefault?()
  date = @dataset.date
  setlist = setlists.filter((s) -> s.date is date)[0]
  console.log(setlist)
  $('#setlist').html(Mustache.render(setlistTempl, setlist))
  location.hash = '#setlist'
  false

renderSong = (e) ->
  e.preventDefault?()
  id = @dataset.id
  song = songs[id]
  $('#song').html(Mustache.render(songTempl, song))
  location.hash = '#song'
  false

$ -> $.getJSON '/data.json', render
$(document).on 'click', '.setlists a', renderSetlist
$(document).on 'click', '.songs a', renderSong

@@style
$fg: #444;
$bg: #eee;

body {
  margin: 0;
  background: 0;
  font-size: 2em;
}
section {
  display: none;
  &:target {
    display: block;
  }
}
ul {
  display: block;
  list-style: none;
  margin: 0;
  padding: 0;
  text-align: center;
  a {
    color: inherit;
    text-decoration: none;
    display: block;
    line-height: 1.5em;
  }
}
#setlists ul {
  font-family: "Erica One";
}
#setlist ul {
  font-family: "Bangers";
}
#song blockquote {
  font-family: "indie Flower";
}
