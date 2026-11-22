#!/usr/bin/env python3
"""Apply v0.4 fixes to the archived 0.3 Java sources, failing if upstream layout changes."""
import sys
from pathlib import Path

root = Path(sys.argv[1])
java = root / "app/src/main/java/io/oll/nornspocket"
app = root / "app/build.gradle"

def change(path, old, new):
    data = path.read_text()
    count = data.count(old)
    if count != 1:
        raise RuntimeError(f"{path}: expected exactly one match, got {count}: {old[:100]!r}")
    path.write_text(data.replace(old,new))

runtime = java / "LuaRuntime.java"
change(runtime,
    "        generation++;loaded=false;phasePolling=false;currentScript=script;",
    '        if(loaded && globals!=null) call("cleanup");\n        generation++;loaded=false;phasePolling=false;currentScript=script;')
change(runtime,
    '            globals.load(bootstrap,"norns_bootstrap").call();',
    '            globals.load(bootstrap,"norns_bootstrap").call();\n            globals.load(readAssetText("compat_04.lua"),"norns_compat_04").call();')
change(runtime,
    '    private String readAssetBootstrap() throws IOException {\n        try(java.io.InputStream in=screenContext.open("bootstrap.lua")){',
    '    private String readAssetBootstrap() throws IOException { return readAssetText("bootstrap.lua"); }\n    private String readAssetText(String assetName) throws IOException {\n        try(java.io.InputStream in=screenContext.open(assetName)){')
change(runtime,
    '            File file=new File(currentScript.getParentFile(),path).getCanonicalFile();',
    '            String localName=path.replace(\'\\\\\',\'/\');\n            String folderName=currentScript.getParentFile().getName()+"/";\n            if(localName.startsWith(folderName))localName=localName.substring(folderName.length());\n            File file=new File(currentScript.getParentFile(),localName).getCanonicalFile();')

main = java / "MainActivity.java"
change(main,
    'private static final int IMPORT_LUA=101,IMPORT_WAV=102,MIC_PERMISSION=103;',
    'private static final int IMPORT_LUA=101,IMPORT_WAV=102,MIC_PERMISSION=103,IMPORT_ZIP=104;')
change(main,
    '        Button importAudio=btn("+ WAV");importAudio.setOnClickListener(v->openFile(IMPORT_WAV));fileControls.addView(importAudio);\n        Button help=btn("?");help.setOnClickListener(v->showHelp());fileControls.addView(help);',
    '        Button help=btn("?");help.setOnClickListener(v->showHelp());fileControls.addView(help);\n'
    '        LinearLayout packageControls=horizontal();root.addView(packageControls);\n'
    '        Button zip=btn("+ ZIP PACKAGE");zip.setOnClickListener(v->openFile(IMPORT_ZIP));packageControls.addView(zip);\n'
    '        Button importAudio=btn("+ WAV");importAudio.setOnClickListener(v->openFile(IMPORT_WAV));packageControls.addView(importAudio);\n'
    '        Button library=btn("LIBRARY");library.setOnClickListener(v->showLibrary());packageControls.addView(library);')
change(main,
    '    private void showHelp(){',
    '''    private void showLibrary(){
        new android.app.AlertDialog.Builder(this).setTitle("Norns Pocket 0.4 script library")
          .setMessage("Bundled and playable:\\n"
            +"Pocket Grid, Tape Garden, MIDI Monitor, Sample Deck\\n"
            +"Walkabout (Darwin Grosse, MIT; Android port)\\n"
            +"Awake Pocket (independent adaptation)\\n"
            +"Meadowphysics Pocket (independent adaptation)\\n"
            +"Bloom Pocket (independent adaptation)\\n"
            +"MLR Pocket (independent adaptation)\\n\\n"
            +"The Pocket editions are NOT the original norns projects. "
            +"Original scripts may require SuperCollider, Lua 5.3, or modules not yet implemented. "
            +"Import trusted norns package ZIPs using + ZIP PACKAGE; script folders and libraries are extracted safely.")
          .setPositiveButton("OK",null).show();
    }
    private void showHelp(){''')
change(main,
    '        if(request!=IMPORT_LUA&&request!=IMPORT_WAV)return;',
    '''        if(request==IMPORT_ZIP){
            try(InputStream in=getContentResolver().openInputStream(intent.getData())){
                String name="norns_package.zip";
                try(android.database.Cursor c=getContentResolver().query(intent.getData(),null,null,null,null)){
                    if(c!=null&&c.moveToFirst()){
                        int col=c.getColumnIndex(android.provider.OpenableColumns.DISPLAY_NAME);
                        if(col>=0&&c.getString(col)!=null)name=c.getString(col);
                    }
                }
                ScriptZipInstaller.Installed installed=ScriptZipInstaller.install(in,scripts,name);
                showStatus("Imported "+installed.scripts+" scripts: "+installed.folder.getName());
                refreshScripts();
            }catch(Exception e){showStatus("ZIP import failed: "+e.getMessage());}
            return;
        }
        if(request!=IMPORT_LUA&&request!=IMPORT_WAV)return;''')
change(main,
    '''    private File[] scriptFiles(){
        File[] f=scripts.listFiles((dir,name)->name.toLowerCase().endsWith(".lua"));
        if(f==null)return new File[0];Arrays.sort(f,Comparator.comparing(File::getName));return f;
    }''',
    '''    private File[] scriptFiles(){
        java.util.ArrayList<File> result=new java.util.ArrayList<>();
        collectScripts(scripts,result,0);
        File[] files=result.toArray(new File[0]);
        Arrays.sort(files,Comparator.comparing(f->scripts.toPath().relativize(f.toPath()).toString()));
        return files;
    }
    private void collectScripts(File dir,java.util.List<File> result,int depth){
        if(depth>6)return;
        File[] children=dir.listFiles();
        if(children==null)return;
        for(File child:children){
            if(child.isDirectory()){
                String name=child.getName().toLowerCase();
                if(!name.equals("lib")&&!name.equals("data")&&!name.startsWith("."))collectScripts(child,result,depth+1);
            }else if(child.getName().toLowerCase().endsWith(".lua"))result.add(child);
        }
    }''')
change(main,
    '        for(int i=0;i<files.length;i++)names[i]=files[i].getName();',
    '        for(int i=0;i<files.length;i++)names[i]=scripts.toPath().relativize(files[i].toPath()).toString();')
change(app,
    "        versionCode 1\n        versionName '0.3.0-alpha'",
    "        versionCode 2\n        versionName '0.4.0-alpha'")
print("Applied v0.4 Android code changes")
