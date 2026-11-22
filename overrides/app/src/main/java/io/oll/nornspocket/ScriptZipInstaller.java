package io.oll.nornspocket;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.HashSet;
import java.util.Locale;
import java.util.Set;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

/** Safely imports a norns script repository ZIP into app-local script storage. */
public final class ScriptZipInstaller {
    private static final int MAX_ENTRIES=1200;
    private static final long MAX_UNCOMPRESSED=64L*1024*1024;
    private ScriptZipInstaller(){}

    public static final class Installed {
        public final File folder;
        public final int scripts;
        Installed(File folder,int scripts){this.folder=folder;this.scripts=scripts;}
    }

    public static Installed install(InputStream source,File scriptsRoot,String sourceName) throws IOException {
        if(source==null)throw new IOException("No ZIP input");
        if(!scriptsRoot.isDirectory() && !scriptsRoot.mkdirs())throw new IOException("Cannot create scripts folder");
        String stem=sourceName==null?"package":sourceName;
        stem=stem.replaceFirst("(?i)\\.zip$","").replaceAll("[^A-Za-z0-9._-]","_");
        if(stem.isEmpty()||stem.equals(".")||stem.equals(".."))stem="package";
        File output=new File(scriptsRoot,stem);
        for(int i=2;output.exists();i++)output=new File(scriptsRoot,stem+"_"+i);
        if(!output.mkdirs())throw new IOException("Cannot create package folder");
        int scriptCount=0,entryCount=0;
        long expanded=0;
        String prefix=null;
        Set<String> seen=new HashSet<>();
        final String rootPath=output.getCanonicalPath()+File.separator;
        try {
            ZipInputStream zin=new ZipInputStream(source);
            ZipEntry entry;
            byte[] block=new byte[8192];
            while((entry=zin.getNextEntry())!=null) {
                if(++entryCount>MAX_ENTRIES)throw new IOException("Too many ZIP entries");
                String name=entry.getName().replace('\\','/');
                if(name.startsWith("/")||name.startsWith("../")||name.contains("/../")||name.equals(".."))
                    throw new IOException("Unsafe ZIP path: "+name);
                if(prefix==null){
                    int slash=name.indexOf('/');
                    // GitHub source ZIPs usually contain a single outer repository directory.
                    prefix=(slash>0)?name.substring(0,slash)+"/":"";
                }
                if(!prefix.isEmpty()&&name.startsWith(prefix))name=name.substring(prefix.length());
                if(name.isEmpty()||entry.isDirectory()){zin.closeEntry();continue;}
                if(name.startsWith(".")||name.contains("/.")){zin.closeEntry();continue;}
                String lower=name.toLowerCase(Locale.US);
                if(!(lower.endsWith(".lua")||lower.endsWith(".wav")||lower.endsWith(".txt")||
                     lower.endsWith(".pset")||lower.endsWith(".json")||lower.endsWith(".md"))){
                    zin.closeEntry();continue;
                }
                File target=new File(output,name).getCanonicalFile();
                if(!target.getCanonicalPath().startsWith(rootPath))throw new IOException("ZIP entry escapes import directory");
                if(!seen.add(target.getCanonicalPath()))throw new IOException("Duplicate ZIP entry: "+name);
                File parent=target.getParentFile();
                if(!parent.isDirectory()&&!parent.mkdirs())throw new IOException("Cannot create package subfolder");
                try(FileOutputStream file=new FileOutputStream(target)){
                    int size;
                    while((size=zin.read(block))!=-1){
                        expanded+=size;
                        if(expanded>MAX_UNCOMPRESSED)throw new IOException("ZIP exceeds 64 MB unpacked limit");
                        file.write(block,0,size);
                    }
                }
                if(lower.endsWith(".lua")&&!lower.startsWith("lib/")&&!lower.contains("/lib/"))scriptCount++;
                zin.closeEntry();
            }
            zin.close();
            if(scriptCount==0)throw new IOException("No script .lua files in ZIP");
            return new Installed(output,scriptCount);
        }catch(IOException|RuntimeException e){
            deleteTree(output);
            throw e;
        }
    }

    private static void deleteTree(File file){
        File[] children=file.listFiles();
        if(children!=null)for(File c:children)deleteTree(c);
        file.delete();
    }
}
