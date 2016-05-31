//
//  PreferencesViewController.swift
//  S3Sync
//
//  Created by Eiji KOMINAMI on 2016/05/11.
//  Copyright © 2016年 Eiji KOMINAMI. All rights reserved.
//

import Cocoa

/** 設定画面 */
class PreferencesViewController: NSViewController {
    
    /** コマンド入力画面 */
    @IBOutlet weak var textField: NSTextField!
    /** スリープ時実行設定 */
    @IBOutlet weak var segmentedControl: NSSegmentedControl!
    /** ログファイル保存先 */
    @IBOutlet weak var logDirectoryLabel: NSTextField!
    
    override func viewDidLoad() {
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let command = defaults.objectForKey("command") {
            textField.stringValue = command as! String
        }else{
            // デフォルトコマンド
            textField.stringValue = "/usr/local/bin/aws s3 sync SOURCE_DIR s3://DIST_DIR --delete --exclude *.DS_Store"
        }
        if let sync = defaults.objectForKey("sync") {
            segmentedControl.selectedSegment = (Int)(sync as! String)!
        }
        if let logfile = defaults.objectForKey("logfile") {
            logDirectoryLabel.stringValue = logfile as! String
        }
    }
    
    override func viewDidDisappear() {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setObject(textField.stringValue, forKey: "command")
        defaults.setObject(segmentedControl.selectedSegment.description, forKey: "sync")
        defaults.setObject(logDirectoryLabel.stringValue, forKey: "logfile")
    }
    
    @IBAction func selectLogFileDirectory(sender: AnyObject) {
        // MARK: ディレクトリ選択画面
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.beginWithCompletionHandler({(num) -> Void in
            if num == NSModalResponseOK {
                // MARK: absoluteStringだとSchemaも文字列に含まれる
                self.logDirectoryLabel.stringValue = (panel.directoryURL?.path)!
            }
        })
    }
}