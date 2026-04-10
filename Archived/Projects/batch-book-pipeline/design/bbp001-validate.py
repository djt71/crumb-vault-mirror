"""BBP-001: API validation — 3 test books through Gemini 3.1 Pro.

Uploads PDFs, counts tokens, generates with each template, saves samples.
"""

import os
import sys
import json
import time
from pathlib import Path

from google import genai

# --- Config ---
API_KEY = os.environ["GEMINI_API_KEY"]
MODEL = "gemini-3.1-pro-preview"
BASE = Path("/Users/tess/crumb-vault")
PDF_DIR = BASE / "_inbox" / "bbp-pdfs"
SAMPLES_DIR = BASE / "Projects" / "batch-book-pipeline" / "design" / "samples"

BOOKS = [
    {
        "name": "Augustine — Confessions",
        "path": PDF_DIR / "nonfiction" / "The Confessions of St Augustine.pdf",
        "genre": "nonfiction",
        "templates": ["book-digest"],
    },
    {
        "name": "Wu — Attention Merchants",
        "path": PDF_DIR / "nonfiction" / "The Attention Merchants The Epic Struggle to Get Inside Our Heads.pdf",
        "genre": "nonfiction",
        "templates": ["book-digest"],
    },
    {
        "name": "Dostoyevsky — Brothers Karamazov",
        "path": PDF_DIR / "fiction" / "The Brothers Karamazov - Fyodor Dostoyevsky.pdf",
        "genre": "fiction",
        "templates": ["fiction-digest"],
    },
]

# Chapter-digest on the shortest book (Augustine) to keep cost down
CHAPTER_DIGEST_BOOK = 0  # index into BOOKS

# --- Prompts (rough adaptation from NLM templates — strip NLM-specific language) ---

PROMPT_BOOK_DIGEST = """Please provide a deep, comprehensive digest of this book.

Begin with a top-level heading:

# [Book Title] by [Author]

Then structure your response with these exact headings:

## Core Thesis
The book's central argument in a full paragraph. What problem is the author addressing, why does it matter, and what is their framework?

## Key Arguments
Each major argument as a separate paragraph. State the claim, the evidence, and how it connects to the thesis.

## Key Concepts & Frameworks
The most important concepts. Format each as:
- **Concept Name** — What it means, how the author uses it, and a concrete example from the text.

## Notable Quotes
8-12 significant quotes with page/location references. Prioritize quotes that capture the author's voice or crystallize key arguments. Format as blockquotes.

## Checklists & Procedures
If the book contains procedures, checklists, or decision frameworks, reproduce using checkbox syntax (- [ ]) and numbered lists. If none, write "Not applicable."

## Tables & Structured Data
If the book contains tables, matrices, or taxonomies, reproduce as markdown tables. If none, write "Not applicable."

## Takeaways & Applications
Concrete applications: who benefits, in what situation, what would they do differently?

## Uncertain / Needs Verification
Flag unsupported or weakly evidenced claims. If none, write "None identified."

## Connections
Connections to other books, ideas, or fields."""

PROMPT_FICTION_DIGEST = """Please provide a digest of this novel focused on its ideas, themes, and memorable language — not a plot summary.

Begin with a top-level heading:

# [Book Title] by [Author]

Then structure your response with these exact headings:

## Premise
What the book is about in 2-3 sentences. Setting, situation, central tension. Just enough to orient someone who hasn't read it. Do not summarize the plot.

## Themes & Ideas
The major themes the author explores. For each: what it is, how it manifests in the story, and what perspective the author presents through it. Give each theme its own paragraph. This is the core of the note.

## Character Study
Major characters and what they represent or illuminate. Focus on what is interesting about each character's arc, what they reveal about the themes, and how they change. This is analysis, not a character list.

## Craft & Style
What is distinctive about how this book is written? Narrative structure, prose style, notable techniques. If the craft is unremarkable, write "No distinctive craft elements to note."

## Notable Quotes
8-12 memorable passages with page/location references. Prioritize lines that crystallize a theme, capture the author's voice, or are worth reading again. Format as blockquotes with brief context notes where helpful.

## Resonance & Connections
What questions does the book raise? What does it challenge? Connections to other works, ideas, or thinkers. This section is an invitation to think, not a prescription.

## Context
OPTIONAL — include only if it materially affects interpretation. When written, relevant biographical or historical context, literary context. Skip entirely if the book stands on its own."""

PROMPT_CHAPTER_DIGEST = """Please provide a chapter-by-chapter digest of this entire book.

Begin with a top-level heading:

# [Book Title] by [Author]

For each chapter, use an H3 heading and include:

### Chapter N: [Title]

**Summary** — 2-3 paragraph summary of the chapter's argument, what it builds on from prior chapters, and what it sets up.

**Key Points** — the chapter's main claims with evidence.

**Notable Quotes** — 2-3 per chapter with page references, as blockquotes.

**Checklists & Procedures** — if present in this chapter, reproduce using checkbox syntax. If none, skip.

**Tables & Structured Data** — if present, reproduce as markdown tables. If none, skip.

After all chapters, include these two synthesis sections:

## Argument Arc
How does the book's argument develop across chapters? Which chapters are foundational vs. which apply or extend? Are there structural patterns (e.g., theory→evidence→application)?

## Cross-Chapter Connections
What themes or concepts recur across multiple chapters? How does the author build, revisit, or complicate ideas as the book progresses?"""


def upload_and_wait(client, path):
    """Upload PDF and poll until ACTIVE."""
    print(f"  Uploading {path.name} ({path.stat().st_size / 1024 / 1024:.1f} MB)...")
    uploaded = client.files.upload(file=str(path))
    # Poll for ACTIVE state
    for i in range(30):
        status = client.files.get(name=uploaded.name)
        if status.state.name == "ACTIVE":
            print(f"  File active: {uploaded.name}")
            return uploaded
        print(f"  Waiting for file processing... ({status.state.name})")
        time.sleep(2)
    raise TimeoutError(f"File {path.name} did not become ACTIVE after 60s")


def count_tokens(client, uploaded_file):
    """Count tokens for an uploaded file."""
    response = client.models.count_tokens(
        model=MODEL,
        contents=[uploaded_file],
    )
    return response


def generate(client, uploaded_file, prompt):
    """Generate content with file + prompt."""
    response = client.models.generate_content(
        model=MODEL,
        contents=[uploaded_file, prompt],
    )
    return response


def evaluate_output(text, template_type):
    """Check structural completeness of output."""
    if template_type == "book-digest":
        required = ["## Core Thesis", "## Key Arguments", "## Key Concepts"]
        optional = ["## Notable Quotes", "## Checklists", "## Tables", "## Takeaways", "## Uncertain", "## Connections"]
    elif template_type == "fiction-digest":
        required = ["## Premise", "## Themes & Ideas", "## Character Study"]
        optional = ["## Craft & Style", "## Notable Quotes", "## Resonance", "## Context"]
    elif template_type == "chapter-digest":
        required = ["### Chapter"]
        optional = ["## Argument Arc", "## Cross-Chapter Connections"]
    else:
        return {}

    found_required = [h for h in required if h in text]
    found_optional = [h for h in optional if h in text]
    missing_required = [h for h in required if h not in text]

    return {
        "required_found": found_required,
        "required_missing": missing_required,
        "optional_found": found_optional,
        "word_count": len(text.split()),
        "complete": len(missing_required) == 0,
    }


def main():
    client = genai.Client(api_key=API_KEY)
    results = []

    # Phase 1: Upload all PDFs
    print("=== Phase 1: Upload PDFs ===")
    uploaded_files = {}
    for book in BOOKS:
        uploaded_files[book["name"]] = upload_and_wait(client, book["path"])

    # Phase 2: Count tokens
    print("\n=== Phase 2: Count Tokens ===")
    from pypdf import PdfReader
    for book in BOOKS:
        uf = uploaded_files[book["name"]]
        token_resp = count_tokens(client, uf)
        reader = PdfReader(str(book["path"]))
        pages = len(reader.pages)
        total_tokens = token_resp.total_tokens
        tokens_per_page = total_tokens / pages if pages > 0 else 0
        print(f"  {book['name']}: {pages} pages, {total_tokens:,} tokens ({tokens_per_page:.0f} tok/page)")
        book["pages"] = pages
        book["total_tokens"] = total_tokens
        book["tokens_per_page"] = tokens_per_page

    # Phase 3: Generate with primary template for each book
    print("\n=== Phase 3: Generate (primary templates) ===")
    prompts = {
        "book-digest": PROMPT_BOOK_DIGEST,
        "fiction-digest": PROMPT_FICTION_DIGEST,
        "chapter-digest": PROMPT_CHAPTER_DIGEST,
    }

    for book in BOOKS:
        template = book["templates"][0]
        uf = uploaded_files[book["name"]]
        print(f"\n  Generating {template} for {book['name']}...")
        t0 = time.time()
        resp = generate(client, uf, prompts[template])
        elapsed = time.time() - t0
        text = resp.text
        eval_result = evaluate_output(text, template)

        # Save sample
        safe_name = book["name"].replace(" — ", "-").replace(" ", "-").lower()
        sample_path = SAMPLES_DIR / f"{safe_name}-{template}.md"
        sample_path.write_text(text, encoding="utf-8")
        print(f"  Saved: {sample_path.name}")
        print(f"  Time: {elapsed:.1f}s | Words: {eval_result['word_count']} | Complete: {eval_result['complete']}")
        if eval_result.get("required_missing"):
            print(f"  MISSING REQUIRED: {eval_result['required_missing']}")

        book[f"result_{template}"] = {
            "elapsed_s": round(elapsed, 1),
            "word_count": eval_result["word_count"],
            "complete": eval_result["complete"],
            "required_missing": eval_result.get("required_missing", []),
            "optional_found": eval_result.get("optional_found", []),
            "sample_file": sample_path.name,
        }
        # usage metadata
        if hasattr(resp, 'usage_metadata') and resp.usage_metadata:
            um = resp.usage_metadata
            book[f"result_{template}"]["input_tokens"] = um.prompt_token_count
            book[f"result_{template}"]["output_tokens"] = um.candidates_token_count
            print(f"  Tokens: {um.prompt_token_count:,} in / {um.candidates_token_count:,} out")

    # Phase 4: Chapter-digest on Augustine (shortest book)
    print("\n=== Phase 4: Chapter-digest test ===")
    book = BOOKS[CHAPTER_DIGEST_BOOK]
    uf = uploaded_files[book["name"]]
    print(f"  Generating chapter-digest for {book['name']}...")
    t0 = time.time()
    resp = generate(client, uf, prompts["chapter-digest"])
    elapsed = time.time() - t0
    text = resp.text
    eval_result = evaluate_output(text, "chapter-digest")

    safe_name = book["name"].replace(" — ", "-").replace(" ", "-").lower()
    sample_path = SAMPLES_DIR / f"{safe_name}-chapter-digest.md"
    sample_path.write_text(text, encoding="utf-8")
    print(f"  Saved: {sample_path.name}")
    print(f"  Time: {elapsed:.1f}s | Words: {eval_result['word_count']} | Complete: {eval_result['complete']}")
    if hasattr(resp, 'usage_metadata') and resp.usage_metadata:
        um = resp.usage_metadata
        print(f"  Tokens: {um.prompt_token_count:,} in / {um.candidates_token_count:,} out")
        book["result_chapter-digest"] = {
            "elapsed_s": round(elapsed, 1),
            "word_count": eval_result["word_count"],
            "complete": eval_result["complete"],
            "input_tokens": um.prompt_token_count,
            "output_tokens": um.candidates_token_count,
            "sample_file": sample_path.name,
        }

    # Phase 5: Summary
    print("\n=== Summary ===")
    for book in BOOKS:
        print(f"\n{book['name']}:")
        print(f"  Pages: {book['pages']} | Tokens: {book['total_tokens']:,} ({book['tokens_per_page']:.0f}/page)")
        for tmpl in book["templates"] + (["chapter-digest"] if book is BOOKS[CHAPTER_DIGEST_BOOK] else []):
            key = f"result_{tmpl}"
            if key in book:
                r = book[key]
                status = "PASS" if r["complete"] else "FAIL"
                print(f"  {tmpl}: {status} | {r['word_count']} words | {r['elapsed_s']}s", end="")
                if "input_tokens" in r:
                    print(f" | {r['input_tokens']:,} in / {r['output_tokens']:,} out", end="")
                print()

    # Save telemetry
    telemetry_path = SAMPLES_DIR / "bbp001-telemetry.json"
    # Strip non-serializable fields
    serializable = []
    for book in BOOKS:
        entry = {k: v for k, v in book.items() if k != "path"}
        entry["path"] = str(book["path"])
        serializable.append(entry)
    telemetry_path.write_text(json.dumps(serializable, indent=2), encoding="utf-8")
    print(f"\nTelemetry saved: {telemetry_path}")


if __name__ == "__main__":
    main()
