require 'json'
require 'nokogiri'

module FlexMessage
  LINE_HEIGHT = 1.4

  class << self

    def generate_content(doc, data)
      if data['type'] == 'carousel'
        generate_carousel(doc, data)
      else
        generate_bubble(doc, data)
      end
    end

    ################################################################################

    def generate_carousel(doc, data)
      data['contents'].each do |bubble|
        generate_bubble(doc, bubble)
      end
    end

    ################################################################################

    def generate_blockstyle(style_data)
      return {} if style_data == nil
      style = {}
      style['background-color'] = style_data['backgroundColor'] if style_data['backgroundColor']
      if style_data['separator']
        style['border-top'] = "1px solid #{style_data['separatorColor']}" if style_data['separatorColor']
      end
      return style
    end

    ################################################################################

    def generate_header(doc, header)
      style = generate_blockstyle(header['style'])
      doc.header() {
        generate_component(doc, header, style)
      }
    end

    def generate_hero(doc, hero)
      style = generate_blockstyle(hero['style'])
      doc.div(class: 'hero') {
        generate_component(doc, hero, style)
      }
    end

    def generate_body(doc, body, container_type)
      style = generate_blockstyle(body['style'])
      style['padding'] = '10px'
      if container_type == 'mega' || container_type == 'giga'
        style['padding'] = '20px'
      end
      doc.div(class: 'body') {
        generate_component(doc, body, style)
      }
    end

    def generate_footer(doc, footer)
      style = generate_blockstyle(footer['style'])
      style['padding'] = '10px'
      doc.footer() {
        generate_component(doc, footer, style)
      }
    end

    ################################################################################

    def generate_component(doc, data, style)
      action = data['action']
      if !action
        generate_component_without_action(doc, data, style)
      else
        case action['type']
        when 'postback'       then generate_postback_action(doc, data, style, action)
        when 'message'        then generate_message_action(doc, data, style, action)
        when 'uri'            then generate_uri_action(doc, data, style, action)
        when 'datetimepicker' then generate_datetimepicker_action(doc, data, style, action)
        when 'camera'         then generate_camera_action(doc, data, style, action)
        when 'cameraRoll'     then generate_cameraRoll_action(doc, data, style, action)
        when 'location'       then generate_location_action(doc, data, style, action)
        else raise NotImplementedError
        end
      end
    end

    def generate_component_without_action(doc, data, style)
      case data['type']
      when 'box'       then generate_box(doc, data, style)
      when 'button'    then generate_button(doc, data, style)
      when 'image'     then generate_image(doc, data, style)
      when 'icon'      then generate_icon(doc, data, style)
      when 'text'      then generate_text(doc, data, style)
      when 'span'      then generate_span(doc, data, style)
      when 'separator' then generate_separator(doc, data, style)
      when 'filler'    then generate_filler(doc, data, style)
      when 'spacer'    then generate_spacer(doc, data, style)
      else raise NotImplementedError
      end
    end

    ################################################################################

    def style_to_str(ary)
      ary.map {|key, value| "#{key}:#{value};"}.join()
    end

    ################################################################################

    def generate_postback_action(doc, data, style, action)
      doc.a(onclick: "alert('#{action['displayText'] || action['text']}');", title: action['label'], style: 'text-decoration:none;color:#333;') {
        generate_component_without_action(doc, data, style)
      }
    end

    def generate_message_action(doc, data, style, action)
      doc.a(onclick: "alert('#{action['text']}');", title: action['label'], style: 'text-decoration:none;color:#333;') {
        generate_component_without_action(doc, data, style)
      }
    end

    def generate_uri_action(doc, data, style, action)
      doc.a(href: action['altUri.desktop'] || action['uri'], title: action['label'], style: 'text-decoration:none;color:#333;') {
        generate_component_without_action(doc, data, style)
      }
    end

    def generate_datetimepicker_action(doc, data, style, action)
      doc.a(title: action['label'], style: 'text-decoration:none;color:#333;') {
        generate_component_without_action(doc, data, style)
      }
    end

    def generate_camera_action(doc, data, style, action)
      doc.a(title: action['label'], style: 'text-decoration:none;color:#333;') {
        generate_component_without_action(doc, data, style)
      }
    end

    def generate_cameraRoll_action(doc, data, style, action)
      doc.a(title: action['label'], style: 'text-decoration:none;color:#333;') {
        generate_component_without_action(doc, data, style)
      }
    end

    def generate_location_action(doc, data, style, action)
      doc.a(title: action['label'], style: 'text-decoration:none;color:#333;') {
        generate_component_without_action(doc, data, style)
      }
    end

    ################################################################################

    def generate_box_style(style_data)
      style = {}
      style['display']  = 'flex'
      style['position'] = 'relative'
      style['overflow'] = 'hidden'
      case style_data['layout']
      when 'horizontal' then style['flex-direction'] = 'row'
      when 'vertical'   then style['flex-direction'] = 'column'
      when 'baseline'
        style['flex-direction'] = 'row'
        style['align-items'] = 'baseline'
      end
      style.merge!(generate_component_common_style(style_data))

      return style
    end

    def generate_button_style(style_data)
      style = generate_component_common_style(style_data)
      style['display']   = 'block'
      style['width']     = '100%'
      style['padding']   = '0 16px'
      style['border']    = 0
      style['font-size'] = '16px'
      style['margin-left']  = 'auto'
      style['margin-right'] = 'auto'

      if style_data['height'] == 'sm'
        style['height'] = '40px'
      else
        style['height'] = '52px'
      end

      if style_data['style'] == 'primary'
        style['border-radius'] = '8px'
        style['color'] = '#FFF'
        if style_data['color']
          style['background-color'] = style_data['color']
        else
          style['background-color'] = '#17c950'
        end
      elsif style_data['style'] == 'secondary'
        style['border-radius'] = '8px'
        style['color'] = '#111'
        if style_data['color']
          style['background-color'] = style_data['color']
        else
          style['background-color'] = '#dcdfe5'
        end
      else
        style['background-color'] = 'inherit'
        if style_data['color']
          style['color'] = style_data['color']
        else
          style['color'] = '#42659a'
        end
      end
      return style
    end

    def generate_image_style(doc, style_data)
      style = generate_component_common_style(style_data)
      style['display'] = 'block'

      if style_data['align'] == 'start' && doc.parent['type'] == 'box'
        style['margin-left']  = 0
        style['margin-right'] = 'auto'
      elsif style_data['align'] == 'end' && doc.parent['type'] == 'box'
        style['margin-left']  = 'auto'
        style['margin-right'] = 0
      else
        style['margin-left']  = 'auto'
        style['margin-right'] = 'auto'
      end

      width = calc_imageWidth(style_data['size'] || 'md')
      style['width'] = width
      aspect = [1, 1]
      if style_data['aspectRatio']
        aspect = style_data['aspectRatio'].split(':')
      end
      if width == '100%'
        style['padding-top'] = "calc(#{aspect[1].to_f / aspect[0].to_f * 100}%)"
      else
        style['height']      = "calc(#{width} * #{ aspect[1].to_f / aspect[0].to_f})"
      end

      if style_data['aspectMode'] == 'cover'
        style['background-size'] = 'cover'
      else
        style['background-size'] = 'contain'
      end
      style['background-position'] = 'center'
      style['background-image']    = "url('#{style_data['url']}')"
      return style
    end

    def calc_imageWidth(str)
      case str
      when 'xxs'  then return '40px'
      when 'xs'   then return '60px'
      when 'sm'   then return '80px'
      when 'md'   then return '100px'
      when 'lg'   then return '120px'
      when 'xl'   then return '140px'
      when 'xxl'  then return '160px'
      when '3xl'  then return '180px'
      when '4xl'  then return '200px'
      when '5xl'  then return '240px'
      when 'full' then return '100%'
      else raise NotImplementedError
      end
    end

    def generate_icon_style(doc, style_data)
      fontSize = calc_fontSize(style_data['size'] || 'md')
      style = {'flex' => 'none'}
      style.merge!(generate_component_common_style(style_data))
      style['display']             = 'inline-block'
      style['font-size']           = fontSize.to_s + 'px'
      aspect = [1, 1]
      if style_data['aspectRatio']
        aspect = style_data['aspectRatio'].split(':')
      end
      style['height']              = (aspect[1].to_f / aspect[0].to_f).to_s + 'em'
      style['width']               = '1em'
      style['background-image']    = "url('#{style_data['url']}')"
      style['background-repeat']   = 'no-repeat'
      style['background-position'] = 'center'
      style['background-size']     = 'contain'
      return style
    end

    def calc_fontSize(str)
      case str
      when 'xxs'  then return 11
      when 'xs'   then return 13
      when 'sm'   then return 14
      when 'md'   then return 16
      when 'lg'   then return 19
      when 'xl'   then return 22
      when 'xxl'  then return 29
      when '3xl'  then return 35
      when '4xl'  then return 48
      when '5xl'  then return 74
      else raise NotImplementedError
      end
    end

    def generate_text_style(style_data)
      fontSize = calc_fontSize(style_data['size'] || 'md')
      style = generate_span_style(style_data)
      style['text-overflow'] = 'ellipsis'
      style['white-space']   = style_data['wrap'] ? 'normal' : 'nowrap'
      style['overflow']      = 'hidden' unless style_data['wrap']
      style['height']        = fontSize * style_data['maxLines'] * LINE_HEIGHT if style_data['maxLines']
      return style
    end

    def generate_span_style(style_data)
      fontSize = calc_fontSize(style_data['size'] || 'md')
      style = generate_component_common_style(style_data)
      style['font-size']       = fontSize.to_s + 'px'
      style['text-align']      = style_data['align']      if style_data['align']
      style['font-weight']     = style_data['weight']     if style_data['weight']
      style['color']           = style_data['color']      if style_data['color']
      style['font-style']      = style_data['style']      if style_data['style']
      style['text-decoration'] = style_data['decoration'] if style_data['decoration']
      return style
    end

    ################################################################################

    def generate_component_common_style(style_data)
      style = {'box-sizing' => 'border-box'}
      style['background-color'] = style_data['backgroundColor']               if style_data['backgroundColor']
      style['border-color']     = style_data['borderColor']                   if style_data['borderColor']
      style['border-width']     = calc_borderWidth(style_data['borderWidth']) if style_data['borderWidth']
      style['border-style']     = 'solid'                                     if style_data['borderWidth']
      style['border-radius']    = calc_cornerRadius(style_data['cornerRadius']) if style_data['cornerRadius']
      style['width']            = style_data['width']                         if style_data['width']
      style['height']           = style_data['height']                        if style_data['height']
      style['flex']             = style_data['flex']                          if style_data['flex']
      style['flex'] = 'none' if style['flex'] == 0
      style['padding']          = calc_padding(style_data['paddingAll'])      if style_data['paddingAll']
      style['padding-top']      = calc_padding(style_data['paddingTop'])      if style_data['paddingTop']
      style['padding-bottom']   = calc_padding(style_data['paddingBottom'])   if style_data['paddingBottom']
      style['padding-left']     = calc_padding(style_data['paddingStart'])    if style_data['paddingStart']
      style['padding-right']    = calc_padding(style_data['paddingEnd'])      if style_data['paddingEnd']
      style['position']         = style_data['position']                      if style_data['position']
      style['top']              = calc_offset(style_data['offsetTop'])        if style_data['offsetTop']
      style['bottom']           = calc_offset(style_data['offsetBottom'])     if style_data['offsetBottom']
      style['left']             = calc_offset(style_data['offsetStart'])      if style_data['offsetStart']
      style['right']            = calc_offset(style_data['offsetEnd'])        if style_data['offsetEnd']
      style['align-self']       = calc_gravity(style_data['gravity'])         if style_data['gravity']
      return style
    end

    def calc_borderWidth(str)
      case str
      when 'none' then return '0'
      when 'light' then return '0.5px'
      when 'normal' then return '1px'
      when 'medium' then return '2px'
      when 'semi-bold' then return '3px'
      when 'bold' then return '4px'
      else return str
      end
    end

    def calc_gravity(str)
      case str
      when 'top' then return 'start'
      when 'center' then return 'center'
      when 'bottom' then return 'end'
      else return str
      end
    end

    def calc_cornerRadius(str)
      calc_style_size(str)
    end

    def calc_margin(str)
      calc_style_size(str)
    end

    def calc_padding(str)
      calc_style_size(str)
    end

    def calc_offset(str)
      calc_style_size(str)
    end

    def calc_style_size(str)
      case str
      when 'none' then return '0'
      when 'xs' then return '2px'
      when 'sm' then return '4px'
      when 'md' then return '8px'
      when 'lg' then return '12px'
      when 'xl' then return '16px'
      when 'xxl' then return '20px'
      else return str
      end
    end

    ################################################################################

    def generate_box(doc, data, style)
      style.merge!(generate_box_style(data))

      child_style_all = {}
      child_style_except_1st = {}

      case data['layout']
      when 'vertical'
        child_style_except_1st['margin-top'] = calc_style_size(data['spacing']) if data['spacing']
      else
        child_style_all['flex'] = '1'
        child_style_except_1st['margin-left'] = calc_style_size(data['spacing']) if data['spacing']
      end

      doc.div(style: style_to_str(style)) {
        data['contents'].each_with_index do |content, idx|
          child_style = child_style_all.clone
          child_style = child_style_all.merge(child_style_except_1st) if idx != 0
          case data['layout']
          when 'vertical'
            child_style['margin-top'] = calc_margin(content['margin']) if content['margin']
            child_style['flex'] = 'none' if content['height']
          else
            child_style['margin-left'] = calc_margin(content['margin']) if content['margin']
            child_style['flex'] = 'none' if content['width']
          end
          generate_component(doc, content, child_style)
        end
      }
    end

    def generate_button(doc, data, style)
      style.merge!(generate_button_style(data))
      doc.button(style: style_to_str(style)) {
        doc.text(data['action']['label'])
      }
    end

    def generate_image(doc, data, style)
      style.merge!(generate_image_style(doc, data))
      inner_style = style.clone
      style.delete('padding-top')
      style.delete('background-image')
      doc.div(style: style_to_str(style)) {
        doc.div(style: style_to_str(inner_style)) {}
      }
    end

    def generate_icon(doc, data, style)
      style.merge!(generate_icon_style(doc, data))
      doc.div(style: style_to_str(style)) {}
    end

    def generate_text(doc, data, style)
      style.merge!(generate_text_style(data))
      if data['contents'] && data['contents'].count != 0
        doc.div(style: style_to_str(style)) {
          data['contents'].each do |span|
            generate_span(doc, span, style)
          end
        }
      else
        doc.div(style: style_to_str(style)) {
          doc.text(data['text'])
        }
      end
    end

    def generate_span(doc, data, style)
      span_style = style.merge(generate_span_style(data))
      doc.span(style: style_to_str(span_style)) {
        doc.text(data['text'])
      }
    end

    def generate_separator(doc, data, style)
      parent_styles = doc.parent['style']
      if parent_styles.include?('flex-direction:column;')
        style['height'] = '1px'
        style['margin-top'] = calc_margin(data['margin']) if data['margin']
      else
        style['width'] = '1px'
        style['margin-left'] = calc_margin(data['margin']) if data['margin']
      end
      style['background-color'] = data['backgroundColor'] || '#aaaaaa'
      doc.div(style: style_to_str(style))
    end

    def generate_filler(doc, data, style)
      style = {}
      style['flex'] = data['flex'] || '1 1 auto'
      style.merge!(generate_component_common_style(data))
      doc.div(style: style_to_str(style))
    end

    def generate_spacer(doc, data, style)
      parent_styles = doc.parent['style']
      if parent_styles.include?('flex-direction:column;')
        style['height'] = calc_style_size(data['size']) if data['size']
      else
        style['width']  = calc_style_size(data['size']) if data['size']
      end
      doc.div(style: style_to_str(style))
    end

    ################################################################################

    def generate_bubble(doc, data)
      if data['action']
      end
      container_type = data['size'] || 'mega'
      doc.section(style: "margin:16px;width:#{calc_bubbleWidth(container_type)};border-radius:#{calc_bubbleRadius(container_type)};overflow:hidden;background:#FFF;line-height:#{LINE_HEIGHT};") {
        generate_header(doc, data['header']) if data['header']
        generate_hero(doc, data['hero']) if data['hero']
        generate_body(doc, data['body'], container_type) if data['body']
        generate_footer(doc, data['footer']) if data['footer']
      }
    end

    def calc_bubbleWidth(str)
      case str
      when 'nano'  then return '120px'
      when 'micro' then return '160px'
      when 'kilo'  then return '260px'
      when 'mega'  then return '300px'
      when 'giga'  then return '400px'
      else raise NotImplementedError
      end
    end

    def calc_bubbleRadius(str)
      case str
      when 'nano'  then return '10px'
      when 'micro' then return '10px'
      when 'kilo'  then return '10px'
      when 'mega'  then return '17px'
      when 'giga'  then return '5px'
      else raise NotImplementedError
      end
    end
  end
end

################################################################################

def generate_flex_message(flex_json)
  flex_data = JSON.load(flex_json)
  builder = Nokogiri::HTML::Builder.new do |doc|
    doc.html {
      doc.body(style: "background:#728BB2;display:flex;font-family:-apple-system,'BlinkMacSystemFont',Helvetica,Roboto,Sans-Serif;-webkit-text-size-adjust:none;") {
        FlexMessage::generate_content(doc, flex_data)
        doc.script {
          doc.text('let data=' + flex_json + ';')
        }
      }
    }
  end
  return builder
end

################################################################################

if __FILE__ == $0
  flex_json = '{"type":"bubble","hero":{"type":"image","url":"https://scdn.line-apps.com/n/channel_devcenter/img/fx/01_1_cafe.png","size":"full","aspectRatio":"20:13","aspectMode":"cover","action":{"type":"uri","uri":"http://linecorp.com/"}},"body":{"type":"box","layout":"vertical","contents":[{"type":"text","text":"Brown Cafe","weight":"bold","size":"xl"},{"type":"box","layout":"baseline","margin":"md","contents":[{"type":"icon","size":"sm","url":"https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png"},{"type":"icon","size":"sm","url":"https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png"},{"type":"icon","size":"sm","url":"https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png"},{"type":"icon","size":"sm","url":"https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gold_star_28.png"},{"type":"icon","size":"sm","url":"https://scdn.line-apps.com/n/channel_devcenter/img/fx/review_gray_star_28.png"},{"type":"text","text":"4.0","size":"sm","color":"#999999","margin":"md","flex":0}]},{"type":"box","layout":"vertical","margin":"lg","spacing":"sm","contents":[{"type":"box","layout":"baseline","spacing":"sm","contents":[{"type":"text","text":"Place","color":"#aaaaaa","size":"sm","flex":1},{"type":"text","text":"Miraina Tower, 4-1-6 Shinjuku, Tokyo","wrap":true,"color":"#666666","size":"sm","flex":5}]},{"type":"box","layout":"baseline","spacing":"sm","contents":[{"type":"text","text":"Time","color":"#aaaaaa","size":"sm","flex":1},{"type":"text","text":"10:00 - 23:00","wrap":true,"color":"#666666","size":"sm","flex":5}]}]}]},"footer":{"type":"box","layout":"vertical","spacing":"sm","contents":[{"type":"button","style":"link","height":"sm","action":{"type":"uri","label":"CALL","uri":"https://linecorp.com"}},{"type":"button","style":"link","height":"sm","action":{"type":"uri","label":"WEBSITE","uri":"https://linecorp.com"}},{"type":"spacer","size":"sm"}],"flex":0}}'
# TODO: test with below data
#  flex_json = '{"type":"bubble","body":{"type":"box","layout":"vertical","contents":[{"type":"box","layout":"horizontal","contents":[{"type":"image","url":"https://scdn.line-apps.com/n/channel_devcenter/img/flexsnapshot/clip/clip7.jpg","size":"5xl","aspectMode":"cover","aspectRatio":"150:196","gravity":"center","flex":1},{"type":"box","layout":"vertical","contents":[{"type":"image","url":"https://scdn.line-apps.com/n/channel_devcenter/img/flexsnapshot/clip/clip8.jpg","size":"full","aspectMode":"cover","aspectRatio":"150:98","gravity":"center"},{"type":"image","url":"https://scdn.line-apps.com/n/channel_devcenter/img/flexsnapshot/clip/clip9.jpg","size":"full","aspectMode":"cover","aspectRatio":"150:98","gravity":"center"}],"flex":1}]},{"type":"box","layout":"horizontal","contents":[{"type":"box","layout":"vertical","contents":[{"type":"image","url":"https://scdn.line-apps.com/n/channel_devcenter/img/flexsnapshot/clip/clip13.jpg","aspectMode":"cover","size":"full"}],"cornerRadius":"100px","width":"72px","height":"72px"},{"type":"box","layout":"vertical","contents":[{"type":"text","contents":[{"type":"span","text":"brown_05","weight":"bold","color":"#000000"},{"type":"span","text":"     "},{"type":"span","text":"I went to the Brown&Cony cafe in Tokyo and took a picture"}],"size":"sm","wrap":true},{"type":"box","layout":"baseline","contents":[{"type":"text","text":"1,140,753 Like","size":"sm","color":"#bcbcbc"}],"spacing":"sm","margin":"md"}]}],"spacing":"xl","paddingAll":"20px"}],"paddingAll":"0px"}}'
  puts generate_flex_message(flex_json).to_html
end

