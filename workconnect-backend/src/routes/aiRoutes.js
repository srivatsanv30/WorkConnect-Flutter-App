const express = require('express');
const { GoogleGenerativeAI } = require('@google/generative-ai');
const requireAuth = require('../middleware/requireAuth');

const router = express.Router();
const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

// POST /api/ai/breakdown  (turn a rough idea into a structured project plan)
router.post('/breakdown', requireAuth, async (req, res) => {
  try {
    const { idea } = req.body;
    if (!idea || !idea.trim()) {
      return res.status(400).json({ message: 'idea is required' });
    }

    if (!process.env.GEMINI_API_KEY) {
      // Smart mock response if API key is missing
      const lowerIdea = idea.toLowerCase();
      let skills = ["React", "Node.js", "MongoDB"];
      let milestones = [
        "Setup project repository and architecture",
        "Implement user authentication and authorization",
        "Build the core user interface",
        "Integrate backend APIs and database",
        "Perform testing and deploy to production"
      ];
      let desc = "A full-stack application built to deliver a seamless user experience.";

      if (lowerIdea.includes('chat') || lowerIdea.includes('messag')) {
        skills = ["Flutter", "Firebase", "WebSockets"];
        milestones = [
          "Setup Firebase project and authentication",
          "Design real-time chat UI",
          "Implement WebSocket/Firestore real-time listeners",
          "Add push notifications for new messages",
          "Test edge cases and deploy"
        ];
        desc = "A real-time communication platform allowing instant messaging between users.";
      } else if (lowerIdea.includes('shop') || lowerIdea.includes('ecommerce') || lowerIdea.includes('store')) {
        skills = ["Next.js", "Stripe", "PostgreSQL"];
        milestones = [
          "Build product catalog and search UI",
          "Implement shopping cart state management",
          "Integrate Stripe for secure checkout",
          "Build admin dashboard for order management",
          "Deploy and optimize SEO"
        ];
        desc = "An e-commerce storefront with a secure checkout flow and product management.";
      } else if (lowerIdea.includes('task') || lowerIdea.includes('todo') || lowerIdea.includes('manage')) {
        skills = ["Vue.js", "Express", "SQLite"];
        milestones = [
          "Design Kanban board or list UI",
          "Implement CRUD operations for tasks",
          "Add drag-and-drop functionality",
          "Implement user roles and task assignment",
          "Finalize testing and deploy"
        ];
        desc = "A productivity tool to organize tasks, track progress, and manage daily workflows.";
      }

      return res.json({
        title: idea.length > 30 ? idea.substring(0, 30) + "..." : idea,
        description: desc + " (Mocked by AI Smart Fallback)",
        skillsRequired: skills,
        milestones: milestones
      });
    }

    const model = genAI.getGenerativeModel({ model: 'gemini-3.6-flash' });

    const prompt = `You are a project planning assistant. A user wants to build: "${idea}".

Respond with ONLY valid JSON, no markdown formatting, no code fences, matching exactly this shape:
{
  "title": "short project title",
  "description": "2-3 sentence description of the project",
  "skillsRequired": ["skill1", "skill2", "skill3"],
  "milestones": ["milestone 1", "milestone 2", "milestone 3", "milestone 4"]
}

Keep skillsRequired to 3-5 realistic technical skills. Keep milestones to 4-6 concrete build steps in logical order.`;

    const result = await model.generateContent(prompt);
    const text = result.response.text();

    // Strip markdown code fences if Gemini adds them despite instructions
    const cleaned = text.replace(/```json|```/g, '').trim();
    const parsed = JSON.parse(cleaned);

    res.json(parsed);
  } catch (err) {
    console.error('AI breakdown error:', err);
    res.status(500).json({ message: 'AI breakdown failed', error: err.message });
  }
});

module.exports = router;