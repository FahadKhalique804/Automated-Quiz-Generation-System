from api.database import SessionLocal
from api.models.attempts import Attempt
from api.models.assignments import Assignment
from api.models.quizzes import Quiz
from api.models.retrieval_records import RetrievalRecord # Needed for relationship resolution
from api.models.students import Student
from api.models.teachers import Teacher
from datetime import datetime
import json
import traceback

def test_orm():
    db = SessionLocal()
    print("--- Testing ORM Insert ---")
    try:
        # Find a quiz
        quiz = db.query(Quiz).first()
        if not quiz:
            print("No quizzes found.")
            return
        
        print(f"Using Quiz ID: {quiz.id}")
        
        # Create Assignment
        assignment = Assignment(
            quiz_id=quiz.id,
            assigned_by=quiz.created_by,
            student_id=1,
            status="assigned",
            assigned_at=datetime.now()
        )
        db.add(assignment)
        db.commit()
        db.refresh(assignment)
        print(f"Created Assignment: {assignment.id}")
        
        # Create Attempt
        # Payload simulation
        submitted_answers_data = {"1": 0} # Dict, not string
        
        attempt = Attempt(
            assignment_id=assignment.id,
            quiz_id=quiz.id,
            student_id=1,
            submitted_answers=submitted_answers_data,
            total_correct=10,
            percentage=100.0,
            submitted_at=datetime.now(),
            teacher_feedback="ORM Test"
        )
        db.add(attempt)
        db.commit()
        db.refresh(attempt)
        print(f"Created Attempt: {attempt.id}")
        
        # Verify read
        read_att = db.query(Attempt).get(attempt.id)
        print(f"Read Attempt Feedback: {read_att.teacher_feedback}")
        
        # Cleanup
        db.delete(attempt)
        db.delete(assignment)
        db.commit()
        print("Cleanup successful.")
        
    except Exception as e:
        print("ORM TEST FAILED:")
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    test_orm()
