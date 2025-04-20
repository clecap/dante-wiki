

# Scenario 1: Backend and Frontend Wiki 

This scenario consists of two DanteWikis under the control of one author or a small group of authors.

Backend Wiki: Here the material is prepared and it may be in a draft or beta state.

Frontend Wiki: Here the material is presented to a wider audience.

The article names, namespaces, templates etc. usually are identical on the two wikis.


## Use Case 1: Pushing

A user registered in the backend presses "copy " and the respective article is marked as public.

If the frontend wiki is online at the moment of publishing, the article is immediatley copied to the frontend wiki.

If the fontend wiki is not online at the moment of publishing, there is a mechanism which ensures that the article
will eventually be copied.

The backend article will display if it has been copied successfully.

If the backend article receives further edits, no automatic publishing takes place - it will need a
further user activity. However, the backend article will indicate that the frontend article is not up to date.

In addition to a single article, also an entire category can be published.


## Use Case 2: Synchronization








