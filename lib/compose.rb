# frozen_string_literal: true

require 'cfpropertylist'
require 'open-uri'

require './lib/CFPropertyList_extension.rb'
require './lib/models.rb'
require './lib/sticker.rb'
require './lib/definitions.rb'

def get_file_info(domain, relative_path)
  return Filename.where('flags=1 and domain like ? and relativePath like ?', domain, relative_path)
end

def get_attachment_paths(msg)
  # 'Message Attachments' / 'Message Thumbnails'
  relative_path = 'Library/Application Support/PrivateStore/P_u%/Message %s/' \
    "#{ChatRoom.find_by(Z_PK: msg[:ZCHAT])['ZMID']}/#{msg[:ZID]}%"
  return get_file_info('%line%', relative_path)&.map { |m| m.filepath($backup_root_dir) }
end

def get_unpacked_plist_dic(plist_blob)
  plist = CFPropertyList::List.new(data: plist_blob)
  data = CFPropertyList.native_types(plist.value)

  obj_indices = data['$objects'][1]['NS.objects']
  key_indices = data['$objects'][1]['NS.keys']

  dic = {}
  key_indices.zip(obj_indices).each do |key_idx, obj_idx|
    dic[data['$objects'][key_idx]] = data['$objects'][obj_idx]
  end
  return dic
end

def compose_text_content(msg, mail)
  # TODO: convert some codes into LINE emoji
  # https://developers.line.me/media/messaging-api/emoji-list.pdf
  mail.text_part do
    body "#{msg[:ZTEXT]}\n"
    content_type 'text/plain; charset=UTF-8'
  end
  return mail
end

def compose_image_content(msg, mail)
  mail.text_part do
    body "#{msg[:ZTEXT]}\n"
    content_type 'text/plain; charset=UTF-8'
  end
  if !!msg[:ZTHUMBNAIL] then
    mail.attachments['thumb.jpg'] = msg[:ZTHUMBNAIL]
  end
  get_attachment_paths(msg)&.each do |path|
    next unless File.exist?(path)
    mail.attachments[File.basename(path) + '.jpg'] = File.read(path)
  end
  return mail
end

def compose_movie_content(msg, mail)
  # TODO: search movie files
  mail.text_part do
    body "#{msg[:ZTEXT]}\n"
    content_type 'text/plain; charset=UTF-8'
  end
  if msg[:ZTHUMBNAIL]
    mail.attachments['thumb.jpg'] = msg[:ZTHUMBNAIL]
  end
  get_attachment_paths(msg)&.each do |path|
    next unless File.exist?(path)
    mail.attachments[File.basename(path) + '.jpg'] = File.read(path)
  end
  return mail
end

def compose_audio_content(msg, mail)
  mail.text_part do
    body (msg[:ZTEXT] || ' ') + "\n"
    content_type 'text/plain; charset=UTF-8'
  end
  get_attachment_paths(msg)&.each do |path|
    next unless File.exist?(path)
    mail.attachments[File.basename(path) + '.m4a'] = File.read(path)
  end
  return mail
end

def compose_html_content(msg, mail)
  dic = get_unpacked_plist_dic(msg[:ZCONTENTMETADATA])
  html = Nokogiri::HTML.parse(dic['HTML_CONTENT'])
  html.at_css('body')['style']=html.at_css('body')['style'].gsub(/opacity: ?0/, '')
  mail.text_part do
    body "#{msg[:ZTEXT]}\n#{html.at_css('body').inner_text}\n"
    content_type 'text/plain; charset=UTF-8'
  end
  mail.html_part = Mail::Part.new do
    content_type 'text/html; charset=UTF-8'
    body html.to_s
  end
  return mail
end

def compose_phone_content(msg, mail)
  mail.text_part do
    body "電話がありました。\n"
    content_type 'text/plain; charset=UTF-8'
  end
  return mail
end

def compose_sticker_content(msg, mail)
  data = get_sticker_data(msg[:ZLONGITUDE].to_i.to_s)
  mail.attachments['sticker.png'] = data['sticker'] if data['sticker']
  mail.attachments['animation.png'] = data['animation'] if data['animation']
  mail.attachments['sound.m4a'] = data['sound'] if data['sound']
  mail.text_part do
    body "スタンプを送信しました。\n"
    content_type 'text/plain; charset=UTF-8'
  end
  return mail
end

def compose_present_sticker_content(msg, mail)
  dic = get_unpacked_plist_dic(msg[:ZCONTENTMETADATA])
  mail.text_part do
    body "プレゼントが届きました。\n#{dic}\n"
    content_type 'text/plain; charset=UTF-8'
  end
  return mail
end

def compose_applink_content(msg, mail)
  dic = get_unpacked_plist_dic(msg[:ZCONTENTMETADATA])
  begin
    open(dic['previewUrl'], 'rb') do |io|
      mail.attachments[File.basename(URI.parse(dic['previewUrl']).path)] = io.read
    end
  rescue
  end
  mail.text_part do
    body (msg[:ZTEXT] || dic['altText'] || '') + \
      "\n#{dic['linkText']}\n#{dic['i-installUrl']}\n#{dic['a-installUrl']}\n"
    content_type 'text/plain; charset=UTF-8'
  end
  return mail
end

def compose_location_content(msg, mail)
  uri = "http://maps.google.com/maps?q=#{msg[:ZLATITUDE]},#{msg[:ZLONGITUDE]}"
  mail.text_part do
    body "#{uri}\n#{msg[:ZTEXT]}\n"
    content_type 'text/plain; charset=UTF-8'
  end
  return mail
end

def compose_attachment_content(msg, mail)
  dic = get_unpacked_plist_dic(msg[:ZCONTENTMETADATA])
  get_attachment_paths(msg)&.each_with_index do |path, idx|
    next unless File.exist?(path)
    if idx.zero? && dic['FILE_NAME']
      mail.attachments[dic['FILE_NAME']] = File.read(path)
    else
      mail.attachments[File.basename(path)] = File.read(path)
    end
  end
  mail.text_part do
    body (msg[:ZTEXT] || ' ') + "\n" + dic['FILE_NAME'] + "\n"
    content_type 'text/plain; charset=UTF-8'
  end
  return mail
end

def compose_note_content(msg, mail)
  # TODO: analyze LINE Album
  # line://group/home/albums/album?albumId=01234567&homeId=c0123456789abcdef0123456789abcdef
  # Library/Application Support/PrivateStore/P_*/Message Attachments/#{ChatRoom[ZMID]}/LineAlbumData/?/??? (bplist)
  # Library/Application Support/PrivateStore/P_*/Message Attachments/#{ChatRoom[ZMID]}/LineAlbumImage/?/??? (jpg)
  dic = get_unpacked_plist_dic(msg[:ZCONTENTMETADATA])
  if dic['albumName'].nil? then
    info_str = (dic['contentType'] == 'C') ? '[ノート>コメント]' : '[ノート]'
    mail.text_part do
      body "#{info_str}\n#{dic['text']}\n#{dic['postEndUrl']}\n"
      content_type 'text/plain; charset=UTF-8'
    end
  else
    info_str = (dic['locKey'] == 'BA') ? '[アルバムを作成]' : '[アルバムに追加]'
    mail.text_part do
      body "#{info_str}\n#{dic['text']}\nアルバム名: #{dic['albumName']}\n#{dic['postEndUrl']}\n"
      content_type 'text/plain; charset=UTF-8'
    end
  end
  mail.attachments['zContentMetadata.plist'] = msg[:ZCONTENTMETADATA] if msg[:ZCONTENTMETADATA]
  return mail
end

def compose_adbanner_content(msg, mail)
  dic = get_unpacked_plist_dic(msg[:ZCONTENTMETADATA])
  begin
    open(dic['DOWNLOAD_URL'], 'rb') do |io|
      mail.attachments[File.basename(URI.parse(dic['DOWNLOAD_URL']).path) + '.jpg'] = io.read
    end
  rescue
  end
  mail.text_part do
    body dic['ALT_TEXT'] + "\n"
    content_type 'text/plain; charset=UTF-8'
  end
  return mail
end

def compose_download_image_content(msg, mail)
  dic = get_unpacked_plist_dic(msg[:ZCONTENTMETADATA])
  begin
    open(dic['DOWNLOAD_URL'], 'rb') do |io|
      mail.attachments[File.basename(URI.parse(dic['DOWNLOAD_URL']).path)] = io.read
    end
  rescue
  end
  mail.text_part do
    body msg[:ZTEXT] + "\n"
    content_type 'text/plain; charset=UTF-8'
  end
  return mail
end

def compose_content(msg, mail)
  case msg[:ZCONTENTTYPE]
  when ContentType::TEXT
    mail = compose_text_content(msg, mail)
  when ContentType::IMAGE
    mail = compose_image_content(msg, mail)
  when ContentType::MOVIE
    mail = compose_movie_content(msg, mail)
  when ContentType::AUDIO
    mail = compose_audio_content(msg, mail)
  when ContentType::HTML
    mail = compose_html_content(msg, mail)
  when ContentType::PHONE
    mail = compose_phone_content(msg, mail)
  when ContentType::STICKER
    mail = compose_sticker_content(msg, mail)
  when ContentType::PRESENT_STICKER
    mail = compose_present_sticker_content(msg, mail)
  when ContentType::APP_LINK
    mail = compose_applink_content(msg, mail)
  when ContentType::ATTACHMENT
    mail = compose_attachment_content(msg, mail)
  when ContentType::NOTE
    mail = compose_note_content(msg, mail)
  when ContentType::ADBANNER
    mail = compose_adbanner_content(msg, mail)
  when ContentType::DOWNLOAD_IMAGE
    mail = compose_download_image_content(msg, mail)
  when ContentType::LOCATION
    mail = compose_location_content(msg, mail)
  else
    p 'ContentType: ' + msg[:ZCONTENTTYPE].to_s
    raise StandardError
  end
  return mail
end
