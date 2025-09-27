//
//  ModernToneEngine.swift
//  Snail Maze like2
//
//  Created by Williams SAADI on 22/09/2025.
//

import Foundation
import AVFoundation

final class ModernToneEngine: ObservableObject {
    private let engine = AVAudioEngine()
    private var kickNode: AVAudioSourceNode!
    private var hatNode: AVAudioSourceNode!
    private var leadNode: AVAudioSourceNode!
    
    private let sampleRate: Double = 44100
    private let twoPi = 2.0 * Double.pi
    
    private struct EnvState {
        var active = false
        var startTime: CFAbsoluteTime = 0
        var attack: Double = 0.005
        var decay: Double = 0.12
        var sustain: Double = 0.0
        var release: Double = 0.08
        var gate: Bool = false
        
        mutating func trigger(now: CFAbsoluteTime) { active = true; startTime = now; gate = true }
        mutating func releaseGate(now: CFAbsoluteTime) { gate = false; startTime = now }
        
        func amp(now: CFAbsoluteTime) -> Double {
            guard active else { return 0 }
            let t = now - startTime
            if gate {
                if t < attack { return t/attack }
                return max(sustain, exp(-(t-attack)/decay))
            } else {
                return max(0, exp(-t/release))
            }
        }
    }
    
    // Kick
    private var kickPhase = 0.0
    private var kickFreq0 = 110.0
    private var kickEnv = EnvState(attack: 0.002, decay: 0.12, sustain: 0.0, release: 0.06)
    private var kickPitchDrop = 0.004
    
    // Hat
    private var hatEnv = EnvState(attack: 0.001, decay: 0.05, sustain: 0.0, release: 0.03)
    private var hatLast: Double = 0.0
    
    // Lead
    private var leadPhase = 0.0
    private var leadFreq = 440.0
    private var leadEnv = EnvState(attack: 0.004, decay: 0.12, sustain: 0.15, release: 0.06)
    
    // Mix volumes
    private var masterKick: Double = 0.50
    private var masterHat: Double = 0.20
    private var masterLead: Double = 0.20
    
    // Urgency
    private var urgTimer: Timer?
    private var sixteenthSec: Double = 0.25
    private var stepIndex = 0
    private var lastTimeLeft: Double = 0.0
    
    init() {
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setCategory(.soloAmbient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { 
            print("AudioSession error:", error) 
        }
        #endif
        
        // Kick Node
        kickNode = AVAudioSourceNode { [weak self] _, _, frameCount, abl in
            guard let self = self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(abl)
            let now = CFAbsoluteTimeGetCurrent()
            
            for f in 0..<Int(frameCount) {
                let t = now - self.kickEnv.startTime
                let freq = max(40.0, self.kickFreq0 * exp(-self.kickPitchDrop * max(0, t)))
                self.kickPhase += self.twoPi * freq / self.sampleRate
                if self.kickPhase > self.twoPi { self.kickPhase -= self.twoPi }
                
                let tri = 2.0 * abs((self.kickPhase / self.twoPi).truncatingRemainder(dividingBy: 1.0) - 0.5) - 1.0
                let amp = self.kickEnv.amp(now: now) * self.masterKick
                let s = Float(tri * amp)
                
                for b in buffers {
                    b.mData!.assumingMemoryBound(to: Float.self)[f] = s
                }
            }
            return noErr
        }
        
        // Hat Node
        hatNode = AVAudioSourceNode { [weak self] _, _, frameCount, abl in
            guard let self = self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(abl)
            let now = CFAbsoluteTimeGetCurrent()
            
            for f in 0..<Int(frameCount) {
                let noise = Double.random(in: -1.0...1.0)
                let amp = self.hatEnv.amp(now: now) * self.masterHat
                let s = Float(noise * amp)
                
                for b in buffers {
                    b.mData!.assumingMemoryBound(to: Float.self)[f] = s
                }
            }
            return noErr
        }
        
        // Lead Node
        leadNode = AVAudioSourceNode { [weak self] _, _, frameCount, abl in
            guard let self = self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(abl)
            let now = CFAbsoluteTimeGetCurrent()
            
            for f in 0..<Int(frameCount) {
                self.leadPhase += self.twoPi * self.leadFreq / self.sampleRate
                if self.leadPhase > self.twoPi { self.leadPhase -= self.twoPi }
                
                let sine = sin(self.leadPhase)
                let amp = self.leadEnv.amp(now: now) * self.masterLead
                let s = Float(sine * amp)
                
                for b in buffers {
                    b.mData!.assumingMemoryBound(to: Float.self)[f] = s
                }
            }
            return noErr
        }
        
        // Setup audio routing
        engine.attach(kickNode)
        engine.attach(hatNode)
        engine.attach(leadNode)
        
        let mix = engine.mainMixerNode
        let fmt = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        
        engine.connect(kickNode, to: mix, format: fmt)
        engine.connect(hatNode, to: mix, format: fmt)
        engine.connect(leadNode, to: mix, format: fmt)
        
        mix.outputVolume = 1.0
        engine.prepare()
        
        do { 
            try engine.start() 
        } catch { 
            print("Engine start error:", error) 
        }
    }
    
    // Public API
    func successJingle() {
        trigLead(freq: 880, dur: 0.12, vel: 0.35)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) { 
            self.trigLead(freq: 1320, dur: 0.18, vel: 0.35) 
        }
    }
    
    func timeoutBuzz() {
        trigKick(freq: 80)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { 
            self.trigKick(freq: 60) 
        }
    }
    
    func updateUrgency(timeLeft: Double) {
        lastTimeLeft = timeLeft
        setIntensity(for: timeLeft)
        let should = timeLeft > 0
        
        if should && urgTimer == nil {
            scheduleUrgLoop(timeLeft: timeLeft)
        } else if should, let t = urgTimer {
            let newInt = stepInterval(for: timeLeft)
            if abs(t.timeInterval - newInt) > 0.01 { 
                t.invalidate()
                urgTimer = nil
                scheduleUrgLoop(timeLeft: timeLeft) 
            }
        } else if !should {
            urgTimer?.invalidate()
            urgTimer = nil
        }
    }
    
    // Private methods
    private func scheduleUrgLoop(timeLeft: Double) {
        sixteenthSec = stepInterval(for: timeLeft)
        stepIndex = 0
        urgTimer = Timer.scheduledTimer(withTimeInterval: sixteenthSec, repeats: true) { [weak self] _ in
            self?.urgStep()
        }
        if let urgTimer = urgTimer {
            RunLoop.main.add(urgTimer, forMode: .common)
        }
    }
    
//    private func stepInterval(for timeLeft: Double) -> Double {
//        let maxSpan = 120.0
//        let clamped = min(maxSpan, max(0.0, timeLeft))
//        let t = 1.0 - (clamped / maxSpan)
//        let bpmStart = 90.0, bpmMid = 120.0, bpmEnd = 160.0
//        
//        let bpm = (t < 0.5)
//            ? bpmStart + (bpmMid - bpmStart) * (t / 0.5)
//            : bpmMid + (bpmEnd - bpmMid) * ((t - 0.5) / 0.5)
//        
//        return 60.0 / (bpm * 4.0)
//    }
    
    private func stepInterval(for timeLeft: Double) -> Double {
        // Tempo calme tant qu'il reste plus de 10s
        var bpm = 100.0

        if timeLeft <= 10 {
            // Phase "stress" entre 10s et 3s incluses → de 120 à 150 BPM
            if timeLeft > 3 {
                let t = (10 - timeLeft) / 7.0   // progresse de 0 à 1 entre 10 → 3
                bpm = 120 + t * (150 - 120)
            } else {
                // Phase "urgence" ≤ 3s → de 150 à 180 BPM
                let t = (3 - timeLeft) / 3.0    // progresse de 0 à 1 entre 3 → 0
                bpm = 150 + t * (180 - 150)
            }
        }

        // Conversion BPM → intervalle (1/16 de note)
        return 60.0 / (bpm * 4.0)
    }

    
    private func setIntensity(for timeLeft: Double) {
        let hi = 60.0, lo = 5.0
        let x = min(1.0, max(0.0, (hi - timeLeft) / (hi - lo)))
        let k = x * x * (3 - 2 * x)
        
        masterKick = 0.35 + 0.45 * k
        masterHat = 0.10 + 0.25 * k
        masterLead = 0.10 + 0.30 * k
    }
    
    private func urgStep() {
        let beat = stepIndex % 16
        
        if beat % 4 == 0 { trigKick(freq: 55) }
        if beat % 4 == 2 { trigHat() }
        
        let arp: [Double] = [440.0, 523.25, 659.25, 783.99, 880.0]
        let base = arp[(beat/2) % arp.count]
        let span: Double = 15.0
        let semitones = max(0.0, min(7.0, (span - min(span, lastTimeLeft)) * (7.0/span)))
        let factor = pow(2.0, semitones/12.0)
        
        trigLead(freq: base * factor, dur: 0.08, vel: masterLead)
        stepIndex += 1
    }
    
    private func trigKick(freq: Double) {
        kickFreq0 = freq
        kickEnv.trigger(now: CFAbsoluteTimeGetCurrent())
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { [weak self] in
            self?.kickEnv.releaseGate(now: CFAbsoluteTimeGetCurrent())
        }
    }
    
    private func trigHat() {
        hatEnv.trigger(now: CFAbsoluteTimeGetCurrent())
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            self?.hatEnv.releaseGate(now: CFAbsoluteTimeGetCurrent())
        }
    }
    
    private func trigLead(freq: Double, dur: Double, vel: Double) {
        leadFreq = freq
        leadEnv.trigger(now: CFAbsoluteTimeGetCurrent())
        DispatchQueue.main.asyncAfter(deadline: .now() + dur) { [weak self] in
            self?.leadEnv.releaseGate(now: CFAbsoluteTimeGetCurrent())
        }
    }
}
