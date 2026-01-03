#!/usr/bin/env python3

import hashlib

def flutter_legacy_hash(text, salt):
    """Replicate the Flutter _hashPassphraseLegacy function"""
    to_hash = text + salt
    digest = hashlib.sha256(to_hash.encode('utf-8')).hexdigest()
    return f"{digest}$salt:{salt}"

def quick_test():
    print("=== QUICK TEST FOR COMMON ANSWERS ===\n")
    
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
    
    # Test common development/testing answers
    test_answers = ["test", "demo", "example", "sample", "admin", "password", "123", "abc"]
    
    print("Testing common development answers...")
    
    for i, q in enumerate(questions, 1):
        print(f"\nQuestion {i}: {q['question']}")
        found = False
        
        for answer in test_answers:
            # Test the answer
            normalized = answer.lower().strip()
            parts = q['hash'].split('$salt:')
            salt = parts[1]
            computed = flutter_legacy_hash(normalized, salt)
            
            if computed == q['hash']:
                print(f"  ✓ FOUND: '{answer}' is the correct answer!")
                found = True
                break
        
        if not found:
            print(f"  ✗ None of the common test answers work")
    
    print("\n" + "="*50)
    print("If no matches found, you'll need to manually test your remembered answers.")
    print("The answers are case-insensitive and whitespace is trimmed.")

if __name__ == "__main__":
    quick_test()
