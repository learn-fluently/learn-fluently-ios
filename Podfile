platform :ios, '11.0'

target 'Learn Fluently' do
  use_frameworks!
  
  # ignore all warnings from all pods
  inhibit_all_warnings!

  pod 'SnapKit', '~> 4.2.0'
  pod 'SwiftRichString'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'SwiftLint'
  pod 'RLBAlertsPickers', :git => 'https://github.com/loicgriffie/Alerts-Pickers.git', :branch => 'master'
  pod 'ZIPFoundation', '~> 0.9'
  pod 'XCDYouTubeKit', :git => 'https://github.com/0xced/XCDYouTubeKit.git', :branch => 'master'
  pod 'SWXMLHash', '~> 4.7.0'
  pod 'mobile-ffmpeg-min', '~> 4.2'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
    end
  end
end
