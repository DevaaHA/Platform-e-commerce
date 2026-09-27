from fastapi import FastAPI, Form, HTTPException
from pydantic import BaseModel
from enum import Enum
import uvicorn
import requests
import math
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import HuggingFaceEmbeddings

app = FastAPI(title="SouqJO AI Microservice", description="محرك الذكاء الاصطناعي الشامل")

# --- إعدادات الذكاء الاصطناعي ---
embeddings = HuggingFaceEmbeddings(model_name="sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2")
mock_products = [
    {"name": "حذاء رياضي", "description": "حذاء مريح للمشي والجري لمسافات طويلة"},
    {"name": "بنطلون جينز", "description": "جينز قطني أزرق مناسب للطلعات اليومية"},
    {"name": "عباية ملكية", "description": "عباية سوداء مطرزة بلمسات ملكية للمناسبات الرسمية"},
    {"name": "قميص كلاسيك", "description": "قميص رسمي أبيض مناسب للعمل والاجتماعات"}
]
vector_store = Chroma.from_texts(
    texts=[f"{p['name']} - {p['description']}" for p in mock_products],
    embedding=embeddings,
    persist_directory="./chroma_db"
)

# --- دوال الذكاء الاصطناعي ---
def get_ai_response(user_query, context):
    prompt = f"أنت مساعد تسوق خبير في متجر SouqJo. المنتجات المتاحة: {context}. أجب على سؤال العميل: {user_query}. كن ودوداً ومقنعاً."
    try:
        response = requests.post("http://localhost:11434/api/generate", json={
            "model": "llama3", "prompt": prompt, "stream": False
        })
        return response.json().get('response', "عذراً، لم أستطع الرد.")
    except: return "المحرك الذكي غير متصل."

def query_products(query):
    results = vector_store.similarity_search(query, k=2)
    return [res.page_content for res in results]

# --- منطق المقاسات ---
class ClothingCategory(str, Enum):
    SHIRT = "بلايز وقمصان"; JEANS = "بنطلون جينز"; DRESS_PANTS = "بنطلون قماش"; ABAYA = "عباية"; SHOES = "حذاء"

@app.post("/api/v1/recommend-size")
async def recommend_size(height: float = Form(...), weight: float = Form(...), category: ClothingCategory = Form(...)):
    bmi = weight / ((height / 100) ** 2)
    if category == ClothingCategory.ABAYA: size = f"{round(((height / 2.54) - 8) / 2) * 2}"
    elif category == ClothingCategory.JEANS: 
        w = int(round((30 + ((bmi - 20) * 0.8) if bmi > 20 else 30) / 2) * 2)
        l = 30 if height < 165 else 32 if height < 180 else 34 if height < 190 else 36
        size = f"W{w} L{l}"
    elif category == ClothingCategory.SHOES: size = f"{round((height / 4.15) * 2) / 2}"
    else: size = "M" # تبسيط
    return {"recommended_size": size, "clothing_type": category.value}

@app.post("/api/v1/ask-ai")
async def ask_ai(query: str = Form(...)):
    context = query_products(query)
    ai_answer = get_ai_response(query, context)
    return {"query": query, "ai_answer": ai_answer}

if __name__ == "__main__":
    uvicorn.run("app:app", host="0.0.0.0", port=8000)