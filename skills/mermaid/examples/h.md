# Order Status State Machine

```mermaid
---
title: Order Status State Machine
---

stateDiagram-v2
    [*] --> Draft
    Draft --> Pending : submit_order
    Pending --> Confirmed : payment_received
    Pending --> Cancelled : timeout
    Pending --> Cancelled : user_cancel
    Confirmed --> Processing : start_fulfillment
    Processing --> Shipped : items_shipped
    Processing --> Cancelled : out_of_stock
    Shipped --> Delivered : delivery_confirmed
    Shipped --> Returned : return_requested
    Delivered --> Completed : [*]
    Returned --> Refunded : process_return
    Cancelled --> [*]
    Refunded --> [*]
    
    Pending : Payment pending
    Confirmed : Payment confirmed
    Processing : Preparing items
    Shipped : In transit
    Delivered : Successfully delivered
    Cancelled : Order cancelled
    Returned : Return in progress
    Refunded : Refund processed
    Completed : Order complete

```
