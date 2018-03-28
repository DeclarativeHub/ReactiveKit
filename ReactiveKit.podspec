Pod::Spec.new do |s|
  s.name             = "ReactiveKit"
  s.version          = "3.9.3"
  s.summary          = "A Swift Reactive Programming Framework"
  s.description      = "ReactiveKit is a Swift framework for reactive and functional reactive programming."
  s.homepage         = "https://github.com/DeclarativeHub/ReactiveKit"
  s.license          = 'MIT'
  s.author           = { "Srdan Rasic" => "srdan.rasic@gmail.com" }
  s.source           = { :git => "https://github.com/DeclarativeHub/ReactiveKit.git", :tag => "v3.9.3" }

  s.ios.deployment_target       = '8.0'
  s.osx.deployment_target       = '10.9'
  s.watchos.deployment_target   = '2.0'
  s.tvos.deployment_target      = '9.0'

  s.source_files      = 'Sources/*.swift', 'ReactiveKit/*.{h,m}'
  s.requires_arc      = true
end
