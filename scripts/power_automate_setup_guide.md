# Power Automate Email Parser - Step-by-Step Configuration Guide

Follow these steps in Power Automate to add intelligent metadata extraction to your existing email trigger.

---

## Starting Point
You should have a flow open with **"When a new email arrives (V3)"** trigger already configured.

---

## Step 1: Add Initialize Variables (Add 8 Variables)

After the trigger, click **+ New step** → search for **Initialize variable**. Add each of these:

| Variable Name | Type | Initial Value |
|--------------|------|---------------|
| `ProjectName` | String | `_Uncategorized` |
| `DeveloperName` | String | *(leave empty)* |
| `ConstructionPhase` | String | *(leave empty)* |
| `ProjectStage` | String | `Unknown` |
| `ActionType` | String | `General` |
| `Priority` | Integer | `3` |
| `StakeholderType` | String | `Unknown` |
| `DocumentTypes` | String | *(leave empty)* |
| `VIPContacts` | String | *(placeholder - add domains later)* |
| `EmailFolderName` | String | *(leave empty)* |

> **Note**: `VIPContacts` is a placeholder. You can later populate it with comma-separated domains to flag important senders.

---

## Step 2: Set Email Folder Name

1. Click **+ New step** → search for **Compose**
2. Name it: `Create Safe Folder Name`
3. In **Inputs**, use this expression:
```
concat(
  formatDateTime(triggerOutputs()?['body/receivedDateTime'], 'yyyy-MM-dd_HHmmss'),
  '_',
  take(
    replace(replace(replace(replace(
      triggerOutputs()?['body/subject'],
      '/', '-'), '\', '-'), ':', '-'), '?', '-'
    ),
    50
  )
)
```

4. Click **+ New step** → **Set variable**
   - Name: `EmailFolderName`
   - Value: Select the output from the Compose step above

---

## Step 3: Extract Project Information (Developer - Project Pattern)

Based on actual email analysis, subjects follow this pattern:
```
Developer - Project Name - Topic
Example: "Qualex - Artesia - Public Art Report"
Example: "PCI - King George Hub - Phase D - Artwork Acceptance"
```

### Step 3A: Clean the Subject Line

1. Click **+ New step** → search for **Compose**
2. Rename it to `Clean Subject`
3. In **Inputs**, use this expression to strip prefixes:
   ```
   replace(replace(replace(replace(replace(
     triggerOutputs()?['body/subject'],
     'RE: ', ''), 'FW: ', ''), 'Fw: ', ''), '[EXT] ', ''), 'EXTERNAL-', ''
   )
   ```

### Step 3B: Check if Subject Contains Project Pattern

1. Click **+ New step** → **Condition**
2. Configure:
   - **Left value**: Click, go to **Expression** tab, paste:
     ```
     indexOf(outputs('Clean_Subject'), ' - ')
     ```
   - **Operator**: `is greater than`
   - **Right value**: `-1`

This checks if the subject contains ` - ` (the delimiter used in project emails).

### Step 3C: Extract Developer Name (If yes branch)

1. Inside **If yes**, click **Add an action** → **Compose**
2. Rename to `Extract Developer`
3. In **Inputs**, use expression:
   ```
   first(split(outputs('Clean_Subject'), ' - '))
   ```

### Step 3D: Extract Project Name

1. Add another **Compose** action, rename to `Extract Project`
2. Use expression:
   ```
   if(
     greater(length(split(outputs('Clean_Subject'), ' - ')), 1),
     split(outputs('Clean_Subject'), ' - ')[1],
     ''
   )
   ```

### Step 3E: Set the Variables

1. Add **Set variable**:
   - Name: `ProjectName`  
   - Value: Use expression: `concat(outputs('Extract_Developer'), ' - ', outputs('Extract_Project'))`

### Step 3F: Match Against Known Developers (Optional Enhancement)

Add a condition to validate the developer is known:

1. Add **Condition**
2. Use expression in left value:
   ```
   contains('Qualex,Anthem,PCI,Holborn,Intracorp,Beedie,Polygon,Avisina,Peterson,Aryze,Onni,Edgar,Williams,Greystar,PC Urban,Aragon,Dayhu,Bosa', outputs('Extract_Developer'))
   ```
3. Operator: `is equal to` → `true`

If yes: Keep the project name as extracted
If no: Set ProjectName to "Unknown" or leave as full subject

### Step 3G: Extract Construction Phase (Optional)

Construction phases (Phase D, Phase E, Phase 1, etc.) indicate which construction plan the opportunity is associated with.

1. Add **Condition**
2. Use expression in left value:
   ```
   indexOf(outputs('Clean_Subject'), 'Phase ')
   ```
3. Operator: `is greater than` → `-1`

**If yes:**
1. Add **Compose** action, rename to `Extract Phase`
2. Use expression (extracts "Phase X" pattern):
   ```
   concat('Phase ', first(split(last(split(outputs('Clean_Subject'), 'Phase ')), ' ')))
   ```
3. Add **Set variable**:
   - Name: `ConstructionPhase`
   - Value: Output from Extract Phase

### Visual Summary:
```
Subject: "RE: Qualex - Artesia - Public Art Report"
         ↓
Clean Subject: "Qualex - Artesia - Public Art Report"
         ↓
Extract Developer: "Qualex"
         ↓
Extract Project: "Artesia"
         ↓
ProjectName = "Qualex - Artesia"
```

---

## Step 4: Detect Project Stage

Add a **Condition** for each stage keyword. Here's the first one:

1. Click **+ New step** → **Condition**
2. Condition: `Body` → **contains** → `invoice` (case insensitive)

**If yes:**
- Add **Set variable**: `ProjectStage` = `Billing/Invoice`
- Add **Set variable**: `ActionType` = `Invoice`

Add similar conditions for these keywords:

| Keywords to Check | Stage | ActionType |
|-------------------|-------|------------|
| `invoice`, `payment`, `billing` | `Billing/Invoice` | `Invoice` |
| `contract`, `agreement`, `execution` | `Contract Administration` | `Approval` |
| `proposal`, `fee proposal`, `quote` | `Project Initiation` | `Proposal` |
| `meeting`, `schedule`, `availability` | *(don't change stage)* | `Meeting` |
| `urgent`, `asap`, `deadline` | *(don't change stage)* | `Urgent` |
| `attached`, `please find`, `here is` | *(don't change stage)* | `Delivery` |
| `install`, `fabrication`, `production` | `Fabrication/Installation` | `Update` |
| `final report`, `documentation`, `closeout` | `Final Documentation` | `Delivery` |

---

## Step 5: Detect Urgency and Set Priority

1. Click **+ New step** → **Condition**
2. Condition: `Subject` → **contains** → `urgent`
   - OR `Subject` → **contains** → `ASAP`
   - OR `Subject` → **contains** → `deadline`

**If yes:**
- Add **Set variable**: `Priority` = `5`
- Add **Set variable**: `ActionType` = `Urgent`

---

## Step 6: Classify Sender (Stakeholder Type)

1. Click **+ New step** → **Condition**
2. Condition: `From` → **contains** → `@yourcompany.com` (your internal domain)

**If yes:**
- Set `StakeholderType` = `Internal`

**If no (nested conditions):**
- Check if From contains `@city` or `@gov` → Set `StakeholderType` = `Government`
- Check if From contains common client domains → Set `StakeholderType` = `Client`
- Else → Set `StakeholderType` = `External`

---

## Step 7: Detect Document Types from Attachments

1. Click **+ New step** → **Condition**
2. Condition: `Has Attachments` → **is equal to** → `true`

**If yes:**
1. Add **Apply to each** → Select `Attachments`
2. Inside the loop, add multiple conditions:

| Attachment Name Contains | Set DocumentTypes to |
|-------------------------|---------------------|
| `.pdf`, `.docx` | Append `Document, ` |
| `invoice` | Append `Invoice, ` |
| `contract`, `agreement` | Append `Contract, ` |
| `.dwg`, `.dxf`, `drawing` | Append `Drawing, ` |
| `.xlsx`, `.xls` | Append `Spreadsheet, ` |
| `.jpg`, `.png`, `.heic` | Append `Image, ` |

---

## Step 8: Create OneDrive Folder

1. Click **+ New step** → search for **Create folder** (OneDrive for Business)
2. Configure:
   - **Folder Path**: `/Emails/@{variables('ProjectName')}/@{variables('EmailFolderName')}`

> **Note**: Emails are organized by project name. Uncategorized emails go to `_Uncategorized/`.

---

## Step 9: Save Metadata as JSON

1. Click **+ New step** → **Create file** (OneDrive for Business)
2. Configure:
   - **Folder Path**: `/Emails/@{variables('ProjectName')}/@{variables('EmailFolderName')}`
   - **File Name**: `metadata.json`
   - **File Content**:
```json
{
  "id": "@{triggerOutputs()?['body/id']}",
  "subject": "@{triggerOutputs()?['body/subject']}",
  "from": "@{triggerOutputs()?['body/from']}",
  "to": "@{triggerOutputs()?['body/toRecipients']}",
  "cc": "@{triggerOutputs()?['body/ccRecipients']}",
  "receivedDateTime": "@{triggerOutputs()?['body/receivedDateTime']}",
  "hasAttachments": @{triggerOutputs()?['body/hasAttachments']},
  "importance": "@{triggerOutputs()?['body/importance']}",
  "isRead": @{triggerOutputs()?['body/isRead']},
  "projectName": "@{variables('ProjectName')}",
  "projectStage": "@{variables('ProjectStage')}",
  "actionType": "@{variables('ActionType')}",
  "priority": @{variables('Priority')},
  "stakeholderType": "@{variables('StakeholderType')}",
  "documentTypes": "@{variables('DocumentTypes')}",
  "extractedKeywords": "@{variables('ExtractedKeywords')}"
}
```

---

## Step 10: Save Email Body

1. Click **+ New step** → **Create file** (OneDrive for Business)
2. Configure:
   - **Folder Path**: `/Emails/@{variables('ProjectName')}/@{variables('EmailFolderName')}`
   - **File Name**: `body.html`
   - **File Content**: Select **Body** from dynamic content

---

## Step 11: Save Attachments

1. Click **+ New step** → **Condition**
2. Condition: `Has Attachments` → **is equal to** → `true`

**If yes:**
1. Add **Apply to each** → Select `Attachments`
2. Inside, add **Create file** (OneDrive for Business):
   - **Folder Path**: `/Emails/@{variables('ProjectName')}/@{variables('EmailFolderName')}/attachments`
   - **File Name**: `@{items('Apply_to_each')?['name']}`
   - **File Content**: `@{base64ToBinary(items('Apply_to_each')?['contentBytes'])}`

---

## Step 12: Save and Test

1. Click **Save** in the top right
2. Send yourself a test email with subject: `URGENT: Invoice #123 - Avisina P1`
3. Check your OneDrive → Emails → inbox folder
4. Open `metadata.json` to verify extracted fields

---

## Expected Folder Structure

```
OneDrive/
└── Emails/
    ├── Qualex - Artesia/
    │   └── 2026-01-08_091530_Public-Art-Report/
    │       ├── metadata.json
    │       ├── body.html
    │       └── attachments/
    ├── PCI - King George Hub/
    │   └── 2026-01-07_143022_Phase-D-Artwork/
    │       └── ...
    └── _Uncategorized/
        └── 2026-01-06_082145_Team-Meeting/
            └── ...
```

---

## Sync to Local Folder

After OneDrive is receiving emails, create a symbolic link:

```powershell
# Run PowerShell as Administrator
$onedrive = "$env:USERPROFILE\OneDrive\Emails\inbox"
$local = "C:\Users\Neal\Documents\emails\inbox"
New-Item -ItemType SymbolicLink -Path $local -Target $onedrive -Force
```
