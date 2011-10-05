require 'rubygems'
require 'image_science'
require 'RMagick'
require 'exifr'

include FileUtils

class Thumb

  THUMBNAIL_SIZE = 64
  THUMBS = ".vignettes.jpg"

  attr_reader :tmp_dir

  def delete_tmp()
    rm_rf @tmp_dir
  end

  def create_tmp(year, path)
    @tmp_dir = "/tmp/#{year}_#{path}"
    delete_tmp
    puts "create tmp dir #{@tmp_dir}"
    mkdir_p @tmp_dir
  end

  def build(files)
    puts "Creation vignette :"
    @total = 0
    files.each do |file|
      puts " #{file} -> #{@tmp_dir}/#{file}"
      ImageScience.with_image(file) do |img|
        img.cropped_thumbnail(THUMBNAIL_SIZE) { |thumb| thumb.save "#{@tmp_dir}/#{file}" }
      end
      @total += 1
    end
  end

  def create_small(path)
    system "convert \"#{path}\" -auto-orient -quality 50 -thumbnail 600x600 -verbose \"#{@tmp_dir}/#{File.basename(path)}\""
  end

  def create_image_list(files)
    puts "Creation planche"
    if files.length > 0
      system "montage -thumbnail 64x64^ -gravity center -extent 64x64 -auto-orient -geometry 64x64+6+6 -tile x1 -verbose #{files.join(' ')} #{THUMBS}"
      system "mogrify -strip -quality 80 #{THUMBS}"
    end
  end

end

class Photo

  PHOTOS_HOME = ENV['PHOTOS_HOME']
  SCRIPTS_HOME = ENV['SCRIPTS_HOME']
  BUCKET = ENV['S3_BUCKET']

  # retrouve le nom + extension d'une image
  def decode_image(f)
    base = File.basename f
    base = base.split('.')
    return base[0], base[1]
  end

  def list_albums(year)
    Dir.glob("#{PHOTOS_HOME}/#{year}/**").sort
  end

  def images_by_album(path)
    Dir.glob("#{path}/*.{jpg,JPG}").sort
  end

  # Construction de la liste d'ACL
  def build_acl
    result = []
    File.open(".picasa.ini", File::RDWR|File::CREAT) do |f|
      f.each_line do |l|
        if l =~ /acl:/
          result << l[l.index('acl:')+4,200].chomp.strip.split(',').map { |x| x.strip }
        end
      end
    end
    result
  end

  def build_images_info(path)
    pos = 0
    result = []
    images_by_album(path).each do |f|
      base, ext = decode_image(f)
      result << { "name" => base,
                  "ext"  => ext,
                  "pos"  => "background-position:-#{pos*76}px" }
      pos = pos + 1
    end
    result
  end

  def create_infos(year)
    result =  {}
    list_albums(year).each do |path|
      Dir.chdir(path) do
        acls = [ "herve", "fanny" ] << build_acl
        images = build_images_info path
        result[File.basename(path)] = { "images" => images, "acl" => acls.flatten }
      end
    end
    result
  end

  def build_small(year, album)
    path = "#{PHOTOS_HOME}/#{year}/#{album}"
    thumb = Thumb.new
    thumb.create_tmp year, album
    images_by_album(path).each do |img|
      thumb.create_small img
    end
    cmd = "#{SCRIPTS_HOME}/s3sync/s3sync.rb -rsv --delete \"#{thumb.tmp_dir}/\" \"#{S3_BUCKET}:small/#{year}_#{album}\""
    puts cmd
    system cmd
    thumb.delete_tmp
  end

  def list_exif(files)
    puts "Recuperation des informations exif"
    infos = {}
    files.each do |file|
      infos[file] = { :exif => EXIFR::JPEG.new(file), :size => format("%.2f", File.size(file) / 1024.0 / 1024.0) }
    end
    infos
  end

  def build_thumbs(year, path)
    album = "#{PHOTOS_HOME}/#{year}/#{path}"
    Dir.chdir(album) do
#      if opt == "all"
        thumb = Thumb.new
        thumb.create_tmp year, path

        files = images_by_album "."
        #thumb.build files
        #infos = thumb.build files
#        create_s3_infos infos

        thumb.create_image_list files
#      end

#      if opt == "all" || opt == "index"
        exif_infos = list_exif files

#      rescue
#        puts "  Pas de fichier"
#      end

#      end
      thumb.delete_tmp
    end
  end

end
