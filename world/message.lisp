(in-package #:alice)

(defclass message ()
  ((raw-text :initarg :raw-text
             :type string
             :accessor raw-text)

   ;; sentence-understanding-related
   (words :accessor words
          :documentation "Sentence split to particular words.")

   (nicks-present :accessor nicks-present
                  :documentation "All the nicknames identified in the sentence that are present on channel.")

   (nicks-known :accessor nicks-known
                :documentation "All the nicknames identified in the sentence that the bot ever heard, even if not present on particular channel.")

   (tone :accessor tone
         :documentation "Tone of the sentence; i.e. whether it is recognized as nice, angry, etc.")

   (urls :accessor urls
         :documentation "List of URLs mentioned.")

   ;; IRC-related
   (channel :initarg :channel
            :accessor channel
            :documentation "Name of channel on which this sentence was spoken.")

   (author :initarg :author
           :accessor author
           :documentation "Source person (nickname) who spoke the message.")

   (reply-to :initarg :reply-to
             :accessor reply-to
             :documentation "Either name (private mesage) or channel that can be used as a reply destination.")

   (publicp :initarg :publicp
            :accessor publicp
            :documentation "Was this message public (i.e. not directed, said on channel)?")

   (directedp :accessor directedp
              :documentation "Was this message directed at the bot? (in a form of 'Bot: ...' message)?")

   (mentionsp :accessor mentionsp
              :documentation "Does this sentence mentions bot by nickname?")

   (privatep :initarg :privatep
             :accessor directp
             :documentation "Is this message sent directly to the bot (as opposed to publicly on the channel)?")
   ))

(defmethod initialize-instance :after ((message message) &key)
  (setf (words message) (extract-words (raw-text message)))
  (setf (mentionsp message) (mentions-name *nick* (raw-text message)))

  (setf (urls message) (extract-urls (raw-text message)))
  ;; tone TODO

  ;; nicks known
  ;; nicks present
  )

(defun extract-urls (text)
  (cl-ppcre:all-matches-as-strings *general-url-regexp* text))

(defun extract-all-words (text)
  (delete-duplicates
   (cl-ppcre:all-matches-as-strings "[\\w\\|]{2,}" text)
   :test #'string=
   :from-end t))

(defun extract-words (text)
  (cl-ppcre:all-matches-as-strings "[\\w\\|]{2,}" text))

(defun extract-message-features (irc-message)
  (flet ((public-message-p (message)
             (and
              (not (string-equal *nick* (first (irc:arguments message)))) ; search message
              (not (starts-with-subseq *nick* (second (irc:arguments message))))))
         (private-message-p (message)
           (string-equal (first (irc:arguments message))
                         *nick*)))
    (make-instance 'message
                   :raw-text (second (irc:arguments irc-message))
                   :publicp (public-message-p irc-message)
                   :privatep (private-message-p irc-message)
                   :channel (first (irc:arguments irc-message))
                   :author (irc:source irc-message)
                   :reply-to (if (string-equal (first (irc:arguments irc-message)) *nick*)
                                 (irc:source irc-message)
                                 (first (irc:arguments irc-message))))))
