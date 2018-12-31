#!/bin/bash

# header guard
[ -n "$_SQLITE_HIST" ] && return || readonly _SQLITE_HIST=1

HISTDB="$HOME/.history.db"
HISTSESSION=`dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64`

__quote_str() {
	local str
	local quoted
	str="$1"
	quoted="'$(echo "$str" | sed -e "s/'/''/g")'"
	echo "$quoted"
}
__create_histdb() {
	if bash -c "set -o noclobber; > \"$HISTDB\" ;" &> /dev/null; then
		sqlite3 "$HISTDB" <<-EOD
		CREATE TABLE command (
			command_id INTEGER PRIMARY KEY,
			shell TEXT,
			command TEXT,
			cwd TEXT,
			return INTEGER,
			started INTEGER,
			ended INTEGER,
			shellsession TEXT,
			loginsession TEXT
		);
		EOD
	fi
}

preexec() {
	[[ ! -v HISTDB ]] && return 0
	local cmd
	cmd="$1"

	#atomic create file if not exist
	__create_histdb
	
	local quotedloginsession
	if [[ -v LOGINSESSION ]]; then
		quotedloginsession=$(__quote_str "$LOGINSESSION")
	else
		quotedloginsession="NULL"
	fi
	LASTHISTID="$(sqlite3 "$HISTDB" <<-EOD
		INSERT INTO command (shell, command, cwd, started, shellsession, loginsession)
		VALUES (
			'bash',
			$(__quote_str "$cmd"),
			$(__quote_str "$PWD"),
			$(date +%s%3),
			$(__quote_str "$HISTSESSION"),
			$quotedloginsession
		);
		SELECT last_insert_rowid();
		EOD
	)"

	#echo "$cmd" >> ~/.testlog
}

precmd() {
	local ret_value="$?"
	if [[ -v LASTHISTID ]]; then
		__create_histdb
		sqlite3 "$HISTDB" <<- EOD
			UPDATE command SET
				ended=$(date +%s%3),
				return=$ret_value
			WHERE
				command_id=$LASTHISTID ;
		EOD
	fi
}