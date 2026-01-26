//
//  KeyboardObserverTests.swift
//  NeuroID
//
//  Created by Collin Dunphy on 1/14/26.
//


import Testing
import UIKit

@testable import NeuroID

@MainActor
struct KeyboardObserverTests {
    
    final class TestViewController: UIViewController {
        override func loadView() { self.view = UIView(frame: .init(x: 0, y: 0, width: 390, height: 844)) }
    }

    @Test
    func keyboardWillShow_canBeCalledDirectly() async throws {
        let vc = TestViewController()
        _ = vc.view

        let keyboardFrame = CGRect(x: 0, y: 500, width: 390, height: 344)
        let notification = Notification(
            name: UIResponder.keyboardWillShowNotification,
            object: nil,
            userInfo: [UIResponder.keyboardFrameEndUserInfoKey: keyboardFrame]
        )

        // Direct call, no NotificationCenter involved:
        vc.keyboardWillShow(notification: notification)

        // If you want to assert "saveEventToLocalDataStore" was called,
        // you need a seam (event sink / spy) rather than relying on global NeuroID.shared.
    }
}
