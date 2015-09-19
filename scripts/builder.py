import os
import fnmatch
import glob
import types
import time
from os import path
from scripts.run import run

def get_sources_path(directory, pattern):
    """obtain path of all source files for a matching pattern"""
    matches = []
    for root, dirnames, filenames in os.walk(directory):
        for filename in filenames:
            full_path = os.path.join(root, filename)
            if fnmatch.filter([full_path], pattern):
                matches.append(os.path.join(root, filename))
    return matches
    
class Builder(object):
    """helper to generate tasks to compile vala code"""

    def __init__(self,
                 source_directory,
                 valac_command,
                 cc_command,
                 linker_command,
                 target_binary,
                 link = None,
                 dependencies = None):
        self.source_directory = source_directory
        self.valac_command = valac_command
        self.cc_command = cc_command
        self.linker_command = linker_command
        self.target_binary = target_binary
        self.link = link
        self.dependencies = dependencies

    def build(self):
        source_directory = self.source_directory
        valac_command = self.valac_command
        cc_command = self.cc_command
        linker_command = self.linker_command
        target_binary = self.target_binary
        
        if not self.dependencies == None:
            bindep = [path.join('build', 'bin', f) for f in self.dependencies]
        else:
            bindep = []
            
        copied_csource_paths = get_sources_path(source_directory, '*.c')
        copied_cheader_paths = get_sources_path(source_directory, '*.h')
        vala_source_paths = get_sources_path(source_directory, '*.vala')
        build_directory = path.join('build', source_directory)

        csource_files = [path.basename(f) for f in copied_csource_paths]
        generated_csource_paths = []
        for vala_path in vala_source_paths:
            vala_file = path.basename(vala_path)
            cfile = vala_file.replace('.vala', '.c')
            cpath = path.join(build_directory, cfile)
            generated_csource_paths.append(cpath)
            csource_files.append(cfile)
       
        build_file = path.join(build_directory, 'placeholder')
        yield {
            'basename': 'mkdir ' + build_directory,
            'actions': ['mkdir -p ' + path.join('build', 'bin'),
                        'mkdir -p ' + build_directory, 
                        '[ -e "' + build_file + '" ] || touch "' + build_file + '"'],
            'targets': [build_file],
        }
        
        copied_csources = []
        copied_cheader = [] 
        for csource in copied_cheader_paths + copied_csource_paths:
            dest = path.join(build_directory, path.basename(csource))
            
            if not dest[-2:] == ".h":
                copied_csources.append(dest)
            else:
                copied_cheader.append(dest)
                
            yield {
                'basename': 'copy ' + csource,
                'file_dep': [build_file] + [csource],
                'actions': ['cp ' + csource + ' ' + build_directory],
                'targets': [dest]
            }
        
        yield {
            'basename': 'valac ' + source_directory,
            'file_dep': [build_file] + vala_source_paths + bindep,
            'actions': [valac_command],
            'targets': generated_csource_paths
        }
               
        csource_paths = generated_csource_paths + copied_csources
        object_files = []
        
        for csource in csource_paths:
            object_file = path.basename (csource.replace('.c', '.o'))
            object_files.append(object_file);
             
            command = cc_command.replace('C_SOURCE', csource)
            object_path = path.join(build_directory, object_file)
            command = command.replace('OBJECT_FILE', object_path)
            yield {
                'basename': 'compile ' + path.basename(csource),
                'file_dep': [build_file, csource] + bindep + copied_cheader,
                'actions': [command],
                'targets': [path.join(build_directory, object_file)],
            }
            
        object_paths = [path.join(build_directory, f) for f in object_files] 
        yield {
            'basename': source_directory,
            'file_dep': object_paths + [build_file] + bindep,
            'actions': [linker_command],
            'targets': [path.join('build', 'bin', target_binary)]
        }

        if not self.link == None:
            createlink = 'cd build/bin/ && ln -s -f ' + target_binary + ' ' + self.link
            yield {
                'basename': 'Create link ' + target_binary + ' ' + self.link,
                'file_dep': [path.join('build', 'bin', target_binary)],
                'actions': [createlink],
                'targets': [path.join('build', 'bin', self.link)]
            }

def is_up_to_date(task):
    for target in task['targets']:
        if not path.isfile(target):
            return False

    if not 'file_dep' in task.keys():
        return False

    for dep in task['file_dep']:
        if not path.isfile(dep):
            print('Dependency is not created yet: ' + dep + ' needed for ' + task['targets'])
            exit(1)

    target_times = []
    for target in task['targets']:
        target_times.append(path.getmtime(target))
    target_times.sort()

    dependency_times = []
    for dependency in task['file_dep']:
        if not path.basename(dependency) == 'placeholder':
            dependency_times.append(path.getmtime(dependency))	
    dependency_times.sort()

    if len(dependency_times) == 0 or len(target_times) == 0:
        return False

    return dependency_times[-1] <= target_times[0]


def get_name(task):
    try:
	    return task['name']
    except KeyError:
        return task['basename']

def execute_task(task):
    if is_up_to_date(task):
        print(get_name(task) + ' - up to date.')
    else:
        for action in task['actions']:
            print(action)
            run(action)

def process_tasks(generator):
	for task in generator:
		if isinstance(task, types.GeneratorType):
			process_tasks(task)
		else:
			execute_task(task)

