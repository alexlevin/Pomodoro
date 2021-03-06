//
//  PomodoroTimer.swift
//  Pomodoro
//
//  Created by Chelsea Valentine on 10/17/16.
//  Copyright © 2016 Chelsea Valentine. All rights reserved.
//

import Foundation
import Cocoa

class PomodoroTimer {
    private var view: PomodoroScreenProtocol!
    
    private var textField: NSTextField!
    private var currentCount: Int
    private var totalCount: Int
    
    private var timer: NSTimer?
    private var isActive = false
    
    init(view: PomodoroScreenProtocol, textField: NSTextField, currentCount: Int, totalCount: Int) {
        self.view = view
        self.textField = textField
        self.currentCount = currentCount
        self.totalCount = totalCount
    }
    
    deinit {
        // Save incomplete session
        if currentCount > 0 {
            let context = DataManager.getContext()!
            context.count = currentCount
            DataManager.saveManagedContext()
        }
    }
    
    func start() {

        if isActive {
            // Stop the timer
            let timerWasJustStarted = currentCount != totalCount - 1
            
            if timer == nil && timerWasJustStarted {
                return
            }
            
            stopTimer()
            view.setPausedMode()
        } else {
            // Start the timer
            startTimer()
            
            // It's not the first time starting this session
            if currentCount != totalCount {
                return
            }
            
            if !view.isBreakView() {
                initializeSession()
            }
        }
    }
    
    func isRunning() -> Bool {
        return isActive
    }
    
    func count() -> Int {
        return currentCount
    }
    
    private func initializeSession() {
        let context = DataManager.getContext()!
        let session = context.sessionRelationship
        
        session.started = NSDate()
        session.modeRelationship = context.modeRelationship
        
        DataManager.saveManagedContext()
    }
    
    private func startTimer() {
        timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(PomodoroTimer.updateTimer), userInfo: nil, repeats: true)
        
        isActive = true
        view.setRunningMode()
    }
    
    @objc private func updateTimer() {
        if currentCount > 0 {
            // Decrement the timer
            currentCount -= 1
            textField.stringValue = TimeHelper.toTimeString(currentCount)
            
            let progressPercentage: Double = Double(totalCount - currentCount) / Double(totalCount)
            view.updateProgressBar(progressPercentage)
        } else {
            // Stop the timer
            stopTimer()
            view.setStoppedMode()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        isActive = false
        
        view.setPausedMode()
        
        // Save paused times
        if currentCount != 0 {
            let context = DataManager.getContext()
            let session = context?.sessionRelationship
            
            session?.numPausedTimes = (session?.numPausedTimes as! Int) + 1
            context!.count = currentCount
            
            DataManager.saveManagedContext()
        }
    }
}