#
# Be sure to run `pod lib lint SwiftSyft.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'OpenMinedSwiftSyft'
  s.module_name      = 'SwiftSyft'
  s.version          = '0.1.0-beta1'
  s.summary          = 'The official Syft worker for iOS, built in Swift.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  SwiftSyft allows developers to integrate their apps as a worker to PySyft to facilitate
  Federated Learning.
                       DESC

  s.homepage         = 'https://github.com/OpenMined/SwiftSyft'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE' }
  s.author           = { 'OpenMined' => 'author@openmined.com' }
  s.source           = { :git => 'https://github.com/OpenMined/SwiftSyft.git', :tag => "v#{s.version.to_s}" }

  s.pod_target_xcconfig = { 'ENABLE_BITCODE' => 'NO' }
  s.ios.deployment_target = '13.0'
  s.swift_versions = '5.1.3'

  s.source_files = 'SwiftSyft/**/*'
  s.static_framework = true

  s.pod_target_xcconfig = {
    'HEADER_SEARCH_PATHS' => '$(inherited) "${PODS_ROOT}/LibTorch/install/include"',
    'VALID_ARCHS' => 'x86 arm64'
  }
  
  # s.resource_bundles = {
  #   'SwiftSyft' => ['SwiftSyft/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'LibTorch', '~> 1.5.0'
  s.dependency 'GoogleWebRTC', '~> 1.1.0'
  #s.dependency 'SyftProto', '0.2.9.a1' # TODO: Change this when official syft-proto comes out
  s.dependency 'SyftProto', '0.4.7' # TODO: Change this when official syft-proto comes out

  
  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/*.swift'

    test_spec.resources = 'Tests/Resources/*.{json,proto}'
    test_spec.dependency 'OHHTTPStubs/Swift'
    test_spec.requires_app_host = true
  end

end
