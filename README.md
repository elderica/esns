# esns

[エンジニアのための SNS](https://qiita.com/HawkClaws/items/599d7666f55e79ef7f56) 用の単純な CLI クライアント

## 使い方

### ユーザアカウントを作成する

```bash
esns -c <your username> <your description>
```

### ユーザアカウントを更新する

```bash
esns -u <your username> <your description>
```

### ツイートする

```bash
esns -t <text>
```

### SNS 上にいるユーザアカウントのリストを得る

```bash
esns -w
```

### SNS 上の全てのツイートのリストを得る

```bash
esns -l
```

## ビルド

[Racket](https://racket-lang.org/) が必要です。  
`raco exe -o esns main.rkt` と入力することで実行ファイルが得られます。  
この実行ファイルを PATH が通っているところにコピーしてください。
