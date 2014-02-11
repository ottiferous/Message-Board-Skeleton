-- Add a users table.
-- Should track fname and lname attributes.
--
-- Add a questions table.
-- Track the title, the body, and the associated author (a foreign key).
--
-- Add a question_followers table.
-- This should support the many-to-many relationship between questions and users (a user can have many questions she is following, and a question can have many followers).
-- This is an example of a join table; the rows in question_followers are used to join users to questions and vice versa.
--

-- Add a replies table.
-- Each reply should contain a reference to the subject question.
-- Each reply should have a reference to its parent reply.
-- Each reply should have a reference to the user who wrote it.
-- Don't forget to keep track of the body of a reply.
-- "Top level" replies don't have any parent, but all replies have a subject question.

-- Add a question_likes table.
-- Users can like a question.
-- Have references to the user and the question in this table

CREATE TABLE users (
	id INTEGER PRIMARY KEY,
	fname VARCHAR(20) NOT NULL,
	lname VARCHAR(20) NOT NULL
);

CREATE TABLE questions (
	id INTEGER PRIMARY KEY,
	title VARCHAR(50) NOT NULL,
	body VARCHAR(200) NOT NULL,
	user_id INTEGER,
	FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_followers (
	id INTEGER PRIMARY KEY,
	user_id INTEGER NOT NULL,
	question_id INTEGER NOT NULL,

	FOREIGN KEY (user_id) REFERENCES users(id),
	FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
	id INTEGER PRIMARY KEY,
	question_id INTEGER NOT NULL,
	parent_id INTEGER,
	user_id INTEGER NOT NULL,
	body VARCHAR(200) NOT NULL,

	FOREIGN KEY (question_id) REFERENCES questions(id),
	FOREIGN KEY (parent_id) REFERENCES replies(id),
	FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
	id INTEGER PRIMARY KEY,					-- THROW AWAY?
	user_id INTEGER NOT NULL,
	question_id INTEGER NOT NULL,

	FOREIGN KEY (user_id) REFERENCES users(id),
	FOREIGN KEY (question_id) REFERENCES questions(id)
);


-- Users
INSERT INTO
	users(fname, lname)
VALUES
	('Sam', 'Eng'),
	('Andrew', 'Marrone');

-- Questions
INSERT INTO
	questions(title, body, user_id)
VALUES
	('What is love?', "Baby don't hurt me", 1),
	('Why do cats moo?', 'Seriously, I want to know.', 2),
	("What does 'Question_followers' mean?", "I am very confused by this. Cats?", 2 );

-- Replies
INSERT INTO
  replies(question_id, parent_id, user_id, body)
VALUES
	(1, NULL, 1, "I'm so awesome!!!"),
	(1, NULL, 2, "I agree."),
	(1, 2, 1, "THANKS :)");

-- Likes
INSERT INTO
	question_likes(user_id, question_id)
VALUES
	(1, 1), -- Sam likes her own post
	(2, 1),	-- Andrew likes Sam's post
	(1, 2);	-- Sam likes Andrew's post

--Question Followers
INSERT INTO
	question_followers(user_id, question_id)
VALUES
	(1, 1),
	(1, 2),
	(1, 3),
	(2, 2),
	(2, 3);
