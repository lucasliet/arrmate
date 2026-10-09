#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'apple_foundation_models'
  s.version          = '0.1.0'
  s.summary          = 'Apple Intelligence on-device language model for Flutter.'
  s.description      = <<-DESC
Bridges the Foundation Models framework so Flutter apps can generate text with
the Apple Intelligence system language model on iOS and macOS.
                       DESC
  s.homepage         = 'https://github.com/lucasliet/arrmate'
  s.license          = { :type => 'MIT' }
  s.author           = { 'Lucas Oliveira' => 'lucasouliveira@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'apple_foundation_models/Sources/apple_foundation_models/**/*.swift'
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  s.ios.deployment_target = '15.0'
  s.osx.deployment_target = '10.15'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
