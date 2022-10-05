;36.8 village color
extensions [ time rnd ]

breed [ bears bear ]
breed [ hunters hunter ]

bears-own [
  kcal
  age
  sex
  agitation
  traveled-today
  pregnant
  pregnancy-duration
  time-since-cub-birth
]

hunters-own [
  hunt-day ; day in which the hunter will hunt
  hunted ; marks if the hunting permit has been used
  hunts-aggressive ; emergency hunting refers to hunting aggressive bears
]

globals [
  first-day
  date
  gained-kcal ;gained kcal per food
  lost-kcal ; lost kcal due to metabolism
  traveled-distance ;distance/quarter
  travel-kcal-lost ;kcal lost per km
  hunger-threshold ; if the bear has less, it might enter a human settlement
  season
  sexual-maturity-age
  liberally-hunted-bears
  hunted-aggressive-bears
  calm-down-period
]


to setup
  clear-all
  import-pcolors "map.png"

  set first-day time:create "2019/01/01"
  set date first-day
  set sexual-maturity-age ( 5.5 * 365 )
  set liberally-hunted-bears 0
  set hunted-aggressive-bears 0

  create-bears number-of-bears [
    move-to one-of patches with [ pcolor = 56.4 ]
    set size 15
    set shape "bear"
    set kcal 20000 + random 10000
    set age random 30 * 365
    set sex one-of [ "male" "female" ]
    ifelse ( sex = "female" )
      [ set color pink ]
      [ set color blue ]
    set pregnant 0
    ifelse ( age >= sexual-maturity-age )
      [ set time-since-cub-birth random ( 365 * 3 ) ] ;; not all females will mate immediately
      [ set time-since-cub-birth ( 365 * 3 ) ] ;; so when cubs reach maturity, they can immediately get pregnant
  ]

  set gained-kcal 3000
  set lost-kcal 3000
  set traveled-distance 14
  set travel-kcal-lost 100
  set calm-down-period 28
  regrow-food
  reset-ticks
end


to go
  print-date
  if time:get "year" date = 2024 [ stop ]
  if time:get "month" date = 1 and time:get "day" date = 1 [ issue-hunting-permits ]
  regrow-food
  if not any? bears [ stop ]
  ask bears [
    check-kcal
    check-age
  ]
  set-season
  if season = "mating" [
    mate
  ]
  birth-cubs
  update-time-since-cub-birth

  if ( hunt-aggressive-bears and any? bears with [ agitation > 5 ] ) [
    hunt-aggressive
  ]
  hunt

  move-turtles
  calm-down-bears

  ask hunters with [ hunted = 1 ] [ die ]
  set date time:plus date 1 "days"
  tick
end


to print-date
  clear-output
  output-print "Current date:"
  output-print time:show date "MMMM d, yyyy"
end


to issue-hunting-permits
  if ( liberal-hunting = "non-restrictive" or liberal-hunting = "liberal, but no cubs" ) [
    create-hunters liberal-hunting-permits [
      set size 30
      set color yellow
      set shape "person"
      set hunt-day random 365
      set hunted 0
      set hunts-aggressive false
      hide-turtle
    ]
  ]
end


to set-season
  let month time:get "month" date
  ifelse (month >= 5 and month < 8)
    [ set season "mating" ]
    [ set season "normal" ]
end


to check-kcal
  if kcal <= 0 [ die ]
  set kcal kcal - lost-kcal
end


;; Bears die at 30
to check-age
  if age = 365 * 30 [ die ]
end


to calm-down-bears
  if ticks mod calm-down-period = 0 [
    ask bears with [agitation > 0] [
      set agitation agitation - 1
    ]
  ]
end


;; Updated time since a female bear last gave birth to cubs
to update-time-since-cub-birth
  ask bears with [ (sex = "female" ) and ( age >= sexual-maturity-age ) and ( pregnant = 0 ) ] [
    set time-since-cub-birth time-since-cub-birth + 1
  ]
end


;; Produces offspring from a pregnant female bear if to 'term' and
;; tracks pregnancy duration.
to birth-cubs
  ask bears with [ pregnant = 1 ] [
    ifelse pregnancy-duration = 194 [
      reproduce
      set pregnant 0
      set pregnancy-duration 0
      set time-since-cub-birth 0
    ][
      set pregnancy-duration pregnancy-duration + 1
    ]

  ]
end


;; Produces a number of cubs based on weighted list
to reproduce
  let pairs [ [ 1 0.2 ] [ 2 0.3 ] [ 3 0.3 ] [ 4 0.2 ] ]
    hatch first rnd:weighted-one-of-list pairs [ [p] -> last p ] [
    set age 1
    set pregnant 0
    set pregnancy-duration 0
    set sex one-of [ "male" "female" ]
    if sex = "male" [ set color blue ]
  ]
end


;; Non-pregnant female bears that reached maturity mate if
;; mature bears are close by
to mate
  ask bears with [ ( ( sex  = "female" ) and ( age >= sexual-maturity-age ) and ( pregnant != 1 ) and ( time-since-cub-birth >= ( 365 * 2.5 ) ) ) ] [
    if any? bears-here with [ ( ( sex  = "male" ) and ( age >= sexual-maturity-age ) ) ] [
      set pregnant 1
    ]
  ]
end


to hunt
  if liberal-hunting = "liberal, but no cubs" [
    if any? hunters with [ hunt-day = ticks and hunts-aggressive = false ] [
      ifelse any? bears with [ age > 2 * 365 ] [
        ask one-of hunters with [ hunt-day = ticks ] [
          show-turtle
          move-to one-of bears with [ age > 2 * 365 ]
          ask one-of bears-here with [ age > 2 * 365 ]  [ die ]
          set liberally-hunted-bears liberally-hunted-bears + 1
          set hunted 1
        ]
      ][
        ask hunters with [ hunt-day = ticks ] [
          set hunt-day ticks + 1 + random ( 365 - ticks - 1)
        ]
      ]
    ]
  ]

  if liberal-hunting = "non-restrictive" [
    if any? hunters with [ hunt-day = ticks and hunts-aggressive = false ] and any? bears [
      ask one-of hunters with [ hunt-day = ticks ] [
        show-turtle
        move-to one-of bears
        ask one-of bears-here [ die ]
        set liberally-hunted-bears liberally-hunted-bears + 1
        set hunted 1
      ]
    ]
  ]
end


to hunt-aggressive
  create-hunters count bears with [ agitation > 5 ] [
    set size 30
    set color red
    set shape "person"
    set hunts-aggressive true
    set hunted 0
  ]
  ask hunters with [ hunts-aggressive = true ] [
    show-turtle
    move-to one-of bears with [ agitation > 5 ]
    ask one-of bears-here with [ agitation > 5 ]  [ die ]
    set hunted-aggressive-bears hunted-aggressive-bears + 1
    set hunted 1
  ]
end


to regrow-food
  let needed-food 0
  let current-food count(patches with [pcolor = orange])
  while [ needed-food < (available-food - current-food) ] [
      if (random 100 < regrowth-rate) [
        ask one-of patches with [ pcolor = 56.4 ]
        [set pcolor orange]
    ]
    set needed-food needed-food + 1
  ]
end


to move-turtles
  let quarter 0
  ask bears [
    set traveled-today 0
  ]
  while [quarter < 3] [
    ask bears [
      let new-patch patch-here
      ifelse any? patches in-radius traveled-distance with [ pcolor = orange ] [
        set new-patch one-of patches in-radius traveled-distance with [ pcolor = orange ]
      ] [
        ifelse any? patches in-radius traveled-distance with [pcolor = 36.8] [
          ; move to human turf
          set new-patch one-of patches in-radius traveled-distance with [pcolor = 36.8]
        ] [
          let dist random-normal 40 10
          if dist < 0 [set dist 0]
          set new-patch one-of patches in-radius dist with [pcolor = 56.4]
        ]
      ]
      let dist distance new-patch
      set traveled-today traveled-today + dist
      let journey-cost dist * travel-kcal-lost
      set kcal kcal - journey-cost
      move-to new-patch
      eat-food
    ]
    set quarter quarter + 1
  ]
end


to eat-food
  if kcal < 15000 [
    if [pcolor] of patch-here != 56.4 [
      set kcal kcal + gained-kcal
    ]
    if [pcolor] of patch-here = orange [
      ask patch-here [
        set pcolor 56.4
      ]
    ]
  ]
  if [pcolor] of patch-here = 36.8 [
    set agitation agitation + 1
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
350
10
731
562
-1
-1
1.0
1
10
1
1
1
0
1
1
1
-186
186
-271
271
0
0
1
days
40.0

BUTTON
87
98
150
131
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
80
150
252
183
number-of-bears
number-of-bears
0
300
283.0
1
1
NIL
HORIZONTAL

BUTTON
175
98
238
131
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
79
216
251
249
available-food
available-food
0
8000
3057.0
1
1
NIL
HORIZONTAL

PLOT
776
28
976
178
Bear population over time
Ticks
Bear Count
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

OUTPUT
92
29
247
75
11

MONITOR
768
192
984
237
Number of pregnant bears
count bears with [pregnant = 1]
17
1
11

SLIDER
75
412
248
445
liberal-hunting-permits
liberal-hunting-permits
0
100
0.0
1
1
NIL
HORIZONTAL

MONITOR
802
253
950
298
Liberally hunted bears
liberally-hunted-bears
17
1
11

PLOT
783
404
945
541
food over time
ticks
food count
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count(patches with [pcolor = orange])"

SLIDER
80
256
252
289
regrowth-rate
regrowth-rate
1
100
25.0
1
1
NIL
HORIZONTAL

PLOT
1028
139
1188
259
% of angry bears
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot (count bears with [agitation > 0]) / (count bears)"

PLOT
951
404
1121
541
avg traveled distance per day
days
km
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot mean [traveled-today] of bears / 7.3"

MONITOR
1026
86
1166
131
number of angry bears
count bears with [agitation > 0]
2
1
11

MONITOR
1024
31
1213
76
number of very angry bears
count bears with [agitation > 5]
17
1
11

CHOOSER
83
360
237
405
liberal-hunting
liberal-hunting
"none" "liberal, but no cubs" "non-restrictive"
0

SWITCH
70
321
251
354
hunt-aggressive-bears
hunt-aggressive-bears
0
1
-1000

MONITOR
802
307
953
352
Hunted aggressive bears
hunted-aggressive-bears
17
1
11

MONITOR
1006
315
1096
360
NIL
count hunters
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

bear
true
0
Circle -7500403 true true 30 60 240
Circle -7500403 true true 30 30 90
Circle -7500403 true true 180 30 90
Circle -16777216 true false 90 120 30
Circle -16777216 true false 180 120 30
Polygon -16777216 true false 120 180
Polygon -16777216 true false 120 180 180 180 150 225 120 180
Line -16777216 false 150 255 150 210
Line -16777216 false 150 255 165 255
Line -16777216 false 150 255 135 255
Line -16777216 false 165 255 195 240
Line -16777216 false 135 255 105 240

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count bears</metric>
    <enumeratedValueSet variable="available-food">
      <value value="3057"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="hunt-aggressive-bears">
      <value value="true"/>
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="regrowth-rate">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="liberal-hunting-permits">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-bears">
      <value value="283"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="liberal-hunting">
      <value value="&quot;none&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
