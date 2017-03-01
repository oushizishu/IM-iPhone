#
# Be sure to run `pod lib lint BJHL-IM-iOS-SDK.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "BJHL-IM-iOS-SDK"
  s.version          = "4.6.1"
  s.summary          = "BJHL-IM-iOS-SDK."
  s.description      = <<-DESC
                      百家互联 iOS IM SDK
                       DESC
  s.homepage         = "http://git.baijiahulian.com/app/im-iphone"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "yanglei" => "yanglei@baijiahulian.com" }
  s.source           = { :git => "git@git.baijiahulian.com:app/im-iphone.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '6.1'
  s.requires_arc = true

  s.source_files = 'core/**/*.{h,m,cpp,mm}'
  # s.vendored_libraries = 'core/lib/*.a'
  s.libraries        = 'stdc++', 'z'
  # s.resource_bundles = {
  #   'BJHL-IM-iOS-SDK' => ['Resources/*']
  # }

  s.public_header_files = 'core/**/*.h'
  s.frameworks = 'CoreData'

s.dependency 'AFNetworking'
s.dependency 'Mantle'
s.dependency 'CocoaLumberjack'
s.dependency 'BJHL-Kit-iOS'
s.dependency 'BJHL-Foundation-iOS'
s.dependency 'BJHL-Media-iOS'
s.dependency 'BJHL-Permissions-iOS'
s.dependency 'BJHL-Network-iOS'
s.dependency 'BJHL-PictureBrowser-iOS'
s.dependency 'LKDBHelper'
s.dependency 'YLGIFImage'
s.dependency 'MBProgressHUD'
s.dependency 'BJHL-Websocket-iOS'
s.dependency 'ReactiveCocoa'
end
