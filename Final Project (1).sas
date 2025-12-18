/* ---------- Setup: paths and library ---------- */

%let projpath = /home/u64313069/pg3;                     /* (setup, not graded) */
%let csvpath  = &projpath./Listings.csv;                 /* (setup, not graded) */

libname project "&projpath.";                            /* 2a */


/* 
   PG1.02 – Accessing Data
   Topic 1: Importing data (1a, 1b)
   Topic 2: Access SAS tables in a library (2a, 2b, 2c)
*/

/* 1a: PROC IMPORT step */
proc import datafile="&csvpath."
    out=project.airbnb_raw
    dbms=csv
    replace;
run;                                                      /* 1a */

/* 1b: PROC CONTENTS for imported table, VARNUM option */
proc contents data=project.airbnb_raw varnum;
    title "Contents of Airbnb Raw Listing Data (VarNum Order)";
run;                                                      /* 1b */

/* 2a: LIBNAME statement (already above, repeated here as explicit use) */
libname project "&projpath.";                            /* 2a */

/* 2b: PROC CONTENTS for the library using _ALL_ and NODS */
proc contents data=project._all_ nods;
    title "Contents of PROJECT Library (All Tables)";
run;                                                      /* 2b */

/* 2c: PROC CONTENTS for a single table in the library */
proc contents data=project.airbnb_raw;
    title "Contents of project.airbnb_raw";
run;                                                      /* 2c */

title;                                                    /* clear titles (housekeeping) */


/* 
   PG1.03 – Exploring and Validating Data
   Topic 3: PROC PRINT (3a–3e)
   Topic 4: Duplicates with FREQ and SORT (4a, 4b)
*/

/* Create a small cleaned subset just for exploration */
data project.airbnb_explore;
    set project.airbnb_raw;
    /* Keep some key columns, including host_id now */
    keep listing_id host_id name city district neighbourhood 
         property_type room_type accommodates bedrooms 
         price review_scores_rating;
run;


/* Formats used in question 3 (e) */
proc format;
    value pricefmt
        low-50    = "Budget (<=50)"
        50<-150   = "Mid-range (50-150)"
        150<-high = "High-end (>150)";
    value ratingfmt
        0-80      = "Low"
        80<-95    = "Medium"
        95<-100   = "High";
run;                                                      /* 3e (define formats) */

/* 3a–3e: PROC PRINT with OBS=, VAR, WHERE IN, formats */
proc print data=project.airbnb_explore (obs=10);          /* 3a, 3b */
    var listing_id name city neighbourhood room_type 
        price review_scores_rating;                       /* 3c */
    where room_type in ("Entire home/apt","Private room");/* 3d */
    format price pricefmt. 
           review_scores_rating ratingfmt.;               /* 3e */
    title "First 10 Airbnb Listings – Selected Rooms and Formats";
run;
title;                                                    /* housekeeping */

proc contents data=project.airbnb_raw varnum;
run;


/* 4a: Use PROC FREQ to identify duplicate HOST IDs */
proc freq data=project.airbnb_explore;
    tables host_id / nocum nopercent;
    title "Frequency of Host IDs (Checking for Duplicate Hosts)";
run;
title;

/* 4b: Use PROC SORT to remove unwanted duplicate rows */
proc sort data=project.airbnb_explore
          out=project.airbnb_nodups nodupkey;
    by host_id;
run;                                                      /* 4b */


/* 
   PG1.04 – Preparing Data
   Topic 5: DATA step, SET, WHERE, DROP/KEEP, FORMAT, LENGTH, assignment (5a–5f)
   Topic 6: IF styles (6a–6c)
*/

data project.airbnb_prepped;
    set project.airbnb_nodups;                            /* 5a */

    where city ne "" and price > 0;                       /* 5b */

    /* Keep only relevant columns in final output */
    keep listing_id name city neighbourhood district property_type room_type
         accommodates bedrooms price minimum_nights maximum_nights
         review_scores_rating instant_bookable avg_price_per_night
         stay_category long_stay_flag;                    /* 5c */

    length stay_category $12 long_stay_flag $3;           /* 5e */

    format price dollar8.2;                               /* 5d */

    /* Create new columns using assignment statements */
    avg_price_per_night = price / max(1, minimum_nights); /* 5f (assignment #1) */

    if maximum_nights > 28 then                           /* 5f (assignment #2 inside IF) */
        stay_category = "Long stay";
    else stay_category = "Short stay";

    /* ---------- Question 6: IF-THEN styles ---------- */

    /* 6a: Simple IF THEN */
    if accommodates >= 6 then long_stay_flag = "Yes";     /* 6a */

    /* 6b: IF THEN; ELSE IF THEN */
    if review_scores_rating >= 95 then
        long_stay_flag = "Yes";
    else if review_scores_rating < 70 then
        long_stay_flag = "No";                            /* 6b */

    /* 6c: IF THEN DO; END; */
    if city = "Chicago" then do;
        stay_category = "Chicago Stay";
        avg_price_per_night = price;
    end;                                                  /* 6c */
run;


/* 
   PG1.05 – Analyzing and Reporting on Data
   Topic 7: Titles/footnotes/macros/labels (7a–7f)
   Topic 8: Frequency reports (8a, 8b)
   Topic 9: PROC MEANS summary statistics (9a–9d)
*/

/* Macro vars for titles/footnotes (used in 7a–7d) */
%let projcity   = Airbnb City Listings;                   /* 7d (macro var) */
%let datasource = Public Airbnb CSV;                      /* 7d (macro var) */

data project.airbnb_labeled;
    set project.airbnb_prepped;
    label
        listing_id           = "Listing ID"
        city                 = "City"
        neighbourhood        = "Neighbourhood"
        room_type            = "Room Type"
        price                = "Total Price"
        avg_price_per_night  = "Average Price per Night";
run;                                                      /* 7e (labels defined) */

/* 7a: TITLE using macro variable */
/* 7b: TITLE2 subtitle */
/* 7c: FOOTNOTE */
/* 7d: Macro variables used in title/footnote */
title1 "&projcity.";                                      /* 7a, 7d */
title2 "Selected Listings Summary";                       /* 7b */
footnote "Data source: &datasource.";                     /* 7c, 7d */

/* 7e: Display labels in PROC PRINT using LABEL option */
proc print data=project.airbnb_labeled (obs=15) label;
    var listing_id city neighbourhood room_type 
        price avg_price_per_night;
run;                                                      /* 7e */

/* 7f: Clear titles and footnote */
title;                                                    /* 7f */
footnote;                                                 /* 7f */


/* ---- Question 8: Frequency reports ---- */

/* 8a: One-way frequency with ORDER= and output to table */
proc freq data=project.airbnb_prepped order=freq;
    tables room_type / out=project.freq_roomtype;
    title "Frequency of Room Type (Most Common First)";
run;                                                      /* 8a */
title;

proc format;
    value accomfmt
        low-2   = "1-2 guests"
        3-4     = "3-4 guests"
        5-high  = "5+ guests";
run;                                                      /* 8b (format used for 2-way freq) */

/* 8b: Two-way frequency, formats, suppress stats */
proc freq data=project.airbnb_prepped;
    tables room_type * accommodates / norow nocol nopercent; /* suppress stats */ /* 8b */
    format accommodates accomfmt.;                          /* 8b */
    title "Cross-tab of Room Type by Accommodates";
run;
title;


/* ---- Question 9: PROC MEANS summary stats ---- */

/* 9a: Non-default stats (mean, median, std, min, max)
/* 9b: VAR statement
/* 9c: CLASS + WAYS
/* 9d: Output to new table */
proc means data=project.airbnb_prepped
           mean median std min max;
    var price avg_price_per_night review_scores_rating; /* 9b */
    class room_type;                                    /* 9c */
    ways 1;                                             /* 9c */
    output out=project.means_roomtype
        mean(price avg_price_per_night review_scores_rating)=
        median(price)=MedianPrice;                      /* 9d */
    title "Summary Statistics of Prices and Ratings by Room Type";
run;                                                    /* 9a–9d */
title;


/* 
   PG1.07 – Using SQL in SAS
   Topic 12: PROC SQL queries (12a–12c)
   Topic 13: SQL join with 3 tables + aliases (13a, 13b)
*/

/* 12a: Create a new table with subset of columns */
proc sql;
    create table project.sql_subset as
    select listing_id, city, neighbourhood, room_type,
           price, avg_price_per_night, review_scores_rating
    from project.airbnb_prepped;
quit;                                                    /* 12a */


/* 12b: Display subset based on WHERE clause */
proc sql;
    select listing_id, city, room_type, price, review_scores_rating
    from project.sql_subset
    where room_type = "Entire place"
      and price between 50 and 200;
quit;                                                   /* 12b */

/* 12c: Display table sorted by two columns */
proc sql;
    select city, room_type, price, review_scores_rating
    from project.sql_subset
    order by city, price desc;
quit;                                                    /* 12c */


/* Helper tables for 13a–13b (join) */
proc sql;
    create table project.city_avg_price as
    select city,
           mean(price) as city_avg_price
    from project.airbnb_prepped
    group by city;
quit;

proc sql;
    create table project.roomtype_avg_rating as
    select room_type,
           mean(review_scores_rating) as rt_avg_rating
    from project.airbnb_prepped
    group by room_type;
quit;

/* 13a: Display result of merging at least three tables
   13b: Use aliases */
proc sql;
    create table project.join3 as
    select a.listing_id,
           a.city,
           a.room_type,
           a.price,
           b.city_avg_price,
           c.rt_avg_rating
    from project.airbnb_prepped      as a
         left join project.city_avg_price      as b
            on a.city = b.city
         left join project.roomtype_avg_rating as c
            on a.room_type = c.room_type;
quit;                                                    /* 13a, 13b */
proc print data=project.join3 (obs=10);
run;


/* 
   PG2.01 – Controlling DATA Step Processing
   Topic 14: SELECT, KEEP=/DROP=, PUTLOG (14a–14c)
*/

data project.low_price
     project.high_price;
    set project.airbnb_prepped (keep=listing_id city room_type price);
                                                           /* 14b (KEEP= option) */

    /* 14c: At least two informative PUTLOG statements */
    if price <= 0 then putlog "WARNING: Non-positive price for listing " listing_id=; /* 14c */
    if city = "" then putlog "NOTE: Missing city for listing " listing_id=;          /* 14c */

    /* 14a: SELECT group, OTHERWISE, explicit output to multiple tables */
    select;
        when (price < 75)  output project.low_price;       /* 14a(2) explicit output */
        when (price >= 75) output project.high_price;      /* 14a(2) explicit output */
        otherwise putlog "NOTE: Price not categorized: " listing_id= price=; /* 14a(1) OTHERWISE */
    end;
run;                                                       /* 14a, 14b, 14c */


/* 
   PG2.02 – Summarizing Data
   Topic 15: RETAIN, sum statement, FIRST./LAST., PROC SORT (15a–15d)
*/

/* 15d: PROC SORT */
proc sort data=project.airbnb_prepped
          out=project.by_city;
    by city;
run;                                                      /* 15d */

/* 15a: RETAIN
   15b: Sum statement
   15c: Use FIRST. and LAST. */
data project.city_summary;
    set project.by_city;
    by city;

    retain total_price 0 n_listings 0;                    /* 15a */

    if first.city then do;                                /* 15c */
        total_price = 0;
        n_listings = 0;
    end;

    total_price + price;                                  /* 15b (sum statement) */
    n_listings + 1;                                       /* 15b */

    if last.city then do;                                 /* 15c */
        avg_price = total_price / n_listings;
        output;
    end;
run;
proc print data=project.city_summary (obs=10);
    var avg_price total_price n_listings;
    title "Numeric Summary Columns from CITY_SUMMARY";
run;
title;




/* 
   PG2.03 – Manipulating Data with Functions
   Topics 16–21
   16: CALL routines
   17: Date functions
   18: Character functions (SUBSTR, LENGTH, SCAN, PROPCASE, UPCASE, CATX)
   19: FIND, SUBSTR on left, TRANWRD, COMPRESS, STRIP/trim/compbl
   20: At least 8 numeric/stat functions across categories
   21: Converting column type
*/

data project.func_demo;
    set project.airbnb_prepped (obs=100);

    length clean_name $200 short_neighbourhood $40;       /* (support for 18) */

    /* ---- 17: Date-related functions ---- */

    today_date = today();                                 /* 17a */
    months_back = mod(listing_id, 6);                     /* helper */

    booking_date = intnx('month', today_date, -months_back, 'same'); /* 17e (INTNX) */
    format today_date booking_date date9.;

    first_of_booking_month = 
        mdy(month(booking_date), 1, year(booking_date));  /* 17b (MDY) */

    booking_year     = year(booking_date);                /* 17c (YEAR) */
    booking_month    = month(booking_date);               /* 17c (MONTH) */
    booking_weekday  = weekday(booking_date);             /* 17c (WEEKDAY) */
    days_since_booking = intck('day', booking_date, today_date); /* 17d (INTCK) */

    /* ---- 18: Character functions ---- */

    name_length = length(name);                           /* 18b (LENGTH) */
    name_prefix = substr(name, 1, 15);                    /* 18a (SUBSTR) */

    short_neighbourhood = 
        propcase(scan(neighbourhood, 1, ','));            /* 18c (SCAN), 18d (PROPCASE) */

    city_upper = upcase(city);                            /* 18e (UPCASE) */

    city_room = catx(' - ', city, room_type);             /* 18f (CATX) */

    /* ---- 19: FIND, SUBSTR on left, TRANWRD, COMPRESS, STRIP ---- */

    /* 19a: FIND – look for the word "room" in the listing name (case-insensitive) */
    pos_room = find(name, "room", 'i');                    /* 19a (FIND) */

    /* 19b: SUBSTR on the left side – emphasize the word "room" if present */
    name_modified = name;                                  /* create a writable copy */
    if pos_room > 0 then substr(name_modified, pos_room, 4) = "ROOM";  
                                                           /* 19b (SUBSTR on left) */

    /* 19c: TRANWRD – replace 'St.' with 'Street' in neighbourhood text */
    neighbourhood_clean = tranwrd(neighbourhood, "St.", "Street");  /* 19c (TRANWRD) */

    /* 19d: COMPRESS – remove spaces from neighbourhood */
    neighbourhood_nospace = compress(neighbourhood);       /* 19d (COMPRESS) */

    /* 19e: STRIP – remove leading/trailing blanks from city */
    city_stripped = strip(city);                           /* 19e (STRIP) */


    /* ---- 20: Numeric/stat functions ---- */

    score_mean     = mean(of review_scores_rating);       /* 20b (MEAN) */

    rounded_price  = round(price, 1);                     /* 20a (ROUND) */
    ceil_price     = ceil(price);                         /* 20a (CEIL) */
    floor_price    = floor(price);                        /* 20a (FLOOR) */
    int_price      = int(price);                          /* 20a (INT) */

    high_metric    = largest(1, price, avg_price_per_night); /* 20b (LARGEST) */
    min_metric     = min(price, avg_price_per_night);        /* 20b (MIN) */
    max_metric     = max(price, avg_price_per_night);        /* 20b (MAX) */
    sum_metric     = sum(price, avg_price_per_night);        /* 20b (SUM) */

    n_nonmissing   = n(price, bedrooms, review_scores_rating);  /* 20c (N) */
    n_missing      = nmiss(price, bedrooms, review_scores_rating); /* 20c (NMISS) */
    c_missing      = cmiss(city, neighbourhood, property_type);    /* 20c (CMISS) */

    /* ---- 16: CALL routines ---- */

    if room_type = "" then 
        call missing(city_room, rounded_price);           /* 16a (CALL MISSING) */

    x1 = price;
    x2 = avg_price_per_night;
    x3 = review_scores_rating;
    call sortn(of x1-x3);                                 /* 16b (CALL SORTN) */

run;
proc print data=project.func_demo (obs=10);
    var 
        /* Original identifiers */
        listing_id city neighbourhood price

        /* 17: Date functions */
        today_date booking_date first_of_booking_month days_since_booking

        /* 18: Character functions */
        name_length name_prefix short_neighbourhood city_upper city_room

        /* 19: FIND + SUBSTR-left + TRANWRD + COMPRESS + STRIP */
        pos_room name_modified neighbourhood_clean neighbourhood_nospace city_stripped

        /* 20: Numeric/stat functions */
        rounded_price ceil_price floor_price int_price
        high_metric min_metric max_metric sum_metric
        n_nonmissing n_missing c_missing

        /* 16: CALL routines */
        x1 x2 x3
    ;
    title "PG2.03 Demonstration (Topics 16–21)";
run;
title;




/* 21a–21d: Converting column types + PROC CONTENTS */

data project.type_conversion;
    set project.func_demo;

    bedrooms_char = put(bedrooms, 8.);                    /* 21b helper + 21b? */
    bedrooms_num  = input(bedrooms_char, 8.);             /* 21a (INPUT: char->num) */

    price_char    = put(price, dollar8.2);                /* 21b (PUT: num->char) */

    auto_conv = bedrooms_char + 1;                        /* 21c (automatic conversion in log) */
run;

proc contents data=project.type_conversion;
    title "Type Conversion Demo – Showing Character/Numeric Types";
run;                                                      /* 21d */
title;


/*
   PG2.05 – Combining Tables
   Topic 24: Concatenate, simple merge (24a, 24b)
   Topic 25: Merge with non-matches + options (25a, 25b)
*/

/* Split into two tables for concatenation and merging */
data project.entire_home project.private_room;
    set project.airbnb_prepped;
    if room_type = "Entire home/apt" then output project.entire_home;
    else if room_type = "Private room" then output project.private_room;
run;                                                      /* (prep for 24, 25) */

/* 24a: Concatenate two tables using RENAME= option */
data project.concat_example;
    set project.entire_home
        project.private_room (rename=(price=price_private)); /* 24a (RENAME= while concatenating) */
run;

/* 24b: Simple ONE-to-ONE merge by listing_id */

/* Build a small table with host_is_superhost from the RAW data */
data project.host_flag;
    set project.airbnb_raw (keep=listing_id host_is_superhost);
run;   /* 24b: create host_flag with listing_id + host_is_superhost */

/* Sort both datasets by listing_id for the merge */
proc sort data=project.airbnb_prepped; 
    by listing_id; 
run;  /* 24b prep */

proc sort data=project.host_flag;       
    by listing_id; 
run;  /* 24b prep */

/* Simple one-to-one merge on listing_id */
data project.merge_one_to_one;
    merge project.airbnb_prepped
          project.host_flag;
    by listing_id;
run;   /* 24b */


/* 25a: Merge with non-matches using IN= and output matches/non-matches
   25b: Use RENAME= and KEEP=/DROP= options */

data project.city_info;
    set project.city_summary (rename=(avg_price=city_avg_price)); /* 25b(1) RENAME= */
    keep city city_avg_price;                                     /* 25b(2) KEEP=  */
run;

proc sort data=project.airbnb_prepped out=project.airbnb_by_city; by city; run;
proc sort data=project.city_info;                         by city; run;

data project.matches
     project.nonmatches;
    merge project.airbnb_by_city (in=inListings)
          project.city_info      (in=inCity);
    by city;

    if inListings and inCity then 
        output project.matches;                           /* 25a(1),(2) matches table */
    else if inListings and not inCity then 
        output project.nonmatches;                        /* 25a(1),(2) non-matches table */
run;

proc print data=project.city_info;
    title "PG2.05 (25b): City Info Table with City_Avg_Price";
run;
title;
proc print data=project.matches (obs=10);
    var city listing_id price city_avg_price;
    title "PG2.05 (25a): Sample of MATCHES (Listings with City Info)";
run;
title;


/*
   PG2.06 – Processing Repetitive Code (DO Loops)
   Topic 26: DO loops with index, BY option, WHILE/UNTIL, explicit OUTPUT
*/

/* 26a: DO loop using index column + 26d explicit OUTPUT */
data project.do_loop_index;
    do i = 1 to 10;                                       /* 26a */
        squared = i**2;
        cubed   = i**3;
        output;                                           /* 26d */
    end;
run;

/* Prepare sorted data to demonstrate BY option */
proc sort data=project.airbnb_prepped
          out=project.airbnb_price_sorted;
    by price;
run;                                                      /* 26b (BY used in next step) */

/* 26b, 26c, 26d: DO UNTIL with BY and explicit output */
data project.do_until_example;
    set project.airbnb_price_sorted;
    by price;                                             /* 26b (BY option) */

    retain count_high 0;

    threshold = 300;

    do until(price > threshold);                          /* 26c (UNTIL) */
        count_high + 1;
        output;                                           /* 26d (explicit output in loop) */
        leave;                                            /* just to avoid infinite loop */
    end;
run;

/* 26c, 26d: DO WHILE with explicit OUTPUT */
data project.do_while_example;
    set project.airbnb_price_sorted;
    by price;                                             /* 26b (BY option again) */
    retain running_total 0;

    running_total + price;

    do while(running_total < 2000);                       /* 26c (WHILE) */
        extra_flag = 1;
        output;                                           /* 26d */
        leave;
    end;
run;

/* Show DO loop index example (26a, 26d) */
proc print data=project.do_loop_index;
    title "PG2.06: DO Loop with Index (26a, 26d)";
run;

/* Show a few rows from DO UNTIL example */
proc print data=project.do_until_example (obs=10);
    title "PG2.06: DO UNTIL with BY and OUTPUT (26b, 26c, 26d)";
run;

/* Show a few rows from DO WHILE example */
proc print data=project.do_while_example (obs=10);
    title "PG2.06: DO WHILE with BY and OUTPUT (26b, 26c, 26d)";
run;
title;
