# Fastfile 2.0 - Simplified Configuration
# Documentation: https://github.com/fastlane/fastlane/tree/master/docs
# All available actions: https://github.com/fastlane/fastlane/blob/master/docs/Actions.md

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

        # 準備 export options（使用 Xcode 自動配置）
        export_options = {
          method: "app-store"
        }

        # 如果有團隊 ID，加入 export options（自動簽名需要）
        if team_id
          export_options[:teamID] = team_id
        end

        # Build
        if $WORKSPACE == ""
          build_app(
            scheme: scheme,
            output_name: "#{scheme}.ipa",
            export_options: export_options,
            export_xcargs: "-allowProvisioningUpdates"
          )
        else
          build_app(
            workspace: "#{$WORKSPACE}.xcworkspace",
            scheme: scheme,
            output_name: "#{scheme}.ipa",
            export_options: export_options,
            export_xcargs: "-allowProvisioningUpdates"
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
