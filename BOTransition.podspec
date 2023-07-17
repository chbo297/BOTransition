Pod::Spec.new do |s|
  s.name         = "BOTransition"
  s.version      = "2.2.14"
  s.summary      = "ViewController Present/Push/Pop Transition Effect"

  s.description  = "ViewController Present/Push/Pop Transition Effect. 统一present、NavigationController、TabController的转场动画设置方式。一行代码实现系统相册图片打开效果，弹窗效果，神奇动画转场。支持右滑、下滑、屏幕边缘滑入手势转场。"

  s.homepage     = "https://github.com/chbo297/BOTransition"
  s.license      = { :type => "Apache", :file => "LICENSE" }
  s.author       = { "bo" => "chbo297@gmail.com" }

  s.platform     = :ios, "9.0"
  s.source       = {
                     :git => "https://github.com/chbo297/BOTransition.git",
                     :tag => s.version
  }

  s.source_files  = "BOTransition", "BOTransition/*.{h}", "BOTransition/*.{m}", "BOTransition/effectGroup", "BOTransition/effectGroup/*.{h}", "BOTransition/effectGroup/*.{m}",
  s.framework = 'UIKit'
  s.license = 'Apache'
end
