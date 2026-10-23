import os
import base64
from playwright.sync_api import sync_playwright
import PyPDF2

# Load clean header image as base64
img_path = r'c:\Users\SRII\WorkConnect\header_clean.png'
with open(img_path, 'rb') as f:
    img_b64 = base64.b64encode(f.read()).decode('utf-8')

pages_data = [
    {
        "module": "Job Marketplace and Smart Project Posting Engine",
        "progress": "The core job marketplace and project posting engine was developed to streamline freelance opportunities and talent recruitment workflows. Key functionalities include dynamic budget range specification, category and required skill tagging, responsive job filtering, and instant proposal submission. Navigation workflows and reusable UI components were implemented to deliver a seamless job discovery experience.",
        "description": "The Job Marketplace module enables clients and project leads to post itemized project listings with specified skill tags, expected deadlines, and compensation tiers. Users can browse, filter, and search open positions in real time, view comprehensive project briefs, and submit detailed proposals. An integrated skill chip selector and dynamic category search optimize listing efficiency and eliminate redundant browsing."
    },
    {
        "module": "AI-Powered Skill Matching and Task Breakdown Engine",
        "progress": "The generative artificial intelligence module was engineered to transform unstructured project concepts into actionable execution roadmaps. Features include Google Generative AI (Gemini) integration, automated project description generation, required skill extraction, structured milestone decomposition, and an intelligent offline fallback mechanism directly embedded into the project planning workflow.",
        "description": "The AI Task Breakdown module provides automated project scoping by leveraging large language models to analyze rough user ideas. It decomposes complex technical requirements into structured milestone phases, recommends critical programming languages and frameworks, and estimates technical scope. This capability empowers project managers and freelancers with structured project planning and precise implementation roadmaps."
    },
    {
        "module": "Real-Time Team Collaboration and Messaging Workspace",
        "progress": "The team collaboration workspace was implemented with live conversational messaging and contextual room routing. The module supports low-latency bidirectional socket communication, instant project-specific chat channels, read status indicators, and file attachment sharing integrated into the primary application state with real-time UI synchronization.",
        "description": "The Real-Time Collaboration module provides project teams with an agile communication hub for ongoing development tasks. It organizes team communications into distinct project channels, enabling developers and stakeholders to exchange updates, share technical assets, and coordinate sprints without third-party communication tools. Optimistic UI updates and resilient socket reconnection ensure uninterrupted team collaboration."
    },
    {
        "module": "Project Milestone Tracking and Workflow Monitoring",
        "progress": "The progress tracking module was developed to provide granular visibility into multi-phase project execution and deliverable verification. Key functionalities include milestone creation, percentage completion algorithms, interactive task status toggling, deadline scheduling, and deliverable review workflows organized into responsive, reactive interface components.",
        "description": "The Progress Tracking module provides project stakeholders with real-time oversight of project milestones from inception to completion. It calculates composite completion metrics based on closed deliverables, alerts collaborators to upcoming deadlines, and enables clients to review submitted artifacts before approving milestone transitions. This structured transparency mitigates project delivery bottlenecks and guarantees accountability."
    },
    {
        "module": "User Portfolio, Reputation and Rating System",
        "progress": "The user profile and reputation management module was implemented with customizable developer showcases and transactional peer reviews. Developer portfolio catalogs, verified skill endorsements, interactive star ratings, feedback history logs, and profile customization options were organized within reusable interface components and responsive navigation structures.",
        "description": "The Reputation and Rating module provides a trusted verification layer for freelancers and hiring clients. It maintains transparent credibility metrics through multi-criteria review rubrics, calculated performance ratings, and documented project histories. Freelancers can showcase technical skillsets and past successes, enabling prospective clients to evaluate freelancer credibility and select optimal collaborators with high confidence."
    },
    {
        "module": "REST API Backend, MongoDB and WebSocket Architecture",
        "progress": "The Node.js and Express backend service was architected with structured RESTful endpoints and Mongoose schemas for cloud persistence. Client-side integration layers with resilient JWT authentication, WebSocket connection pooling for live updates, and MongoDB Atlas data models were established to safeguard data consistency, complemented by secure middleware authorization.",
        "description": "The Backend Architecture module delivers a high-throughput communication layer connecting Flutter mobile clients to cloud persistence services. It handles concurrent CRUD operations for project jobs, user credentials, real-time message streams, and milestone statuses with built-in schema validation and error-handling middleware. Stateless token security and efficient database indexing ensure scalable performance during peak concurrent collaboration."
    }
]

abstract_text = (
    "Efficient client-freelancer collaboration, agile project scoping, and structured milestone tracking remain "
    "significant operational challenges in modern freelance ecosystems and distributed student engineering teams, "
    "where fragmented communication tools often result in misaligned requirements, untracked project deliverables, "
    "and delayed milestone completion. The proposed WorkConnect platform is a robust cross-platform mobile "
    "application that unifies freelance job marketplace discovery, AI-assisted task breakdown, real-time team messaging, "
    "and dynamic project progress monitoring into a centralized, streamlined interface. Built using Flutter with a "
    "Node.js, Express, and MongoDB backend, WorkConnect incorporates Google Generative AI (Gemini) for smart task "
    "breakdown and skill matching, Socket.io for low-latency collaboration, interactive milestone progress tracking, "
    "and structured user reputation ratings to empower professionals and student developers with real-time project "
    "management and seamless team synchronization."
)

html_content = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  @page {{
    size: letter;
    margin: 0;
  }}
  * {{
    box-sizing: border-box;
    -webkit-print-color-adjust: exact;
  }}
  html, body {{
    margin: 0;
    padding: 0;
    background: #fff;
    font-family: "Times New Roman", Times, Georgia, serif;
    color: #000;
  }}
  .page {{
    width: 8.5in;
    height: 11in;
    max-height: 11in;
    box-sizing: border-box;
    padding: 22.5pt 48pt;
    page-break-after: always;
    page-break-inside: avoid;
    overflow: hidden;
    position: relative;
    background: #fff;
  }}
  .outer-border {{
    width: 100%;
    height: 100%;
    border: 0.75pt solid #000;
    box-sizing: border-box;
    padding: 10pt 28.5pt 16pt 28.5pt;
    display: flex;
    flex-direction: column;
  }}
  .header-img-container {{
    text-align: center;
    margin: 0 0 16pt 0;
  }}
  .header-img {{
    width: 466.8pt;
    height: auto;
    max-height: 53pt;
    display: block;
    margin: 0 auto;
  }}
  .project-title {{
    font-size: 13.5pt;
    font-weight: bold;
    text-align: center;
    text-transform: uppercase;
    margin: 0 0 16pt 0;
    letter-spacing: 0.2pt;
    white-space: nowrap;
    line-height: 1.2;
  }}
  .meta-info {{
    font-size: 12.5pt;
    margin: 0 0 18pt 0;
    line-height: 1.45;
  }}
  .meta-line {{
    margin-bottom: 2pt;
    font-weight: bold;
  }}
  .module-title {{
    font-size: 15.5pt;
    font-weight: bold;
    text-align: center;
    margin: 0 0 18pt 0;
    line-height: 1.25;
  }}
  .section-block {{
    margin-bottom: 14pt;
  }}
  .section-heading {{
    font-size: 12.2pt;
    font-weight: bold;
    text-transform: uppercase;
    margin: 0 0 3pt 0;
    letter-spacing: 0.2pt;
  }}
  .section-body {{
    font-size: 12pt;
    font-weight: normal;
    text-align: justify;
    text-indent: 28pt;
    line-height: 1.35;
    margin: 0;
  }}
</style>
</head>
<body>
"""

for page in pages_data:
    html_content += f"""
<div class="page">
  <div class="outer-border">
    <div class="header-img-container">
      <img class="header-img" src="data:image/png;base64,{img_b64}" alt="Sri Shakthi Logo" />
    </div>
    
    <div class="project-title">WORKCONNECT: SMART FREELANCING & MANAGEMENT SYSTEM</div>
    
    <div class="meta-info">
      <div class="meta-line">Name: Srivatsan V</div>
      <div class="meta-line">Roll Number: 24CS215</div>
    </div>
    
    <div class="module-title">{page['module']}</div>
    
    <div class="section-block">
      <div class="section-heading">ABSTRACT</div>
      <p class="section-body">{abstract_text}</p>
    </div>
    
    <div class="section-block">
      <div class="section-heading">PROGRESS</div>
      <p class="section-body">{page['progress']}</p>
    </div>
    
    <div class="section-block">
      <div class="section-heading">DESCRIPTION</div>
      <p class="section-body">{page['description']}</p>
    </div>
  </div>
</div>
"""

html_content += """
</body>
</html>
"""

html_path = r'c:\Users\SRII\WorkConnect\report_preview.html'
with open(html_path, 'w', encoding='utf-8') as f:
    f.write(html_content)

print("Saved report_preview.html")

pdf_path = r'c:\Users\SRII\WorkConnect\WorkConnect_Project_Report_Srivatsan_V.pdf'
with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    page.goto(f'file:///{html_path}')
    page.pdf(
        path=pdf_path,
        format='Letter',
        print_background=True,
        margin={'top': '0', 'right': '0', 'bottom': '0', 'left': '0'}
    )
    browser.close()

print(f"Generated PDF at {pdf_path}")

# Verify generated PDF
reader = PyPDF2.PdfReader(pdf_path)
print("Total pages in generated PDF:", len(reader.pages))
for i in range(len(reader.pages)):
    print(f"Page {i+1} character count:", len(reader.pages[i].extract_text()))
