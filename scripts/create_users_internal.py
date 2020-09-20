#! /usr/bin/env python3

# create-users.py
# Create users specified in users.json

import argparse
import json
import os
import os.path

class User:
    def __init__(self, userJson=None):
        self.username = "test"
        self.fullName = "Testificate Tom"
        self.email = "test@example.com"
        self.password = "test0000"
        self.groups = "sudo,audio,video,input,render,lp"
        self.createHome = True
        self.shell = None
        self.skel = None
        self.homeDir = None
        if userJson is None:
            return
        
        if (v := userJson.get("username")) is not None:
            self.username = v
        if (v := userJson.get("fullName")) is not None:
            self.fullName = v
        if (v := userJson.get("email")) is not None:
            self.email = v
        if (v := userJson.get("password")) is not None:
            self.password = v
        if (v := userJson.get("groups")) is not None:
            self.groups = v
        if (v := userJson.get("createHome")) is not None:
            self.createHome = v
        if (v := userJson.get("shell")) is not None:
            self.shell = v
        if (v := userJson.get("skel")) is not None:
            self.skel = v
        if (v := userJson.get("homeDir")) is not None:
            self.homeDir = v

    def createUser(self):
        useradd_cmd = "useradd "
        if self.createHome:
            useradd_cmd += "-m "
        if self.shell is not None:
            useradd_cmd += "-s {0} ".format(self.shell)
        if self.skel is not None:
            useradd_cmd += "-k {0} ".format(self.skel)
        if self.homeDir is not None:
            useradd_cmd += "-d {0} ".format(self.homeDir)
        if self.groups is not None:
            useradd_cmd += "-G {0} ".format(self.groups)
        if self.fullName is not None:
            useradd_cmd += "-c \"{0}\" ".format(self.fullName)
        useradd_cmd += self.username

        print ("Creating user: {0}".format(self.username))
        #print (useradd_cmd)
        os.system(useradd_cmd)

    def configureGit(self):
        gitConfig_cmd = "git config --global user.name \"{0}\" && git config --global user.email \"{1}\"".format(
                        self.fullName, self.email)
        
        print ("Configuring git with user {0} <{1}>".format(self.username, self.email))
        #print (gitConfig_cmd)
        os.system(gitConfig_cmd)
        gitConfig_cmd = "git config --global color.ui false"
        os.system(gitConfig_cmd)

    def setPassword(self):
        chpasswd_cmd = "echo \"{0}:{1}\" | chpasswd".format(self.username, self.password)

        print ("Setting password for user {0}".format(self.username))
        #print (chpasswd_cmd)
        os.system(chpasswd_cmd)

    def enableServicesForUser(self):
        enable_service_cmd = "/build/output/scripts/services_internal.sh \"{0}\"".format(self.username)
        print ("Enabling needed services for ("+ self.username +")...")
        os.system(enable_service_cmd)

class UsersDefinition:
    def __init__(self, jsonFile=None):
        self.rootPassword = "test0000"
        self.users = None
        if jsonFile is None:
            return

        # Override defaults with values from json file
        if os.path.exists(jsonFile):
            try:
                with open(jsonFile) as f:
                    user_config = json.load(f)
                    if user_config is not None:
                        if (v := user_config.get("rootPassword")) is not None:
                            self.rootPassword = v
                        if (users := user_config.get("users")) is not None:
                            self.users = []
                            for user in users:
                                self.users.append(User(user))
            except ValueError:
                print("Failed to decode users spec file. Ensure it's valid json.")
                raise
            except OSError:
                print("Something went wrong")
                raise
        else:
            print("Failed to find users spec json file (" + jsonFile + ")")

    def setRootPassword(self):
        chpasswd_cmd = "echo \"root:{0}\" | chpasswd".format(self.rootPassword)

        print ("Setting password for root user")
        os.system(chpasswd_cmd)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--spec", help="Specify user spec json file.", 
                        metavar="FILE", nargs=2, default=["config/users.json" "false"])
    args = vars(parser.parse_args())
    print ("Enabling needed services for ("+ args["spec"][0] +")...")
    print ("Enabling needed services for ("+ args["spec"][1] +")...")

    users = UsersDefinition(args["spec"][0])
    if args["spec"][1] == "false":
      print ("write arg false")
      users.setRootPassword()
      if users.users is not None:
          for user in users.users:
              user.createUser()
              user.configureGit()
              user.setPassword()

    if args["spec"][1] == "true":
      print ("write arg")
      if users.users is not None:
        print ("user found")
        for user in users.users:
          user.enableServicesForUser()
