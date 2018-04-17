# frozen_string_literal: true

module MessageType
  INFO = 'I'
  RECEIVED = 'R'
  SENT = 'S'
  NULL = nil
end

module ContentType
  TEXT  = 0
  IMAGE = 1
  MOVIE = 2
  AUDIO = 3
  HTML  = 4
  PHONE = 6
  STICKER = 7
  PRESENT_STICKER = 9
  APP_LINK = 12
  ATTACHMENT = 14
  NOTE = 16
  ADBANNER = 17
  DOWNLOAD_IMAGE = 96
  LOCATION = 100
end

# $backup_root_dir: String
