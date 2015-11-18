module PKCEGoogle
  module_function

  def config
    {
      issuer:                 'https://accounts.google.com',
      authorization_endpoint: 'https://accounts.google.com/o/oauth2/v2/auth',
      token_endpoint:         'https://www.googleapis.com/oauth2/v4/token',
      userinfo_endpoint:      'https://www.googleapis.com/oauth2/v3/userinfo',
      jwks_uri:               'https://www.googleapis.com/oauth2/v3/certs',
      client_id:              '38576672693-tjq8f59ku41h2eb73ohir0r6m4lkb159.apps.googleusercontent.com',
      redirect_uri:           'com.googleusercontent.apps.38576672693-tjq8f59ku41h2eb73ohir0r6m4lkb159:/oauth2Callback'
    }
  end

  def authorization_url(params = {})
    x = [
      config[:authorization_endpoint],
      {
        response_type:         :code,
        client_id:             config[:client_id],
        scope:                 [:openid, :email].collect(&:to_s).join(' '),
        state:                 state(:force_regenerate),
        nonce:                 state,
        # code_challenge:        code_challenge(:force_regenerate),
        # code_challenge_method: :S256,
        verifier:              code_verifier(:force_regenerate),
        redirect_uri:          config[:redirect_uri]
      }.merge(params).to_query
    ].join('?').nsurl
    puts x
    x
  end

  def state(force_regenerate = false)
    App::Persistence.delete :state if force_regenerate
    App::Persistence[:state] ||= BW.create_uuid # NOTE: this line return true when no state exists. probably BubbleWrap's bug.
    App::Persistence[:state]
  end

  def code_challenge(force_regenerate = false)
    RmDigest::SHA256.digest(code_verifier force_regenerate).to_url_safe_base64
  end

  def code_verifier(force_regenerate = false)
    App::Persistence.delete :code_verifier if force_regenerate
    App::Persistence[:code_verifier] ||= BW.create_uuid
    App::Persistence[:code_verifier]
  end

  def can_handle?(callback_url)
    [:scheme, :host, :path].all? do |segment|
      callback_url.send(segment) == PKCEGoogle.config[:redirect_uri].nsurl.send(segment)
    end
  end

  def handle(callback_url, &block)
    params = callback_url.queryParameters.with_indifferent_access
    if state == params[:state]
      payload = {
        grant_type:    :authorization_code,
        code:          params[:code],
        client_id:     config[:client_id],
        redirect_uri:  config[:redirect_uri],
        # code_verifier: code_verifier
        verifier:      code_verifier
      }
      AFMotion::HTTP.post config[:token_endpoint], payload do |response|
        if response.success?
          token_response = BW::JSON.parse(response.object).with_indifferent_access
          p token_response
          block.call "#{token_response.keys.join(', ')} given"
        else
          block.call 'Token Request Failed'
        end
      end
    else
      block.call 'CSRF Attack Detected'
    end
  end

  def refresh!

  end
end