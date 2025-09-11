#!/usr/bin/env python3

import hashlib

def flutter_legacy_hash(text, salt):
    """Replicate the Flutter _hashPassphraseLegacy function"""
    to_hash = text + salt
    digest = hashlib.sha256(to_hash.encode('utf-8')).hexdigest()
    return f"{digest}$salt:{salt}"

def test_user_answers():
    print("=== TESTING YOUR ACTUAL ANSWERS ===\n")
    
    questions = [
        {
            "question": "What is the name of your first pet?",
            "hash": "3de40fbd4249c2dcfaa4428cedc3ad35802b13e668b52f905dfb1f5a636b8930$salt:AmscAoLPjtsZ20-bxyqmFCsCDwJPppvK1x0O-7nSDcw=",
            "your_answer": "gismo"
        },
        {
            "question": "What is your mother's maiden name?",
            "hash": "e8692c53460b7d5935ab49efe7c72917ab4716685c39f23ddbbc5bcac6a4054c$salt:OcBX7l7iSDmv2-L4ZifHl_tdkYwXMmNds0tMTgRkSug=",
            "your_answer": "lister"
        },
        {
            "question": "What is the name of the street you grew up on?",
            "hash": "6843f5394b70d936355d1ce8b2afbaf42b63c0435e28ae36e985f4003c8d753e$salt:hoOhDC5Dcczw0FFc_qe_74xQEAV3zOd5gnne9NC9PFg=",
            "your_answer": "westminister"
        }
    ]
    
    all_correct = True
    
    for i, q in enumerate(questions, 1):
        print(f"Question {i}: {q['question']}")
        print(f"Your answer: '{q['your_answer']}'")
        
        # Test the answer
        normalized = q['your_answer'].lower().strip()
        print(f"Normalized: '{normalized}'")
        
        parts = q['hash'].split('$salt:')
        if len(parts) != 2:
            print(f"  ✗ ERROR: Invalid hash format")
            all_correct = False
            continue
            
        expected_hash = parts[0]
        salt = parts[1]
        
        print(f"Salt: {salt}")
        
        computed = flutter_legacy_hash(normalized, salt)
        computed_hash = computed.split('$salt:')[0]
        
        print(f"Expected hash: {expected_hash}")
        print(f"Computed hash: {computed_hash}")
        
        if computed == q['hash']:
            print(f"  ✓ CORRECT! This answer matches.")
        else:
            print(f"  ✗ INCORRECT! This answer does not match.")
            all_correct = False
            
            # Try some variations
            variations = [
                q['your_answer'],  # original
                q['your_answer'].lower(),
                q['your_answer'].upper(),
                q['your_answer'].strip(),
                q['your_answer'].lower().strip(),
            ]
            
            # For the street, try with and without "street"
            if i == 3:
                variations.extend([
                    q['your_answer'] + " street",
                    q['your_answer'] + " st",
                    q['your_answer'].replace("street", "").strip(),
                    q['your_answer'].replace("st", "").strip(),
                ])
            
            print(f"  Testing variations:")
            for var in set(variations):  # Remove duplicates
                var_normalized = var.lower().strip()
                var_computed = flutter_legacy_hash(var_normalized, salt)
                if var_computed == q['hash']:
                    print(f"    ✓ FOUND MATCH: '{var}' works!")
                    all_correct = True
                    break
                else:
                    print(f"    ✗ '{var}' - no match")
        
        print()
    
    print("="*50)
    if all_correct:
        print("✓ All answers are correct! The app should accept these.")
    else:
        print("✗ Some answers don't match. There might be an issue with:")
        print("  - The verification logic in the app")
        print("  - How the answers were originally stored")
        print("  - Spelling variations you might have used")

if __name__ == "__main__":
    test_user_answers()
