# frozen_string_literal: true

require './lib/definitions.rb'
require './lib/models.rb'

MSG_ADDRESS_SUFFIX = 'line.message'
MSG_ID_SUFFIX = 'line.message.id'

def get_message_id(msg)
  case msg[:ZMESSAGETYPE]
  when MessageType::RECEIVED
    return "<#{msg[:ZID] || msg[:ZTIMESTAMP]}@#{MSG_ID_SUFFIX}>"
  when MessageType::SENT
    return "<#{msg[:ZID] || msg[:ZTIMESTAMP]}@#{MSG_ID_SUFFIX}>"
  when MessageType::INFO
    return "<info#{msg[:ZTIMESTAMP]}@#{MSG_ID_SUFFIX}>"
  when nil
    return "<#{msg[:ZID] || msg[:ZTIMESTAMP]}@#{MSG_ID_SUFFIX}>"
  else
    raise StandardError
  end
end

def get_message_from(msg, me)
  case msg[:ZMESSAGETYPE]
  when MessageType::RECEIVED
    return get_recv_message_from(msg, me)
  when MessageType::SENT
    return get_sent_message_from(msg, me)
  when MessageType::INFO
    return get_info_message_from(msg, me)
  when nil
    if !msg[:ZSENDER]
      return get_sent_message_from(msg, me)
    else
      return get_recv_message_from(msg, me)
    end
  else
    raise StandardError
  end
end

def get_message_to(msg, me)
  members = []
  ChatMembers.where('Z_1CHATS=?', msg[:ZCHAT]).map do |mem|
    if mem[:Z_12MEMBERS] != msg[:ZSENDER]
      status = get_user_status(mem[:Z_12MEMBERS])
      members.push "\"#{status.sender}\" <#{status.address}@#{MSG_ADDRESS_SUFFIX}>" if status
    end
  end
  if msg[:ZMESSAGETYPE] != MessageType::SENT && !msg[:ZSENDER].nil?
    members.push "\"#{me.sender}\" <#{me.address}@#{MSG_ADDRESS_SUFFIX}>"
  end
  return members
end

def get_message_subject(msg)
  room = ChatRoom.find(msg[:ZCHAT])
  if room[:ZTYPE] == 2
    return Group.where('ZID=?', room[:ZMID])&.first&.[](:ZNAME)
  else
    return nil
  end
end

def save_lastmessage(conf, msg, mail)
  conf.last_message_id_dic[msg[:ZCHAT]] = \
    "<#{mail.message_id}>".sub(/^<</,'<').sub(/>>$/,'>')
end

private

def get_recv_message_from(msg, _me)
  status = get_user_status(msg[:ZSENDER])
  if status.nil?
    return "<nil@#{MSG_ADDRESS_SUFFIX}>"
  else
    return "\"#{status.sender}\" <#{status.address}@#{MSG_ADDRESS_SUFFIX}>"
  end
end

def get_sent_message_from(_msg, me)
  return "\"#{me.sender}\" <#{me.address}@#{MSG_ADDRESS_SUFFIX}>"
end

def get_info_message_from(_msg, _me)
  return "\"Info\" <info@#{MSG_ADDRESS_SUFFIX}>"
end

def get_user_status(id)
  usr = User.find_by(Z_PK: id)
  return nil if usr.nil?
  status = UserStatus.new
  status.sender = [usr[:ZCUSTOMNAME], usr[:ZNAME], usr[:ZADDRESSBOOKNAME]].select { |n| n && n != '' }.join(', ')
  status.address = usr[:ZMID]
  return status
end
