`timescale 1ns / 1ps

interface reg_interface;
    logic        clk;
    logic        rst;
    logic        enable;
    logic [31:0] d;
    logic [31:0] q;
endinterface

class transaction;
    bit             rst;
    rand bit        enable;
    rand bit [31:0] d;
    logic    [31:0] q;

    function void debug_print(string name);
        $display("%t : [%s] enable = %d, d = %d, q = %d", $time, name, enable,
                 d, q);
    endfunction


endclass

class transaction2;
    bit             rst;
    rand bit        enable;
    rand bit [31:0] d;
    logic    [31:0] q;

    function void debug_print(string name);
        $display("%t : [%s] enable = %d, d = %d, q = %d", $time, name, enable,
                 d, q);
    endfunction


endclass

class generator;
    transaction  tr;
    transaction2 tr_scb;

    mailbox #(transaction)  gen2drv_mbox;
    mailbox #(transaction2) gen2scb_mbox;

    event event2_gen;

    function new(
        mailbox #(transaction) gen2drv_mbox,
        mailbox #(transaction2) gen2scb_mbox,
        event event2_gen
    );
        this.gen2drv_mbox = gen2drv_mbox;
        this.gen2scb_mbox = gen2scb_mbox;
        this.event2_gen = event2_gen;
    endfunction

    task run(int run_count);
        repeat (run_count) begin

            tr = new;
            tr.randomize();

            tr_scb = new;
            tr_scb.enable = tr.enable;
            tr_scb.d      = tr.d;
            tr_scb.q      = tr.q;

            gen2drv_mbox.put(tr);
            gen2scb_mbox.put(tr_scb);
            tr_scb.debug_print("GEN_TR_SCB");
            tr.debug_print("GEN");
            @(event2_gen);
        end
    endtask

endclass

class driver;
    transaction tr;
    mailbox #(transaction) gen2drv_mbox;
    virtual reg_interface reg_vif;

    event event2_mon;

    function new(mailbox#(transaction) gen2drv_mbox,
                 virtual reg_interface reg_vif);
        this.gen2drv_mbox = gen2drv_mbox;
        this.reg_vif      = reg_vif;
    endfunction

    task preset();
        reg_vif.rst    = 1;
        reg_vif.enable = 0;
        reg_vif.d      = 0;
        @(negedge reg_vif.clk);
        @(negedge reg_vif.clk);
        reg_vif.rst = 0;
        @(negedge reg_vif.clk);
    endtask

    task run();
        forever begin
            gen2drv_mbox.get(tr);
            @(posedge reg_vif.clk);
            #1;
            reg_vif.enable = tr.enable;
            reg_vif.d = tr.d;
            tr.debug_print("DRV");
            #1;
        end
    endtask

endclass

class monitor;
    transaction tr;
    mailbox #(transaction) mon2scb_mbox;
    virtual reg_interface reg_vif;

    function new(mailbox#(transaction) mon2scb_mbox,
                 virtual reg_interface reg_vif);
        this.mon2scb_mbox = mon2scb_mbox;
        this.reg_vif = reg_vif;
    endfunction

    task run();
        forever begin
            @(negedge reg_vif.clk);
            tr = new;
            tr.enable = reg_vif.enable;
            tr.d = reg_vif.d;
            tr.q = reg_vif.q;
            mon2scb_mbox.put(tr);
            tr.debug_print("MON");
        end
    endtask

endclass

class scoreboard;

    transaction  tr;
    transaction2 tr_scb;

    mailbox #(transaction2) gen2scb_mbox;
    mailbox #(transaction)  mon2scb_mbox;

    event event2_gen;

    int pass_cnt = 0;
    int fail_cnt = 0;

    bit [31:0] expected_q = 0;

    function new(
        mailbox #(transaction2) gen2scb_mbox,
        mailbox #(transaction) mon2scb_mbox,
        event event2_gen
    );
        this.gen2scb_mbox = gen2scb_mbox;
        this.mon2scb_mbox = mon2scb_mbox;
        this.event2_gen   = event2_gen;
    endfunction

    bit first_flag = 0;

    task run();
        forever begin

           mon2scb_mbox.get(tr);
           if (first_flag) begin
                tr.debug_print("SCB");
                if (tr.scb.enable) begin
                    if(tr_scb.d == tr.q) $display("PASS");
                    else $display("FAIL : gen.d = %d, tr.q = %d", tr_scb.d, tr.q);
                end
           end else
                first_flag = 1;
            gen2scb_mbox.get(tr_scb);
            -> event2_gen;
        end
    endtask

endclass

class environment;

    generator              gen;
    driver                 drv;
    monitor                mon;
    scoreboard             scb;

    mailbox #(transaction)  gen2drv_mbox;
    mailbox #(transaction2) gen2scb_mbox;
    mailbox #(transaction)  mon2scb_mbox;

    event                  event2_gen;

    function new(virtual reg_interface reg_vif);
        gen2drv_mbox = new;
        gen2scb_mbox = new;
        mon2scb_mbox = new;

        gen = new(gen2drv_mbox, gen2scb_mbox, event2_gen);
        drv = new(gen2drv_mbox, reg_vif);
        mon = new(mon2scb_mbox, reg_vif);
        scb = new(gen2scb_mbox, mon2scb_mbox, event2_gen);

    endfunction

    task run();
        drv.preset();
        fork
            gen.run(10);
            drv.run();
            mon.run();
            scb.run();
        join_any
        #10;
        $display("end process env");
        $finish;
    endtask

endclass

module tb_register_sv ();

    reg_interface reg_if ();
    environment env;

    register_sv dut (
        .clk   (reg_if.clk),
        .rst   (reg_if.rst),
        .enable(reg_if.enable),
        .d     (reg_if.d),
        .q     (reg_if.q)
    );

    always #5 reg_if.clk = ~reg_if.clk;

    initial begin
        reg_if.clk = 0;
        env = new(reg_if);
        env.run();
    end

endmodule

