#!/bin/bash
# 
# clone or download each extension, and build
set -eux

MW_DIR="${POD_CHARLESREID1_DIR}/d-mediawiki"
MW_CONF_DIR="${MW_DIR}/charlesreid1-config/mediawiki"
EXT_DIR="${MW_CONF_DIR}/extensions"

mkdir -p ${EXT_DIR}

(
cd ${EXT_DIR}

##############################

Extension="SyntaxHighlight_GeSHi"
if [ ! -d ${Extension} ]
then
    ## This requires mediawiki > 1.31
    ## (so does REL1_31)
    #git clone https://github.com/wikimedia/mediawiki-extensions-SyntaxHighlight_GeSHi.git SyntaxHighlight_GeSHi

    ## This manually downloads REL1_30
    #wget https://extdist.wmflabs.org/dist/extensions/SyntaxHighlight_GeSHi-REL1_30-87392f1.tar.gz -O SyntaxHighlight_GeSHi.tar.gz
    #tar -xzf SyntaxHighlight_GeSHi.tar.gz -C ${PWD}
    #rm -f SyntaxHighlight_GeSHi.tar.gz

    # Best of both worlds
    git clone https://github.com/wikimedia/mediawiki-extensions-SyntaxHighlight_GeSHi.git SyntaxHighlight_GeSHi
    (
    cd ${Extension}
    git checkout --track remotes/origin/REL1_34
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
    git checkout --track remotes/origin/REL1_34
    )
else
    echo "Skipping ${Extension}"
fi

##############################

Extension="EmbedVideo"
if [ ! -d ${Extension} ]
then
    git clone https://github.com/HydraWiki/mediawiki-embedvideo.git ${Extension}
    (
    cd ${Extension}
    git checkout v2.7.3
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
    git checkout REL1_34
    )
else
    echo "Skipping ${Extension}"
fi

##############################

Extension="Fail2banlog"
if [ ! -d ${Extension} ]
then
    git clone https://github.com/charlesreid1-docker/mw-fail2ban.git ${Extension}
    (
    cd ${Extension}
    git checkout master
    )
else
    echo "Skipping ${Extension}"
fi

##############################

# fin
)
