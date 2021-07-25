#lang racket/base

(require racket/contract
         racket/string
         racket/bool
         net/http-easy)

;; エンドポイントURL
(define endpoint "https://versatileapi.herokuapp.com/api")

;; ユーザアカウントに関する情報を構造体で表現する。
(struct user
  [id                 ;; ユーザアカウントのID(文字列)
   created-at         ;; ユーザアカウントの作成日時(ISO 8601形式)
   updated-at         ;; ユーザアカウントの更新日時(ISO 8601形式)
   name               ;; スクリーンネーム(文字列)
   description]       ;; 自己紹介(文字列)
  #:transparent)

;; ユーザアカウント系APIから返ってくるオブジェクトをuserに変換する。
(define/contract (hash-to-user user#)
  (-> hash-eq? user?)
  (user (hash-ref user# 'id)
        (hash-ref user# '_created_at)
        (hash-ref user# '_updated_at)
        (hash-ref user# 'name)
        (hash-ref user# 'description)))

;; ユーザアカウントを作成する
(define/contract (sns-create-user name description)
  (-> string? string? string?)
  (let ([user# (response-json
                (post (string-append endpoint "/user/create_user")
                      #:json (hasheq 'name name
                                     'description description)))])
    (hash-ref user# 'id)))

;; ユーザアカウントを更新する。
(define/contract (sns-update-user name description)
  (-> string? string? string?)
  (let ([user# (response-json
                (put (string-append endpoint "/user/create_user")
                     #:json (hasheq 'name name
                                    'description description)))])
    (hash-ref user# 'id)))

;; SNS上に存在するユーザを全て取得する。
(define/contract (sns-get-all-users)
  (-> (listof user?))
  (let ([user#s (response-json
                 (get (string-append endpoint "/user/all")))])
    (map hash-to-user user#s)))

;; 指定したユーザIDをもつユーザアカウントを取得する。
(define/contract (sns-get-user user-id)
  (-> string? (or/c user? false?))
  (let ([response (get (string-append endpoint "/user/" user-id))])
    (if (= (response-status-code response) 200)
        (hash-to-user (response-json response))
        #f)))

;; 指定したユーザIDをもつユーザアカウントを取得する(キャッシュ付き)。
(define userdb (make-hash))
(define (sns-get-user* user-id)
  ;(-> string? user?)
  (hash-ref! userdb user-id (lambda ()
                              (sns-get-user user-id))))

;; ツイートに関する情報を構造体で表現する。
(struct tweet
  [id          ;; ツイートID
   user-id     ;; ユーザID
   created-at  ;; 投稿された日時
   updated-at  ;; 更新された日時
   text]       ;; 本文
  #:transparent)

;; SNSにツイートする。
(define/contract (sns-tweet text)
  (-> string? string?)
  (let ([response (post (string-append endpoint "/text")
                        #:headers (hasheq 'Authorization "HelloWorld")
                        #:json (hasheq 'text text))])
    (if (= 201 (response-status-code response))
        (hash-ref (response-json response) 'id)
        (raise 'post-failed))))

;; ツイート系APIから返ってくるオブジェクトをtweetに変換する。
(define/contract (hash-to-tweet tweet#)
  (-> hash-eq? tweet?)
  (tweet (hash-ref tweet# 'id)
         (hash-ref tweet# '_user_id)
         (hash-ref tweet# '_created_at)
         (hash-ref tweet# '_updated_at)
         (hash-ref tweet# 'text)))

;; 指定されたツイートIDをもつツイートを取得する。
(define/contract (sns-get-tweet id)
  (-> string? tweet?)
  (let* ([response (get (string-append endpoint "/text/" id))]
         [tweet# (response-json response)])
    (hash-to-tweet tweet#)))

;; SNS上の全てのツイートを取得する。
(define/contract (sns-get-all-tweets)
  (-> (listof tweet?))
  (let ([user#s (response-json (get (string-append endpoint "/text/all")))])
    (map hash-to-tweet user#s)))

;; ユーザIDのリストからスクリーンネームを割りだす


(module+ main
  (require racket/cmdline)

  (define cmd-operation (make-parameter null))
  (define cmd-user-name (make-parameter null))
  (define cmd-user-description (make-parameter ""))
  (define cmd-text-to-tweet (make-parameter ""))
  
  (command-line
   #:program "esns"
   #:once-any
   [("-c" "--create-user") name description "Create user"
                           (begin (cmd-operation 'create-user)
                                  (cmd-user-name name)
                                  (cmd-user-description description))]
   [("-u" "--update-user") name description "Update user"
                           (begin (cmd-operation 'create-user)
                                  (cmd-user-name name)
                                  (cmd-user-description description))]
   [("-t" "--tweet") text "Tweet"
                     (begin (cmd-operation 'tweet)
                            (cmd-text-to-tweet text))]
   [("-w" "--who-are-you") "List all users in SNS"
                           (begin (cmd-operation 'list-all-users))]
   [("-l" "--list-all-tweets") "List all tweets in SNS"
                               (begin (cmd-operation 'list-all-tweets))]
   #:args ()
   (case (cmd-operation)
     [(create-user) (printf "~a~n" (sns-create-user (cmd-user-name) (cmd-user-description)))]
     [(update-user) (printf "~a~n" (sns-update-user (cmd-user-name) (cmd-user-description)))]
     [(tweet) (if (non-empty-string? (cmd-text-to-tweet))
                  (printf "~a~n" (sns-tweet (cmd-text-to-tweet)))
                  (eprintf "empty text! specify something~n"))]
     [(list-all-users) (for-each (lambda (user)
                                   (printf "~a:~a~n"
                                           (user-name user)
                                           (user-description user)))
                                 (sns-get-all-users))]
     [(list-all-tweets) (for-each (lambda (tweet)
                                    (printf "~a:~a:~a~n"
                                            (let ([user (sns-get-user* (tweet-user-id tweet))])
                                              (if (user? user)
                                                  (user-name user)
                                                  "<unavailable>"))
                                            (tweet-created-at tweet)
                                            (tweet-text tweet)))
                                  (sns-get-all-tweets))]
     [else (eprintf "see help using -h flag~n")]))

  )