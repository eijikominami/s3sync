//
//  AppDelegate.swift
//  S3Sync
//
//  Created by Eiji KOMINAMI on 2016/05/11.
//  Copyright © 2016年 Eiji KOMINAMI. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {

    @IBOutlet weak var menu: NSMenu!
    
    // MARK: applicationDidFinishLaunching()の中で定義すると動作しない
    let statusBarItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    
    let task: NSTask = NSTask()
    var isSuspended = false

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        // ステータスバー
        statusBarItem.menu = menu
        statusBarItem.image = NSImage(named: "StatusBarIcon")
        
        // スリープ検知
        // MARK: Swift2.2からSelectorの記法が変わった
        NSWorkspace.sharedWorkspace().notificationCenter.addObserver(self, selector: #selector(self.receiveSleepNotification(_:)), name: NSWorkspaceWillSleepNotification, object: nil)
    }
    
    // MARK: アプリ終了時に呼び出される
    func applicationShouldTerminate(sender: NSApplication) -> NSApplicationTerminateReply {
        suspendTask()
        return NSApplicationTerminateReply.TerminateNow
    }

    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    /**
        スリープ通知を受信する
     
        - parameter     notification:    通知
        - returns:   購読していれば true を返す
     */
    func receiveSleepNotification(notification: NSNotification){
        if !task.running {
            sync()
        }
    }
    
    /**
        同期する
     */
    func sync(){
        let defaults = NSUserDefaults.standardUserDefaults()
        if let sync = defaults.objectForKey("sync") {
            if sync as! String=="1" {
                exec(defaults.objectForKey("command") as! String, logfileDir: defaults.objectForKey("logfile") as! String?)
            }
        }else{
            exec(defaults.objectForKey("command") as! String, logfileDir: defaults.objectForKey("logfile") as! String?)
        }
    }
    
    /**
        外部コマンドを実行する
     
        - parameter     command:        実行コマンド
        - parameter     logfileDir:     ログ保存ディレクトリ
     */
    func exec(command: String, logfileDir: String?){
        if !task.running {
            if isSuspended {
                // MARK: タスクの再開
                task.resume()
            }else{
                var commands = command.componentsSeparatedByString(" ")
                task.launchPath = commands[0]
                commands.removeAtIndex(0)
                task.arguments = commands
                let pipe: NSPipe = NSPipe()
                task.standardOutput = pipe
                let stdoutHundle = pipe.fileHandleForReading
                
                self.deliverNotification("S3Sync: Start:", command: command, output: nil)
                
                // MARK: 非同期処理
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), {
                    // MARK: データをセット
                    var dataRead = stdoutHundle.availableData
                    while(dataRead.length > 0){
                        let stringRead = NSString(data: dataRead, encoding: NSUTF8StringEncoding)
                        if let output = stringRead {
                            let outputs = output.componentsSeparatedByString(" ")
                            self.deliverNotification("S3Sync: " + outputs[0], command: command, output: output as String)
                            if let str = logfileDir {
                                let absolutePath = str + "/s3sync.log"
                                // MARK: ファイル追記
                                if(NSFileManager.defaultManager().fileExistsAtPath(absolutePath)){
                                    if let fileHandle = NSFileHandle(forWritingAtPath: absolutePath) {
                                        fileHandle.seekToEndOfFile()
                                        fileHandle.writeData(output.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!)
                                        fileHandle.closeFile()
                                    }
                                // MARK: ファイル新規書き込み
                                }else{
                                    do {
                                        try output.writeToFile(absolutePath, atomically: true, encoding: NSUTF8StringEncoding)
                                    } catch {
                                        
                                    }
                                }
                            }
                        }
                        dataRead = stdoutHundle.availableData
                    }
                    self.deliverNotification("S3Sync: finish:", command: command, output: nil)
                })
                // MARK: タスクの開始
                task.launch()
            }
        }
    }
    
    /**
        通知を送信する
     
        - parameter     title:      タイトル
        - parameter     command:    実行コマンド
        - parameter     output:     出力テキスト
     */
    func deliverNotification(title : String, command : String?, output: String?){
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
        let notification = NSUserNotification()
        notification.title = title
        if command != nil {
            notification.subtitle = "Command: " + command! as String
        }
        notification.informativeText = output
        //notification.contentImage =  NSImage(named: "MainIcon")
        //notification.userInfo = ["title" : "タイトル"]
        NSUserNotificationCenter.defaultUserNotificationCenter().deliverNotification(notification)
    }
    
    /**
        通知を受信する
     
        - parameter     center:         通知センター
        - parameter     notification:   通知
     */
    func userNotificationCenter(center: NSUserNotificationCenter, didDeliverNotification notification: NSUserNotification) {

    }
    
    /**
        タスクを停止する
     */
    func suspendTask(){
        // MARK: 
        if task.running {
            if task.suspend() {
                isSuspended = true
                self.deliverNotification("S3Sync: terminate:", command: nil, output: nil)
            }
        }
    }

    /**
        同期ボタンを押下する
     
        - parameter     sender:         センダー
     */
    @IBAction func sync(sender: AnyObject) {
        sync()
    }

    /**
        停止ボタンを押下する
     
        - parameter     sender:         センダー
     */
    @IBAction func stop(sender: AnyObject) {
        suspendTask()
    }
}

