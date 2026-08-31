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
      // Mock response if API key is missing
      return res.json({
        title: idea.length > 20 ? idea.substring(0, 20) + "..." : idea,
        description: "This is a mock project breakdown. Add a valid GEMINI_API_KEY to your .env file to get real AI-generated project plans.",
        skillsRequired: ["Flutter", "Node.js", "MongoDB"],
        milestones: ["Setup project structure", "Implement authentication", "Build core UI", "Integrate APIs", "Testing and deployment"]
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