
from sqlalchemy.orm import Session
from fastapi import HTTPException
from api.models.quizzes import Quiz
from api.models.quiz_questions import QuizQuestion
from api.models.lecture_notes import LectureNote
from api.models.question_library import QuestionLibrary
from api.services.search_service import search_lecture_chunks
from api.services.mcq_generator import generate_mcq_phi3
from datetime import datetime
import asyncio

async def generate_quiz(
    db: Session,
    lecture_note_id: int,
    topic: str,
    difficulty: str,
    num_questions: int,
    difficulty_dict: dict[str, int] = None,
    selected_library_question_ids: list[int] = []
):
    questions = await generate_questions_preview(
        db=db,
        lecture_note_id=lecture_note_id,
        topic=topic,
        difficulty=difficulty,
        num_questions=num_questions,
        difficulty_dict=difficulty_dict,
        selected_library_question_ids=selected_library_question_ids
    )

    return finalize_quiz(
         db=db,
         lecture_note_id=lecture_note_id,
         topic=topic,
         difficulty=difficulty, # Passed for metadata, though individual questions have their own diff
         questions=questions
    )

async def generate_questions_preview(
    db: Session,
    lecture_note_id: int,
    topic: str,
    difficulty: str,
    num_questions: int,
    difficulty_dict: dict[str, int] = None,
    selected_library_question_ids: list[int] = []
):

    # 1. Fetch Lecture Note
    note = db.query(LectureNote).get(lecture_note_id)
    if not note:
        raise HTTPException(status_code=404, detail="Lecture note not found")
        
    # 2. Vector Search (RAG)
    top_chunks = search_lecture_chunks(db, lecture_note_id, topic, top_k=5)
    
    # We allow generating even if no chunks found? Maybe purely from topic?
    # Current logic enforces chunks.
    if not top_chunks:
        raise HTTPException(status_code=400, detail="Not enough context found in lecture notes.")
    
    # 3. Determine Difficulty Distribution
    target_counts = {}
    if difficulty_dict:
        target_counts = difficulty_dict
        # Update num_questions to match the sum if a dict is provided
        num_questions = sum(target_counts.values())
    else:
        target_counts = {difficulty: num_questions}

    generated_questions = []

    # 4. Fetch Selected Library Questions
    if selected_library_question_ids:
        lib_questions = db.query(QuestionLibrary).filter(QuestionLibrary.id.in_(selected_library_question_ids)).all()
        for lq in lib_questions:
            q_dict = {
                "question": lq.question_text,
                "options": {
                    "A": lq.option_a,
                    "B": lq.option_b,
                    "C": lq.option_c,
                    "D": lq.option_d,
                },
                "correct": lq.correct_option,
                "difficulty": lq.difficulty,
                "time_secs": lq.time_secs or 60
            }
            generated_questions.append(q_dict)

    # 5. Generate Loop
    chunk_index = 0
    max_retries = 3
    
    for diff_level, count in target_counts.items():
        # Count how many we already have of this difficulty from library selection
        # (This is a refinement: if user selected 3 Easy from library, and wants 5 Easy total, we only generate 2)
        # However, the previous logic just APPENDED library questions. 
        # Usually, 'num_questions' or 'difficulty_dict' implies TOTAL desired size.
        # If I selected 3 questions, do I want 3 + 10 generated? Or 3 included in the 10?
        # The prompt says: "When a teacher generates a quiz... date... number of easy/medium/hard... He can select questions... If he selects only 3 out of 5... generate another 2".
        # This implies the target_counts are the TOTAL desired.
        
        current_existing = sum(1 for q in generated_questions if q.get('difficulty') == diff_level)
        needed = count - current_existing
        
        if needed <= 0:
            continue
            
        current_generated_for_diff = 0
        retries = 0
        
        while current_generated_for_diff < needed and retries < max_retries * needed:
            # Rotate chunks
            chunk = top_chunks[chunk_index % len(top_chunks)]
            chunk_text = chunk.text
            
            # Generate
            mcq = generate_mcq_phi3(context_chunk=chunk_text, difficulty=diff_level)
            
            if mcq:
                # Check duplicates
                if not any(q['question'] == mcq['question'] for q in generated_questions):
                    generated_questions.append(mcq)
                    current_generated_for_diff += 1
                    chunk_index += 1
                else:
                    retries += 1
            else:
                retries += 1
                
    if not generated_questions:
        raise HTTPException(status_code=500, detail="Failed to generate any questions.")
        
    return generated_questions

def finalize_quiz(
    db: Session,
    lecture_note_id: int,
    topic: str,
    difficulty: str, # Overall difficulty label
    questions: list[dict]
):
    """
    Saves a list of question dicts as a finalized Quiz.
    """
    note = db.query(LectureNote).get(lecture_note_id)
    if not note:
        raise HTTPException(404, "Lecture note not found during finalization")

    diff_title = difficulty.capitalize()
    
    new_quiz = Quiz(
        course_id=note.course_id,
        created_by=note.uploaded_by,
        lecture_notes_id=note.id,
        title=f"Quiz: {topic}",
        total_questions=len(questions),
        avg_difficulty=diff_title,
        total_time_mins=sum(q.get('time_secs', 60) for q in questions) // 60,
        total_marks=len(questions),
        created_at=datetime.utcnow() 
    )
    
    db.add(new_quiz)
    db.commit()
    db.refresh(new_quiz)
    
    # Save Questions
    for idx, mcq in enumerate(questions):
        question = QuizQuestion(
            quiz_id=new_quiz.id,
            q_order=idx + 1,
            question_text=mcq.get('question'),
            option_a=mcq['options']['A'],
            option_b=mcq['options']['B'],
            option_c=mcq['options']['C'],
            option_d=mcq['options']['D'],
            correct_option=mcq.get('correct'),
            difficulty=mcq.get('difficulty'),
            time_secs=mcq.get('time_secs', 60),
            marks=1
        )
        db.add(question)
        
        # Save to Library (if not exists)
        exists = db.query(QuestionLibrary).filter(
            QuestionLibrary.lecture_note_id == lecture_note_id,
            QuestionLibrary.question_text == mcq['question']
        ).first()
        
        if not exists:
            q_lib = QuestionLibrary(
                lecture_note_id=lecture_note_id,
                question_text=mcq['question'],
                option_a=mcq['options']['A'],
                option_b=mcq['options']['B'],
                option_c=mcq['options']['C'],
                option_d=mcq['options']['D'],
                correct_option=mcq['correct'],
                difficulty=mcq['difficulty'],
                time_secs=mcq.get('time_secs', 60),
                question_quality='good_question'
            )
            db.add(q_lib)
        
    db.commit()
    
    return {
        "quiz_id": new_quiz.id,
        "questions_saved": len(questions),
        "topic": topic,
        "difficulty": diff_title
    }
