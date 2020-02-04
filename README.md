[ja](./README.ja.md)

# push

Push to GitHub with current directory as repository.

# Features

* CLI (bash script)
* Create Repository
    * git commands (`init`, `config`, `remote add`, `status`, `add`, `commit`, `push`)
    * [github api](https://developer.github.com/v3/repos/)

# Requirement

* <time datetime="2020-01-26T12:18:40+0900">2020-01-26</time>
* [Raspbierry Pi](https://ja.wikipedia.org/wiki/Raspberry_Pi) 4 Model B Rev 1.2
* [Raspbian](https://ja.wikipedia.org/wiki/Raspbian) buster 10.0 2019-09-26 <small>[setup](http://ytyaru.hatenablog.com/entry/2019/12/25/222222)</small>
* bash 5.0.3(1)-release

```sh
$ uname -a
Linux raspberrypi 4.19.75-v7l+ #1270 SMP Tue Sep 24 18:51:41 BST 2019 armv7l GNU/Linux
```

# Installation

```sh
git clone https://github.com/ytyaru/push
ln -s ./push.sh /usr/bin/push
```

# Usage

## Show help

[help](res/help.txt)

```sh
cd push/src
push -h
```

<details><summary>help</summary>
```sh
Push to GitHub with current directory as repository.
Usage: push.sh [options...]
Options:
  -u USERNAME
  -m COMMIT_MESSAGE
  -h HOMEPAGE
  -t TOPICS
Setting files:
  TokensTsv: ./res/tokens.tsv
    line-format: Username\tToken\tNote(ScopesCsv)
  EmailsTsv: ./res/emails.tsv
    line-format: Username\tEMail
  Setting file: ./res/setting.sh
    examples: 
      PATH_TSV_TOKENS=./tokens.tsv
      PATH_TSV_EMAILS=./emails.tsv
  Source code: ./src/push/push.sh
Examples:
  push.sh
  push.sh -u YourUsername
  push.sh -u YourUsername -m CommitMessage -h HomePage -t topic1 -t topic2 -t topic3
```
</details>

The `-h` option can also be used to display help. The `-h` option is for homepage setting, but an error will occur if the value is not set. Display help in case of error. As a result, help is displayed with `-h`.

## Batch

```sh
push -u USER -m COMMIT_MSG -h HOMEPAGE -t topic1 -t topic2
```

All are optional. If no value is found, look for a default value. If it cannot be found, an error occurs and the processing is interrupted.

## Interactive

```sh
push
```

The username is obtained from `[user]name` in `./.git/config`. If not, prompt for input.

```sh
Please select a user.
1) user1
2) user2
3) user3
#? 
```

View your changes. When you enter a commit message, the git commands `init`,` add`, `commit`, and` push`.

```sh
 M README.md
--------------------
add 'README.md'
--------------------
Push when you enter a commit message. Press Enter key without any input to end.

```

If this is the first time, create a local repository with `git init`. It also creates a remote repository using the [GitHub API](https://developer.github.com/v3/repos/#create).

```sh
Created a repository
[master (root-commit) 1342344] Created a repository
 1 file changed, 4 insertions(+)
 create mode 100644 README.md
{
  "id": ?????????,
  ...
  "subscribers_count": 1
}
Enumerating objects: 3, done.
Counting objects: 100% (3/3), done.
Writing objects: 100% (3/3), 235 bytes | 117.00 KiB/s, done.
Total 3 (delta 0), reused 0 (delta 0)
To https://github.com/USERNAME/REPO_NAME.git
 * [new branch]      master -> master
```

If nothing has changed, exit without doing anything.

```sh
No change. Exit.
```

After the second time, if there is a change, `add`,` commit`, `push`.

```sh
 M README.md
--------------------
add 'README.md'
--------------------
Push when you enter a commit message. Press Enter key without any input to end.

```

## Setting

Enter your GitHub username, email address and token in each configuration file.

### [emails.tsv](res/emails.tsv)

```tsv
#username	email
user1	user1@mail.com
user2	user2@mail.com
user3	user2@mail.com
```

### [tokens.tsv](res/tokens.tsv)

```tsv
#username	token	note(ScopeCsv)
user1	user1token_all	all
user1	user1token_repo	repo
user1	user1token_repo_del	repo,delete_repo
user1	user1token_del_repo	repo_delete_repo,repo
user1	user1token_del_repo_gist	delete_repo,repo,gist
user1	user1token_user	user
user2	user2token_all	all
user3	user3token_repo	repo
```

# Note

## Errors

```sh
Repository name is invalid. Please follow the regular expression "^[-._ A-Za-z0-9]+$
```
```sh
Homepage is invalid. Follow the regular expression "(https?|ftp|file)://.*
```
```sh
Topics should be no longer than 35 characters.
```
```sh
Topics begin with a lowercase letter or number and can include hyphens. No other characters can be used.
```
```sh
Token of specified user \"$1\" does not exist in the configuration file.
```
```sh
Cannot find target user. Add the information of GitHub user who has Email and Token to the configuration file.
```
```sh
Could not select user. Exit.
```
```sh
EMail of specified user \"$USERNAME\" does not exist in the configuration file.
```
```sh
Token of specified user \"$USERNAME\" does not exist in the configuration file.
```
```sh
README.md does not exist in the current directory. Please create.
```
```sh
No description was found.
The description is obtained from the README.md file.
The second line from the first heading (the line starting with #) is regarded as the description.
```

# Note

* How to update to the latest code with `git pull` while keeping account information locally
    * include `res/setting/setting.sh` in` .gitignore`
    * The contents of `res/setting/setting.sh` must specify a path outside the repository

# Author

ytyaru

* [![github](http://www.google.com/s2/favicons?domain=github.com)](https://github.com/ytyaru "github")
* [![hatena](http://www.google.com/s2/favicons?domain=www.hatena.ne.jp)](http://ytyaru.hatenablog.com/ytyaru "hatena")
* [![mastodon](http://www.google.com/s2/favicons?domain=mstdn.jp)](https://mstdn.jp/web/accounts/233143 "mastdon")

# License

This software is CC0 licensed.

[![CC0](http://i.creativecommons.org/p/zero/1.0/88x31.png "CC0")](http://creativecommons.org/publicdomain/zero/1.0/deed.en)

