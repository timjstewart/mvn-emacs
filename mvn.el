;;;; mvn.el -- functions to make working with Maven a little easier from Emacs.
;;;; 
;;;; Using the mvn-run command;
;;;; 
;;;; For the mvn-run command to work, you have to have something like the following 
;;;; in your pom.xml file.
;;;; 
;;;;  <build>
;;;;   <plugins>
;;;;    <plugin>
;;;;     <groupId>org.codehaus.mojo</groupId>
;;;;     <artifactId>exec-maven-plugin</artifactId>
;;;;	 <version>1.2.1</version>
;;;;     <configuration>
;;;;       <mainClass><!-- Your main class (e.g. com.foobar.Main) --></mainClass>
;;;;     </configuration>
;;;;    </plugin>
;;;;   </plugins>
;;;;  </build>

(defconst +mvn-output-buffer-name+ "*Maven Output*"
  "The name of the buffer that displays mvn output")

(defconst +mvn-pom-file-name+ "pom.xml"
  "The name of the Maven project object model file")

(defcustom mvn-command "mvn"
  "The name of the maven command to run")

(defmacro mvn-defcommand (cmd-name arguments doc-string)
  `(defun ,cmd-name ()
     ,doc-string
     (interactive)
     (mvn-run-mvn-command default-directory ,arguments)))

(mvn-defcommand mvn-validate "validate"          "validates the maven project is correct") 
(mvn-defcommand mvn-package  "package"           "package the compiled code into a jar file") 
(mvn-defcommand mvn-verify   "verify"            "run checks to verify the package is valid and meets quality criteria") 
(mvn-defcommand mvn-deploy   "deploy"            "deploy the package to a remote repository for sharing") 
(mvn-defcommand mvn-compile  "compile"           "compiles the maven project") 
(mvn-defcommand mvn-install  "install"           "installs the Maven project") 
(mvn-defcommand mvn-tests    "test"              "runs unit tests")
(mvn-defcommand mvn-clean    "clean"             "cleans the Maven project")
(mvn-defcommand mvn-install  "install"           "installs the project jar file into the local Maven repository.")
(mvn-defcommand mvn-run      "compile exec:java" "runs the Maven project.  This requires the maven-exec-plugin")

(defun mvn-new-project (group-id artifact-id)
  (interactive "MEnter Group ID (e.g com.timjstewart): \nMEnter Artifact ID (e.g. super-widget): ")
  (mvn-generate-pom-file default-directory group-id artifact-id))

(defun mvn-find-project-directory (directory)
  (message (format "Looking for project directory starting in: %s" directory))
  (let ((pom-file-path (mvn-find-pom-file directory)))
    (when pom-file-path
      (message (format "Found pom.xml file: %s" pom-file-path))
      (file-name-directory pom-file-path))))

(defun mvn-find-pom-file (directory)
  (let ((pom-file-path (concat directory +mvn-pom-file-name+)))
    (if (file-exists-p pom-file-path)
        pom-file-path
      (let ((parent-dir (mvn-get-parent-directory directory)))
        (if (string= parent-dir directory)
            nil
          (mvn-find-pom-file parent-dir))))))

(defun mvn-get-parent-directory (directory)
  (file-name-directory 
   (directory-file-name 
    (file-name-directory directory))))

(defun mvn-generate-pom-file (directory group-id artifact-id)
  "Generates a pom.xml file in DIRECTORY with the specified GROUP-ID and ARTIFACT-ID."
  (labels ((make-flag (name value) 
                      (format "-D%s=%s" name value)))
    (message (format "Generating project.  Artifact ID: %s, Group ID: %s" artifact-id group-id))

    (mvn-run-mvn-command-in-directory directory "archetype:generate"
                                      (make-flag "artifactId" artifact-id)
                                      (make-flag "groupId" group-id)
                                      (make-flag "interactiveMode" "false")
                                      (make-flag "archetypeArtifactId" 
                                                 "maven-archetype-quickstart"))))

(defmacro in-directory (directory &rest body)
  `(let ((orig-dir default-directory))
     (unwind-protect
         (progn
           (cd-absolute ,directory)
           ,@body)
       (message orig-dir)
       (cd orig-dir))))

(defun mvn-build-command (command args)
  (message (format "Command: %s Args: %s" command args))
  (let ((tokens (cons mvn-command (cons command args))))
    (message (format "Tokens: %s" tokens))
    (let ((result (mapconcat 'identity tokens " ")))
      (message (format "Final Command: %s" result))
      result)))

;;(defun mvn-clear-output-buffer ()
;;  (let ((buffer (get-buffer +mvn-output-buffer-name+)))
;;    (when buffer
;;      (message (format "Clearing buffer from: %d to %d" (point-min) (point-max)))
;;      (with-current-buffer buffer
;;        (save-excursion
;;          (bury-buffer buffer)
;;          (delete-region (point-min) (point-max)))))))

(defun mvn-run-mvn-command (directory command &rest args)
  (let ((project-directory (mvn-find-project-directory directory))
        (command (mvn-build-command command args)))
    (when project-directory
      ;(mvn-clear-output-buffer)
      ;(message (format "Project Directory: %s" project-directory))
      (in-directory project-directory
                    (shell-command (concat "clear; " command) +mvn-output-buffer-name+)))))

(defun mvn-run-mvn-command-in-directory (directory command &rest args)
  (let ((command (mvn-build-command command args)))
    (in-directory directory
                  (shell-command command "*Maven Output*"))))

(provide 'mvn)
