

In some use cases we want to filter or hide contents.


Examples
* Solutions to exercises
* Didactical remarks which are only intended for the docent
* Remarks not meant for publication


Aspects to consider when implementing such mechanisms:

* A user can have a look at "view source" of HTML and there see portions which are not rendered.
* A user can have a look at the wiki source view and there see markup 

One idea was to hide parts when producing a backup.

The problem here is that the XML Backup is structured in such a way that the text is not conforming to XML rules.
We would have to analyse the text by a mediawiki parser. Thus, it is easier to do this in the context of other forms
of mechanisms.














