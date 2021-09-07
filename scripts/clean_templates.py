import os
import glob

scripts_dir = os.path.dirname(os.path.abspath(__file__))
repo_root = os.path.abspath(os.path.join(scripts_dir, '..'))

def clean():
    p = os.path.join(repo_root,'**','*.j2')
    template_files = glob.glob(p)
    for template_file in template_files:
        tpath = os.path.abspath(template_file)
        tdir, tname = os.path.split(tpath)
        rname = tname[:-3]
        rpath = os.path.join(tdir, rname)

        print(f"Removing file {rpath}")
        os.remove(rpath)

    print("Done")

if __name__=="__main__":
    clean()
