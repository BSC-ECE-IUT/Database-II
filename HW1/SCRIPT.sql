--create Trn_Src_Des table
CREATE TABLE [dbo].[Trn_Src_Des](
	[VoucherId] [varchar](21) NULL,
	[TrnDate] [date] NULL,
	[TrnTime] [varchar](6) NULL,
	[Amount] [bigint] NULL,
	[SourceDep] [int] NULL,
	[DesDep] [int] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
--insert question data to Trn_Src_Des table
INSERT [dbo].[Trn_Src_Des] ([VoucherId], [TrnDate], [TrnTime], [Amount], [SourceDep], [DesDep]) VALUES (N'10', CAST(0x233F0B00 AS Date), N'101000', 1000, 45, 23)
INSERT [dbo].[Trn_Src_Des] ([VoucherId], [TrnDate], [TrnTime], [Amount], [SourceDep], [DesDep]) VALUES (N'11', CAST(0x233F0B00 AS Date), N'101000', 1000, 45, 23)
INSERT [dbo].[Trn_Src_Des] ([VoucherId], [TrnDate], [TrnTime], [Amount], [SourceDep], [DesDep]) VALUES (N'12', CAST(0x233F0B00 AS Date), N'091000', 200, 345, NULL)
INSERT [dbo].[Trn_Src_Des] ([VoucherId], [TrnDate], [TrnTime], [Amount], [SourceDep], [DesDep]) VALUES (N'14', CAST(0x243F0B00 AS Date), N'080023', 300, NULL, 45)
INSERT [dbo].[Trn_Src_Des] ([VoucherId], [TrnDate], [TrnTime], [Amount], [SourceDep], [DesDep]) VALUES (N'15', CAST(0x273F0B00 AS Date), N'151201', 700, 438, 259)
INSERT [dbo].[Trn_Src_Des] ([VoucherId], [TrnDate], [TrnTime], [Amount], [SourceDep], [DesDep]) VALUES (N'16', CAST(0x273F0B00 AS Date), N'151201', 700, 438, 259)
INSERT [dbo].[Trn_Src_Des] ([VoucherId], [TrnDate], [TrnTime], [Amount], [SourceDep], [DesDep]) VALUES (N'25', CAST(0x503F0B00 AS Date), N'132022', 1700, 876, 2000)

--write procedure
CREATE PROCEDURE bank as
begin
-- it might have temp tables in db with this names, so we remove them
  IF OBJECT_ID('[dbo].[Temp1]') IS NOT NULL 
    DROP TABLE [dbo].[Temp1]

  IF OBJECT_ID('[dbo].[Temp2]') IS NOT NULL
    DROP TABLE [dbo].[temp2]

-- craete temp table to do our procedure	
	BEGIN TRAN
	CREATE TABLE [dbo].[Temp1](
		[VoucherId] [varchar](21) NULL,
		[TrnDate] [date] NULL,
		[TrnTime] [varchar](6) NULL,
		[Amount] [bigint] NULL,
		[SourceDep] [int] NULL,
		[DesDep] [int] NULL
	) ON [PRIMARY]

	
	CREATE TABLE [dbo].[Temp2](
		[VoucherId] [varchar](21) NULL,
		[TrnDate] [date] NULL,
		[TrnTime] [varchar](6) NULL,
		[Amount] [bigint] NULL,
		[SourceDep] [int] NULL,
		[DesDep] [int] NULL
	) ON [PRIMARY]

	declare @currdate date;

	-- we run our procedure for this period, [2019-03-01,2019-01-01]. You can change it
	set @currdate = CAST('2019-03-01' as date);
	while @currdate >= CAST('2019-01-01' as date) 
	begin
	-- For a specific day, we separate our data, this procedure is going to run daily  
		insert into [dbo].[Temp1] (VoucherId, TrnDate, TrnTime, Amount, SourceDep, DesDep)
		select *
		from [dbo].[Trn_Src_Des] where [dbo].[Trn_Src_Des].TrnDate = @currdate;
		
	-- Main part of code 
	-- by using left join we find 2 records with the same time and destintion and source in a specific day
	-- we use case when to add pip in VoucherId 
		insert into [dbo].[Temp2] (VoucherId ,TrnDate, TrnTime, Amount, SourceDep, DesDep)
			select (case 
					when f.VoucherId is not null then concat(t.VoucherId, concat('|', f.VoucherId))
					when f.VoucherId is null then t.VoucherId
				    end) as VoucherId, t.TrnDate as TrnDate, t.TrnTime as TrnTime , t.Amount as Amount, t.SourceDep as SourceDep, t.DesDep as DesDep
			from [dbo].[Temp1] as t left outer join [dbo].[Temp1] as f on t.VoucherId <> f.VoucherId and t.TrnTime = f.TrnTime and t.SourceDep = f.SourceDep and t.DesDep = f.DesDep 
			where t.VoucherId < isnull(f.VoucherId,9999)

		--update is more slower than in/del
		-- we delete useless data, because we have new one
		delete from [dbo].[Trn_Src_Des] where TrnDate = @currdate;
		-- insert changed data, they are changed by the Main part
		insert into [dbo].[Trn_Src_Des] (VoucherId, TrnDate, TrnTime, Amount, SourceDep, DesDep)
			select *
			from [dbo].[Temp2]

		delete from [dbo].[Temp1];
		delete from [dbo].[Temp2];

		--set new day in the interval, to do while loop again
		set @currdate = DATEADD(day, -1, @currdate);
	end
	-- Now we don't need Temp files, for next time of using procedure we create them again
	drop table [dbo].[Temp1];
	drop table [dbo].[Temp2];

end
-- Running procedure
EXEC bank

--show output
Select * From [dbo].[Trn_Src_Des]
Order by [TrnDate]