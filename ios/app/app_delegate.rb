class AppDelegate
  def application(application, didFinishLaunchingWithOptions: options)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    storyboard = UIStoryboard.storyboardWithName('Storyboard', bundle: nil)
    @window.rootViewController = storyboard.instantiateInitialViewController
    @window.rootViewController.popup options[:popup] if options.try(:[], :popup)
    @window.makeKeyAndVisible
    true
  end

  def application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    if PKCEGoogle.can_handle?(url)
      PKCEGoogle.handle url do |response|
        application application, didFinishLaunchingWithOptions: {popup: response.body.to_s}
      end
    end
  end
end
