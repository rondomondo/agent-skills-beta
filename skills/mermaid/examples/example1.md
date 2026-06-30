## [SLO] Component Relationship

```mermaid
---
title: SLO Component Relationship
---

flowchart TB
    SLI[SLI - Actual Measurements]:::measurementNode --> SLO[SLO - Target Objectives]:::objectiveNode
    SLO --> EB[Error Budget]:::budgetNode
    EB --> EBP[Error Budget Policy]:::policyNode
    
    subgraph Reliability Metrics
    MTBF[Mean Time Between Failures]:::timeMetricNode
    MTTR[Mean Time To Recovery]:::timeMetricNode
    end
    
    MTBF --> REL[System Reliability]:::reliabilityNode
    MTTR --> REL
    
    subgraph Error Budget Management
    EB --> EBC[Error Budget Consumption]:::consumptionNode
    EBC --> EPA[Policy Actions]:::actionNode
    EPA --> FR[Feature Releases]:::outputNode
    EPA --> DR[Deployment Restrictions]:::outputNode
    end

    classDef measurementNode fill:#4CAF50,stroke:#2E7D32,color:white
    classDef objectiveNode fill:#2196F3,stroke:#1976D2,color:white
    classDef budgetNode fill:#FF9800,stroke:#F57C00,color:white
    classDef policyNode fill:#9C27B0,stroke:#7B1FA2,color:white
    classDef timeMetricNode fill:#00BCD4,stroke:#0097A7,color:white
    classDef reliabilityNode fill:#3F51B5,stroke:#303F9F,color:white
    classDef consumptionNode fill:#FF5722,stroke:#E64A19,color:white
    classDef actionNode fill:#795548,stroke:#5D4037,color:white
    classDef outputNode fill:#607D8B,stroke:#455A64,color:white

    classDef subgraphStyle fill:#f5f5f5,stroke:#cccccc,stroke-width:2px
    class ReliabilityMetrics,ErrorBudgetManagement subgraphStyle
```


[Frameworks]: https://alertstack.io/frameworks

[Observability Frameworks]: https://alertstack.io/frameworks

[SLO]: https://sre.google/sre-book/service-level-objectives/

[SLI]: https://www.sumologic.com/glossary/sli-service-level-indicator/

[SLA]: https://sre.google/sre-book/service-level-objectives/

[MTTR]: https://www.blameless.com/blog/mttr

[MTBF]: https://www.blameless.com/blog/mttr

[MTTA]: https://www.blameless.com/blog/mttr

[MTTR]: https://www.blameless.com/blog/mttr

[RED]: https://www.splunk.com/en_us/blog/learn/red-monitoring.html

[DURESS]: https://sre.google/sre-book/service-level-objectives/

[DUNE]: https://sre.google/sre-book/service-level-objectives/

[USE]: https://sre.google/sre-book/service-level-objectives/

[CELTE]: https://sre.google/sre-book/service-level-objectives/

[4 Signals]: https://sre.google/sre-book/monitoring-distributed-systems/#xref_monitoring_golden-signals

[Error Budget Policy]: https://sre.google/workbook/error-budget-policy

[SLO Document]: https://sre.google/workbook/slo-document/

