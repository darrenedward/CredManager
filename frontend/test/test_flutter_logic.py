#!/usr/bin/env python3

import hashlib
import base64

def flutter_legacy_hash(text, salt):
    """Replicate the Flutter _hashPassphraseLegacy function"""
    # Convert text to bytes and hash with salt
    to_hash = text + salt
    digest = hashlib.sha256(to_hash.encode('utf-8')).hexdigest()
    return f"{digest}$salt:{salt}"

def flutter_verify_answer(answer, stored_hash):
    """Replicate the Flutter _verifyAnswerCaseInsensitive function logic"""
    # Normalize answer
    normalized = answer.lower().strip()
    
    # Check format
    if '$salt:' not in stored_hash:
        return False
    
    # Split to get salt
    parts = stored_hash.split('$salt:')
    if len(parts) != 2:
        return False
    
    salt = parts[1]
    
    # Create hash using the same method as Flutter
    computed_hash = flutter_legacy_hash(normalized, salt)
    
    # Compare
    return computed_hash == stored_hash

def main():
    print("=== FLUTTER LOGIC REPLICATION TEST ===\n")
    
    # Your actual stored hashes
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
    
    print("Testing with Flutter's exact verification logic...")
    print()
    
    # Test a few more common pet names for the first question
    test_answers_q1 = [
        "dog", "cat", "fish", "bird", "hamster", "rabbit", "turtle",
        "spot", "lucky", "shadow", "smokey", "tiger", "mittens", "patches",
        "simba", "nala", "garfield", "felix", "whiskers", "snowball"
    ]
    
    print("Question 1: What is the name of your first pet?")
    for answer in test_answers_q1:
        if flutter_verify_answer(answer, questions[0]['hash']):
            print(f"  ✓ FOUND: '{answer}' matches!")
            break
    else:
        print("  No matches found in common pet names")
    
    print()
    
    # Test maiden names for question 2
    test_answers_q2 = [
        "anderson", "clark", "davis", "evans", "garcia", "harris", "jackson",
        "lee", "martinez", "moore", "rodriguez", "taylor", "thomas", "white",
        "wilson", "young", "king", "wright", "lopez", "hill", "green", "adams"
    ]
    
    print("Question 2: What is your mother's maiden name?")
    for answer in test_answers_q2:
        if flutter_verify_answer(answer, questions[1]['hash']):
            print(f"  ✓ FOUND: '{answer}' matches!")
            break
    else:
        print("  No matches found in common surnames")
    
    print()
    
    # Test street names for question 3
    test_answers_q3 = [
        "main", "first", "second", "third", "park", "oak", "elm", "pine",
        "maple", "cedar", "church", "school", "broadway", "washington",
        "lincoln", "madison", "jackson", "franklin", "center", "high"
    ]
    
    print("Question 3: What is the name of the street you grew up on?")
    for answer in test_answers_q3:
        if flutter_verify_answer(answer, questions[2]['hash']):
            print(f"  ✓ FOUND: '{answer}' matches!")
            break
    else:
        print("  No matches found in common street names")
    
    print()
    print("=== MANUAL TESTING ===")
    print()
    print("If you'd like to test specific answers, you can modify this script")
    print("or try some variations of what you remember entering.")
    print()
    print("Remember the answers are:")
    print("- Case insensitive (converted to lowercase)")
    print("- Whitespace trimmed")
    print("- Exactly as you typed them during setup")

if __name__ == "__main__":
    main()
