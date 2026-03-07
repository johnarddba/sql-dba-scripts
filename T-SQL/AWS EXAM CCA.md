AWS Cloud Solutions Architect Associate (SAA-C03) — 45 days Plan

--
I did the following course of Stephane Maarek on Udemy. This course is extremely good. I recommend you go with this course.

Ultimate AWS Certified Solutions Architect Associate 2026

Preparation Plan:
I read multiple articles and watched videos on “How to Prepare for the AWS Certified Solutions Architect Exam in 7 Days, 10 Days, or 2 Weeks.” You can follow those plans if you want, but for me, completing everything in a week is very challenging since I work full-time and don’t get enough time to study. To make it manageable, I created a 45-day plan that fits around my full-time job, a German course, and daily household responsibilities.

From Day 1 to Day 29: The course I followed has 33 sections, covering everything from the basics of “What is Cloud Computing?” to advanced topics. The first two and last two sections — Introduction, Code & Slides Download, etc. — are brief and don’t take much time. The remaining 29 sections cover the main topics relevant to the exam.

I followed a pace of one section per day, with each section ranging from 15 minutes to 2 hours. I typically tackled the shorter sections on weekdays when I was busy and the longer ones on weekends, planning for roughly 2 hours of study per day. If you can’t finish a section in one day, it’s okay to continue the next day along with a shorter section — you won’t exceed 2 hours per day. Overall, it took 29 days to complete the course.

Tip: Make a cheat sheet for each service, noting the most important points, keywords, trade-offs, pros and cons, and best-case scenarios for using the service. By the end of the course, without a cheat sheet, it’s easy to mix up concepts and forget important details.

From Day 30 to Day 35: In addition to the main course, I took the Practice Exams | AWS Certified Solutions Architect Associate course by the same instructor on Udemy. The practice exams help you tackle critical questions, case studies, and give a clear idea of how questions are structured in the real exam. I solved one practice exam per day, which took 6 days to complete all the questions.

Tip: Don’t worry or panic if you get questions wrong in the practice exams. The goal at this stage is to understand the question properly and determine the best possible answer according to the requirements. If your answer is wrong, carefully read the explanation, understand why, and update your cheat sheet. This approach helps you reinforce your understanding of AWS services and identify areas where you feel less confident.

From Day 36 to Day 42: During these 7 days, I reviewed the course material for the topics I found challenging in the practice exams and updated my cheat sheet accordingly. This helped reinforce weak areas and clarify any doubts.

From Day 43 to Day 45: I solved the same practice exams again. This time, I felt much more confident because I had reviewed my weak areas and understood the scenarios better. On the final day of practice, I also scheduled my exam for the next day.

Day 46: I attempted the exam. Stay calm during the test — focus on each question carefully, read thoroughly, and answer with confidence. I will share exam tips in the next section.

Exam Strategy:
Step 1: Read the LAST sentence first — Before reading the whole scenario, read the question line:

“MOST cost-effective?”

“MINIMIZE operational overhead?”

“HIGH availability?”

“Disaster recovery?”

“Secure without internet exposure?”

That final requirement determines the correct service. Then read the scenario. This prevents overthinking.

Step 2: Instantly Eliminate 2 Answers (Fast Kill Technique) — In most SAA questions:

1 answer = clearly wrong

1 answer = technically possible but violates requirement

2 answers = plausible

1 answer = best

Your goal: remove the obvious 2 immediately.

Step 3: Identify the Core Domain Being Tested — Most questions secretly test one of these:

RDS Multi-AZ vs Read Replica

NAT vs IGW

CloudFront vs Global Accelerator

Route 53 routing types

Gateway Endpoint vs Interface Endpoint

Snowball vs Direct Connect

EFS vs EBS

IAM Role vs IAM User

If you detect the domain, the answer becomes obvious.

Step 4: Use the “Overengineering Filter” — If an answer introduces:

Extra region

Extra service not mentioned

Unnecessary complexity

Custom management

It is usually wrong. The exam prefers:
Simple + Managed + Meets requirement.

Step 5: Time Management Strategy — You have:

65 questions

130 minutes

That’s 2 minutes per question. Recommended Approach:

First pass: answer everything you are 70% confident in

Flag hard ones

Do not spend 5+ minutes on one question

Most people fail because they get stuck early.

Step 6: “Architect Mindset” Rule — Always ask:

What would AWS Solutions Architect recommend in Well-Architected Framework? Priorities order:

Security

Reliability

Performance

Cost optimization

Operational excellence

Security and reliability usually beat cost unless cost is explicitly stated.

Step 7: When Stuck Between Two Answers — Ask:

Which one is more managed?

Which one removes responsibility from me?

Which one better matches the exact requirement wording?

The more AWS-managed option usually wins.

Step 8: Mental Strategy — If you see 3 difficult questions in a row:

That’s normal. Don’t panic. The exam is adaptive in difficulty perception. Move forward. You only need ~72% to pass. Not 100%.