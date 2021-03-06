#!/bin/bash
WORKINGCOPY=/usr/src/cvs/eclipse-workspace/Freenet\ 0.7
echo -n "Please enter revision number after patch applied? "
read REVISION
OLDREVISION=$(($REVISION-1))
echo -n "Please enter location of patch from mailing list? "
read FILENAME
if [[ -z $FILENAME ]] ; then FILENAME=/home/toad/${REVISION}.diff; fi
echo Filename: "$FILENAME"
echo -n "Please enter sed script?"
read SEDSCRIPT
echo -n "Please enter rename script?"
read RENAMESCRIPT
# Make a temporary directory
TEMPDIR=`mktemp -d ~/verify-patch-temp-XXXXXXXXXX`
echo Temporary directory: $TEMPDIR
OLDDIR=${TEMPDIR}/old
NEWDIR=${TEMPDIR}/new
mkdir $OLDDIR $NEWDIR
echo "Old dir: $OLDDIR"
echo "New dir: $NEWDIR"
cp -a "$WORKINGCOPY" $OLDDIR/
cd $OLDDIR
DNAME=`ls`
echo DNAME = "$DNAME"
cd "${OLDDIR}/${DNAME}"
ant distclean
svn revert -R .
svn update -r $OLDREVISION
cd "$OLDDIR"
mv "$DNAME" freenet
cd freenet
mv src/plugins ..
cd ../plugins
ant distclean
svn revert -R .
svn update -r $OLDREVISION
cd ..
find -iname .svn | xargs rm -R
rm -R .[a-z0-9]*
cp -a $OLDDIR/* $NEWDIR
if [[ -n $SEDSCRIPT ]]; then
	cd $OLDDIR
	find . -type f -iname "*.java" | (while read x; do cat "$x" | sed "$SEDSCRIPT" > "$x.1"; mv "$x.1" "$x"; done)
fi
if [[ -n $RENAMESCRIPT ]]; then
	find "$OLDDIR" -type d | (while read x; do cd "$x"; rename "$SEDSCRIPT" *; done)
fi
cd "$NEWDIR"
if ! patch -p1 < $FILENAME ; then exit Failed to apply patch ; else echo Applied patch successfully. ; fi
diff -Nurw "$OLDDIR" "$NEWDIR" > $TEMPDIR/diff-uw
if [ -s $TEMPDIR/diff-uw ] ; then less $TEMPDIR/diff-uw ; else echo No differences found after compensating for whitespace; fi
rm -R $TEMPDIR
