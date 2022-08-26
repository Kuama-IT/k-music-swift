#
# Be sure to run `pod lib lint kMusicSwift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'kMusicSwift'
  s.version          = '0.1.0'
  s.summary          = 'A short description of kMusicSwift.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/cc18675dd6a3d8f9dd752f1bc3bc9210bda2938e/kMusicSwift'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'cc18675dd6a3d8f9dd752f1bc3bc9210bda2938e' => 'daniele@kuama.net' }
  s.source           = { :git => 'https://github.com/cc18675dd6a3d8f9dd752f1bc3bc9210bda2938e/kMusicSwift.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'

  s.source_files = 'kMusicSwift/Classes/**/*'
  
  # s.resource_bundles = {
  #   'kMusicSwift' => ['kMusicSwift/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
