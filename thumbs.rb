#!/usr/bin/env ruby
require "photo"
require "yaml"

$year = ARGV[0]
$url  = ARGV[1] unless %w[ nfo small all ].include?(ARGV[1])
$opt  = ARGV[2] || ARGV[1]

if $year.nil? 
  puts "ruby thumbs.rb year [album] [nfo|all|small]"
  exit
end

$photo = Photo.new
$errs = []

def create_thumbs(album)
  begin
    $photo.build_thumbs $year, album unless $opt == "small"
    $photo.build_small($year, album) if $opt
  rescue => e
    $errs << album
    puts e
  end
end

# Quoi que l'on fasse, on met à jour la description de l'année au sein
# de l'application
File.open("#{WEB_SITE_HOME}/config/#{$year}.yml", "w+") do |file|
  file.puts $photo.create_infos($year).to_yaml
end
exit if $opt == "nfo"

# Création des vignettes/miniatures
if $url.nil?
  $photo.list_albums($year).each do |a|
    create_thumbs File.basename(a)
  end
else
  create_thumbs $url
end

if $errs.count > 0
  puts "Des albums n'ont pas pu etre generes"
  $errs.each { |album| puts "  #{album}" }
end
