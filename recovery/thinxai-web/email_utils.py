#!/usr/bin/env python3
"""
Email utility for ThinxAI Web - standalone email capability.
Uses Gmail SMTP with app password authentication.
"""

import smtplib
import os
import uuid
from datetime import datetime, timedelta
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.base import MIMEBase
from email import encoders
from pathlib import Path
from dotenv import load_dotenv

# Load environment from local .env
env_path = Path(__file__).parent / ".env"
load_dotenv(env_path)

GMAIL_ADDRESS = os.getenv("GMAIL_ADDRESS")
GMAIL_APP_PASSWORD = os.getenv("GMAIL_APP_PASSWORD")


def send_email(to_address: str, subject: str, body: str, html: bool = False) -> dict:
    """
    Send an email via Gmail SMTP.

    Args:
        to_address: Recipient email address
        subject: Email subject line
        body: Email body (plain text or HTML)
        html: If True, send as HTML email

    Returns:
        dict with 'success' bool and 'message' string
    """
    if not GMAIL_ADDRESS or not GMAIL_APP_PASSWORD:
        return {
            "success": False,
            "message": "Email credentials not configured. Check .env file."
        }

    try:
        msg = MIMEMultipart("alternative")
        msg["Subject"] = subject
        msg["From"] = GMAIL_ADDRESS
        msg["To"] = to_address

        if html:
            msg.attach(MIMEText(body, "html"))
        else:
            msg.attach(MIMEText(body, "plain"))

        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(GMAIL_ADDRESS, GMAIL_APP_PASSWORD)
            server.sendmail(GMAIL_ADDRESS, to_address, msg.as_string())

        return {
            "success": True,
            "message": f"Email sent to {to_address}"
        }

    except smtplib.SMTPAuthenticationError:
        return {
            "success": False,
            "message": "Authentication failed. Check Gmail app password."
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Failed to send email: {str(e)}"
        }


def send_health_status(to_address: str = "longmire.jd@gmail.com") -> dict:
    """Send a system health status email."""
    import subprocess
    from datetime import datetime

    # Gather system info
    hostname = subprocess.getoutput("hostname")
    uptime = subprocess.getoutput("uptime -p")
    disk = subprocess.getoutput("df -h / | tail -1 | awk '{print $5 \" used\"}'")
    memory = subprocess.getoutput("free -h | grep Mem | awk '{print $3 \"/\" $2}'")
    load = subprocess.getoutput("cat /proc/loadavg | awk '{print $1, $2, $3}'")
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    subject = f"[ThinxAI] Health Status - {hostname}"
    body = f"""ThinxAI System Health Report
Generated: {timestamp}

Host: {hostname}
Uptime: {uptime}
Disk Usage: {disk}
Memory: {memory}
Load Average: {load}

---
Sent from ThinxAI Web (Claude Code session)
"""

    return send_email(to_address, subject, body)


def send_calendar_invite(
    to_address: str,
    title: str,
    start: datetime,
    end: datetime = None,
    description: str = "",
    location: str = "",
    all_day: bool = False
) -> dict:
    """
    Send a calendar invite (.ics) via email.

    Args:
        to_address: Recipient email address
        title: Event title
        start: Event start datetime
        end: Event end datetime (defaults to 1 hour after start)
        description: Event description (optional)
        location: Event location (optional)
        all_day: If True, create an all-day event

    Returns:
        dict with 'success' bool and 'message' string
    """
    if not GMAIL_ADDRESS or not GMAIL_APP_PASSWORD:
        return {
            "success": False,
            "message": "Email credentials not configured. Check .env file."
        }

    # Default end time: 1 hour after start
    if end is None:
        end = start + timedelta(hours=1)

    # Generate unique event ID
    event_uid = f"{uuid.uuid4()}@thinxai.net"

    # Format datetime for iCalendar
    now = datetime.utcnow()
    dtstamp = now.strftime("%Y%m%dT%H%M%SZ")

    if all_day:
        dtstart = start.strftime("%Y%m%d")
        dtend = end.strftime("%Y%m%d")
        dtstart_line = f"DTSTART;VALUE=DATE:{dtstart}"
        dtend_line = f"DTEND;VALUE=DATE:{dtend}"
    else:
        dtstart = start.strftime("%Y%m%dT%H%M%S")
        dtend = end.strftime("%Y%m%dT%H%M%S")
        dtstart_line = f"DTSTART:{dtstart}"
        dtend_line = f"DTEND:{dtend}"

    # Build iCalendar content
    ics_content = f"""BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//ThinxAI//Calendar//EN
METHOD:REQUEST
BEGIN:VEVENT
UID:{event_uid}
DTSTAMP:{dtstamp}
{dtstart_line}
{dtend_line}
SUMMARY:{title}
DESCRIPTION:{description}
LOCATION:{location}
ORGANIZER;CN=ThinxAI:mailto:{GMAIL_ADDRESS}
ATTENDEE;PARTSTAT=NEEDS-ACTION;RSVP=TRUE:mailto:{to_address}
STATUS:CONFIRMED
SEQUENCE:0
END:VEVENT
END:VCALENDAR"""

    try:
        # Create email message
        msg = MIMEMultipart("mixed")
        msg["Subject"] = f"Calendar Invite: {title}"
        msg["From"] = GMAIL_ADDRESS
        msg["To"] = to_address

        # Add plain text body
        body_text = f"""You've been invited to: {title}

When: {start.strftime("%A, %B %d, %Y at %I:%M %p")}
Where: {location if location else "TBD"}

{description}

---
Open the attached .ics file to add to your calendar.
Sent from ThinxAI
"""
        msg.attach(MIMEText(body_text, "plain"))

        # Attach the .ics file
        ics_attachment = MIMEBase("text", "calendar", method="REQUEST")
        ics_attachment.set_payload(ics_content)
        encoders.encode_base64(ics_attachment)
        ics_attachment.add_header(
            "Content-Disposition",
            "attachment",
            filename="invite.ics"
        )
        ics_attachment.add_header("Content-Class", "urn:content-classes:calendarmessage")
        msg.attach(ics_attachment)

        # Send the email
        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(GMAIL_ADDRESS, GMAIL_APP_PASSWORD)
            server.sendmail(GMAIL_ADDRESS, to_address, msg.as_string())

        return {
            "success": True,
            "message": f"Calendar invite sent to {to_address}: {title}"
        }

    except smtplib.SMTPAuthenticationError:
        return {
            "success": False,
            "message": "Authentication failed. Check Gmail app password."
        }
    except Exception as e:
        return {
            "success": False,
            "message": f"Failed to send calendar invite: {str(e)}"
        }


if __name__ == "__main__":
    # Quick test
    import sys
    if len(sys.argv) > 1:
        to = sys.argv[1]
        result = send_email(to, "Test from ThinxAI Web", "This is a test email.")
        print(result["message"])
    else:
        print("Usage: python email_utils.py <email_address>")
