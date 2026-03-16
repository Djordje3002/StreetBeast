// StreakResponse.swift
import Foundation

struct StreakResponse: Codable, Equatable {
    let currentStreak: Int
    let longestStreak: Int
    // ISO8601 string date from backend; optional when no collections yet.
    let lastCollectionDate: String?
    let totalCollections: Int
}
