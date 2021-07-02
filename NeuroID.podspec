Pod::Spec.new do |spec|

  spec.name         = "NeuroID"
  spec.version      = "0.0.1"
  spec.summary      = "Test NeuroID"
  spec.homepage     = "https://google.com" //github url
  spec.license      = "MIT"

  spec.author             = { "Ky Nguyen" => "nguyentruongky33@gmail.com" }
  spec.platform     = :ios, "11.0"
  spec.source       = { :git => "https://github.com/nguyentruongky/Test.git", :tag => "#{spec.version}" }
  spec.source_files  = "NeuroID/**/*.{h,c,m,swift}"

  spec.xcconfig = { 
    'OTHER_CFLAGS'  => '-DSQLITE_HAS_CODEC -DSQLITE_TEMP_STORE=3 -DSQLCIPHER_CRYPTO_CC -DNDEBUG',
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) COCOAPODS=1 IOS=1 SQLITE_HAS_CODEC=1'
  }

end
