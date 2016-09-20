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

//MARK: Gesture Recognition
//Used to Tie Gesture Recognizers on Outside to Inner Objects
public protocol OverlayCoordinating : class {
    func handlePanGesture(_ recognizer : UIPanGestureRecognizer)
    func handleTapGesture(_ recognizer : UITapGestureRecognizer)
}



public protocol OverlayableViewControllerConvenience {
    func unwindFromOverlayToPrevious(_ unwindSegue : UIStoryboardSegue)
    func unwindFromNonCustomOverlay(segue : UIStoryboardSegue)
    func defaultViewForDraggedDismissal() -> UIView?
}

//MARK: View Controller Support
extension UIViewController {
    
    @IBAction open func unwindFromOverlayToPrevious(_ unwindSegue : UIStoryboardSegue) {
        debugPrint(#function)
    }
    
    @IBAction open func unwindFromNonCustomOverlay(segue : UIStoryboardSegue) {
        debugPrint(#function)
        
        if let currentPresenter = self.ancestorOverlayController {
            let matchingSegues = currentPresenter.matchingSeguesFilter(segue)
            currentPresenter.draggableOverlayCoordinators.filter(matchingSegues).first?.closeDraggableOverlayIfPossible()
        } else {
            presentingViewController?.dismiss(animated: true, completion: nil)
        }
    }
    
    public var ancestorOverlayController : OverlayableViewControllerProtocol? {
        get {
            return self.searchForAncestorOverlayer()
        } set {}
    }
    
    private func searchForAncestorOverlayer()  -> OverlayableViewControllerProtocol? {
        
        var controller = self.presentingViewController
        while let presenter = controller  {
            if let overlayPresenter = presenter as? OverlayableViewControllerProtocol {
                return overlayPresenter
            } else {
                controller = presenter.presentingViewController
            }
        }
        
        return nil
    }
    
    public func defaultViewForDraggedDismissal() -> UIView? {
        if let headerToolbar = self.navigationController?.navigationBar {
            return headerToolbar
        }
        
        return nil
    }
    
}


//MARK: Overlayable View Controller Protocols and Default Implementations
public protocol OverlayableViewControllerProtocol : OverlayObservering {
    func matchingSeguesFilter(_ segue:UIStoryboardSegue) ->  (DraggableSegueCoordinator) -> Bool
    func attempt(overlaying segue: UIStoryboardSegue, sender: Any?)
    
    var draggableOverlayCoordinators : [DraggableSegueCoordinator] {get set}
    var viewForDraggedDismissalOutlet : UIView? {get set}
    var lightStatusBar : Bool {get set}
}

extension OverlayableViewControllerProtocol where Self : UIViewController {
    
    public func matchingSeguesFilter(_ segue:UIStoryboardSegue) ->  (DraggableSegueCoordinator) -> Bool {
        return { coordinator in
            if  let coordinatorIdentifier = coordinator.openSegueIdentifier,
                let segueEdentifier = segue.identifier
                , coordinatorIdentifier == segueEdentifier {
                return true
            }
            return false
        }
    }
    
    public func attempt(overlaying segue: UIStoryboardSegue, sender: Any?) {
        let matchingSegues = self.matchingSeguesFilter(segue)
        self.draggableOverlayCoordinators.filter(matchingSegues).first?.handle(segue, sender: self, observer: self)
    }
    
    public var statusBarStyle: UIStatusBarStyle {
        if true == self.lightStatusBar {
            return UIStatusBarStyle.lightContent
        } else {
            return UIStatusBarStyle.default
        }
    }
    
    public var viewForDraggedDismissal : UIView? {
        get {
            if let dragView = self.viewForDraggedDismissalOutlet {
                return dragView
            }
            return self.defaultViewForDraggedDismissal()
        } set {}
    }
}


//MARK: -
//MARK: ⬛︎ ⬛︎ ⬛︎ Privates ⬛︎ ⬛︎ ⬛︎
//MARK: -

//MARK: Private Protocols
//Overlay Config is Passed to Helper Objects as Protocols with only GET functionality to prevent accidental changes
protocol OverlayConfigurationProtocol {
    var zoomedOverlayTranslatesUpwardsProportionallyToTopMargin : Bool {get}
    var modalPresentationCapturesStatusBarAppearance : Bool {get}
    var overlayIsFullScreenWhenNotCustomPresentation : Bool {get}
    var overlayZoomsOutPresentingViewController : Bool {get}
    var fadeInPresentationAndFadeOutDismissal : Bool {get}
    var overlayPresentationStyleIsCustom : Bool {get}
    var zoomOutMultipier : CGFloat {get}
    var cornerRadius : CGFloat {get}
    
    var segue : UIStoryboardSegue? {get}
    var overlay : UIView  {get}
    
    var overlayTopMargin : UInt {get}
    var dragSourceView : UIView? {get}    
}

struct OverlayConfiguration : OverlayConfigurationProtocol {
    
    var overlay : UIView = UIView().setBgColor(OverlayColor)

    var zoomedOverlayTranslatesUpwardsProportionallyToTopMargin = false
    var modalPresentationCapturesStatusBarAppearance = true
    var overlayIsFullScreenWhenNotCustomPresentation = false
    var overlayZoomsOutPresentingViewController = true
    var fadeInPresentationAndFadeOutDismissal = false
    var overlayPresentationStyleIsCustom = true
    var zoomOutMultipier : CGFloat = -1.52
    var cornerRadius : CGFloat = 8
    
    var transistionDirection = TransistionDirection.forwards
    
    var sourceViewController : UIViewController?
    var openSegueIdentifier : String?
    var segue : UIStoryboardSegue?
    
    var overlayTopMargin : UInt = 20
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
let OverlayColor = #colorLiteral(red: 0.03935645978, green: 0.07072254669, blue: 0.1498023435, alpha: 0.2637689917)

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

