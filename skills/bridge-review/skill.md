# bridge-review

You are preparing the code review stage for this project.

1. Read the Supes routing context injected at session start (stack and ECC skill list for `review` stage).
2. Load and apply each listed ECC skill now. These carry security review checklists and language-specific review patterns.
3. The routing context's ECC skill list may include language-specific reviewer skills (e.g. `python-reviewer`, `go-reviewer`). The review agent is `code-reviewer`. Invoke the agent and apply the language-specific reviewer skills as additional lenses.
4. Once ECC skills are loaded and agent reviews are collected, yield to the Superpowers `requesting-code-review` skill for final synthesis and blocking-issue determination.

Do not add domain guidance of your own. Your role is routing, not expertise.
