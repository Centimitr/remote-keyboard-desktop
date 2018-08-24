//
//  ViewController.swift
//  Remote Keyboard Desktop
//
//  Created by Xiao Shi on 2/2/18.
//  Copyright © 2018 devbycm. All rights reserved.
//

import Cocoa
import MultipeerConnectivity

class ViewController: NSViewController {
    
    let service = KeyboardService()
    @IBOutlet weak var tokenField: NSTokenField!
    @IBOutlet var textView: NSTextView!
    
    override func viewDidLoad() {
        service.delegate = self
        view.layer?.backgroundColor = CGColor.white
        textView.textContainerInset = CGSize(width: 16, height: 16)
        textView.delegate = self
//        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: {
//
//        })
        super.viewDidLoad()
    }
    
    override func viewDidDisappear() {
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func delete(_ sender: NSButton) {
        service.delete()
    }
    
    @IBAction func input(_ sender: NSButton) {
//        let text = self.text.stringValue
//        if service.input(text) {
//            self.text.stringValue = ""
//            service.update("")
//        }
    }
    
    func send() {
        let text: String = (self.textView.textStorage?.string)!
        print("send!", text)
        if service.input(text) {
            self.textView.textStorage?.mutableString.setString("")
            service.update("")
        }
    }
    
}

extension ViewController: KeyboardServiceDelegate {
    
    func peer(_ peer: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            var v: Array<String> = []
            if let value = self.tokenField.objectValue {
                v = value as! Array<String>
            }
            let name = peer.displayName
            switch state {
            case .connected:
                if !v.contains(name) {
                    v.append(name)
                    self.tokenField.objectValue = v
                }
            case .notConnected:
                print("XXX, notConnected", peer.displayName)
                print(self.tokenField.objectValue)
                self.tokenField.objectValue = v.filter {$0 != name}
                print(self.tokenField.objectValue)
            default: break
            }
        }
    }
}

extension ViewController: NSTextViewDelegate {
    func textDidChange(_ notification: Notification) {
        let text: String = (self.textView.textStorage?.string)!
        service.update(text)
    }
    
    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
//        let event = NSApp.currentEvent
        var handled = false
        let needCmdKey = false
        if needCmdKey {
            let isCmdEnter = true
            if isCmdEnter {
                self.send()
                handled = true
            }
        } else if commandSelector.description == "insertNewline:" {
            self.send()
            handled = true
        }
        return handled
    }
}
