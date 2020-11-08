
import argparse
import glob
import yaml
import pathlib


def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--src",
    )
    parser.add_argument(
        "--dst",
    )
    args = parser.parse_args()
    return args


def sanitize_title(title):
    """
    https://stackoverflow.com/a/61448658/1804173
    https://stackoverflow.com/a/9847306/1804173
    """
    pseudo_slash = "∕"
    return title\
        .replace(pseudo_slash, pseudo_slash+pseudo_slash)\
        .replace("/", pseudo_slash)\
        .replace("\n", " ")


def convert(src, dst):
    files = glob.glob(f"{src}/**/note.yaml")

    num_copied = 0

    for f in files:
        meta = yaml.load(open(f), Loader=yaml.FullLoader)

        title = meta["title"]
        title_sanitized = sanitize_title(title)

        notes_file = f.replace(".yaml", ".md")
        notes_file_content = open(notes_file).read()

        file_dst = pathlib.Path(f"{dst}/notes/{title_sanitized}.md")
        file_dst.parent.mkdir(parents=True, exist_ok=True)

        print(f"{notes_file} => {file_dst}")
        try:
            with open(file_dst, "w") as out_file:
                out_file.write(notes_file_content)
        except OSError as e:
            print(e)
            continue

        file_dst = pathlib.Path(f"{dst}/.notemarks/notes/{title_sanitized}.yaml")
        file_dst.parent.mkdir(parents=True, exist_ok=True)

        print(f"{notes_file} => {file_dst}")
        try:
            with open(file_dst, "w") as out_file:
                yaml.dump({
                    "labels": meta["labels"],
                    "timeCreated": meta["timeCreated"],
                    "timeUpdated": meta["timeUpdated"],
                }, out_file)
        except OSError as e:
            print(e)
            continue

        num_copied += 1

    print(f"Num copied: {num_copied}")


def main():
    args = parse_args()
    convert(args.src, args.dst)


if __name__ == "__main__":
    main()
