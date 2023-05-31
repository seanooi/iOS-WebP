Pod::Spec.new do |s|
  s.name         		= 'iOS-WebP'
  s.ios.deployment_target  	= '11.0'
  s.tvos.deployment_target  	= '11.0'
  s.license      		= 'MIT'
  s.version      		= '0.5'
  s.homepage     		= 'https://github.com/seanooi/iOS-WebP'
  s.summary     		= 'WebP image decoder and encoder for iOS'
  s.author       		= { 'Sean Ooi' => 'sean.ooi@me.com' }
  s.source       		= { :git => 'https://github.com/seanooi/iOS-WebP.git', :tag => '0.5' }
  s.source_files		= 'iOS-WebP/*.{h,m}'
  s.requires_arc		= true
  s.dependency      'libwebp/webp', '~> 1.2.4'
end
