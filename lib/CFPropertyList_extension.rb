# frozen_string_literal: true

require 'cfpropertylist'

# for LINE Album plist
module CFPropertyList
  # Converts a NSKeyedArchiver to native Ruby types
  def unpacked_native_types(archiver)
    return if archiver&.value&.[]('$archiver')&.value != 'NSKeyedArchiver'

    objects_array = archiver.value['$objects']&.value
    return if objects_array.nil?
    top_ptr = archiver.value['$top']&.value&.[]('root')&.value
    return if top_ptr.nil?
    root_dic = objects_array[top_ptr]
    return if root_dic.nil?

    lambda_def = lambda do |obj|
      return if obj.nil?
      case obj
      when CFUid then
        return lambda_def.call(objects_array[obj.value])
      when CFDate, CFString, CFInteger, CFReal, CFBoolean then
        return obj.value
      when CFData then
        return CFPropertyList::Blob.new(obj.decoded_value)
      when CFArray then
        return obj.value.map { |v| lambda_def.call(v) }
      when CFDictionary then
        # remove all '$class' information from dictionaries
        return obj.value.reject { |k, _| k == '$class' }.map { |k, v| [k, lambda_def.call(v)] }.to_h
      end
    end

    return lambda_def.call(root_dic)
  end

  module_function :unpacked_native_types
end
