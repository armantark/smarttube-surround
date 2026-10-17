import json, os, pathlib, subprocess, tempfile
repo = pathlib.Path.cwd()
with tempfile.TemporaryDirectory(prefix='smarttube-manifest-') as tmp:
    root = pathlib.Path(tmp)
    build = root / 'build'
    apks = build / 'smarttubetv/build/outputs/apk/stbeta/release'
    apks.mkdir(parents=True)
    for abi in ('armeabi-v7a', 'arm64-v8a', 'x86', 'universal'):
        (apks / f'SmartTube_beta_32.56_{abi}.apk').touch()
    (build / 'smarttubetv/build.gradle').write_text('versionCode 244603\n')
    bins = root / 'bin'
    bins.mkdir()
    curl = bins / 'curl'
    curl.write_text("#!/usr/bin/env python3\nimport json,os,sys,pathlib\nassert '--retry' in sys.argv and '--retry-all-errors' in sys.argv\nout=pathlib.Path(sys.argv[sys.argv.index('--output')+1])\nmode=os.environ['MOCK_STATUS']\nif mode=='200': out.write_text(json.dumps({'package':{'downloadUrlList':['old']}, '32.56-surround':{'versionCode':244602,'changelog':['old release']}, '32.54-surround':{'versionCode':244402,'changelog':['older release']}}))\nelse: out.write_text('not found')\nprint(mode,end='')\n")
    curl.chmod(493)
    for status in ('200', '404', '503'):
        out = root / status
        env = dict(os.environ, BUILD_DIR=str(build), PATH=str(bins) + os.pathsep + os.environ['PATH'], MOCK_STATUS=status)
        result = subprocess.run([str(repo / 'scripts/release-assets.sh'), '32.56', str(out)], env=env, text=True, capture_output=True)
        if status == '503':
            assert result.returncode != 0 and (not (out / 'smarttube_surround.json').exists())
            print('PASS HTTP 503 refuses to replace history: ' + result.stderr.strip())
            continue
        assert result.returncode == 0, result.stderr
        manifest = json.loads((out / 'smarttube_surround.json').read_text())
        assert manifest['32.56-surround-r3'] == {'versionCode': 244603, 'changelog': ['Upstream SmartTube 32.56 with patch revision 3']}
        assert manifest['package']['downloadUrlList'] == ['https://github.com/armantark/smarttube-surround/releases/download/32.56-r3/SmartTube_Surround_armeabi-v7a.apk']
        if status == '200':
            assert manifest['32.56-surround'] == {'versionCode': 244602, 'changelog': ['old release']}
            assert manifest['32.54-surround']['versionCode'] == 244402
            print('PASS HTTP 200 preserves two historical entries, adds r3, updates ABI URLs')
        else:
            assert set(manifest) == {'package', '32.56-surround-r3'}
            print('PASS HTTP 404 starts empty and adds r3')
