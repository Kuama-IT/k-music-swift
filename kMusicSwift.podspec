Pod::Spec.new do |s|
  s.name             = 'kMusicSwift'
  s.version          = '0.1.0'
  s.summary          = 'just_audio flutter plugin iOS implementation'

  s.description      = <<-DESC
See https://github.com/ryanheise/just_audio/tree/minor/just_audio#readme for a full list of features
                       DESC

  s.homepage         = 'https://github.com/Kuama-IT/k-music-swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'cc18675dd6a3d8f9dd752f1bc3bc9210bda2938e' => 'daniele@kuama.net' }
  s.source           = { :git => 'https://github.com/cc18675dd6a3d8f9dd752f1bc3bc9210bda2938e/kMusicSwift.git', :tag => s.version.to_s }

  s.ios.deployment_target = '10.0'

  s.source_files = 'kMusicSwift/Classes/**/*'
  s.swift_version = '5.0'
  
  # s.resource_bundles = {
  #   'kMusicSwift' => ['kMusicSwift/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'SwiftAudioPlayer'
end
