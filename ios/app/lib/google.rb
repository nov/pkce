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
    [
      config[:authorization_endpoint],
      {
        response_type:         :code,
        client_id:             config[:client_id],
        scope:                 [:openid, :email].collect(&:to_s).join(' '),
        state:                 state(:force_regenerate),
        nonce:                 state,
        code_challenge:        code_challenge(:force_regenerate),
        code_challenge_method: :S256,
        redirect_uri:          config[:redirect_uri],
        # prompt: :none
      }.merge(params).to_query
    ].join('?').nsurl
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
    # NOTE: handling query & fragment params in same code.
    authz_response = callback_url.to_s.sub('#', '?').nsurl.queryParameters.with_indifferent_access
    if state == authz_response[:state]
      puts '# AuthZ Response'
      p authz_response
      if authz_response[:code]
        exchange_code! authz_response[:code] do |token_response|
          puts '# Token Response'
          p token_response
          if token_response[:refresh_token]
            refresh_token! token_response[:refresh_token] do |refresh_response|
              puts '# Refresh Response'
              p refresh_response
              block.call summarize(authz_response, token_response, refresh_response)
            end
          else
            block.call summarize(authz_response, token_response)
          end
        end
      else
        block.call summarize(authz_response)
      end
    else
      block.call 'CSRF Attack Detected'
    end
  end

  def exchange_code!(code, &block)
    payload = {
      grant_type:    :authorization_code,
      code:          code,
      client_id:     config[:client_id],
      redirect_uri:  config[:redirect_uri],
      code_verifier: code_verifier
    }
    AFMotion::HTTP.post config[:token_endpoint], payload do |response|
      block.call BW::JSON.parse(response.object).with_indifferent_access
    end
  end

  def refresh_token!(refresh_token, &block)
    payload = {
      grant_type:    :refresh_token,
      refresh_token: refresh_token,
      client_id:     config[:client_id],
      redirect_uri:  config[:redirect_uri]
    }
    AFMotion::HTTP.post config[:token_endpoint], payload do |response|
      block.call BW::JSON.parse(response.object).with_indifferent_access
    end
  end

  def summarize(*responses)
    responses.collect(&:keys).collect do |keys|
      "#{keys.join(', ')} given"
    end.join("\n-----\n")
  end
end