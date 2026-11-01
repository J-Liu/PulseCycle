// SPDX-License-Identifier: AGPL-3.0-or-later
// Copyright © 2026 Jia Liu

import Foundation

extension Notification.Name {
    static let languageChanged = Notification.Name("languageChanged")
}

/// Supported languages for the app
enum AppLanguage: String, CaseIterable {
    case system = "system"
    case english = "en"
    case simplifiedChinese = "zh-Hans"
    case traditionalChinese = "zh-Hant"

    var displayName: String {
        switch self {
        case .system:
            return localizedStrings[.english]?["settings.language.system"] ?? "System Default"
        case .english:
            return localizedStrings[.english]?["settings.language.english"] ?? "English"
        case .simplifiedChinese:
            return localizedStrings[.simplifiedChinese]?["settings.language.simplifiedChinese"] ?? "简体中文"
        case .traditionalChinese:
            return localizedStrings[.traditionalChinese]?["settings.language.traditionalChinese"] ?? "繁體中文"
        }
    }
}

/// Manages app localization settings
final class LocalizationManager {
    static let shared = LocalizationManager()

    private let languageKey = "appLanguage"

    var currentLanguage: AppLanguage {
        get {
            if let rawValue = UserDefaults.standard.string(forKey: languageKey),
               let language = AppLanguage(rawValue: rawValue) {
                return language
            }
            return .system
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: languageKey)
            NotificationCenter.default.post(name: .languageChanged, object: nil)
        }
    }

    private init() {}

    func localizedString(_ key: String) -> String {
        let language = currentLanguage == .system ? systemLanguage() : currentLanguage
        return localizedStrings[language]?[key] ?? key
    }

    private func systemLanguage() -> AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? "en"
        if preferred.hasPrefix("zh-Hans") || preferred.hasPrefix("zh-CN") {
            return .simplifiedChinese
        } else if preferred.hasPrefix("zh-Hant") || preferred.hasPrefix("zh-TW") || preferred.hasPrefix("zh-HK") {
            return .traditionalChinese
        }
        return .english
    }
}

/// Global helper for localized strings
func L(_ key: String) -> String {
    return LocalizationManager.shared.localizedString(key)
}

// MARK: - Localized Strings Dictionary

private let localizedStrings: [AppLanguage: [String: String]] = [
    .english: [
        // Settings
        "settings.title": "Settings",
        "settings.tab.general": "General",
        "settings.tab.about": "About",
        "settings.language": "Language:",
        "settings.language.system": "System Default",
        "settings.language.english": "English",
        "settings.language.simplifiedChinese": "Simplified Chinese",
        "settings.language.traditionalChinese": "Traditional Chinese",
        "settings.quitOnClose": "Close Window:",
        "settings.quitOnClose.checkbox": "Quit when closing window",
        "settings.updateCheck": "Auto Update Check:",
        "settings.updateCheck.now": "Check Now",
        "settings.updateCheck.never": "Never",
        "settings.updateCheck.atStartup": "At Startup",
        "settings.updateCheck.daily": "Daily",
        "settings.updateCheck.weekly": "Weekly",
        "settings.updateCheck.monthly": "Monthly",
        "settings.about.version": "Version",
        "settings.about.copyright": "Copyright © 2026 Jia Liu",
        "settings.button.add": "Add",
        "settings.button.remove": "Remove",

        // Main Window
        "main.timer.ready": "READY",
        "main.timer.work": "WORK",
        "main.timer.rest": "REST",
        "main.round": "Round %d",
        "main.button.start": "Start",
        "main.button.pause": "Pause",
        "main.button.reset": "Reset",
        "main.profile.select": "Select Profile",
        "main.heartRate": "Heart Rate: %d BPM",
        "main.heartRate.connecting": "Heart Rate: Connecting...",
        "main.heartRate.disconnected": "Heart Rate: Disconnected",

        // Menu
        "menu.about": "About %@",
        "menu.checkForUpdates": "Check for Updates...",
        "menu.quit": "Quit %@",
        "menu.hide": "Hide %@",
        "menu.hideOthers": "Hide Others",
        "menu.showAll": "Show All",
        "menu.file": "File",
        "menu.closeWindow": "Close Window",
        "menu.view": "View",
        "menu.enterFullScreen": "Enter Full Screen",
        "menu.window": "Window",
        "menu.minimize": "Minimize",
        "menu.zoom": "Zoom",
        "menu.bringAllToFront": "Bring All to Front",
        "menu.settings": "Settings...",
    ],

    .simplifiedChinese: [
        // Settings
        "settings.title": "设置",
        "settings.tab.general": "通用",
        "settings.tab.about": "关于",
        "settings.language": "语言：",
        "settings.language.system": "系统默认",
        "settings.language.english": "English",
        "settings.language.simplifiedChinese": "简体中文",
        "settings.language.traditionalChinese": "繁體中文",
        "settings.quitOnClose": "关闭窗口：",
        "settings.quitOnClose.checkbox": "关闭窗口时退出应用",
        "settings.updateCheck": "自动检查更新：",
        "settings.updateCheck.now": "立即检查",
        "settings.updateCheck.never": "从不",
        "settings.updateCheck.atStartup": "每次启动",
        "settings.updateCheck.daily": "每天",
        "settings.updateCheck.weekly": "每周",
        "settings.updateCheck.monthly": "每月",
        "settings.about.version": "版本",
        "settings.about.copyright": "版权所有 © 2026 Jia Liu",
        "settings.button.add": "添加",
        "settings.button.remove": "移除",

        // Main Window
        "main.timer.ready": "准备",
        "main.timer.work": "训练",
        "main.timer.rest": "休息",
        "main.round": "第 %d 轮",
        "main.button.start": "开始",
        "main.button.pause": "暂停",
        "main.button.reset": "重置",
        "main.profile.select": "选择配置",
        "main.heartRate": "心率：%d BPM",
        "main.heartRate.connecting": "心率：连接中...",
        "main.heartRate.disconnected": "心率：未连接",

        // Menu
        "menu.about": "关于 %@",
        "menu.checkForUpdates": "检查更新...",
        "menu.quit": "退出 %@",
        "menu.hide": "隐藏 %@",
        "menu.hideOthers": "隐藏其他",
        "menu.showAll": "全部显示",
        "menu.file": "文件",
        "menu.closeWindow": "关闭窗口",
        "menu.view": "显示",
        "menu.enterFullScreen": "进入全屏幕",
        "menu.window": "窗口",
        "menu.minimize": "最小化",
        "menu.zoom": "缩放",
        "menu.bringAllToFront": "全部移到最前",
        "menu.settings": "设置...",
    ],

    .traditionalChinese: [
        // Settings
        "settings.title": "設定",
        "settings.tab.general": "一般",
        "settings.tab.about": "關於",
        "settings.language": "語言：",
        "settings.language.system": "系統預設",
        "settings.language.english": "English",
        "settings.language.simplifiedChinese": "简体中文",
        "settings.language.traditionalChinese": "繁體中文",
        "settings.quitOnClose": "關閉視窗：",
        "settings.quitOnClose.checkbox": "關閉視窗時退出應用程式",
        "settings.updateCheck": "自動檢查更新：",
        "settings.updateCheck.now": "立即檢查",
        "settings.updateCheck.never": "從不",
        "settings.updateCheck.atStartup": "每次啟動",
        "settings.updateCheck.daily": "每天",
        "settings.updateCheck.weekly": "每週",
        "settings.updateCheck.monthly": "每月",
        "settings.about.version": "版本",
        "settings.about.copyright": "版權所有 © 2026 Jia Liu",
        "settings.button.add": "新增",
        "settings.button.remove": "移除",

        // Main Window
        "main.timer.ready": "準備",
        "main.timer.work": "訓練",
        "main.timer.rest": "休息",
        "main.round": "第 %d 輪",
        "main.button.start": "開始",
        "main.button.pause": "暫停",
        "main.button.reset": "重設",
        "main.profile.select": "選擇設定檔",
        "main.heartRate": "心率：%d BPM",
        "main.heartRate.connecting": "心率：連線中...",
        "main.heartRate.disconnected": "心率：未連線",

        // Menu
        "menu.about": "關於 %@",
        "menu.checkForUpdates": "檢查更新...",
        "menu.quit": "結束 %@",
        "menu.hide": "隱藏 %@",
        "menu.hideOthers": "隱藏其他",
        "menu.showAll": "全部顯示",
        "menu.file": "檔案",
        "menu.closeWindow": "關閉視窗",
        "menu.view": "顯示",
        "menu.enterFullScreen": "進入全螢幕",
        "menu.window": "視窗",
        "menu.minimize": "最小化",
        "menu.zoom": "縮放",
        "menu.bringAllToFront": "全部移到最前",
        "menu.settings": "設定...",
    ]
]
