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
end