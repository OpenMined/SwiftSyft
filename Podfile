platform :ios, '13.0'
source 'https://github.com/CocoaPods/Specs.git'
workspace 'SwiftSyft'
use_frameworks!

target 'SwiftSyft_Example' do
  project 'Example/SwiftSyft.xcodeproj'
  pod 'OpenMinedSwiftSyft', :path => '.', :testspecs => ['Tests'] 
  pod 'SwiftLint', '~> 0.38.0'
  pod 'Charts'
  
  # Not included until https://github.com/CocoaPods/CocoaPods/issues/9473 is resolved
#  target 'SwiftSyft_Tests' do
#    inherit! :search_paths
#  end
end

target 'SwiftSyft-Background' do
  project 'Example-Background/SwiftSyft-Background.xcodeproj'
  pod 'OpenMinedSwiftSyft', :path => '.', :testspecs => ['Tests']
  pod 'SwiftLint', '~> 0.38.0'

  # Not included until https://github.com/CocoaPods/CocoaPods/issues/9473 is resolved
#  target 'SwiftSyft_Tests' do
#    inherit! :search_paths
#  end
end
