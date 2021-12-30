import os
import glob

scripts_dir = os.path.dirname(os.path.abspath(__file__))
repo_root = os.path.abspath(os.path.join(scripts_dir, '..'))

def clean():
    p = os.path.join(repo_root,'**','*.j2')
    template_files = glob.glob(p, recursive=True)
    for template_file in template_files:
        tpath = os.path.abspath(template_file)
        tdir, tname = os.path.split(tpath)
        rname = tname[:-3]
        rpath = os.path.join(tdir, rname)

        ignore_list = ['environment']

        if os.path.exists(rpath) and rname not in ignore_list:
            print(f"Removing file {rpath}")
            os.remove(rpath)
        else:
            print(f"Skipping file {rpath}")

    print("Done")

if __name__=="__main__":
    clean()
