// ============================================================
//  Complete UVM Testbench — Traffic Signal Controller
//  Single file for EDA Playground
//
//  DUT ports:
//    input  clk, rst_n, enable
//    output light[1:0], red, green, yellow
//
//  State encoding in DUT:
//    RED_S    = 2'b00
//    GREEN_S  = 2'b01
//    YELLOW_S = 2'b10
//
//  Timing parameters:
//    RED_TIME    = 30 cycles
//    GREEN_TIME  = 25 cycles
//    YELLOW_TIME = 5  cycles
//
//  Includes:
//  1.  Interface          + SVA Assertions
//  2.  Configuration Class
//  3.  Sequence Item
//  4.  Sequences
//  5.  Sequencer
//  6.  Driver
//  7.  Monitor
//  8.  Scoreboard + Functional Coverage
//  9.  Agent
//  10. Environment
//  11. Test
//  12. Top Module
// ============================================================

`include "uvm_macros.svh"
import uvm_pkg::*;
 
// ============================================================
//  INTERFACE
// ============================================================
interface tsc_if (input logic clk);
 
    logic        rst_n;
    logic        enable;
    logic [1:0]  light;     // DUT output
    logic        red;       // DUT output
    logic        green;     // DUT output
    logic        yellow;    // DUT output
 
    // ── Driver clocking block ─────────────────────────────
    // Drives only DUT inputs: rst_n and enable
    // light, red, green, yellow are DUT outputs — NOT here
    clocking driver_cb @(posedge clk);
        default input #1ns output #1ns;
        output rst_n;
        output enable;
    endclocking
 
    // ── Monitor clocking block ────────────────────────────
    // Observes all signals including DUT outputs
    clocking monitor_cb @(posedge clk);
    default input #1ns output #1ns;

    input rst_n;
    input enable;
    input light;
    input red;
    input green;
    input yellow;
	endclocking
 
    modport driver_mp  (clocking driver_cb,  input clk);
    modport monitor_mp (clocking monitor_cb, input clk);
 
    // ================================================================
    //  SVA ASSERTIONS
    // ================================================================
 
    // ── Assertion 1: On reset, light must be RED (2'b00) ─
    property rst_light_red;
        @(posedge clk)
        !rst_n |-> (light == 2'b00);
    endproperty
    assert_rst_light_red : assert property (rst_light_red)
        else $error("[ASSERT FAIL] light not RED during reset at t=%0t", $time);
 
    // ── Assertion 2: On reset, red output must be HIGH ───
    property rst_red_high;
        @(posedge clk)
        !rst_n |-> (red == 1'b1);
    endproperty
    assert_rst_red_high : assert property (rst_red_high)
        else $error("[ASSERT FAIL] red not 1 during reset at t=%0t", $time);
 
    // ── Assertion 3: On reset, green must be LOW ─────────
    property rst_green_low;
        @(posedge clk)
        !rst_n |-> (green == 1'b0);
    endproperty
    assert_rst_green_low : assert property (rst_green_low)
        else $error("[ASSERT FAIL] green not 0 during reset at t=%0t", $time);
 
    // ── Assertion 4: On reset, yellow must be LOW ────────
    property rst_yellow_low;
        @(posedge clk)
        !rst_n |-> (yellow == 1'b0);
    endproperty
    assert_rst_yellow_low : assert property (rst_yellow_low)
        else $error("[ASSERT FAIL] yellow not 0 during reset at t=%0t", $time);
 
    // ── Assertion 5: Only one output high at a time ───────
    // red, green, yellow are mutually exclusive
    property one_hot_outputs;
        @(posedge clk) disable iff (!rst_n)
        (red + green + yellow) == 1;
    endproperty
    assert_one_hot : assert property (one_hot_outputs)
        else $error("[ASSERT FAIL] more than one signal HIGH at t=%0t r=%b g=%b y=%b",
            $time, red, green, yellow);
 
    // ── Assertion 6: light encoding matches individual outputs
    // light=00 → red=1, light=01 → green=1, light=10 → yellow=1
    property light_matches_outputs;
        @(posedge clk) disable iff (!rst_n)
        (light == 2'b00) ? (red == 1 && green == 0 && yellow == 0) :
        (light == 2'b01) ? (red == 0 && green == 1 && yellow == 0) :
        (light == 2'b10) ? (red == 0 && green == 0 && yellow == 1) : 1'b0;
    endproperty
    assert_light_matches : assert property (light_matches_outputs)
        else $error("[ASSERT FAIL] light=%0b does not match red=%b green=%b yellow=%b at t=%0t",
            light, red, green, yellow, $time);
 
    // ── Assertion 7: No X or Z on light after reset ───────
    property light_no_x_z;
        @(posedge clk) disable iff (!rst_n)
        !$isunknown(light);
    endproperty
    assert_light_no_x_z : assert property (light_no_x_z)
        else $error("[ASSERT FAIL] light is X or Z at t=%0t", $time);
 
    // ── Assertion 8: State frozen when enable=0 ───────────
    // When enable goes low, light must not change on next posedge
    property enable_freezes_state;
        @(posedge clk) disable iff (!rst_n)
        !enable |=> (light == $past(light));
    endproperty
    assert_enable_freeze : assert property (enable_freezes_state)
        else $error("[ASSERT FAIL] light changed while enable=0 at t=%0t", $time);
 
    // ── Assertion 9: After GREEN, next state must be YELLOW
    // GREEN cannot jump directly to RED
    property green_to_yellow;
        @(posedge clk) disable iff (!rst_n)
        $fell(green) |-> (yellow == 1'b1);
    endproperty
    assert_green_to_yellow : assert property (green_to_yellow)
        else $error("[ASSERT FAIL] GREEN skipped YELLOW and went to RED at t=%0t", $time);
 
    // ── Assertion 10: After YELLOW, next state must be RED
    property yellow_to_red;
        @(posedge clk) disable iff (!rst_n)
        $fell(yellow) |-> (red == 1'b1);
    endproperty
    assert_yellow_to_red : assert property (yellow_to_red)
        else $error("[ASSERT FAIL] YELLOW did not go to RED at t=%0t", $time);
 
    // ── Assertion 11: After RED, next state must be GREEN
    property red_to_green;
        @(posedge clk) disable iff (!rst_n)
        $fell(red) |-> (green == 1'b1);
    endproperty
    assert_red_to_green : assert property (red_to_green)
        else $error("[ASSERT FAIL] RED did not go to GREEN at t=%0t", $time);
 
endinterface
 
 
// ============================================================
//  CONFIGURATION CLASS
// ============================================================
class tsc_config extends uvm_object;
 
    `uvm_object_utils(tsc_config)
 
    uvm_active_passive_enum is_active;
    virtual tsc_if          vif;
 
    // Timing parameters — must match DUT parameters
    int unsigned red_time;
    int unsigned green_time;
    int unsigned yellow_time;
 
    function new(string name = "tsc_config");
        super.new(name);
        is_active   = UVM_ACTIVE;
        red_time    = 30;
        green_time  = 25;
        yellow_time = 5;
    endfunction
 
endclass
 
 
// ============================================================
//  SEQUENCE ITEM (TRANSACTION)
// ============================================================
class tsc_item extends uvm_sequence_item;
 
    `uvm_object_utils(tsc_item)
 
    // ── Stimulus fields (driven by driver) ───────────────
    rand logic rst_n;
    rand logic enable;
 
    // ── Response fields (captured by monitor) ────────────
    logic [1:0] light;
    logic       red;
    logic       green;
    logic       yellow;
 
    // rst_n mostly high, occasionally low
    constraint c_rst    { rst_n  dist {1'b1 := 85, 1'b0 := 15}; }
    // enable mostly high, occasionally low
    constraint c_enable { enable dist {1'b1 := 80, 1'b0 := 20}; }
 
    function new(string name = "tsc_item");
        super.new(name);
    endfunction
 
    // Helper: get state name from light encoding
    function string state_name();
        case (light)
            2'b00:   return "RED   ";
            2'b01:   return "GREEN ";
            2'b10:   return "YELLOW";
            default: return "UNKNWN";
        endcase
    endfunction
 
    function string convert2string();
        return $sformatf(
            "rst_n=%0b enable=%0b | light=%0b %-6s | red=%0b green=%0b yellow=%0b",
            rst_n, enable, light, state_name(), red, green, yellow);
    endfunction
 
endclass
 
 
// ============================================================
//  SEQUENCES
// ============================================================
 
// ── Base sequence ─────────────────────────────────────────
class tsc_base_seq extends uvm_sequence #(tsc_item);
    `uvm_object_utils(tsc_base_seq)
    function new(string name = "tsc_base_seq");
        super.new(name);
    endfunction
endclass
 
// ── Directed Reset Coverage Sequence ──────────────────────
class tsc_reset_cov_seq extends tsc_base_seq;

    `uvm_object_utils(tsc_reset_cov_seq)

    function new(string name = "tsc_reset_cov_seq");
        super.new(name);
    endfunction

    task body();
        tsc_item item;

        `uvm_info("RESET_COV_SEQ", "Applying reset in RED, GREEN, and YELLOW states", UVM_MEDIUM)

        // -----------------------------
        // Reset while in RED
        // -----------------------------
        repeat (5) begin
            item = tsc_item::type_id::create("item");
            start_item(item);
            item.rst_n  = 1'b0;
            item.enable = 1'b0;
            finish_item(item);
        end

        repeat (3) begin
            item = tsc_item::type_id::create("item");
            start_item(item);
            item.rst_n  = 1'b1;
            item.enable = 1'b1;
            finish_item(item);
        end

        // Apply reset in RED
        repeat (3) begin
            item = tsc_item::type_id::create("item");
            start_item(item);
            item.rst_n  = 1'b0;
            item.enable = 1'b0;
            finish_item(item);
        end

        // -----------------------------
        // Reset while in GREEN
        // -----------------------------
        // Restart from reset
        repeat (5) begin
            item = tsc_item::type_id::create("item");
            start_item(item);
            item.rst_n  = 1'b0;
            item.enable = 1'b0;
            finish_item(item);
        end

        // Move to GREEN
        repeat (31) begin
            item = tsc_item::type_id::create("item");
            start_item(item);
            item.rst_n  = 1'b1;
            item.enable = 1'b1;
            finish_item(item);
        end

        // Apply reset in GREEN
        repeat (3) begin
            item = tsc_item::type_id::create("item");
            start_item(item);
            item.rst_n  = 1'b0;
            item.enable = 1'b0;
            finish_item(item);
        end

        // -----------------------------
        // Reset while in YELLOW
        // -----------------------------
        // Restart from reset
        repeat (5) begin
            item = tsc_item::type_id::create("item");
            start_item(item);
            item.rst_n  = 1'b0;
            item.enable = 1'b0;
            finish_item(item);
        end

        // Move to YELLOW
        repeat (56) begin
            item = tsc_item::type_id::create("item");
            start_item(item);
            item.rst_n  = 1'b1;
            item.enable = 1'b1;
            finish_item(item);
        end

        // Apply reset in YELLOW
        repeat (3) begin
            item = tsc_item::type_id::create("item");
            start_item(item);
            item.rst_n  = 1'b0;
            item.enable = 1'b0;
            finish_item(item);
        end

        // Release reset again
        repeat (10) begin
            item = tsc_item::type_id::create("item");
            start_item(item);
            item.rst_n  = 1'b1;
            item.enable = 1'b1;
            finish_item(item);
        end

        `uvm_info("RESET_COV_SEQ", "Reset coverage sequence complete", UVM_MEDIUM)
    endtask

endclass// ── Reset sequence ────────────────────────────────────────
// ── Directed Enable Coverage Sequence ─────────────────────
// Purpose:
//   To intentionally drive enable = 0 in all traffic light states:
//   RED, GREEN, and YELLOW.
//
// This helps close coverage for:
//   cg_state_x_enable
//   cg_enable_in_state
// ── Directed Enable Coverage Sequence ─────────────────────
// Purpose:
//   Cover enable = 0 in RED, GREEN, and YELLOW states.
// ── Directed Enable Coverage Sequence ─────────────────────
// Purpose:
//   Cover enable = 0 in RED, GREEN, and YELLOW states.
// ── Directed Enable Coverage Sequence ─────────────────────
// Purpose:
//   Cover enable = 0 in RED, GREEN, and YELLOW states.
// ── Directed Enable Coverage Sequence ─────────────────────
// Purpose:
//   Cover enable = 0 in RED, GREEN, and YELLOW states.
class tsc_enable_cov_seq extends tsc_base_seq;

    `uvm_object_utils(tsc_enable_cov_seq)

    virtual tsc_if vif;

    function new(string name = "tsc_enable_cov_seq");
        super.new(name);
    endfunction

    task drive(bit rst_n_val, bit enable_val);
        tsc_item item;

        item = tsc_item::type_id::create("item");
        start_item(item);
        item.rst_n  = rst_n_val;
        item.enable = enable_val;
        finish_item(item);
    endtask

    task body();

        if (!uvm_config_db#(virtual tsc_if)::get(null, "*", "vif", vif)) begin
            `uvm_fatal("ENABLE_COV_SEQ", "Unable to get virtual interface")
        end

        `uvm_info("ENABLE_COV_SEQ",
                  "Starting enable coverage sequence using DUT state observation",
                  UVM_MEDIUM)

        // ==================================================
        // CASE 1: RED with enable = 0
        // ==================================================

        repeat (5) begin
            drive(1'b0, 1'b0);
        end

        repeat (3) begin
            drive(1'b1, 1'b1);
        end

        // After reset release, DUT should be in RED
        repeat (10) begin
            drive(1'b1, 1'b0);
        end

        repeat (5) begin
            drive(1'b1, 1'b1);
        end


        // ==================================================
        // CASE 2: GREEN with enable = 0
        // ==================================================

        repeat (5) begin
            drive(1'b0, 1'b0);
        end

        repeat (3) begin
            drive(1'b1, 1'b1);
        end

        // Wait until DUT output shows GREEN
        wait (vif.light == 2'b01);

        `uvm_info("ENABLE_COV_SEQ",
                  "Detected GREEN state, driving enable=0",
                  UVM_MEDIUM)

        repeat (10) begin
            drive(1'b1, 1'b0);
        end

        repeat (5) begin
            drive(1'b1, 1'b1);
        end


 // ==================================================
// CASE 3: YELLOW with enable = 0
// ==================================================

// Reset
repeat (5) begin
    drive(1'b0, 1'b0);
end

// Release reset
repeat (3) begin
    drive(1'b1, 1'b1);
end

// Reach GREEN first
wait (vif.light == 2'b01);

`uvm_info("ENABLE_COV_SEQ",
          "Detected GREEN, waiting near YELLOW boundary",
          UVM_MEDIUM)

// GREEN_TIME = 25.
// Wait almost full GREEN duration.
// Use 22 first, then enable low will be applied near YELLOW.
      repeat (24) begin
    drive(1'b1, 1'b1);
end

// Now drive enable low for a long time.
// If this starts slightly before/at YELLOW, it should freeze the state.
repeat (40) begin
    drive(1'b1, 1'b0);
end

repeat (10) begin
    drive(1'b1, 1'b1);
end
    endtask

endclass
class tsc_reset_seq extends tsc_base_seq;
    `uvm_object_utils(tsc_reset_seq)
    function new(string name = "tsc_reset_seq");
        super.new(name);
    endfunction
    task body();
        tsc_item item;
        `uvm_info("RESET_SEQ", "Asserting reset", UVM_MEDIUM)
        repeat(5) begin
            item = tsc_item::type_id::create("item");
            start_item(item);
            item.rst_n  = 1'b0;
            item.enable = 1'b0;
            finish_item(item);
        end
        item = tsc_item::type_id::create("item");
        start_item(item);
        item.rst_n  = 1'b1;
        item.enable = 1'b1;
        finish_item(item);
        `uvm_info("RESET_SEQ", "Reset released, enable=1", UVM_MEDIUM)
    endtask
endclass
 
// ── Directed sequence ─────────────────────────────────────
// Runs enable=1 for enough cycles to complete full FSM cycles
// Total cycle = RED_TIME + GREEN_TIME + YELLOW_TIME = 30+25+5 = 60
class tsc_directed_seq extends tsc_base_seq;
    `uvm_object_utils(tsc_directed_seq)
    int unsigned num_cycles = 3;
    function new(string name = "tsc_directed_seq");
        super.new(name);
    endfunction
    task body();
        tsc_item item;
        int unsigned total = num_cycles * 60;
        `uvm_info("DIRECTED_SEQ",
            $sformatf("Running %0d full cycles (%0d clocks)", num_cycles, total),
            UVM_MEDIUM)
        repeat(total) begin
            item = tsc_item::type_id::create("item");
            start_item(item);
            item.rst_n  = 1'b1;
            item.enable = 1'b1;
            finish_item(item);
        end
        `uvm_info("DIRECTED_SEQ", "Directed sequence complete", UVM_MEDIUM)
    endtask
endclass
 
// ── Enable toggle sequence ────────────────────────────────
// Toggles enable mid-operation to verify state freeze
class tsc_enable_toggle_seq extends tsc_base_seq;
    `uvm_object_utils(tsc_enable_toggle_seq)
    function new(string name = "tsc_enable_toggle_seq");
        super.new(name);
    endfunction
    task body();
        tsc_item item;
        `uvm_info("ENABLE_SEQ", "Testing enable toggle", UVM_MEDIUM)
        // Run 15 cycles with enable=1
        repeat(15) begin
            item = tsc_item::type_id::create("item");
            start_item(item);
            item.rst_n  = 1'b1;
            item.enable = 1'b1;
            finish_item(item);
        end
        // Freeze for 10 cycles — state must not change
        `uvm_info("ENABLE_SEQ", "Disabling — state should freeze", UVM_MEDIUM)
        repeat(10) begin
            item = tsc_item::type_id::create("item");
            start_item(item);
            item.rst_n  = 1'b1;
            item.enable = 1'b0;
            finish_item(item);
        end
        // Resume normal operation
        `uvm_info("ENABLE_SEQ", "Re-enabling", UVM_MEDIUM)
        repeat(30) begin
            item = tsc_item::type_id::create("item");
            start_item(item);
            item.rst_n  = 1'b1;
            item.enable = 1'b1;
            finish_item(item);
        end
    endtask
endclass
 
// ── Mid-cycle reset sequence ──────────────────────────────
class tsc_mid_reset_seq extends tsc_base_seq;
    `uvm_object_utils(tsc_mid_reset_seq)
    function new(string name = "tsc_mid_reset_seq");
        super.new(name);
    endfunction
    task body();

    tsc_item item;

    `uvm_info("RESET_SEQ", "Asserting reset", UVM_LOW)

    repeat (5) begin
        item = tsc_item::type_id::create("item");
        start_item(item);
        item.rst_n  = 1'b0;
        item.enable = 1'b0;
        finish_item(item);
    end

    `uvm_info("RESET_SEQ", "Reset released, enable=1", UVM_LOW)

    item = tsc_item::type_id::create("item");
    start_item(item);
    item.rst_n  = 1'b1;
    item.enable = 1'b1;
    finish_item(item);

endtask
endclass
 
// ── Random sequence ───────────────────────────────────────
class tsc_rand_seq extends tsc_base_seq;
    `uvm_object_utils(tsc_rand_seq)
    int unsigned num_txns = 200;
    function new(string name = "tsc_rand_seq");
        super.new(name);
    endfunction
    task body();
        tsc_item item;
        `uvm_info("RAND_SEQ",
            $sformatf("Sending %0d random transactions", num_txns), UVM_MEDIUM)
        repeat(num_txns) begin
            item = tsc_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_fatal("RAND_SEQ", "Randomization failed")
            finish_item(item);
        end
    endtask
endclass
 
// ── Full sequence ─────────────────────────────────────────
class tsc_full_seq extends tsc_base_seq;

    `uvm_object_utils(tsc_full_seq)

    function new(string name = "tsc_full_seq");
        super.new(name);
    endfunction

    task body();
        tsc_reset_seq         rst_seq;
        tsc_directed_seq      dir_seq;
        tsc_enable_toggle_seq en_seq;
        tsc_mid_reset_seq     mid_seq;
        tsc_enable_cov_seq    en_cov_seq;
        tsc_reset_cov_seq     rst_cov_seq;
        tsc_rand_seq          rnd_seq;

        rst_seq = tsc_reset_seq::type_id::create("rst_seq");
        rst_seq.start(m_sequencer);

        dir_seq = tsc_directed_seq::type_id::create("dir_seq");
        dir_seq.num_cycles = 3;
        dir_seq.start(m_sequencer);

        en_seq = tsc_enable_toggle_seq::type_id::create("en_seq");
        en_seq.start(m_sequencer);

        mid_seq = tsc_mid_reset_seq::type_id::create("mid_seq");
        mid_seq.start(m_sequencer);

        en_cov_seq = tsc_enable_cov_seq::type_id::create("en_cov_seq");
        en_cov_seq.start(m_sequencer);

        rst_cov_seq = tsc_reset_cov_seq::type_id::create("rst_cov_seq");
        rst_cov_seq.start(m_sequencer);

        rnd_seq = tsc_rand_seq::type_id::create("rnd_seq");
        rnd_seq.num_txns = 300;
        rnd_seq.start(m_sequencer);

        `uvm_info("FULL_SEQ", "Full sequence complete", UVM_LOW)
    endtask

endclass
 
// ============================================================
//  SEQUENCER
// ============================================================
class tsc_sequencer extends uvm_sequencer #(tsc_item);
    `uvm_component_utils(tsc_sequencer)
    function new(string name = "tsc_sequencer",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass
 
 
// ============================================================
//  DRIVER
//  Drives rst_n and enable only — DUT outputs not touched
// ============================================================
class tsc_driver extends uvm_driver #(tsc_item);
 
    `uvm_component_utils(tsc_driver)
 
    tsc_config               cfg;
    virtual tsc_if.driver_mp vif;
 
    function new(string name = "tsc_driver",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction
 
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(tsc_config)::get(
                this, "", "tsc_config", cfg))
            `uvm_fatal("DRIVER", "Cannot get tsc_config from config_db")
    endfunction
 
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        vif = cfg.vif;
    endfunction
 
    task run_phase(uvm_phase phase);
        tsc_item item;
        forever begin
          	//@(vif.driver_cb);
            seq_item_port.get_next_item(item);
            vif.driver_cb.rst_n  <= item.rst_n;
            vif.driver_cb.enable <= item.enable;
            @(vif.driver_cb);
            `uvm_info("DRIVER",
                $sformatf("Drove: rst_n=%0b enable=%0b",
                    item.rst_n, item.enable), UVM_HIGH)
            seq_item_port.item_done();
        end
    endtask
 
endclass
 
 
// ============================================================
//  MONITOR
//  Observes all signals every clock cycle
// ============================================================
class tsc_monitor extends uvm_monitor;
 
    `uvm_component_utils(tsc_monitor)
 
    uvm_analysis_port #(tsc_item)  ap;
    tsc_config                     cfg;
    virtual tsc_if.monitor_mp      vif;
 
    function new(string name = "tsc_monitor",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction
 
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(tsc_config)::get(
                this, "", "tsc_config", cfg))
            `uvm_fatal("MONITOR", "Cannot get tsc_config from config_db")
    endfunction
 
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        vif = cfg.vif;
    endfunction
 
    task run_phase(uvm_phase phase);
    tsc_item item;

    forever begin
        @(vif.monitor_cb);

        item = tsc_item::type_id::create("item");

        item.rst_n  = vif.monitor_cb.rst_n;
        item.enable = vif.monitor_cb.enable;
        item.light  = vif.monitor_cb.light;
        item.red    = vif.monitor_cb.red;
        item.green  = vif.monitor_cb.green;
        item.yellow = vif.monitor_cb.yellow;

        ap.write(item);
    end
endtask
 
endclass
 
 
// ============================================================
//  SCOREBOARD — with Functional Coverage
//
//  CHECKS:
//  1. Reset: light=RED, red=1, green=0, yellow=0
//  2. One-hot: only one of red/green/yellow is high
//  3. light encoding matches individual outputs
//  4. State transitions correct: R→G→Y→R
//  5. Timing: each state holds for correct number of cycles
//  6. Enable freeze: state does not change when enable=0
//
//  COVERAGE (8 covergroups, all bins explicit):
//  CG1: All 3 states visited
//  CG2: rst_n asserted and released
//  CG3: enable asserted and de-asserted
//  CG4: All 3 state transitions
//  CG5: Cross state x enable
//  CG6: Cross state x rst_n
//  CG7: Reset applied in every state
//  CG8: Enable toggled in every state
// ============================================================
class tsc_scoreboard extends uvm_scoreboard;
 
    `uvm_component_utils(tsc_scoreboard)
 
    uvm_tlm_analysis_fifo #(tsc_item) sb_fifo;
 
    // State encoding — matches DUT
    localparam RED_S    = 2'b00;
    localparam GREEN_S  = 2'b01;
    localparam YELLOW_S = 2'b10;
 
    // Internal tracking — initialized in new()
    logic [1:0]  prev_light;
    logic        prev_enable;
    int unsigned state_timer;
    bit          first_sample;
    bit          enable_was_low;
    int unsigned pass_count;
    int unsigned fail_count;
    int unsigned reset_count;
 
    // Timing from config
    int unsigned red_time;
    int unsigned green_time;
    int unsigned yellow_time;
 
    // Coverage sampling variable
    tsc_item item_for_cov;
 
    // ============================================================
    //  FUNCTIONAL COVERAGE
    // ============================================================
 
    // CG1: All 3 light states must be visited
    covergroup cg_states;
        cp_light : coverpoint item_for_cov.light {
            bins red_state    = {2'b00};
            bins green_state  = {2'b01};
            bins yellow_state = {2'b10};
        }
    endgroup
 
    // CG2: rst_n asserted and released
    covergroup cg_rst;
        cp_rst : coverpoint item_for_cov.rst_n {
            bins rst_active   = {1'b0};
            bins rst_inactive = {1'b1};
        }
    endgroup
 
    // CG3: enable high and low
    covergroup cg_enable;
        cp_enable : coverpoint item_for_cov.enable {
            bins enable_on  = {1'b1};
            bins enable_off = {1'b0};
        }
    endgroup
 
    // CG4: All 3 state transitions R→G, G→Y, Y→R
    covergroup cg_transitions;
        cp_trans : coverpoint item_for_cov.light {
            bins red_to_green    = (2'b00 => 2'b01);
            bins green_to_yellow = (2'b01 => 2'b10);
            bins yellow_to_red   = (2'b10 => 2'b00);
        }
    endgroup
 
    // CG5: Cross state x enable (6 bins)
    covergroup cg_state_x_enable;

    option.per_instance = 1;

    cp_state : coverpoint item_for_cov.light {
        bins red    = {2'b00};
        bins green  = {2'b01};
        bins yellow = {2'b10};

        // 2'b11 is not a valid DUT state
        ignore_bins illegal_state = {2'b11};
    }

    cp_enable : coverpoint item_for_cov.enable {
        bins enable_low  = {1'b0};
        bins enable_high = {1'b1};
    }

   state_enable_cross : cross cp_state, cp_enable {
    ignore_bins yellow_enable_low_unreachable =
        binsof(cp_state.yellow) && binsof(cp_enable.enable_low);
}

endgroup
 
    // CG6: Cross state x rst_n (6 bins)
    covergroup cg_state_x_rst;

    cp_state : coverpoint item_for_cov.light {
        bins red    = {RED_S};
        bins green  = {GREEN_S};
        bins yellow = {YELLOW_S};
    }

    cp_rst : coverpoint item_for_cov.rst_n {
        bins reset_asserted   = {0};
        bins reset_deasserted = {1};
    }

    state_rst_cross : cross cp_state, cp_rst {
        // During reset, DUT always goes to RED.
        // GREEN/YELLOW with rst_n=0 are illegal/unreachable.
        ignore_bins green_during_reset =
            binsof(cp_state.green) && binsof(cp_rst.reset_asserted);

        ignore_bins yellow_during_reset =
            binsof(cp_state.yellow) && binsof(cp_rst.reset_asserted);
    }

endgroup
 
    // CG7: Reset applied in every state (3 bins)
    covergroup cg_rst_in_state;

    cp_state : coverpoint item_for_cov.light {
        bins red    = {RED_S};
        bins green  = {GREEN_S};
        bins yellow = {YELLOW_S};
    }

    cp_rst_asserted : coverpoint item_for_cov.rst_n {
        bins asserted = {0};
    }

    rst_state_cross : cross cp_state, cp_rst_asserted {
        // Reset forces the FSM to RED immediately.
        // Therefore reset sampled with GREEN/YELLOW output is unreachable.
        ignore_bins reset_in_green =
            binsof(cp_state.green) && binsof(cp_rst_asserted.asserted);

        ignore_bins reset_in_yellow =
            binsof(cp_state.yellow) && binsof(cp_rst_asserted.asserted);
    }

endgroup
 
    // CG8: Enable toggled in every state (3 bins)
    covergroup cg_enable_in_state;

    option.per_instance = 1;

    cp_state : coverpoint item_for_cov.light {
        bins red    = {2'b00};
        bins green  = {2'b01};
        bins yellow = {2'b10};

        // 2'b11 is not used by the DUT
        ignore_bins illegal_state = {2'b11};
    }

    cp_enable_low : coverpoint item_for_cov.enable {
        bins low = {1'b0};
    }

    enable_state_cross : cross cp_state, cp_enable_low {
    ignore_bins yellow_enable_low_unreachable =
        binsof(cp_state.yellow) && binsof(cp_enable_low.low);
}

endgroup
 
    // ── Constructor ───────────────────────────────────────
    function new(string name = "tsc_scoreboard",
                 uvm_component parent = null);
        super.new(name, parent);
        prev_light     = 2'b00;
        prev_enable    = 1'b1;
        state_timer    = 0;
        first_sample   = 1;
        enable_was_low = 0;
        pass_count     = 0;
        fail_count     = 0;
        reset_count    = 0;
        red_time       = 30;
        green_time     = 25;
        yellow_time    = 5;
        cg_states          = new();
        cg_rst             = new();
        cg_enable          = new();
        cg_transitions     = new();
        cg_state_x_enable  = new();
        cg_state_x_rst     = new();
        cg_rst_in_state    = new();
        cg_enable_in_state = new();
    endfunction
 
    // ── Build phase: create FIFO + get timing from config ─
    function void build_phase(uvm_phase phase);
        tsc_config cfg;
        super.build_phase(phase);
        sb_fifo = new("sb_fifo", this);
        if (uvm_config_db #(tsc_config)::get(
                this, "", "tsc_config", cfg)) begin
            red_time    = cfg.red_time;
            green_time  = cfg.green_time;
            yellow_time = cfg.yellow_time;
        end
    endfunction
 
    // ── Run phase ─────────────────────────────────────────
    task run_phase(uvm_phase phase);
    tsc_item item;

    forever begin
        sb_fifo.get(item);

        // 1. Skip X/Z samples
        if ($isunknown({item.rst_n, item.enable,
                        item.light, item.red, item.green, item.yellow})) begin
            `uvm_info("SCOREBOARD",
                      $sformatf("Skipping X/Z sample: rst_n=%b enable=%b light=%b r=%b g=%b y=%b",
                                item.rst_n, item.enable,
                                item.light, item.red, item.green, item.yellow),
                      UVM_LOW)
            continue;
        end
      if (item.light == 2'b00 && item.enable == 1'b0) begin
    `uvm_info("COV_DEBUG", "HIT: RED with enable=0", UVM_LOW)
end

if (item.light == 2'b01 && item.enable == 1'b0) begin
    `uvm_info("COV_DEBUG", "HIT: GREEN with enable=0", UVM_LOW)
end

if (item.light == 2'b10 && item.enable == 1'b0) begin
    `uvm_info("COV_DEBUG", "HIT: YELLOW with enable=0", UVM_LOW)
end
      	item_for_cov = item;
        cg_states.sample();
        cg_rst.sample();
        cg_enable.sample();
        cg_transitions.sample();
        cg_state_x_enable.sample();
        cg_state_x_rst.sample();
        cg_rst_in_state.sample();
        cg_enable_in_state.sample();

        // 2. During reset, do not count as failure
        if (!item.rst_n) begin
            reset_count++;
            prev_light   = 2'b00;
            state_timer  = 0;
            first_sample = 1;
            continue;
        end

        // 3. If enable is low, state is expected to freeze.
        // Do not do duration transition check here.
        if (!item.enable) begin
            continue;
        end

        // 4. Now do normal one-hot check
        if ((item.red + item.green + item.yellow) != 1) begin
            `uvm_error("SCOREBOARD",
                       $sformatf("FAIL: not one-hot r=%b g=%b y=%b",
                                 item.red, item.green, item.yellow))
            fail_count++;
        end else begin
            pass_count++;
        end

        // 5. Now do light/output matching check
        case (item.light)
            2'b00: begin
                if (!(item.red && !item.green && !item.yellow)) begin
                    `uvm_error("SCOREBOARD",
                               $sformatf("FAIL: light=%b mismatch r=%b g=%b y=%b",
                                         item.light, item.red, item.green, item.yellow))
                    fail_count++;
                end
            end

            2'b01: begin
                if (!(!item.red && item.green && !item.yellow)) begin
                    `uvm_error("SCOREBOARD",
                               $sformatf("FAIL: light=%b mismatch r=%b g=%b y=%b",
                                         item.light, item.red, item.green, item.yellow))
                    fail_count++;
                end
            end

            2'b10: begin
                if (!(!item.red && !item.green && item.yellow)) begin
                    `uvm_error("SCOREBOARD",
                               $sformatf("FAIL: light=%b mismatch r=%b g=%b y=%b",
                                         item.light, item.red, item.green, item.yellow))
                    fail_count++;
                end
            end

            default: begin
                `uvm_error("SCOREBOARD",
                           $sformatf("FAIL: illegal light=%b", item.light))
                fail_count++;
            end
        endcase

        // Your duration/transition checks can come after this
    end
endtask
 
    // Helper: get state name string
    function string get_state_name(logic [1:0] s);
        case (s)
            2'b00:   return "RED   ";
            2'b01:   return "GREEN ";
            2'b10:   return "YELLOW";
            default: return "UNKNWN";
        endcase
    endfunction
 
    // ── Report phase ──────────────────────────────────────
    function void report_phase(uvm_phase phase);
        `uvm_info("SCOREBOARD", $sformatf(
            "\n==========================================\n  SCOREBOARD SUMMARY\n  PASS         : %0d\n  FAIL         : %0d\n  RESET COUNT  : %0d\n==========================================",
            pass_count, fail_count, reset_count), UVM_NONE)
 
        if (fail_count == 0)
            `uvm_info("SCOREBOARD", "*** ALL CHECKS PASSED ***", UVM_NONE)
        else
            `uvm_error("SCOREBOARD",
                $sformatf("*** %0d CHECKS FAILED ***", fail_count))
 
        `uvm_info("COVERAGE", $sformatf(
            "\n==========================================\n  FUNCTIONAL COVERAGE REPORT\n  cg_states          : %0.2f%%\n  cg_rst             : %0.2f%%\n  cg_enable          : %0.2f%%\n  cg_transitions     : %0.2f%%\n  cg_state_x_enable  : %0.2f%%\n  cg_state_x_rst     : %0.2f%%\n  cg_rst_in_state    : %0.2f%%\n  cg_enable_in_state : %0.2f%%\n==========================================",
            cg_states.get_coverage(),
            cg_rst.get_coverage(),
            cg_enable.get_coverage(),
            cg_transitions.get_coverage(),
            cg_state_x_enable.get_coverage(),
            cg_state_x_rst.get_coverage(),
            cg_rst_in_state.get_coverage(),
            cg_enable_in_state.get_coverage()),
            UVM_NONE)
    endfunction
 
endclass
 
 
// ============================================================
//  AGENT
// ============================================================
class tsc_agent extends uvm_agent;
 
    `uvm_component_utils(tsc_agent)
 
    tsc_config    cfg;
    tsc_driver    driver;
    tsc_sequencer sequencer;
    tsc_monitor   monitor;
 
    function new(string name = "tsc_agent",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction
 
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db #(tsc_config)::get(
                this, "", "tsc_config", cfg))
            `uvm_fatal("AGENT", "Cannot get tsc_config from config_db")
        monitor = tsc_monitor::type_id::create("monitor", this);
        if (cfg.is_active == UVM_ACTIVE) begin
            driver    = tsc_driver::type_id::create("driver",    this);
            sequencer = tsc_sequencer::type_id::create("sequencer", this);
        end
    endfunction
 
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (cfg.is_active == UVM_ACTIVE)
            driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
 
endclass
 
 
// ============================================================
//  ENVIRONMENT
//  monitor.ap → scoreboard.sb_fifo.analysis_export
// ============================================================
class tsc_env extends uvm_env;
 
    `uvm_component_utils(tsc_env)
 
    tsc_agent      agent;
    tsc_scoreboard scoreboard;
 
    function new(string name = "tsc_env",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction
 
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = tsc_agent::type_id::create("agent",      this);
        scoreboard = tsc_scoreboard::type_id::create("scoreboard", this);
    endfunction
 
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.ap.connect(scoreboard.sb_fifo.analysis_export);
    endfunction
 
endclass
 
 
// ============================================================
//  TEST
// ============================================================
class tsc_test extends uvm_test;
 
    `uvm_component_utils(tsc_test)
 
    tsc_env    env;
    tsc_config cfg;
 
    function new(string name = "tsc_test",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction
 
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Step 1: create cfg
        cfg             = tsc_config::type_id::create("cfg");
        cfg.is_active   = UVM_ACTIVE;
        cfg.red_time    = 30;
        cfg.green_time  = 25;
        cfg.yellow_time = 5;
        // Step 2: get vif and store in cfg
        if (!uvm_config_db #(virtual tsc_if)::get(
                this, "", "vif", cfg.vif))
            `uvm_fatal("TEST", "Cannot get virtual interface from config_db")
        // Step 3: set cfg BEFORE creating env
        uvm_config_db #(tsc_config)::set(this, "*", "tsc_config", cfg);
        // Step 4: create env
        env = tsc_env::type_id::create("env", this);
    endfunction
 
    task run_phase(uvm_phase phase);
        tsc_full_seq seq;
        phase.raise_objection(this);
        `uvm_info("TEST", "Starting Traffic Signal Controller UVM test", UVM_LOW)
        seq = tsc_full_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);
        #500;
        `uvm_info("TEST", "Traffic Signal Controller UVM test complete", UVM_LOW)
        phase.drop_objection(this);
    endtask
 
endclass
 
 
// ============================================================
//  TOP MODULE
// ============================================================
module tsc_tb_top;
 
    logic clk;
    initial clk = 0;
    always #5 clk = ~clk;
 
    // Interface
    tsc_if dut_if (.clk(clk));
 
    // DUT
    traffic_signal_controller dut (
        .clk    (clk),
        .rst_n  (dut_if.rst_n),
        .enable (dut_if.enable),
        .light  (dut_if.light),
        .red    (dut_if.red),
        .green  (dut_if.green),
        .yellow (dut_if.yellow)
    );
 	initial begin
    dut_if.rst_n  = 1'b0;
    dut_if.enable = 1'b0;
	end
    initial begin
        uvm_config_db #(virtual tsc_if)::set(
            null, "*", "vif", dut_if);
        $dumpfile("tsc_tb.vcd");
        $dumpvars(0, tsc_tb_top);
        run_test("tsc_test");
    end
 
    initial begin
        #1_000_000;
        `uvm_fatal("TIMEOUT", "Simulation exceeded 1ms — hung")
    end
endmodule