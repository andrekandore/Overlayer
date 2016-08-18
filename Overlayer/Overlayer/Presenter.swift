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
        super.init(presentedViewController: segue.destination, presenting: segue.source)
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
                vars.parentView.transform = vars.parentView.transform.scaledBy(x: scale, y: scale)
                
                if self.configuration.zoomedOverlayTranslatesUpwardsProportionallyToTopMargin {
                    vars.parentView.transform = vars.parentView.transform.translatedBy(x: 0, y: -CGFloat(self.configuration.overlayTopMargin))
                }
            }
        }
        
        let cancelAnimation = {
            vars.parentView.layer.transform = CATransform3DIdentity
            self.configuration.overlay.alpha = 0.0
        }
        
        let completionBlock : CoordinatedTransition = { context in
            if true == context.isCancelled {
                UIView.animate(animation: cancelAnimation) { _ in
                    self.configuration.overlay.removeFromSuperview()
                }
            }
        }
        
        vars.coordinator.animateAlongsideTransition(in: vars.parentView, animation:zoomOutAnimation, completion: nil)
        vars.coordinator.animate(alongsideTransition: overlayAnimation,completion:nil)
        vars.coordinator.notifyWhenInteractionEnds(completionBlock)
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
            vars.parentView.transform = CGAffineTransform.identity
        }
        
        let completion : CoordinatedTransition = { completion in
            if !completion.isCancelled {
//                vars.parentView.superview?.layer.sublayerTransform = CATransform3DIdentity
            }
        }
        
        vars.coordinator.animateAlongsideTransition(in: vars.parentView, animation:zoomBackInAnimation, completion:nil)
        vars.coordinator.animate(alongsideTransition: closeOverlayAnimation, completion: completion)
        vars.coordinator.notifyWhenInteractionEnds({_ in})
    }
}

extension Presenter {
    func preparePresentationAnimation(_ vars : TransitionVariables) {
        if configuration.overlayZoomsOutPresentingViewController {
            configuration.overlay.alpha = 0.0
            configuration.overlay.autoresizingMask = [.flexibleWidth,.flexibleHeight]
            configuration.overlay.frame = vars.containerView.bounds
            vars.containerView.insertSubview(configuration.overlay, at: 0)
        }
    }
}

extension Presenter {
    override var frameOfPresentedViewInContainerView : CGRect {
        
        guard let containerView = self.containerView else {
            return super.frameOfPresentedViewInContainerView
        }
        
        var containerViewBounds = containerView.bounds
        containerViewBounds.origin.y = CGFloat(configuration.overlayTopMargin)
        containerViewBounds.size.height -= CGFloat(configuration.overlayTopMargin)
        
        return containerViewBounds
    }
}

extension Presenter {
    override func presentationTransitionDidEnd(_ completed: Bool) {
        if completed {
            self.observer?.didPresentViewControllerInOverlay(nil)
        } else {
            self.observer?.didCancelViewControllerPresentationInOverlay(nil)
        }
    }
    
    override func dismissalTransitionDidEnd(_ completed: Bool) {
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
            guard let parentView = self.presentingViewController.view, let containerView = self.containerView, let coordinator = self.presentedViewController.transitionCoordinator else {
                return nil
            }
            
            return (parentView,containerView,coordinator)
        }
    }
    
    func zoomOutScale(_ vars:TransitionVariables) -> CGFloat {
        return 1.0 - fabs(self.configuration.zoomOutMultipier * CGFloat(self.configuration.overlayTopMargin) / vars.containerView.bounds.height)
    }
}
