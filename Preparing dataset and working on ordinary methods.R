### Fifa Dataset
# https://www.kaggle.com/general/307245

### Libraries that will be used (and that you should install them)
library(dplyr)

######## PART 1
### Preparing dataset to analyse

# Transforming Fifa's csv to dataframe
fifa = read.csv('players_22.csv', encoding = 'UTF-8')

# Updating the players's ages to 2023
fifa$dob_y = substr(fifa$dob, 1, 4)
fifa = fifa %>% mutate(age_2023 = 2023 - as.numeric(dob_y))

# Separating the columns that I want to use, filtering for only Brazilian ST players below 23 years old
cols = c(1, 3, 5:9, 112, 12:13, 15:18, 24, 26, 31, 28:30, 38:43, 32:33, 36:37)
fifa_br = fifa %>% filter(nationality_name == 'Brazil',
                          age_2023 <= 23,
                          grepl('ST', player_positions)) %>%
                    select(all_of(cols))

# As ordinary methods demands e preview ranking for each column, I reorder them all
fifa_br = fifa_br %>% arrange(age_2023, desc(height_cm), weight_kg, desc(weak_foot),
                              league_level, desc(skill_moves), desc(pace), desc(shooting),
                              desc(passing), desc(dribbling), desc(defending), desc(physic))

# Creating a matrix with only the columns that I should use in the analysis
cols = c(1, 9, 19:26)
matrix_df = fifa_br %>% select(all_of(cols))
rownames(matrix_df) = matrix_df$sofifa_id
sofifa_id = matrix_df$sofifa_id

matrix_players = as.matrix(matrix_df[, c(2:10)])

######## PART 2
### Borda Count Method

# Calculating the player's scores by column
borda = apply(matrix_players, 2, function(column) rank(-column))

# Adding up the score of each row
borda = apply(borda, 1, sum)

# Assigning the Borda's score to each player
borda_df = data.frame(cbind(sofifa_id, borda))
fifa_om = left_join(fifa_br, borda_df, by = 'sofifa_id')

### Condorcet Count Method


