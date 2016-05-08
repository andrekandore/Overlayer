//
//  DraggableOverlay.swift
//  DraggableOverlayView
//
//  Created by アンドレ on 2016/05/03.
//  Copyright © 2016年 Swift. All rights reserved.
//

import UIKit

//MARK: -
//MARK: ⬛︎ ⬛︎ ⬛︎ Public ⬛︎ ⬛︎ ⬛︎
//MARK: -

//MARK: Public Types
//MARK: - Overlay Obervation Protocol
public protocol OverlayObservering : class {
    func didCancelViewControllerPresentationInOverlay(coordinator:DraggableSegueCoordinator?)
    func didCancelViewControllerClosureInOverlay(coordinator:DraggableSegueCoordinator?)
    
    func willPresentViewControllerInOverlay(coordinator:DraggableSegueCoordinator?)
    func didPresentViewControllerInOverlay(coordinator:DraggableSegueCoordinator?)
    
    func willDismissViewControllerFromOverlay(coordinator:DraggableSegueCoordinator?)
    func didDismissViewControllerFromOverlay(coordinator:DraggableSegueCoordinator?)
}

//MARK: - Overlay Obervation Default Implementation
public extension OverlayObservering {
    func didCancelViewControllerPresentationInOverlay(coordinator:DraggableSegueCoordinator?) {debugPrint(#function)}
    func willPresentViewControllerInOverlay(coordinator:DraggableSegueCoordinator?) {debugPrint(#function)}
    func didPresentViewControllerInOverlay(coordinator:DraggableSegueCoordinator?) {debugPrint(#function)}
    
    func didCancelViewControllerClosureInOverlay(coordinator:DraggableSegueCoordinator?) {debugPrint(#function)}
    func willDismissViewControllerFromOverlay(coordinator:DraggableSegueCoordinator?) {debugPrint(#function)}
    func didDismissViewControllerFromOverlay(coordinator:DraggableSegueCoordinator?) {debugPrint(#function)}
}

//Mark: Gesture Recognition
//Used to Tie Gesture Recognizers on Outside to Inner Objects
public protocol OverlayCoordinating : class {
    func handlePanGesture(recognizer : UIPanGestureRecognizer)
    func handleTapGesture(recognizer : UITapGestureRecognizer)
}

//MARK: -
//MARK: ⬛︎ ⬛︎ ⬛︎ Privates ⬛︎ ⬛︎ ⬛︎
//MARK: -

//MARK: Private Protocols
//Overlay Config is Passed to Helper Objects as Protocols with only GET functionality to prevent accidental changes
protocol OverlayConfigurationProtocol {
    var zoomedOverlayTranslatesUpwardsProportionallyToTopMargin : Bool {get}
    var zoomedOverlayAltersContainerContainerBackground : Bool {get}
    var overlayZoomsOutPresentingViewController : Bool {get}
    var fadeInPresentationAndFadeOutDismissal : Bool {get}
    var zoomOutMultipier : CGFloat {get}
    var overlay : UIView {get}
    
    var segue : UIStoryboardSegue? {get}
    
    var overlayTopMargin : UInt {get}
    var dragSourceView : UIView? {get}    
}

struct OverlayConfiguration : OverlayConfigurationProtocol {
    var zoomedOverlayTranslatesUpwardsProportionallyToTopMargin : Bool = false
    var zoomedOverlayAltersContainerContainerBackground = true
    var overlay : UIView = UIView().setBgColor(OverlayColor)
    var overlayZoomsOutPresentingViewController = true
    var fadeInPresentationAndFadeOutDismissal = false
    var zoomOutMultipier : CGFloat = -1.72
    
    var transistionDirection = TransistionDirection.Forwards
    
    var sourceViewController : UIViewController?
    var openSegueIdentifier : String?
    var segue : UIStoryboardSegue?
    
    var overlayTopMargin : UInt = 0
    var dragSourceView : UIView?
}


//MARK: - Animator / Interactive Transision Types
protocol AnimationDirecting {
    var transistionDirection : TransistionDirection {get set}
    var recognizerDirection : RecognizerDirection {get set}
}

protocol TransistorProtocol {
    var recognitionBeganCallback : VoidFunc {get}
    var interactiveTransitionActive : Bool {get}
}

//Mark: Gesture Recognition Default Implementations
extension OverlayCoordinating {
    public func handlePanGesture(recognizer : UIPanGestureRecognizer) {debugPrint(#function)}
    public func handleTapGesture(recognizer : UITapGestureRecognizer) {debugPrint(#function)}
}

//Private Enums
enum RecognizerDirection {
    case Horizontal
    case Vertical
}

enum TransistionDirection {
    case Forwards
    case Backwards
}

//Private Typealiases
typealias TransistorObject = protocol<TransistorProtocol, OverlayCoordinating,UIViewControllerInteractiveTransitioning>
typealias CoordinatedTransition = (UIViewControllerTransitionCoordinatorContext) -> Void
typealias CompletionFunc = (Bool) -> Void
typealias VoidFunc = (Void) -> Void


//Private Constants
let ContainerViewBakgroundColor = UIColor.init(colorLiteralRed: 0.333, green: 0.358, blue: 0.364, alpha: 1.0)
let OverlayColor = UIColor(colorLiteralRed: 0.005, green: 0.025, blue: 0.1, alpha: 0.18)

let InteractiveLinearAnimationOptions : UIViewAnimationOptions = [.OverrideInheritedCurve,.CurveLinear]
let EaseInEaseOutAnimationOptions : UIViewAnimationOptions = [.OverrideInheritedCurve,.CurveEaseInOut]

let DefaultOverlayViewAnimationDuration : NSTimeInterval = 0.77

let EmptyCompletionFunc : CompletionFunc = {_ in}
let EmptyVoidFunc : VoidFunc = {}

let zDepthTransform : CATransform3D = {
    var transform = CATransform3DIdentity
    transform.m34 = -1.0 / 500.0
    return transform
}()


//MARK: - Private Extensions
extension UIView {
    static func bounce(duration: NSTimeInterval = DefaultOverlayViewAnimationDuration,animation:() -> Void, completion: ((Bool) -> Void)? = EmptyCompletionFunc) {
        self.animateWithDuration(DefaultOverlayViewAnimationDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 2.0, options: [], animations: animation, completion: completion)
    }
    
    static func interactivelyAnimate(duration: NSTimeInterval = DefaultOverlayViewAnimationDuration,animation:() -> Void, completion: ((Bool) -> Void)? = EmptyCompletionFunc) {
        self.animateWithDuration(duration, delay:0, options:InteractiveLinearAnimationOptions, animations:animation, completion:completion)
    }
    
    static func animate(duration: NSTimeInterval = DefaultOverlayViewAnimationDuration,animation:() -> Void, completion: ((Bool) -> Void)? = EmptyCompletionFunc) {
        self.animateWithDuration(duration, delay:0, options:EaseInEaseOutAnimationOptions, animations:animation, completion:completion)
    }
}

extension UIView {
    func setBgColor(color:UIColor) -> UIView {
        self.backgroundColor = color
        return self
    }
}

//Note: doesnt work for some UIView Subclasses such as UINavigationBar... in that case the view will not be able to be added to the view heirarchy...
extension UIView {
    func archivedCopy() -> UIView? {
        let archive = NSKeyedArchiver.archivedDataWithRootObject(self)
        let unarchivedObject = NSKeyedUnarchiver.unarchiveObjectWithData(archive)
        return unarchivedObject as? UIView
    }
}

