# Customise this file, documentation can be found here:
# https://github.com/fastlane/fastlane/tree/master/docs
# All available actions: https://github.com/fastlane/fastlane/blob/master/docs/Actions.md
# can also be listed using the `fastlane actions` command

# Change the syntax highlighting to Ruby
# All lines starting with a # are ignored when running `fastlane`

# By default, fastlane will send which actions are used
# No personal data is shared, more information on https://github.com/fastlane/enhancer
# Uncomment the following line to opt out
# opt_out_usage

# If you want to automatically update fastlane if a new version is available:
# update_fastlane

# This is the minimum version number required.
# Update this, if you use features of a newer version


default_platform :ios
$WORKSPACE = ""
$SCHEME_INFOS = []
$tagPrefix = ""
$MAIN_PROJECT = nil
$PROVISIONING_PROFILES = {}
$APP_STORE_CONNECT_API_KEY_KEY_ID = ""
$APP_STORE_CONNECT_API_KEY_ISSUER_ID = ""
$APP_STORE_CONNECT_API_KEY_KEYFILE = ""

def generateReleaseNote
    count = sh("git describe --match \"distribute/v*\" | wc -l")
    changelog = "no log...."
    if count > 0.to_s
        #changelog = sh("git log --reverse --format=\"%b %s\"")
        changelog = changelog_from_git_commits(between:['HEAD^^','HEAD'])
    else
        changelog = changelog_from_git_commits(
           tag_match_pattern: "distribute/" + $tagPrefix + "v*",
           match_lightweight_tag: false,
           include_merges: false)
    end
    return changelog
end


def doDistributeAppleStore()
	$SCHEME_INFOS.each { |scheme, bundleId |
		gym(scheme: scheme, 
                skip_profile_detection:false,
                include_bitcode:true,
                include_symbols:true,
                export_method: "app-store-connect")
			# export_options: {
    				# provisioningProfiles: profiles
			# }) # Build your app - more options available
        deliver(app_identifier: bundleId,
			skip_screenshots: true,
           	skip_metadata: true,
            submit_for_review: false,
			skip_binary_upload: false)
	}
	
end 

platform :ios do
  desc "Remove Swift Package Manager Cache"
  lane :removeSPMcache do
	sh("rm","-rf","~/Library/Caches/org.swift.swiftpm")
        sh("rm","-rf","~/Library/org.swift.swiftpm")
  end
  desc "Reload Cocoapods library"
  lane :podReload do
	sh("rm", "-rf",Dir.home + "/Library/Caches/CocoaPods")
	sh("rm","-rf","../Pods/")
	cocoapods(repo_update:true, try_repo_update_on_error:true, clean_install:true)  
  end
  desc "Upload ScreenShots to AppStore"
  lane :UploadScreenshots do
        deliver(skip_screenshots: false,
                skip_metadata: true,
                submit_for_review: false,
		skip_binary_upload: true,
		overwrite_screenshots:true)
  end

  desc "Deploy a new version to the App Store"
  lane :Distribute do
    # match(type: "appstore")
    # snapshot
    app_store_connect_api_key(
  	key_id: $APP_STORE_CONNECT_API_KEY_KEY_ID,
	issuer_id: $APP_STORE_CONNECT_API_KEY_ISSUER_ID,
	key_filepath: $APP_STORE_CONNECT_API_KEY_KEYFILE, # 使用相對或絕對路徑
	in_house: false # 如果是企業帳號則設為 true，否則設為 false
    )
    doDistributeAppleStore()
    # frameit 
    add_git_tag(
            tag:"distribute/v" + get_version_number() + "/" + get_build_number()
            )
  end

	
  desc "Deploy a new version to the App Store with version bump"
  lane :UploadTestFlight do |options|
    # match(type: "appstore")
    # snapshot

    app_store_connect_api_key(
  	key_id: $APP_STORE_CONNECT_API_KEY_KEY_ID,
	issuer_id: $APP_STORE_CONNECT_API_KEY_ISSUER_ID,
	key_filepath: $APP_STORE_CONNECT_API_KEY_KEYFILE, # 使用相對或絕對路徑
	in_house: false # 如果是企業帳號則設為 true，否則設為 false
    )



    if !options[:nobump]
	
 
    	increment_build_number   
	    # frameit
	unless $MAIN_PROJECT.nil?
		commit_version_bump(
			force:true,
			xcodeproj: $MAIN_PROJECT
			)
	else
		commit_version_bump(
			force:true,
			)
    	end 

	scheme = $SCHEME_INFOS.first.first
	add_git_tag(
            tag:"distribute/v" + get_version_number(target: scheme) + "/" + get_build_number()
            )

    end
    changelog = generateReleaseNote()
    $SCHEME_INFOS.any? {
    	if !options[:nobuild]
        	$SCHEME_INFOS.each { |scheme, bundleId |
			export_options = {
				method: "app-store-connect"
			}

			if defined?($PROVISIONING_PROFILES) && !$PROVISIONING_PROFILES.empty?
				export_options[:provisioningProfiles] = $PROVISIONING_PROFILES
			end

			if $WORKSPACE == ""
				build_app(scheme:scheme,
					output_name: scheme + ".ipa",
					export_options: export_options)
			else

				build_app(workspace:$WORKSPACE + ".xcworkspace",
					scheme:scheme,
					output_name: scheme + ".ipa",
					export_options: export_options)
                        end
		}
	end
	$SCHEME_INFOS.each { |scheme, bundleId |
		if !options[:changelog]
			upload_to_testflight(
				app_identifier:bundleId,
				skip_submission:true,
				skip_waiting_for_build_processing:true,
				ipa:scheme + ".ipa")			
		else

			upload_to_testflight(
				app_identifier:bundleId,
				changelog: changelog,
				ipa:scheme + ".ipa")
		end
        }

    }
 
  end

end



# More information about multiple platforms in fastlane: https://github.com/fastlane/fastlane/blob/master/docs/Platforms.md
# All available actions: https://github.com/fastlane/fastlane/blob/master/docs/Actions.md
