# Concepts

Every dante-wiki page may have a publicity status. The status valid for a page is given
by the status of the most recent (highest revision number) of that page.

This status may comprise
* A mandatory publicity status. Currently the only possible value is "public".
* An optional array of topic names. The array may be empty. This may be used for making it easier to organize articles into groups (channels, journals, lectures) and to find them.
* An optional revision identifier. The identifier tells us, which versions of the page are public. Possible values are:
** last
** 1324  ( a specific revision number )
** 1324+ ( a specific revision number and all later revisions of that page )




# Dante-Wiki Interface

### Ideas:

* We might publish by placing the template {{public}} on to the page. This would correspond to the Wiki philosophy, make it
part of the article (no need for separate DB), allow a reconstruction of the properties in a parse, easily allow different
publication status in different versions, allow use in https://www.mediawiki.org/wiki/Manual:Page_props_table 
allow easy generation of info as part of the page itself and much more.

* Problem: How would we de-publish a page then? Would we have to remove all the {{public}} tags in ALL old versions? 
* Problem: How would we de-publish information which had been mistakenly published? And already distributed? 

### Issues:

* Internal links to material which is not (yet) public.
* Internal links to material which is public, but is changed.
* Use of different Parsifal templates
* Transcluded templates which are not published, name inconsistencies
* Substituted templates, as in: https://en.wikipedia.org/wiki/Wikipedia:Substitution
* Transcluded sections which are not published, name inconsistencies
* are there substituted sections as well?
* What about the history? Is it also exported / visible? What is shown in the import side?
* Used media files?

### Permissions:

* How would we restrict publication? 

Idea: Relevant for publication always is the current version!
* {{publish|lecture-RN}} publishes to channel lecture-RN.
* {{publish|lecture-RN|103347}} published to channel lecture-RN, using the version 103347 only
* {{publish|lecture-RN|103347+}} published to channel lecture-RN, using the version 103347 or any later version

It is not "publish" but "public". We explain the status and not the activity. 

### Verb versus Status:

Is it really a verb (we actively publish and then distribute it) or is it a status (it is public, so it may, at every time, be pulled / imported,
and there might be a pub-sub service for the change events in the status. Which might include depublishing.)



### Must have


### Might have

* Has the document been read by subscribers, and when, and how often.



## Use Case

### Use Case 1: Presenting (Lecture)

Publish: To a channel identifier.
Subscribe: To a channel identifier.

### Use Case 2: Publishing (Journal)


### USe case 3: Exchanging and Reviewing (Ideas, Collaboration and Preprints)



## Selection of System



## Selection of Implementation

### Requirements:

* Client and Broker
* Open Source
* Active Development
* Linux compatible
* Light weight
* Supports also large (20 MB) size messages
* Supports SSL and authentication


* NanoMQ
* LV-MQTT
* Mongoose
* Mosquitto (looks like the best choice)
* mqttools

