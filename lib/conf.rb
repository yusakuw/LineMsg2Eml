# frozen_string_literal: true

require 'yaml'
require './lib/models.rb'

class Conf
  FILENAME = 'linebackup.yml'
  attr_accessor :my_status, :last_message_ids, :latest_timestamp, :backup_dir

  def initialize
    if File.exist? FILENAME
      read
    else
      @my_status = UserStatus.new('mysender', 'myaddress')
      @last_message_ids = {}
      @latest_timestamp = 0
      @backup_dir = nil
      YAML.dump(self, File.open(FILENAME, 'w')) unless File.exist?(FILENAME)
    end
  end

  def read
    replace YAML.load_file(FILENAME)
  end

  def replace(new)
    @my_status = new.my_status
    @last_message_ids = new.last_message_ids
    @latest_timestamp = new.latest_timestamp
    @backup_dir = new.backup_dir
  end

  def write
    File.open(FILENAME, 'w') do |e|
      YAML.dump(self, e)
    end
  end

  def save_lastmessage(msg, mail)
    @last_message_ids[msg[:ZCHAT]] = "<#{mail.message_id}>".sub(/^<</,'<').sub(/>>$/,'>')

    if @latest_timestamp >= msg[:ZTIMESTAMP]
      puts "NOTICE: @latest_timestamp = #{@latest_timestamp}, msg[:ZTIMESTAMP] = #{msg[:ZTIMESTAMP]}"
    end
    @latest_timestamp = msg[:ZTIMESTAMP]
    write
  end
end
