# Changelog

## v0.2.1 May ?? 2017

### Features:
* Add brandId and allow_reassign options to DocusignRest::Client#create_envelope_from_template and DocusignRest::Client#create_envelope_from_composite_template (Jayan Jacob)
* Implement DocusignRest::Client#add_envelope_certified_deliveries (Moses Dwaram)
* Add envelopeIds option to DocusignRest::Client#get_envelope_statuses (Amit Chakradeo)
* Add recipientEvents option to event notification payload (Guillermo Wu)
* Added logging of each call to support Docusign API certification (Jon Witucki)
* Enable requireSignOnPaper option for a recipient in a composite template (Tom Copeland)
* Support routingOrder option when generating signers (Guillaume Dott)
* Support arbitrary parameters to DocusignRest::Client#get_combined_document_from_envelope (Coley Brown)
* Support event notifications in DocusignRest::Client#get_combined_document_from_envelope (Maxime Orefice)
* Support wet_sign option on DocusignRest::Client#create_envelope_from_document (Sergio Cambra)
* Support signHereTabs on DocusignRest::Client#get_inline_signers (Chris Sturm)
* Support additional tab options (Hoang Le)

### Misc:
* Replace monkeypatch with argument usage (Jean-Philippe Moal)
* Bumped minimum Ruby version to 2.1.0. (Tom Copeland)
* DocusignRest::Client#void_envelope now returns a JSON object rather than a request object (Tom Copeland)

## v0.2.0 April 28 2017

### Features:
* Implement DocusignRest::Client#get_sender_view (Gonzalo Rodríguez)
* Implement DocusignRest::Client#add_envelope_signers (Dan Rench)
* Implement DocusignRest::Client#get_folder_list (Matthew Santeler)
* Implement DocusignRest::Client#get_composite_template (lbspen)
* Implement DocusignRest::Client#create_envelope_from_composite_template (lbspen, Ariel Fox)
* Implement DocusignRest::Client#get_templates_in_envelope (lbspen)
* Implement DocusignRest::Client#get_combined_document_from_envelope (Patrick Logan)
* Implement DocusignRest::Client#get_envelope_audit_events (Sean Woojin Kim)
* Implement DocusignRest::Client#void_envelope (Mike Pence)
* Implement DocusignRest::Client#delete_envelope_recipient (Mike Pence)
* DocusignRest::Client#get_template_roles now supports numberTabs (Mike Pence)
* DocusignRest::Client#get_tabs now supports the "selected" and "optional" options (Shane Stanford, Greg)
* DocusignRest::Client#get_token now requires an integrationKey argument (Joe Heth)
* Added support for adding/removing envelope documents (Andrew Porterfield)
* Added support for adding recipient tabs (Andrew Porterfield)
* DocusignRest::Client#create_envelope_from_document now supports a customFields options (Jon Witucki)
* DocusignRest::Client#create_envelope_from_template now supports a customFields option (Tyler Green)
* DocusignRest::Client#get_signer_tabs now supports locking tabs (Chris Antaki)
* DocusignRest::Client#get_inline_signers now supports a client id as well as email address (Patrick Logan)

### Bug fixes:
* A tab's scaleValue can now be set (Jon Witucki)
* tab height is no longer improperly set to tab width (mesbahmilad)
* DocusignRest::Client#get_account_id no longer always returns nil (Mark Wilson)

### Misc:
* More Rubyish variable naming (Chris Doyle)
* Whitespace cleanup and unnecessary local variable removal (Jon Witucki)
* Updated setup instructions (entrision)
* Fixed header syntax in code example (Paulo Abreu)
