# frozen_string_literal: true

require 'active_record'

UserStatus = Struct.new(:sender, :address)

class ManifestDb < ActiveRecord::Base
  establish_connection(
    adapter: 'sqlite3',
    database: "#{$backup_root_dir}/Manifest.db"
  )
end

class Filename < ManifestDb
  self.table_name = :Files
  self.primary_key = :fileID

  def filepath(root_path)
    return "#{root_path}/#{self[:fileID][0, 2]}/#{self[:fileID]}"
  end
end

class LineDb < ActiveRecord::Base
  establish_connection(
    adapter: 'sqlite3',
    database: "#{$backup_root_dir}/48/48d4238245188c830e35ad9c644a406645aa8246" # Line.sqlite
  )
end

class ChatRoom < LineDb
  self.table_name = :ZCHAT
  self.primary_key = :Z_PK
end

class ChatMembers < LineDb
  self.table_name = :Z_1MEMBERS
end

class Group < LineDb
  self.table_name = :ZGROUP
  self.primary_key = :Z_PK
end

class Message < LineDb
  self.table_name = :ZMESSAGE
  self.primary_key = :Z_PK
end

class User < LineDb
  self.table_name = :ZUSER
end

class StickerPackage < LineDb
  self.table_name = :ZSTICKERPACKAGE
end
