---
title: "Intro to datagoboop: pitch & playback"
author: Arnie
date: '2021-01-18'
slug: datagoboop-intro
categories:
  - data sonification
  - data visualization
  - datagoboop
tags:
  - data viz
  - datagoboop
subtitle: ''
summary: ''
authors: []
lastmod: '2021-01-18T22:53:20-08:00'
featured: no
image:
  caption: '[Nicholas-Rougeux-the-four-seasons-color](https://www.c82.net/offthestaff/?id=4)'
  focal_point: ''
  preview_only: no
projects: []
toc: yes
fig_caption: true
markup:
  tableOfContents:
    endLevel: 2
    startLevel: 1
---






# Introducing `datagoboop`

`datagoboop` is an R package for data sonification, or the audio version of data visualization.  This project started off while I was dreaming of representing data as a symphony --- our ears can with some training pick out each instrument in a symphony orchestra (maybe 15-20 instruments), whereas representing more than 4 or 5 variables in one plot usually becomes somewhat cumbersome.

Turns out a library of high-quality audio files can get large fast, so most output from `datagoboop` sounds more like 8-bit video game music :stuck_out_tongue_winking_eye:.  But we still think it sounds pretty neat!



## Why `datagoboop`

There are a few other data sonification packages for R, such as

+ [`sonify`](https://cran.r-project.org/web/packages/sonify/index.html)
+ [`audiolyzr`](https://cran.r-project.org/web/packages/audiolyzR/index.html)
+ [`playitbyr`](http://playitbyr.org/)

(In particular, I like the way `audiolyzr` [sounds!](https://www.r-bloggers.com/2013/01/audiolyzr-data-sonification-with-r/))

The main difference between these packages and `datagoboop` is that `datagoboop` includes several built-in sonification versions of common plots, but also allows users to build audio plots piece by piece by providing a higher level of control and modular functions.



# Setup


```r
if (!requireNamespace("devtools")) install.packages('devtools')
devtools::install_github("akseong/datagoboop")
```




# Ground-level sonification

## Pitch

Pitch in `datagoboop` is parameterized as idealized piano key numbers, where the pitch frequency (hz) is given as a function of the piano key number \$n\$ by
\$\$f(n) = 2^{\big( \frac{n - 49}{12}\big)}  \times 440\$\$

<div class=fyi>

[The Wikipedia page for piano key frequencies](https://en.wikipedia.org/wiki/Piano_key_frequencies) is a useful reference.

Note that `datagoboop`'s implementation uses the equation above, so the (seemingly arbitrary) numbering for the extended keys on the Wikipedia page will not correspond correctly.
</div>



## function: `note()`


```r
library(datagoboop)

midC <- note(40)
wplay(midC, file_path = "index.en.Rmark/midC.wav")
```

<audio controls="">
<source src="index.en.Rmark/midC.wav" type="audio/wav"/>
</audio>

`note()` is the most basic function in `datagoboop` --- most other functions in `datagoboop` are built on top of it.  The only required argument is a `pkey` (piano key); output is a .wav-format vector.

The optional arguments in `note()` are worth spending a moment on, since they appear frequently in `datagoboop` functions.  

+ optional arguments and defaults: 
    - `vol = 1`, volume (values from 0 to 1);
    - `dur = 1`, duration in seconds;
    - `fs = 44100`, sampling rate (varies by speaker hardware/audio driver);
    - `inst_lab = "sine"`, instrument type 
        + `"piano"`, `"string"`, `"wind"`, `"bass"`, are built in, though as mentioned they sound like an 8-bit piano, string, flute, or bass 
        + You can also add sounds using `add_inst()` if you don't like our 8-bit sounds, then specify its label here;
    - `decay = FALSE`, exponential decay of sound;
    - `decay_rate = 6`, sound decay rate if `decay = TRUE` 



```r
midC_bounce <- note(
  pkey = 40, 
  vol = 1, 
  dur = 2, 
  inst_lab = "piano",
  decay = TRUE,
  decay_rate = 6)

wplay(midC_bounce, file_path = "index.en.Rmark/midC_bounce.wav")
```

<audio controls="">
<source src="index.en.Rmark/midC_bounce.wav" type="audio/wav"/>
</audio>




## functions: `cplay()`, `wplay()`

To actually play audio, you'll need to use either
+ `cplay()`: audio playback with console controls (name intended to evoke "control playback")
+ `wplay()`: audio playback more suited for .Rmd documents knitted to HTML 
    + `wplay()`'s default behavior in console is to institute a system timeout while playback is ongoing.  
    + `wplay()`'s default behavior __when knitting an .Rmd to HTML__ is to save the audio output as a `.wav` (named with timestamp), in a folder with the same name as your .Rmd file. 

<div class=fyi>

+ you can set `wplayback = FALSE` in the parent environment (i.e. just create a new variable `wplayback = FALSE`) to suppress all playback from calls to `wplay()`, for example when you are executing multiple code chunks.  Just set it to `TRUE` when you want to hear it again!
+ you can also set the `wplayback` argument in the function arguments for an individual call to `wplay()`.
</div>



# Example: audio histogram / violinplot

One of the first things we did after creating some of the basic playback functions was to make an audio version of a histogram.  A little modification turns it into something like a violinplot, which I think may convey the general shape a little more clearly.


Overall, we're going to

1. map histogram breakpoints to pitch;
1. map counts/bar heights to duration;
1. scale volume to counts/bar heights.  (Volume can be a bit tricky, because volume is a combination of different sound wave characteristics --- not just amplitude.  For example, higher frequencies/pitches sound louder than lower frequencies with the same amplitude)

I think it's a bit clearer when we start off hearing the highest count bars, and then allow the lower count bars to gradually emerge (so we'll do that :+1:).


## Audio Histogram

First, we generate the data, and create a histogram.  We'll specify the breaks manually (16 breaks = 15 bins), and also store the histogram's info.


```r
set.seed(2)
y <- rnorm(1000, 40, 5)
breaks = seq(
  floor(min(y)), 
  floor(max(y)) + 1, 
  length.out = 16)
hist_inf <- hist(y, breaks = breaks)
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/unnamed-chunk-1-1.png" width="672" />



Next, we'll select a C-major scale to map the breaks to.  Note that only every other note is used to avoid dissonance.  (There will still be some!)



```r
Cmajor <- major_scale(tonic_pkey = 40, n_octaves = 4)
pkeys <- Cmajor[2 * 1:length(breaks)]
```


Now we need to construct each "bar" of the audio histogram --- each bar gets a note.  Some calculations are required, since we need to fill in each note with silence to start, then the pitch of the note for a duration that expresses bar height.

We use the sampling rate and desired total duration to calculate total length of each note (each note is a `.wav` vector, playable on its own).



```r
fs <- 44100
total_dur <- 8
wave_length <- total_dur*fs

# scale the durations and volume to reflect counts
# i.e. the longest note is the bin with the highest counts
vols <- (hist_inf$counts)/(max(hist_inf$counts))
durs <- vols * total_dur
fill_durs <- wave_length - durs*fs
```


Last, we construct each note in a loop, and sum each note's sound wave together to construct the audio histogram's sound wave.

_Note:_ summing note vectors to construct the sound wave is OK even though the vectors will exceed [-1, 1] because wplay() normalizes the soundwave to [-1, 1]


```r
audiohist <- rep(0, wave_length)
for (i in 1:length(durs)){
  wave_i <- c(
    rep(0, fill_durs[i]),# notes begin with silence
    note(
      pkey = pkeys[i], 
      dur = durs[i], 
      vol = vols[i]
    ))
  audiohist <- audiohist + wave_i[1:wave_length]
}
```


The histogram is reproduced below for purposes of comparison.


```r
wplay(audiohist, file_path = "index.en.Rmark/hist.wav")
```

<audio controls="">
<source src="index.en.Rmark/hist.wav" type="audio/wav"/>
</audio>

<img src="{{< blogdown/postref >}}index.en_files/figure-html/unnamed-chunk-6-1.png" width="672" />


## Audio Violinplot

I like the overall effect of the histogram --- sort of like an island emerging out of the water.  But the tails are _very_ hard to hear.  So, let's try a violin plot, which we can do simply by reversing the sound vector and placing it back to back.



```r
wplay(c(audiohist, rev(audiohist)), file_path = "index.en.Rmark/violin.wav")
```

<audio controls="">
<source src="index.en.Rmark/violin.wav" type="audio/wav"/>
</audio>

Fortuitously, you can hear a progression in there that sounds --- just for a moment --- like the opening to Debussy's _[La Fille Aux Cheveux De Lin](https://www.youtube.com/watch?v=wv8iHEM4g7Q&ab_channel=Adagietto)_.  


# Next up: built-in audio plot analogues

Next post will cover some of the basic plot types built-into `datagoboop`, for example, a scatterplot, in which the lower register indicates rising values in the \$x\$-variable, and the higher register indicates the value of the \$y\$-variable.


```r
library(ggplot2)
ggplot(mtcars, aes(y=disp, x = mpg, size = factor(gear))) + 
  geom_point(alpha = 0.25) + 
  labs(title = "mtcars")
```

<img src="{{< blogdown/postref >}}index.en_files/figure-html/unnamed-chunk-8-1.png" width="672" />



```r
mtcars_audio <- sonify_scatter(
    data = mtcars,
    x_var = "mpg",
    y_var = "disp",
    factor_var = "gear"
  )
# output suppressed; shows progress bar in console
```






```r
wplay(mtcars_audio, file_path = "index.en.Rmark/mtc.wav")
```

<audio controls="">
<source src="index.en.Rmark/mtc.wav" type="audio/wav"/>
</audio>


# A small parting gift



```r
bp2_stereo <- bach(stereo=TRUE)
cplay(bp2_stereo)
```


















