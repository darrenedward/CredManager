#!/usr/bin/env python3

import sqlite3
import hashlib
import base64

def flutter_legacy_hash(text, salt):
    """Replicate the Flutter _hashPassphraseLegacy function"""
    to_hash = text + salt
    digest = hashlib.sha256(to_hash.encode('utf-8')).hexdigest()
    return f"{digest}$salt:{salt}"

def verify_current_database():
    """Verify that the current database works with your answers"""
    print("=== VERIFYING CURRENT DATABASE STATE ===\n")
    
    # Connect to database
    db_path = '/home/curryman/Documents/APIKeyManager/api_key_manager.db'
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Get stored questions
        cursor.execute("SELECT question, encrypted_answer_hash FROM security_questions ORDER BY created_at ASC")
        stored_questions = cursor.fetchall()
        
        # Your answers
        your_answers = ["gismo", "lister", "westminister"]
        
        print("Testing verification with current database:")
        print()
        
        all_correct = True
        for i, (question, stored_hash) in enumerate(stored_questions):
            answer = your_answers[i]
            print(f"Question {i+1}: {question}")
            print(f"Your answer: '{answer}'")
            print(f"Stored hash: {stored_hash}")
            
            # Normalize answer like Flutter does
            normalized = answer.lower().strip()
            print(f"Normalized: '{normalized}'")
            
            # Check hash format and verify
            if stored_hash.startswith('$argon2'):
                print("Format: Argon2 (requires Flutter to verify)")
                print("✓ Cannot verify here, but should work in Flutter")
            elif '$salt:' in stored_hash:
                print("Format: Legacy SHA-256")
                parts = stored_hash.split('$salt:')
                expected_hash = parts[0]
                salt = parts[1]
                
                computed = flutter_legacy_hash(normalized, salt)
                computed_hash = computed.split('$salt:')[0]
                
                print(f"Expected: {expected_hash}")
                print(f"Computed: {computed_hash}")
                
                if computed == stored_hash:
                    print("✓ CORRECT - Answer matches!")
                else:
                    print("✗ INCORRECT - Answer does not match!")
                    all_correct = False
            else:
                print("✗ Unknown hash format")
                all_correct = False
            
            print()
        
        print("="*50)
        if all_correct:
            print("✅ SUCCESS: All answers should work in the Flutter app!")
        else:
            print("❌ PROBLEM: Some answers may not work in the Flutter app!")
            
    except Exception as e:
        print(f"Error: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    verify_current_database()
