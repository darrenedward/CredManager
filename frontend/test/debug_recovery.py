#!/usr/bin/env python3

import hashlib
import sqlite3
import sys

def flutter_legacy_hash(text, salt):
    """Replicate the Flutter _hashPassphraseLegacy function"""
    to_hash = text + salt
    digest = hashlib.sha256(to_hash.encode('utf-8')).hexdigest()
    return f"{digest}$salt:{salt}"

def flutter_verify_answer(answer, stored_hash, debug=False):
    """Replicate the Flutter _verifyAnswerCaseInsensitive function logic with debug info"""
    normalized = answer.lower().strip()
    
    if debug:
        print(f"    Original answer: '{answer}'")
        print(f"    Normalized answer: '{normalized}'")
        print(f"    Stored hash: {stored_hash}")
    
    if '$salt:' not in stored_hash:
        if debug:
            print(f"    ERROR: No salt found in hash")
        return False
    
    parts = stored_hash.split('$salt:')
    if len(parts) != 2:
        if debug:
            print(f"    ERROR: Invalid hash format, found {len(parts)} parts")
        return False
    
    expected_hash = parts[0]
    salt = parts[1]
    
    if debug:
        print(f"    Expected hash: {expected_hash}")
        print(f"    Salt: {salt}")
    
    computed_hash = flutter_legacy_hash(normalized, salt)
    computed_hash_part = computed_hash.split('$salt:')[0]
    
    if debug:
        print(f"    Computed hash: {computed_hash_part}")
        print(f"    Match: {computed_hash == stored_hash}")
    
    return computed_hash == stored_hash

def debug_recovery_process():
    """Debug the complete recovery process"""
    print("=== DEBUGGING RECOVERY PROCESS ===\n")
    
    # Connect to the database
    db_path = '/home/curryman/Documents/APIKeyManager/api_key_manager.db'
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Get security questions in the same order as the app
        cursor.execute("SELECT question, encrypted_answer_hash FROM security_questions ORDER BY created_at ASC")
        stored_questions = cursor.fetchall()
        
        if not stored_questions:
            print("No security questions found in database!")
            return
        
        print(f"Found {len(stored_questions)} security questions in database:")
        for i, (question, hash_val) in enumerate(stored_questions, 1):
            print(f"  {i}. {question}")
        print()
        
        # Simulate the recovery process
        user_answers = []
        for i, (question, hash_val) in enumerate(stored_questions, 1):
            print(f"Question {i}: {question}")
            answer = input("Enter your answer: ").strip()
            user_answers.append((question, answer, hash_val))
            print()
        
        print("=== VERIFICATION PROCESS ===\n")
        
        correct_count = 0
        for i, (question, answer, stored_hash) in enumerate(user_answers, 1):
            print(f"Verifying Question {i}:")
            print(f"  Question: {question}")
            is_correct = flutter_verify_answer(answer, stored_hash, debug=True)
            
            if is_correct:
                print(f"  ✓ CORRECT!")
                correct_count += 1
            else:
                print(f"  ✗ INCORRECT")
            print()
        
        print(f"=== FINAL RESULT ===")
        print(f"Correct answers: {correct_count}/{len(stored_questions)}")
        
        # This matches the Flutter logic: correctAnswers == answers.length && answers.length == storedQuestions.length
        is_valid = correct_count == len(user_answers) and len(user_answers) == len(stored_questions)
        
        if is_valid:
            print("✓ Recovery would SUCCEED - all answers correct!")
        else:
            print("✗ Recovery would FAIL - not all answers correct")
            print(f"   Need: {len(stored_questions)} correct")
            print(f"   Got: {correct_count} correct")
        
    except Exception as e:
        print(f"Database error: {e}")
    finally:
        if 'conn' in locals():
            conn.close()

def test_specific_answers():
    """Test specific answers without interactive input"""
    print("=== TESTING SPECIFIC ANSWERS ===\n")
    
    # Common test cases - you can modify these
    test_cases = [
        {
            "question": "What is the name of your first pet?",
            "hash": "3de40fbd4249c2dcfaa4428cedc3ad35802b13e668b52f905dfb1f5a636b8930$salt:AmscAoLPjtsZ20-bxyqmFCsCDwJPppvK1x0O-7nSDcw=",
            "test_answers": ["test", "Test", "TEST", "fluffy", "max", "buddy", "spot", "shadow"]
        },
        {
            "question": "What is your mother's maiden name?",
            "hash": "e8692c53460b7d5935ab49efe7c72917ab4716685c39f23ddbbc5bcac6a4054c$salt:OcBX7l7iSDmv2-L4ZifHl_tdkYwXMmNds0tMTgRkSug=",
            "test_answers": ["test", "Test", "TEST", "smith", "johnson", "brown", "davis"]
        },
        {
            "question": "What is the name of the street you grew up on?",
            "hash": "6843f5394b70d936355d1ce8b2afbaf42b63c0435e28ae36e985f4003c8d753e$salt:hoOhDC5Dcczw0FFc_qe_74xQEAV3zOd5gnne9NC9PFg=",
            "test_answers": ["test", "Test", "TEST", "main", "oak", "elm", "first", "maple"]
        }
    ]
    
    for i, test_case in enumerate(test_cases, 1):
        print(f"Question {i}: {test_case['question']}")
        found_match = False
        
        for answer in test_case['test_answers']:
            if flutter_verify_answer(answer, test_case['hash']):
                print(f"  ✓ MATCH FOUND: '{answer}'")
                found_match = True
                break
        
        if not found_match:
            print(f"  ✗ No matches found in test answers")
        print()

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == 'test':
        test_specific_answers()
    else:
        debug_recovery_process()
