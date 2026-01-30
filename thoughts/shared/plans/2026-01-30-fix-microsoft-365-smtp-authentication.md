# Fix Microsoft 365 SMTP Authentication (Error 535 5.7.139)

## Overview

Email sending fails with error `535 5.7.139 Authentication unsuccessful`. This is a Microsoft 365 authentication policy issue - the Rails SMTP configuration is correct, but Microsoft 365 is blocking the authentication request.

## Current State Analysis

**Rails SMTP Configuration (CORRECT):**
- File: [production.rb:68-78](config/environments/production.rb#L68-L78)
- Server: `smtp-mail.outlook.com`
- Port: `587`
- STARTTLS: enabled
- Authentication: `login`
- Username: `pakiety@edk.org.pl`

**Error Analysis:**
The error `535 5.7.139` indicates one or more of these Microsoft 365 settings are blocking authentication:
1. Azure Security Defaults enabled (blocks legacy/basic authentication)
2. SMTP AUTH disabled at organization level
3. SMTP AUTH disabled for specific mailbox
4. MFA "Enforced" status (requires App Password)

## Desired End State

- Email sending works reliably through Microsoft 365 SMTP
- Welcome emails, order confirmations, and other notifications are delivered
- Configuration is documented for future reference

## What We're NOT Doing

- Changing email provider (staying with Microsoft 365)
- Implementing OAuth 2.0 yet (future improvement, required by April 2026)
- Modifying Rails SMTP settings (they are already correct)

## Implementation Approach

The fix requires Microsoft 365 Admin Center configuration changes, not code changes.

---

## Phase 1: Enable SMTP AUTH in Microsoft 365

### Overview
Enable SMTP Client Submission (SMTP AUTH) for the `pakiety@edk.org.pl` account.

### Steps Required:

#### 1.1 Check and Disable Azure Security Defaults (if enabled)

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Azure Active Directory** → **Properties**
3. Click **Manage Security Defaults** at the bottom
4. If **Enable Security Defaults** is set to **Yes**, you need to disable it:
   - Set to **No**
   - Select reason: "My organization is using Conditional Access"
   - Save

**⚠️ Warning:** Disabling Security Defaults reduces security. Consider implementing Conditional Access policies as an alternative if you have Azure AD P1 license.

#### 1.2 Enable SMTP AUTH Organization-Wide

**Option A: Via Exchange Admin Center (GUI)**
1. Go to [Exchange Admin Center](https://admin.exchange.microsoft.com)
2. Navigate to **Settings** → **Mail Flow**
3. Find "**Turn off SMTP AUTH protocol for your organization**"
4. **UNCHECK** this option (to enable SMTP AUTH)
5. Save changes

**Option B: Via PowerShell**
```powershell
# Connect to Exchange Online
Connect-ExchangeOnline -UserPrincipalName admin@edk.org.pl

# Enable SMTP AUTH organization-wide
Set-TransportConfig -SmtpClientAuthenticationDisabled $false

# Verify
Get-TransportConfig | Format-List SmtpClientAuthenticationDisabled
# Should return: SmtpClientAuthenticationDisabled : False
```

#### 1.3 Enable SMTP AUTH for Specific Mailbox

**Option A: Via Microsoft 365 Admin Center (GUI)**
1. Go to [Microsoft 365 Admin Center](https://admin.microsoft.com)
2. Navigate to **Users** → **Active users**
3. Find and click on `pakiety@edk.org.pl`
4. Click **Mail** tab
5. Under **Email apps**, click **Manage email apps**
6. **CHECK** the **Authenticated SMTP** checkbox
7. Click **Save changes**

**Option B: Via PowerShell**
```powershell
# Enable SMTP AUTH for specific mailbox
Set-CASMailbox -Identity pakiety@edk.org.pl -SmtpClientAuthenticationDisabled $false

# Verify
Get-CASMailbox -Identity pakiety@edk.org.pl | Format-List SmtpClientAuthenticationDisabled
# Should return: SmtpClientAuthenticationDisabled : False
```

### Success Criteria:

#### Automated Verification:
- [ ] PowerShell command confirms: `SmtpClientAuthenticationDisabled : False` for TransportConfig
- [ ] PowerShell command confirms: `SmtpClientAuthenticationDisabled : False` for CASMailbox

#### Manual Verification:
- [ ] Azure Security Defaults status is documented
- [ ] SMTP AUTH is enabled in Exchange Admin Center

**Implementation Note**: After completing this phase, proceed to Phase 2 to handle MFA if the issue persists.

---

## Phase 2: Configure MFA App Password (if MFA is enabled)

### Overview
If the account has MFA enabled (especially "Enforced" status), an App Password is required instead of the regular account password.

### Check MFA Status:

1. Go to [Microsoft 365 Admin Center](https://admin.microsoft.com)
2. Navigate to **Users** → **Active users**
3. Click on `pakiety@edk.org.pl`
4. Click **Multifactor authentication** link
5. Check the MFA status:
   - **Disabled**: No App Password needed
   - **Enabled**: App Password recommended
   - **Enforced**: App Password required

### Create App Password (if MFA is enabled):

1. Sign in to [My Account](https://myaccount.microsoft.com) as `pakiety@edk.org.pl`
2. Go to **Security info**
3. Click **Add method** → Select **App password**
4. Give it a name (e.g., "EDK Rails App")
5. Copy the generated 16-character password
6. Update the Kubernetes secret with this password

### Update SMTP Password in Kubernetes:

```bash
# Encode the new app password to base64
echo -n 'your-16-char-app-password' | base64

# Update the secret in _deploy/admin-packages-secrets.yaml
# SMTP_PASSWORD: <base64-encoded-app-password>

# Apply the updated secret
kubectl apply -f _deploy/admin-packages-secrets.yaml

# Restart the deployment to pick up new secret
kubectl rollout restart deployment/admin-packages
```

### Success Criteria:

#### Automated Verification:
- [ ] Kubernetes secret updated with new password
- [ ] Deployment restarted successfully: `kubectl rollout status deployment/admin-packages`

#### Manual Verification:
- [ ] MFA status is documented (Disabled/Enabled/Enforced)
- [ ] App Password created (if MFA enabled)

**Implementation Note**: After completing this phase, proceed to Phase 3 for testing.

---

## Phase 3: Test Email Sending

### Overview
Verify that email sending works after the configuration changes.

### Test via Rails Console:

```ruby
# Connect to production Rails console
kubectl exec -it deployment/admin-packages -- rails console

# Test sending an email
ActionMailer::Base.mail(
  from: ENV['LEADER_EMAIL_FROM'],
  to: 'your-test-email@example.com',
  subject: 'Test Email from EDK',
  body: 'This is a test email to verify SMTP configuration.'
).deliver_now
```

### Test via Telnet/OpenSSL (Optional):

```bash
# Test SMTP connection
openssl s_client -connect smtp-mail.outlook.com:587 -starttls smtp

# Expected: Connection established, certificate shown
```

### Success Criteria:

#### Automated Verification:
- [ ] Rails console email delivery returns success (no exception)
- [ ] OpenSSL connection test shows valid certificate

#### Manual Verification:
- [ ] Test email received in inbox
- [ ] No error in application logs

---

## Phase 4: Monitor and Document

### Overview
Verify production email sending and document the configuration for future reference.

### Check Application Logs:

```bash
# Check recent email-related logs
kubectl logs deployment/admin-packages --tail=100 | grep -i mail
```

### Document Final Configuration:

Update `_deploy/PRODUCTION_SECRETS_SETUP.md` with:
- Which Microsoft 365 settings were changed
- Whether App Password is used
- Date of configuration change

### Success Criteria:

#### Automated Verification:
- [ ] No email errors in application logs for 24 hours

#### Manual Verification:
- [ ] Welcome emails are being sent successfully
- [ ] Order confirmation emails are working
- [ ] Configuration documented

---

## Testing Strategy

### Immediate Testing:
1. Send test email via Rails console
2. Trigger welcome email by creating test user
3. Check email delivery in Microsoft 365 sent items

### Ongoing Monitoring:
1. Check application logs for email errors
2. Monitor Microsoft 365 email queue
3. Verify users receive expected emails

---

## Future Considerations: OAuth 2.0 Migration

**⚠️ IMPORTANT:** Microsoft will permanently disable Basic Authentication for SMTP by **April 30, 2026**.

Before that date, you should migrate to OAuth 2.0 authentication:

1. Register an Azure AD application
2. Configure `SMTP.Send` permission
3. Implement OAuth token generation in Rails
4. Use `ActionMailer` with OAuth2 credentials

This is out of scope for this immediate fix but should be planned for 2025-2026.

---

## References

- [Enable or disable SMTP AUTH in Exchange Online](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/authenticated-client-smtp-submission)
- [Authenticate an IMAP, POP or SMTP connection using OAuth](https://learn.microsoft.com/en-us/exchange/client-developer/legacy-protocols/how-to-authenticate-an-imap-pop-smtp-application-by-using-oauth)
- [Deprecation of Basic authentication in Exchange Online](https://learn.microsoft.com/en-us/exchange/clients-and-mobile-in-exchange-online/deprecation-of-basic-authentication-exchange-online)
- Rails SMTP configuration: [production.rb:68-78](config/environments/production.rb#L68-L78)
