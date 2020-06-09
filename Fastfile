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
MAIN_PROJECT = nil
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
#def distributeFabric(changelog)
#    $FABRIC_SCHEMES.any? {
#    	$FABRIC_SCHEMES.each { |scheme,configuration,bundleID, provisioningProfile|
#           doDistributeFabric(scheme,configuration,bundleID, provisioningProfile,changelog,'ad-hoc')
#	}
#    }
#    $FABRIC_DEV_SCHEMES.any? {
#        $FABRIC_DEV_SCHEMES.each { |scheme,configuration,bundleID, provisioningProfile|
#	   doDistributeFabric(scheme,configuration,bundleID, provisioningProfile,changelog,'development')
#        }
#    }
    
#end
#def doDistributeFabric(scheme, configuration,bundleID,provisioningProfile,changelog,export_method)
#	gym(scheme: scheme,skip_profile_detection:true,configuration:configuration,export_method:export_method,export_options:{
#     		  provisioningProfiles: {
#		        bundleID => provisioningProfile,
#		      }
#	    }
#	) # Build your app - more options available
#	puts $FABRIC_GROUPS
#	puts ENV["CRASHLYTICS_API_TOKEN"]
#	puts ENV["CRASHLYTICS_BUILD_SECRET"]
#        crashlytics(
#	    crashlytics_path: './Pods/Crashlytics/Crashlytics.framework',
#            api_token: ENV["CRASHLYTICS_API_TOKEN"],
#            build_secret: ENV["CRASHLYTICS_BUILD_SECRET"],
#            groups:$FABRIC_GROUPS,
#            notes: changelog)

#end

def doDistributeAppleStore()
	$SCHEME_INFOS.each { |scheme, bundleId |
		gym(scheme: scheme, 
                skip_profile_detection:true,
                include_bitcode:true,
                include_symbols:true,
                export_method: "app-store",
			export_options: {
    				provisioningProfiles: profiles
			}) # Build your app - more options available
            deliver(app_identifier: bundleId,
			skip_screenshots: true,
        	        skip_metadata: true,
                	submit_for_review: false,
                    skip_binary_upload: false)
	}
	
end 

platform :ios do
  
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
    doDistributeAppleStore()
    # frameit 
    add_git_tag(
            tag:"distribute/v" + get_version_number() + "_" + get_build_number()
            )
  end

	
  desc "Deploy a new version to the App Store with version bump"
  lane :UploadTestFlight do |options|
    # match(type: "appstore")
    # snapshot
    if !options[:nobump]
	
 
    	increment_build_number   
	    # frameit
	unless MAIN_PROJECT.nil?
		commit_version_bump(
			force:true,
			xcodeproj: MAIN_PROJECT
			)
	else
		commit_version_bump(
			force:true,
			)
    	end 

	scheme = $SCHEME_INFOS.first.first
	add_git_tag(
            tag:"distribute/v" + get_version_number(target: scheme) + "_" + get_build_number()
            )

    end
    changelog = generateReleaseNote()
    $SCHEME_INFOS.any? {
    	if !options[:nobuild]
        	$SCHEME_INFOS.each { |scheme, bundleId |
			build_app(workspace:$WORKSPACE + ".xcworkspace",
				scheme:scheme,
				output_name: scheme + ".ipa", )
		}
	end
	$SCHEME_INFOS.each { |scheme, bundleId |
		if !options[:changelog]
			upload_to_testflight(
				app_identifier:bundleId,
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



#  desc "Deploy a new version to Fabric"
#  lane :Fabric do

#    increment_build_number   
#    changelog = generateReleaseNote()
#    unless changelog.nil?
#	puts changelog
#    end
#    distributeFabric(changelog)
#    unless MAIN_PROJECT.nil?
#	commit_version_bump(
#		force:true,
#		xcodeproj: MAIN_PROJECT
#		)
#    else
#	commit_version_bump(
#		force:true,
#		)
#    end

#    add_git_tag(
#            tag:"build/" + $tagPrefix + "v" + get_build_number()
#            )
#  end

end



# More information about multiple platforms in fastlane: https://github.com/fastlane/fastlane/blob/master/docs/Platforms.md
# All available actions: https://github.com/fastlane/fastlane/blob/master/docs/Actions.md
