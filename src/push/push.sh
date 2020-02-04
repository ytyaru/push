#!/bin/bash
Run() { # arguments: -u:username, -m:commit-message, -h:homepage -t:topics
	local THIS="$(realpath "${BASH_SOURCE:-$0}")"
	local HERE="$(cd "$(dirname "$THIS")"; pwd)"
	. "$HERE/lib/Error.sh"
	local PATH_DIR_RES="$(cd "$HERE"; cd '../../res'; pwd)"
	local PATH_DIR_SETTING="$PATH_DIR_RES/setting"
	local PATH_SH_SETTING="$PATH_DIR_SETTING/setting.sh"
	. "$PATH_SH_SETTING" # PATH_TSV_TOKENS, PATH_TSV_EMAILS
	[[ "$PATH_TSV_TOKENS" =~ ^\./.*$ ]] && PATH_TSV_TOKENS="$PATH_DIR_SETTING/${PATH_TSV_TOKENS:2:${#PATH_TSV_TOKENS}}"
	[[ "$PATH_TSV_EMAILS" =~ ^\./.*$ ]] && PATH_TSV_EMAILS="$PATH_DIR_SETTING/${PATH_TSV_EMAILS:2:${#PATH_TSV_EMAILS}}"
	local PATH_TXT_HELP="$PATH_DIR_RES/help/help.txt"
	DeleteCommentAndBlankLine() { grep -v -e '^\s*#' -e '^\s*$' "$1"; }
	TokensTsvUsers() { DeleteCommentAndBlankLine "$PATH_TSV_TOKENS" | grep "$1"; }
	TokensTsvUsernames() { DeleteCommentAndBlankLine "$PATH_TSV_TOKENS" | cut -f1 | sort | uniq; }
	EmailsTsvUsers() { DeleteCommentAndBlankLine "$PATH_TSV_EMAILS" | grep "$1"; }
	EmailsTsvUserMail() { echo -e "$(EmailsTsvUsers "$1")" | sort | uniq | head -n 1 | cut -f2; }
	UsersWithEmailAndToken() { echo -e "$(grep -x -f <(TokensTsvUsernames) <(cat "$PATH_TSV_EMAILS" | cut -f1))"; }
	ThisFileName() { echo "$(basename "$THIS")"; }
	GetArgs() {
		Help() { eval "cat <<< \"$(cat "$PATH_TXT_HELP")\""; exit 1; }
		local OPTIND OPT
		ARG_TOPICS=()
		while getopts ":u:m:h:t:" OPT; do
			case $OPT in
				u) ARG_USERNAME="$OPTARG";;
				m) ARG_COMMIT_MESSAGE="$OPTARG";;
				h) ARG_HOMEPAGE="$OPTARG";;
				t) ARG_TOPICS+=("$OPTARG");;
				\?) Help; exit 1;;
				*) Help; exit 1;;
			esac
		done
	}
	Validate() {
		IsValidRepoName() {
			# https://stackoverflow.com/questions/59081778/rules-for-special-characters-in-github-repository-name
			[[ ! "$REPO_NAME" =~ ^[-._A-Za-z0-9]+$ ]] && { Throw 'Repository name is invalid. Please follow the regular expression "^[-._ A-Za-z0-9]+$".'; }
		}
		IsValidHomepage() {
			IsUrl() { local regex='(https?|ftp|file)://.*'; [[ "$1" =~ $regex ]]; }
			IsUrl "$1" || { Throw 'Homepage is invalid. Follow the regular expression "(https?|ftp|file)://.*".'; }
		}
		IsValidTopics() {
			for topic in ${ARG_TOPICS[@]}; do
				[ 35 -lt ${#topic} ] && { Throw 'Topics should be no longer than 35 characters.'; }
				[[ ! "$topic" =~ ^[a-z0-9][-a-z0-9]*$ ]] && { Throw 'Topics begin with a lowercase letter or number and can include hyphens. No other characters can be used.'; }
			done
		}
		IsValidRepoName
		[ 0 -lt ${#ARG_TOPICS} ] && IsValidTopics
		[ -n "$ARG_HOMEPAGE" ] && IsValidHomepage "$ARG_HOMEPAGE"
	}
	Username() {
		IsExistTsv() {
			local tsvusers="$(TokensTsvUsers "$USERNAME")"
			[ -n "$tsvusers" ] || { Throw "Specified user \"$USERNAME\" does not exist in token.tsv file." 'Create it as described in the help.'; }
		}
		GetGitConfigUser() { git config --local user.name; }
		HasGitConfigUser() { GetGitConfigUser &> /dev/null; }
		HasGitConfigUser && { USERNAME="$(GetGitConfigUser)"; IsExistTsv; return; }
		[ -n "$ARG_USERNAME" ] && { USERNAME="$ARG_USERNAME"; IsExistTsv; return; }
	}
	SelectUser() {
		[ -n "$USERNAME" ] && { return; }
		local users="$(UsersWithEmailAndToken)"
		[ -z "$users" ] && Throw 'Cannot find target user.' 'Add the information of GitHub user who has Email and Token to the configuration file.'
		echo "Please select a user."
		select i in $(UsersWithEmailAndToken); do [ -n "$i" ] && { USERNAME="$i"; return; }; done;
		[ -n "$USERNAME" ] || { Throw 'Could not select user. Exit.'; }
	}
	Email() {
		IsExistTsv() {
			local tsvusers="$(EmailsTsvUsers "$USERNAME")"
			[ -n "$tsvusers" ] || { Throw "EMail of specified user \"$USERNAME\" does not exist in the configuration file." 'Follow the instructions in the help.'; }
		}
		IsExistTsv && { EMAIL="$(EmailsTsvUserMail "$USERNAME")"; return; }
	}
	Token() {
		. "$HERE/lib/get_tokens.sh"
		local tsvtoken="$(GetToken "$USERNAME" "public_repo")"
		[ -n "$tsvtoken" ] || { Throw "Token of specified user \"$USERNAME\" does not exist in the configuration file." 'Create it with the following procedure.'; }
		TOKEN="$tsvtoken"
	}
	GetReadMePath() { find . -type f -regextype posix-extended  -regex "./README(.*.md|.*.ad|.*.txt|.*.rst|.*.rdoc)?"; }
	SortLength() { echo -e "$1" | awk '{print length() ,$0}' | sort -n | cut -d' ' -f2; }
	GetPrimaryReadMePath() { echo "$(SortLength "$(GetReadMePath)" | head -n 1)"; }
	ExistReadMe() {
		[ -n "$(GetReadMePath)" ] || { Throw "README.md does not exist in the current directory. Please create.: ${REPO_PATH}"; }
	}
	GetDescription() {
		GetLine() { echo -e "$1" | head -n $2 | tail -n 1; }
		content="$(cat "$(GetPrimaryReadMePath)")"
		local line_no=0
		echo -e "$content" | ( while read line; do
			let line_no++
			[[ "$line" =~ ^#.* ]] && { echo "$(GetLine "$content" $((line_no + 2)))"; return; }
		done; Throw 'No description was found.' 'The description is obtained from the README.md file.' 'The second line from the first heading (the line starting with #) is regarded as the description.'; )
	}
	CreateRepository() {
		SetupGitGlobalUser() {
			# 「*** Please tell me who you are.」error measures
			[ -f "$HOME/.gitconfig" ] && return;
			git config --global user.name "$USERNAME"
			git config --global user.email "$EMAIL"
		}
		SetupGitLocalUser() {
			git config --local user.name "$USERNAME"
			git config --local user.email "$EMAIL"
		}
		SetCommitMessage() { [ -n "$ARG_COMMIT_MESSAGE" ] && COMMIT_MESSAGE="$ARG_COMMIT_MESSAGE" || COMMIT_MESSAGE='Created a repository'; }
		[ ! -d ".git" ] && {
			echo "Create a repository."
			git init
			SetCommitMessage
			SetupGitGlobalUser
			SetupGitLocalUser
			git remote add origin "https://${USERNAME}:${TOKEN}@github.com/${USERNAME}/${REPO_NAME}.git"
			IS_INIT=1
		}
	}
	CreateRemoteRepository() {
		local json='"name":"'"${REPO_NAME}"'","description":"'"${DESCRIPTION}"'"'
		[ -n "$ARG_HOMEPAGE" ] && json+=',"homepage":"'"$ARG_HOMEPAGE"'"'
		json='{'"$json"'}'
		echo "$json" | curl -u "${USERNAME}:${TOKEN}" https://api.github.com/user/repos -d @-
		ReplaceTopics
	}
	ReplaceTopics() {
		[ 0 -lt ${#ARG_TOPICS} ] && {
			local topics='['
			for topic in ${ARG_TOPICS[@]}; do { topics+='"'"$topic"'",'; } done;
			topics="${topics:0:-1}"; topics+=']'
			local json='{"names":'"$topics"'}'
			sleep 1
			echo "$json" | curl -XPUT -H "Accept: application/vnd.github.mercy-preview+json" -u "${USERNAME}:${TOKEN}" https://api.github.com/repos/${USERNAME}/${REPO_NAME}/topics -d @-
		}
	}
	CheckView() {
		Status() { git status -s; }
		AddN() { git add -n .; }
		IsInputShortcut() { [ -n "$ARG_COMMIT_MESSAGE" ]; }
		local status="$(Status)"
		local addn="$(AddN)"
		[ -n "$COMMIT_MESSAGE" ] || COMMIT_MESSAGE="$ARG_COMMIT_MESSAGE";
		[ -n "$status" ] && {
			echo "$status"
			echo "--------------------"
			echo "$addn"
			echo "--------------------"
			IsInputShortcut && { echo "$COMMIT_MESSAGE"; } || {
				echo 'Push when you enter a commit message. Press Enter key without any input to end.'
				read -e -i "$COMMIT_MESSAGE" COMMIT_MESSAGE
			}
		}
	}
	AddCommitPush() {
		Add() { git add .; }
		Commit() { git commit -m "$COMMIT_MESSAGE"; }
		Push() { git push origin master; }
		IsNotReposiotry() { [[ "$1" =~ ^fatal:[[:space:]]not[[:space:]]a[[:space:]]git[[:space:]]repository* ]]; }
		IsNotFoundRemoteRepository() { [[ "$res" =~ ^remote:[[:space:]]Repository[[:space:]]not[[:space:]]found. ]]; }
		[ -n "$COMMIT_MESSAGE" ] && {
			Add; Commit;
			local res="$(Push 2>&1)"
			IsNotReposiotry "$res" && { git init; CreateRemoteRepository; Push; return; }
			IsNotFoundRemoteRepository "$res" && { CreateRemoteRepository; Push; return; }
			echo -e "$res"
		} || { echo 'No change. Exit.'; }
	}
	GetArgs "$@"
	IS_INIT=0
	REPO_PATH=`pwd`
	REPO_NAME=$(basename $REPO_PATH)
	USERNAME=; EMAIL=; TOKEN=;
	Username; SelectUser; Email; Token;
	Validate
	echo "$USERNAME/$REPO_NAME"
#	echo "<$EMAIL> $TOKEN"
	ExistReadMe
	DESCRIPTION="$(GetDescription)"
	echo "$DESCRIPTION"
	CreateRepository
	CheckView
	AddCommitPush
	unset USERNAME EMAIL TOKEN DESCRIPTION REPO_PATH REPO_NAME
}
Run "$@"
