// JSON schemas the function hands to Claude: the job post shape for structured output and the
// task tools for the agent. The app runs the tools on the device; the server only declares them,
// so a client cannot add a tool Claude would then call.
import type Anthropic from "npm:@anthropic-ai/sdk@1.1.0";

export const JOB_POST_SCHEMA = {
  type: "object",
  properties: {
    title: { type: "string", description: "Job title as written in the post" },
    company: { type: "string" },
    location: { type: "string", description: "City and country, or empty when not stated" },
    remote: { type: "string", enum: ["remote", "hybrid", "onsite", "not_stated"] },
    seniority: { type: "string", enum: ["intern", "junior", "mid", "senior", "lead", "not_stated"] },
    salary: { type: "string", description: "Salary or rate exactly as written, or empty" },
    skills: { type: "array", items: { type: "string" }, description: "Required tools and skills" },
    nice_to_have: { type: "array", items: { type: "string" } },
    summary: { type: "string", description: "Two sentences on what the role is" },
    apply_by: { type: "string", description: "Deadline as written, or empty" },
  },
  required: [
    "title",
    "company",
    "location",
    "remote",
    "seniority",
    "salary",
    "skills",
    "nice_to_have",
    "summary",
    "apply_by",
  ],
  additionalProperties: false,
} as const;

export const AGENT_TOOLS: Anthropic.Beta.BetaTool[] = [
  {
    name: "list_tasks",
    description:
      "Return every task on the user's list with its id, title, due date, priority and whether it is done. Also returns today's date on the phone.",
    strict: true,
    input_schema: { type: "object", properties: {}, required: [], additionalProperties: false },
  },
  {
    name: "add_task",
    description: "Add one task to the user's list.",
    strict: true,
    input_schema: {
      type: "object",
      properties: {
        title: { type: "string", description: "Short task title" },
        due_date: { type: "string", description: "YYYY-MM-DD, or empty when no date was given" },
        priority: { type: "string", enum: ["low", "medium", "high"] },
      },
      required: ["title", "due_date", "priority"],
      additionalProperties: false,
    },
  },
  {
    name: "complete_task",
    description: "Mark one existing task as done, by the id list_tasks returned.",
    strict: true,
    input_schema: {
      type: "object",
      properties: { task_id: { type: "string" } },
      required: ["task_id"],
      additionalProperties: false,
    },
  },
  {
    name: "set_reminder",
    description: "Schedule a local notification on the phone.",
    strict: true,
    input_schema: {
      type: "object",
      properties: {
        text: { type: "string", description: "What the notification says" },
        minutes_from_now: { type: "integer", description: "1 to 10080 (one week)" },
      },
      required: ["text", "minutes_from_now"],
      additionalProperties: false,
    },
  },
];
