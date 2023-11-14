


ext.drawioeditor.js:

in line 52 remove the slash before ?embed in src: this.baseUrl + '?embed=1&proto=json&spin=1&analytics=0&picker=0&lang=' + this.language + localAttr,


# Do Due Diligence

Check whether you have done the following:
* Allow upload of files in the wiki configuration
* Allow upload of filetype svg in wiki configuration
* Check if the file shows up in image directory

# Fix ext.drawioeditor.js

In file ext.drawioeditor.js the error reporting is broken in function DrawioEditor.prototype.uploadToWiki. Therefore
the extension does not properly report errors and exceptions caused by the MediaWiki system.

# Fix includes/libs/ParamValidator/Util/UploadedFile.php

When the error reporting is fixed, one gets error which still exist MediaWiki.



Declaration of Wikimedia\ParamValidator\Util\UploadedFile::getStream() must be compatible with Psr\Http\Message\UploadedFileInterface::getStream(): 
Psr\Http\Message\StreamInterface in <b>/var/www/html/wiki-dir/includes/libs/ParamValidator/Util/UploadedFile.php</b> on line <b>86</b><br />

The function getStream() lacks the specification StreamInterface public function getStream(): StreamInterface;

wiki-dir/includes/libs/ParamValidator/Util/UploadedFile.php in line 86 needs the additional specification StreamInterface


Declaration of Wikimedia\\ParamValidator\\Util\\UploadedFile::moveTo($targetPath) must be compatible with Psr\\Http\\Message\\UploadedFileInterface::moveTo(string $targetPath): void in <b>/var/www/html/wiki-dir/includes/libs/ParamValidator/Util/UploadedFile.php</b> on line <b>96</b><br 



\UploadedFile::getSize() must be compatible with Psr\\Http\\Message\\UploadedFileInterface::getSize(): ?int in <b>/var/www/html/wiki-dir/includes/libs/ParamValidator/Util/UploadedFile.php</b> on line <b>121</b><br /


 Declaration of Wikimedia\\ParamValidator\\Util\\UploadedFile::getError() must be compatible with Psr\\Http\\Message\\UploadedFileInterface::getError(): int in <b>/var/www/html/wiki-dir/includes/libs/ParamValidator/Util/UploadedFile.php</b> on line <b>125</b><br /


Fatal error</b>:  Declaration of Wikimedia\\ParamValidator\\Util\\UploadedFile::getClientFilename() must be compatible with Psr\\Http\\Message\\UploadedFileInterface::getClientFilename(): ?string in <b>/var/www/html/wiki-dir/includes/libs/ParamValidator/Util/UploadedFile.php</b> on line <b>129</b><br 



Fatal error</b>:  Declaration of Wikimedia\\ParamValidator\\Util\\UploadedFile::getClientMediaType() must be compatible with Psr\\Http\\Message\\UploadedFileInterface::getClientMediaType(): ?string in <b>/var/www/html/wiki-dir/includes/libs/ParamValidator/Util/UploadedFile.php</b> on line <b>134</b><br /


Fatal error</b>:  Could not check compatibility between Wikimedia\\ParamValidator\\Util\\UploadedFile::getStream(): Wikimedia\\ParamValidator\\Util\\StreamInterface and Psr\\Http\\Message\\UploadedFileInterface::getStream(): Psr\\Http\\Message\\StreamInterface, because class Wikimedia\\ParamValidator\\Util\\StreamInterface is not available in <b>/var/www/html/wiki-dir/includes/libs/ParamValidator/Util/UploadedFile.php</b> on line <b>86</b><br /

add to header in UploadedFile.php
use Psr\Http\Message\StreamInterface;





Further Bug:

We need to do a reload after we return from the editor to the Wikipage.