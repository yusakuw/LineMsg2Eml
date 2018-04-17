require 'mail'
require 'cfpropertylist'
require 'nokogiri'

require './lib/definitions.rb'

backup_dirs = Dir.glob(Dir.home + '/Library/Application Support/MobileSync/Backup/*')
if backup_dirs.count.zero?
  puts 'Backup directry is not found. Make iPhone backup by iTunes.'
  exit 1
end
backup_dirs.each_with_index do |path, idx|
  plist = CFPropertyList::List.new(file: path + '/Info.plist')
  data = CFPropertyList.native_types(plist.value)
  info_str = "#{data['Device Name']} - #{data['Product Name']}(#{data['Product Type']}), " \
    "iOS #{data['Product Version']}(#{data['Build Version']}), " \
    "Serial Number: #{data['Serial Number']}, " \
    "Last Backup: #{Time.parse(data['Last Backup Date'].to_s).strftime("%Y/%m/%d %H:%M:%S")}"
  puts "#{idx + 1}: #{info_str}"
end
print 'num?: '
selected = gets.to_i - 1
if selected < 0
  puts 'Abort.'
  exit 0
end
$backup_root_dir = backup_dirs[selected]

require './lib/models.rb'
require './lib/conf.rb'
require './lib/compose.rb'
require './lib/header.rb'

conf = Conf.new
if conf.backup_dir && conf.backup_dir != $backup_root_dir
  puts "Selected backup directory (#{$backup_root_dir}) is different from" \
    "previous backup directory (#{conf.backup_dir})"
  exit 1
end
conf.backup_dir = $backup_root_dir

msgs = Message.where('ZTIMESTAMP > ?', conf.latest_timestamp).order('ZTIMESTAMP asc')
msgs.each_with_index do |msg, idx|
  print "\r#{idx + 1}/#{msgs.count}"
  STDOUT.flush

  mail = Mail.new
  mail.charset = 'UTF-8'
  unixtime = msg[:ZTIMESTAMP]
  mail.date = Time.at(unixtime / 1000, unixtime % 1000)

  mail.message_id = get_message_id(msg)
  mail.from = get_message_from(msg, conf.my_status)
  mail.to = get_message_to(msg, conf.my_status)
  mail.in_reply_to = conf.last_message_ids[msg[:ZCHAT]]
  mail.subject = get_message_subject(msg)

  mail = compose_content(msg, mail)

  conf.save_lastmessage(msg, mail)

  File.write("emls/#{msg[:Z_PK]}_#{'time' + msg[:ZTIMESTAMP].to_s}.eml", mail.to_s)
end
