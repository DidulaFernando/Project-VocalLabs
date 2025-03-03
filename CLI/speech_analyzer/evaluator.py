import numpy as np

class SpeechEvaluator:
    """Handles speech evaluation, scoring, and feedback generation"""

    def __init__(self):
        self.component_names = {
            'effectiveness': 'Speech Effectiveness',
            'structure': 'Speech Structure',
            'grammar': 'Grammar & Word Choice',
            'pronunciation': 'Pronunciation',
            'pitch': 'Pitch & Volume',
            'emphasis': 'Speech Emphasis'
        }

    def calculate_final_score(self, effectiveness_results, structure_results,
                              grammar_results, pronunciation_results, pitch_volume_results,
                              emphasis_results=None):
        """Calculate final weighted score based on all analysis components"""
        try:
            # Define component weights (sum = 1.0)
            weights = {
                'effectiveness': 0.18,
                'structure': 0.15,
                'grammar': 0.18,
                'pronunciation': 0.20,
                'pitch': 0.15,
                'emphasis': 0.14
            }

            scores = {}

            # Get scores from each component (with validation)
            if effectiveness_results and 'effectiveness_score' in effectiveness_results:
                scores['effectiveness'] = effectiveness_results['effectiveness_score']
            else:
                scores['effectiveness'] = 50  # Default score if missing

            if structure_results and 'structure_score' in structure_results:
                scores['structure'] = structure_results['structure_score']
            else:
                scores['structure'] = 50

            if grammar_results and 'combined_score' in grammar_results:
                scores['grammar'] = grammar_results['combined_score']
            else:
                scores['grammar'] = 50

            if pronunciation_results and 'pronunciation_score' in pronunciation_results:
                scores['pronunciation'] = pronunciation_results['pronunciation_score']
            else:
                scores['pronunciation'] = 50

            if pitch_volume_results and 'pitch_analysis' in pitch_volume_results:
                scores['pitch'] = pitch_volume_results['pitch_analysis'].get('pitch_score', 50)
            else:
                scores['pitch'] = 50

            if emphasis_results and 'emphasis_score' in emphasis_results:
                scores['emphasis'] = emphasis_results['emphasis_score']
            else:
                scores['emphasis'] = 50

            # Calculate weighted final score
            final_score = sum(scores[component] * weights[component] for component in weights)

            # Round to nearest integer
            final_score = round(final_score)

            # Return both final score and component scores for detailed feedback
            return {
                'final_score': final_score,
                'component_scores': scores
            }

        except Exception as e:
            print(f"Error calculating final score: {e}")
            return {'final_score': 60, 'component_scores': {}}  # Default score on error

    def generate_improvement_suggestions(self, score_data, effectiveness_results, structure_results,
                                         grammar_results, pronunciation_results, pitch_volume_results,
                                         time_results, num_pauses=0, emphasis_results=None):
        """Generate prioritized suggestions based on scores and analysis"""
        try:
            suggestions = []
            component_scores = score_data.get('component_scores', {})
            final_score = score_data.get('final_score', 60)

            # Add overall assessment based on final score
            if final_score >= 90:
                suggestions.append("Overall: Outstanding speech performance! You excel in most areas of public speaking.")
            elif final_score >= 80:
                suggestions.append("Overall: Excellent speech delivery with a few minor areas for improvement.")
            elif final_score >= 70:
                suggestions.append("Overall: Very good speech with several strengths and some specific areas to refine.")
            elif final_score >= 60:
                suggestions.append("Overall: Good speech with clear strengths but also important areas that need attention.")
            elif final_score >= 50:
                suggestions.append("Overall: Fair speech with balanced strengths and weaknesses that need improvement.")
            else:
                suggestions.append("Overall: This speech needs significant improvement in several key areas.")

            # Find weakest areas (lowest scoring components)
            sorted_components = sorted(component_scores.items(), key=lambda x: x[1])
            weakest_areas = sorted_components[:2]  # Get 2 weakest areas

            # Add specific suggestions for the weakest areas
            for area, score in weakest_areas:
                if area == 'effectiveness' and effectiveness_results:
                    if score < 60:
                        suggestions.append("Priority: Improve speech effectiveness by clearly stating your purpose at the beginning and providing a strong conclusion.")

                elif area == 'structure' and structure_results:
                    if score < 60:
                        suggestions.append("Priority: Work on speech structure by organizing content with clear introduction, body, and conclusion. Use transitions between main points.")

                elif area == 'grammar' and grammar_results:
                    if score < 60:
                        suggestions.append("Priority: Focus on grammar and word choice. Reduce repetitive words and incorporate more varied vocabulary.")

                elif area == 'pronunciation' and pronunciation_results:
                    if score < 60:
                        suggestions.append("Priority: Practice pronunciation clarity and articulation, especially with challenging sounds.")

                elif area == 'pitch' and pitch_volume_results:
                    if score < 60:
                        gender = pitch_volume_results['pitch_range']['detected_gender']
                        suggestions.append(f"Priority: Work on maintaining your pitch within the ideal {gender} range. Practice vocal exercises to improve pitch control.")

                elif area == 'emphasis' and emphasis_results:
                    if score < 60:
                        suggestions.append("Priority: Improve your use of vocal emphasis to highlight key points. Vary your tone to stress important concepts.")

            # Add specific feedback for time management if available
            if time_results:
                speaking_rate = time_results.get('speaking_rate', 0)
                if speaking_rate > 4:
                    suggestions.append("Consider slowing down your speaking rate to improve clarity and audience comprehension.")
                elif speaking_rate < 2:
                    suggestions.append("Try increasing your speaking pace slightly to maintain audience engagement.")

                pause_time = time_results.get('pause_time', 0)
                total_time = time_results.get('original_duration', 0)
                if total_time > 0 and pause_time / total_time > 0.3:
                    suggestions.append("Reduce excessive pausing to maintain flow and audience engagement.")
                elif total_time > 0 and pause_time / total_time < 0.05:
                    suggestions.append("Incorporate more strategic pauses to emphasize key points and give listeners time to process.")

            # Add filler word advice if significant
            if num_pauses is not None:
                # Count pauses per minute
                audio_duration_minutes = time_results.get('original_duration', 60) / 60 if time_results else 1
                pause_rate = num_pauses / audio_duration_minutes

                if pause_rate > 5:
                    suggestions.append("Work on reducing filler words and unnecessary pauses to sound more confident and articulate.")

            # Add emphasis-specific suggestions if appropriate
            if emphasis_results:
                emphasis_coverage = emphasis_results.get('emphasis_coverage', 0)
                if emphasis_coverage < 30 and 'emphasis' not in [area for area, _ in weakest_areas]:
                    suggestions.append("Try to emphasize more of your key points through vocal variation and strategic pauses.")

                emphasis_density = emphasis_results.get('emphasis_density_per_minute', 0)
                if emphasis_density > 10:
                    suggestions.append("Be selective with emphasis - too many emphasized points can dilute their impact.")

            # Add specific practice suggestions if score is below threshold
            if final_score < 70:
                suggestions.append("Practice Tip: Record yourself regularly and analyze your speeches to track improvement in your weakest areas.")

            if len(suggestions) > 6:  # Limit to most important suggestions
                suggestions = suggestions[:6]

            return suggestions

        except Exception as e:
            print(f"Error generating improvement suggestions: {e}")
            return ["Focus on improving your overall speech delivery and practice regularly."]

    def format_evaluation_output(self, final_score_data):
        """Format the component scores for display"""
        output = []
        output.append("\n" + "="*50)
        output.append("=== FINAL SPEECH EVALUATION ===")
        output.append(f"Overall Score: {final_score_data['final_score']}/100")

        output.append("\nComponent Scores:")
        for component, score in final_score_data.get('component_scores', {}).items():
            if component in self.component_names:
                output.append(f"  - {self.component_names[component]}: {score}/100")

        return "\n".join(output)