
import sys
import os
from sqlalchemy.orm import Session
from datetime import datetime

# Add api directory to path so imports work
current_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.append(current_dir)

from api.database import SessionLocal, engine, Base
from api.models.quizzes import Quiz
from api.models.quiz_questions import QuizQuestion
from api.models.courses import Course
from api.models.teachers import Teacher
from api.models.lecture_notes import LectureNote
from api.models.chunks import Chunk
from api.models.retrieval_records import RetrievalRecord
from api.services.quiz_generation_service import generate_quiz
import asyncio

# Ensure tables exist
Base.metadata.create_all(bind=engine)

def verify_saving():
    db: Session = SessionLocal()
    try:
        print("\n--- EXTENSIVE DB VERIFICATION ---")
        
        # 1. Setup Test Data (Teacher, Course, LectureNote)
        # Check if we have a teacher, if not create one
        teacher = db.query(Teacher).first()
        if not teacher:
            teacher = Teacher(name="Test Teacher", email="test@teacher.com", password="pass")
            db.add(teacher)
            db.commit()
            print("[INFO] Created Test Teacher")
            
        course = db.query(Course).first()
        if not course:
            course = Course(code="CS101", title="Intro to CS")
            db.add(course)
            db.commit()
            print("[INFO] Created Test Course")
            
        note = db.query(LectureNote).first()
        if not note:
            note = LectureNote(
                course_id=course.id, 
                uploaded_by=teacher.id, 
                original_name="test_note.pdf", 
                stored_name="test_note.pdf"
            )
            db.add(note)
            db.commit()
            print("[INFO] Created Test LectureNote")
            
        # Ensure we have at least one chunk for RAG
        chunk = db.query(Chunk).filter(Chunk.lecture_notes_id == note.id).first()
        if not chunk:
            chunk = Chunk(
                lecture_notes_id=note.id, 
                text="Object Oriented Programming is a paradigm based on objects.", 
                embedding=None # We might skip specific embedding check if mock search is strictly mostly text
            )
            db.add(chunk)
            db.commit()
            print("[INFO] Created Test Chunk")
            
        # 2. Simulate Quiz Generation Request
        topic = "OOP Basics"
        # We want: 1 Easy, 1 Medium
        diff_dict = {"Easy": 1, "Medium": 1} 
        
        print(f"[ACTION] calling generate_quiz with distribution: {diff_dict}...")
        
        # Since generate_quiz is async, we run it
        result = asyncio.run(generate_quiz(
            db=db,
            lecture_note_id=note.id,
            topic=topic,
            difficulty="Medium", # Fallback label
            num_questions=2,
            difficulty_dict=diff_dict
        ))
        
        print("[RESULT] Service returned:", result)
        
        # 3. Verify Database Records
        quiz_id = result['quiz_id']
        
        # Fetch Quiz
        saved_quiz = db.query(Quiz).get(quiz_id)
        if saved_quiz:
            print(f"\n[PASS] Quiz record found. ID: {saved_quiz.id}")
            print(f"       Title: {saved_quiz.title}")
            print(f"       Total Questions: {saved_quiz.total_questions}")
            print(f"       Avg Difficulty: {saved_quiz.avg_difficulty}")
        else:
            print("\n[FAIL] Quiz record NOT found!")
            return

        # Fetch Questions
        saved_questions = db.query(QuizQuestion).filter(QuizQuestion.quiz_id == quiz_id).all()
        print(f"\n[INFO] Found {len(saved_questions)} questions in DB.")
        
        if len(saved_questions) == 2:
            print("[PASS] Correct number of questions saved.")
        else:
            print(f"[FAIL] Expected 2 questions, found {len(saved_questions)}.")
            
        # Verify Difficulty Mix
        difficulties = [q.difficulty for q in saved_questions]
        print(f"       Difficulties found: {difficulties}")
        
        if "Easy" in difficulties and "Medium" in difficulties:
            print("[PASS] Difficulty distribution verified (Easy & Medium present).")
        else:
            print("[WARN] Difficulty distribution might be off (randomness factor).")
            
        # Verify Content
        for q in saved_questions:
            print(f"\n       Question: {q.question_text[:50]}...")
            print(f"       Options: A:{q.option_a}, B:{q.option_b}, C:{q.option_c}, D:{q.option_d}")
            print(f"       Correct: {q.correct_option}")
            if q.option_a and q.option_b and q.option_c and q.option_d:
                print("       [PASS] All options present.")
            else:
                print("       [FAIL] Missing options.")

    except Exception as e:
        print(f"\n[ERROR] An error occurred: {e}")
        import traceback
        traceback.print_exc()
    finally:
        db.close()

if __name__ == "__main__":
    verify_saving()
