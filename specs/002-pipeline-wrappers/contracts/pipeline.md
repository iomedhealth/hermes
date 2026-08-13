# Pipeline Contract

Each stage function MUST:
1. Accept an S3 object of the preceding stage's class (except `init` which takes a `cdm`).
2. Return a new S3 object appending the stage's specific outputs.
3. Not mutate the OMOP `cdm` tables. All intermediate tables must be in a scratch schema or memory.