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

  s.source_files = 'Pod/Classes/*.{h,m}'
  s.resource_bundles = {
    'BJHL-IM-iOS-SDK' => ['Pod/Assets/*']
  }

  s.public_header_files = 'Pod/Classes/BJHL.h'
  s.frameworks = 'CoreData'
  s.dependency 'AFNetworking', '~> 2.5'
  s.dependency 'Mantle', '~> 1.5'
  s.dependency 'MagicalRecord', '~> 2.2'
  s.dependency 'Log4Cocoa', '~> 0.1.0'
 
  s.subspec 'Vendor' do |ss|  
    ss.source_files = 'Pod/Classes/Vendor/*.{h,m}'
    ss.subspec 'aes' do |sss|
      sss.source_files = 'Pod/Classes/Vendor/aes/*.{h,m}'
    end 
  end
end
