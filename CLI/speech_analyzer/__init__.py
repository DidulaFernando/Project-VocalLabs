# Import necessary modules to make them available when importing the package
from .core import SpeechAnalyzer
from .evaluator import SpeechEvaluator

# Ensure all required NLTK downloads are available
import nltk
try:
    nltk.download('punkt')
except:
    pass