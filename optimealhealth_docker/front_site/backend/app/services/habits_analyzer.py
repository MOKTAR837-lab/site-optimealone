class HabitsAnalyzer:
    @staticmethod
    def analyze_habits(data: dict) -> dict:
        score = 70
        strengths = []
        improvements = []
        
        if data.get("water_intake_liters", 0) >= 2.0:
            strengths.append("Bonne hydratation")
            score += 5
        else:
            improvements.append("Augmenter hydratation")
        
        return {
            "diet_score": score,
            "strengths": strengths,
            "improvements": improvements,
            "personalized_tips": ["Conseil 1", "Conseil 2"],
            "risk_factors": []
        }
