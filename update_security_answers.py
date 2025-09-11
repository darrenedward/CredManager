#!/usr/bin/env python3

import sqlite3
import hashlib
import base64
import os
from datetime import datetime

def flutter_legacy_hash(text, salt):
    """Replicate the Flutter _hashPassphraseLegacy function"""
    to_hash = text + salt
    digest = hashlib.sha256(to_hash.encode('utf-8')).hexdigest()
    return f"{digest}$salt:{salt}"

def generate_salt(length=32):
    """Generate a new salt like Flutter does"""
    random_bytes = os.urandom(length)
    return base64.urlsafe_b64encode(random_bytes).decode('utf-8')

def update_security_answers():
    """Update the database with the correct answers"""
    print("=== UPDATING SECURITY ANSWERS IN DATABASE ===\n")
    
    # Your correct answers
    correct_answers = ["gismo", "lister", "westminister"]
    
    # Connect to database
    db_path = '/home/curryman/Documents/APIKeyManager/api_key_manager.db'
    
    # Backup the database first
    backup_path = db_path + '.backup.' + datetime.now().strftime('%Y%m%d_%H%M%S')
    os.system(f'cp "{db_path}" "{backup_path}"')
    print(f"✓ Database backed up to: {backup_path}")
    
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Get existing questions
        cursor.execute("SELECT id, question FROM security_questions ORDER BY created_at ASC")
        existing_questions = cursor.fetchall()
        
        if len(existing_questions) != 3:
            print(f"Error: Expected 3 questions, found {len(existing_questions)}")
            return False
        
        print("Updating answers for:")
        for i, (question_id, question) in enumerate(existing_questions):
            answer = correct_answers[i]
            print(f"  {i+1}. {question} -> '{answer}'")
            
            # Generate new salt and hash
            salt = generate_salt()
            normalized_answer = answer.lower().strip()
            new_hash = flutter_legacy_hash(normalized_answer, salt)
            
            print(f"     New hash: {new_hash}")
            
            # Update the database
            cursor.execute(
                "UPDATE security_questions SET encrypted_answer_hash = ?, updated_at = ? WHERE id = ?",
                (new_hash, int(datetime.now().timestamp() * 1000), question_id)
            )
        
        conn.commit()
        print("\n✓ Database updated successfully!")
        
        # Verify the updates
        print("\nVerifying updates:")
        cursor.execute("SELECT question, encrypted_answer_hash FROM security_questions ORDER BY created_at ASC")
        updated_questions = cursor.fetchall()
        
        verification_success = True
        for i, (question, stored_hash) in enumerate(updated_questions):
            answer = correct_answers[i]
            normalized = answer.lower().strip()
            
            # Extract salt and verify
            if '$salt:' in stored_hash:
                parts = stored_hash.split('$salt:')
                salt = parts[1]
                computed = flutter_legacy_hash(normalized, salt)
                
                if computed == stored_hash:
                    print(f"  ✓ Question {i+1}: '{answer}' verifies correctly")
                else:
                    print(f"  ✗ Question {i+1}: '{answer}' verification failed")
                    verification_success = False
            else:
                print(f"  ✗ Question {i+1}: Invalid hash format")
                verification_success = False
        
        if verification_success:
            print("\n🎉 All answers updated and verified successfully!")
            print("You should now be able to use these answers in the recovery process:")
            for i, answer in enumerate(correct_answers, 1):
                print(f"  {i}. {answer}")
        else:
            print("\n❌ Verification failed. Rolling back changes...")
            conn.rollback()
            return False
            
    except Exception as e:
        print(f"Error updating database: {e}")
        conn.rollback()
        return False
    finally:
        conn.close()
    
    return True

def test_recovery_simulation():
    """Test the recovery process with the new answers"""
    print("\n" + "="*60)
    print("TESTING RECOVERY SIMULATION")
    print("="*60)
    
    # Connect to database
    db_path = '/home/curryman/Documents/APIKeyManager/api_key_manager.db'
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    try:
        # Get questions
        cursor.execute("SELECT question, encrypted_answer_hash FROM security_questions ORDER BY created_at ASC")
        questions = cursor.fetchall()
        
        # Your answers
        your_answers = ["gismo", "lister", "westminister"]
        
        print("Simulating recovery process:")
        correct_count = 0
        
        for i, (question, stored_hash) in enumerate(questions):
            answer = your_answers[i]
            normalized = answer.lower().strip()
            
            print(f"\nQuestion {i+1}: {question}")
            print(f"Your answer: '{answer}'")
            print(f"Normalized: '{normalized}'")
            
            if '$salt:' in stored_hash:
                parts = stored_hash.split('$salt:')
                salt = parts[1]
                computed = flutter_legacy_hash(normalized, salt)
                
                if computed == stored_hash:
                    print(f"✓ CORRECT")
                    correct_count += 1
                else:
                    print(f"✗ INCORRECT")
                    print(f"  Expected: {stored_hash}")
                    print(f"  Computed: {computed}")
            else:
                print(f"✗ Invalid hash format")
        
        print(f"\nFinal result: {correct_count}/3 correct")
        
        if correct_count == 3:
            print("🎉 RECOVERY WOULD SUCCEED!")
        else:
            print("❌ Recovery would fail")
            
    except Exception as e:
        print(f"Error during simulation: {e}")
    finally:
        conn.close()

if __name__ == "__main__":
    if update_security_answers():
        test_recovery_simulation()
    else:
        print("Update failed. Database not modified.")
