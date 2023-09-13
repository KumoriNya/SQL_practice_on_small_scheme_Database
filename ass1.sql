-- COMP3311 22T3 Assignment 1
--
-- Fill in the gaps ("...") below with your code
-- You can add any auxiliary views/function that you like
-- The code in this file *MUST* load into an empty database in one pass
-- It will be tested as follows:
-- createdb test; psql test -f ass1.dump; psql test -f ass1.sql
-- Make sure it can load without error under these conditions

-- Q1: new breweries in Sydney in 2020
-- breweries founded where it's located_in.metro = 'sydney' and founded = 2020
create or replace view Q1(brewery,suburb)
as
select 	br.name, l.town
from	Breweries br 
join 	Locations l on	br.located_in = l.id
where	l.metro = 'Sydney' and br.founded = 2020
order by	br.name
;

-- Q2: beers whose name is same as their style

create or replace view Q2(beer,brewery)
as
select 	b.name, br.name
from	Beers b 
join 	Styles s on b.style = s.id
join 	Brewed_By brb on b.id = brb.beer
join 	Breweries br on brb.brewery = br.id
where	b.name = s.name
order by	b.name, br.name
;

-- Q3: original Californian craft brewery
-- name and foundation year of the oldest brewery in California
create or replace view BreweryInCalifornia
as
select	br.name, br.founded
from	Breweries br join Locations l
on		br.located_in = l.id
where	l.region = 'California'
;

create or replace view oldest(founded)
as
select	MIN(founded)
from	BreweryInCalifornia
;

create or replace view Q3(brewery, founded)
as
select	br.name, br.founded
from	Breweries br join oldest
on		br.founded = oldest.founded
;

-- Q4: all IPA variations, and how many times each occurs
-- From all styles,
	-- Select the ones with 'IPA' in the name
-- From all beers,
	-- Select the ones that are brewed in the selected styles

create or replace view BeersJoinStylesWithIPA
as
select	b.name as beer_name, s.name as style_name
from	Beers b 
join 	Styles s on b.style = s.id
where	s.name like '%IPA%'
order by	s.name
;

create or replace view Q4(style,count)
as
select	style_name, count(*)
from	BeersJoinStylesWithIPA
group by	style_name
;

-- Q5: all Californian breweries, showing precise location

create or replace view LocationsWithPrecision
as
select	id, country, region, town as town_or_metro
from	Locations l
where	l.town is not null
union
select	id, country, region, metro as town_or_metro
from	Locations l
where	l.town is null
order by id
;

create or replace view Q5(brewery,location)
as
select	br.name, lp.town_or_metro
from	LocationsWithPrecision lp join Breweries br
on		br.located_in = lp.id
where	lp.region = 'California'
order by	br.name
;

-- -- Q6: strongest barrel-aged beer

create or replace view BeersAgedBarrel
as
select	b.id, b.abv, b.name
from	Beers b
where	b.notes like '%barrel%aged%' or b.notes like '%aged%barrel%'
order by	b.id
;

create or replace view BeersAgedBarrelWithBreweries(beer,brewery,abv)
as
select	b.name, br.name, b.abv
from	BeersAgedBarrel b 
join 	Brewed_By bby on b.id = bby.beer
join	Breweries br on bby.brewery = br.id
order by	b.name
;

create or replace view HighestABV
as
select MAX(abv)
from BeersAgedBarrelWithBreweries
;

create or replace view Q6(beer,brewery,abv)
as
select	b.beer, b.brewery, b.abv
from	BeersAgedBarrelWithBreweries b join HighestABV
on		HighestABV.max = b.abv
;

-- Q7: most popular hop

create or replace view HopFrequency
as
select	name, count(*)
from	Contains join Ingredients
on		Contains.ingredient = Ingredients.id
where	Ingredients.itype = 'hop'
group by 	name
order by	count(*)
;

create or replace view max_Q7
as
select	MAX(count)
from	HopFrequency
;

create or replace view Q7(hop)
as
select	f.name
from	HopFrequency f join max_Q7
on		max_Q7.max = f.count
;

-- Q8: breweries that don't make IPA or Lager or Stout (any variation thereof)
-- Find all that make IPA or Lager or Stout
-- then complement those from all brewerires

-- This is a helper view that contains the ids and names of all beers brewed by a brewery
create or replace view infos
as
select 	s.id as style_id, s.name as style_name, 
		b.id as beer_id, b.name as beer_name, 
		r.id as brewery_id, r.name as brewery_name 
from 	Styles s 
join 	Beers b on b.style = s.id 
join 	Brewed_by bby on bby.beer = b.id 
join 	Breweries r on r.id=bby.brewery 
order by r.id
;

create or replace view BreweriesMakingCommonBeers
as
select	br.name
from	Styles s
join	Beers b on s.id = b.style
join	Brewed_By bby on b.id = bby.beer
join	Breweries br on bby.brewery = br.id
where	s.name like '%IPA%' or s.name like '%Lager%' or s.name like '%Stout%'
group by 	br.name
order by 	br.name
;

create or replace view Q8(brewery)
as
select	br.name
from	Breweries br
except
select	BreweriesMakingCommonBeers.name
from	BreweriesMakingCommonBeers
;

-- Q9: most commonly used grain in Hazy IPAs

-- view that contains all beers in Hazy IPA style
create or replace view HIBeers
as
select	b.name, b.id
from	Beers b
join	Styles s on b.style = s.id
where	s.name = 'Hazy IPA'
;

-- view that contains all ingredients used in making Hazy IPA styled beers
create or replace view IngsHI
as
select	ing.name, count(*)
from	HIBeers as b
join	Contains c on c.beer = b.id
join	Ingredients ing on ing.id = c.ingredient
where	ing.itype = 'grain'
group by ing.name
;

create or replace view Q9(grain)
as
select	ing.name
from	IngsHI ing
where	ing.count = (select max(count) from IngsHI)
;

-- Q10: ingredients not used in any beer
-- find all ing used by something
-- then complement

create or replace view IngsUsed
as
select	ing.name
from	Ingredients ing
join	Contains c on c.ingredient = ing.id
join	Beers b on b.id = c.beer
group by ing.name
;

create or replace view Q10(unused)
as
select	ing.name
from	Ingredients ing
except
select 	*
from 	IngsUsed
;

-- Q11: min/max abv for a given country

drop type if exists ABVrange cascade;
create type ABVrange as (minABV float, maxABV float);

create or replace function
	Q11(_country text) returns ABVrange
as $$
declare
	range		ABVrange;
	min_abv		float;
	max_abv		float;
begin
	select 	min(b.abv), max(b.abv) into min_abv, max_abv
	from	Beers b
	join	Brewed_By bby on bby.beer = b.id
	join	Breweries br on br.id = bby.brewery
	join	Locations l on l.id = br.located_in
	where	l.country = _country;
	if (min_abv is null) or (max_abv is null) then
		min_abv = 0;
		max_abv = 0;
	end if;
	select min_abv, max_abv into range;
	return range;
end;
$$
language plpgsql;

-- Q12: details of beers
-- Include: beer_name, brewer_name, ingredients_of_beer

drop type if exists BeerData cascade;
create type BeerData as (beer text, brewer text, info text);

create or replace view BeerAndBrewer
as
select	b.name as beer, b.id as bid, br.name as brewer
from	Beers b
join	Brewed_By bby on b.id = bby.beer
join	Breweries br on br.id = bby.brewery
;


create or replace view BeerAndIng
as
select	b.name as beer, b.id as bid, i.name as ingredient, i.itype as type
from	Beers b
join	Contains c on b.id = c.beer
join	Ingredients i on i.id = c.ingredient
order by    b.id, i.itype
;

create or replace function
    BeerIngredients() returns table (beer text, ingredients text, id integer)
as $$
declare
    r       record;
    outp    text    := '';
    curbeer text    := '';
    curbid  integer := -1;
    curtype text    := '';
    nocomma boolean := false;
begin
    for r in select * from BeerAndIng order by bid, type, ingredient
    loop
        -- if r.bid = 360 then
        --     raise notice 'Current ing: % and itype: %' , r.ingredient, r.type;
        -- end if;
        -- if id not equal, then reset identifier
        if (r.bid <> curbid) then
            -- if not default value, then return and reset current infos
            if (curbid <> -1) then
                beer := curbeer;
                ingredients := outp;
                curtype     := '';
                return next;
                outp := '';
            end if;
            curbid := r.bid;
            curbeer := r.beer;
            id := r.bid;
        end if;
        -- if type not equal, then add a new header
        if (curtype <> r.type::text) then
            if (curtype <> '') then
                outp := outp || E'\n';
            end if;
            if (r.type = 'adjunct') then
                outp := outp || 'Extras: ';
            elsif (r.type = 'hop') then
                outp := outp || 'Hops: ';
            else
                outp := outp || 'Grain: ';
            end if;
            curtype := r.type;
            nocomma := true;
        end if;
        -- append current ingredient
        if nocomma then
            outp := outp || r.ingredient;
            nocomma := false;
        else
            outp := outp || ',' || r.ingredient;
        end if;
    end loop;
    beer := curbeer;
    ingredients := outp;
    id := r.bid;
    return next;
end;
$$ language plpgsql;


create or replace function
    BeerBrewers() returns table (beer text, brewers text, id integer)
as $$
declare
    r       record;
    outp    text    := '';
    curbeer text    := '';
    curbid  integer := -1;
begin
    for r in select * from BeerAndBrewer order by bid
    loop
        -- if id not equal, then reset identifier
        if (r.bid <> curbid) then
            -- if not default value, then return and reset current brewers
            if (curbid <> -1) then
                beer := curbeer;
                brewers := outp;
                id := curbid;
                return next;
                outp := '';
            end if;
            curbid := r.bid;
            curbeer := r.beer;
            outp := outp || r.brewer;
        else
            outp := outp || ' + ' || r.brewer;
        end if;
    end loop;
    beer := curbeer;
    brewers := outp;
    id := curbid;
    return next;
end;
$$ language plpgsql;

create or replace view IntegratedBeersJoinBrewersAndIngredients
as
select          bb.beer as beer, bb.brewers as brewers, 
                bi.ingredients as infos, bb.id as beer_id
from            BeerBrewers() bb 
full outer join BeerIngredients() bi on bb.id = bi.id
group by        bb.beer, bb.brewers, bi.ingredients, bb.id
order by        bb.id
;

create or replace function
	Q12(partial_name text) returns setof BeerData
as $$
declare
    r       record;
    data    BeerData;
    partial text;
begin
    partial := '%' || partial_name || '%';
    for r in select * from IntegratedBeersJoinBrewersAndIngredients v
    loop
        if r.beer ilike partial then
            select r.beer, r.brewers, r.infos into data;
            return next data;
        end if;
    end loop;
end;
$$
language plpgsql;
