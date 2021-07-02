Pod::Spec.new do |s|

s.platform = :ios
s.ios.deployment_target = '11.0'
s.name = "NeuroID"
s.summary = "A Swift implementation of a custom UIControl for selecting a range of values on a slider bar."
s.requires_arc = true

s.version = "0.0.1"
s.license = { :type => "MIT", :file => "LICENSE" }
s.author = { "Ky Nguyen" => "nguyentruongky33@gmail.com" }
s.homepage = "https://google.com"
s.source = { :git => "https://github.com/nguyentruongky/Test.git", :tag => "#{s.version}"}

s.source_files = "NeuroID/**/*.{h,c,m,swift}"
spec.xcconfig = { 
    'OTHER_CFLAGS'  => '-DSQLITE_HAS_CODEC -DSQLITE_TEMP_STORE=3 -DSQLCIPHER_CRYPTO_CC -DNDEBUG',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) COCOAPODS=1 IOS=1 SQLITE_HAS_CODEC=1'
  }
end