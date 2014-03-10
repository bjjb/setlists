require 'bundler/setup'
require 'yaml'
require 'sinatra'
require 'haml'
require 'sass'
require 'redcarpet'
require 'coffee-script'

set :public_folder, File.dirname(__FILE__)

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
%html(lang="en")
  %head
    %meta(charset="UTF-8")
    %meta(name="viewport" content="width: device-width, user-scalable=no")
    %link(rel="stylesheet" href="/style.css")
    %link(href='//fonts.googleapis.com/css?family=Erica+One|Bangers|Indie+Flower' rel='stylesheet')
    %title= @title
    %script(src="//cdnjs.cloudflare.com/ajax/libs/jquery/2.1.0/jquery.min.js")
    %script(src="//cdnjs.cloudflare.com/ajax/libs/mustache.js/0.7.2/mustache.min.js")
    %script(src="//cdnjs.cloudflare.com/ajax/libs/marked/0.3.1/marked.min.js")
    %script(src="/js-yaml.js")
    %script(src="/app.js")
    = yield

@@index
%section#setlists
%section#setlist
%section#song

@@app
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
    <header>
      <h1>{{name}}</h1>
      <time>{{date}}</time>
    </header>
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
  <article class='song' id={{id}}>
    <header>
      <h1>{{name}}</h1>
    </header>
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
  background-color: $bg;
  color: $fg;
  font-family: sans-serif;
  font-size: 2em;
  margin: 20px;
}
section {
  display: none;
  &:target {
    display: inherit;
  }
}
ul {
  list-style: none;
  margin: 0; padding: 0;
  display: block;
  li {
    text-align: center;
    a {
      display: block;
      text-decoration: none;
      color: inherit;
      font-size: 2em;
    }
  }
}

header {
  color: white;
  text-shadow: 1px 1px 3px $fg;
  z-index: 1;
  h1 {
    position: absolute;
    margin: 0;
    padding: 0;
    top: 0;
    left: 0;
    text-align: center;
    z-index: -1;
  }
  time {
    display: none;
  }
}
#setlists {
  font-family: "Erica One", serif;
}
#setlist {
  font-family: "Bangers", sans-serif;
  h1 { font-family: "Erica One", serif; }
}
#song {
  font-family: "Indie Flower", cursive;
  h1 { font-family: "Bangers", cursive; }
  blockquote {
    background-color: transparentize($bg, 0.8);
    font-size: 1.4em;
    z-index: 2;
  }
}
