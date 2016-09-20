//
//  DraggableAnimator.swift
//  DraggableOverlayView
//
//  Created by アンドレ on 2016/05/03.
//  Copyright © 2016年 Swift. All rights reserved.
//

import UIKit

class Animator : NSObject, UIViewControllerAnimatedTransitioning {
    
    let transistionDirection : TransistionDirection
    let configuration : OverlayConfigurationProtocol
    let identifier = Int(arc4random())
    
    init(with configuration:OverlayConfigurationProtocol, direction:TransistionDirection) {
        self.transistionDirection = direction
        self.configuration = configuration
        super.init()
    }

    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return DefaultOverlayViewAnimationDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let constants = self.animationConstants(from:transitionContext) else {
            return
        }
        
        self.prepareViewsForAnimation(using:constants)
        
        let animations = {
            constants.presentedView.frame = constants.endingFrame
            
            if .backwards == self.transistionDirection {
                constants.presentedView.alpha = self.configuration.fadeInPresentationAndFadeOutDismissal ? 0.0 : 1.0
                constants.presentedView.layer.cornerRadius = 0
                constants.presentedView.layer.cornerRadius = 0
            } else {
                constants.presentedView.alpha = 1.0
                constants.presentedView.layer.cornerRadius = self.configuration.cornerRadius
                constants.presentingView.layer.cornerRadius = self.configuration.cornerRadius
            }
            
            constants.presentedView.layoutIfNeeded()
        }
        
        let completion : CompletionFunc = { finished in
            
            let canceled = constants.context.transitionWasCancelled
            constants.context.completeTransition(!canceled)
            if !canceled  {
                self.cleanUpViewsAfterClosing(using: constants)
            } else {
                self.returnViewsToOriginalStateAfterCancelation(using: constants)
            }
        }
        
        if true == transitionContext.isInteractive {
            UIView.interactivelyAnimate(animation:animations, completion:completion)
        } else {
            UIView.bounce(animation:animations, completion:completion)
        }
    }
    
}

typealias AnimationConstants = (context:UIViewControllerContextTransitioning, startingFrame:CGRect, endingFrame:CGRect, container: UIView,presentingController:UIViewController,presentingView:UIView,presentedController:UIViewController,presentedView:UIView)
extension Animator {
    func prepareViewsForAnimation(using constants:AnimationConstants) {
        
        if .forwards == self.transistionDirection {
            constants.presentedView.alpha = configuration.fadeInPresentationAndFadeOutDismissal ? 0.0 : 1.0
            constants.presentedView.frame = constants.startingFrame
            constants.container.addSubview(constants.presentedView)
        }
        
        constants.presentedView.superview?.layoutIfNeeded()
    }
    
    func cleanUpViewsAfterClosing(using constants:AnimationConstants) {
        
        if .backwards == self.self.transistionDirection {
            constants.presentedView.alpha = 0.0
            constants.presentedView.removeFromSuperview()
        }
    }
    
    func returnViewsToOriginalStateAfterCancelation(using constants:AnimationConstants) {
        UIView.bounce( animation:{
            if .forwards == self.transistionDirection  {
                constants.presentedView.alpha = self.configuration.fadeInPresentationAndFadeOutDismissal ? 0.0 : 1.0
            }
            constants.presentedView.frame = constants.startingFrame
        }, completion: { _ in
            if .forwards == self.self.transistionDirection  {
                self.cleanUpViewsAfterClosing(using: constants)
            }
        })
    }
}

extension Animator {
    func frameOf(_ controller:UIViewController, beforeBeingPresentedIn container:UIView, with context: UIViewControllerContextTransitioning) -> CGRect {
        
        let container = container.bounds
        
        var initialFrame = context.initialFrame(for: controller)
        if CGRect.zero == initialFrame {
            initialFrame = CGRect(x: 0, y: container.height, width: container.width, height: container.height)
        }
        
        if  let sourceFrame = configuration.dragSourceView?.frame {
            return CGRect(origin: sourceFrame.origin, size: CGSize(width: sourceFrame.width, height: initialFrame.height))
        } else {
            return CGRect(x: container.origin.x, y: container.height, width: initialFrame.width, height: initialFrame.height)
        }
    }
}

extension Animator {
    func animationConstants(from context: UIViewControllerContextTransitioning) -> AnimationConstants? {

        guard let presentedController = context.viewController(forKey: self.presentedControllerKey), let presentedView = context.view(forKey: self.presentedViewKey) else {
            return nil
        }
        
        guard let presentingController = context.viewController(forKey: self.presentingControllerKey) else {
            return nil
        }
        
        let containerView = context.containerView
        let closedPositionFrame = self.frameOf(presentedController, beforeBeingPresentedIn:containerView ,with:context)
        let openedPositionFrame = context.finalFrame(for: presentedController)
        
        let startingFrame : CGRect = .backwards == self.transistionDirection ? openedPositionFrame : closedPositionFrame
        let endingFrame : CGRect = .backwards == self.transistionDirection ? closedPositionFrame : openedPositionFrame
        
        return (context,startingFrame,endingFrame,containerView,presentingController,UIView(),presentedController,presentedView)
    }
    
    var presentedControllerKey : UITransitionContextViewControllerKey {
        get { return (.forwards == self.transistionDirection ? .to : .from) }
    }
    
    var presentedViewKey : UITransitionContextViewKey {
        get { return (.forwards == self.transistionDirection ? .to : .from) }
    }
    
    var presentingControllerKey : UITransitionContextViewControllerKey {
        get { return (.forwards == self.transistionDirection ? .from : .to) }
    }
    
    var presentingViewKey : UITransitionContextViewKey {
        get { return (.forwards == self.transistionDirection ? .from : .to) }
    }

    
}
