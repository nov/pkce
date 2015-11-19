class AppDelegate
  def application(application, didFinishLaunchingWithOptions: options)
    @window = UIWindow.alloc.initWithFrame(UIScreen.mainScreen.bounds)
    storyboard = UIStoryboard.storyboardWithName('Storyboard', bundle: nil)
    @window.rootViewController = storyboard.instantiateInitialViewController
    @window.makeKeyAndVisible
    true
  end

  def application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    application application, didFinishLaunchingWithOptions: nil
    @window.rootViewController.callback url
    true
  end
end
