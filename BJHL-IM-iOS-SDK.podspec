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
  s.version          = "1.0.0"
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

  s.source_files = 'core/**/*.{h,m}'
  s.resource_bundles = {
    'BJHL-IM-iOS-SDK' => ['Resources/*']
  }

  s.public_header_files = 'core/**/*.h'
  s.frameworks = 'CoreData'
  s.dependency 'AFNetworking', '~> 2.5'
  s.dependency 'Mantle', '~> 2.0'
  s.dependency 'MagicalRecord', '~> 2.2'
  s.dependency 'CocoaLumberjack', '~> 2.0.1'
  s.dependency 'BJHL-Common-iOS-SDK', '0.4.4'
  s.dependency 'LKDBHelper', '~>2.1.3'
  s.dependency 'YLGIFImage', '~> 0.11'
  s.dependency 'SlimeRefresh', '~> 0.0.1'
end
