#!/usr/bin/env python3

import hashlib
import itertools
import string

def flutter_legacy_hash(text, salt):
    """Replicate the Flutter _hashPassphraseLegacy function"""
    to_hash = text + salt
    digest = hashlib.sha256(to_hash.encode('utf-8')).hexdigest()
    return f"{digest}$salt:{salt}"

def brute_force_answers():
    """Try to find the actual answers by testing common variations and patterns"""
    print("=== BRUTE FORCE SEARCH FOR ACTUAL ANSWERS ===\n")
    
    questions = [
        {
            "question": "What is the name of your first pet?",
            "hash": "3de40fbd4249c2dcfaa4428cedc3ad35802b13e668b52f905dfb1f5a636b8930$salt:AmscAoLPjtsZ20-bxyqmFCsCDwJPppvK1x0O-7nSDcw=",
            "base_answer": "gismo",
            "variations": [
                "gismo", "Gismo", "GISMO", "gizmo", "Gizmo", "GIZMO",
                "gismo ", " gismo", " gismo ", "gismo.", "gismo!", 
                "gismo1", "gismo2", "gismo123", "pet", "dog", "puppy"
            ]
        },
        {
            "question": "What is your mother's maiden name?",
            "hash": "e8692c53460b7d5935ab49efe7c72917ab4716685c39f23ddbbc5bcac6a4054c$salt:OcBX7l7iSDmv2-L4ZifHl_tdkYwXMmNds0tMTgRkSug=",
            "base_answer": "lister",
            "variations": [
                "lister", "Lister", "LISTER", "Lister ", " Lister",
                " lister ", "lister.", "lister!", "lister1", "lister2",
                "maiden", "mother", "mom", "name"
            ]
        },
        {
            "question": "What is the name of the street you grew up on?",
            "hash": "6843f5394b70d936355d1ce8b2afbaf42b63c0435e28ae36e985f4003c8d753e$salt:hoOhDC5Dcczw0FFc_qe_74xQEAV3zOd5gnne9NC9PFg=",
            "base_answer": "westminister",
            "variations": [
                "westminister", "Westminster", "WESTMINSTER", "westminster",
                "westminister ", " westminister", " westminister ",
                "westminster street", "westminster st", "westminster road",
                "westminster ave", "westminster avenue", "street", "road"
            ]
        }
    ]
    
    for i, q in enumerate(questions, 1):
        print(f"Question {i}: {q['question']}")
        print(f"Expected base answer: {q['base_answer']}")
        
        parts = q['hash'].split('$salt:')
        salt = parts[1]
        expected_hash = parts[0]
        
        found = False
        for variation in q['variations']:
            # Test as-is
            computed = flutter_legacy_hash(variation, salt)
            computed_hash = computed.split('$salt:')[0]
            
            if computed_hash == expected_hash:
                print(f"  ✓ FOUND EXACT MATCH: '{variation}'")
                found = True
                break
            
            # Also test lowercase version (since verification normalizes)
            normalized = variation.lower().strip()
            computed_norm = flutter_legacy_hash(normalized, salt)
            computed_hash_norm = computed_norm.split('$salt:')[0]
            
            if computed_hash_norm == expected_hash:
                print(f"  ✓ FOUND NORMALIZED MATCH: '{variation}' -> '{normalized}'")
                found = True
                break
        
        if not found:
            print(f"  ✗ No match found in common variations")
            
            # Try some basic character substitutions for common typos
            base = q['base_answer']
            typo_variations = []
            
            # Try single character differences
            for i in range(len(base)):
                for char in 'abcdefghijklmnopqrstuvwxyz':
                    typo = base[:i] + char + base[i+1:]
                    typo_variations.append(typo)
            
            # Try with missing characters
            for i in range(len(base)):
                typo = base[:i] + base[i+1:]
                typo_variations.append(typo)
            
            # Try with extra characters
            for i in range(len(base) + 1):
                for char in 'abcdefghijklmnopqrstuvwxyz':
                    typo = base[:i] + char + base[i:]
                    typo_variations.append(typo)
            
            print(f"  Testing {len(typo_variations)} typo variations...")
            for typo in typo_variations[:100]:  # Limit to first 100 to avoid too much output
                normalized = typo.lower().strip()
                computed = flutter_legacy_hash(normalized, salt)
                computed_hash = computed.split('$salt:')[0]
                
                if computed_hash == expected_hash:
                    print(f"  ✓ FOUND TYPO MATCH: '{typo}' -> '{normalized}'")
                    found = True
                    break
            
            if not found:
                print(f"  ✗ No typo variations found either")
        
        print()
    
    print("If no matches are found, the issue might be in the verification logic itself.")

if __name__ == "__main__":
    brute_force_answers()
