#!/usr/bin/env python3

import sqlite3
import hashlib
import base64
import os
import argon2
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

def argon2_hash(text):
    """Generate Argon2 hash like Flutter does"""
    try:
        ph = argon2.PasswordHasher()
        return ph.hash(text)
    except Exception as e:
        print(f"Argon2 not available: {e}")
        return None

def update_with_argon2():
    """Update the database with Argon2 hashes"""
    print("=== UPDATING SECURITY ANSWERS WITH ARGON2 ===\n")
    
    # Check if argon2 is available
    try:
        import argon2
    except ImportError:
        print("Installing argon2-cffi...")
        os.system("pip3 install argon2-cffi")
        try:
            import argon2
        except ImportError:
            print("Failed to install argon2. Using legacy SHA-256 instead.")
            return update_with_legacy()
    
    # Your correct answers
    correct_answers = ["gismo", "lister", "westminister"]
    
    # Connect to database
    db_path = '/home/curryman/Documents/APIKeyManager/api_key_manager.db'
    
    # Backup the database first
    backup_path = db_path + '.backup.argon2.' + datetime.now().strftime('%Y%m%d_%H%M%S')
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
        
        print("Updating answers with Argon2 encryption:")
        for i, (question_id, question) in enumerate(existing_questions):
            answer = correct_answers[i]
            print(f"  {i+1}. {question} -> '{answer}'")
            
            # Generate Argon2 hash
            normalized_answer = answer.lower().strip()
            argon2_hash_result = argon2_hash(normalized_answer)
            
            if argon2_hash_result is None:
                print("     Failed to generate Argon2 hash, falling back to legacy")
                return update_with_legacy()
            
            print(f"     New Argon2 hash: {argon2_hash_result}")
            
            # Update the database
            cursor.execute(
                "UPDATE security_questions SET encrypted_answer_hash = ?, updated_at = ? WHERE id = ?",
                (argon2_hash_result, int(datetime.now().timestamp() * 1000), question_id)
            )
        
        conn.commit()
        print("\n✓ Database updated with Argon2 hashes!")
        
        # Verify the updates
        print("\nVerifying Argon2 updates:")
        cursor.execute("SELECT question, encrypted_answer_hash FROM security_questions ORDER BY created_at ASC")
        updated_questions = cursor.fetchall()
        
        verification_success = True
        ph = argon2.PasswordHasher()
        
        for i, (question, stored_hash) in enumerate(updated_questions):
            answer = correct_answers[i]
            normalized = answer.lower().strip()
            
            try:
                ph.verify(stored_hash, normalized)
                print(f"  ✓ Question {i+1}: '{answer}' verifies correctly with Argon2")
            except argon2.exceptions.VerifyMismatchError:
                print(f"  ✗ Question {i+1}: '{answer}' Argon2 verification failed")
                verification_success = False
            except Exception as e:
                print(f"  ✗ Question {i+1}: Argon2 error: {e}")
                verification_success = False
        
        if verification_success:
            print("\n🎉 All answers updated and verified with Argon2!")
            print("Your answers for recovery:")
            for i, answer in enumerate(correct_answers, 1):
                print(f"  {i}. {answer}")
        else:
            print("\n❌ Argon2 verification failed. Rolling back...")
            conn.rollback()
            return False
            
    except Exception as e:
        print(f"Error updating database: {e}")
        conn.rollback()
        return False
    finally:
        conn.close()
    
    return True

def update_with_legacy():
    """Update with legacy SHA-256 (fallback)"""
    print("Using legacy SHA-256 encryption...")
    
    # Re-run the previous script
    os.system("python3 update_security_answers.py")
    return True

def main():
    print("Choose encryption method:")
    print("1. Argon2 (modern, secure - recommended)")
    print("2. Legacy SHA-256 (for compatibility)")
    
    try:
        choice = input("Enter choice (1 or 2): ").strip()
        
        if choice == "1":
            success = update_with_argon2()
        elif choice == "2":
            success = update_with_legacy()
        else:
            print("Invalid choice. Using Argon2 by default...")
            success = update_with_argon2()
        
        if success:
            print("\n" + "="*60)
            print("SUCCESS! Database updated.")
            print("Now test the recovery in your Flutter app with these answers:")
            print("1. gismo")
            print("2. lister") 
            print("3. westminister")
        else:
            print("\n" + "="*60)
            print("FAILED! Database not updated.")
            
    except (KeyboardInterrupt, EOFError):
        print("\nCancelled.")

if __name__ == "__main__":
    main()
