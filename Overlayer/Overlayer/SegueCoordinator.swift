//
//  DraggableSegueCoordinatorProtocol.swift
//  DraggableOverlayView
//
//  Created by アンドレ on 2016/05/01.
//  Copyright © 2016年 Swift. All rights reserved.
//

import UIKit


open class DraggableSegueCoordinator : NSObject {

    lazy var closeTransistor : TransistorObject = Transistor(recognitionBeganCallback:self.closeDraggableOverlayIfPossible, transistionDirection:.backwards)
    lazy var openTransistor : TransistorObject = Transistor(recognitionBeganCallback:self.openDraggableOverlayIfPossible, transistionDirection:.forwards)

    var configuration : OverlayConfiguration = OverlayConfiguration()
    var observer : OverlayObservering?

    fileprivate var _state : State = .unintialized
    enum State {
        case presentable(String,UIViewController)
        case presenting(UIStoryboardSegue)
        case unintialized
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
    
    @IBInspectable public var modalPresentationCapturesStatusBarAppearance: Bool {
        get { return self.configuration.modalPresentationCapturesStatusBarAppearance }
        set { self.configuration.modalPresentationCapturesStatusBarAppearance = newValue }
    }
    @IBInspectable public var overlayIsFullScreenWhenNotCustomPresentation : Bool {
        get { return self.configuration.overlayIsFullScreenWhenNotCustomPresentation }
        set { self.configuration.overlayIsFullScreenWhenNotCustomPresentation = newValue }
    }
    
    @IBInspectable public var overlayZoomsOutPresentingViewController : Bool {
        get { return self.configuration.overlayZoomsOutPresentingViewController }
        set { self.configuration.overlayZoomsOutPresentingViewController = newValue }
    }

    @IBInspectable public var fadeInPresentationAndFadeOutDismissal : Bool {
        get { return self.configuration.fadeInPresentationAndFadeOutDismissal }
        set { self.configuration.fadeInPresentationAndFadeOutDismissal = newValue }
    }

    @IBInspectable public var overlayPresentationStyleIsCustom : Bool {
        get { return self.configuration.overlayPresentationStyleIsCustom }
        set { self.configuration.overlayPresentationStyleIsCustom = newValue }
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

    @IBAction public func showDraggableOverlayView(_ sender : AnyObject) {
        self.openDraggableOverlayIfPossible()
    }
    
    @IBAction public func openRecognizerDidRecognize(_ recognizer:UIPanGestureRecognizer) {
        debugPrint(#function)
        self.openTransistor.handlePanGesture(recognizer)
    }
}

//Public entry points to change state
extension DraggableSegueCoordinator {
    public func handle(_ segue: UIStoryboardSegue, sender: UIViewController, observer:OverlayObservering) -> Bool {
        
        if (self.makePresentingIfPossible(segue)) {

            segue.destination.modalPresentationCapturesStatusBarAppearance = self.configuration.modalPresentationCapturesStatusBarAppearance
            segue.destination.modalPresentationStyle = self.presentationStyle
            segue.destination.transitioningDelegate = self
            
            segue.source.providesPresentationContextTransitionStyle = true
            segue.source.definesPresentationContext = true
            
            self.observer = observer
        }
        
        return true
    }
    
    public func openDraggableOverlayIfPossible() {
        if case .presentable(let segueIdentier,let sourceDestinationViewController) = self.state {
            sourceDestinationViewController.performSegue(withIdentifier: segueIdentier, sender: self)
        }
    }
    
    public func closeDraggableOverlayIfPossible() {
        if case .presenting(let segue) = self.state {
            segue.destination.dismiss(animated: true, completion: nil)
        }
    }
    
    public func prepareToRelenquishSegueAfterDismissingOverlay() {
        if case .presenting(let segue) = self.state {
            segue.destination.transitioningDelegate = nil
        }
    }
    
    public var presentationStyle : UIModalPresentationStyle {
        get {
            return (self.configuration.overlayPresentationStyleIsCustom ? .custom : self.nonCustomPresentationStyle)
        } set {}
    }
    
    public var nonCustomPresentationStyle : UIModalPresentationStyle {
        get {
            return (self.configuration.overlayIsFullScreenWhenNotCustomPresentation ? .overFullScreen : .overCurrentContext)
        } set {}
    }
}

private extension DraggableSegueCoordinator {
    
    func prepareDestinationViewControllerForSwipeDown() {
        if case .presenting(let segue) = self.state, let slideDownView = segue.destination.viewForDraggedDismissal {
            let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(self.closeRecognizerDidRecognize))
            slideDownView.addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    @objc @IBAction func closeRecognizerDidRecognize(_ recognizer:UIPanGestureRecognizer) {
        self.closeTransistor.handlePanGesture(recognizer)
    }
}

//These are entry points for state change... NEVER EVER EVER SET STATE DIRECTLY!! 😋
//This extension just wraps the _state so that its all in one place...
private extension DraggableSegueCoordinator {
    func makePresentableIfPossible(with configuration:OverlayConfiguration)  -> Bool {
        return self._state.makePresentableIfPossible(with:configuration)
    }
    
    func makePresentingIfPossible(_ segue : UIStoryboardSegue?)  -> Bool {
        return self._state.makePresentingIfPossible(segue)
    }
    
    func returnFromPresentingIfPossible(with configuration:OverlayConfiguration) -> Bool {
        return self._state.returnFromPresentingIfPossible(with: configuration)
    }
}

//Actual State Altering Parts
private extension DraggableSegueCoordinator.State {
    mutating func makePresentableIfPossible(with configuration:OverlayConfiguration)  -> Bool {
        
        if case .unintialized = self, case .presenting(_) = self {
            return false
        }
        
        guard let segueID = configuration.openSegueIdentifier, let source = configuration.sourceViewController else {
            return false
        }
        
        self = .presentable(segueID, source)
        return true
    }
    
    mutating func makePresentingIfPossible(_ segue : UIStoryboardSegue?)  -> Bool {
        
        guard case .presentable(_,_) = self, let segue = segue else {
            return false
        }
        
        self = .presenting(segue)
        return true
    }
    
    mutating func returnFromPresentingIfPossible(with configuration:OverlayConfiguration) -> Bool {
        
        guard case .presenting(_) = self else {
            return false
        }
        
        guard self.makePresentableIfPossible(with: configuration) else {
            self = .unintialized
            return true
        }
        
        return true
    }
}


extension DraggableSegueCoordinator : UIViewControllerTransitioningDelegate {
    
    public func animationController( forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController)
        -> UIViewControllerAnimatedTransitioning? {        
        return Animator(with: self.configuration, direction: .forwards)
    }
    
    public func interactionControllerForPresentation(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if self.openTransistor.interactiveTransitionActive {
            return openTransistor
        }
        return nil
    }
    
    //The following are only called if the presentation style is .custom...
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        
        guard case .presenting(let segue) = self.state else  {
            return nil
        }
        
        return Presenter(with: self.configuration, segue:segue, observer: self)
    }

    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return Animator(with: self.configuration, direction: .backwards)
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if self.closeTransistor.interactiveTransitionActive {
            return closeTransistor
        }
        return nil
    }
}

extension DraggableSegueCoordinator : OverlayObservering {
    public func willPresentViewControllerInOverlay(_ coordinator:DraggableSegueCoordinator?) {
        self.observer?.willPresentViewControllerInOverlay(self)
    }
    
    public func didPresentViewControllerInOverlay(_ coordinator:DraggableSegueCoordinator?) {
        self.observer?.didPresentViewControllerInOverlay(self)
        self.prepareDestinationViewControllerForSwipeDown()
    }
    
    public func willDismissViewControllerFromOverlay(_ coordinator:DraggableSegueCoordinator?) {
        self.observer?.willDismissViewControllerFromOverlay(self)
    }
    
    public func didDismissViewControllerFromOverlay(_ coordinator:DraggableSegueCoordinator?) {
        self.prepareToRelenquishSegueAfterDismissingOverlay()
        self.returnFromPresentingIfPossible(with: self.configuration)
        self.observer?.didDismissViewControllerFromOverlay(self)
        self.observer = nil
    }
    
    public func didCancelViewControllerPresentationInOverlay(_ coordinator: DraggableSegueCoordinator?) {
        self.returnFromPresentingIfPossible(with: self.configuration)
        self.observer?.didCancelViewControllerClosureInOverlay(self)
    }
    
    public func didCancelViewControllerClosureInOverlay(_ coordinator: DraggableSegueCoordinator?) {
        self.observer?.didCancelViewControllerClosureInOverlay(self)
    }
}

