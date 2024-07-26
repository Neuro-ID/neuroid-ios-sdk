Pod::Spec.new do |s|

s.platform = :ios
s.ios.deployment_target = '12.0'
s.swift_version = '5.0'

s.name = "NeuroID"
s.module_name = "NeuroID"
s.summary = "NeuroID's official SDK for the iOS platform"
s.requires_arc = true
s.version = "3.3.2"
s.author = { "NeuroID" => "NeuroID" }
s.homepage = "https://neuro-id.com/"

s.source = { :git => "https://github.com/Neuro-ID/neuroid-ios-sdk.git", :tag => "v#{s.version}"}
s.source_files = "NeuroID/**/*.{h,c,m,swift,mlmodel,mlmodelc}"
s.resource_bundles = {
    'Resources' => ['NeuroID/Resources/**/*', 'Info.plist'],
    'NeuroID' => ['NeuroID/PrivacyInfo.xcprivacy']
}
s.exclude_files = 'NeuroID/NeuroIDClass/Extensions/NIDAdvancedDevice.swift'

s.dependency 'Alamofire'

s.default_subspecs = 'Core'
s.subspec 'Core' do |core|
    core.source_files = "NeuroID/**/*.{h,c,m,swift,mlmodel,mlmodelc}"
    core.exclude_files = 'NeuroID/NeuroIDClass/Extensions/NIDAdvancedDevice.swift'
end

s.subspec 'AdvancedDevice' do |advanced|
    advanced.ios.deployment_target = '12.0'
    advanced.source_files = "NeuroID/**/*.{h,c,m,swift,mlmodel,mlmodelc}"
    advanced.dependency 'NeuroIDAdvancedDevice'
end

s.license = { :type => "MIT", :text => <<-LICENSE
Copyright (c) 2021 Neuro-ID <product@neuro-id.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

LICENSE
 }
end
