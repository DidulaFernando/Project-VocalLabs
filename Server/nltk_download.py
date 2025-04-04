import nltk

def download_nltk_resources():
    """Download required NLTK resources."""
    resources = [
        'punkt',
        'stopwords',
        'wordnet',
        'averaged_perceptron_tagger_eng'   
    ]
    
    for resource in resources:
        try:
            nltk.download(resource, quiet=True)
            print(f"Downloaded NLTK resource: {resource}")
        except Exception as e:
            print(f"Error downloading {resource}: {str(e)}")

if __name__ == "__main__":
    download_nltk_resources()
