#!/bin/bash
GetTokens() { # $1:username, $2...:has_must_scopes
	GetUsers() { cat "$PATH_TSV_TOKENS" | grep $1; }
	GetUsername() { echo "$1" | cut -f1; }
	GetToken() { echo "$1" | cut -f2; }
	GetScopeCsv() { echo "$1" | cut -f3; }
	HasAllScope() { # $1: scope_csv
		local scopes=( $(echo "$scopes" | tr ',' '\n') )
		[ 'all' = "${scopes[0]}" ] && return 0 || return 1
	}
	HasScope() { # $1: scope_csv, $2...: has_must_scopes
		GetParentScope() { # $1: ChildScope
			#child	parent
			local ChildrenScopes="$(cat <<-EOS
				repo:status	repo
				repo_deployment	repo
				public_repo	repo
				repo:invite	repo
				read:user	user
				user:email	user
				user:follow	user
				write:org	admin:org
				read:org	admin:org
				write:public_key	admin:public_key
				read:public_key	admin:public_key
				write:repo_hook	admin:repo_hook
				read:repo_hook	admin:repo_hook
				read:discussion	write:discussion
				manage_billing:enterprise	admin:enterprise
				read:enterprise	admin:enterprise
				write:gpg_key	admin:gpg_key
				read:gpg_key	admin:gpg_key
			EOS
			)"
			local line="$(echo -e "$ChildrenScopes" | cut -f1 | grep $1)"
			[ -n "$line" ] && { echo "$line" | cut -f2; } 
		}
		local args=($@)
		local scopes=${args[0]}
		local scopes=( $(echo "$scopes" | tr ',' '\n') )
		local has_must_scopes=("${args[@]:1:${#args[@]}}")
		[ 'all' = "${scopes[0]}" ] && return 0;
		for must in "${has_must_scopes[@]}"; do
			local is_exist=0
			local must_parent="$(GetParentScope "$must")"
			for scope in ${scopes[@]}; do
				[ "$must" = "$scope" ] && { is_exist=1; break; }
				[ -n "$must_parent" ] && [ "$must_parent" = "$scope" ] && { is_exist=1; break; }
			done
			[ 0 -eq $is_exist ] && { return 1; }
		done
		return 0
	}
	local has_all_scope_token=
	tokens=()
	args=($@)
	[ $# -lt 1 ] && { Throw '引数不足。\$1:username, \$2...:has_must_scopes'; }
	local username="${args[0]}"
	local has_must_scopes="${args[@]:1:${#args[@]}}"
	echo -e "$(GetUsers "$username")" | ( while read line; do
		local token="$(GetToken "$line")"
		HasAllScope && { has_all_scope_token="$token"; continue; }
		HasScope "$(GetScopeCsv "$line")" "${has_must_scopes[@]}" && tokens+=( "$token" )
	done; tokens+=( $has_all_scope_token ); echo -e "$(IFS=$'\n'; echo -e "${tokens[*]}";)" )
}
GetToken() { GetTokens "$@" | head -n 1; }

