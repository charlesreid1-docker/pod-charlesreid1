#!/bin/bash
#
# Clone each REL1_39 extension into d-mediawiki-new for the MW 1.39 green stack.
# EmbedVideo is intentionally skipped for now (add back later if needed).
set -eux

MW_DIR="${POD_CHARLESREID1_DIR}/d-mediawiki-new"
MW_CONF_DIR="${MW_DIR}/charlesreid1-config/mediawiki"
EXT_DIR="${MW_CONF_DIR}/extensions"

mkdir -p ${EXT_DIR}

(
cd ${EXT_DIR}

##############################

Extension="SyntaxHighlight_GeSHi"
if [ ! -d ${Extension} ]
then
    git clone https://github.com/wikimedia/mediawiki-extensions-SyntaxHighlight_GeSHi.git ${Extension}
    (
    cd ${Extension}
    git checkout --track remotes/origin/REL1_39
    )
else
    echo "Skipping ${Extension}"
fi

##############################

Extension="ParserFunctions"
if [ ! -d ${Extension} ]
then
    git clone https://github.com/wikimedia/mediawiki-extensions-ParserFunctions.git ${Extension}
    (
    cd ${Extension}
    git checkout --track remotes/origin/REL1_39
    )
else
    echo "Skipping ${Extension}"
fi

##############################

Extension="Math"
if [ ! -d ${Extension} ]
then
    git clone https://github.com/wikimedia/mediawiki-extensions-Math.git ${Extension}
    (
    cd ${Extension}
    git checkout --track remotes/origin/REL1_39
    )
else
    echo "Skipping ${Extension}"
fi

##############################

# fin
)
