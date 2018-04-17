# frozen_string_literal: true

require 'json'
require 'open-uri'

require './lib/models.rb'

def get_sticker_data(sticker_id)
  package_id = StickerPackage.find_by('ZSTICKERIDSTART <= ? and ZSTICKERIDEND >= ?', \
                                      sticker_id, sticker_id)&.[]('ZPACKAGEID')
  return if package_id.nil?

  info_uri = "https://dl.stickershop.line.naver.jp/products/0/0/1/#{package_id}" \
    '/iphone/productInfo.meta'
  sticker_uri = "http://dl.stickershop.line.naver.jp/products/0/0/1/#{package_id}" \
    "/iphone/stickers/#{sticker_id}@2x.png"
  animation_uri = "http://dl.stickershop.line.naver.jp/products/0/0/1/#{package_id}" \
    "/iphone/animation/#{sticker_id}@2x.png"
  sound_uri = "http://dl.stickershop.line.naver.jp/products/0/0/1/#{package_id}" \
    "/iphone/sound/#{sticker_id}.m4a"

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
