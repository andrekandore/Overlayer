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
    
    init(with configuration:OverlayConfigurationProtocol, direction:TransistionDirection) {
        self.transistionDirection = direction
        self.configuration = configuration
        super.init()
    }

    func transitionDuration(transitionContext: UIViewControllerContextTransitioning?) -> NSTimeInterval {
        return DefaultOverlayViewAnimationDuration
    }
    
    func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        
        guard let constants = self.animationConstants(from:transitionContext) else {
            return
        }
        
        self.prepareViewsForAnimation(using:constants)
        
        let animations = {
            constants.view.frame = constants.endingFrame
            constants.view.superview?.layoutIfNeeded()
            
            if .Backwards == self.transistionDirection {
                constants.view.alpha = self.configuration.fadeInPresentationAndFadeOutDismissal ? 0.0 : 1.0
            } else {
                constants.view.alpha = 1.0
            }
        }
        
        let completion : CompletionFunc = { finished in
            
            let canceled = constants.context.transitionWasCancelled()
            constants.context.completeTransition(!canceled)
            if !canceled  {
                self.cleanUpViewsAfterClosing(using: constants)
            } else {
                self.returnViewsToOriginalStateAfterCancelation(using: constants)
            }
        }
        
        if true == transitionContext.isInteractive() {
            UIView.interactivelyAnimate(animation:animations, completion:completion)
        } else {
            UIView.bounce(animation:animations, completion:completion)
        }
    }    
}


typealias AnimationConstants = (controller:UIViewController, view:UIView, context:UIViewControllerContextTransitioning,startingFrame:CGRect, endingFrame:CGRect, container: UIView)
extension Animator {
    func prepareViewsForAnimation(using constants:AnimationConstants) {
        if .Forwards == self.transistionDirection {
            constants.view.alpha = configuration.fadeInPresentationAndFadeOutDismissal ? 0.0 : 1.0
            constants.view.frame = constants.startingFrame
            constants.container.addSubview(constants.view)
        }
        constants.container.superview?.backgroundColor = ContainerViewBakgroundColor
        constants.view.superview?.layoutIfNeeded()        
    }
    
    func cleanUpViewsAfterClosing(using constants:AnimationConstants) {
        if .Backwards == self.self.transistionDirection {
            constants.container.superview?.backgroundColor = UIColor.clearColor()
            constants.view.alpha = 0.0
            constants.view.removeFromSuperview()
        }
    }
    
    func returnViewsToOriginalStateAfterCancelation(using constants:AnimationConstants) {
        UIView.bounce( animation:{
            if .Forwards == self.transistionDirection  {
                constants.view.alpha = self.configuration.fadeInPresentationAndFadeOutDismissal ? 0.0 : 1.0
            }
            constants.view.frame = constants.startingFrame
        }, completion: { _ in
            if .Forwards == self.self.transistionDirection  {
                self.cleanUpViewsAfterClosing(using: constants)
            }
        })
    }
}

extension Animator {
    func frameOf(controller:UIViewController, beforeBeingPresentedIn container:UIView, with context: UIViewControllerContextTransitioning) -> CGRect {
        
        let container = container.bounds
        
        var initialFrame = context.initialFrameForViewController(controller)
        if CGRectZero == initialFrame {
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
        
        let controllerKey : String = .Forwards == self.self.transistionDirection ? UITransitionContextToViewControllerKey : UITransitionContextFromViewControllerKey
        let viewKey : String = .Forwards == self.self.transistionDirection ? UITransitionContextToViewKey : UITransitionContextFromViewKey
        
        guard let controller = context.viewControllerForKey(controllerKey), let view = context.viewForKey(viewKey) else {
            return nil
        }
        
        let containerView = context.containerView()
        let closedPositionFrame = self.frameOf(controller, beforeBeingPresentedIn:containerView ,with:context)
        let openedPositionFrame = context.finalFrameForViewController(controller)
        
        let startingFrame : CGRect = .Backwards == self.transistionDirection ? openedPositionFrame : closedPositionFrame
        let endingFrame : CGRect = .Backwards == self.transistionDirection ? closedPositionFrame : openedPositionFrame
        
        return (controller,view,context,startingFrame,endingFrame,containerView)
    }
}
