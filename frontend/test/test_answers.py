#!/usr/bin/env python3

import hashlib
import base64

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

def main():
    print("=== SECURITY QUESTIONS ANSWER TESTER ===\n")
    
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
    
    for i, q in enumerate(questions, 1):
        print(f"Question {i}: {q['question']}")
        answer = input("Enter your answer: ")
        
        if test_answer(answer, q['hash']):
            print("✓ CORRECT! This answer matches.\n")
        else:
            print("✗ INCORRECT. This answer does not match.\n")
    
    print("Note: Answers are compared case-insensitive with leading/trailing spaces removed.")
    print("If none of your answers work, there might be an issue with the hashing process.")

if __name__ == "__main__":
    main()
