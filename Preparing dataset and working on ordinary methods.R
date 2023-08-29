### Fifa Dataset
# https://www.kaggle.com/general/307245

### Libraries that will be used (and that you should install them)
library(dplyr)
library(igraph)

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

# You can see the players ranking by Borda's scores just ordering the borda's column


### Condorcet Count Method

# Creating a Win matrix and initializing with zeros
wins = matrix(0, ncol = nrow(matrix_players), nrow = nrow(matrix_players))
rownames(wins) = matrix_df$sofifa_id
colnames(wins) = matrix_df$sofifa_id

# Creating a loop to count scores
for ( player in 1:(ncol(matrix_players)-1) ) {
  for ( next_player in (player+1):ncol(matrix_players) ) {
    # Wins
    win_player = 0
    win_next_player = 0
    
    for ( duel in 1:nrow(matrix_players) ) {
      if ( matrix_players[duel, player] > matrix_players[ duel, next_player] ) {
        win_player = win_player+1
      } else if ( matrix_players[duel, player] < matrix_players[duel, next_player] ) {
        win_next_player = win_next_player+1
      } else {
        win_player = win_player+0
        win_next_player = win_next_player+0
      }
    } 
    
    # Wins attribuitions
    if ( win_player > win_next_player ) {
      wins[player, next_player] = 1
      wins[next_player, player] = -1
    } else if ( win_player < win_next_player ) {
      wins[player, next_player] = -1
      wins[next_player, player] = 1
    }
  }
}

# We usually see Condorcet's results in a graph, so we have to build one 
grafo = graph.adjacency(wins, mode = 'directed')

# Finding and removing the isolated players
players_off = which(degree(grafo, mode = 'total') == 0)
new_grafo = delete_vertices(grafo, players_off)

# Finding the winner
winner = which.max(degree(new_grafo, mode = 'out'))

# Changing the winner's color
V(new_grafo)$color = 'grey'
V(new_grafo)$color[winner] = 'green'

# Graph visualization to see the winner
plot(new_grafo)


### Copeland Count Method

# Adding player's scores from Condorcet's wins
copeland = apply(wins, 1, sum)
copeland = copeland[order(copeland, decreasing = T)]


# Assigning the Copeland's score to each player
copeland_df = data.frame(cbind(sofifa_id, copeland))
fifa_om = left_join(fifa_om, copeland_df, by = 'sofifa_id')

