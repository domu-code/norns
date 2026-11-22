package io.oll.nornspocket;

import static org.junit.Assert.*;
import java.io.*;
import java.nio.file.Files;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import org.junit.Test;

public class ScriptZipInstallerTest {
    @Test public void importsGithubStyleNestedLuaPackage() throws Exception {
        ByteArrayOutputStream data=new ByteArrayOutputStream();
        try(ZipOutputStream zip=new ZipOutputStream(data)){
            put(zip,"example-main/example.lua","include('example/lib/foo')");
            put(zip,"example-main/lib/foo.lua","return 42");
            put(zip,"example-main/README.md","Example script");
        }
        File root=Files.createTempDirectory("nornspocket-import").toFile();
        try{
            ScriptZipInstaller.Installed result=ScriptZipInstaller.install(
                new ByteArrayInputStream(data.toByteArray()),root,"example-main.zip");
            assertEquals(1,result.scripts);
            assertTrue(new File(result.folder,"example.lua").isFile());
            assertTrue(new File(result.folder,"lib/foo.lua").isFile());
        }finally{delete(root);}
    }
    @Test public void refusesTraversalAndRemovesPartialPackage() throws Exception{
        ByteArrayOutputStream data=new ByteArrayOutputStream();
        try(ZipOutputStream zip=new ZipOutputStream(data)){
            put(zip,"src-main/demo.lua","function init() end");
            put(zip,"src-main/../../escape.lua","print('bad')");
        }
        File root=Files.createTempDirectory("nornspocket-slip").toFile();
        try {
            try {
                ScriptZipInstaller.install(new ByteArrayInputStream(data.toByteArray()),root,"evil.zip");
                fail("Path traversal should fail");
            } catch(IOException expected) {
                assertTrue(expected.getMessage().contains("Unsafe"));
            }
            assertEquals(0,root.list().length);
        }finally{delete(root);}
    }
    private static void put(ZipOutputStream zip,String name,String text) throws IOException{
        zip.putNextEntry(new ZipEntry(name));
        zip.write(text.getBytes("UTF-8"));
        zip.closeEntry();
    }
    private static void delete(File file){
        File[] children=file.listFiles();if(children!=null)for(File child:children)delete(child);
        file.delete();
    }
}
