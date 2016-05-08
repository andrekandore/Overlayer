//
//  PresentationCoordinator.swift
//  DraggableOverlayView
//
//  Created by アンドレ on 2016/05/03.
//  Copyright © 2016年 Swift. All rights reserved.
//

import UIKit


class Presenter : UIPresentationController {
    
    let configuration : OverlayConfigurationProtocol
    let observer : OverlayObservering?
    
    init(with configuration:OverlayConfigurationProtocol, segue:UIStoryboardSegue ,observer:OverlayObservering?) {
        self.configuration = configuration
        self.observer = observer
        super.init(presentedViewController: segue.destinationViewController, presentingViewController: segue.sourceViewController)
    }
    
    override func presentationTransitionWillBegin() {
        
        super.presentationTransitionWillBegin()
        
        guard let vars = self.transitionVariables else {
            return
        }

        self.observer?.willPresentViewControllerInOverlay(nil)
        self.preparePresentationAnimation(vars)
        
        let overlayAnimation : CoordinatedTransition = { context in
            self.configuration.overlay.alpha = 1.0
        }
        
        let zoomOutAnimation : CoordinatedTransition = { coordinator in
            if self.configuration.overlayZoomsOutPresentingViewController {
                
                let scale = self.zoomOutScale(vars)
                vars.parentView.transform = CGAffineTransformScale(vars.parentView.transform, scale, scale)
                
                if self.configuration.zoomedOverlayTranslatesUpwardsProportionallyToTopMargin {
                    vars.parentView.transform = CGAffineTransformTranslate(vars.parentView.transform, 0, -CGFloat(self.configuration.overlayTopMargin))
                }
            }
        }
        
        let cancelAnimation = {
            vars.parentView.layer.transform = CATransform3DIdentity
            self.configuration.overlay.alpha = 0.0
        }
        
        let completionBlock : CoordinatedTransition = { context in
            if true == context.isCancelled() {
                UIView.animate(animation: cancelAnimation) { _ in
                    self.configuration.overlay.removeFromSuperview()
                }
            }
        }
        
        vars.coordinator.animateAlongsideTransitionInView(vars.parentView, animation:zoomOutAnimation, completion: nil)
        vars.coordinator.animateAlongsideTransition(overlayAnimation,completion:nil)
        vars.coordinator.notifyWhenInteractionEndsUsingBlock(completionBlock)
    }
    
    override func dismissalTransitionWillBegin() {
        
        guard let vars = self.transitionVariables else {
            return
        }
        
        self.observer?.willDismissViewControllerFromOverlay(nil)
        
        let closeOverlayAnimation : CoordinatedTransition = { context in
            self.configuration.overlay.alpha = 0.0
        }
        
        let zoomBackInAnimation : CoordinatedTransition = { context in
            vars.parentView.transform = CGAffineTransformIdentity
        }
        
        let completion : CoordinatedTransition = { completion in
            if !completion.isCancelled() {
//                vars.parentView.superview?.layer.sublayerTransform = CATransform3DIdentity
            }
        }
        
        vars.coordinator.animateAlongsideTransitionInView(vars.parentView, animation:zoomBackInAnimation, completion:nil)
        vars.coordinator.animateAlongsideTransition(closeOverlayAnimation, completion: completion)
        vars.coordinator.notifyWhenInteractionEndsUsingBlock({_ in})
    }
}

extension Presenter {
    func preparePresentationAnimation(vars : TransitionVariables) {
        if configuration.overlayZoomsOutPresentingViewController {
            configuration.overlay.alpha = 0.0
            configuration.overlay.autoresizingMask = [.FlexibleWidth,.FlexibleHeight]
            configuration.overlay.frame = vars.containerView.bounds
            vars.containerView.insertSubview(configuration.overlay, atIndex: 0)
        }
    }
}

extension Presenter {
    override func frameOfPresentedViewInContainerView() -> CGRect {
        
        guard let containerView = self.containerView else {
            return super.frameOfPresentedViewInContainerView()
        }
        
        var containerViewBounds = containerView.bounds
        containerViewBounds.origin.y = CGFloat(configuration.overlayTopMargin)
        containerViewBounds.size.height -= CGFloat(configuration.overlayTopMargin)
        
        return containerViewBounds
    }
}

extension Presenter {
    override func presentationTransitionDidEnd(completed: Bool) {
        if completed {
            self.observer?.didPresentViewControllerInOverlay(nil)
        } else {
            self.observer?.didCancelViewControllerPresentationInOverlay(nil)
        }
    }
    
    override func dismissalTransitionDidEnd(completed: Bool) {
        if true == completed {
            self.observer?.didDismissViewControllerFromOverlay(nil)
        } else {
            self.observer?.didCancelViewControllerClosureInOverlay(nil)
        }
    }
}

typealias TransitionVariables = (parentView:UIView, containerView:UIView, coordinator:UIViewControllerTransitionCoordinator)
extension Presenter {
    var transitionVariables : TransitionVariables? {
        get {
            guard let parentView = self.presentingViewController.view, let containerView = self.containerView, let coordinator = self.presentedViewController.transitionCoordinator() else {
                return nil
            }
            
            return (parentView,containerView,coordinator)
        }
    }
    
    func zoomOutScale(vars:TransitionVariables) -> CGFloat {
        return 1.0 - fabs(self.configuration.zoomOutMultipier * CGFloat(self.configuration.overlayTopMargin) / vars.containerView.bounds.height)
    }
}
