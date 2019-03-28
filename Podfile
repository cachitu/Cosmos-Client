# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Cosmos Client' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
    use_frameworks!
    pod 'secp256k1.swift', '~> 0.1.4'
    pod 'CryptoSwift', '~> 0.11'
    pod 'scrypt', '~> 3.0'

    post_install do |installer|
      installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['DEBUG_INFORMATION_FORMAT'] = 'dwarf'
        end
      end
    end

end



