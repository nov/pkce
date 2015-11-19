class PKCERootViewController < UIViewController
  extend IB
  outlet :login_button, UIButton

  def start_dancing
    safari_view = SFSafariViewController.alloc.initWithURL(
      PKCEGoogle.authorization_url
    )
    presentViewController(
      safari_view,
      animated: true,
      completion: nil
    )
  end

  def callback(url)
    puts url
    if PKCEGoogle.can_handle?(url)
      PKCEGoogle.handle url do |message|
        App.alert message
      end
    end
  end
end