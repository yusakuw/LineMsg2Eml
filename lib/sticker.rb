# frozen_string_literal: true

require 'json'
require 'open-uri'

require './lib/models.rb'

def get_sticker_data(sticker_id)
  package = StickerPackage.find_by('ZSTICKERIDSTART <= ? and ZSTICKERIDEND >= ?', \
                                      sticker_id, sticker_id)
  return if package.nil?
  package_id = package['ZPACKAGEID']
  package_version = package['ZVERSION'] || 1
  return if package_id.nil?

  base_uri = "https://dl.stickershop.line.naver.jp/products/0/0/#{package_version}/#{package_id}"
  info_uri = base_uri + '/iphone/productInfo.meta'
  sticker_uri =  base_uri + "/iphone/stickers/#{sticker_id}@2x.png"
  animation_uri = base_uri + "/iphone/animation/#{sticker_id}@2x.png"
  sound_uri = base_uri + "/iphone/sound/#{sticker_id}.m4a"

  data = {}
  begin
    data['sticker'] = open(sticker_uri, 'rb', ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read
    info = JSON.load(open(info_uri, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read)
    if info['hasAnimation']
      data['animation'] = open(animation_uri, 'rb', ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read
    end
    if info['hasSound']
      data['sound'] = open(sound_uri, 'rb', ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read
    end
  rescue
  end
  return data # {'sticker': png or nil, 'animation': apng or nil, 'sound': m4a or nil}
end
