//
//  ViewController.swift
//  Sync Utility
//
//  Created by yuxiqian on 2018/8/29.
//  Copyright © 2018 yuxiqian. All rights reserved.
//

import Alamofire
import Cocoa
import Foundation
import Kanna

class jAccountViewController: NSViewController, loginHelperDelegate {
    func validateLoginResult(htmlData: String) {
        // reset
    }
    
    func forceResetAccount() {
        // reset
    }
    
//    var windowController: NSWindowController?

    var htmlDelegate: readInHTMLDelegate?
    var UIDelegate: UIManagerDelegate?

    override func viewWillAppear() {
        checkLoginStatus()
        updateCaptcha(refreshCaptchaButton)
    }

    override func viewDidLoad() {
//        super.viewDidLoad()
        loadingIcon.startAnimation(self)
//        openRequestPanel()
        setAccessibilityLabel()
    }

    func setAccessibilityLabel() {
        accessNewElectsys.setAccessibilityLabel("访问新版教学信息服务网")
        accessLegacyElectsys.setAccessibilityLabel("访问旧版教学信息服务网")
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

//    var requestDelegate: requestHtmlDelegate?
//    var inputDelegate: inputHtmlDelegate?

    @IBOutlet var accessNewElectsys: NSButton!
    @IBOutlet var accessLegacyElectsys: NSButton!
    @IBOutlet var userNameField: NSTextField!
    @IBOutlet var passwordField: NSSecureTextField!
    @IBOutlet var captchaTextField: NSTextField!
    @IBOutlet var captchaImage: NSImageView!
    @IBOutlet var loginButton: NSButton!
    @IBOutlet var refreshCaptchaButton: NSButton!
    @IBOutlet var resetButton: NSButton!
//    @IBOutlet weak var manualOpenButton: NSButton!
    @IBOutlet var loadingIcon: NSProgressIndicator!
//    @IBOutlet weak var expandButton: NSButton!
//    @IBOutlet weak var operationSelector: NSPopUpButton!
//    @IBOutlet weak var checkHistoryButton: NSButton!

    @IBAction func loginButtonClicked(_ sender: NSButton) {
        if userNameField.stringValue == "" ||
            passwordField.stringValue == "" ||
            captchaTextField.stringValue == "" {
            showErrorMessage(errorMsg: "请完整填写所有信息。")
            return
        }
        let accountParams = [self.userNameField.stringValue, self.passwordField.stringValue, self.captchaTextField.stringValue]
        disableUI()

//        if self.operationSelector.selectedItem!.title == "同步课程表到系统日历" {

        LoginHelper.attemptLogin(username: accountParams[0],
                                  password: accountParams[1],
                                  captcha: accountParams[2],
                                  handler: { success in
                                    if success {
                                        self.UIDelegate?.unlockIcon()
                                    } else {
                                        self.UIDelegate?.lockIcon()
                                        self.resumeUI()
                                    }
        })

//        } else if self.operationSelector.selectedItem!.title == "同步考试安排到系统日历" {
//            DispatchQueue.global().async {
//                self.loginSession?.attempt(userName: accountParams[0], password: accountParams[1], captchaWord: accountParams[2], isLegacy: false)
//            }
//        }
    }
    
    func checkLoginStatus() {
        LoginHelper.checkLoginAvailability({ status in
            if status {
                self.loadingIcon.isHidden = true
                let infoAlert: NSAlert = NSAlert()
                infoAlert.messageText = "提示"
                infoAlert.informativeText = "您已作为「\(LoginHelper.lastLoginUserName)」登录。"
                infoAlert.alertStyle = NSAlert.Style.informational
                infoAlert.addButton(withTitle: "嗯")
                infoAlert.addButton(withTitle: "切换账号")
                infoAlert.beginSheetModal(for: self.view.window!) { returnCode in
                    if returnCode == NSApplication.ModalResponse.alertSecondButtonReturn {
                        self.resetInput(self.resetButton)
                        self.resumeUI()
                        self.UIDelegate?.lockIcon()
                        LoginHelper.logOut()
                    }
                }
            } else {
                if LoginHelper.lastLoginUserName != "{null}" {
                    LoginHelper.lastLoginUserName = "{null}"
                    let infoAlert: NSAlert = NSAlert()
                    infoAlert.messageText = "提示"
                    infoAlert.informativeText = "用户「\(LoginHelper.lastLoginUserName)」的登录身份已过期，请重新登录。"
                    infoAlert.alertStyle = NSAlert.Style.informational
                    infoAlert.addButton(withTitle: "嗯")
                    infoAlert.beginSheetModal(for: self.view.window!)
                }
            }
        })
    }

    @IBAction func updateCaptcha(_ sender: NSButton) {
        captchaTextField.stringValue = ""

        LoginHelper.requestCaptcha({ image in
            self.captchaImage.image = image
        })
    }

    @IBAction func resetInput(_ sender: NSButton) {
        userNameField.stringValue = ""
        passwordField.stringValue = ""
        captchaTextField.stringValue = ""
        updateCaptcha(refreshCaptchaButton)
    }

    func setCaptchaImage(image: NSImage) {
        captchaImage.image = image
    }

    func disableUI() {
        userNameField.isEnabled = false
        passwordField.isEnabled = false
        captchaTextField.isEnabled = false
        loginButton.isEnabled = false
        resetButton.isEnabled = false
        refreshCaptchaButton.isEnabled = false
//        manualOpenButton.isEnabled = false
        captchaImage.isEnabled = false
//        operationSelector.isEnabled = false
//        checkHistoryButton.isEnabled = false
        loadingIcon.isHidden = false
    }

    func resumeUI() {
        userNameField.isEnabled = true
        passwordField.isEnabled = true
        captchaTextField.isEnabled = true
        loginButton.isEnabled = true
        resetButton.isEnabled = true
        refreshCaptchaButton.isEnabled = true
        captchaImage.isEnabled = true
//        operationSelector.isEnabled = true
//        checkHistoryButton.isEnabled = true
        loadingIcon.isHidden = true
        updateCaptcha(refreshCaptchaButton)
//        if operationSelector.selectedItem!.title == "同步课程表到系统日历" {
//            manualOpenButton.isEnabled = true
//        }
    }

    func showErrorMessage(errorMsg: String) {
        let errorAlert: NSAlert = NSAlert()
        errorAlert.messageText = "出错啦"
        errorAlert.informativeText = errorMsg
        errorAlert.addButton(withTitle: "嗯")
        errorAlert.alertStyle = NSAlert.Style.critical
        errorAlert.beginSheetModal(for: view.window!, completionHandler: nil)
    }

    func failedToLoadCaptcha() {
        showErrorMessage(errorMsg: "获取验证码时发生错误。\n请检查您的网络连接。")
    }

//    @IBAction func onExpand(_ sender: NSButton) {
//        var frame: NSRect = (self.view.window?.frame)!
//        if sender.state == .on {
//            frame.size = NSSize(width: 260, height: 318)
//        } else {
//            frame.size = NSSize(width: 260, height: 230)
//        }
//        self.view.window?.setFrame(frame, display: true, animate: true)
//    }

//
//    @IBAction func operationSelectorPopped(_ sender: NSPopUpButton) {
//        if sender.selectedItem!.title == "同步课程表到系统日历" {
//            self.manualOpenButton.isEnabled = true
//        } else {
//            self.manualOpenButton.isEnabled = false
//        }
//    }

//    @IBAction func checkHistoryData(_ sender: NSButton) {
//        // do something crazy
//        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
//        windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("FullDataWindowController")) as? FullDataWindowController
//        windowController?.showWindow(self)
//    }

    @IBAction func goToElectsysNew(_ sender: NSButton) {
        if let url = URL(string: "http://i.sjtu.edu.cn/"), NSWorkspace.shared.open(url) {
            // successfully opened
        }
    }

    @IBAction func goToElectsysLegacy(_ sender: NSButton) {
        if let url = URL(string: "http://electsys.sjtu.edu.cn"), NSWorkspace.shared.open(url) {
            // successfully opened
        }
    }

}
