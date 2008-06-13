#!/usr/bin/python -u

subversion_id = "$Id$"

import sys, os, os.path
import re
import time
from glob import glob
from optparse import OptionParser

# e.g. other_choices = [ ('d','iff') , ('g','uess') ] - lowercase 
def prompt (question,default=True,other_choices=[],allow_outside=False):
    if not isinstance (other_choices,list):
        other_choices = [ other_choices ]
    chars = [ c for (c,rest) in other_choices ]

    choices = []
    if 'y' not in chars:
        if default is True: choices.append('[y]')
        else : choices.append('y')
    if 'n' not in chars:
        if default is False: choices.append('[n]')
        else : choices.append('n')

    for (char,choice) in other_choices:
        if default == char:
            choices.append("["+char+"]"+choice)
        else:
            choices.append("<"+char+">"+choice)
    try:
        answer=raw_input(question + " " + "/".join(choices) + " ? ")
        if not answer:
            return default
        answer=answer[0].lower()
        if answer == 'y':
            if 'y' in chars: return 'y'
            else: return True
        elif answer == 'n':
            if 'n' in chars: return 'n'
            else: return False
        elif other_choices:
            for (char,choice) in other_choices:
                if answer == char:
                    return char
            if allow_outside:
                return answer
        return prompt(question,default,other_choices)
    except:
        raise

def default_editor():
    try:
        editor = os.environ['EDITOR']
    except:
        editor = "emacs"
    return editor

class Command:
    def __init__ (self,command,options):
        self.command=command
        self.options=options
        self.tmp="/tmp/command-%d"%os.getpid()

    def run (self):
        if self.options.verbose and self.options.mode not in Main.silent_modes:
            print '+',self.command
            sys.stdout.flush()
        return os.system(self.command)

    def run_silent (self):
        if self.options.verbose:
            print '+',self.command,' .. ',
            sys.stdout.flush()
        retcod=os.system(self.command + " &> " + self.tmp)
        if retcod != 0:
            print "FAILED ! -- out+err below (command was %s)"%self.command
            os.system("cat " + self.tmp)
            print "FAILED ! -- end of quoted output"
        elif self.options.verbose:
            print "OK"
        os.unlink(self.tmp)
        return retcod

    def run_fatal(self):
        if self.run_silent() !=0:
            raise Exception,"Command %s failed"%self.command

    # returns stdout, like bash's $(mycommand)
    def output_of (self,with_stderr=False):
        tmp="/tmp/status-%d"%os.getpid()
        if self.options.debug:
            print '+',self.command,' .. ',
            sys.stdout.flush()
        command=self.command
        if with_stderr:
            command += " &> "
        else:
            command += " > "
        command += tmp
        os.system(command)
        result=file(tmp).read()
        os.unlink(tmp)
        if self.options.debug:
            print 'Done',
        return result

class Svnpath:
    def __init__(self,path,options):
        self.path=path
        self.options=options

    def url_exists (self):
        return os.system("svn list %s &> /dev/null"%self.path) == 0

    def dir_needs_revert (self):
        command="svn status %s"%self.path
        return len(Command(command,self.options).output_of(True)) != 0
    # turns out it's the same implem.
    def file_needs_commit (self):
        command="svn status %s"%self.path
        return len(Command(command,self.options).output_of(True)) != 0

class Module:

    svn_magic_line="--This line, and those below, will be ignored--"
    
    redirectors=[ # ('module_name_varname','name'),
                  ('module_version_varname','version'),
                  ('module_taglevel_varname','taglevel'), ]

    # where to store user's config
    config_storage="CONFIG"
    # 
    config={}

    import commands
    configKeys=[ ('svnpath',"Enter your toplevel svnpath",
                  "svn+ssh://%s@svn.planet-lab.org/svn/"%commands.getoutput("id -un")),
                 ("build", "Enter the name of your build module","build"),
                 ('username',"Enter your firstname and lastname for changelogs",""),
                 ("email","Enter your email address for changelogs",""),
                 ]

    @staticmethod
    def prompt_config ():
        for (key,message,default) in Module.configKeys:
            Module.config[key]=""
            while not Module.config[key]:
                Module.config[key]=raw_input("%s [%s] : "%(message,default)).strip() or default


    # for parsing module spec name:branch
    matcher_branch_spec=re.compile("\A(?P<name>[\w-]+):(?P<branch>[\w\.-]+)\Z")
    matcher_rpm_define=re.compile("%(define|global)\s+(\S+)\s+(\S*)\s*")

    def __init__ (self,module_spec,options):
        # parse module spec
        attempt=Module.matcher_branch_spec.match(module_spec)
        if attempt:
            self.name=attempt.group('name')
            self.branch=attempt.group('branch')
        else:
            self.name=module_spec
            self.branch=None

        self.options=options
        self.moddir="%s/%s"%(options.workdir,self.name)

    def friendly_name (self):
        if not self.branch:
            return self.name
        else:
            return "%s:%s"%(self.name,self.branch)

    def edge_dir (self):
        if not self.branch:
            return "%s/trunk"%(self.moddir)
        else:
            return "%s/branches/%s"%(self.moddir,self.branch)

    def tags_dir (self):
        return "%s/tags"%(self.moddir)

    def run (self,command):
        return Command(command,self.options).run()
    def run_fatal (self,command):
        return Command(command,self.options).run_fatal()
    def run_prompt (self,message,command):
        if not self.options.verbose:
            while True:
                choice=prompt(message,True,('s','how'))
                if choice is True:
                    self.run(command)
                    return
                elif choice is False:
                    return
                else:
                    print 'About to run:',command
        else:
            question=message+" - want to run " + command
            if prompt(question,True):
                self.run(command)            

    @staticmethod
    def init_homedir (options):
        topdir=options.workdir
        if options.verbose and options.mode not in Main.silent_modes:
            print 'Checking for',topdir
        storage="%s/%s"%(topdir,Module.config_storage)
        # sanity check. Either the topdir exists AND we have a config/storage
        # or topdir does not exist and we create it
        # to avoid people use their own daily svn repo
        if os.path.isdir(topdir) and not os.path.isfile(storage):
            print """The directory %s exists and has no CONFIG file
If this is your regular working directory, please provide another one as the
module-* commands need a fresh working dir. Make sure that you do not use 
that for other purposes than tagging"""%topdir
            sys.exit(1)
        if not os.path.isdir (topdir):
            print "Cannot find",topdir,"let's create it"
            Module.prompt_config()
            print "Checking ...",
            Command("svn co -N %s %s"%(Module.config['svnpath'],topdir),options).run_fatal()
            Command("svn co -N %s/%s %s/%s"%(Module.config['svnpath'],
                                             Module.config['build'],
                                             topdir,
                                             Module.config['build']),options).run_fatal()
            print "OK"
            
            # store config
            f=file(storage,"w")
            for (key,message,default) in Module.configKeys:
                f.write("%s=%s\n"%(key,Module.config[key]))
            f.close()
            if options.debug:
                print 'Stored',storage
                Command("cat %s"%storage,options).run()
        else:
            # read config
            f=open(storage)
            for line in f.readlines():
                (key,value)=re.compile("^(.+)=(.+)$").match(line).groups()
                Module.config[key]=value                
            f.close()
        if options.verbose and options.mode not in Main.silent_modes:
            print '******** Using config'
            for (key,message,default) in Module.configKeys:
                print '\t',key,'=',Module.config[key]

    def init_moddir (self):
        if self.options.verbose:
            print 'Checking for',self.moddir
        if not os.path.isdir (self.moddir):
            self.run_fatal("svn up -N %s"%self.moddir)
        if not os.path.isdir (self.moddir):
            raise Exception, 'Cannot find %s - check module name'%self.moddir

    def init_subdir (self,fullpath):
        if self.options.verbose:
            print 'Checking for',fullpath
        if not os.path.isdir (fullpath):
            self.run_fatal("svn up -N %s"%fullpath)

    def revert_subdir (self,fullpath):
        if self.options.fast_checks:
            if self.options.verbose: print 'Skipping revert of %s'%fullpath
            return
        if self.options.verbose:
            print 'Checking whether',fullpath,'needs being reverted'
        if Svnpath(fullpath,self.options).dir_needs_revert():
            self.run_fatal("svn revert -R %s"%fullpath)

    def update_subdir (self,fullpath):
        if self.options.fast_checks:
            if self.options.verbose: print 'Skipping update of %s'%fullpath
            return
        if self.options.verbose:
            print 'Updating',fullpath
        self.run_fatal("svn update -N %s"%fullpath)

    def init_edge_dir (self):
        # if branch, edge_dir is two steps down
        if self.branch:
            self.init_subdir("%s/branches"%self.moddir)
        self.init_subdir(self.edge_dir())

    def revert_edge_dir (self):
        self.revert_subdir(self.edge_dir())

    def update_edge_dir (self):
        self.update_subdir(self.edge_dir())

    def main_specname (self):
        attempt="%s/%s.spec"%(self.edge_dir(),self.name)
        if os.path.isfile (attempt):
            return attempt
        else:
            try:
                return glob("%s/*.spec"%self.edge_dir())[0]
            except:
                raise Exception, 'Cannot guess specfile for module %s'%self.name

    def all_specnames (self):
        return glob("%s/*.spec"%self.edge_dir())

    def parse_spec (self, specfile, varnames):
        if self.options.verbose:
            print 'Parsing',specfile,
            for var in varnames:
                print "[%s]"%var,
            print ""
        result={}
        f=open(specfile)
        for line in f.readlines():
            attempt=Module.matcher_rpm_define.match(line)
            if attempt:
                (define,var,value)=attempt.groups()
                if var in varnames:
                    result[var]=value
        f.close()
        if self.options.debug:
            print 'found',len(result),'keys'
            for (k,v) in result.iteritems():
                print k,'=',v
        return result
                
    # stores in self.module_name_varname the rpm variable to be used for the module's name
    # and the list of these names in self.varnames
    def spec_dict (self):
        specfile=self.main_specname()
        redirector_keys = [ varname for (varname,default) in Module.redirectors]
        redirect_dict = self.parse_spec(specfile,redirector_keys)
        if self.options.debug:
            print '1st pass parsing done, redirect_dict=',redirect_dict
        varnames=[]
        for (varname,default) in Module.redirectors:
            if redirect_dict.has_key(varname):
                setattr(self,varname,redirect_dict[varname])
                varnames += [redirect_dict[varname]]
            else:
                setattr(self,varname,default)
                varnames += [ default ] 
        self.varnames = varnames
        result = self.parse_spec (specfile,self.varnames)
        if self.options.debug:
            print '2st pass parsing done, varnames=',varnames,'result=',result
        return result

    def patch_spec_var (self, patch_dict,define_missing=False):
        for specfile in self.all_specnames():
            # record the keys that were changed
            changed = dict ( [ (x,False) for x in patch_dict.keys() ] )
            newspecfile=specfile+".new"
            if self.options.verbose:
                print 'Patching',specfile,'for',patch_dict.keys()
            spec=open (specfile)
            new=open(newspecfile,"w")

            for line in spec.readlines():
                attempt=Module.matcher_rpm_define.match(line)
                if attempt:
                    (define,var,value)=attempt.groups()
                    if var in patch_dict.keys():
                        if self.options.debug:
                            print 'rewriting %s as %s'%(var,patch_dict[var])
                        new.write('%%%s %s %s\n'%(define,var,patch_dict[var]))
                        changed[var]=True
                        continue
                new.write(line)
            if define_missing:
                for (key,was_changed) in changed.iteritems():
                    if not was_changed:
                        if self.options.debug:
                            print 'rewriting missing %s as %s'%(key,patch_dict[key])
                        new.write('\n%%define %s %s\n'%(key,patch_dict[key]))
            spec.close()
            new.close()
            os.rename(newspecfile,specfile)

    def unignored_lines (self, logfile):
        result=[]
        exclude="Tagging module %s"%self.name
        for logline in file(logfile).readlines():
            if logline.strip() == Module.svn_magic_line:
                break
            if logline.find(exclude) < 0:
                result += [ logline ]
        return result

    def insert_changelog (self, logfile, oldtag, newtag):
        for specfile in self.all_specnames():
            newspecfile=specfile+".new"
            if self.options.verbose:
                print 'Inserting changelog from %s into %s'%(logfile,specfile)
            spec=open (specfile)
            new=open(newspecfile,"w")
            for line in spec.readlines():
                new.write(line)
                if re.compile('%changelog').match(line):
                    dateformat="* %a %b %d %Y"
                    datepart=time.strftime(dateformat)
                    logpart="%s <%s> - %s"%(Module.config['username'],
                                                 Module.config['email'],
                                                 newtag)
                    new.write(datepart+" "+logpart+"\n")
                    for logline in self.unignored_lines(logfile):
                        new.write("- " + logline)
                    new.write("\n")
            spec.close()
            new.close()
            os.rename(newspecfile,specfile)
            
    def show_dict (self, spec_dict):
        if self.options.verbose:
            for (k,v) in spec_dict.iteritems():
                print k,'=',v

    def mod_url (self):
        return "%s/%s"%(Module.config['svnpath'],self.name)

    def edge_url (self):
        if not self.branch:
            return "%s/trunk"%(self.mod_url())
        else:
            return "%s/branches/%s"%(self.mod_url(),self.branch)

    def tag_name (self, spec_dict):
        try:
            return "%s-%s-%s"%(#spec_dict[self.module_name_varname],
                self.name,
                spec_dict[self.module_version_varname],
                spec_dict[self.module_taglevel_varname])
        except KeyError,err:
            raise Exception, 'Something is wrong with module %s, cannot determine %s - exiting'%(self.name,err)

    def tag_url (self, spec_dict):
        return "%s/tags/%s"%(self.mod_url(),self.tag_name(spec_dict))

    def check_svnpath_exists (self, url, message):
        if self.options.fast_checks:
            return
        if self.options.verbose:
            print 'Checking url (%s) %s'%(url,message),
        ok=Svnpath(url,self.options).url_exists()
        if ok:
            if self.options.verbose: print 'exists - OK'
        else:
            if self.options.verbose: print 'KO'
            raise Exception, 'Could not find %s URL %s'%(message,url)

    def check_svnpath_not_exists (self, url, message):
        if self.options.fast_checks:
            return
        if self.options.verbose:
            print 'Checking url (%s) %s'%(url,message),
        ok=not Svnpath(url,self.options).url_exists()
        if ok:
            if self.options.verbose: print 'does not exist - OK'
        else:
            if self.options.verbose: print 'KO'
            raise Exception, '%s URL %s already exists - exiting'%(message,url)

    # locate specfile, parse it, check it and show values

##############################
    def do_version (self):
        self.init_moddir()
        self.init_edge_dir()
        self.revert_edge_dir()
        self.update_edge_dir()
        spec_dict = self.spec_dict()
        for varname in self.varnames:
            if not spec_dict.has_key(varname):
                print 'Could not find %%define for %s'%varname
                return
            else:
                print "%-16s %s"%(varname,spec_dict[varname])
        if self.options.show_urls:
            print "%-16s %s"%('edge url',self.edge_url())
            print "%-16s %s"%('latest tag url',self.tag_url(spec_dict))
        if self.options.verbose:
            print "%-16s %s"%('main specfile:',self.main_specname())
            print "%-16s %s"%('specfiles:',self.all_specnames())

##############################
    def do_list (self):
#        print 'verbose',self.options.verbose
#        print 'list_tags',self.options.list_tags
#        print 'list_branches',self.options.list_branches
#        print 'all_modules',self.options.all_modules
        
        (verbose,branches,pattern,exact) = (self.options.verbose,self.options.list_branches,
                                            self.options.list_pattern,self.options.list_exact)

        extra_command=""
        extra_message=""
        if self.branch:
            pattern=self.branch
        if pattern or exact:
            if exact:
                if verbose: grep="%s/$"%exact
                else: grep="^%s$"%exact
            else:
                grep=pattern
            extra_command=" | grep %s"%grep
            extra_message=" matching %s"%grep

        if not branches:
            message="==================== tags for %s"%self.friendly_name()
            command="svn list "
            if verbose: command+="--verbose "
            command += "%s/tags"%self.mod_url()
            command += extra_command
            message += extra_message
            if verbose: print message
            self.run(command)

        else:
            message="==================== branches for %s"%self.friendly_name()
            command="svn list "
            if verbose: command+="--verbose "
            command += "%s/branches"%self.mod_url()
            command += extra_command
            message += extra_message
            if verbose: print message
            self.run(command)

##############################
    sync_warning="""*** WARNING
The module-init function has the following limitations
* it does not handle changelogs
* it does not scan the -tags*.mk files to adopt the new tags"""

    def do_sync(self):
        if self.options.verbose:
            print Module.sync_warning
            if not prompt('Want to proceed anyway'):
                return

        self.init_moddir()
        self.init_edge_dir()
        self.revert_edge_dir()
        self.update_edge_dir()
        spec_dict = self.spec_dict()

        edge_url=self.edge_url()
        tag_name=self.tag_name(spec_dict)
        tag_url=self.tag_url(spec_dict)
        # check the tag does not exist yet
        self.check_svnpath_not_exists(tag_url,"new tag")

        if self.options.message:
            svnopt='--message "%s"'%self.options.message
        else:
            svnopt='--editor-cmd=%s'%self.options.editor
        self.run_prompt("Create initial tag",
                        "svn copy %s %s %s"%(svnopt,edge_url,tag_url))

##############################
    def do_diff (self,compute_only=False):
        self.init_moddir()
        self.init_edge_dir()
        self.revert_edge_dir()
        self.update_edge_dir()
        spec_dict = self.spec_dict()
        self.show_dict(spec_dict)

        edge_url=self.edge_url()
        tag_url=self.tag_url(spec_dict)
        self.check_svnpath_exists(edge_url,"edge track")
        self.check_svnpath_exists(tag_url,"latest tag")
        command="svn diff %s %s"%(tag_url,edge_url)
        if compute_only:
            if self.options.verbose:
                print 'Getting diff with %s'%command
        diff_output = Command(command,self.options).output_of()
        # if used as a utility
        if compute_only:
            return (spec_dict,edge_url,tag_url,diff_output)
        # otherwise print the result
        if self.options.list:
            if diff_output:
                print self.name
        else:
            if not self.options.only or diff_output:
                print 'x'*30,'module',self.friendly_name()
                print 'x'*20,'<',tag_url
                print 'x'*20,'>',edge_url
                print diff_output

##############################
    # using fine_grain means replacing only those instances that currently refer to this tag
    # otherwise, <module>-SVNPATH is replaced unconditionnally
    def patch_tags_file (self, tagsfile, oldname, newname,fine_grain=True):
        newtagsfile=tagsfile+".new"
        tags=open (tagsfile)
        new=open(newtagsfile,"w")

        matches=0
        # fine-grain : replace those lines that refer to oldname
        if fine_grain:
            if self.options.verbose:
                print 'Replacing %s into %s\n\tin %s .. '%(oldname,newname,tagsfile),
            matcher=re.compile("^(.*)%s(.*)"%oldname)
            for line in tags.readlines():
                if not matcher.match(line):
                    new.write(line)
                else:
                    (begin,end)=matcher.match(line).groups()
                    new.write(begin+newname+end+"\n")
                    matches += 1
        # brute-force : change uncommented lines that define <module>-SVNPATH
        else:
            if self.options.verbose:
                print 'Setting %s-SVNPATH for using %s\n\tin %s .. '%(self.name,newname,tagsfile),
            pattern="\A\s*%s-SVNPATH\s*(=|:=)\s*(?P<url_main>[^\s]+)/%s/[^\s]+"\
                                          %(self.name,self.name)
            matcher_module=re.compile(pattern)
            for line in tags.readlines():
                attempt=matcher_module.match(line)
                if attempt:
                    svnpath="%s-SVNPATH"%self.name
                    replacement = "%-32s:= %s/%s/tags/%s\n"%(svnpath,attempt.group('url_main'),self.name,newname)
                    new.write(replacement)
                    matches += 1
                else:
                    new.write(line)
        tags.close()
        new.close()
        os.rename(newtagsfile,tagsfile)
        if self.options.verbose: print "%d changes"%matches
        return matches

    def do_tag (self):
        self.init_moddir()
        self.init_edge_dir()
        self.revert_edge_dir()
        self.update_edge_dir()
        # parse specfile
        spec_dict = self.spec_dict()
        self.show_dict(spec_dict)
        
        # side effects
        edge_url=self.edge_url()
        old_tag_name = self.tag_name(spec_dict)
        old_tag_url=self.tag_url(spec_dict)
        if (self.options.new_version):
            # new version set on command line
            spec_dict[self.module_version_varname] = self.options.new_version
            spec_dict[self.module_taglevel_varname] = 0
        else:
            # increment taglevel
            new_taglevel = str ( int (spec_dict[self.module_taglevel_varname]) + 1)
            spec_dict[self.module_taglevel_varname] = new_taglevel

        # sanity check
        new_tag_name = self.tag_name(spec_dict)
        new_tag_url=self.tag_url(spec_dict)
        self.check_svnpath_exists (edge_url,"edge track")
        self.check_svnpath_exists (old_tag_url,"previous tag")
        self.check_svnpath_not_exists (new_tag_url,"new tag")

        # checking for diffs
        diff_output=Command("svn diff %s %s"%(old_tag_url,edge_url),
                            self.options).output_of()
        if len(diff_output) == 0:
            if not prompt ("No difference in trunk for module %s, want to tag anyway"%self.name,False):
                return

        # side effect in trunk's specfile
        self.patch_spec_var(spec_dict)

        # prepare changelog file 
        # we use the standard subversion magic string (see svn_magic_line)
        # so we can provide useful information, such as version numbers and diff
        # in the same file
        changelog="/tmp/%s-%d.txt"%(self.name,os.getpid())
        file(changelog,"w").write("""Tagging module %s - %s

%s
Please write a changelog for this new tag in the section above
"""%(self.name,new_tag_name,Module.svn_magic_line))

        if not self.options.verbose or prompt('Want to see diffs while writing changelog',True):
            file(changelog,"a").write('DIFF=========\n' + diff_output)
        
        if self.options.debug:
            prompt('Proceed ?')

        # edit it        
        self.run("%s %s"%(self.options.editor,changelog))
        # insert changelog in spec
        if self.options.changelog:
            self.insert_changelog (changelog,old_tag_name,new_tag_name)

        ## update build
        try:
            buildname=Module.config['build']
        except:
            buildname="build"
        if self.options.build_branch:
            buildname+=":"+self.options.build_branch
        build = Module(buildname,self.options)
        build.init_moddir()
        build.init_edge_dir()
        build.revert_edge_dir()
        build.update_edge_dir()
        
        tagsfiles=glob(build.edge_dir()+"/*-tags*.mk")
        tagsdict=dict( [ (x,'todo') for x in tagsfiles ] )
        default_answer = 'y'
        while True:
            for (tagsfile,status) in tagsdict.iteritems():
                basename=os.path.basename(tagsfile)
                print ".................... Dealing with %s"%basename
                while tagsdict[tagsfile] == 'todo' :
                    choice = prompt ("insert %s in %s    "%(new_tag_name,basename),default_answer,
                                     [ ('y','es'), ('n', 'ext'), ('f','orce'), 
                                       ('d','iff'), ('r','evert'), ('h','elp') ] ,
                                     allow_outside=True)
                    if choice == 'y':
                        self.patch_tags_file(tagsfile,old_tag_name,new_tag_name,fine_grain=True)
                    elif choice == 'n':
                        print 'Done with %s'%os.path.basename(tagsfile)
                        tagsdict[tagsfile]='done'
                    elif choice == 'f':
                        self.patch_tags_file(tagsfile,old_tag_name,new_tag_name,fine_grain=False)
                    elif choice == 'd':
                        self.run("svn diff %s"%tagsfile)
                    elif choice == 'r':
                        self.run("svn revert %s"%tagsfile)
                    else:
                        name=self.name
                        print """y: change %(name)s-SVNPATH only if it currently refers to %(old_tag_name)s
f: unconditionnally change any line setting %(name)s-SVNPATH to using %(new_tag_name)s
d: show current diff for this tag file
r: revert that tag file
n: move to next file"""%locals()

            if prompt("Want to review changes on tags files",False):
                tagsdict = dict ( [ (x, 'todo') for tagsfile in tagsfiles ] )
                default_answer='d'
            else:
                break

        paths=""
        paths += self.edge_dir() + " "
        paths += build.edge_dir() + " "
        self.run_prompt("Review trunk and build","svn diff " + paths)
        self.run_prompt("Commit trunk and build","svn commit --file %s %s"%(changelog,paths))
        self.run_prompt("Create tag","svn copy --file %s %s %s"%(changelog,edge_url,new_tag_url))

        if self.options.debug:
            print 'Preserving',changelog
        else:
            os.unlink(changelog)
            
##############################
    def do_branch (self):

        # save self.branch if any, as a hint for the new branch 
        # do this before anything else and restore .branch to None, 
        # as this is part of the class's logic
        new_trunk_name=None
        if self.branch:
            new_trunk_name=self.branch
            self.branch=None

        # compute diff - a way to initialize the whole stuff
        # do_diff already does edge_dir initialization
        # and it checks that edge_url and tag_url exist as well
        (spec_dict,edge_url,tag_url,diff_listing) = self.do_diff(compute_only=True)

        # the version name in the trunk becomes the new branch name
        branch_name = spec_dict[self.module_version_varname]

        # figure new branch name (the one for the trunk) if not provided on the command line
        if not new_trunk_name:
            # heuristic is to assume 'version' is a dot-separated name
            # we isolate the rightmost part and try incrementing it by 1
            version=spec_dict[self.module_version_varname]
            try:
                m=re.compile("\A(?P<leftpart>.+)\.(?P<rightmost>[^\.]+)\Z")
                (leftpart,rightmost)=m.match(version).groups()
                incremented = int(rightmost)+1
                new_trunk_name="%s.%d"%(leftpart,incremented)
            except:
                raise Exception, 'Cannot figure next branch name from %s - exiting'%version

        # record starting point tagname
        latest_tag_name = self.tag_name(spec_dict)

        print "**********"
        print "Using starting point %s (%s)"%(tag_url,latest_tag_name)
        print "Creating branch %s  &  moving trunk to %s"%(branch_name,new_trunk_name)
        print "**********"

        # print warning if pending diffs
        if diff_listing:
            print """*** WARNING : Module %s has pending diffs on its trunk
It is safe to proceed, but please note that branch %s
will be based on latest tag %s and *not* on the current trunk"""%(self.name,branch_name,latest_tag_name)
            while True:
                answer = prompt ('Are you sure you want to proceed with branching',True,('d','iff'))
                if answer is True:
                    break
                elif answer is False:
                    raise Exception,"User quit"
                elif answer == 'd':
                    print '<<<< %s'%tag_url
                    print '>>>> %s'%edge_url
                    print diff_listing

        branch_url = "%s/%s/branches/%s"%(Module.config['svnpath'],self.name,branch_name)
        self.check_svnpath_not_exists (branch_url,"new branch")
        
        # patching trunk
        spec_dict[self.module_version_varname]=new_trunk_name
        spec_dict[self.module_taglevel_varname]='0'
        # remember this in the trunk for easy location of the current branch
        spec_dict['module_current_branch']=branch_name
        self.patch_spec_var(spec_dict,True)
        
        # create commit log file
        tmp="/tmp/branching-%d"%os.getpid()
        f=open(tmp,"w")
        f.write("Branch %s for module %s created from tag %s\n"%(new_trunk_name,self.name,latest_tag_name))
        f.close()

        # we're done, let's commit the stuff
        command="svn diff %s"%self.edge_dir()
        self.run_prompt("Review changes in trunk",command)
        command="svn copy --file %s %s %s"%(tmp,self.edge_url(),branch_url)
        self.run_prompt("Create branch",command)
        command="svn commit --file %s %s"%(tmp,self.edge_dir())
        self.run_prompt("Commit trunk",command)
        new_tag_url=self.tag_url(spec_dict)
        command="svn copy --file %s %s %s"%(tmp,self.edge_url(),new_tag_url)
        self.run_prompt("Create initial tag in trunk",command)
        os.unlink(tmp)

##############################
class Main:

    usage="""Usage: %prog options module_desc [ .. module_desc ]
Purpose:
  manage subversion tags and specfile
  requires the specfile to define *version* and *taglevel*
  OR alternatively 
  redirection variables module_version_varname / module_taglevel_varname
Trunk:
  by default, the trunk of modules is taken into account
  in this case, just mention the module name as <module_desc>
Branches:
  if you wish to work on a branch rather than on the trunk, 
  you can use something like e.g. Mom:2.1 as <module_desc>
More help:
  see http://svn.planet-lab.org/wiki/ModuleTools
"""

    modes={ 
        'list' : "displays a list of available tags or branches",
        'version' : "check latest specfile and print out details",
        'diff' : "show difference between trunk and latest tag",
        'tag'  : """increment taglevel in specfile, insert changelog in specfile,
                create new tag and and monitor its adoption in build/*-tags*.mk""",
        'branch' : """create a branch for this module, from the latest tag on the trunk, 
                  and change trunk's version number to reflect the new branch name;
                  you can specify the new branch name by using module:branch""",
        'sync' : """create a tag from the trunk
                this is a last resort option, mostly for repairs""",
        }

    silent_modes = ['list']

    def run(self):

        mode=None
        for function in Main.modes.keys():
            if sys.argv[0].find(function) >= 0:
                mode = function
                break
        if not mode:
            print "Unsupported command",sys.argv[0]
            sys.exit(1)

        Main.usage += "\nmodule-%s : %s"%(mode,Main.modes[mode])
        all_modules=os.path.dirname(sys.argv[0])+"/modules.list"

        parser=OptionParser(usage=Main.usage,version=subversion_id)
        
        if mode == 'list':
            parser.add_option("-b","--branches",action="store_true",dest="list_branches",default=False,
                              help="list branches")
            parser.add_option("-t","--tags",action="store_false",dest="list_branches",
                              help="list tags")
            parser.add_option("-m","--match",action="store",dest="list_pattern",default=None,
                               help="grep pattern for filtering output")
            parser.add_option("-x","--exact-match",action="store",dest="list_exact",default=None,
                               help="exact grep pattern for filtering output")
        if mode == "tag" or mode == 'branch':
            parser.add_option("-s","--set-version",action="store",dest="new_version",default=None,
                              help="set new version and reset taglevel to 0")
        if mode == "tag" :
            parser.add_option("-c","--no-changelog", action="store_false", dest="changelog", default=True,
                              help="do not update changelog section in specfile when tagging")
            parser.add_option("-b","--build-branch", action="store", dest="build_branch", default=None,
                              help="specify a build branch; used for locating the *tags*.mk files where adoption is to take place")
        if mode == "tag" or mode == "sync" :
            parser.add_option("-e","--editor", action="store", dest="editor", default=default_editor(),
                              help="specify editor")
        if mode == "sync" :
            parser.add_option("-m","--message", action="store", dest="message", default=None,
                              help="specify log message")
        if mode == "diff" :
            parser.add_option("-o","--only", action="store_true", dest="only", default=False,
                              help="report diff only for modules that exhibit differences")
        if mode == "diff" :
            parser.add_option("-l","--list", action="store_true", dest="list", default=False,
                              help="just list modules that exhibit differences")

        if mode  == 'version':
            parser.add_option("-u","--url", action="store_true", dest="show_urls", default=False,
                              help="display URLs")
            
        # default verbosity depending on function - temp
        parser.add_option("-a","--all",action="store_true",dest="all_modules",default=False,
                          help="run on all modules as found in %s"%all_modules)
        verbose_default=False
        if mode in ['tag','sync'] : verbose_default = True
        parser.add_option("-v","--verbose", action="store_true", dest="verbose", default=verbose_default, 
                          help="run in verbose mode")
        if mode not in ['version','list']:
            parser.add_option("-q","--quiet", action="store_false", dest="verbose", 
                              help="run in quiet (non-verbose) mode")
        parser.add_option("-w","--workdir", action="store", dest="workdir", 
                          default="%s/%s"%(os.getenv("HOME"),"modules"),
                          help="""name for dedicated working dir - defaults to ~/modules
** THIS MUST NOT ** be your usual working directory""")
        parser.add_option("-f","--fast-checks",action="store_true",dest="fast_checks",default=False,
                          help="skip safety checks, such as svn updates -- use with care")
        parser.add_option("-d","--debug", action="store_true", dest="debug", default=False, 
                          help="debug mode - mostly more verbose")
        (options, args) = parser.parse_args()
        options.mode=mode

        if len(args) == 0:
            if options.all_modules:
                args=Command("grep -v '#' %s"%all_modules,options).output_of().split()
            else:
                parser.print_help()
                sys.exit(1)
        Module.init_homedir(options)
        for modname in args:
            module=Module(modname,options)
            if len(args)>1 and mode not in Main.silent_modes:
                print '========================================',module.friendly_name()
            # call the method called do_<mode>
            method=Module.__dict__["do_%s"%mode]
            try:
                method(module)
            except Exception,e:
                print 'Skipping failed %s: '%modname,e

if __name__ == "__main__" :
    try:
        Main().run()
    except KeyboardInterrupt:
        print '\nBye'
        
