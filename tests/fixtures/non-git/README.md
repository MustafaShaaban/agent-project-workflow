# Fixture: non-git

This fixture simulates a directory that has not been initialized as a Git repository.
Used to test that audit and guard scripts correctly detect the absence of Git and report it.

Expected audit result: Git not initialized. Risk reported.
