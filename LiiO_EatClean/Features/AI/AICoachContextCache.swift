import Foundation
import SwiftUI

@Observable
class AICoachContextCache {
    static let shared = AICoachContextCache()
    
    // Cache entries using generic Wrapper for timestamp checking
    struct CacheEntry<T> {
        let data: T
        let timestamp: Date
    }
    
    var todayMealLogsCache: CacheEntry<[AICoachContextSnapshot.ActualMealLog]>?
    var todayPlanCache: CacheEntry<AICoachContextSnapshot.DailyPlanSummary?>?
    var profileCache: CacheEntry<AICoachContextSnapshot.ProfileSummary>?
    var metabolicCache: CacheEntry<AICoachContextSnapshot.MetabolicSummary>?
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        let nc = NotificationCenter.default
        
        nc.addObserver(forName: NSNotification.Name("mealLogDidUpdate"), object: nil, queue: .main) { [weak self] _ in
            self?.invalidateTodayNutrition()
        }
        
        nc.addObserver(forName: NSNotification.Name("mealPlanDidUpdate"), object: nil, queue: .main) { [weak self] _ in
            self?.invalidateTodayPlan()
        }
        
        nc.addObserver(forName: NSNotification.Name("dailyPlanDidConfirm"), object: nil, queue: .main) { [weak self] _ in
            self?.invalidateTodayPlan()
        }
        
        nc.addObserver(forName: NSNotification.Name("userProfileDidUpdate"), object: nil, queue: .main) { [weak self] _ in
            self?.invalidateProfile()
        }
        
        nc.addObserver(forName: NSNotification.Name("weightDidUpdate"), object: nil, queue: .main) { [weak self] _ in
            self?.invalidateProfile()
            self?.invalidateMetabolic()
        }
    }
    
    func invalidateTodayNutrition() {
        todayMealLogsCache = nil
    }
    
    func invalidateTodayPlan() {
        todayPlanCache = nil
    }
    
    func invalidateProfile() {
        profileCache = nil
    }
    
    func invalidateMetabolic() {
        metabolicCache = nil
    }
    
    func clearAll() {
        todayMealLogsCache = nil
        todayPlanCache = nil
        profileCache = nil
        metabolicCache = nil
    }
    
    // Helper functions to fetch safely with TTL
    func getTodayLogs(ttl: TimeInterval = 30) -> [AICoachContextSnapshot.ActualMealLog]? {
        guard let entry = todayMealLogsCache, Date().timeIntervalSince(entry.timestamp) < ttl else { return nil }
        return entry.data
    }
    
    func getTodayPlan(ttl: TimeInterval = 30) -> AICoachContextSnapshot.DailyPlanSummary?? {
        guard let entry = todayPlanCache, Date().timeIntervalSince(entry.timestamp) < ttl else { return nil }
        return entry.data
    }
    
    func getProfile(ttl: TimeInterval = 300) -> AICoachContextSnapshot.ProfileSummary? {
        guard let entry = profileCache, Date().timeIntervalSince(entry.timestamp) < ttl else { return nil }
        return entry.data
    }
    
    func getMetabolic(ttl: TimeInterval = 600) -> AICoachContextSnapshot.MetabolicSummary? {
        guard let entry = metabolicCache, Date().timeIntervalSince(entry.timestamp) < ttl else { return nil }
        return entry.data
    }
}
