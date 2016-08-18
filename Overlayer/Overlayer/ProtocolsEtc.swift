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
    func didCancelViewControllerPresentationInOverlay(_ coordinator:DraggableSegueCoordinator?)
    func didCancelViewControllerClosureInOverlay(_ coordinator:DraggableSegueCoordinator?)
    
    func willPresentViewControllerInOverlay(_ coordinator:DraggableSegueCoordinator?)
    func didPresentViewControllerInOverlay(_ coordinator:DraggableSegueCoordinator?)
    
    func willDismissViewControllerFromOverlay(_ coordinator:DraggableSegueCoordinator?)
    func didDismissViewControllerFromOverlay(_ coordinator:DraggableSegueCoordinator?)
}

//MARK: - Overlay Obervation Default Implementation
public extension OverlayObservering {
    func didCancelViewControllerPresentationInOverlay(_ coordinator:DraggableSegueCoordinator?) {debugPrint(#function)}
    func willPresentViewControllerInOverlay(_ coordinator:DraggableSegueCoordinator?) {debugPrint(#function)}
    func didPresentViewControllerInOverlay(_ coordinator:DraggableSegueCoordinator?) {debugPrint(#function)}
    
    func didCancelViewControllerClosureInOverlay(_ coordinator:DraggableSegueCoordinator?) {debugPrint(#function)}
    func willDismissViewControllerFromOverlay(_ coordinator:DraggableSegueCoordinator?) {debugPrint(#function)}
    func didDismissViewControllerFromOverlay(_ coordinator:DraggableSegueCoordinator?) {debugPrint(#function)}
}

//Mark: Gesture Recognition
//Used to Tie Gesture Recognizers on Outside to Inner Objects
public protocol OverlayCoordinating : class {
    func handlePanGesture(_ recognizer : UIPanGestureRecognizer)
    func handleTapGesture(_ recognizer : UITapGestureRecognizer)
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
    
    var transistionDirection = TransistionDirection.forwards
    
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
    public func handlePanGesture(_ recognizer : UIPanGestureRecognizer) {debugPrint(#function)}
    public func handleTapGesture(_ recognizer : UITapGestureRecognizer) {debugPrint(#function)}
}

//Private Enums
enum RecognizerDirection {
    case horizontal
    case vertical
}

enum TransistionDirection {
    case forwards
    case backwards
}

//Private Typealiases
typealias TransistorObject = protocol<TransistorProtocol, OverlayCoordinating,UIViewControllerInteractiveTransitioning>
typealias CoordinatedTransition = (UIViewControllerTransitionCoordinatorContext) -> Void
typealias CompletionFunc = (Bool) -> Void
typealias VoidFunc = (Void) -> Void


//Private Constants
let ContainerViewBakgroundColor = UIColor.init(colorLiteralRed: 0.333, green: 0.358, blue: 0.364, alpha: 1.0)
let OverlayColor = UIColor(colorLiteralRed: 0.005, green: 0.025, blue: 0.1, alpha: 0.18)

let InteractiveLinearAnimationOptions : UIViewAnimationOptions = [.overrideInheritedCurve,.curveLinear]
let EaseInEaseOutAnimationOptions : UIViewAnimationOptions = [.overrideInheritedCurve, .curveEaseInOut]

let DefaultOverlayViewAnimationDuration : TimeInterval = 0.77

let EmptyCompletionFunc : CompletionFunc = {_ in}
let EmptyVoidFunc : VoidFunc = {}

let zDepthTransform : CATransform3D = {
    var transform = CATransform3DIdentity
    transform.m34 = -1.0 / 500.0
    return transform
}()


//MARK: - Private Extensions
extension UIView {
    static func bounce(_ duration: TimeInterval = DefaultOverlayViewAnimationDuration,animation:@escaping () -> Void, completion: ((Bool) -> Void)? = EmptyCompletionFunc) {
        self.animate(withDuration: DefaultOverlayViewAnimationDuration, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 2.0, options: [], animations: animation, completion: completion)
    }
    
    static func interactivelyAnimate(_ duration: TimeInterval = DefaultOverlayViewAnimationDuration,animation:@escaping () -> Void, completion: ((Bool) -> Void)? = EmptyCompletionFunc) {
        self.animate(withDuration: duration, delay:0, options:InteractiveLinearAnimationOptions, animations:animation, completion:completion)
    }
    
    static func animate(_ duration: TimeInterval = DefaultOverlayViewAnimationDuration,animation:@escaping () -> Void, completion: ((Bool) -> Void)? = EmptyCompletionFunc) {
        self.animate(withDuration: duration, delay:0, options:EaseInEaseOutAnimationOptions, animations:animation, completion:completion)
    }
}

extension UIView {
    func setBgColor(_ color:UIColor) -> UIView {
        self.backgroundColor = color
        return self
    }
}

//Note: doesnt work for some UIView Subclasses such as UINavigationBar... in that case the view will not be able to be added to the view heirarchy...
extension UIView {
    func archivedCopy() -> UIView? {
        let archive = NSKeyedArchiver.archivedData(withRootObject: self)
        let unarchivedObject = NSKeyedUnarchiver.unarchiveObject(with: archive)
        return unarchivedObject as? UIView
    }
}

