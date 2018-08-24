//
//  KeyboardService.swift
//  Remote Keyboard
//
//  Created by Xiao Shi on 2/2/18.
//  Copyright © 2018 devbycm. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol KeyboardServiceDelegate {
    func peer(_ peer: MCPeerID, didChange state: MCSessionState)
}

class KeyboardService: NSObject {
    private let serviceType = "rkb"
    private let myPeerId = MCPeerID(displayName: Host.current().name!)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let session: MCSession
    var delegate: KeyboardServiceDelegate?

    override init() {
        self.serviceAdvertiser = MCNearbyServiceAdvertiser(
            peer: myPeerId,
            discoveryInfo: nil,
            serviceType: serviceType)
        self.session = MCSession(peer: myPeerId, securityIdentity: nil, encryptionPreference: .optional)
        super.init()
        self.serviceAdvertiser.delegate = self
        self.session.delegate = self
        self.serviceAdvertiser.startAdvertisingPeer()
    }
    
    func start() {
        print(1)
    }
    
    deinit {
        self.serviceAdvertiser.stopAdvertisingPeer()
    }
    
}

extension KeyboardService {
    
    private func isPeerConnected(_ peer: MCPeerID) -> Bool {
        return self.session.connectedPeers.contains(peer)
    }
    
    private func jsonStringify(from object: Any) -> String? {
        if let objectData = try? JSONSerialization.data(withJSONObject: object, options: JSONSerialization.WritingOptions(rawValue: 0)) {
            let objectString = String(data: objectData, encoding: .utf8)
            return objectString
        }
        return nil
    }

    private func sendStringToPeers(_ string: String, peers: [MCPeerID]) -> Bool {
        var ok = false
        do {
            if peers.count > 0 {
                print("Send to:", peers.map({id in id.displayName}), "   with: ", string)
                try session.send(string.data(using: .utf8)!, toPeers: peers, with: .reliable)
                ok = true
            }
        } catch {
            print("_err", error)
        }
        return ok
    }
    
    private func sendInstructionToPeers(type: String, content: String, peers: [MCPeerID]) -> Bool {
        var ok = false
        if let str = jsonStringify(from: [type, content]) {
            ok = sendStringToPeers(str, peers: peers)
        } else {
            print("_err", "jsonStringify error", type, content)
        }
        return ok
    }
}

extension KeyboardService {
    
    func update(_ text: String) {
        let receivers = session.connectedPeers
        _ = sendInstructionToPeers(type: "update", content: text, peers: receivers)
    }
    
    func input(_ text: String) -> Bool {
        let receivers = session.connectedPeers
        let ok = sendInstructionToPeers(type: "insert", content: text, peers: receivers)
        return ok
    }
    
    func delete() {
        let receivers = session.connectedPeers
        _ = sendInstructionToPeers(type: "delete", content: "", peers: receivers)
    }
    
}

extension KeyboardService: MCNearbyServiceAdvertiserDelegate {
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("[didNotStartAdvertisingPeer] \(error)")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("[didReceiveInvitationFromPeer] \(peerID.displayName)")
        invitationHandler(true && !isPeerConnected(peerID), self.session)
    }
    
}

extension KeyboardService: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:
            print("[Connected]", peerID.displayName)
            do {
                try self.session.send("123".data(using: .utf8)!, toPeers: [peerID], with: .reliable)
            } catch {
                print("_err", error)
            }
        case .connecting:
            print("[Connecting]", peerID.displayName)
        case .notConnected:
            print("[NotConnected]", peerID.displayName)
        }
        self.delegate?.peer(peerID, didChange: state)
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        print("[rcv]\(peerID.displayName):", String.init(data: data, encoding: .utf8)!)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        
    }
    
    
}

