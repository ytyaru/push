[en](./README.md)

# push

　現在のディレクトリをリポジトリとしてGitHubにプッシュする。

# 特徴

* CLI (bash script)
* リポジトリ新規生成
    * git commands (`init`, `config`, `remote add`, `status`, `add`, `commit`, `push`)
    * [github api](https://developer.github.com/v3/repos/)

# 開発環境

* <time datetime="2020-01-26T12:18:40+0900">2020-01-26</time>
* [Raspbierry Pi](https://ja.wikipedia.org/wiki/Raspberry_Pi) 4 Model B Rev 1.2
* [Raspbian](https://ja.wikipedia.org/wiki/Raspbian) buster 10.0 2019-09-26 <small>[setup](http://ytyaru.hatenablog.com/entry/2019/12/25/222222)</small>
* bash 5.0.3(1)-release

```sh
$ uname -a
Linux raspberrypi 4.19.75-v7l+ #1270 SMP Tue Sep 24 18:51:41 BST 2019 armv7l GNU/Linux
```

# インストール

```sh
git clone https://github.com/ytyaru/push
ln -s ./lish.sh /usr/bin/lish
```

# 使い方

## ヘルプ表示

[help](res/help.txt)

```sh
cd push/src
push -h
```

<details><summary>help</summary>
```sh
Push to GitHub with current directory as repository.
Usage: push [options...]
Options:
  -u USERNAME
  -m COMMIT_MESSAGE
  -h HOMEPAGE
  -t TOPICS
Setting:
  Work flow:
    1. Create a GitHub account    https://github.com/
    2. Create AccessToken         https://github.com/settings/tokens
    3. Create setting-file
  Setting-file: ./res/setting/setting.sh
    examples: 
      PATH_TSV_TOKENS=./tokens.tsv
      PATH_TSV_EMAILS=./emails.tsv
    Source code: $THIS
  tokens.tsv: ./res/setting/tokens.sh
    line-format: Username\\tToken\\tNote(ScopesCsv)
  emails.tsv:./res/setting/emails.sh
    line-format: Username\\tEMail
Examples:
  push
  push -u YourUsername
  push -u YourUsername -m CommitMessage -h HomePage -t topic1 -t topic2 -t topic3
```

　`-h`オプションはヘルプの表示にも使える。`-h`オプションはホームページ設定用だが、値が設定されていないと引数エラーが発生する。引数エラーが発生した場合、ヘルプを表示する。結果、ヘルプは`-h`で表示される。

</details>

## バッチ処理

```sh
push -u USER -m COMMIT_MSG -h HOMEPAGE -t topic1 -t topic2
```

　すべてオプション。 値が見つからない場合はデフォルト値を探す。それも見つからない場合はエラーとなり処理が中断される。

## 対話モード

```sh
push
```

　ユーザー名は`./.git/config`の`[user]name`から取得する。存在しない場合は次のように入力を求めます。

```sh
Please select a user.
1) user1
2) user2
3) user3
#? 
```

　変更を表示する。 コミットメッセージを入力すると、gitコマンドの`init`,` add`, `commit`, and` push`が実行される。

```sh
 M README.md
--------------------
add 'README.md'
--------------------
Push when you enter a commit message. Press Enter key without any input to end.

```

　初回時、`git init`でローカルリポジトリを作成します。 また、[GitHub API](https://developer.github.com/v3/repos/#create)を使用してリモートリポジトリを作成します。

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
無効なリポジトリ名です。カレントディレクトリ名は次の正規表現に従ってください。: ^[-._ A-Za-z0-9]+$
```
```sh
無効なホームページURLです。次の正規表現に従ってください: (https?|ftp|file)://.*
```
```sh
トピックスは35文字以内であるべきです。
```
```sh
トピックスは小文字または数字で始まり、ハイフンを含めることができます。他の文字は使用できません。
```
```sh
指定ユーザ\"$USERNAME\"はtoken.tsvファイルに存在しません。
```
```sh
対象ユーザが見つかりません。
設定ファイルにEmailとTokenを持ったGitHubユーザの情報を追加してください。
```
```sh
ユーザを選択できませんでした。終了します。
```
```sh
指定ユーザ\"$USERNAME\"のEMailは設定ファイルに存在しません。
```
```sh
指定ユーザ\"$USERNAME\"のTokenは設定ファイルに存在しません。
```
```sh
カレントディレクトリに README.md が存在しません。作成してください。
```
```sh
説明文が見つかりませんでした。
説明文はREADME.mdファイルから取得します。
最初の見出し(#で始まる行)から2行目を説明文とみなします。
```

# Note

* アカウント情報をローカルで保持したまま`git pull`で最新コードに更新する方法
    * `.gitignore`に`res/setting/setting.sh`を含むこと
    * `res/setting/setting.sh`の内容はリポジトリ外のパスを指定すること

# Author

ytyaru

* [![github](http://www.google.com/s2/favicons?domain=github.com)](https://github.com/ytyaru "github")
* [![hatena](http://www.google.com/s2/favicons?domain=www.hatena.ne.jp)](http://ytyaru.hatenablog.com/ytyaru "hatena")
* [![mastodon](http://www.google.com/s2/favicons?domain=mstdn.jp)](https://mstdn.jp/web/accounts/233143 "mastdon")

# License

This software is CC0 licensed.

[![CC0](http://i.creativecommons.org/p/zero/1.0/88x31.png "CC0")](http://creativecommons.org/publicdomain/zero/1.0/deed.en)

