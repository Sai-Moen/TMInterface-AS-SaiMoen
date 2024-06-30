"""Builds local version of Jekyll site. Run init_site before this."""

from utils import PROJECT_SITE, PROJECT_SITE_LOCAL

BOILERPLATE = """---
---

<link href="{{ 'assets/css/style.css' | relative_url }}" rel="stylesheet">

"""

def main():
    for root, dirs, files in PROJECT_SITE.walk():
        local = PROJECT_SITE_LOCAL / root.relative_to(PROJECT_SITE)

        for d in dirs:
            (local / d).mkdir(exist_ok=True)

        for f in files:
            file = root / f
            if file.suffix == ".md":
                text = preprocess_markdown(file.read_text())
                (local / f).write_text(text)
            else:
                data = file.read_bytes()
                (local / f).write_bytes(data)

def preprocess_markdown(text: str) -> str:
    # fixes links not working (lol)
    return BOILERPLATE + text.replace(".md)", ".html)")

if __name__ == "__main__":
    main()
