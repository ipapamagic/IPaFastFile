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
# 範例 4: 需要手動指定 Provisioning Profile
# ============================================
# $SCHEMES = ["MyApp", "MyAppWidget"]
# $WORKSPACE = "MyApp"
#
# # 手動指定 provisioning profiles（覆蓋自動配置）
# $PROVISIONING_PROFILES = {
#   "com.example.myapp" => "MyApp AppStore Profile",
#   "com.example.myapp.widget" => "Widget AppStore Profile"
# }
#
# $APP_STORE_CONNECT_API_KEY_KEY_ID = "ABC123XYZ"
# $APP_STORE_CONNECT_API_KEY_ISSUER_ID = "12345678-abcd-1234-abcd-123456789012"
# $APP_STORE_CONNECT_API_KEY_KEYFILE = "./AuthKey_ABC123XYZ.p8"


# ============================================
# 範例 5: 完整配置（所有選項）
# ============================================
# $SCHEMES = ["MyApp", "MyAppWidget"]
# $WORKSPACE = "MyApp"
# $tagPrefix = "MyApp-"  # Git tag 前綴，例如: distribute/MyApp-v1.0/123
# $MAIN_PROJECT = "MyApp.xcodeproj"  # 主專案名稱（用於 version bump commit）
#
# # Optional: 手動指定 provisioning profiles
# $PROVISIONING_PROFILES = {
#   "com.example.myapp" => "MyApp AppStore Profile",
#   "com.example.myapp.widget" => "Widget AppStore Profile"
# }
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
# 使用方法
# ============================================
# 完整流程（version bump + build + upload）:
#   fastlane UploadTestFlight
#
# 跳過 version bump:
#   fastlane UploadTestFlight nobump:true
#
# 只上傳已有的 ipa（自動跳過 version bump 和 build）:
#   fastlane UploadTestFlight nobuild:true
#
# 包含 changelog:
#   fastlane UploadTestFlight changelog:true
