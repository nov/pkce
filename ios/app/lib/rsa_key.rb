class RSAKey
  def initialize
    generate_key_pair unless public_key_ref
  end

  def hash_algorighm
    :sha256
  end

  def public_key
    sec_key_wrapper.getPublicKeyBits
  end

  def destroy
    sec_key_wrapper.deleteAsymmetricKeys
  end

  private

  def generate_key_pair(key_size = 2048)
    sec_key_wrapper.generateKeyPair key_size
  end

  def tag_for(mode)
    [App.identifier, mode].collect(&:to_s).join('.')
  end

  def sec_key_wrapper
    SecKeyWrapper.sharedWrapper
  end

  def public_key_ref
    sec_key_wrapper.getPublicKeyRef
  end
end