#!/usr/bin/env python3

import hashlib
import sys

def flutter_legacy_hash(text, salt):
    """Replicate the Flutter _hashPassphraseLegacy function"""
    to_hash = text + salt
    digest = hashlib.sha256(to_hash.encode('utf-8')).hexdigest()
    return f"{digest}$salt:{salt}"

def flutter_verify_answer(answer, stored_hash):
    """Replicate the Flutter _verifyAnswerCaseInsensitive function logic"""
    normalized = answer.lower().strip()
    
    if '$salt:' not in stored_hash:
        return False
    
    parts = stored_hash.split('$salt:')
    if len(parts) != 2:
        return False
    
    salt = parts[1]
    computed_hash = flutter_legacy_hash(normalized, salt)
    return computed_hash == stored_hash

def main():
    print("=== INTERACTIVE SECURITY QUESTIONS TESTER ===\n")
    
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
    
    correct_answers = 0
    
    for i, q in enumerate(questions, 1):
        print(f"Question {i}: {q['question']}")
        
        while True:
            answer = input("Enter your answer (or 'skip' to move to next): ").strip()
            
            if answer.lower() == 'skip':
                print("Skipped this question.\n")
                break
            
            if not answer:
                print("Please enter an answer or 'skip'.")
                continue
            
            if flutter_verify_answer(answer, q['hash']):
                print(f"✓ CORRECT! '{answer}' matches this question.\n")
                correct_answers += 1
                break
            else:
                print(f"✗ '{answer}' does not match. Try again or 'skip'.")
    
    print(f"=== RESULTS ===")
    print(f"Correct answers: {correct_answers} out of {len(questions)}")
    
    if correct_answers == len(questions):
        print("\n🎉 All answers correct! Your recovery should work in the app.")
    elif correct_answers > 0:
        print(f"\n✓ You got {correct_answers} correct. The app requires all answers to be correct for recovery.")
    else:
        print("\n❌ No correct answers found. There might be an issue with:")
        print("   - How you're remembering the answers")
        print("   - How the answers were originally stored")
        print("   - The verification logic in the app")
    
    print("\n=== WHAT TO DO NEXT ===")
    if correct_answers == len(questions):
        print("Try using these exact answers in the app's recovery process.")
    else:
        print("Try these suggestions:")
        print("1. Think of variations of your answers (nicknames, full names, etc.)")
        print("2. Consider if you used special characters or numbers")
        print("3. Check if you might have made typos during setup")
        print("4. Consider if the questions might have been answered differently than expected")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nTesting interrupted.")
    except EOFError:
        print("\n\nInput ended.")
