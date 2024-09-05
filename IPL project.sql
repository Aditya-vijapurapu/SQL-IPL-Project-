USE IPL;

##1.	Show the percentage of wins of each bidder in the order of highest to lowest percentage.
select*from ipl_bidding_details;
select*from ipl_bidder_points;
select*from ipl_bidder_details;

select NO_OF_BIDS from ipl_bidder_points ;

with bid_win as(
select BIDDER_ID,count(bid_status)as wins 
from ipl_bidder_details
where bid_status='Won'
group by bidder_id)

select*from ipl_bidding_details where bid_status='Won';



#2.	Display the number of matches conducted at each stadium with the stadium name and city.
select*from ipl_stadium;
select*from ipl_match_schedule;

select count(im.match_id)as matches_played,s.stadium_name,s.city
from ipl_match_schedule im join ipl_stadium s
on im.stadium_id=s.stadium_id
group by stadium_name,city
order by count(im.match_id) desc;

#3.	In a given stadium, what is the percentage of wins by a team that has won the toss?
select*from ipl_match_schedule;
select*from ipl_stadium;

select ist.STADIUM_NAME,(sum((case
 when TOSS_WINNER=MATCH_WINNER then 1 else 0
 end))/count(*))*100 as 'percentage of wins'
from ipl_stadium ist join ipl_match_schedule ms
  on ist.stadium_id = ms.stadium_id
join ipl_match im 
	on ms.match_id = im.match_id
group by ist.STADIUM_NAME
order by 1;    
#4.	Show the total bids along with the bid team and team name.
select *from ipl_bidding_details;

select bid_team,team_name,count(bidder_id)as no_of_bids
from ipl_bidding_details bd join ipl_team t
 on t.team_id=bd.bid_team
group by bid_team
order by bid_team;

#5.	Show the team ID who won the match as per the win details.

 WITH temp AS 
        (SELECT Win_Details FROM ipl_match)
        SELECT Team_id, Team_name FROM ipl_team,temp
        WHERE Win_Details LIKE concat('%',remarks,'%');
        
select*from ipl_team;
select*from ipl_match;

#6.	Display the total matches played, total matches won and total matches lost by the team along with its team name.


 
 SELECT it.Team_ID, it.Team_Name, sum(matches_played) as Total_Match_Played, sum(matches_won) Total_Match_Won, sum(matches_lost) Total_Match_Lost
        FROM ipl_team_standings s 
        JOIN ipl_team it 
        ON s.Team_ID = it.Team_ID
        GROUP BY Team_id,Team_Name;



#7.	Display the bowlers for the Mumbai Indians team.

select player_id,player_name from ipl_player
 where player_id in(select player_id from ipl_team_players
 where team_id in(
select  team_id from ipl_team where team_name='mumbai indians')and player_role='bowler' );
        
#8.	How many all-rounders are there in each team, Display the teams with more than 4 
#all-rounders in descending order.

select team_id,team_name,count(*)as no_of_allrounders
from ipl_team_players p
join ipl_team t 
using(team_id)
where player_role='All-Rounder'
group by team_id
having count(*)>4
order by no_of_allrounders desc;

 #9.	 Write a query to get the total bidders points for each bidding status of those bidders who bid on CSK when they won the match in
 #M. Chinnaswamy Stadium bidding year-wise.
#Note the total bidders’ points in descending order and the year is the bidding year.
# Display columns: bidding status, bid date as year, total bidder’s points
SELECT * FROM ipl_bidding_details;
        
        SELECT Bid_status, YEAR(Bid_date) Bidding_Year, sum(total_points) Total_Bidder_Points
        FROM ipl_bidding_details bd
        JOIN ipl_bidder_points bp USING (bidder_id)
        JOIN ipl_match_schedule ms USING (schedule_id)
        JOIN ipl_match m USING (Match_id)
        WHERE ms.stadium_id = (SELECT Stadium_id from ipl_stadium as s WHERE m.win_details like '%CSK%' AND s.Stadium_name = 'M. Chinnaswamy Stadium')
        GROUP BY Bid_status, Bidding_Year
        ORDER BY Total_Bidder_Points DESC;

-- 10.	Extract the Bowlers and All-Rounders that are in the 5 highest number of wickets.
-- Note 
-- 1. Use the performance_dtls column from ipl_player to get the total number of wickets
--  2. Do not use the limit method because it might not give appropriate results when players have the same number of wickets
-- 3.	Do not use joins in any cases.
-- 4.	Display the following columns teamn_name, player_name, and player_role.

		SELECT team_name, player_name, player_role
        FROM ipl_player ip,
			( SELECT t.team_id, t.team_name, player_id,player_role 
            FROM ipl_team t, ipl_team_players tp
            WHERE t.team_id = tp.team_id IN ( SELECT Player_id FROM ipl_team_players
											  WHERE player_id IN (SELECT player_id FROM 
                                              (SELECT player_id, dense_rank() over(order by substring(performance_dtls,instr(performance_dtls,"Wkt") +4,
                                              (instr(performance_dtls,"Dot") -5)-instr(Performance_dtls,"Wkt"))desc) AS ranking
				FROM ipl_player 
				WHERE player_id IN (SELECT Player_id FROm ipl_team_players WHERE player_role = "Bowler" Or player_role = "All-Rounder"))a
			WHERE ranking <=5))) temp
            WHERE ip.player_id = temp.player_id;

-- 11.	show the percentage of toss wins of each bidder and display the results in descending order based on the percentage

	SELECT bd.BIDDER_ID, bd.BIDDER_NAME,
    (SUM(CASE WHEN (m.TEAM_ID1 = bg.BID_TEAM AND m.TOSS_WINNER = 1) OR
                  (m.TEAM_ID2 = bg.BID_TEAM AND m.TOSS_WINNER = 2)
             THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS Toss_Win_Percentage
	FROM ipl_match m
		INNER JOIN ipl_match_schedule schd 
		ON m.MATCH_ID = schd.MATCH_ID
		INNER JOIN ipl_bidding_details bg 
		ON schd.SCHEDULE_ID = bg.SCHEDULE_ID
		INNER JOIN ipl_bidder_details bd 
		ON bg.BIDDER_ID = bd.BIDDER_ID
		INNER JOIN ipl_bidder_points pts 
		ON bd.BIDDER_ID = pts.BIDDER_ID
	GROUP BY bd.BIDDER_ID, bd.BIDDER_NAME
	ORDER BY Toss_Win_Percentage DESC;
    
-- 12.	find the IPL season which has a duration and max duration.
-- Output columns should be like the below:
--  Tournment_ID, Tourment_name, Duration column, Duration

WITH ipl AS (																		
    SELECT Tournmt_ID, Tournmt_name, DATEDIFF(TO_DATE, FROM_DATE) AS Duration
    FROM ipl_tournament),max_durations AS (								
    SELECT MAX(Duration) AS Max_Duration
    FROM
        ipl), min_durations AS (
    SELECT MIN(Duration) AS Min_Duration
    FROM ipl
)
SELECT Tournmt_ID, Tournmt_name, Duration,
    CASE
        WHEN Duration = (SELECT Max_Duration FROM max_durations) THEN 'Max_duration'
        WHEN Duration = (SELECT Min_Duration FROM min_durations) THEN 'Min_duration'
    END AS Duration_Column
FROM ipl;

-- 13.	Write a query to display to calculate the total points month-wise for the 2017 bid year. sort the results based on total points in descending order and month-wise in ascending order.
-- Note: Display the following columns:
-- 1.	Bidder ID, 2. Bidder Name, 3. Bid date as Year, 4. Bid date as Month, 5. Total points
-- Only use joins for the above query queries.

	SELECT bd.bidder_id, bd.bidder_name, YEAR(bg.bid_date) Bid_year, month(bg.bid_date) bid_month,pts.Total_points
    FROM ipl_bidder_details bd
    INNER JOIN ipl_bidder_points pts
    ON bd.bidder_id = pts.bidder_id
    INNER JOIN ipl_bidding_details bg 
    ON pts.bidder_id = bg.bidder_id
    WHERE year(bg.bid_date) = 2017
    ORDER BY total_points DESC, bid_month ASC;

-- 14.	Write a query for the above question using sub-queries by having the same constraints as the above question.

		SELECT bd.bidder_id, bd.bidder_name, year(bg.bid_date) bid_year, monthname(bg.bid_date) as bid_month,pts.total_points
        FROM ipl_bidding_details bg
        INNER JOIN ipl_bidder_details bd 
        ON bg.bidder_id = bd.bidder_id
        INNER JOIN ipl_bidder_points pts 
        ON bg.bidder_id = pts.bidder_id
        WHERE year(bg.bid_date) = 2017
        GROUP BY bd.bidder_id,bg.bid_date,bd.bidder_name,pts.total_points
        ORDER BY Total_points DESC;
        
-- 15.	Write a query to get the top 3 and bottom 3 bidders based on the total bidding points for the 2018 bidding year.
-- Output columns should be:
-- like
-- Bidder Id, Ranks (optional), Total points, Highest_3_Bidders --> columns contains name of bidder, Lowest_3_Bidders  --> columns contains name of bidder;

		CREATE OR REPLACE VIEW highest AS (
        SELECT pts.bidder_id,pts.total_points,bd.bidder_name
        FROM ipl_bidder_points pts
        INNER JOIN ipl_bidder_details bd
        ON pts.bidder_id = bd.bidder_id
        WHERE dense_rank() over (order by pts.total_points desc)<4);
        
        CREATE OR REPLACE VIEW lowest AS
        SELECT pts.bidder_id,pts.total_points,bd.bidder_name
        FROM ipl_bidder_points pts
        INNER JOIN ipl_bidder_details bd
        ON pts.bidder_id = bd.bidder_id
        WHERE dense_rank() over (order by pts.total_points) <4;
        
        SELECT * FROM highest
        UNION ALL
        SELECT * FROm lowest;
        