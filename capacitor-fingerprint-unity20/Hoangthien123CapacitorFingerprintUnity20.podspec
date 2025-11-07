Pod::Spec.new do |s|
  s.name             = 'Hoangthien123CapacitorFingerprintUnity20'
  s.version          = '0.1.0'
  s.summary          = 'Capacitor v7 plugin for Unity20 BLE fingerprint (iOS)'
  s.license          = { :type => 'MIT' }
  s.homepage         = 'https://github.com/hoangthien123/sdk-finger'
  s.author           = { 'hoangthien123' => 'noreply@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'ios/Plugin/**/*.{swift,h,m,mm,c}'
  s.ios.deployment_target = '13.0'
  s.swift_version    = '5.0'
  s.static_framework = true
  s.dependency       'Capacitor'
end
