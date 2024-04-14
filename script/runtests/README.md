The `runtests.py` allows you to configure and execute a series of experiments in sequence, on the same DO setup, to make comparisons fair.
This is achieved by replacing tags on template files for the `../../testnet.toml` and `../../experiment.mk` by combinations of the values specified
in an `options` file.
For each combination, the `runtests.py` scripts invokes the make commands in Makefile` to recreate the node configuration,
clean up the nodes (not the prometheus server), push the new configuration, and run the experiments., 

## Configuration
To use `runtests.py` create an `options` file that specifies which template files should be used taken as input, which tags/fields should be replaced by what, and which files will be generated as output.

For example, consider the contents of the `sampl_tmpl.toml` file.

```json

config1 = {{conf 1 var 2}}
config2 = "{{conf 1 var 1}}"
config3 = {{conf 2 var 1}}
config4 = {{conf 2 var 2}}
```

It defines 4 tags, `{{conf 1 var 2}}`, `{{conf 1 var 1}}`, `{{conf 2 var 1}}` and `{{conf 2 var 2}}`.

Now consider the contents of file `example_options.json`, which defines how these tags will be replaced.
The `sequences` field specifies two independent experiments, which will be executed one after the other,
`seq1` and `seq2`.

`seq` specifies a series of `configurations`, `conf 1`, `conf 2` and `conf 3`.
Each configuration has a set of tags that will be associated with diferent values.
The resulting associations will be combined to into full configurations.
That is, all values of `conf 1` will be combined with all values of `conf 2`
and the result will be combined with all values of `conf 3`.

For example, `conf 1` specifies that tag "conf 1 var 1" will be first associated with value `c1v1 0` and then `c1v1 1`.
Both values will be used in combination with the tags associated by `conf 2` and `conf 3`.

The sets of values associate with a tag inside a `zip_vars` field, for the lack of a better name, are associated simultaneously
and in the same order. In the example, when tag `conf 1 var 1` is associated with `c1v1 0`, `conf 1 var 2` will be associated with `c1v2 0`.
and when tag `conf 1 var 1` is associated with `c1v1 1`, `conf 1 var 2` will be associated with `c1v2 1`.
Observe that the association happens in the context of the same file, `sampl_tmpl.toml`, but this need not be the case.

```json
{
    "comment": "Entries are processed sequentially",
    "sequences": [
        {
            "name": "seq 1",
            "configurations": [
                {
                    "name": "conf 1",
                    "zip_vars": [
                        {
                            "tmpl_file": "sampl_tmpl.toml",
                            "output_file": "sampl.out",
                            "tag": "conf 1 var 1",
                            "values": [
                                "c1v1 0",
                                "c1v1 1"
                            ]
                        },
                        {
                            "tmpl_file": "sampl_tmpl.toml",
                            "output_file": "sampl.out",
                            "tag": "conf 1 var 2",
                            "values": [
                                "c1v2 0",
                                "c1v2 1"
                            ]
                        }
                    ]
                },
                {
                    "name": "conf 2",
...
                },
                {
                    "name": "conf 3",
...
                }
            ]
        },
        {
            "name": "seq 2",
...
        }
    ]
}
```

## Templates

The `reactors` files have real examples of experiment configurations.

## Execution

```bash
cd script/runtests
python3 runtests.py -l log.log -o flood_skip_options.json -r -t log.log
```

