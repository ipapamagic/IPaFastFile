# Fastfile 2.0 - Simplified Configuration
# Documentation: https://github.com/fastlane/fastlane/tree/master/docs
# All available actions: https://github.com/fastlane/fastlane/blob/master/docs/Actions.md

default_platform :ios

# ============================================
# 2.0 Simplified Configuration (只需要配置這些)
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

# Optional: 如果需要手動指定 provisioning profiles (舊版兼容)
# 格式: { "com.example.app" => "ProfileName", "com.example.app.widget" => "WidgetProfileName" }
$PROVISIONING_PROFILES = {}

# App Store Connect API Key (必填 - 用於上傳到 TestFlight)
$APP_STORE_CONNECT_API_KEY_KEY_ID = ""
$APP_STORE_CONNECT_API_KEY_ISSUER_ID = ""
$APP_STORE_CONNECT_API_KEY_KEYFILE = ""

# ============================================
# 向後兼容：舊版配置仍然支持
# ============================================
$SCHEME_INFOS = []  # 舊版格式: [["SchemeName", "bundle.id"], ...]


# ============================================
# Helper Functions
# ============================================

# 從 Xcode 專案自動提取 scheme 的 bundle ID
def get_bundle_id_for_scheme(scheme)
  begin
    # 嘗試從 build settings 中獲取 bundle ID
    if $WORKSPACE != ""
      # 使用 workspace
      result = sh("xcodebuild -workspace ../#{$WORKSPACE}.xcworkspace -scheme '#{scheme}' -showBuildSettings | grep 'PRODUCT_BUNDLE_IDENTIFIER' | head -n 1 | awk '{print $3}'").strip
    else
      # 查找 .xcodeproj 文件
      xcodeproj = Dir.glob("../*.xcodeproj").first
      if xcodeproj
        project_name = File.basename(xcodeproj)
        result = sh("xcodebuild -project ../#{project_name} -scheme '#{scheme}' -showBuildSettings | grep 'PRODUCT_BUNDLE_IDENTIFIER' | head -n 1 | awk '{print $3}'").strip
      else
        UI.error("找不到 .xcodeproj 文件")
        return nil
      end
    end

    if result && !result.empty?
      UI.message("✓ Scheme '#{scheme}' 的 Bundle ID: #{result}")
      return result
    else
      UI.error("無法獲取 scheme '#{scheme}' 的 Bundle ID")
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

  # 檢查是否使用舊版配置
  if defined?($SCHEME_INFOS) && !$SCHEME_INFOS.empty?
    UI.important("⚠️  使用舊版配置 $SCHEME_INFOS（建議遷移到 2.0 配置）")
    return $SCHEME_INFOS
  end

  # 使用新版配置：自動提取 bundle ID
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

  UI.error("❌ 請配置 $SCHEMES 或 $SCHEME_INFOS")
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
      UI.user_error!("❌ 沒有可用的 scheme 配置，請檢查 $SCHEMES 或 $SCHEME_INFOS")
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

      scheme_infos.each do |scheme, bundle_id|
        UI.message("正在構建: #{scheme}")

        # 準備 export options
        export_options = {
          method: "app-store"
        }

        # 如果用戶指定了 provisioning profiles，使用它們
        if defined?($PROVISIONING_PROFILES) && !$PROVISIONING_PROFILES.empty?
          export_options[:provisioningProfiles] = $PROVISIONING_PROFILES
          UI.message("使用手動指定的 Provisioning Profiles")
        else
          # 否則讓 Xcode 自動處理
          UI.message("使用 Xcode 自動配置的 Provisioning Profiles")
        end

        # Build
        if $WORKSPACE == ""
          build_app(
            scheme: scheme,
            output_name: "#{scheme}.ipa",
            export_options: export_options
          )
        else
          build_app(
            workspace: "#{$WORKSPACE}.xcworkspace",
            scheme: scheme,
            output_name: "#{scheme}.ipa",
            export_options: export_options
          )
        end

        UI.success("✓ #{scheme} 構建完成")
      end
    end

    # Upload to TestFlight
    UI.message("☁️  開始上傳到 TestFlight...")

    scheme_infos.each do |scheme, bundle_id|
      UI.message("正在上傳: #{scheme}")

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
    end

    UI.success("🎉 所有任務完成！")
  end

end
