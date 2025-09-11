#!/usr/bin/env python3

import hashlib
import sqlite3

def flutter_legacy_hash(text, salt):
    """Replicate the Flutter _hashPassphraseLegacy function"""
    to_hash = text + salt
    digest = hashlib.sha256(to_hash.encode('utf-8')).hexdigest()
    return f"{digest}$salt:{salt}"

def diagnose_verification_logic():
    """Diagnose the complete verification process step by step"""
    print("=== COMPREHENSIVE VERIFICATION DIAGNOSIS ===\n")
    
    # Connect to database
    db_path = '/home/curryman/Documents/APIKeyManager/api_key_manager.db'
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Get stored questions in database order
    cursor.execute("SELECT question, encrypted_answer_hash FROM security_questions ORDER BY created_at ASC")
    stored_questions = cursor.fetchall()
    
    print("STEP 1: Database Questions (in storage order)")
    for i, (question, hash_val) in enumerate(stored_questions):
        print(f"  {i+1}. '{question}'")
        print(f"     Hash: {hash_val}")
    print()
    
    # Simulate how the app gets questions for recovery (random order)
    question_texts = [q[0] for q in stored_questions]
    print("STEP 2: Questions presented to user (same order as stored)")
    for i, question in enumerate(question_texts):
        print(f"  {i+1}. '{question}'")
    print()
    
    # Your answers
    your_answers = ["gismo", "lister", "westminister"]
    
    print("STEP 3: Your answers")
    for i, answer in enumerate(your_answers):
        print(f"  {i+1}. '{answer}'")
    print()
    
    # Simulate Flutter verification logic
    print("STEP 4: Simulating Flutter verification logic")
    print("This replicates the verifyRecoveryAnswers function...")
    print()
    
    # Prepare answers as the recovery screen would
    user_answers = []
    for i, question in enumerate(question_texts):
        user_answers.append({
            'question': question,
            'answer': your_answers[i]
        })
    
    print("User answers structure:")
    for i, answer_data in enumerate(user_answers):
        print(f"  {i+1}. Question: '{answer_data['question']}'")
        print(f"     Answer: '{answer_data['answer']}'")
    print()
    
    # Simulate the matching logic
    print("STEP 5: Question matching and verification")
    correct_answers = 0
    
    for i, answer_data in enumerate(user_answers):
        question = answer_data['question']
        answer_text = answer_data['answer']
        
        print(f"Processing answer {i+1}:")
        print(f"  Looking for question: '{question}'")
        
        # Find matching question in stored questions (this is the Flutter logic)
        matching_question = None
        matching_hash = None
        
        for stored_q, stored_hash in stored_questions:
            if stored_q == question:
                matching_question = stored_q
                matching_hash = stored_hash
                break
        
        if matching_question:
            print(f"  ✓ Found matching stored question")
            print(f"  Stored hash: {matching_hash}")
            
            # Verify the answer
            normalized_answer = answer_text.lower().strip()
            print(f"  Normalized answer: '{normalized_answer}'")
            
            # Extract salt from stored hash
            if '$salt:' in matching_hash:
                parts = matching_hash.split('$salt:')
                expected_hash = parts[0]
                salt = parts[1]
                
                print(f"  Expected hash: {expected_hash}")
                print(f"  Salt: {salt}")
                
                # Compute hash
                computed_full = flutter_legacy_hash(normalized_answer, salt)
                computed_hash = computed_full.split('$salt:')[0]
                
                print(f"  Computed hash: {computed_hash}")
                print(f"  Full computed: {computed_full}")
                
                if computed_full == matching_hash:
                    print(f"  ✓ VERIFICATION SUCCESS")
                    correct_answers += 1
                else:
                    print(f"  ✗ VERIFICATION FAILED")
            else:
                print(f"  ✗ Invalid hash format")
        else:
            print(f"  ✗ No matching stored question found")
        
        print()
    
    print("STEP 6: Final verification result")
    print(f"Correct answers: {correct_answers}")
    print(f"Total answers: {len(user_answers)}")
    print(f"Total stored questions: {len(stored_questions)}")
    
    # Flutter logic: correctAnswers == answers.length && answers.length == storedQuestions.length
    is_valid = (correct_answers == len(user_answers) and 
                len(user_answers) == len(stored_questions))
    
    if is_valid:
        print("✓ RECOVERY WOULD SUCCEED")
    else:
        print("✗ RECOVERY WOULD FAIL")
        print(f"  Need all {len(stored_questions)} answers correct")
        print(f"  Got {correct_answers} answers correct")
    
    print()
    print("STEP 7: Troubleshooting")
    if not is_valid:
        print("Possible issues:")
        print("1. Answers were stored with different normalization")
        print("2. There's a bug in the hash comparison logic")
        print("3. The answers might have been stored differently")
        print("4. Character encoding issues")
        
        # Try some alternative storage methods
        print("\nTesting alternative storage methods:")
        
        for i, (question, stored_hash) in enumerate(stored_questions):
            answer = your_answers[i]
            print(f"\nQuestion {i+1}: {question}")
            print(f"Your answer: '{answer}'")
            
            # Try various ways the answer might have been stored
            test_variants = [
                answer,  # as-is
                answer.lower(),
                answer.upper(),
                answer.strip(),
                answer.lower().strip(),
                answer + " ",  # with trailing space
                " " + answer,  # with leading space
            ]
            
            parts = stored_hash.split('$salt:')
            if len(parts) == 2:
                salt = parts[1]
                expected = parts[0]
                
                for variant in test_variants:
                    test_hash = flutter_legacy_hash(variant, salt).split('$salt:')[0]
                    if test_hash == expected:
                        print(f"  ✓ FOUND: Answer was stored as '{variant}'")
                        break
                else:
                    print(f"  ✗ No variant matches")
    
    conn.close()

if __name__ == "__main__":
    diagnose_verification_logic()
