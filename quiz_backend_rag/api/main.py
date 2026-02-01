from fastapi import FastAPI
from api.routers import teachers_router, students_router,retrieval_records_router , courses_router, teaches_router, enrollments_router, lecture_notes_router, quizzes_router, quiz_questions_router, assignments_router, attempts_router, search_router, auth_router, question_library_router
import api.database as database

app = FastAPI(title="Quiz Generation & Assessment API")

# include routers
app.include_router(auth_router.router)
app.include_router(teachers_router.router)
app.include_router(students_router.router)
app.include_router(courses_router.router)
app.include_router(teaches_router.router)
app.include_router(enrollments_router.router)
app.include_router(lecture_notes_router.router)
app.include_router(quizzes_router.router)
app.include_router(quiz_questions_router.router)
app.include_router(assignments_router.router)
app.include_router(attempts_router.router)
app.include_router(question_library_router.router) # Added question_library_router
app.include_router(retrieval_records_router.router)
app.include_router(search_router.router)


# create tables if needed (optional)
@app.on_event("startup")
def startup_event():
    database.Base.metadata.create_all(bind=database.engine)
