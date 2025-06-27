/*

--Once you identify which query is taking the maximum CPU you may consider tuning that query based on what you find offending in that query. You should focus on the following aspect, along with the execution plan operators when you are looking at query tuning exercise.

--Wait statistics of the session
--Scheduler workload
--IO stalling queries
--Memory grant for session
--Blocking scenarios
--Optional Max degree of parallelism for query
--Execution plan operators consuming a lot of CPU
--Ad-hoc workload of the server
--Parameter sniffing configuration
--etc.




*/