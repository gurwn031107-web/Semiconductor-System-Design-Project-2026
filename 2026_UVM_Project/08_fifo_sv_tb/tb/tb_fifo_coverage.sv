`timescale 1ns / 1ps

interface fifo_interface (
    input logic clk
);
    localparam WIDTH = 4;
    localparam DEPTH = 2 ** WIDTH;
    logic reset = 0, push = 0, pop = 0;
    logic [7:0] w_data = 0;
    logic [7:0] r_data;
    logic full, empty;
    // TB-only marker: not connected to the DUT.
    bit valid = 0;
    bit random_phase = 0;  // TB-only tag for the 256 random requests
endinterface

class transaction;
    rand bit push, pop;
    rand bit [7:0] w_data;
    bit reset;
    bit random_phase = 0;
    int id;
    logic [7:0] r_data;
    logic full, empty;
    logic full_after, empty_after;
    logic [7:0] r_data_after;

    function void display(string name);
        $display(
            "%0t [%s] reset=%b push=%b pop=%b w_data=%02h r_data=%02h full=%b empty=%b",
            $time, name, reset, push, pop, w_data, r_data, full, empty);
    endfunction
endclass

// Functional coverage for the existing non-UVM class-based testbench.
// State and acceptance use PRE-edge flags, matching the scoreboard policy.
class fifo_coverage;
    transaction item;
    int sample_count = 0;
    int accepted_write_samples = 0, accepted_read_samples = 0;

    covergroup fifo_cg;
        option.per_instance = 1;

        cp_reset: coverpoint item.reset {
            bins inactive = {0}; bins active = {1};
        }
        cp_request: coverpoint {
            item.push, item.pop
        } iff (!item.reset) {
            bins idle = {2'b00};
            bins pop_only = {2'b01};
            bins push_only = {2'b10};
            bins simultaneous = {2'b11};
        }
        cp_state: coverpoint {
            item.full, item.empty
        } iff (!item.reset) {
            bins middle = {2'b00};
            bins empty = {2'b01};
            bins full = {2'b10};
            // Invalid flags remain a scoreboard failure, not a coverage goal.
            ignore_bins invalid = {2'b11};
        }
        cp_push: coverpoint item.full iff (!item.reset && item.push) {
            bins accepted = {0}; bins blocked = {1};
        }
        cp_pop: coverpoint item.empty iff (!item.reset && item.pop) {
            bins accepted = {0}; bins blocked = {1};
        }
        cp_wdata: coverpoint item.w_data
            iff (!item.reset && item.push && (item.full === 1'b0)) {
            bins values[] = {[0 : 255]};
        }
        // The existing DUT/testbench uses the PRE-edge head for a read.
        cp_rdata: coverpoint item.r_data
            iff (!item.reset && item.pop && (item.empty === 1'b0)) {
            bins values[] = {[0 : 255]};
        }
        cp_full_change: coverpoint {
            item.full, item.full_after
        } iff (!item.reset) {
            bins stay_not_full = {2'b00};
            bins become_full = {2'b01};
            bins leave_full = {2'b10};
            bins stay_full = {2'b11};
        }
        cp_empty_change: coverpoint {
            item.empty, item.empty_after
        } iff (!item.reset) {
            bins stay_not_empty = {2'b00};
            bins become_empty = {2'b01};
            bins leave_empty = {2'b10};
            bins stay_empty = {2'b11};
        }
        // 4 request types x 3 valid PRE-edge states = 12 combinations.
        cx_request_state: cross cp_request, cp_state;
    endgroup

    function new();
        fifo_cg = new();
    endfunction

    function void sample (transaction tr);
        item = tr;
        sample_count++;
        if (!tr.reset && tr.push && (tr.full === 1'b0))
            accepted_write_samples++;
        if (!tr.reset && tr.pop && (tr.empty === 1'b0)) accepted_read_samples++;
        fifo_cg.sample();
    endfunction

    function void report();
        $display("========== FIFO FUNCTIONAL COVERAGE ==========");
        $display("Scope: all scenarios, including reset and final drain");
        $display("Samples=%0d accepted writes=%0d accepted reads=%0d",
                 sample_count, accepted_write_samples, accepted_read_samples);
        $display("Overall       : %0.2f%%", fifo_cg.get_inst_coverage());
        $display("Reset         : %0.2f%%",
                 fifo_cg.cp_reset.get_inst_coverage());
        // $display("FIFO state    : %0.2f%%",fifo_cg.cp_state.get_inst_coverage());
        $display("Push   : %0.2f%%", fifo_cg.cp_push.get_inst_coverage());
        $display("Pop    : %0.2f%%", fifo_cg.cp_pop.get_inst_coverage());
        $display("w_data    : %0.2f%%", fifo_cg.cp_wdata.get_inst_coverage());
        $display("r_data     : %0.2f%%", fifo_cg.cp_rdata.get_inst_coverage());
        $display("Full   : %0.2f%%",
                 fifo_cg.cp_full_change.get_inst_coverage());
        $display("Empty          : %0.2f%%",
                 fifo_cg.cp_empty_change.get_inst_coverage());
        $display("Request/state : %0.2f%%",
                 fifo_cg.cx_request_state.get_inst_coverage());
        $display("==============================================");
    endfunction
endclass

class generator;
    localparam DEPTH = 16;
    mailbox #(transaction) gen2drv_mbox;
    // A mailbox acknowledgment cannot be lost like a transient event.
    mailbox #(bit) scb2gen_mbox;
    int generated_cnt = 0;
    int random_generated_cnt = 0;

    function new(mailbox#(transaction) gen2drv_mbox,
                 mailbox#(bit) scb2gen_mbox);
        this.gen2drv_mbox = gen2drv_mbox;
        this.scb2gen_mbox = scb2gen_mbox;
    endfunction

    task send(bit rst, bit wr, bit rd, bit [7:0] data = 0);
        transaction tr;
        bit ack;
        tr = new;
        tr.reset = rst;
        tr.push = wr;
        tr.pop = rd;
        tr.w_data = data;
        generated_cnt++;
        tr.id = generated_cnt;
        if (!$test$plusargs("QUIET"))
            $display(
                "%0t [gen #%0d] reset=%b push=%b pop=%b w_data=%02h random=%b",
                $time,
                tr.id,
                tr.reset,
                tr.push,
                tr.pop,
                tr.w_data,
                tr.random_phase
            );
        gen2drv_mbox.put(tr);
        scb2gen_mbox.get(ack);
    endtask

    task run(int run_count);
        transaction tr;
        bit ack;
        $display("[GEN] SCENARIO 1: RESET / EMPTY SIMULTANEOUS");
        send(1, 0, 0);
        send(0, 0, 0);
        // Random data for Empty simultaneous request; only push is accepted.
        // Match the reference UART example by excluding zero.
        tr = new;
        if (!tr.randomize() with {
                push == 1;
                pop == 1;
                w_data != 8'h00;
            })
            $fatal(1, "[GEN] Empty simultaneous randomization failed");
        send(0, 1, 1, tr.w_data);
        // Keep the first item at address 0; append exactly 15 items.
        $display("[GEN] SCENARIO 2: APPEND 15 RANDOM ITEMS / FULL");
        repeat (DEPTH - 1) begin
            tr = new;
            if (!tr.randomize() with {
                    push == 1;
                    pop == 0;
                    w_data != 8'h00;
                })
                $fatal(1, "[GEN] Fill randomization failed");
            send(0, 1, 0, tr.w_data);
        end
        // Hold Full for a complete cycle to make the memory easy to inspect.
        send(0, 0, 0, tr.w_data);
        $display("[GEN] SCENARIO 3: FULL SIMULTANEOUS");
        tr = new;
        if (!tr.randomize() with {
                push == 1;
                pop == 1;
                w_data != 8'h00;
            })
            $fatal(1, "[GEN] Full simultaneous randomization failed");
        send(0, 1, 1, tr.w_data);  // Pop accepted; new write rejected.
        $display("[GEN] SCENARIO 4: DRAIN REMAINING 15 ITEMS");
        repeat (DEPTH - 1) send(0, 0, 1);
        // One additional pop confirms Empty rejection.
        send(0, 0, 1);
        $display("[GEN] SCENARIO 5: RANDOM: %0d transactions", run_count);
        repeat (run_count) begin
            tr = new;
            if (!tr.randomize()) $fatal(1, "[GEN] randomization failed");
            tr.reset = 0;
            tr.random_phase = 1;
            random_generated_cnt++;
            generated_cnt++;
            tr.id = generated_cnt;
            if (!$test$plusargs("QUIET"))
                $display(
                    "%0t [gen #%0d] reset=%b push=%b pop=%b w_data=%02h random=1",
                    $time,
                    tr.id,
                    tr.reset,
                    tr.push,
                    tr.pop,
                    tr.w_data
                );
            gen2drv_mbox.put(tr);
            scb2gen_mbox.get(ack);
        end
        $display("[GEN] CLEANUP: FINAL DRAIN (excluded from random report)");
        repeat (DEPTH + 1) send(0, 0, 1);
        send(0, 0, 0);
    endtask
endclass

class driver;
    mailbox #(transaction) gen2drv_mbox;
    virtual fifo_interface f_if;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual fifo_interface f_if);
        this.gen2drv_mbox = gen2drv_mbox;
        this.f_if = f_if;
    endfunction

    task preset();
        f_if.valid = 0;
        f_if.reset = 1;
        f_if.push = 0;
        f_if.pop = 0;
        f_if.w_data = 0;
        repeat (3) @(negedge f_if.clk);
        f_if.reset = 0;
    endtask

    task run();
        transaction tr;
        // First drive: 1ns after a rising edge.
        // Later items arrive through the scoreboard acknowledgment at
        // the next processing edge +1ns. Do not wait an extra clock here:
        // holding push/pop for another edge would duplicate an operation.
        @(posedge f_if.clk);
        #1;
        forever begin
            gen2drv_mbox.get(tr);
            f_if.reset <= tr.reset;
            f_if.push <= tr.push;
            f_if.pop <= tr.pop;
            f_if.w_data <= tr.w_data;
            f_if.valid <= 1;
            f_if.random_phase <= tr.random_phase;
            if (!$test$plusargs("QUIET"))
                $display(
                    "%0t [drv #%0d] drive reset=%b push=%b pop=%b w_data=%02h | current full=%b empty=%b r_data=%02h",
                    $time,
                    tr.id,
                    tr.reset,
                    tr.push,
                    tr.pop,
                    tr.w_data,
                    f_if.full,
                    f_if.empty,
                    f_if.r_data
                );
        end
    endtask
endclass

class monitor;
    fifo_coverage cov;
    mailbox #(transaction) mon2scb_mbox;
    virtual fifo_interface f_if;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual fifo_interface f_if, fifo_coverage cov);
        this.mon2scb_mbox = mon2scb_mbox;
        this.f_if = f_if;
        this.cov = cov;
    endfunction

    task run();
        transaction tr;
        int sample_id = 0;
        forever begin
            @(posedge f_if.clk);
            if (f_if.valid) begin
                tr = new;
                sample_id++;
                tr.id = sample_id;
                // Capture old head before RTL nonblocking pointer updates.
                tr.reset = f_if.reset;
                tr.random_phase = f_if.random_phase;
                tr.push = f_if.push;
                tr.pop = f_if.pop;
                tr.w_data = f_if.w_data;
                tr.r_data = f_if.r_data;
                tr.full = f_if.full;
                tr.empty = f_if.empty;
                if (!$test$plusargs("QUIET"))
                    $display(
                        "%0t [mon PRE #%0d] reset=%b push=%b pop=%b w_data=%02h full=%b empty=%b r_data=%02h",
                        $time,
                        tr.id,
                        tr.reset,
                        tr.push,
                        tr.pop,
                        tr.w_data,
                        tr.full,
                        tr.empty,
                        tr.r_data
                    );
                // Separately observe the result of this clock edge.
                #1;
                tr.full_after   = f_if.full;
                tr.empty_after  = f_if.empty;
                tr.r_data_after = f_if.r_data;
                if (!$test$plusargs("QUIET"))
                    $display(
                        "%0t [mon POST #%0d] full=%b empty=%b r_data=%02h",
                        $time,
                        tr.id,
                        tr.full_after,
                        tr.empty_after,
                        tr.r_data_after
                    );
                // Sample synchronously before the scoreboard acknowledges.
                cov.sample(tr);
                mon2scb_mbox.put(tr);
            end
        end
    endtask
endclass

class scoreboard;
    localparam DEPTH = 16;
    mailbox #(transaction) mon2scb_mbox;
    mailbox #(bit) scb2gen_mbox;
    logic [7:0] fifo_queue[$];
    int pass_cnt = 0, fail_cnt = 0, compared_cnt = 0;
    int push_cnt = 0, pop_cnt = 0;
    int blocked_push_cnt = 0, blocked_pop_cnt = 0;
    int random_sample_cnt = 0, random_pop_cnt = 0;
    int random_pass_cnt = 0, random_fail_cnt = 0;

    function new(mailbox#(transaction) mon2scb_mbox,
                 mailbox#(bit) scb2gen_mbox);
        this.mon2scb_mbox = mon2scb_mbox;
        this.scb2gen_mbox = scb2gen_mbox;
    endfunction

    task run();
        transaction tr;
        logic [7:0] removed;
        bit ok;
        int before_count, after_count;
        forever begin
            mon2scb_mbox.get(tr);
            ok = 1;
            before_count = fifo_queue.size();
            // Presentation report counts only accepted reads in random phase.
            // Compare the PRE-edge head before changing the reference queue.
            if (tr.random_phase) begin
                random_sample_cnt++;
                if (!tr.reset && tr.pop && tr.empty === 1'b0) begin
                    random_pop_cnt++;
                    if (before_count > 0) begin
                        if (tr.r_data === fifo_queue[0]) random_pass_cnt++;
                        else random_fail_cnt++;
                    end else random_fail_cnt++;
                end
            end
            if (tr.reset) begin
                fifo_queue.delete();
                if (tr.full !== 1'b0 || tr.empty !== 1'b1) ok = 0;
            end else begin
                if(tr.full !== (before_count==DEPTH) ||
                   tr.empty !== (before_count==0)) begin
                    ok = 0;
                    $display("[SCB] PRE FLAG FAIL count=%0d", before_count);
                end
                if (before_count > 0) begin
                    if (tr.r_data !== fifo_queue[0]) begin
                        ok = 0;
                        $display("[SCB] DATA FAIL expected=%02h actual=%02h",
                                 fifo_queue[0], tr.r_data);
                    end
                end
                // Use PRE-edge model occupancy for BOTH acceptance decisions.
                if (tr.pop && before_count > 0) begin
                    removed = fifo_queue.pop_front();
                    pop_cnt++;
                end
                if (tr.push && before_count < DEPTH) begin
                    fifo_queue.push_back(tr.w_data);
                    push_cnt++;
                end
                if (tr.push && before_count == DEPTH) blocked_push_cnt++;
                if (tr.pop && before_count == 0) blocked_pop_cnt++;
            end
            after_count = fifo_queue.size();
            if(tr.full_after !== (after_count==DEPTH) ||
               tr.empty_after !== (after_count==0)) begin
                ok = 0;
                $display("[SCB] POST FLAG FAIL count=%0d", after_count);
            end
            if (after_count > 0) begin
                if (tr.r_data_after !== fifo_queue[0]) begin
                    ok = 0;
                    $display("[SCB] POST DATA FAIL expected=%02h actual=%02h",
                             fifo_queue[0], tr.r_data_after);
                end
            end
            compared_cnt++;
            if (!$test$plusargs("QUIET") || !ok) begin
                if (!tr.reset && tr.pop && before_count > 0)
                    $display(
                        "%0t [%s] Pop #%0d Expected=%02h Actual=%02h random=%b",
                        $time,
                        (removed === tr.r_data) ? "PASS" : "FAIL",
                        tr.id,
                        removed,
                        tr.r_data,
                        tr.random_phase
                    );
                if (!tr.reset && tr.pop && before_count == 0)
                    $display(
                        "%0t [scb #%0d] Empty: Pop must be blocked",
                        $time,
                        tr.id
                    );
                if (!tr.reset && tr.push && before_count == DEPTH)
                    $display(
                        "%0t [scb #%0d] Full: Push must be blocked",
                        $time,
                        tr.id
                    );
                $display(
                    "%0t [%s] Request #%0d count=%0d->%0d full Expected/Actual=%b/%b empty Expected/Actual=%b/%b",
                    $time, ok ? "PASS" : "FAIL", tr.id, before_count,
                    after_count, (after_count == DEPTH), tr.full_after,
                    (after_count == 0), tr.empty_after);
            end
            if (ok) begin
                pass_cnt++;
            end else begin
                fail_cnt++;
                tr.display("FAIL");
            end
            scb2gen_mbox.put(ok);
        end
    endtask
endclass

class environment;
    fifo_coverage cov;
    generator gen;
    driver drv;
    monitor mon;
    scoreboard scb;
    mailbox #(transaction) gen2drv_mbox, mon2scb_mbox;
    mailbox #(bit) scb2gen_mbox;
    virtual fifo_interface f_if;

    function new(virtual fifo_interface f_if);
        this.f_if = f_if;
        gen2drv_mbox = new;
        mon2scb_mbox = new;
        scb2gen_mbox = new;
        gen = new(gen2drv_mbox, scb2gen_mbox);
        drv = new(gen2drv_mbox, f_if);
        cov = new();
        mon = new(mon2scb_mbox, f_if, cov);
        scb = new(mon2scb_mbox, scb2gen_mbox);
    endfunction

    task run();
        drv.preset();
        fork
            gen.run(256);
            drv.run();
            mon.run();
            scb.run();
        join_any
        // Generator returns only after its FINAL sample is checked.
        disable fork;
        @(negedge f_if.clk);
        f_if.valid = 0;
        f_if.push  = 0;
        f_if.pop   = 0;
        $display("========== ALL SCENARIOS: REQUEST CHECKS ==========");
        $display(
            "generated=%0d compared=%0d request_pass=%0d request_fail=%0d",
            gen.generated_cnt, scb.compared_cnt, scb.pass_cnt, scb.fail_cnt);
        $display("accepted push=%0d pop=%0d blocked push=%0d pop=%0d",
                 scb.push_cnt, scb.pop_cnt, scb.blocked_push_cnt,
                 scb.blocked_pop_cnt);
        $display("==================================================");
        $display("[ TEST REPORT ] RANDOM TEST SIMULATION FINISHED!");
        $display("--------------------------------------------------");
        $display("Generated wdata Count : %0d", gen.random_generated_cnt);
        $display("Actual Pop Count      : %0d", scb.random_pop_cnt);
        $display("Total PASS Count      : %0d", scb.random_pass_cnt);
        $display("Total FAIL Count      : %0d", scb.random_fail_cnt);
        cov.report();
        if(scb.fail_cnt!=0 || scb.compared_cnt!=gen.generated_cnt ||
           cov.sample_count!=scb.compared_cnt ||
           gen.random_generated_cnt!=256 ||
           scb.random_sample_cnt!=gen.random_generated_cnt ||
           scb.random_pop_cnt==0 || scb.random_fail_cnt!=0 ||
           scb.random_pass_cnt+scb.random_fail_cnt!=scb.random_pop_cnt ||
           scb.compared_cnt==0 || scb.fifo_queue.size()!=0 ||
           scb.push_cnt==0 || scb.pop_cnt==0 ||
           scb.blocked_push_cnt==0 || scb.blocked_pop_cnt==0) begin
            $display(
                "Result : FAIL (see complete log for request/data errors)");
            $fatal(1, "FIFO TEST FAILED");
        end
        $display("Result : PASS");
        $display("==================================================");
        $display("FIFO TEST PASS");
        $finish;
    endtask
endclass

module tb_fifo_uvm;
    logic clk = 0;
    always #5 clk = ~clk;
    fifo_interface f_if (clk);
    environment env;
    fifo #(
        .WIDTH(4)
    ) dut (
        .clk(clk),
        .reset(f_if.reset),
        .push(f_if.push),
        .pop(f_if.pop),
        .w_data(f_if.w_data),
        .r_data(f_if.r_data),
        .full(f_if.full),
        .empty(f_if.empty)
    );
    initial begin
`ifdef VCD_ONLY
        $dumpfile("wave.vcd");
        $dumpvars(0);
`else
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0, tb_fifo_uvm);
        $fsdbDumpMDA();
`endif
    end
    initial begin
        $display("[TB_VERSION] FIFO_RANDOM256_POP_REPORT_V3_COVERAGE");
        env = new(f_if);
        env.run();
    end
    initial begin
        #1000000;
        $fatal(1, "TIMEOUT: test did not finish");
    end
endmodule

