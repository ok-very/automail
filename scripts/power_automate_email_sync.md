# Power Automate Email Sync Flow

This guide helps you set up a Power Automate Cloud flow to automatically save new Outlook 365 emails to your local `emails\inbox` folder.

## Prerequisites

1. **Power Automate Premium** or a work account with Power Automate access
2. **OneDrive for Business** (used as a bridge to sync files locally)
3. **OneDrive Desktop App** installed and syncing

> **Note**: Power Automate Cloud flows cannot write directly to local folders. We use OneDrive as a bridge, which syncs to your local machine.

---

## Flow Overview

**Trigger**: When a new email arrives in Outlook 365  
**Actions**:
1. Create a folder for each email (named by date + subject)
2. Save email metadata as JSON
3. Save email body as HTML
4. Save all attachments

---

## Step-by-Step Setup

### Step 1: Create the Flow

1. Go to [Power Automate](https://make.powerautomate.com)
2. Click **Create** → **Automated cloud flow**
3. Name it: `Email to Local Folder Sync`
4. Choose trigger: **When a new email arrives (V3)** - Office 365 Outlook
5. Click **Create**

### Step 2: Configure the Trigger

Set these trigger options:
- **Folder**: Inbox (or your preferred folder)
- **Include Attachments**: Yes
- **Only with Attachments**: No (unless you only want attachments)

### Step 3: Add Initialize Variable (for folder name)

1. Click **+ New step** → search for **Initialize variable**
2. Configure:
   - **Name**: `EmailFolderName`
   - **Type**: String
   - **Value**: Use this expression:
   ```
   concat(formatDateTime(triggerOutputs()?['body/receivedDateTime'], 'yyyy-MM-dd_HHmmss'), '_', replace(replace(replace(triggerOutputs()?['body/subject'], '/', '-'), '\', '-'), ':', '-'))
   ```

### Step 4: Create Email Folder in OneDrive

1. Click **+ New step** → search for **Create folder** (OneDrive for Business)
2. Configure:
   - **Folder Path**: `/Emails/inbox/@{variables('EmailFolderName')}`

### Step 5: Save Email Metadata as JSON

1. Click **+ New step** → search for **Create file** (OneDrive for Business)
2. Configure:
   - **Folder Path**: `/Emails/inbox/@{variables('EmailFolderName')}`
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
     "conversationId": "@{triggerOutputs()?['body/conversationId']}"
   }
   ```

### Step 6: Save Email Body as HTML

1. Click **+ New step** → search for **Create file** (OneDrive for Business)
2. Configure:
   - **Folder Path**: `/Emails/inbox/@{variables('EmailFolderName')}`
   - **File Name**: `body.html`
   - **File Content**: Select **Body** from dynamic content (this is the HTML body)

### Step 7: Save Attachments (Apply to Each)

1. Click **+ New step** → search for **Apply to each**
2. Select **Attachments** from dynamic content as the input
3. Inside the loop, add **Create file** (OneDrive for Business):
   - **Folder Path**: `/Emails/inbox/@{variables('EmailFolderName')}/attachments`
   - **File Name**: `@{items('Apply_to_each')?['name']}`
   - **File Content**: `@{base64ToBinary(items('Apply_to_each')?['contentBytes'])}`

### Step 8: Save and Test

1. Click **Save** in the top right
2. Send yourself a test email with an attachment
3. Check your OneDrive → Emails → inbox folder

---

## Sync to Local Folder

### Option A: OneDrive Sync (Recommended)

1. Open OneDrive desktop app
2. Right-click the **Emails** folder in OneDrive
3. Select **Always keep on this device**
4. Create a symbolic link to your emails folder:

Open PowerShell as Administrator and run:
```powershell
# Adjust paths as needed
$onedrivePath = "$env:USERPROFILE\OneDrive - YourCompany\Emails\inbox"
$localPath = "C:\Users\Neal\Documents\emails\inbox"

# Create symbolic link (run as admin)
New-Item -ItemType SymbolicLink -Path $localPath -Target $onedrivePath -Force
```

### Option B: Power Automate Desktop (Direct Local Save)

For direct local folder access, you need **Power Automate Desktop**. See the companion script `power_automate_desktop_flow.txt` for a PAD flow.

---

## Flow JSON Export

You can import this flow definition. Go to **My flows** → **Import** → **Import Package (Legacy)**:

Save the content below as `email_sync_flow.zip` after base64 decoding, or manually recreate following the steps above.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Flow not triggering | Check Outlook connection, verify folder selection |
| Attachments empty | Ensure "Include Attachments" is Yes in trigger |
| Special characters in subject | The expression in Step 3 handles common cases |
| Large attachments failing | Check OneDrive storage limits |

---

## Customization Options

### Filter by Sender
In the trigger, add a condition:
- **From**: contains `@specificdomain.com`

### Filter by Subject
Add a **Condition** action after the trigger:
- If `Subject` contains `[Important]` → proceed
- Else → terminate

### Organize by Sender
Modify the folder path to include sender:
```
/Emails/inbox/@{triggerOutputs()?['body/from']?['emailAddress']?['address']}/@{variables('EmailFolderName')}
```
