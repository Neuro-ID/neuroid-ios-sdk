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
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
    xcconfig_path = config.base_configuration_reference.real_path
    xcconfig = File.read(xcconfig_path)
    xcconfig_mod = xcconfig.gsub(/DT_TOOLCHAIN_DIR/, "TOOLCHAIN_DIR")
    File.open(xcconfig_path, "w") { |file| file << xcconfig_mod }
    end
  end
end
