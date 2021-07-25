esns
====
[エンジニアのためのSNS](https://qiita.com/HawkClaws/items/599d7666f55e79ef7f56) 用の単純なCLIクライアント


使い方
-----

**ユーザアカウントを作成する**

`esns -c <your username> <your description>`

**ユーザアカウントを更新する**

`esns -u <your username> <your description>`

**ツイートする**

`esns -t <text>`

**SNS上にいるユーザアカウントのリストを得る**

`esns -w`

**SNS上の全てのツイートのリストを得る**

`esns -l`

ビルド
------
[Racket](https://racket-lang.org/) が必要です。  
`raco exe -o esns main.rkt` と入力することで実行ファイルが得られます。  
この実行ファイルをPATHが通っているところにコピーしてください。
