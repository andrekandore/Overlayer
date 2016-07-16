//
//  DraggableSegueCoordinatorProtocol.swift
//  DraggableOverlayView
//
//  Created by アンドレ on 2016/05/01.
//  Copyright © 2016年 Swift. All rights reserved.
//

import UIKit


public class DraggableSegueCoordinator : NSObject {

    lazy var closeTransistor : TransistorObject = Transistor(recognitionBeganCallback:self.closeDraggableOverlayIfPossible, transistionDirection:.Backwards)
    lazy var openTransistor : TransistorObject = Transistor(recognitionBeganCallback:self.openDraggableOverlayIfPossible, transistionDirection:.Forwards)

    var configuration : OverlayConfiguration = OverlayConfiguration()
    var observer : OverlayObservering?

    private var _state : State = .Unintialized
    enum State {
        case Presentable(String,UIViewController)
        case Presenting(UIStoryboardSegue)
        case Unintialized
    }
    
    var state : State {
        get { return _state } set {}
    }
}

//Connect the outside world (Interface Builder, other Code etc)
extension DraggableSegueCoordinator {

    @IBInspectable public var zoomedOverlayTranslatesUpwardsProportionallyToTopMargin : Bool {
        get { return self.configuration.zoomedOverlayTranslatesUpwardsProportionallyToTopMargin }
        set { self.configuration.zoomedOverlayTranslatesUpwardsProportionallyToTopMargin = newValue }
    }

    @IBInspectable public var zoomedOverlayAltersContainerContainerBackground : Bool {
        get { return self.configuration.zoomedOverlayAltersContainerContainerBackground }
        set { self.configuration.zoomedOverlayAltersContainerContainerBackground = newValue }
    }
    
    @IBInspectable public var overlayZoomsOutPresentingViewController : Bool {
        get { return self.configuration.overlayZoomsOutPresentingViewController }
        set { self.configuration.overlayZoomsOutPresentingViewController = newValue }
    }

    @IBInspectable public var fadeInPresentationAndFadeOutDismissal : Bool {
        get { return self.configuration.fadeInPresentationAndFadeOutDismissal }
        set { self.configuration.fadeInPresentationAndFadeOutDismissal = newValue }
    }

    @IBInspectable public var overlayTopMargin : UInt {
        get { return self.configuration.overlayTopMargin }
        set { self.configuration.overlayTopMargin = newValue }
    }
    
    @IBInspectable public var zoomOutMultipier : CGFloat {
        get { return self.configuration.zoomOutMultipier }
        set { self.configuration.zoomOutMultipier = newValue }
    }

    @IBOutlet public var dragSourceView : UIView? {
        get { return self.configuration.dragSourceView }
        set { self.configuration.dragSourceView = newValue }
    }

    @IBOutlet public var overlay : UIView? {
        get { return self.configuration.overlay }
        set { if nil != newValue {self.configuration.overlay = newValue!}}
    }
    
    @IBOutlet public var sourceViewController : UIViewController? {
        get { return self.configuration.sourceViewController }
        set {
            self.configuration.sourceViewController = newValue
            self.makePresentableIfPossible(with: self.configuration)
        }
    }

    @IBInspectable public var openSegueIdentifier : String? {
        get { return self.configuration.openSegueIdentifier }
        set {
            self.configuration.openSegueIdentifier = newValue
            self.state.makePresentableIfPossible(with: self.configuration)
        }
    }

    @IBAction public func showDraggableOverlayView(sender : AnyObject) {
        self.openDraggableOverlayIfPossible()
    }
    
    @IBAction public func openRecognizerDidRecognize(recognizer:UIPanGestureRecognizer) {
        debugPrint(#function)
        self.openTransistor.handlePanGesture(recognizer)
    }
}

//Public entry points to change state
extension DraggableSegueCoordinator {
    public func handle(segue: UIStoryboardSegue, sender: UIViewController, observer:OverlayObservering) -> Bool {
        
        if (self.makePresentingIfPossible(segue)) {
            segue.destinationViewController.modalPresentationCapturesStatusBarAppearance = true
            segue.destinationViewController.modalPresentationStyle = .Custom;
            segue.destinationViewController.transitioningDelegate = self
            self.observer = observer
        }
        
        return true
    }
    
    public func openDraggableOverlayIfPossible() {
        if case .Presentable(let segueIdentier,let sourceDestinationViewController) = self.state {
            sourceDestinationViewController.performSegueWithIdentifier(segueIdentier, sender: self)
        }
    }
    
    public func closeDraggableOverlayIfPossible() {
        if case .Presenting(let segue) = self.state {
            segue.destinationViewController.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    public func prepareToRelenquishSegueAfterDismissingOverlay() {
        if case .Presenting(let segue) = self.state {
            segue.destinationViewController.transitioningDelegate = nil
        }
    }
}

private extension DraggableSegueCoordinator {
    
    func prepareDestinationViewControllerForSwipeDown() {
        if case .Presenting(let segue) = self.state, let slideDownView = segue.destinationViewController.viewForDraggedDismissal {
            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.closeRecognizerDidRecognize))
            slideDownView.addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    @objc @IBAction private func closeRecognizerDidRecognize(recognizer:UIPanGestureRecognizer) {
        self.closeTransistor.handlePanGesture(recognizer)
    }
}

//These are entry points for state change... NEVER EVER EVER SET STATE DIRECTLY OR I WILL THROW A CONIPTION FIT!! 😋
//This extension just wraps the _state so that its all in one place...
private extension DraggableSegueCoordinator {
    func makePresentableIfPossible(with configuration:OverlayConfiguration)  -> Bool {
        return self._state.makePresentableIfPossible(with:configuration)
    }
    
    func makePresentingIfPossible(segue : UIStoryboardSegue?)  -> Bool {
        return self._state.makePresentingIfPossible(segue)
    }
    
    func returnFromPresentingIfPossible(with configuration:OverlayConfiguration) -> Bool {
        return self._state.returnFromPresentingIfPossible(with: configuration)
    }
}

//Actual State Altering Parts
private extension DraggableSegueCoordinator.State {
    mutating func makePresentableIfPossible(with configuration:OverlayConfiguration)  -> Bool {
        
        if case .Unintialized = self, case .Presenting(_) = self {
            return false
        }
        
        guard let segueID = configuration.openSegueIdentifier, let source = configuration.sourceViewController else {
            return false
        }
        
        self = .Presentable(segueID, source)
        return true
    }
    
    mutating func makePresentingIfPossible(segue : UIStoryboardSegue?)  -> Bool {
        
        guard case .Presentable(_,_) = self, let segue = segue else {
            return false
        }
        
        self = .Presenting(segue)
        return true
    }
    
    mutating func returnFromPresentingIfPossible(with configuration:OverlayConfiguration) -> Bool {
        
        guard case .Presenting(_) = self else {
            return false
        }
        
        guard self.makePresentableIfPossible(with: configuration) else {
            self = .Unintialized
            return true
        }
        
        return true
    }
}


extension DraggableSegueCoordinator : UIViewControllerTransitioningDelegate {
    
    public func animationControllerForPresentedController( presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {        
        return Animator(with: self.configuration, direction: .Forwards)
    }
    
    public func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if self.openTransistor.interactiveTransitionActive {
            return openTransistor
        }
        return nil
    }
    
    public func presentationControllerForPresentedViewController(presented: UIViewController, presentingViewController presenting: UIViewController?, sourceViewController source: UIViewController) -> UIPresentationController? {
        
        guard case .Presenting(let segue) = self.state else  {
            return nil
        }
        
        return Presenter(with: self.configuration, segue:segue, observer: self)
    }

    public func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return Animator(with: self.configuration, direction: .Backwards)
    }
    
    public func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if self.closeTransistor.interactiveTransitionActive {
            return closeTransistor
        }
        return nil
    }
}

extension DraggableSegueCoordinator : OverlayObservering {
    public func willPresentViewControllerInOverlay(coordinator:DraggableSegueCoordinator?) {
        self.observer?.willPresentViewControllerInOverlay(self)
    }
    
    public func didPresentViewControllerInOverlay(coordinator:DraggableSegueCoordinator?) {
        self.observer?.didPresentViewControllerInOverlay(self)
        self.prepareDestinationViewControllerForSwipeDown()
    }
    
    public func willDismissViewControllerFromOverlay(coordinator:DraggableSegueCoordinator?) {
        self.observer?.willDismissViewControllerFromOverlay(self)
    }
    
    public func didDismissViewControllerFromOverlay(coordinator:DraggableSegueCoordinator?) {
        self.prepareToRelenquishSegueAfterDismissingOverlay()
        self.returnFromPresentingIfPossible(with: self.configuration)
        self.observer?.didDismissViewControllerFromOverlay(self)
        self.observer = nil
    }
    
    public func didCancelViewControllerPresentationInOverlay(coordinator: DraggableSegueCoordinator?) {
        self.returnFromPresentingIfPossible(with: self.configuration)
        self.observer?.didCancelViewControllerClosureInOverlay(self)
    }
    
    public func didCancelViewControllerClosureInOverlay(coordinator: DraggableSegueCoordinator?) {
        self.observer?.didCancelViewControllerClosureInOverlay(self)
    }
}

