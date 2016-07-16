//
//  OverlayableViewController.swift
//  DraggableOverlayView
//
//  Created by アンドレ on 2016/05/02.
//  Copyright © 2016年 Swift. All rights reserved.
//

import UIKit

//Convenience Class for Linking Up and Activating Draggable Overlay
public class OverlayableViewController : UIViewController, OverlayObservering {
    
    @IBOutlet public var draggableOverlayCoordinators : [DraggableSegueCoordinator] = []
    @IBInspectable public var lightStatusBar : Bool = true
    
    override public func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        let matchingSegues = self.matchingSeguesFilter(segue)
        self.draggableOverlayCoordinators.filter(matchingSegues).first?.handle(segue, sender: self, observer: self)
    }
    
    func matchingSeguesFilter(_ segue:UIStoryboardSegue) ->  (DraggableSegueCoordinator) -> Bool {
        return { coordinator in
            if  let coordinatorIdentifier = coordinator.openSegueIdentifier,
                let segueEdentifier = segue.identifier
                where coordinatorIdentifier == segueEdentifier {
                return true
            }
            return false
        }
    }
    
    override public func preferredStatusBarStyle() -> UIStatusBarStyle {
        if true == self.lightStatusBar {
            return UIStatusBarStyle.lightContent
        } else {
            return UIStatusBarStyle.default
        }
    }
    
    private var _draggableView : UIView? = nil
    @IBOutlet override public var viewForDraggedDismissal : UIView? {
        get {
            var theView = self._draggableView
            if nil == theView {
                theView = super.viewForDraggedDismissal
            }
            return theView
        }
        set {
            self._draggableView = newValue
        }
    }
}

public protocol OverlayableViewControllerConvenience {
    func unwindToPrevious(_ unwindSegue : UIStoryboardSegue)
    var viewForDraggedDismissal : UIView? {get set}
}

//Convenience Extension for Presented View Controller to Faitiltate Unwinding and Unwind-Drag
extension UIViewController : OverlayableViewControllerConvenience {
    public func unwindToPrevious(_ unwindSegue : UIStoryboardSegue) {debugPrint(#function)}

    public var viewForDraggedDismissal : UIView? {
        get {
            
            if let headerToolbar = self.navigationController?.navigationBar {
                return headerToolbar
            }
            
            return self.view
        }
        set {}
    }
}
