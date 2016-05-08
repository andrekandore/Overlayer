//
//  TransitionCoordinator.swift
//  DraggableOverlayView
//
//  Created by アンドレ on 2016/05/03.
//  Copyright © 2016年 Swift. All rights reserved.
//

import UIKit

class Transistor : UIPercentDrivenInteractiveTransition, TransistorProtocol, OverlayCoordinating {
    
    let transistionDirection : TransistionDirection
    var interactiveTransitionActive : Bool = false
    let interactionThreshold : CGFloat = 0.22
    let recognitionBeganCallback : VoidFunc
    
    init(recognitionBeganCallback : VoidFunc = EmptyVoidFunc, transistionDirection : TransistionDirection) {
        self.recognitionBeganCallback = recognitionBeganCallback
        self.transistionDirection = transistionDirection
        super.init()
    }
    
    internal override var completionSpeed: CGFloat {
        get {
            return self.percentComplete * (1.0/interactionThreshold)
        } set {}
    }
    
    func handlePanGesture(recognizer:UIPanGestureRecognizer) {
        
        var progress : CGFloat = 0.0
        
        guard let view = recognizer.view, let containerView = view.superview else {
            return
        }
        
        let translation = recognizer.translationInView(view).y
        let containerHeight = CGFloat(containerView.bounds.size.height)
        let movement = .Forwards == self.transistionDirection ? -translation : translation
        progress = movement / containerHeight
        progress = min(1.0, max(0.0, progress))
        
        debugPrint("Progress: \(progress)")
        
        switch recognizer.state {
        case .Possible: fallthrough
        case .Failed: fallthrough
        case .Began:
            self.interactiveTransitionActive = true
            self.recognitionBeganCallback()
            debugPrint("Began")
        case .Changed:
            self.updateInteractiveTransition(progress)
            debugPrint("Changed")
        case .Ended: fallthrough
        case .Cancelled:
            self.interactiveTransitionActive = false
            if progress < interactionThreshold {
                self.cancelInteractiveTransition()
            } else {
                self.finishInteractiveTransition()
            }
            debugPrint("Ended")
        }
    }
}