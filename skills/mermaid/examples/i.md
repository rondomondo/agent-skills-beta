# Git Branching Strategy

```mermaid
---
title: Git Branching Strategy
---

gitGraph
    commit id: "Initial commit"
    branch develop
    checkout develop
    commit id: "Setup project structure"
    
    branch feature/user-auth
    checkout feature/user-auth
    commit id: "Add login component"
    commit id: "Add registration"
    commit id: "Add password reset"
    
    checkout develop
    branch feature/dashboard
    checkout feature/dashboard
    commit id: "Create dashboard layout"
    commit id: "Add widgets"
    
    checkout develop
    merge feature/user-auth
    commit id: "Update dependencies"
    
    checkout feature/dashboard
    commit id: "Fix responsive design"
    
    checkout develop
    merge feature/dashboard
    
    checkout main
    merge develop
    commit id: "Release v1.0.0"
    
    checkout develop
    commit id: "Hotfix preparation"

```
