# Fastfile 2.0 - Simplified Configuration
# Documentation: https://github.com/fastlane/fastlane/tree/master/docs
# All available actions: https://github.com/fastlane/fastlane/blob/master/docs/Actions.md

require 'tmpdir'
require 'fileutils'

default_platform :ios

# ============================================
# 2.0 Configuration
# ============================================
# 只需要提供主 app 的 scheme list
# 注意：Extensions (Widget, Share Extension 等) 不需要加入，它們會自動跟隨主 app 打包
# 例如: ["MyApp"] 或多環境 ["MyApp-Dev", "MyApp-Prod"]
$SCHEMES = []

# Optional: 如果專案使用 CocoaPods，需要指定 workspace 名稱（不含 .xcworkspace）
$WORKSPACE = ""

# Optional: Git tag 前綴
$tagPrefix = ""

# Optional: 主專案名稱（用於 version bump commit）
$MAIN_PROJECT = nil

# App Store Connect API Key (必填 - 用於上傳到 TestFlight)
$APP_STORE_CONNECT_API_KEY_KEY_ID = ""
$APP_STORE_CONNECT_API_KEY_ISSUER_ID = ""
$APP_STORE_CONNECT_API_KEY_KEYFILE = ""

# ============================================
# Android (Google Play) Configuration
# ============================================
# 應用程式的 package name，例如: "com.example.myapp"（必填 - 用於上傳到 Google Play）
$ANDROID_PACKAGE_NAME = ""

# Google Play Service Account JSON Key 檔案路徑（必填，勿 commit 進 repo）
$ANDROID_JSON_KEY_FILE = ""

# Optional: app/build.gradle 相對於專案根目錄的路徑（用於讀取/更新 versionCode、versionName）
$ANDROID_BUILD_GRADLE = "app/build.gradle"

# Optional: Gradle module 名稱（用於決定 build task 與預設 AAB 路徑）
$ANDROID_GRADLE_MODULE = "app"

# Optional: AAB 檔案路徑（相對於專案根目錄）。留空則使用預設路徑：
# "#{$ANDROID_GRADLE_MODULE}/build/outputs/bundle/release/#{$ANDROID_GRADLE_MODULE}-release.aab"
$ANDROID_AAB_PATH = nil

# Optional: Google Play track，預設 "internal"
$ANDROID_TRACK = "internal"

# Optional: changelog 使用的語系
$ANDROID_RELEASE_NOTES_LANG = "en-US"

# Optional: versionCode 來源，"gradle"（預設，數字寫死在 build.gradle）或 "git_tag"
# （由 git tag 推算，適合 build.gradle 用 `git describe` 算 versionCode 的專案）
$ANDROID_VERSION_SOURCE = "gradle"

# git_tag 模式必填：目前的 versionName（例如 "2.9.0"），用來組出下一個 tag
$ANDROID_VERSION_NAME = nil

# Optional: git_tag 模式用來尋找/建立 tag 的前綴，預設 "distribute/v"
# tag 格式為 "#{$ANDROID_GIT_TAG_PREFIX}#{$ANDROID_VERSION_NAME}/#{versionCode}"
$ANDROID_GIT_TAG_PREFIX = "distribute/v"

# Optional: build AAB 用的 gradle task 名稱，預設 "bundleRelease"
# 有 flavor 的專案可指定例如 "bundleProdRelease"
$ANDROID_BUNDLE_TASK = nil


# ============================================
# Helper Functions
# ============================================

# 從 Xcode 專案自動提取開發團隊 ID
def get_development_team
  begin
    if $WORKSPACE != ""
      cmd = "xcodebuild -workspace ../#{$WORKSPACE}.xcworkspace -showBuildSettings 2>/dev/null"
    else
      xcodeproj = Dir.glob("../*.xcodeproj").first
      if xcodeproj
        project_name = File.basename(xcodeproj)
        cmd = "xcodebuild -project ../#{project_name} -showBuildSettings 2>/dev/null"
      else
        return nil
      end
    end

    result = sh("#{cmd} | grep -E '^[[:space:]]+DEVELOPMENT_TEAM = ' | head -n 1 | awk -F ' = ' '{print $2}'").strip
    return result if result && !result.empty?
  rescue => ex
    UI.error("無法獲取 Development Team: #{ex.message}")
  end
  return nil
end

# 從 Xcode 專案自動提取 scheme 的 bundle ID
def get_bundle_id_for_scheme(scheme)
  begin
    # 直接使用 xcodebuild 獲取 PRODUCT_BUNDLE_IDENTIFIER
    # 這個方法適用於所有類型的專案（包括 generated Info.plist）
    if $WORKSPACE != ""
      # 使用 workspace
      cmd = "xcodebuild -workspace ../#{$WORKSPACE}.xcworkspace -scheme '#{scheme}' -showBuildSettings 2>/dev/null"
    else
      # 查找並使用 .xcodeproj 文件
      xcodeproj = Dir.glob("../*.xcodeproj").first
      if xcodeproj
        project_name = File.basename(xcodeproj)
        cmd = "xcodebuild -project ../#{project_name} -scheme '#{scheme}' -showBuildSettings 2>/dev/null"
      else
        UI.error("找不到 .xcodeproj 文件")
        return nil
      end
    end

    # 獲取 build settings 並提取 PRODUCT_BUNDLE_IDENTIFIER
    # 使用 grep 找到包含 PRODUCT_BUNDLE_IDENTIFIER 的行，然後用 awk 提取值
    result = sh("#{cmd} | grep -E '^[[:space:]]+PRODUCT_BUNDLE_IDENTIFIER = ' | head -n 1 | awk -F ' = ' '{print $2}'").strip

    if result && !result.empty? && result != "NO"
      UI.message("✓ Scheme '#{scheme}' 的 Bundle ID: #{result}")
      return result
    else
      UI.error("無法獲取 scheme '#{scheme}' 的 Bundle ID（返回值: #{result}）")
      return nil
    end
  rescue => ex
    UI.error("獲取 Bundle ID 時發生錯誤: #{ex.message}")
    return nil
  end
end

# 自動構建 scheme info (scheme => bundle_id 的映射)
def build_scheme_infos
  scheme_infos = []

  if defined?($SCHEMES) && !$SCHEMES.empty?
    UI.message("🔍 正在自動提取 schemes 的配置信息...")
    $SCHEMES.each do |scheme|
      bundle_id = get_bundle_id_for_scheme(scheme)
      if bundle_id
        scheme_infos << [scheme, bundle_id]
      else
        UI.error("無法獲取 scheme '#{scheme}' 的 bundle ID，請檢查配置")
      end
    end
    return scheme_infos
  end

  UI.error("❌ 請配置 $SCHEMES")
  return []
end

# 生成 Release Note
def generateReleaseNote
  count = sh("git describe --match \"distribute/v*\" | wc -l")
  changelog = "no log...."
  if count > 0.to_s
    changelog = changelog_from_git_commits(between:['HEAD^^','HEAD'])
  else
    changelog = changelog_from_git_commits(
      tag_match_pattern: "distribute/" + $tagPrefix + "v*",
      match_lightweight_tag: false,
      include_merges: false)
  end
  return changelog
end

# 取得 app/build.gradle 的完整路徑（相對於專案根目錄）
def android_gradle_path
  File.expand_path("../#{$ANDROID_BUILD_GRADLE}")
end

# 從 build.gradle 讀取 versionCode
def get_android_version_code(gradle_path)
  content = File.read(gradle_path)
  match = content.match(/versionCode\s*=?\s*(\d+)/)
  UI.user_error!("❌ 在 #{gradle_path} 找不到 versionCode") unless match
  match[1].to_i
end

# 從 build.gradle 讀取 versionName
def get_android_version_name(gradle_path)
  content = File.read(gradle_path)
  match = content.match(/versionName\s*=?\s*["']([^"']+)["']/)
  UI.user_error!("❌ 在 #{gradle_path} 找不到 versionName") unless match
  match[1]
end

# 將 build.gradle 的 versionCode 加一，回傳新的 versionCode
def increment_android_version_code!(gradle_path)
  content = File.read(gradle_path)
  new_version_code = get_android_version_code(gradle_path) + 1
  updated = content.sub(/versionCode(\s*=?\s*)\d+/, "versionCode\\1#{new_version_code}")
  File.write(gradle_path, updated)
  new_version_code
end

# 是否為 git_tag 版號來源模式
def android_git_tag_version_source?
  ($ANDROID_VERSION_SOURCE || "gradle").to_s == "git_tag"
end

# 從符合 $ANDROID_GIT_TAG_PREFIX 的 git tag 中取得目前最大的 versionCode（找不到則回傳 0）
def latest_android_git_tag_version_code
  prefix = $ANDROID_GIT_TAG_PREFIX || "distribute/v"
  tags = sh("git tag --list '#{prefix}*'").split("\n").map(&:strip).reject(&:empty?)
  return 0 if tags.empty?
  tags.map { |t| t.split("/").last.to_i }.max
end

# 取得目前的 versionCode（依 $ANDROID_VERSION_SOURCE 決定從 gradle 檔案讀取或從 git tag 推算）
def current_android_version_code(gradle_path)
  if android_git_tag_version_source?
    latest_android_git_tag_version_code
  else
    get_android_version_code(gradle_path)
  end
end

# git_tag 模式：建立下一個 distribute tag（不修改 build.gradle），回傳新的 versionCode
def bump_android_git_tag_version!
  UI.user_error!("❌ git_tag 模式請設定 $ANDROID_VERSION_NAME") if $ANDROID_VERSION_NAME.to_s.empty?
  prefix = $ANDROID_GIT_TAG_PREFIX || "distribute/v"
  new_version_code = latest_android_git_tag_version_code + 1
  tag = "#{prefix}#{$ANDROID_VERSION_NAME}/#{new_version_code}"
  add_git_tag(tag: tag)
  UI.success("✓ 已創建 tag: #{tag}")
  new_version_code
end

# 計算預設的 AAB 輸出路徑（相對於專案根目錄）
def android_aab_relative_path
  return $ANDROID_AAB_PATH unless $ANDROID_AAB_PATH.to_s.empty?
  "#{$ANDROID_GRADLE_MODULE}/build/outputs/bundle/release/#{$ANDROID_GRADLE_MODULE}-release.aab"
end

# 用 jarsigner 驗證 AAB 簽名，未簽名或驗證失敗會直接拋出例外中止 lane
def verify_aab_signature(aab_path)
  sh("jarsigner -verify -verbose -certs '#{aab_path}'")
end

# 建立暫時的 supply metadata 目錄，只放 changelog 檔案（<lang>/changelogs/<version_code>.txt）
# 這樣可以只上傳 changelog，不需要 repo 裡有完整的 metadata/screenshots
def build_changelog_metadata_dir(version_code, changelog)
  dir = Dir.mktmpdir("ipafastfile_android_changelog")
  changelogs_dir = File.join(dir, $ANDROID_RELEASE_NOTES_LANG, "changelogs")
  FileUtils.mkdir_p(changelogs_dir)
  File.write(File.join(changelogs_dir, "#{version_code}.txt"), changelog)
  dir
end


# ============================================
# Lanes
# ============================================

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

  desc "Deploy a new version to the App Store with version bump"
  desc "Options:"
  desc "  nobump: 跳過 version bump"
  desc "  nobuild: 跳過 build（只上傳已有的 ipa，自動跳過 version bump）"
  desc "  changelog: 是否包含 changelog"
  lane :UploadTestFlight do |options|
    # 如果 nobuild，自動設置 nobump
    if options[:nobuild]
      options[:nobump] = true
      UI.message("⚠️  nobuild 模式：自動跳過 version bump")
    end

    # 設置 App Store Connect API Key
    app_store_connect_api_key(
      key_id: $APP_STORE_CONNECT_API_KEY_KEY_ID,
      issuer_id: $APP_STORE_CONNECT_API_KEY_ISSUER_ID,
      key_filepath: $APP_STORE_CONNECT_API_KEY_KEYFILE,
      in_house: false
    )

    # 自動構建 scheme infos
    scheme_infos = build_scheme_infos

    if scheme_infos.empty?
      UI.user_error!("❌ 沒有可用的 scheme 配置，請檢查 $SCHEMES")
    end

    UI.message("📦 準備處理的 schemes:")
    scheme_infos.each do |scheme, bundle_id|
      UI.message("  • #{scheme} (#{bundle_id})")
    end

    # Version Bump
    if !options[:nobump]
      increment_build_number

      unless $MAIN_PROJECT.nil?
        commit_version_bump(
          force: true,
          xcodeproj: $MAIN_PROJECT
        )
      else
        commit_version_bump(force: true)
      end

      # 添加 git tag
      scheme = scheme_infos.first.first
      version = get_version_number(target: scheme)
      build = get_build_number()
      tag = "distribute/#{$tagPrefix}v#{version}/#{build}"

      add_git_tag(tag: tag)
      UI.success("✓ 已創建 tag: #{tag}")
    end

    # 生成 changelog
    changelog = generateReleaseNote()

    # Build
    if !options[:nobuild]
      UI.message("🔨 開始構建...")

      # 獲取開發團隊 ID（用於自動簽名）
      team_id = get_development_team
      if team_id
        UI.message("✓ Development Team: #{team_id}")
      end

      scheme_infos.each do |scheme, bundle_id|
        UI.message("正在構建: #{scheme}")

        # 專案可提供完整的 export 設定（例如手動 signing）；未提供時維持原本自動簽名設定。
        if defined?($TESTFLIGHT_EXPORT_OPTIONS)
          export_options = $TESTFLIGHT_EXPORT_OPTIONS
          export_xcargs = defined?($TESTFLIGHT_EXPORT_XCARGS) ? $TESTFLIGHT_EXPORT_XCARGS : nil
        else
          export_options = {
            method: "app-store",
            signingStyle: "automatic",
            uploadSymbols: true
          }

          # 如果有團隊 ID，加入 export options（自動簽名需要）
          export_options[:teamID] = team_id if team_id
          export_xcargs = "-allowProvisioningUpdates"
        end

        # Build
        if $WORKSPACE == ""
          build_app(
            scheme: scheme,
            output_name: "#{scheme}.ipa",
            export_options: export_options,
            export_xcargs: export_xcargs
          )
        else
          build_app(
            workspace: "#{$WORKSPACE}.xcworkspace",
            scheme: scheme,
            output_name: "#{scheme}.ipa",
            export_options: export_options,
            export_xcargs: export_xcargs
          )
        end

        UI.success("✓ #{scheme} 構建完成")
      end
    end

    # Upload to TestFlight
    UI.message("☁️  開始上傳到 TestFlight...")

    # 記錄上傳結果
    upload_success = []
    upload_failed = []

    scheme_infos.each do |scheme, bundle_id|
      UI.message("正在上傳: #{scheme}")

      begin
        if !options[:changelog]
          upload_to_testflight(
            app_identifier: bundle_id,
            skip_submission: true,
            skip_waiting_for_build_processing: true,
            ipa: "#{scheme}.ipa"
          )
        else
          upload_to_testflight(
            app_identifier: bundle_id,
            changelog: changelog,
            ipa: "#{scheme}.ipa"
          )
        end

        UI.success("✓ #{scheme} 上傳完成")
        upload_success << scheme
      rescue => ex
        UI.error("✗ #{scheme} 上傳失敗: #{ex.message}")
        upload_failed << scheme
        # 繼續處理下一個 scheme
      end
    end

    # 顯示最終結果
    UI.message("\n" + "=" * 50)
    if upload_success.any?
      UI.success("✓ 上傳成功 (#{upload_success.count}): #{upload_success.join(', ')}")
    end
    if upload_failed.any?
      UI.error("✗ 上傳失敗 (#{upload_failed.count}): #{upload_failed.join(', ')}")
      UI.important("請檢查失敗的 schemes 並重新上傳")
    end
    UI.message("=" * 50)

    if upload_failed.empty?
      UI.success("🎉 所有任務完成！")
    else
      UI.important("⚠️  部分任務完成，#{upload_failed.count} 個 scheme 上傳失敗")
    end
  end

end

platform :android do
  desc "Deploy a new version to Google Play with version bump"
  desc "Options:"
  desc "  nobump: 跳過 version bump"
  desc "  nobuild: 跳過 build（只上傳已有的 aab，自動跳過 version bump）"
  desc "  changelog: 是否包含 changelog"
  lane :UploadGoogle do |options|
    # 如果 nobuild，自動設置 nobump
    if options[:nobuild]
      options[:nobump] = true
      UI.message("⚠️  nobuild 模式：自動跳過 version bump")
    end

    UI.user_error!("❌ 請設定 $ANDROID_PACKAGE_NAME") if $ANDROID_PACKAGE_NAME.to_s.empty?
    UI.user_error!("❌ 請設定 $ANDROID_JSON_KEY_FILE") if $ANDROID_JSON_KEY_FILE.to_s.empty?

    git_tag_mode = android_git_tag_version_source?

    gradle_path = nil
    unless git_tag_mode
      gradle_path = android_gradle_path
      UI.user_error!("❌ 找不到 #{gradle_path}") unless File.exist?(gradle_path)
    end

    # Version Bump
    if !options[:nobump]
      if git_tag_mode
        bump_android_git_tag_version!
      else
        version_code = increment_android_version_code!(gradle_path)
        UI.success("✓ versionCode 已更新為 #{version_code}")

        git_commit(
          path: [gradle_path],
          message: "Version Bump: versionCode #{version_code}"
        )

        version_name = get_android_version_name(gradle_path)
        tag = "distribute/#{$tagPrefix}android-v#{version_name}/#{version_code}"

        add_git_tag(tag: tag)
        UI.success("✓ 已創建 tag: #{tag}")
      end
    end

    # 生成 changelog
    changelog = generateReleaseNote()

    # Build
    if !options[:nobuild]
      UI.message("🔨 開始構建 AAB...")
      bundle_task = $ANDROID_BUNDLE_TASK || "bundleRelease"
      sh("cd .. && ./gradlew --no-daemon :#{$ANDROID_GRADLE_MODULE}:#{bundle_task}")
      UI.success("✓ AAB 構建完成")
    end

    aab_path = File.expand_path("../#{android_aab_relative_path}")
    UI.user_error!("❌ 找不到 AAB 檔案: #{aab_path}") unless File.exist?(aab_path)

    UI.message("🔍 驗證 AAB 簽名...")
    verify_aab_signature(aab_path)
    UI.success("✓ AAB 簽名驗證通過")

    # Upload to Google Play
    UI.message("☁️  開始上傳到 Google Play (#{$ANDROID_TRACK})...")

    changelog_metadata_dir = nil

    begin
      upload_params = {
        package_name: $ANDROID_PACKAGE_NAME,
        aab: aab_path,
        json_key: $ANDROID_JSON_KEY_FILE,
        track: $ANDROID_TRACK,
        skip_upload_metadata: true,
        skip_upload_images: true,
        skip_upload_screenshots: true,
        skip_upload_changelogs: !options[:changelog]
      }

      if options[:changelog]
        version_code = current_android_version_code(gradle_path)
        changelog_metadata_dir = build_changelog_metadata_dir(version_code, changelog)
        upload_params[:metadata_path] = changelog_metadata_dir
      end

      upload_to_play_store(upload_params)

      UI.success("🎉 上傳完成！")
    rescue => ex
      UI.error("✗ 上傳失敗: #{ex.message}")
      UI.user_error!("Google Play 上傳失敗，請檢查後重新上傳（可用 nobuild:true 重試上傳既有的 aab）")
    ensure
      FileUtils.remove_entry(changelog_metadata_dir) if changelog_metadata_dir && Dir.exist?(changelog_metadata_dir)
    end
  end

end
