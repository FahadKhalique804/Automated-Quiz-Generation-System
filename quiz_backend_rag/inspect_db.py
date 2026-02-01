from sqlalchemy import text
from api.database import engine
from datetime import datetime
import json

def inspect_and_test():
    with engine.connect() as conn:
        print("--- Table Inspection ---")
        try:
            print("\n[attempts] columns:")
            result = conn.execute(text("DESCRIBE attempts"))
            for row in result:
                print(row)
                
            print("\n[assignments] columns:")
            result = conn.execute(text("DESCRIBE assignments"))
            for row in result:
                print(row)
        except Exception as e:
            print(f"Error describing tables: {e}")

        print("\n--- Test Insert: Assignment ---")
        try:
            # Try to insert a dummy assignment
            # We need a valid quiz_id and teacher_id.
            # Let's find one.
            quiz = conn.execute(text("SELECT id, created_by FROM quizzes LIMIT 1")).first()
            if not quiz:
                print("No quizzes found to test assignment insert.")
            else:
                q_id, teacher_id = quiz[0], quiz[1]
                print(f"Using Quiz ID: {q_id}, Teacher ID: {teacher_id}")
                
                # Insert Assignment
                stmt = text("""
                    INSERT INTO assignments (quiz_id, assigned_by, student_id, status, assigned_at)
                    VALUES (:qid, :aid, :sid, :status, :aat)
                """)
                # student_id 1 just for test, or None
                result = conn.execute(stmt, {
                    "qid": q_id, "aid": teacher_id, "sid": 1, "status": "assigned", "aat": datetime.now()
                })
                new_assign_id = result.lastrowid
                print(f"SUCCESS: Created Assignment ID: {new_assign_id}")
                
                print("\n--- Test Insert: Attempt ---")
                stmt = text("""
                    INSERT INTO attempts (assignment_id, quiz_id, student_id, submitted_answers, total_correct, percentage, submitted_at, teacher_feedback)
                    VALUES (:aid, :qid, :sid, :ans, :tc, :pct, :sub_at, :fb)
                """)
                conn.execute(stmt, {
                    "aid": new_assign_id,
                    "qid": q_id,
                    "sid": 1,
                    "ans": json.dumps({"1": 0}),
                    "tc": 10,
                    "pct": 100.0,
                    "sub_at": datetime.now(),
                    "fb": "Test feedback"
                })
                print("SUCCESS: Created Attempt.")
                
                # Cleanup
                # conn.execute(text(f"DELETE FROM attempts WHERE assignment_id={new_assign_id}"))
                # conn.execute(text(f"DELETE FROM assignments WHERE id={new_assign_id}"))
                # print("Cleanup complete.")
                conn.rollback() # Don't actually save test data
                print("Rolled back test data.")

        except Exception as e:
            print(f"INSERT FAILED: {e}")

if __name__ == "__main__":
    inspect_and_test()
