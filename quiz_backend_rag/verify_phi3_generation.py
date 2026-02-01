
import sys
import os

# Add api directory to path so imports work
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(current_dir)

from api.services.mcq_generator import generate_mcq_phi3
import json

def test_generation():
    print("Testing Phi-3 GGUF Model Generation (Optimized)...")
    
    lecture_chunk = """
CConstructorwithnoargumentsisknownasno-argconstructor.Thesignatureissameas
defaultconstructor;howeverbodycanhaveanycodeunlikedefaultconstructorwherethe
bodyoftheconstructorisempty.
AJ/Handout15-16 ObjectOrientedProgrammingusingJava(CS-423)
6
Althoughyoumayseesomepeopleclaimthatthatdefaultandno-argconstructorissamebut
infacttheyarenot,evenifyouwritepublicStudent(){}inyourclassStudentitcannotbe
calleddefaultconstructorsinceyouhavewrittenthecodeofit.
public class Student {
private intregNum;
private String name;
public Student()
{
System.out.println("This is noargument Constructor");
}
public void show()
{
System.out.println(regNum+ "\t" +name);
}
}
class Main
{
public static voidmain (String[] args)
{
// this would invoke noargument constructor.
Student s1 = newStudent();
// Default constructor provides the default
// values to the objectlike 0, null
s1.show();
}
}
"""

    
    difficulty = "Hard"
    
    print(f"Generating {difficulty} MCQ...")
    mcq = generate_mcq_phi3(lecture_chunk, difficulty)
    
    if mcq:
        print("\n--- Generated MCQ ---")
        print(json.dumps(mcq, indent=2))
        
        # Validation checks
        required_keys = ["question", "options", "correct", "difficulty"]
        missing = [k for k in required_keys if k not in mcq]
        if missing:
            print(f"\n[FAIL] Missing keys: {missing}")
        else:
            print(f"\n[PASS] All required keys present.")
            
        if len(mcq["options"]) != 4:
            print(f"[FAIL] Options count is {len(mcq['options'])}, expected 4.")
        else:
            print(f"[PASS] Options count is 4.")
            
    else:
        print("\n[FAIL] No MCQ generated.")

if __name__ == "__main__":
    test_generation()
