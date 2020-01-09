#
# Be sure to run `pod lib lint SwiftSyft.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftSyft'
  s.version          = '0.1.0'
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
  s.source           = { :git => 'https://github.com/OpenMined/SwiftSyft.git', :tag => s.version.to_s }

  s.ios.deployment_target = '13.0'
  s.swift_versions = '5.1.3'

  s.source_files = 'SwiftSyft/Classes/**/*'
  s.static_framework = true
  
  # s.resource_bundles = {
  #   'SwiftSyft' => ['SwiftSyft/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
   s.dependency 'LibTorch', '~> 1.3.0'
end
