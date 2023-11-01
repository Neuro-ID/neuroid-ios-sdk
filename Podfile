source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/Alamofire/Alamofire.git'
# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

target 'NeuroID' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!


  pod 'NeuroIDAdvancedDevice'

  pod 'Alamofire'
end
target 'SDKTest' do
  use_frameworks!
  pod 'Alamofire'
  pod 'JSONSchema', '0.5.0'
  pod 'DSJSONSchemaValidation'
end

post_install do |installer|
  installer.generated_projects.each do |project|
    project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
         end
    end
  end
end
