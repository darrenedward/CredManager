#!/usr/bin/env python3

import hashlib
import base64

def verify_answer_logic():
    """Test the answer verification logic"""
    
    print("=== SECURITY QUESTIONS ANALYSIS ===\n")
    
    # Your security questions and their hashes
    questions = [
        {
            "question": "What is the name of your first pet?",
            "hash": "3de40fbd4249c2dcfaa4428cedc3ad35802b13e668b52f905dfb1f5a636b8930$salt:AmscAoLPjtsZ20-bxyqmFCsCDwJPppvK1x0O-7nSDcw="
        },
        {
            "question": "What is your mother's maiden name?",
            "hash": "e8692c53460b7d5935ab49efe7c72917ab4716685c39f23ddbbc5bcac6a4054c$salt:OcBX7l7iSDmv2-L4ZifHl_tdkYwXMmNds0tMTgRkSug="
        },
        {
            "question": "What is the name of the street you grew up on?",
            "hash": "6843f5394b70d936355d1ce8b2afbaf42b63c0435e28ae36e985f4003c8d753e$salt:hoOhDC5Dcczw0FFc_qe_74xQEAV3zOd5gnne9NC9PFg="
        }
    ]
    
    print("Your security questions are:")
    for i, q in enumerate(questions, 1):
        print(f"{i}. {q['question']}")
        hash_part, salt_part = q['hash'].split('$salt:', 1)
        print(f"   Hash: {hash_part}")
        print(f"   Salt: {salt_part}")
        print()
    
    print("=== HOW TO TEST YOUR ANSWERS ===\n")
    print("1. Think of what you entered for each question")
    print("2. Remember that answers are case-insensitive")
    print("3. Leading/trailing spaces are automatically removed")
    print("4. For each answer, the system:")
    print("   - Converts to lowercase")
    print("   - Trims whitespace") 
    print("   - Adds the salt to the end")
    print("   - Creates SHA-256 hash")
    print("   - Compares to stored hash")
    print()
    
    print("=== TESTING SOME EXAMPLE ANSWERS ===\n")
    
    # Test some common examples for each question
    test_cases = [
        {
            "question": 1,
            "examples": ["fluffy", "max", "buddy", "princess", "charlie", "bella", "rocky"]
        },
        {
            "question": 2, 
            "examples": ["smith", "johnson", "williams", "brown", "jones", "garcia", "miller"]
        },
        {
            "question": 3,
            "examples": ["main street", "oak street", "first street", "maple avenue", "pine road", "elm street"]
        }
    ]
    
    for test_case in test_cases:
        q_num = test_case["question"]
        question_data = questions[q_num - 1]
        
        print(f"Testing Question {q_num}: {question_data['question']}")
        
        for example in test_case["examples"]:
            if test_answer(example, question_data['hash']):
                print(f"  ✓ MATCH FOUND: '{example}' is correct!")
            else:
                print(f"  ✗ '{example}' - not a match")
        print()

def test_answer(answer, stored_hash):
    """Test if an answer matches the stored hash"""
    # Normalize answer (lowercase, trimmed)
    normalized_answer = answer.lower().strip()
    
    # Parse the stored hash
    if '$salt:' not in stored_hash:
        return False
    
    hash_part, salt_part = stored_hash.split('$salt:', 1)
    
    # Create the hash with the answer and salt
    to_hash = normalized_answer + salt_part
    computed_hash = hashlib.sha256(to_hash.encode('utf-8')).hexdigest()
    
    # Compare with the stored hash
    return computed_hash == hash_part

if __name__ == "__main__":
    verify_answer_logic()
