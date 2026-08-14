# Fastfile 2.0 配置示例
# 將此文件的內容複製到你的專案的 fastlane/Fastfile 頂部

# ============================================
# 重要說明
# ============================================
# $SCHEMES 只需要填入主 app 的 schemes
# Extensions (Widget, Share Extension, Today Extension 等) 不需要加入
# 因為它們會自動跟隨主 app 一起打包到 .ipa 中

# ============================================
# 範例 1: 單一 App（最簡配置）
# ============================================
# $SCHEMES = ["MyApp"]
#
# $APP_STORE_CONNECT_API_KEY_KEY_ID = "ABC123XYZ"
# $APP_STORE_CONNECT_API_KEY_ISSUER_ID = "12345678-abcd-1234-abcd-123456789012"
# $APP_STORE_CONNECT_API_KEY_KEYFILE = "./AuthKey_ABC123XYZ.p8"


# ============================================
# 範例 2: 使用 CocoaPods 的專案
# ============================================
# $SCHEMES = ["MyApp"]
# $WORKSPACE = "MyApp"  # workspace 名稱（不含 .xcworkspace）
#
# $APP_STORE_CONNECT_API_KEY_KEY_ID = "ABC123XYZ"
# $APP_STORE_CONNECT_API_KEY_ISSUER_ID = "12345678-abcd-1234-abcd-123456789012"
# $APP_STORE_CONNECT_API_KEY_KEYFILE = "./AuthKey_ABC123XYZ.p8"


# ============================================
# 範例 3: 多環境配置（Dev + Production）
# ============================================
# 同一份程式碼，但有不同環境的 schemes
# $SCHEMES = ["MyApp-Dev", "MyApp-Prod"]
# $WORKSPACE = "MyApp"
#
# # 注意：即使有 Widget 或 Extension，也不需要加入
# # 例如 MyAppWidget-Dev 和 MyAppWidget-Prod 會自動跟隨主 app 打包
#
# $APP_STORE_CONNECT_API_KEY_KEY_ID = "ABC123XYZ"
# $APP_STORE_CONNECT_API_KEY_ISSUER_ID = "12345678-abcd-1234-abcd-123456789012"
# $APP_STORE_CONNECT_API_KEY_KEYFILE = "./AuthKey_ABC123XYZ.p8"


# ============================================
# 範例 4: 完整配置（所有選項）
# ============================================
# $SCHEMES = ["MyApp-Dev", "MyApp-Prod"]
# $WORKSPACE = "MyApp"
# $tagPrefix = "MyApp-"  # Git tag 前綴，例如: distribute/MyApp-v1.0/123
# $MAIN_PROJECT = "MyApp.xcodeproj"  # 主專案名稱（用於 version bump commit）
#
# $APP_STORE_CONNECT_API_KEY_KEY_ID = "ABC123XYZ"
# $APP_STORE_CONNECT_API_KEY_ISSUER_ID = "12345678-abcd-1234-abcd-123456789012"
# $APP_STORE_CONNECT_API_KEY_KEYFILE = "./AuthKey_ABC123XYZ.p8"


# ============================================
# 如何獲取 App Store Connect API Key
# ============================================
# 1. 登入 https://appstoreconnect.apple.com
# 2. 前往「用戶和訪問」>「密鑰」>「App Store Connect API」
# 3. 點擊「+」創建新密鑰
# 4. 選擇「Developer」角色
# 5. 下載 .p8 文件（只能下載一次，請妥善保存）
# 6. 記錄：
#    - Key ID（顯示在列表中）
#    - Issuer ID（頁面上方）
#    - Key File（下載的 .p8 文件路徑）


# ============================================
# 使用方法（iOS）
# ============================================
# 完整流程（version bump + build + upload）:
#   fastlane ios UploadTestFlight
#
# 跳過 version bump:
#   fastlane ios UploadTestFlight nobump:true
#
# 只上傳已有的 ipa（自動跳過 version bump 和 build）:
#   fastlane ios UploadTestFlight nobuild:true
#
# 包含 changelog:
#   fastlane ios UploadTestFlight changelog:true


# ============================================
# Android（Google Play）配置
# ============================================
# 專案的 fastlane/Fastfile 只需要放這些設定，lane 邏輯一樣集中在 IPaFastFile。
# 專案結構需符合標準 Android Studio 專案（fastlane/ 與 app/、gradlew 同層）。

# ============================================
# 範例 1: 最簡配置
# ============================================
# $ANDROID_PACKAGE_NAME = "com.example.myapp"
# $ANDROID_JSON_KEY_FILE = "~/Documents/Google/MyApp/play-store-key.json"


# ============================================
# 範例 2: 完整配置（所有選項）
# ============================================
# $ANDROID_PACKAGE_NAME = "com.example.myapp"
# $ANDROID_JSON_KEY_FILE = ENV["ANDROID_JSON_KEY_PATH"] || "~/Documents/Google/MyApp/play-store-key.json"
# $ANDROID_BUILD_GRADLE = "app/build.gradle"     # 相對於專案根目錄，用於讀取/更新 versionCode、versionName
# $ANDROID_GRADLE_MODULE = "app"                 # gradle module 名稱，決定 build task 與預設 AAB 路徑
# $ANDROID_AAB_PATH = nil                        # 留空則用預設路徑 "app/build/outputs/bundle/release/app-release.aab"
# $ANDROID_TRACK = "internal"                    # Google Play track: internal / alpha / beta / production
# $ANDROID_RELEASE_NOTES_LANG = "en-US"          # changelog 語系
# $tagPrefix = "MyApp-"                          # 與 iOS 共用，可用來區分 tag，例如 distribute/MyApp-android-v1.0/5


# ============================================
# 範例 3: versionCode 由 git tag 推算的專案
# ============================================
# 適合 build.gradle(.kts) 用 `git describe` 從最新的 distribute tag 推算 versionCode
# 的專案（例如用 `distribute/v<versionName>/<versionCode>` 格式的 tag）。
# 這種模式下 UploadGoogle 不會編輯 build.gradle，只會建立下一個 tag，
# 讓 gradle build 時自己從最新 tag 讀到新的 versionCode。
#
# $ANDROID_PACKAGE_NAME = "com.example.myapp"
# $ANDROID_JSON_KEY_FILE = "~/Documents/Google/MyApp/play-store-key.json"
# $ANDROID_VERSION_SOURCE = "git_tag"
# $ANDROID_VERSION_NAME = "2.9.0"                # 目前的 versionName，用來組出下一個 tag
# $ANDROID_GIT_TAG_PREFIX = "distribute/v"        # 預設值，通常不用改
# $ANDROID_BUNDLE_TASK = "bundleProdRelease"      # 有 flavor 時可指定，預設 "bundleRelease"
# $ANDROID_AAB_PATH = "app/build/outputs/bundle/prodRelease/app-prod-release.aab"


# ============================================
# 如何取得 Google Play Service Account JSON Key
# ============================================
# 1. 登入 https://play.google.com/console
# 2. 「使用者和權限」>「服務帳戶」>「在 Google Cloud Console 建立新的服務帳戶」
# 3. 在 Google Cloud Console 建立服務帳戶並下載 JSON 金鑰
# 4. 回到 Play Console 把該服務帳戶加入為使用者，並授予「發布應用程式」等必要權限
# 5. 把下載的 JSON 檔放在專案外（例如 ~/Documents/Google/…），絕對不要 commit 進 repo
# 6. $ANDROID_JSON_KEY_FILE 指向該檔案路徑（可用環境變數間接指定，避免明碼寫死路徑）


# ============================================
# 使用方法（Android）
# ============================================
# 完整流程（version bump + build + upload）:
#   fastlane android UploadGoogle
#
# 跳過 version bump:
#   fastlane android UploadGoogle nobump:true
#
# 只上傳已有的 aab（自動跳過 version bump 和 build）:
#   fastlane android UploadGoogle nobuild:true
#
# 包含 changelog:
#   fastlane android UploadGoogle changelog:true
#
# 流程細節：
# 1. nobuild:true 會自動一併設 nobump。
# 2. 非 nobump 時，依 $ANDROID_VERSION_SOURCE 分兩種模式：
#    - "gradle"（預設）：遞增 app/build.gradle 的 versionCode → git commit → 建立 tag
#      distribute/#{$tagPrefix}android-v#{versionName}/#{versionCode}
#    - "git_tag"：不編輯 build.gradle，直接建立下一個 tag
#      #{$ANDROID_GIT_TAG_PREFIX}#{$ANDROID_VERSION_NAME}/#{versionCode}（versionCode 為目前最大值 +1）。
#      build.gradle 需自行用 `git describe` 從最新 tag 推算 versionCode，
#      這樣 build 時就會讀到剛建立的新 tag。
# 3. build 使用 `./gradlew --no-daemon :#{$ANDROID_GRADLE_MODULE}:#{$ANDROID_BUNDLE_TASK || "bundleRelease"}` 產生 AAB。
# 4. 上傳前用 jarsigner 驗證 AAB 簽名，未簽名或驗證失敗會直接中止。
# 5. 上傳採用 fastlane upload_to_play_store（supply），預設 skip metadata/images/
#    screenshots/changelogs；帶 changelog:true 時才會建立暫存的 metadata 目錄
#    （<lang>/changelogs/<versionCode>.txt）並透過 metadata_path 只上傳 changelog 文字，
#    不需要 repo 裡有完整的 metadata。
