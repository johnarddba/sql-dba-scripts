select TOP 5 name + 'A' from sys.all_columns

select TOP 5  [name] + N'Ⱥ'
from sys.all_columns



select TOP 5 substring([name],2,len([name])-1) as [name]
from sys.all_columns


select TOP 5 substring([name],1,len([name])-1) as [name]
from sys.all_columns