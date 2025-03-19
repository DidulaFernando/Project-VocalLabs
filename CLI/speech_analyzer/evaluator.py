class SpeechEvaluator:
    """Evaluates speech analysis results and provides an overall score and suggestions."""

    def __init__(self):
        # Component names for reporting
        self.component_names = {
            'effectiveness': 'Speech Effectiveness',
            'structure': 'Speech Structure',
            'grammar': 'Grammar & Word Choice',
            'pronunciation': 'Pronunciation',
            'pitch': 'Pitch Control',
            'emphasis': 'Vocal Emphasis',
            'topic_relevance': 'Topic Relevance'
        }

    def calculate_final_score(self, effectiveness_results, structure_results,
                              grammar_results, pronunciation_results, pitch_volume_results,
                              emphasis_results=None, topic_relevance_results=None):
        """Calculate final weighted score based on all analysis components"""
        try:
            # Define component weights (sum = 1.0)
            weights = {
                'effectiveness': 0.16,
                'structure': 0.13,
                'grammar': 0.16,
                'pronunciation': 0.18,
                'pitch': 0.13,
                'emphasis': 0.12,
                'topic_relevance': 0.12
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

            if topic_relevance_results and 'topic_relevance_score' in topic_relevance_results:
                scores['topic_relevance'] = topic_relevance_results['topic_relevance_score']
                self.component_names['topic_relevance'] = 'Topic Relevance'
            else:
                # If no topic relevance, redistribute weights
                weights = {k: v / (1 - weights['topic_relevance'])
                           for k, v in weights.items() if k != 'topic_relevance'}
                weights['topic_relevance'] = 0

            # Calculate weighted final score
            final_score = sum(scores.get(component, 0) * weights.get(component, 0)
                              for component in weights)

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

    def generate_improvement_suggestions(self, final_score_data, effectiveness_results=None, structure_results=None,
                                         grammar_results=None, pronunciation_results=None, pitch_volume_results=None,
                                         time_results=None, number_of_pauses=0, emphasis_results=None,
                                         topic_relevance_results=None):
        """Generate prioritized improvement suggestions based on scores"""
        suggestions = []

        # Get component scores
        scores = final_score_data.get('component_scores', {})

        # Find lowest scoring components (areas to improve)
        components = [(name, scores.get(comp, 50)) for comp, name in self.component_names.items()]
        components.sort(key=lambda x: x[1])  # Sort by score (ascending)

        # Add suggestions based on the lowest scores
        for component_name, score in components[:3]:  # Focus on 3 weakest areas
            if score < 60:
                if component_name == 'Pronunciation' and pronunciation_results:
                    suggestions.append(pronunciation_results.get('feedback', ["Work on clearer pronunciation"])[0])

                elif component_name == 'Grammar & Word Choice' and grammar_results:
                    suggestions.append(grammar_results.get('feedback', ["Improve grammar and word selection"])[0])

                elif component_name == 'Speech Structure' and structure_results:
                    suggestions.append(structure_results.get('feedback', ["Improve speech structure"])[0])

                elif component_name == 'Speech Effectiveness' and effectiveness_results:
                    suggestions.append(effectiveness_results.get('feedback', ["Make your message clearer"])[0])

                elif component_name == 'Pitch Control' and pitch_volume_results:
                    if 'pitch_details' in pitch_volume_results and 'feedback' in pitch_volume_results['pitch_details']:
                        suggestions.append(pitch_volume_results['pitch_details']['feedback'][0])
                    else:
                        suggestions.append("Work on your pitch variation for better engagement")

                elif component_name == 'Vocal Emphasis' and emphasis_results:
                    suggestions.append(emphasis_results.get('feedback', ["Emphasize key points more clearly"])[0])

                elif component_name == 'Topic Relevance' and topic_relevance_results:
                    suggestions.append(topic_relevance_results.get('feedback', ["Stay more focused on your topic"])[0])

        # Add timing-related suggestions if available
        if time_results:
            speaking_rate = time_results.get('speaking_rate', 0)
            if speaking_rate > 4.2:
                suggestions.append("Slow down your speaking pace for better clarity")
            elif speaking_rate < 2.5:
                suggestions.append("Try to speak a bit faster to maintain audience engagement")

            if number_of_pauses > 15 and time_results.get('pause_time', 0) > time_results.get('original_duration', 60) * 0.3:
                suggestions.append("Reduce the number and length of pauses for better flow")
            elif number_of_pauses < 3 and time_results.get('original_duration', 0) > 60:
                suggestions.append("Include more strategic pauses to emphasize important points")

        # If we don't have enough suggestions yet, add general ones based on final score
        if len(suggestions) < 3:
            final_score = final_score_data.get('final_score', 60)
            if final_score < 50:
                suggestions.append("Practice with vocal exercises to improve overall delivery")
                suggestions.append("Record and analyze your speeches regularly to track improvement")
            elif final_score < 70:
                suggestions.append("Join a speaking club or get feedback from peers to refine your skills")

        # Return unique suggestions, limited to 5
        unique_suggestions = list(dict.fromkeys(suggestions))
        return unique_suggestions[:5]

    def format_evaluation_output(self, final_score_data):
        """Format the final evaluation results as a readable string"""
        final_score = final_score_data.get('final_score', 0)
        component_scores = final_score_data.get('component_scores', {})

        # Generate star rating (1-5 stars)
        stars = "★" * (round(final_score/20) or 1)
        stars += "☆" * (5 - (round(final_score/20) or 1))

        # Generate performance level description
        if final_score >= 90:
            performance = "OUTSTANDING"
        elif final_score >= 80:
            performance = "EXCELLENT"
        elif final_score >= 70:
            performance = "VERY GOOD"
        elif final_score >= 60:
            performance = "GOOD"
        elif final_score >= 50:
            performance = "FAIR"
        elif final_score >= 40:
            performance = "NEEDS IMPROVEMENT"
        else:
            performance = "SIGNIFICANT IMPROVEMENT NEEDED"

        # Create formatted output
        output = [
            "\n" + "="*50,
            f"\n  SPEECH EVALUATION SCORE: {final_score}/100  {stars}",
            f"\n  PERFORMANCE LEVEL: {performance}",
            "\n" + "="*50,
            "\n\nComponent Scores:"
        ]

        # Add component scores
        for component, name in self.component_names.items():
            if component in component_scores:
                output.append(f"  - {name}: {component_scores[component]}/100")

        return "\n".join(output)