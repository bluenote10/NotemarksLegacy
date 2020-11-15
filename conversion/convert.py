
import argparse
import datetime
import glob
import yaml
import pathlib


LINK_TEMPLATE = """\
[Desktop Entry]
Encoding=UTF-8
Name={name}
Type=Link
URL={url}
Icon=text-html
"""


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


def _handle_note(dst, title_sanitized, meta, notes_file_content):
    if len(notes_file_content) > 0:
        rel_path = f"notes/{title_sanitized}.md"
        file_dst = pathlib.Path(f"{dst}/{rel_path}")
        file_dst.parent.mkdir(parents=True, exist_ok=True)

        with open(file_dst, "w") as out_file:
            out_file.write(notes_file_content)

        _handle_meta(dst, rel_path, meta)


def _handle_link(dst, title_sanitized, meta):
    link = meta.get("link")
    title = meta["title"]
    if link is not None and link.strip() != "":

        rel_path = f"links/{title_sanitized}.desktop"
        file_dst = pathlib.Path(f"{dst}/{rel_path}")
        file_dst.parent.mkdir(parents=True, exist_ok=True)

        with open(file_dst, "w") as out_file:
            out_file.write(LINK_TEMPLATE.format(url=link, name=title))

        _handle_meta(dst, rel_path, meta)


def _transform_timestamp_to_date_string(timestamp):
    date = datetime.datetime.fromtimestamp(timestamp)
    return date.strftime("%Y-%m-%dT%H:%M:%S")


def _handle_meta(dst, rel_path, meta):
    file_dst = pathlib.Path(f"{dst}/.notemarks/{rel_path}.yaml")
    file_dst.parent.mkdir(parents=True, exist_ok=True)

    with open(file_dst, "w") as out_file:
        yaml.dump({
            "labels": meta["labels"],
            "timeCreated": _transform_timestamp_to_date_string(meta["timeCreated"]),
            "timeUpdated": _transform_timestamp_to_date_string(meta["timeUpdated"]),
        }, out_file)


def convert(src, dst):
    files = glob.glob(f"{src}/**/note.yaml")

    num_copied = 0

    for f in files:
        meta = yaml.load(open(f), Loader=yaml.FullLoader)

        title = meta["title"]
        title_sanitized = sanitize_title(title)

        notes_file = f.replace(".yaml", ".md")
        notes_file_content = open(notes_file).read()

        print(f"Processing: {title}")

        if len(title_sanitized) > 255 - 5:
            print("Skipping because of too long title...")
            continue

        _handle_note(dst, title_sanitized, meta, notes_file_content)
        _handle_link(dst, title_sanitized, meta)

        num_copied += 1

    print(f"Num copied: {num_copied}")


def main():
    args = parse_args()
    convert(args.src, args.dst)


if __name__ == "__main__":
    main()
