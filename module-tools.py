#!/usr/bin/env python3

import sys, os, os.path
import re
import time
import tempfile
from glob import glob
from optparse import OptionParser

# e.g. other_choices = [ ('d','iff') , ('g','uess') ] - lowercase 
def prompt (question, default=True, other_choices=[], allow_outside=False):
    if not isinstance (other_choices, list):
        other_choices = [ other_choices ]
    chars = [ c for (c,rest) in other_choices ]

    choices = []
    if 'y' not in chars:
        if default is True:
            choices.append('[y]')
        else :
            choices.append('y')
    if 'n' not in chars:
        if default is False:
            choices.append('[n]')
        else:
            choices.append('n')

    for char, choice in other_choices:
        if default == char:
            choices.append("[{}]{}".format(char, choice))
        else:
            choices.append("<{}>{}>".format(char, choice))
    try:
        answer = input(question + " " + "/".join(choices) + " ? ")
        if not answer:
            return default
        answer = answer[0].lower()
        if answer == 'y':
            if 'y' in chars:
                return 'y'
            else:
                return True
        elif answer == 'n':
            if 'n' in chars:
                return 'n'
            else:
                return False
        elif other_choices:
            for (char,choice) in other_choices:
                if answer == char:
                    return char
            if allow_outside:
                return answer
        return prompt(question, default, other_choices)
    except:
        raise

def default_editor():
    try:
        editor = os.environ['EDITOR']
    except:
        editor = "emacs"
    return editor

### fold long lines
fold_length = 132

def print_fold (line):
    while len(line) >= fold_length:
        print(line[:fold_length],'\\')
        line = line[fold_length:]
    print(line)

class Command:
    def __init__ (self, command, options):
        self.command = command
        self.options = options
        self.tmp = "/tmp/command-{}".format(os.getpid())

    def run (self):
        if self.options.dry_run:
            print('dry_run', self.command)
            return 0
        if self.options.verbose and self.options.mode not in Main.silent_modes:
            print('+', self.command)
            sys.stdout.flush()
        return os.system(self.command)

    def run_silent (self):
        if self.options.dry_run:
            print('dry_run', self.command)
            return 0
        if self.options.verbose:
            print('>', os.getcwd())
            print('+', self.command, ' .. ', end=' ')
            sys.stdout.flush()
        retcod = os.system("{} &> {}".format(self.command, self.tmp))
        if retcod != 0:
            print("FAILED ! -- out+err below (command was {})".format(self.command))
            os.system("cat {}".format(self.tmp))
            print("FAILED ! -- end of quoted output")
        elif self.options.verbose:
            print("OK")
        os.unlink(self.tmp)
        return retcod

    def run_fatal(self):
        if self.run_silent() != 0:
            raise Exception("Command {} failed".format(self.command))

    # returns stdout, like bash's $(mycommand)
    def output_of (self, with_stderr=False):
        if self.options.dry_run:
            print('dry_run', self.command)
            return 'dry_run output'
        tmp="/tmp/status-{}".format(os.getpid())
        if self.options.debug:
            print('+',self.command,' .. ', end=' ')
            sys.stdout.flush()
        command = self.command
        if with_stderr:
            command += " &> "
        else:
            command += " > "
        command += tmp
        os.system(command)
        with open(tmp) as f:
            result=f.read()
        os.unlink(tmp)
        if self.options.debug:
            print('Done', end=' ')
        return result
    
class GitRepository:
    type = "git"

    def __init__(self, path, options):
        self.path = path
        self.options = options

    def name(self):
        return os.path.basename(self.path)

    def url(self):
        return self.repo_root()

    def gitweb(self):
        c = Command("git show | grep commit | awk '{{print $2;}}'", self.options)
        out = self.__run_in_repo(c.output_of).strip()
        return "http://git.onelab.eu/?p={}.git;a=commit;h={}".format(self.name(), out)

    def repo_root(self):
        c = Command("git remote show origin", self.options)
        out = self.__run_in_repo(c.output_of)
        for line in out.split('\n'):
            if line.strip().startswith("Fetch URL:"):
                return line.split()[2]

    @classmethod
    def clone(cls, remote, local, options, depth=None):
        Command("rm -rf {}".format(local), options).run_silent()
        depth_option = "" if depth is None else " --depth {}".format(depth)
        Command("git clone{} {} {}".format(depth_option, remote, local), options).run_fatal()
        return GitRepository(local, options)

    @classmethod
    def remote_exists(cls, remote, options):
        return Command ("git --no-pager ls-remote {} &> /dev/null".format(remote), options).run()==0

    def tag_exists(self, tagname):
        command = 'git tag -l | grep "^{}$"'.format(tagname)
        c = Command(command, self.options)
        out = self.__run_in_repo(c.output_of, with_stderr=True)
        return len(out) > 0

    def __run_in_repo(self, fun, *args, **kwargs):
        cwd = os.getcwd()
        os.chdir(self.path)
        ret = fun(*args, **kwargs)
        os.chdir(cwd)
        return ret

    def __run_command_in_repo(self, command, ignore_errors=False):
        c = Command(command, self.options)
        if ignore_errors:
            return self.__run_in_repo(c.output_of)
        else:
            return self.__run_in_repo(c.run_fatal)

    def __is_commit_id(self, id):
        c = Command("git show {} | grep commit | awk '{{print $2;}}'".format(id), self.options)
        ret = self.__run_in_repo(c.output_of, with_stderr=False)
        if ret.strip() == id:
            return True
        return False

    def update(self, subdir=None, recursive=None, branch="master"):
        if branch == "master":
            self.__run_command_in_repo("git checkout {}".format(branch))
        else:
            self.to_branch(branch, remote=True)
        self.__run_command_in_repo("git fetch origin --tags")
        self.__run_command_in_repo("git fetch origin")
        if not self.__is_commit_id(branch):
            # we don't need to merge anything for commit ids.
            self.__run_command_in_repo("git merge --ff origin/{}".format(branch))

    def to_branch(self, branch, remote=True):
        self.revert()
        if remote:
            command = "git branch --track {} origin/{}".format(branch, branch)
            c = Command(command, self.options)
            self.__run_in_repo(c.output_of, with_stderr=True)
        return self.__run_command_in_repo("git checkout {}".format(branch))

    def to_tag(self, tag):
        self.revert()
        return self.__run_command_in_repo("git checkout {}".format(tag))

    def tag(self, tagname, logfile):
        self.__run_command_in_repo("git tag {} -F {}".format(tagname, logfile))
        self.commit(logfile)

    def diff(self, f=""):
        c = Command("git diff {}".format(f), self.options)
        return self.__run_in_repo(c.output_of, with_stderr=True)

    def diff_with_tag(self, tagname):
        c = Command("git diff {}".format(tagname), self.options)
        return self.__run_in_repo(c.output_of, with_stderr=True)

    def commit(self, logfile, branch="master"):
        self.__run_command_in_repo("git add .", ignore_errors=True)
        self.__run_command_in_repo("git add -u", ignore_errors=True)
        self.__run_command_in_repo("git commit -F  {}".format(logfile), ignore_errors=True)
        if branch == "master" or self.__is_commit_id(branch):
            self.__run_command_in_repo("git push")
        else:
            self.__run_command_in_repo("git push origin {}:{}".format(branch, branch))
        self.__run_command_in_repo("git push --tags")

    def revert(self, f=""):
        if f:
            self.__run_command_in_repo("git checkout {}".format(f))
        else:
            # revert all
            self.__run_command_in_repo("git --no-pager reset --hard")
            self.__run_command_in_repo("git --no-pager clean -f")

    def is_clean(self):
        def check_commit():
            command = "git status"
            s = "nothing to commit, working directory clean"
            return Command(command, self.options).output_of(True).find(s) >= 0
        return self.__run_in_repo(check_commit)

    def is_valid(self):
        return os.path.exists(os.path.join(self.path, ".git"))
    

class Repository:
    """ 
    Generic repository 
    From old times when we had svn and git
    """
    supported_repo_types = [ GitRepository ]

    def __init__(self, path, options):
        self.path = path
        self.options = options
        for repo_class in self.supported_repo_types:
            self.repo = repo_class(self.path, self.options)
            if self.repo.is_valid():
                break

    @classmethod
    def remote_exists(cls, remote, options):
        for repo_class in Repository.supported_repo_types:
            if repo_class.remote_exists(remote, options):
                return True
        return False

    def __getattr__(self, attr):
        return getattr(self.repo, attr)



# support for tagged module is minimal, and is for the Build class only
class Module:

    edit_magic_line = "--This line, and those below, will be ignored--"
    setting_tag_format = "Setting tag {}"
    
    redirectors = [
        # ('module_name_varname', 'name'),
        ('module_version_varname', 'version'),
        ('module_taglevel_varname', 'taglevel'),
    ]

    # where to store user's config
    config_storage = "CONFIG"
    # 
    config = {}

    import subprocess
    configKeys = [
        ('gitserver', "Enter your git server's hostname", "git.onelab.eu"),
        ('gituser', "Enter your user name (login name) on git server", subprocess.getoutput("id -un")),
        ("build", "Enter the name of your build module", "build"),
        ('username', "Enter your firstname and lastname for changelogs", ""),
        ("email", "Enter your email address for changelogs", ""),
    ]

    @classmethod
    def prompt_config_option(cls, key, message, default):
        cls.config[key]=input("{} [{}] : ".format(message,default)).strip() or default

    @classmethod
    def prompt_config (cls):
        for (key,message,default) in cls.configKeys:
            cls.config[key]=""
            while not cls.config[key]:
                cls.prompt_config_option(key, message, default)

    # for parsing module spec name:branch
    matcher_branch_spec = re.compile("\A(?P<name>[\w\.\-\/]+):(?P<branch>[\w\.\-]+)\Z")                                                                                                                         
    # special form for tagged module - for Build
    matcher_tag_spec = re.compile("\A(?P<name>[\w\.\-\/]+)@(?P<tagname>[\w\.\-]+)\Z")

    # parsing specfiles
    matcher_rpm_define = re.compile("%(define|global)\s+(\S+)\s+(\S*)\s*")

    @classmethod
    def parse_module_spec(cls, module_spec):
        name = branch_or_tagname = module_type = ""

        attempt = Module.matcher_branch_spec.match(module_spec)
        if attempt:
            module_type = "branch"
            name=attempt.group('name')
            branch_or_tagname=attempt.group('branch')
        else:
            attempt = Module.matcher_tag_spec.match(module_spec)
            if attempt:
                module_type = "tag"
                name=attempt.group('name')
                branch_or_tagname=attempt.group('tagname')
            else:
                name = module_spec
        return name, branch_or_tagname, module_type


    def __init__ (self, module_spec, options):
        # parse module spec
        self.pathname, branch_or_tagname, module_type = self.parse_module_spec(module_spec)
        self.name = os.path.basename(self.pathname)

        if module_type == "branch":
            self.branch = branch_or_tagname
        elif module_type == "tag":
            self.tagname = branch_or_tagname

        self.options=options
        self.module_dir="{}/{}".format(options.workdir,self.pathname)
        self.repository = None
        self.build = None

    def run (self,command):
        return Command(command,self.options).run()
    def run_fatal (self,command):
        return Command(command,self.options).run_fatal()
    def run_prompt (self,message,fun, *args):
        fun_msg = "{}({})".format(fun.__name__, ",".join(args))
        if not self.options.verbose:
            while True:
                choice = prompt(message, True, ('s','how'))
                if choice:
                    fun(*args)
                    return
                else:
                    print('About to run function:', fun_msg)
        else:
            question = "{} - want to run function: {}".format(message, fun_msg)
            if prompt(question, True):
                fun(*args)

    def friendly_name (self):
        if hasattr(self, 'branch'):
            return "{}:{}".format(self.pathname, self.branch)
        elif hasattr(self, 'tagname'):
            return "{}@{}".format(self.pathname, self.tagname)
        else:
            return self.pathname

    @classmethod
    def git_remote_dir (cls, name):
        return "{}@{}:/git/{}.git".format(cls.config['gituser'], cls.config['gitserver'], name)

    ####################
    @classmethod
    def init_homedir (cls, options):
        if options.verbose and options.mode not in Main.silent_modes:
            print('Checking for', options.workdir)
        storage="{}/{}".format(options.workdir, cls.config_storage)
        # sanity check. Either the topdir exists AND we have a config/storage
        # or topdir does not exist and we create it
        # to avoid people use their own daily work repo
        if os.path.isdir(options.workdir) and not os.path.isfile(storage):
            print("""The directory {} exists and has no CONFIG file
If this is your regular working directory, please provide another one as the
module-* commands need a fresh working dir. Make sure that you do not use 
that for other purposes than tagging""".format(options.workdir))
            sys.exit(1)

        def clone_build():
            print("Checking out build module...")
            remote = cls.git_remote_dir(cls.config['build'])
            local = os.path.join(options.workdir, cls.config['build'])
            GitRepository.clone(remote, local, options, depth=1)
            print("OK")

        def store_config():
            with open(storage, 'w') as f:
                for (key, message, default) in Module.configKeys:
                    f.write("{}={}\n".format(key, Module.config[key]))
            if options.debug:
                print('Stored', storage)
                Command("cat {}".format(storage),options).run()

        def read_config():
            # read config
            with open(storage) as f:
                for line in f.readlines():
                    key, value = re.compile("^(.+)=(.+)$").match(line).groups()
                    Module.config[key] = value                

            # owerride config variables using options.
            if options.build_module:
                Module.config['build'] = options.build_module

        if not os.path.isdir (options.workdir):
            print("Cannot find {}, let's create it".format(options.workdir))
            Command("mkdir -p {}".format(options.workdir), options).run_silent()
            cls.prompt_config()
            clone_build()
            store_config()
        else:
            read_config()
            # check missing config options
            old_layout = False
            for key, message, default in cls.configKeys:
                if key not in Module.config:
                    print("Configuration changed for module-tools")
                    cls.prompt_config_option(key, message, default)
                    old_layout = True
                    
            if old_layout:
                Command("rm -rf {}".format(options.workdir), options).run_silent()
                Command("mkdir -p {}".format(options.workdir), options).run_silent()
                clone_build()
                store_config()

            build_dir = os.path.join(options.workdir, cls.config['build'])
            if not os.path.isdir(build_dir):
                clone_build()
            else:
                build = Repository(build_dir, options)
                if not build.is_clean():
                    print("build module needs a revert")
                    build.revert()
                    print("OK")
                build.update()

        if options.verbose and options.mode not in Main.silent_modes:
            print('******** Using config')
            for (key,message,default) in Module.configKeys:
                print('\t{} = {}'.format(key,Module.config[key]))

    def init_module_dir (self):
        if self.options.verbose:
            print('Checking for', self.module_dir)

        if not os.path.isdir (self.module_dir):
            self.repository = GitRepository.clone(self.git_remote_dir(self.pathname),
                                                  self.module_dir,
                                                  self.options)

        self.repository = Repository(self.module_dir, self.options)

        if self.repository.type == "git":
            if hasattr(self, 'branch'):
                self.repository.to_branch(self.branch)
            elif hasattr(self, 'tagname'):
                self.repository.to_tag(self.tagname)
        else:
            raise Exception('Cannot find {} - or not a git module'.format(self.module_dir))
                

    def revert_module_dir (self):
        if self.options.fast_checks:
            if self.options.verbose: print('Skipping revert of {}'.format(self.module_dir))
            return
        if self.options.verbose:
            print('Checking whether', self.module_dir, 'needs being reverted')
        
        if not self.repository.is_clean():
            self.repository.revert()

    def update_module_dir (self):
        if self.options.fast_checks:
            if self.options.verbose: print('Skipping update of {}'.format(self.module_dir))
            return
        if self.options.verbose:
            print('Updating', self.module_dir)

        if hasattr(self, 'branch'):
            self.repository.update(branch=self.branch)
        elif hasattr(self, 'tagname'):
            self.repository.update(branch=self.tagname)
        else:
            self.repository.update()

    def main_specname (self):
        attempt = "{}/{}.spec".format(self.module_dir, self.name)
        if os.path.isfile (attempt):
            return attempt
        pattern1 = "{}/*.spec".format(self.module_dir)
        level1 = glob(pattern1)
        if level1:
            return level1[0]
        pattern2 = "{}/*/*.spec".format(self.module_dir)
        level2 = glob(pattern2)

        if level2:
            return level2[0]
        raise Exception('Cannot guess specfile for module {} -- patterns were {} or {}'\
                        .format(self.pathname,pattern1,pattern2))

    def all_specnames (self):
        level1 = glob("{}/*.spec".format(self.module_dir))
        if level1:
            return level1
        level2 = glob("{}/*/*.spec".format(self.module_dir))
        return level2

    def parse_spec (self, specfile, varnames):
        if self.options.verbose:
            print('Parsing',specfile, end=' ')
            for var in varnames:
                print("[{}]".format(var), end=' ')
            print("")
        result={}
        with open(specfile) as f:
            for line in f.readlines():
                attempt = Module.matcher_rpm_define.match(line)
                if attempt:
                    define, var, value = attempt.groups()
                    if var in varnames:
                        result[var] = value
        if self.options.debug:
            print('found {} keys'.format(len(result)))
            for k, v in result.items():
                print('{} = {}'.format(k, v))
        return result
                
    # stores in self.module_name_varname the rpm variable to be used for the module's name
    # and the list of these names in self.varnames
    def spec_dict (self):
        specfile = self.main_specname()
        redirector_keys = [ varname for (varname, default) in Module.redirectors]
        redirect_dict = self.parse_spec(specfile, redirector_keys)
        if self.options.debug:
            print('1st pass parsing done, redirect_dict=', redirect_dict)
        varnames = []
        for varname, default in Module.redirectors:
            if varname in redirect_dict:
                setattr(self, varname, redirect_dict[varname])
                varnames += [redirect_dict[varname]]
            else:
                setattr(self, varname, default)
                varnames += [ default ] 
        self.varnames = varnames
        result = self.parse_spec (specfile, self.varnames)
        if self.options.debug:
            print('2st pass parsing done, varnames={} result={}'.format(varnames, result))
        return result

    def patch_spec_var (self, patch_dict,define_missing=False):
        for specfile in self.all_specnames():
            # record the keys that were changed
            changed = dict ( [ (x,False) for x in list(patch_dict.keys()) ] )
            newspecfile = "{}.new".format(specfile)
            if self.options.verbose:
                print('Patching', specfile, 'for', list(patch_dict.keys()))

            with open (specfile) as spec:
                with open(newspecfile, "w") as new:
                    for line in spec.readlines():
                        attempt = Module.matcher_rpm_define.match(line)
                        if attempt:
                            define, var, value = attempt.groups()
                            if var in list(patch_dict.keys()):
                                if self.options.debug:
                                    print('rewriting {} as {}'.format(var, patch_dict[var]))
                                new.write('%{} {} {}\n'.format(define, var, patch_dict[var]))
                                changed[var] = True
                                continue
                        new.write(line)
                    if define_missing:
                        for key, was_changed in changed.items():
                            if not was_changed:
                                if self.options.debug:
                                    print('rewriting missing {} as {}'.format(key, patch_dict[key]))
                                new.write('\n%define {} {}\n'.format(key, patch_dict[key]))
            os.rename(newspecfile, specfile)

    # returns all lines until the magic line
    def unignored_lines (self, logfile):
        result = []
        white_line_matcher = re.compile("\A\s*\Z")
        with open(logfile) as f:
            for logline in f.readlines():
                if logline.strip() == Module.edit_magic_line:
                    break
                elif white_line_matcher.match(logline):
                    continue
                else:
                    result.append(logline.strip()+'\n')
        return result

    # creates a copy of the input with only the unignored lines
    def strip_magic_line_filename (self, filein, fileout ,new_tag_name):
       with open(fileout,'w') as f:
           f.write(self.setting_tag_format.format(new_tag_name) + '\n')
           for line in self.unignored_lines(filein):
               f.write(line)

    def insert_changelog (self, logfile, newtag):
        for specfile in self.all_specnames():
            newspecfile = "{}.new".format(specfile)
            if self.options.verbose:
                print('Inserting changelog from {} into {}'.format(logfile, specfile))

            with open (specfile) as spec:
                with open(newspecfile,"w") as new:
                    for line in spec.readlines():
                        new.write(line)
                        if re.compile('%changelog').match(line):
                            dateformat="* %a %b %d %Y"
                            datepart=time.strftime(dateformat)
                            logpart="{} <{}> - {}".format(Module.config['username'],
                                                          Module.config['email'],
                                                          newtag)
                            new.write("{} {}\n".format(datepart,logpart))
                            for logline in self.unignored_lines(logfile):
                                new.write("- " + logline)
                            new.write("\n")
            os.rename(newspecfile,specfile)
            
    def show_dict (self, spec_dict):
        if self.options.verbose:
            for k, v in spec_dict.items():
                print('{} = {}'.format(k, v))

    def last_tag (self, spec_dict):
        try:
            return "{}-{}".format(spec_dict[self.module_version_varname],
                                  spec_dict[self.module_taglevel_varname])
        except KeyError as err:
            raise Exception('Something is wrong with module {}, cannot determine {} - exiting'\
                            .format(self.name, err))

    def tag_name (self, spec_dict):
        return "{}-{}".format(self.name, self.last_tag(spec_dict))
    

    pattern_format="\A\s*{module}-(GITPATH)\s*(=|:=)\s*(?P<url_main>[^\s]+)/{module}[^\s]+"

    def is_mentioned_in_tagsfile (self, tagsfile):
        # so that {module} gets replaced from format
        module = self.name
        module_matcher = re.compile(Module.pattern_format.format(**locals()))
        with open(tagsfile) as f:
            for line in f.readlines():
                if module_matcher.match(line):
                    return True
        return False

##############################
    # using fine_grain means replacing only those instances that currently refer to this tag
    # otherwise, <module>-GITPATH is replaced unconditionnally
    def patch_tags_file (self, tagsfile, oldname, newname, fine_grain=True):
        newtagsfile = "{}.new".format(tagsfile)

        with open(tagsfile) as tags:
            with open(newtagsfile,"w") as new:
                matches = 0
                # fine-grain : replace those lines that refer to oldname
                if fine_grain:
                    if self.options.verbose:
                        print('Replacing {} into {}\n\tin {} .. '.format(oldname, newname, tagsfile), end=' ')
                    matcher = re.compile("^(.*){}(.*)".format(oldname))
                    for line in tags.readlines():
                        if not matcher.match(line):
                            new.write(line)
                        else:
                            begin, end = matcher.match(line).groups()
                            new.write(begin+newname+end+"\n")
                            matches += 1
                # brute-force : change uncommented lines that define <module>-GITPATH
                else:
                    if self.options.verbose:
                        print('Searching for -GITPATH lines referring to /{}/\n\tin {} .. '\
                              .format(self.pathname, tagsfile), end=' ')
                    # so that {module} gets replaced from format
                    module = self.name
                    module_matcher = re.compile(Module.pattern_format.format(**locals()))
                    for line in tags.readlines():
                        attempt = module_matcher.match(line)
                        if attempt:
                            if line.find("-GITPATH") >= 0:
                                modulepath = "{}-GITPATH".format(self.name)
                                replacement = "{:<32}:= {}/{}.git@{}\n"\
                                    .format(modulepath, attempt.group('url_main'), self.pathname, newname)
                            else:
                                print("Could not locate {}-GITPATH (be aware that support for svn has been removed)"\
                                      .format(self.name))
                                return
                            if self.options.verbose:
                                print(' ' + modulepath, end=' ') 
                            new.write(replacement)
                            matches += 1
                        else:
                            new.write(line)
                            
        os.rename(newtagsfile,tagsfile)
        if self.options.verbose:
            print("{} changes".format(matches))
        return matches

    def check_tag(self, tagname, need_it=False):
        if self.options.verbose:
            print("Checking {} repository tag: {} - ".format(self.repository.type, tagname), end=' ')

        found_tagname = tagname
        found = self.repository.tag_exists(tagname)

        if (found and need_it) or (not found and not need_it):
            if self.options.verbose:
                print("OK", end=' ')
                print("- found" if found else "- not found")
        else:
            if self.options.verbose:
                print("KO")
            exception_format = "tag ({}) is already there" if found else "can not find required tag ({})"
            raise Exception(exception_format.format(tagname))

        return found_tagname


##############################
    def do_tag (self):
        self.init_module_dir()
        self.revert_module_dir()
        self.update_module_dir()
        # parse specfile
        spec_dict = self.spec_dict()
        self.show_dict(spec_dict)
        
        # compute previous tag - if not bypassed
        if not self.options.bypass:
            old_tag_name = self.tag_name(spec_dict)
            # sanity check
            old_tag_name = self.check_tag(old_tag_name, need_it=True)

        if (self.options.new_version):
            # new version set on command line
            spec_dict[self.module_version_varname] = self.options.new_version
            spec_dict[self.module_taglevel_varname] = 0
        else:
            # increment taglevel
            new_taglevel = str ( int (spec_dict[self.module_taglevel_varname]) + 1)
            spec_dict[self.module_taglevel_varname] = new_taglevel

        new_tag_name = self.tag_name(spec_dict)
        # sanity check
        new_tag_name = self.check_tag(new_tag_name, need_it=False)

        # checking for diffs
        if not self.options.bypass:
            diff_output = self.repository.diff_with_tag(old_tag_name)
            if len(diff_output) == 0:
                if not prompt ("No pending difference in module {}, want to tag anyway".format(self.pathname), False):
                    return

        # side effect in head's specfile
        self.patch_spec_var(spec_dict)

        # prepare changelog file 
        # we use the standard subversion magic string (see edit_magic_line)
        # so we can provide useful information, such as version numbers and diff
        # in the same file
        changelog_plain  = "/tmp/{}-{}.edit".format(self.name, os.getpid())
        changelog_strip  = "/tmp/{}-{}.strip".format(self.name, os.getpid())
        setting_tag_line = Module.setting_tag_format.format(new_tag_name)
        with open(changelog_plain, 'w') as f:
            f.write("""
{}
{}
Please write a changelog for this new tag in the section above
""".format(Module.edit_magic_line, setting_tag_line))

        if self.options.bypass: 
            pass
        elif prompt('Want to see diffs while writing changelog', True):
            with open(changelog_plain, "a") as f:
                f.write('DIFF=========\n' + diff_output)
        
        if self.options.debug:
            prompt('Proceed ?')

        # edit it        
        self.run("{} {}".format(self.options.editor, changelog_plain))
        # strip magic line in second file
        self.strip_magic_line_filename(changelog_plain, changelog_strip, new_tag_name)
        # insert changelog in spec
        if self.options.changelog:
            self.insert_changelog (changelog_plain, new_tag_name)

        ## update build
        build_path = os.path.join(self.options.workdir, Module.config['build'])
        build = Repository(build_path, self.options)
        if self.options.build_branch:
            build.to_branch(self.options.build_branch)
        if not build.is_clean():
            build.revert()

        tagsfiles = glob(build.path+"/*-tags.mk")
        tagsdict = dict( [ (x,'todo') for x in tagsfiles ] )
        default_answer = 'y'
        tagsfiles.sort()
        while True:
            # do not bother if in bypass mode
            if self.options.bypass:
                break
            for tagsfile in tagsfiles:
                if not self.is_mentioned_in_tagsfile (tagsfile):
                    if self.options.verbose:
                        print("tagsfile {} does not mention {} - skipped".format(tagsfile, self.name))
                    continue
                status = tagsdict[tagsfile]
                basename = os.path.basename(tagsfile)
                print(".................... Dealing with {}".format(basename))
                while tagsdict[tagsfile] == 'todo' :
                    choice = prompt ("insert {} in {}    ".format(new_tag_name, basename),
                                     default_answer,
                                     [ ('y','es'), ('n', 'ext'), ('f','orce'), 
                                       ('d','iff'), ('r','evert'), ('c', 'at'), ('h','elp') ] ,
                                     allow_outside=True)
                    if choice == 'y':
                        self.patch_tags_file(tagsfile, old_tag_name, new_tag_name, fine_grain=True)
                    elif choice == 'n':
                        print('Done with {}'.format(os.path.basename(tagsfile)))
                        tagsdict[tagsfile] = 'done'
                    elif choice == 'f':
                        self.patch_tags_file(tagsfile, old_tag_name, new_tag_name, fine_grain=False)
                    elif choice == 'd':
                        print(build.diff(f=os.path.basename(tagsfile)))
                    elif choice == 'r':
                        build.revert(f=tagsfile)
                    elif choice == 'c':
                        self.run("cat {}".format(tagsfile))
                    else:
                        name = self.name
                        print(
"""y: change {name}-GITPATH only if it currently refers to {old_tag_name}
f: unconditionnally change any line that assigns {name}-GITPATH to using {new_tag_name}
d: show current diff for this tag file
r: revert that tag file
c: cat the current tag file
n: move to next file""".format(**locals()))

            if prompt("Want to review changes on tags files", False):
                tagsdict = dict ( [ (x, 'todo') for x in tagsfiles ] )
                default_answer = 'd'
            else:
                break

        def diff_all_changes():
            print(build.diff())
            print(self.repository.diff())

        def commit_all_changes(log):
            if hasattr(self, 'branch'):
                self.repository.commit(log, branch=self.branch)
            else:
                self.repository.commit(log)
            build.commit(log)

        self.run_prompt("Review module and build", diff_all_changes)
        self.run_prompt("Commit module and build", commit_all_changes, changelog_strip)
        self.run_prompt("Create tag", self.repository.tag, new_tag_name, changelog_strip)

        if self.options.debug:
            print('Preserving {} and stripped {}', changelog_plain, changelog_strip)
        else:
            os.unlink(changelog_plain)
            os.unlink(changelog_strip)


##############################
    def do_version (self):
        self.init_module_dir()
        self.revert_module_dir()
        self.update_module_dir()
        spec_dict = self.spec_dict()
        if self.options.www:
            self.html_store_title('Version for module {} ({})'\
                                  .format(self.friendly_name(), self.last_tag(spec_dict)))
        for varname in self.varnames:
            if varname not in spec_dict:
                self.html_print ('Could not find %define for {}'.format(varname))
                return
            else:
                self.html_print ("{:<16} {}".format(varname, spec_dict[varname]))
        self.html_print ("{:<16} {}".format('url', self.repository.url()))
        if self.options.verbose:
            self.html_print ("{:<16} {}".format('main specfile:', self.main_specname()))
            self.html_print ("{:<16} {}".format('specfiles:', self.all_specnames()))
        self.html_print_end()


##############################
    def do_diff (self):
        self.init_module_dir()
        self.revert_module_dir()
        self.update_module_dir()
        spec_dict = self.spec_dict()
        self.show_dict(spec_dict)

        # side effects
        tag_name = self.tag_name(spec_dict)

        # sanity check
        tag_name = self.check_tag(tag_name, need_it=True)

        if self.options.verbose:
            print('Getting diff')
        diff_output = self.repository.diff_with_tag(tag_name)

        if self.options.list:
            if diff_output:
                print(self.pathname)
        else:
            thename = self.friendly_name()
            do_print = False
            if self.options.www and diff_output:
                self.html_store_title("Diffs in module {} ({}) : {} chars"\
                                      .format(thename, self.last_tag(spec_dict), len(diff_output)))

                self.html_store_raw ('<p> &lt; (left) {} </p>'"{:<16} {}".format(tag_name))
                self.html_store_raw ('<p> &gt; (right) {} </p>'"{:<16} {}".format(thename))
                self.html_store_pre (diff_output)
            elif not self.options.www:
                print('x'*30, 'module', thename)
                print('x'*20, '<', tag_name)
                print('x'*20, '>', thename)
                print(diff_output)

##############################
    # store and restitute html fragments
    @staticmethod 
    def html_href (url,text):
        return '<a href="{}">{}</a>'.format(url, text)

    @staticmethod 
    def html_anchor (url,text):
        return '<a name="{}">{}</a>'.format(url,text)

    @staticmethod
    def html_quote (text):
        return text.replace('&', '&#38;').replace('<', '&lt;').replace('>', '&gt;')

    # only the fake error module has multiple titles
    def html_store_title (self, title):
        if not hasattr(self,'titles'):
            self.titles=[]
        self.titles.append(title)

    def html_store_raw (self, html):
        if not hasattr(self,'body'):
            self.body=''
        self.body += html

    def html_store_pre (self, text):
        if not hasattr(self,'body'):
            self.body=''
        self.body += '<pre>{}</pre>'.format(self.html_quote(text))

    def html_print (self, txt):
        if not self.options.www:
            print(txt)
        else:
            if not hasattr(self, 'in_list') or not self.in_list:
                self.html_store_raw('<ul>')
                self.in_list = True
            self.html_store_raw('<li>{}</li>'.format(txt))

    def html_print_end (self):
        if self.options.www:
            self.html_store_raw ('</ul>')

    @staticmethod
    def html_dump_header(title):
        nowdate = time.strftime("%Y-%m-%d")
        nowtime = time.strftime("%H:%M (%Z)")
        print("""<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
<title> {} </title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<style type="text/css">
body {{ font-family:georgia, serif; }}
h1 {{font-size: large; }}
p.title {{font-size: x-large; }}
span.error {{text-weight:bold; color: red; }}
</style>
</head>
<body>
<p class='title'> {} - status on {} at {}</p>
<ul>
""".format(title, title, nowdate, nowtime))

    @staticmethod
    def html_dump_middle():
        print("</ul>")

    @staticmethod
    def html_dump_footer():
        print("</body></html")

    def html_dump_toc(self):
        if hasattr(self,'titles'):
            for title in self.titles:
                print('<li>', self.html_href('#'+self.friendly_name(),title), '</li>')

    def html_dump_body(self):
        if hasattr(self,'titles'):
            for title in self.titles:
                print('<hr /><h1>', self.html_anchor(self.friendly_name(),title), '</h1>')
        if hasattr(self,'body'):
            print(self.body)
            print('<p class="top">', self.html_href('#','Back to top'), '</p>')            



class Build(Module):
    
    def __get_modules(self, tagfile):
        self.init_module_dir()
        modules = {}

        tagfile = os.path.join(self.module_dir, tagfile)
        for line in open(tagfile):
            try:
                name, url = line.split(':=')
                name, git_path = name.rsplit('-', 1)
                modules[name] = (git_path.strip(), url.strip())
            except:
                pass
        return modules

    def get_modules(self, tagfile):
        modules = self.__get_modules(tagfile)
        for module in modules:
            module_type = tag_or_branch = ""

            path_type, url = modules[module]
            if path_type == "GITPATH":
                module_spec = os.path.split(url)[-1].replace(".git","")
                name, tag_or_branch, module_type = self.parse_module_spec(module_spec)
            else:
                tag_or_branch = os.path.split(url)[-1].strip()
                if url.find('/tags/') >= 0:
                    module_type = "tag"
                elif url.find('/branches/') >= 0:
                    module_type = "branch"
            
            modules[module] = {"module_type" : module_type,
                               "path_type": path_type,
                               "tag_or_branch": tag_or_branch,
                               "url":url}
        return modules
                
        

def modules_diff(first, second):
    diff = {}

    for module in first:
        if module not in second: 
            print("=== module {} missing in right-hand side ===".format(module))
            continue
        if first[module]['tag_or_branch'] != second[module]['tag_or_branch']:
            diff[module] = (first[module]['tag_or_branch'], second[module]['tag_or_branch'])

    first_set = set(first.keys())
    second_set = set(second.keys())

    new_modules = list(second_set - first_set)
    removed_modules = list(first_set - second_set)

    return diff, new_modules, removed_modules

def release_changelog(options, buildtag_old, buildtag_new):

    # the command line expects new old, so we treat the tagfiles in the same order
    nb_tags = len(options.distrotags)
    if nb_tags == 1:
        tagfile_new = tagfile_old = options.distrotags[0]
    elif nb_tags == 2:
        tagfile_new, tagfile_old = options.distrotags
    else:
        print("ERROR: provide one or two tagfile name (eg. onelab-k32-tags.mk)")
        print("two tagfiles can be mentioned when a tagfile has been renamed")
        return

    if options.dry_run:
        print("------------------------------ Computing Changelog from")
        print("buildtag_old", buildtag_old, "tagfile_old", tagfile_old)
        print("buildtag_new", buildtag_new, "tagfile_new", tagfile_new)
        return

    print('----')
    print('----')
    print('----')
    print('= build tag {} to {} ='.format(buildtag_old, buildtag_new))
    print('== distro {} ({} to {}) =='.format(tagfile_new, buildtag_old, buildtag_new))

    build = Build("build@{}".format(buildtag_old), options)
    build.init_module_dir()
    first = build.get_modules(tagfile_old)

    print(' * from', buildtag_old, build.repository.gitweb())

    build = Build("build@{}".format(buildtag_new), options)
    build.init_module_dir()
    second = build.get_modules(tagfile_new)

    print(' * to', buildtag_new, build.repository.gitweb())

    diff, new_modules, removed_modules = modules_diff(first, second)


    def get_module(name, tag):
        if not tag or  tag == "trunk":
            return Module("{}".format(module), options)
        else:
            return Module("{}@{}".format(module, tag), options)


    for module in diff:
        print('=== {} - {} to {} : package {} ==='.format(tagfile_new, buildtag_old, buildtag_new, module))

        first, second = diff[module]
        m = get_module(module, first)
        os.system('rm -rf {}'.format(m.module_dir)) # cleanup module dir
        m.init_module_dir()

        print(' * from', first, m.repository.gitweb())

        specfile = m.main_specname()
        (tmpfd, tmpfile) = tempfile.mkstemp()
        os.system("cp -f /{} {}".format(specfile, tmpfile))
        
        m = get_module(module, second)
        # patch for ipfw that, being managed in a separate repo, won't work for now
        try:
            m.init_module_dir()
        except Exception as e:
            print("""Could not retrieve module {} - skipped
{{{{{{ {} }}}}}}
""".format( m.friendly_name(), e))
            continue
        specfile = m.main_specname()

        print(' * to', second, m.repository.gitweb())

        print('{{{')
        os.system("diff -u {} {} | sed -e 's,{},[[previous version]],'"\
                  .format(tmpfile, specfile, tmpfile))
        print('}}}')

        os.unlink(tmpfile)

    for module in new_modules:
        print('=== {} : new package in build {} ==='.format(tagfile_new, module))

    for module in removed_modules:
        print('=== {} : removed package from build {} ==='.format(tagfile_new, module))


def adopt_tag (options, args):
    modules=[]
    for module in options.modules:
        modules += module.split()
    for module in modules: 
        modobj=Module(module,options)
        for tags_file in args:
            if options.verbose:
                print('adopting tag {} for {} in {}'.format(options.tag, module, tags_file))
            modobj.patch_tags_file(tags_file, '_unused_', options.tag, fine_grain=False)
    if options.verbose:
        Command("git diff {}".format(" ".join(args)), options).run()

##############################
class Main:

    module_usage="""Usage: %prog [options] module_desc [ .. module_desc ]

module-tools : a set of tools to manage subversion tags and specfile
  requires the specfile to either
  * define *version* and *taglevel*
  OR alternatively 
  * define redirection variables module_version_varname / module_taglevel_varname
Master:
  by default, the 'master' branch of modules is the target
  in this case, just mention the module name as <module_desc>
Branches:
  if you wish to work on another branch, 
  you can use something like e.g. Mom:2.1 as <module_desc>
"""
    release_usage="""Usage: %prog [options] tag1 .. tagn
  Extract release notes from the changes in specfiles between several build tags, latest first
  Examples:
      release-changelog 4.2-rc25 4.2-rc24 4.2-rc23 4.2-rc22
  You can refer to a (build) branch by prepending a colon, like in
      release-changelog :4.2 4.2-rc25
  You can refer to the build trunk by just mentioning 'trunk', e.g.
      release-changelog -t coblitz-tags.mk coblitz-2.01-rc6 trunk
  You can use 2 different tagfile names if that was renamed meanwhile
      release-changelog -t onelab-tags.mk 5.0-rc29 -t onelab-k32-tags.mk 5.0-rc28
"""
    adopt_usage="""Usage: %prog [options] tag-file[s]
  With this command you can adopt a specifi tag or branch in your tag files
    This should be run in your daily build workdir; no call of git is done
  Examples:
    adopt-tag -m "plewww plcapi" -m Monitor onelab*tags.mk
    adopt-tag -m sfa -t sfa-1.0-33 *tags.mk
"""
    common_usage="""More help:
  see http://svn.planet-lab.org/wiki/ModuleTools"""

    modes = { 
        'list' : "displays a list of available tags or branches",
        'version' : "check latest specfile and print out details",
        'diff' : "show difference between module (trunk or branch) and latest tag",
        'tag'  : """increment taglevel in specfile, insert changelog in specfile,
                create new tag and and monitor its adoption in build/*-tags.mk""",
        'branch' : """create a branch for this module, from the latest tag on the trunk, 
                  and change trunk's version number to reflect the new branch name;
                  you can specify the new branch name by using module:branch""",
        'sync' : """create a tag from the module
                this is a last resort option, mostly for repairs""",
        'changelog' : """extract changelog between build tags
                expected arguments are a list of tags""",
        'adopt' : """locally adopt a specific tag""",
        }

    silent_modes = ['list']
    # 'changelog' is for release-changelog
    # 'adopt' is for 'adopt-tag'
    regular_modes = set(modes.keys()).difference(set(['changelog','adopt']))

    @staticmethod
    def optparse_list (option, opt, value, parser):
        try:
            setattr(parser.values,option.dest,getattr(parser.values,option.dest)+value.split())
        except:
            setattr(parser.values,option.dest,value.split())

    def run(self):

        mode=None
        # hack - need to check for adopt first as 'adopt-tag' contains tag..
        for function in [ 'adopt' ] + list(Main.modes.keys()):
            if sys.argv[0].find(function) >= 0:
                mode = function
                break
        if not mode:
            print("Unsupported command",sys.argv[0])
            print("Supported commands:" + " ".join(list(Main.modes.keys())))
            sys.exit(1)

        usage='undefined usage, mode={}'.format(mode)
        if mode in Main.regular_modes:
            usage = Main.module_usage
            usage += Main.common_usage
            usage += "\nmodule-{} : {}".format(mode, Main.modes[mode])
        elif mode == 'changelog':
            usage = Main.release_usage
            usage += Main.common_usage
        elif mode == 'adopt':
            usage = Main.adopt_usage
            usage += Main.common_usage

        parser=OptionParser(usage=usage)
        
        # the 'adopt' mode is really special and doesn't share any option
        if mode == 'adopt':
            parser.add_option("-m","--module",action="append",dest="modules",default=[],
                              help="modules, can be used several times or with quotes")
            parser.add_option("-t","--tag",action="store", dest="tag", default='master',
                              help="specify the tag to adopt, default is 'master'")
            parser.add_option("-v","--verbose", action="store_true", dest="verbose", default=False, 
                              help="run in verbose mode")
            (options, args) = parser.parse_args()
            options.workdir='unused'
            options.dry_run=False
            options.mode='adopt'
            if len(args)==0 or len(options.modules)==0:
                parser.print_help()
                sys.exit(1)
            adopt_tag (options,args)
            return 

        # the other commands (module-* and release-changelog) share the same skeleton
        if mode in [ 'tag', 'branch'] :
            parser.add_option("-s","--set-version",action="store",dest="new_version",default=None,
                              help="set new version and reset taglevel to 0")
            parser.add_option("-0","--bypass",action="store_true",dest="bypass",default=False,
                              help="skip checks on existence of the previous tag")
        if mode == 'tag' :
            parser.add_option("-c","--no-changelog", action="store_false", dest="changelog", default=True,
                              help="do not update changelog section in specfile when tagging")
            parser.add_option("-b","--build-branch", action="store", dest="build_branch", default=None,
                              help="specify a build branch; used for locating the *tags.mk files where adoption is to take place")
        if mode in [ 'tag', 'sync' ] :
            parser.add_option("-e","--editor", action="store", dest="editor", default=default_editor(),
                              help="specify editor")

        if mode in ['diff','version'] :
            parser.add_option("-W","--www", action="store", dest="www", default=False,
                              help="export diff in html format, e.g. -W trunk")

        if mode == 'diff' :
            parser.add_option("-l","--list", action="store_true", dest="list", default=False,
                              help="just list modules that exhibit differences")
            
        default_modules_list=os.path.dirname(sys.argv[0])+"/modules.list"
        parser.add_option("-a","--all",action="store_true",dest="all_modules",default=False,
                          help="run on all modules as found in {}".format(default_modules_list))
        parser.add_option("-f","--file",action="store",dest="modules_list",default=None,
                          help="run on all modules found in specified file")
        parser.add_option("-n","--dry-run",action="store_true",dest="dry_run",default=False,
                          help="dry run - shell commands are only displayed")
        parser.add_option("-t","--distrotags",action="callback",callback=Main.optparse_list, dest="distrotags",
                          default=[], nargs=1,type="string",
                          help="""specify distro-tags files, e.g. onelab-tags-4.2.mk
-- can be set multiple times, or use quotes""")

        parser.add_option("-w","--workdir", action="store", dest="workdir", 
                          default="{}/{}".format(os.getenv("HOME"),"modules"),
                          help="""name for dedicated working dir - defaults to ~/modules
** THIS MUST NOT ** be your usual working directory""")
        parser.add_option("-F","--fast-checks",action="store_true",dest="fast_checks",default=False,
                          help="skip safety checks, such as git pulls -- use with care")
        parser.add_option("-B","--build-module",action="store",dest="build_module",default=None,
                          help="specify a build module to owerride the one in the CONFIG")

        # default verbosity depending on function - temp
        verbose_modes= ['tag', 'sync', 'branch']
        
        if mode not in verbose_modes:
            parser.add_option("-v","--verbose", action="store_true", dest="verbose", default=False, 
                              help="run in verbose mode")
        else:
            parser.add_option("-q","--quiet", action="store_false", dest="verbose", default=True,
                              help="run in quiet (non-verbose) mode")
        options, args = parser.parse_args()
        options.mode=mode
        if not hasattr(options,'dry_run'):
            options.dry_run=False
        if not hasattr(options,'www'):
            options.www=False
        options.debug=False

        

        ########## module-*
        if len(args) == 0:
            if options.all_modules:
                options.modules_list=default_modules_list
            if options.modules_list:
                args=Command("grep -v '#' {}".format(options.modules_list), options).output_of().split()
            else:
                parser.print_help()
                sys.exit(1)
        Module.init_homedir(options)
        

        if mode in Main.regular_modes:
            modules = [ Module(modname, options) for modname in args ]
            # hack: create a dummy Module to store errors/warnings
            error_module = Module('__errors__',options)

            for module in modules:
                if len(args)>1 and mode not in Main.silent_modes:
                    if not options.www:
                        print('========================================', module.friendly_name())
                # call the method called do_<mode>
                method = Module.__dict__["do_{}".format(mode)]
                try:
                    method(module)
                except Exception as e:
                    if options.www:
                        title='<span class="error"> Skipping module {} - failure: {} </span>'\
                            .format(module.friendly_name(), str(e))
                        error_module.html_store_title(title)
                    else:
                        import traceback
                        traceback.print_exc()
                        print('Skipping module {}: {}'.format(module.name,e))
    
            if options.www:
                if mode == "diff":
                    modetitle="Changes to tag in {}".format(options.www)
                elif mode == "version":
                    modetitle="Latest tags in {}".format(options.www)
                modules.append(error_module)
                error_module.html_dump_header(modetitle)
                for module in modules:
                    module.html_dump_toc()
                Module.html_dump_middle()
                for module in modules:
                    module.html_dump_body()
                Module.html_dump_footer()
        else:
            # if we provide, say a b c d, we want to build (a,b) (b,c) and (c,d)
            # remember that the changelog in the twiki comes latest first, so
            # we typically have here latest latest-1 latest-2
            for (tag_new,tag_old) in zip ( args[:-1], args [1:]):
                release_changelog(options, tag_old, tag_new)
            
    
####################
if __name__ == "__main__" :
    try:
        Main().run()
    except KeyboardInterrupt:
        print('\nBye')
