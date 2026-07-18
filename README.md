# Retail Order Management System

A Salesforce-native retail order management solution built with **Salesforce DX (SFDX)**. It includes a custom data model, bulkified Apex automation for inventory control, a Lightning Web Component dashboard for pending orders, and a record-triggered Flow for delivery notifications.

---

## Features

- **Product catalog** with live inventory (`Available_Stock__c`) and pricing
- **Order management** with status tracking (Pending → Shipped → Delivered)
- **Order line items** linked to orders (Master-Detail) and products (Lookup)
- **Automatic stock deduction** when line items are inserted, with validation if stock is insufficient
- **Roll-up summary** of order totals from line item amounts
- **Pending Orders LWC** — datatable of all orders with `Pending` status
- **Delivery email Flow** — sends a confirmation email when status changes to `Delivered`

---

## Tech Stack

| Layer | Technology |
|---|---|
| Platform | Salesforce (API v62.0) |
| Backend | Apex (Trigger + Handler pattern) |
| Frontend | Lightning Web Components (LWC) |
| Automation | Record-Triggered Flow |
| Tooling | Salesforce CLI (`sf`) |

---

## Data Model

```
Product__c
├── Available_Stock__c   (Number)
└── Price__c             (Currency)

Order__c
├── Customer_Name__c     (Text, required)
├── Status__c            (Picklist: Pending, Shipped, Delivered)
└── Total_Amount__c      (Roll-Up Summary → SUM of Line_Total__c)

Order_Line_Item__c
├── Order__c             (Master-Detail → Order__c)
├── Product__c           (Lookup → Product__c)
├── Quantity__c          (Number, required)
└── Line_Total__c        (Formula: Product__r.Price__c × Quantity__c)
```

> **Note:** `Line_Total__c` is a formula field on the child object. It powers the `Total_Amount__c` roll-up on `Order__c`.

---

## Project Structure

```
retail-order-management/
├── sfdx-project.json
├── config/
│   └── project-scratch-def.json
├── force-app/main/default/
│   ├── objects/
│   │   ├── Product__c/
│   │   ├── Order__c/
│   │   └── Order_Line_Item__c/
│   ├── triggers/
│   │   └── OrderLineItemTrigger.trigger
│   ├── classes/
│   │   ├── OrderLineItemTriggerHandler.cls
│   │   ├── OrderLineItemTriggerHandlerTest.cls
│   │   ├── OrderController.cls
│   │   └── OrderControllerTest.cls
│   ├── lwc/
│   │   └── pendingOrders/
│   ├── flows/
│   │   └── Order_Delivered_Email_Notification.flow-meta.xml
│   ├── tabs/
│   └── permissionsets/
│       └── Retail_Order_Management_User.permissionset-meta.xml
└── README.md
```

---

## Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) (`sf`) installed
- A Salesforce Developer Edition org **or** Dev Hub enabled for scratch orgs
- Git (for version control / GitHub)

---

## Setup & Deployment

### 1. Clone the repository

```bash
git clone https://github.com/<your-username>/retail-order-management.git
cd retail-order-management
```

### 2. Authenticate with Salesforce

```bash
# Production / Developer org
sf org login web --alias retail-dev

# Or create a scratch org (requires Dev Hub)
sf org create scratch \
  --definition-file config/project-scratch-def.json \
  --alias retail-scratch \
  --set-default
```

### 3. Deploy metadata

```bash
sf project deploy start --source-dir force-app
```

### 4. Run Apex tests

```bash
sf apex run test \
  --tests OrderLineItemTriggerHandlerTest OrderControllerTest \
  --result-format human \
  --code-coverage
```

### 5. Assign permissions

```bash
sf org assign permset --name Retail_Order_Management_User
```

### 6. Add the LWC to a Lightning page

1. Open **Setup → Lightning App Builder**
2. Edit a Home or App page
3. Drag the **Pending Orders** component onto the page
4. Save and activate

---

## Component Details

### Apex Trigger — Stock Management

**Trigger:** `OrderLineItemTrigger` (Before Insert on `Order_Line_Item__c`)

**Handler:** `OrderLineItemTriggerHandler`

| Step | Behavior |
|---|---|
| Aggregate | Sums requested quantity per product across all records in the transaction |
| Query | Single SOQL with `FOR UPDATE` to lock product rows |
| Validate | Calls `addError()` if requested quantity exceeds `Available_Stock__c` |
| Deduct | Updates product stock in one DML operation (only when validation passes) |

Designed for bulk inserts — respects governor limits (1 SOQL + 1 DML on products per transaction).

### LWC — `pendingOrders`

Displays a `lightning-datatable` of orders where `Status__c = 'Pending'`.

| File | Purpose |
|---|---|
| `pendingOrders.html` | Card layout, spinner, datatable, empty state |
| `pendingOrders.js` | `@wire` to `OrderController.getPendingOrders` |
| `pendingOrders.js-meta.xml` | Exposes component on App, Home, and Record pages |

**Apex Controller:** `OrderController.getPendingOrders()` — `@AuraEnabled(cacheable=true)` with `WITH SECURITY_ENFORCEMENT`.

### Flow — Delivery Email

**File:** `flows/Order_Delivered_Email_Notification.flow-meta.xml`

| Setting | Value |
|---|---|
| Type | Record-Triggered Flow (After Save) |
| Object | `Order__c` |
| Trigger | Update |
| Entry criteria | `Status__c` Is Changed **AND** equals `Delivered` |
| Action | Send Email (Simple) |

For production use, replace the demo recipient (`$User.Email`) with a customer email field on the order.

---

## Manual Testing Checklist

1. Create **Products** with `Available_Stock__c` and `Price__c`
2. Create an **Order** with `Status__c = Pending`
3. Add **Order Line Items** — verify stock decreases on the product
4. Try ordering more units than available — insert should fail with an error
5. Open the **Pending Orders** LWC — confirm only Pending orders appear
6. Change an order status to **Delivered** — verify the Flow email fires

---

## Sample Test Data

| Object | Sample Record |
|---|---|
| Product__c | Name: `Widget A`, Stock: `100`, Price: `25.00` |
| Order__c | Customer: `Jane Doe`, Status: `Pending` |
| Order_Line_Item__c | Product: Widget A, Quantity: `10` → Stock becomes `90`, Line Total: `$250` |

---

## Push to GitHub

```bash
git init
git add .
git commit -m "Add Retail Order Management System for Salesforce"
git branch -M main
git remote add origin https://github.com/<your-username>/retail-order-management.git
git push -u origin main
```

---

## License

This project is provided as-is for learning and portfolio purposes. Adjust and extend as needed for your organization.

---

## Author

Built as a Salesforce portfolio project demonstrating declarative + programmatic best practices on the Salesforce platform.
