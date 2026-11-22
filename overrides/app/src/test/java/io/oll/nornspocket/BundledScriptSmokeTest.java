package io.oll.nornspocket;

import static org.junit.Assert.*;
import java.io.File;
import java.nio.file.Files;
import java.util.Arrays;
import org.junit.Test;
import org.luaj.vm2.Globals;
import org.luaj.vm2.LuaTable;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.Varargs;
import org.luaj.vm2.lib.VarArgFunction;
import org.luaj.vm2.lib.jse.JsePlatform;

/** Loads the actual bundled Lua sources under LuaJ with simulated norns services. */
public class BundledScriptSmokeTest {
    private static final String[] SCRIPTS={
        "01_Pocket_Grid.lua","02_Tape_Garden.lua","03_MIDI_Monitor.lua",
        "04_Sample_Deck.lua","05_Walkabout_Port.lua","06_Awake_Pocket.lua",
        "07_Meadowphysics_Pocket.lua","08_Bloom_Pocket.lua","09_MLR_Pocket.lua"
    };
    private static final String[] SCREEN={
        "clear","update","level","move","line","rect","circle","stroke",
        "fill","text","text_right","text_center","font_size","font_face",
        "aa","line_width","arc","pixel","move_rel","line_rel"
    };
    private static final String[] SOFTCUT={
        "buffer_clear","buffer_read_mono","enable","buffer","loop","loop_start",
        "loop_end","position","fade_time","level","pre_level","rec_level",
        "level_input_cut","rate","play","rec","event_position","query_position",
        "pan","reset"
    };
    private static final VarArgFunction NOOP=new VarArgFunction(){
        @Override public Varargs invoke(Varargs a){return LuaValue.NIL;}
    };
    private static LuaTable stub(String... names) {
        LuaTable table=new LuaTable();
        for(String name:names)table.set(name,NOOP);
        return table;
    }
    private static String text(File file) throws Exception {
        return Files.readString(file.toPath());
    }
    @Test public void bundledScriptsLoadAndInitializeUnderActualLuaJ() throws Exception {
        File assets=new File("src/main/assets");
        assertTrue("Run Gradle from app module: "+assets.getAbsolutePath(),assets.isDirectory());
        File temp=Files.createTempDirectory("nornspocket-luaj").toFile();
        try {
            for(String script:SCRIPTS){
                Globals g=JsePlatform.standardGlobals();
                LuaTable host=stub("grid_set","grid_all","grid_refresh","midi_send",
                    "schedule","include","status");
                host.set("seconds",new VarArgFunction(){
                    @Override public Varargs invoke(Varargs a){
                        return LuaValue.valueOf(System.nanoTime()/1e9);
                    }
                });
                g.set("__host",host);
                g.set("screen",stub(SCREEN));
                g.set("softcut",stub(SOFTCUT));
                g.set("osc",stub("send"));
                g.set("audio",stub("level_dac","level_monitor"));
                LuaTable engine=stub("hz","note_on");
                engine.set("name",LuaValue.valueOf("AndroidSine"));
                g.set("engine",engine);
                LuaTable paths=new LuaTable();
                String base=temp.getAbsolutePath()+File.separator;
                paths.set("audio",LuaValue.valueOf(base));
                paths.set("data",LuaValue.valueOf(base));
                paths.set("code",LuaValue.valueOf(base));
                paths.set("dust",LuaValue.valueOf(base));
                g.set("_path",paths);
                g.load(text(new File(assets,"lua/bootstrap.lua")),"bootstrap").call();
                g.load(text(new File(assets,"lua/compat_04.lua")),"compat").call();
                g.load(text(new File(assets,"scripts/"+script)),script).call();
                g.get("init").call();
                g.get("redraw").call();
                g.get("key").call(LuaValue.valueOf(2),LuaValue.valueOf(1));
                g.get("enc").call(LuaValue.valueOf(2),LuaValue.valueOf(1));
                g.get("__grid_key").call(LuaValue.valueOf(3),LuaValue.valueOf(3),LuaValue.valueOf(1));
            }
        }finally{
            File[] files=temp.listFiles();
            if(files!=null)for(File f:files)f.delete();
            temp.delete();
        }
    }
}
