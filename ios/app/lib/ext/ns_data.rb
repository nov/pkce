class NSData
  def to_url_safe_base64
    to_base64.gsub(/[\s=]+/, '').tr('+/', '-_')
  end
end