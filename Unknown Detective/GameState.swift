//
//  GameState.swift
//  Unknown Detective
//
//  Created by GitHub Copilot on 17.10.2025.
//

import Foundation
import Combine

@MainActor
final class GameState: ObservableObject {
    @Published private(set) var energy: Int
    @Published private(set) var maxEnergy: Int
    @Published private(set) var hintCredits: Int
    @Published private(set) var hasDetectivePlus: Bool

    let dailyEnergyAllowance: Int
    let dailyHintAllowance: Int

    private let defaults: UserDefaults
    private let calendar: Calendar
    private let energyKey = "GameState.energy"
    private let refillKey = "GameState.lastRefill"
    private let maxEnergyKey = "GameState.maxEnergy"
    private let hintKey = "GameState.hintCredits"
    private let detectivePlusKey = "GameState.detectivePlus"
    private var lastRefill: Date

    init(initialMaxEnergy: Int = 10, dailyEnergyAllowance: Int = 3, dailyHintAllowance: Int = 1, defaults: UserDefaults = .standard, calendar: Calendar = .current, now: Date = Date()) {
        self.defaults = defaults
        self.calendar = calendar
        let persistedMaxEnergy = defaults.object(forKey: maxEnergyKey) as? Int
        let resolvedMaxEnergy = max(persistedMaxEnergy ?? initialMaxEnergy, 1)

        self.maxEnergy = resolvedMaxEnergy
        self.dailyEnergyAllowance = min(resolvedMaxEnergy, max(dailyEnergyAllowance, 0))
        self.dailyHintAllowance = max(dailyHintAllowance, 0)
        self.hasDetectivePlus = defaults.bool(forKey: detectivePlusKey)

        let storedHintCredits = defaults.object(forKey: hintKey) as? Int

        if let storedEnergy = defaults.object(forKey: energyKey) as? Int,
           let storedRefill = defaults.object(forKey: refillKey) as? Date {
            let clampedEnergy = max(storedEnergy, 0)
            let clampedHints = max(storedHintCredits ?? self.dailyHintAllowance, 0)
            if calendar.isDate(now, inSameDayAs: storedRefill) {
                energy = clampedEnergy
                hintCredits = clampedHints
                lastRefill = storedRefill
            } else {
                energy = max(clampedEnergy, self.dailyEnergyAllowance)
                hintCredits = max(clampedHints, self.dailyHintAllowance)
                lastRefill = now
                persistState()
            }
        } else {
            energy = self.dailyEnergyAllowance
            hintCredits = max(storedHintCredits ?? self.dailyHintAllowance, self.dailyHintAllowance)
            lastRefill = now
            persistState()
        }
    }

    func consumeEnergy(for caseType: CaseType, now: Date = Date()) -> Bool {
        refillIfNeeded(at: now)
        let cost = caseType.energyCost
        guard energy >= cost else { return false }
        energy -= cost
        persistState()
        return true
    }

    func consumeEnergy(points: Int, now: Date = Date()) -> Bool {
        refillIfNeeded(at: now)
        guard points > 0, energy >= points else { return false }
        energy -= points
        persistState()
        return true
    }

    func addEnergy(_ amount: Int, allowOverflow: Bool = false, now: Date = Date()) {
        refillIfNeeded(at: now)
        let addition = max(0, amount)
        if allowOverflow {
            energy += addition
            if energy > maxEnergy {
                maxEnergy = energy
            }
        } else {
            energy = min(maxEnergy, energy + addition)
        }
        persistState()
    }

    func refillNow(at date: Date = Date()) {
        energy = max(energy, maxEnergy)
        hintCredits = max(hintCredits, dailyHintAllowance)
        lastRefill = date
        persistState()
    }

    @discardableResult
    func consumeHintCredit(now: Date = Date()) -> Bool {
        refillIfNeeded(at: now)
        if hasDetectivePlus { return true }
        guard hintCredits > 0 else { return false }
        hintCredits -= 1
        persistState()
        return true
    }

    func addHintCredits(_ amount: Int, now: Date = Date()) {
        refillIfNeeded(at: now)
        hintCredits += max(0, amount)
        persistState()
    }

    func activateDetectivePlus() {
        hasDetectivePlus = true
        persistState()
    }

    func increaseMaxEnergy(by amount: Int) {
        guard amount > 0 else { return }
        maxEnergy += amount
        persistState()
    }

    private func refillIfNeeded(at date: Date) {
        guard !calendar.isDate(date, inSameDayAs: lastRefill) else { return }
        energy = max(energy, dailyEnergyAllowance)
        hintCredits = max(hintCredits, dailyHintAllowance)
        lastRefill = date
        persistState()
    }

    private func persistState() {
        defaults.set(energy, forKey: energyKey)
        defaults.set(lastRefill, forKey: refillKey)
        defaults.set(maxEnergy, forKey: maxEnergyKey)
        defaults.set(hintCredits, forKey: hintKey)
        defaults.set(hasDetectivePlus, forKey: detectivePlusKey)
    }
}
