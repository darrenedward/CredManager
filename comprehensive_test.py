#!/usr/bin/env python3

import hashlib

def flutter_legacy_hash(text, salt):
    """Replicate the Flutter _hashPassphraseLegacy function"""
    to_hash = text + salt
    digest = hashlib.sha256(to_hash.encode('utf-8')).hexdigest()
    return f"{digest}$salt:{salt}"

def comprehensive_answer_test():
    """Test a comprehensive list of possible answers"""
    print("=== COMPREHENSIVE ANSWER TESTING ===\n")
    
    questions_data = [
        {
            "question": "What is the name of your first pet?",
            "hash": "3de40fbd4249c2dcfaa4428cedc3ad35802b13e668b52f905dfb1f5a636b8930$salt:AmscAoLPjtsZ20-bxyqmFCsCDwJPppvK1x0O-7nSDcw=",
            "candidates": [
                # Your answer and variations
                "gismo", "gizmo", "gizzmo", "gizmo", "gisamo", "gisamo",
                # Common pet names
                "dog", "cat", "puppy", "kitty", "pet", "animal",
                "max", "buddy", "charlie", "bella", "lucy", "cooper", "bailey",
                "daisy", "lola", "luna", "sadie", "molly", "maggie", "sophie",
                "jack", "rocky", "duke", "bear", "zeus", "bentley", "tucker",
                "oliver", "lucky", "shadow", "riley", "harley", "coco", "princess",
                "toby", "sammy", "oscar", "teddy", "winston", "leo", "milo",
                # Test/demo values
                "test", "demo", "example", "pet1", "dog1", "cat1"
            ]
        },
        {
            "question": "What is your mother's maiden name?",
            "hash": "e8692c53460b7d5935ab49efe7c72917ab4716685c39f23ddbbc5bcac6a4054c$salt:OcBX7l7iSDmv2-L4ZifHl_tdkYwXMmNds0tMTgRkSug=",
            "candidates": [
                # Your answer and variations
                "lister", "lyster", "lister", "listor", "liester",
                # Common surnames
                "smith", "johnson", "williams", "brown", "jones", "garcia",
                "miller", "davis", "rodriguez", "martinez", "hernandez",
                "lopez", "gonzalez", "wilson", "anderson", "thomas", "taylor",
                "moore", "jackson", "martin", "lee", "perez", "thompson",
                "white", "harris", "sanchez", "clark", "ramirez", "lewis",
                "robinson", "walker", "young", "allen", "king", "wright",
                "scott", "torres", "nguyen", "hill", "flores", "green",
                # Test/demo values
                "test", "demo", "example", "maiden", "mother", "mom"
            ]
        },
        {
            "question": "What is the name of the street you grew up on?",
            "hash": "6843f5394b70d936355d1ce8b2afbaf42b63c0435e28ae36e985f4003c8d753e$salt:hoOhDC5Dcczw0FFc_qe_74xQEAV3zOd5gnne9NC9PFg=",
            "candidates": [
                # Your answer and variations
                "westminister", "westminster", "westminstr", "westminstor",
                "westministr", "westmister", "westmistr",
                # Common street names
                "main", "first", "second", "third", "park", "oak", "elm",
                "maple", "pine", "cedar", "church", "school", "broadway",
                "washington", "lincoln", "madison", "jackson", "franklin",
                "center", "high", "market", "state", "union", "mill",
                "river", "hill", "spring", "view", "lake", "sunset",
                "cherry", "walnut", "chestnut", "sycamore", "hickory",
                "main street", "first street", "oak street", "elm street",
                # Test/demo values
                "test", "demo", "example", "street", "road", "avenue"
            ]
        }
    ]
    
    total_found = 0
    
    for i, q_data in enumerate(questions_data, 1):
        print(f"Question {i}: {q_data['question']}")
        
        parts = q_data['hash'].split('$salt:')
        salt = parts[1]
        expected_hash = parts[0]
        
        found_answers = []
        
        for candidate in q_data['candidates']:
            # Test as-is and normalized
            test_variants = [candidate, candidate.lower().strip()]
            
            for variant in test_variants:
                computed = flutter_legacy_hash(variant, salt)
                computed_hash = computed.split('$salt:')[0]
                
                if computed_hash == expected_hash:
                    found_answers.append(variant)
                    break
        
        if found_answers:
            print(f"  ✓ FOUND MATCHES:")
            for answer in found_answers:
                print(f"    - '{answer}'")
            total_found += len(found_answers)
        else:
            print(f"  ✗ No matches found in {len(q_data['candidates'])} candidates")
        
        print()
    
    print("="*60)
    print(f"SUMMARY: Found {total_found} matching answers total")
    
    if total_found == 3:
        print("✓ SUCCESS! Found answers for all questions.")
    elif total_found > 0:
        print(f"⚠ PARTIAL: Found answers for some questions.")
    else:
        print("✗ FAILURE: No matching answers found.")
        print("\nThis suggests either:")
        print("1. The actual answers are not common words/names")
        print("2. They contain special characters or numbers")
        print("3. They are very specific personal information")
        print("4. There's a deeper issue with the storage/verification")

def interactive_guess():
    """Allow manual testing of specific guesses"""
    print("\n" + "="*60)
    print("INTERACTIVE TESTING")
    print("Enter your guesses for each question (or 'skip' to skip)")
    print()
    
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
    
    for i, q in enumerate(questions, 1):
        print(f"Question {i}: {q['question']}")
        
        parts = q['hash'].split('$salt:')
        salt = parts[1]
        expected_hash = parts[0]
        
        while True:
            guess = input("Your guess (or 'skip'): ").strip()
            
            if guess.lower() == 'skip':
                print("Skipped.\n")
                break
            
            if not guess:
                continue
            
            # Test the guess
            normalized = guess.lower().strip()
            computed = flutter_legacy_hash(normalized, salt)
            computed_hash = computed.split('$salt:')[0]
            
            if computed_hash == expected_hash:
                print(f"✓ CORRECT! '{guess}' matches this question!\n")
                break
            else:
                print(f"✗ '{guess}' doesn't match. Try again.")

if __name__ == "__main__":
    comprehensive_answer_test()
    
    try:
        interactive_guess()
    except (KeyboardInterrupt, EOFError):
        print("\nTesting ended.")
