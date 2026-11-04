`include "uvm_macros.svh"
import uvm_pkg::*;

// Operation groups and random scenarios
typedef enum int unsigned { MODE_NORMAL, MODE_CONSTRAINED } random_mode_e;
typedef enum int unsigned { GROUP_GENERAL, GROUP_LOGIC, GROUP_SHIFT } op_group_e;
typedef enum int unsigned {
    SC_NORMAL, SC_POS_OVERFLOW, SC_NEG_OVERFLOW,
    SC_EQUAL, SC_LESS, SC_GREATER, SC_DIFFERENT_SIGN
} scenario_e;
typedef enum int unsigned {
    PAT_ZERO, PAT_ONES, PAT_ONE_HOT, PAT_ONE_COLD,
    PAT_ALT_A, PAT_ALT_5, PAT_RANDOM
} pattern_e;

// ================================================================
// Interface
// ================================================================
interface rv32i_if(input logic clk);
    logic        rst_n;
    logic [31:0] instr;

    // DUT observation signals
    logic        rf_we;
    logic [31:0] x1_data;
    logic [31:0] x2_data;
    logic [31:0] rd3_data;

    // Driver-to-monitor sideband information (testbench only)
    logic        test_active;
    int          op;
    random_mode_e mode;
    op_group_e    group;
    scenario_e    scenario;
    pattern_e     rs1_pattern;
    pattern_e     rs2_pattern;
    logic [4:0]   shamt;
    logic [31:0]  rs1_value;
    logic [31:0]  rs2_value;
    logic [11:0]  imm;
endinterface

// ================================================================
// Sequence item: all stimulus is produced by randomize() constraints
// ================================================================
class rv32i_seq_item extends uvm_sequence_item;
    rand int unsigned op;
    rand logic [31:0] rs1_value;
    rand logic [31:0] rs2_value;
    rand logic [11:0] imm;
    rand logic [4:0] shamt;
    rand random_mode_e mode;
    rand op_group_e group;
    rand scenario_e scenario;
    rand pattern_e rs1_pattern;
    rand pattern_e rs2_pattern;

    logic [31:0] instr;
    logic [31:0] actual;
    bit          writeback_seen;

    constraint c_op { op inside {[0:18]}; }
    constraint c_group_weight {
        group dist { GROUP_GENERAL:=7, GROUP_LOGIC:=6, GROUP_SHIFT:=6 };
    }
    constraint c_op_group {
        if (mode==MODE_CONSTRAINED) {
            if (group==GROUP_GENERAL) op inside {0,1,3,4,10,11,12};
            if (group==GROUP_LOGIC)   op inside {5,8,9,13,14,15};
            if (group==GROUP_SHIFT)   op inside {2,6,7,16,17,18};
        }
    }
    constraint c_general_scenario {
        if (mode==MODE_CONSTRAINED && group==GROUP_GENERAL) {
            if (op inside {0,1,10}) scenario inside {SC_NORMAL,SC_POS_OVERFLOW,SC_NEG_OVERFLOW};
            if (op inside {3,4,11,12}) scenario inside {SC_EQUAL,SC_LESS,SC_GREATER,SC_DIFFERENT_SIGN};
        }
    }
    constraint c_arithmetic {
        if (mode==MODE_CONSTRAINED && op==0 && scenario==SC_POS_OVERFLOW) {
            rs1_value inside {[32'h40000000:32'h7fffffff]};
            rs2_value inside {[32'h40000000:32'h7fffffff]};
        }
        if (mode==MODE_CONSTRAINED && op==0 && scenario==SC_NEG_OVERFLOW) {
            rs1_value inside {[32'h80000000:32'hbfffffff]};
            rs2_value inside {[32'h80000000:32'hbfffffff]};
        }
        if (mode==MODE_CONSTRAINED && op==1 && scenario==SC_POS_OVERFLOW) {
            rs1_value inside {[32'h40000000:32'h7fffffff]};
            rs2_value inside {[32'h80000000:32'hbfffffff]};
        }
        if (mode==MODE_CONSTRAINED && op==1 && scenario==SC_NEG_OVERFLOW) {
            rs1_value inside {[32'h80000000:32'hbfffffff]};
            rs2_value inside {[32'h40000000:32'h7fffffff]};
        }
        if (mode==MODE_CONSTRAINED && op==10 && scenario==SC_POS_OVERFLOW) {
            rs1_value inside {[32'h7ffffc01:32'h7fffffff]};
            imm inside {[12'h400:12'h7ff]};
        }
        if (mode==MODE_CONSTRAINED && op==10 && scenario==SC_NEG_OVERFLOW) {
            rs1_value inside {[32'h80000000:32'h800003ff]};
            imm inside {[12'h800:12'hc00]};
        }
    }
    constraint c_compare_r {
        if (mode==MODE_CONSTRAINED && op inside {3,4}) {
            if (scenario==SC_EQUAL) rs2_value==rs1_value;
            if (scenario==SC_LESS) {
                rs1_value inside {[32'h00000000:32'h0000ffff]};
                rs2_value inside {[32'h00010000:32'h3fffffff]};
            }
            if (scenario==SC_GREATER) {
                rs1_value inside {[32'h00010000:32'h3fffffff]};
                rs2_value inside {[32'h00000000:32'h0000ffff]};
            }
            if (scenario==SC_DIFFERENT_SIGN) rs1_value[31]!=rs2_value[31];
        }
    }
    constraint c_compare_i {
        if (mode==MODE_CONSTRAINED && op inside {11,12}) {
            if (scenario==SC_EQUAL) rs1_value=={{20{imm[11]}},imm};
            if (scenario==SC_LESS) {
                rs1_value inside {[0:1023]}; imm inside {[12'h400:12'h7ff]};
            }
            if (scenario==SC_GREATER) {
                rs1_value inside {[1024:65535]}; imm inside {[12'h000:12'h3ff]};
            }
            if (scenario==SC_DIFFERENT_SIGN) rs1_value[31]!=imm[11];
        }
    }
    constraint c_logic_patterns {
        if (mode==MODE_CONSTRAINED && group==GROUP_LOGIC) {
            rs1_pattern inside {[PAT_ZERO:PAT_RANDOM]};
            rs2_pattern inside {[PAT_ZERO:PAT_RANDOM]};
            if (rs1_pattern==PAT_ZERO)     rs1_value==32'h00000000;
            if (rs1_pattern==PAT_ONES)     rs1_value==32'hffffffff;
            if (rs1_pattern==PAT_ONE_HOT)  $countones(rs1_value)==1;
            if (rs1_pattern==PAT_ONE_COLD) $countones(rs1_value)==31;
            if (rs1_pattern==PAT_ALT_A)    rs1_value==32'haaaaaaaa;
            if (rs1_pattern==PAT_ALT_5)    rs1_value==32'h55555555;
            if (op inside {5,8,9}) {
                if (rs2_pattern==PAT_ZERO)     rs2_value==32'h00000000;
                if (rs2_pattern==PAT_ONES)     rs2_value==32'hffffffff;
                if (rs2_pattern==PAT_ONE_HOT)  $countones(rs2_value)==1;
                if (rs2_pattern==PAT_ONE_COLD) $countones(rs2_value)==31;
                if (rs2_pattern==PAT_ALT_A)    rs2_value==32'haaaaaaaa;
                if (rs2_pattern==PAT_ALT_5)    rs2_value==32'h55555555;
            }
            if (op inside {13,14,15}) {
                if (rs2_pattern==PAT_ZERO)     imm==12'h000;
                if (rs2_pattern==PAT_ONES)     imm==12'hfff;
                if (rs2_pattern==PAT_ONE_HOT)  $countones(imm)==1;
                if (rs2_pattern==PAT_ONE_COLD) $countones(imm)==11;
                if (rs2_pattern==PAT_ALT_A)    imm==12'haaa;
                if (rs2_pattern==PAT_ALT_5)    imm==12'h555;
            }
        }
    }
    constraint c_shift {
        if (mode==MODE_CONSTRAINED && group==GROUP_SHIFT) {
            shamt dist {0:=5,1:=5,[2:14]:=1,15:=5,16:=5,[17:30]:=1,31:=5};
            rs1_pattern inside {PAT_ZERO,PAT_ONES,PAT_ONE_HOT,PAT_ALT_A,PAT_ALT_5,PAT_RANDOM};
            if (rs1_pattern==PAT_ZERO)    rs1_value==32'h00000000;
            if (rs1_pattern==PAT_ONES)    rs1_value==32'hffffffff;
            if (rs1_pattern==PAT_ONE_HOT) $countones(rs1_value)==1;
            if (rs1_pattern==PAT_ALT_A)   rs1_value==32'haaaaaaaa;
            if (rs1_pattern==PAT_ALT_5)   rs1_value==32'h55555555;
            if (op inside {2,6,7}) rs2_value[4:0]==shamt;
            if (op inside {16,17,18}) imm[4:0]==shamt;
        }
    }

    `uvm_object_utils_begin(rv32i_seq_item)
        `uvm_field_int(op,UVM_DEFAULT)
        `uvm_field_int(rs1_value,UVM_HEX)
        `uvm_field_int(rs2_value,UVM_HEX)
        `uvm_field_int(imm,UVM_HEX)
        `uvm_field_int(shamt,UVM_DEFAULT)
        `uvm_field_enum(random_mode_e,mode,UVM_DEFAULT)
        `uvm_field_enum(op_group_e,group,UVM_DEFAULT)
        `uvm_field_enum(scenario_e,scenario,UVM_DEFAULT)
        `uvm_field_enum(pattern_e,rs1_pattern,UVM_DEFAULT)
        `uvm_field_enum(pattern_e,rs2_pattern,UVM_DEFAULT)
        `uvm_field_int(instr,UVM_HEX)
        `uvm_field_int(actual,UVM_HEX)
        `uvm_field_int(writeback_seen,UVM_DEFAULT)
    `uvm_object_utils_end

    function new(string name="rv32i_seq_item"); super.new(name); endfunction
endclass

// ================================================================
// Sequence: first 40,000 normal-random, next 40,000 constrained-random
// ================================================================
class rv32i_sequence extends uvm_sequence #(rv32i_seq_item);
    `uvm_object_utils(rv32i_sequence)
    localparam int TESTS=80000;
    function new(string name="rv32i_sequence"); super.new(name); endfunction

    virtual task body();
        rv32i_seq_item item;
        for (int n=0;n<TESTS;n++) begin
            item=rv32i_seq_item::type_id::create($sformatf("item_%0d",n));
            start_item(item);
            if (n<TESTS/2) begin
                if (!item.randomize() with {mode==MODE_NORMAL;})
                    `uvm_fatal("SEQ","normal randomize failed")
            end else begin
                if (!item.randomize() with {mode==MODE_CONSTRAINED;})
                    `uvm_fatal("SEQ","constrained randomize failed")
            end
            finish_item(item);
        end
    endtask
endclass

// ================================================================
// Driver
// ================================================================
class rv32i_driver extends uvm_driver #(rv32i_seq_item);
    `uvm_component_utils(rv32i_driver)
    virtual rv32i_if vif;

    function new(string name="rv32i_driver", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual rv32i_if)::get(this,"","vif",vif))
            `uvm_fatal("DRV", "cannot access virtual interface")
    endfunction

    function automatic logic [31:0] make_instr(
        int op, logic [11:0] imm
    );
        logic [2:0]  funct3;
        logic [6:0]  funct7;
        logic [11:0] enc_imm;

        funct3=0; funct7=0; enc_imm=imm;
        if (op < 10) begin
            case (op)
                0: funct3=3'b000;                                      // ADD
                1: begin funct3=3'b000; funct7=7'b0100000; end         // SUB
                2: funct3=3'b001;                                      // SLL
                3: funct3=3'b010;                                      // SLT
                4: funct3=3'b011;                                      // SLTU
                5: funct3=3'b100;                                      // XOR
                6: funct3=3'b101;                                      // SRL
                7: begin funct3=3'b101; funct7=7'b0100000; end         // SRA
                8: funct3=3'b110;                                      // OR
                9: funct3=3'b111;                                      // AND
            endcase
            return {funct7,5'd2,5'd1,funct3,5'd3,7'b0110011};
        end

        case (op)
            10: funct3=3'b000; // ADDI
            11: funct3=3'b010; // SLTI
            12: funct3=3'b011; // SLTIU
            13: funct3=3'b100; // XORI
            14: funct3=3'b110; // ORI
            15: funct3=3'b111; // ANDI
            16: funct3=3'b001; // SLLI
            17,18: funct3=3'b101; // SRLI/SRAI
        endcase
        if (op==16 || op==17) enc_imm={7'b0000000,imm[4:0]};
        if (op==18)           enc_imm={7'b0100000,imm[4:0]};
        return {enc_imm,5'd1,funct3,5'd3,7'b0010011};
    endfunction

    task automatic execute_writeback(
        logic [31:0] code, output bit seen
    );
        seen=0;
        @(negedge vif.clk);
        vif.instr=code;
        for (int cycle=0; cycle<8; cycle++) begin
            @(negedge vif.clk);
            if (vif.rf_we) begin
                seen=1;
                break;
            end
        end
    endtask

    task automatic load_constant(
        logic [4:0] rd, logic [31:0] value, output bit ok
    );
        logic [31:0] upper;
        logic [31:0] code;
        bit seen;

        upper=(value+32'h00000800)>>12;
        code={upper[19:0],rd,7'b0110111};       // LUI
        execute_writeback(code,seen);
        if (!seen) begin ok=0; return; end
        @(posedge vif.clk);
        #1;

        code={value[11:0],rd,3'b000,rd,7'b0010011}; // ADDI
        execute_writeback(code,seen);
        if (!seen) begin ok=0; return; end
        @(posedge vif.clk);
        #1;
        case (rd)
            5'd1: ok=(vif.x1_data===value);
            5'd2: ok=(vif.x2_data===value);
            default: ok=0;
        endcase
    endtask

    virtual task run_phase(uvm_phase phase);
        rv32i_seq_item item;
        bit ok1,ok2,seen;

        vif.test_active=0;
        vif.rst_n=0;
        vif.instr=32'h00000013;

        forever begin
            seq_item_port.get_next_item(item);

            @(negedge vif.clk);
            vif.rst_n=0;
            vif.instr=32'h00000013;
            repeat (2) @(posedge vif.clk);
            #1 vif.rst_n=1;

            load_constant(5'd1,item.rs1_value,ok1);
            load_constant(5'd2,item.rs2_value,ok2);

            item.instr=make_instr(item.op,item.imm);
            vif.op=item.op;
            vif.mode=item.mode;
            vif.group=item.group;
            vif.scenario=item.scenario;
            vif.rs1_pattern=item.rs1_pattern;
            vif.rs2_pattern=item.rs2_pattern;
            vif.shamt=item.shamt;
            vif.rs1_value=item.rs1_value;
            vif.rs2_value=item.rs2_value;
            vif.imm=item.imm;
            vif.test_active=ok1 && ok2;

            execute_writeback(item.instr,seen);
            if (!seen)
                `uvm_error("DRV",$sformatf("op=%0d: no writeback",item.op))

            if (seen) begin
                @(posedge vif.clk);
                #2;
            end
            vif.test_active=0;
            seq_item_port.item_done();
        end
    endtask
endclass

// ================================================================
// Monitor: publishes only the target instruction write-back.
// Preload write-backs occur while test_active is zero.
// ================================================================
class rv32i_monitor extends uvm_monitor;
    `uvm_component_utils(rv32i_monitor)
    virtual rv32i_if vif;
    uvm_analysis_port #(rv32i_seq_item) send;

    function new(string name="rv32i_monitor", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual rv32i_if)::get(this,"","vif",vif))
            `uvm_fatal("MON", "cannot access virtual interface")
        send=new("send",this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        rv32i_seq_item item;
        forever begin
            @(posedge vif.clk);
            if (vif.test_active && vif.rf_we) begin
                #1;
                item=rv32i_seq_item::type_id::create("observed_item");
                item.op=vif.op;
                item.mode=vif.mode;
                item.group=vif.group;
                item.scenario=vif.scenario;
                item.rs1_pattern=vif.rs1_pattern;
                item.rs2_pattern=vif.rs2_pattern;
                item.shamt=vif.shamt;
                item.rs1_value=vif.rs1_value;
                item.rs2_value=vif.rs2_value;
                item.imm=vif.imm;
                item.instr=vif.instr;
                item.actual=vif.rd3_data;
                item.writeback_seen=1;
                send.write(item);
            end
        end
    endtask
endclass

// ================================================================
// Agent
// ================================================================
class rv32i_agent extends uvm_agent;
    `uvm_component_utils(rv32i_agent)
    rv32i_driver drv;
    rv32i_monitor mon;
    uvm_sequencer #(rv32i_seq_item) sqr;

    function new(string name="rv32i_agent", uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv=rv32i_driver::type_id::create("drv",this);
        mon=rv32i_monitor::type_id::create("mon",this);
        sqr=uvm_sequencer#(rv32i_seq_item)::type_id::create("sqr",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass

// ================================================================
// Scoreboard: PASS/FAIL is independent from functional coverage
// ================================================================
class rv32i_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(rv32i_scoreboard)
    localparam int OPS=19;
    localparam int EXPECTED_TOTAL=80000;
    uvm_analysis_imp #(rv32i_seq_item,rv32i_scoreboard) recv;
    int pass_count[OPS];
    int fail_count[OPS];

    function new(string name="rv32i_scoreboard",uvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase(uvm_phase phase); super.build_phase(phase); recv=new("recv",this); endfunction
    function automatic string op_name(int op);
        case(op)
            0:return "ADD";1:return "SUB";2:return "SLL";3:return "SLT";4:return "SLTU";
            5:return "XOR";6:return "SRL";7:return "SRA";8:return "OR";9:return "AND";
            10:return "ADDI";11:return "SLTI";12:return "SLTIU";13:return "XORI";
            14:return "ORI";15:return "ANDI";16:return "SLLI";17:return "SRLI";
            18:return "SRAI";default:return "UNKNOWN";
        endcase
    endfunction
    function automatic logic [31:0] reference_result(rv32i_seq_item item);
        logic signed [31:0] simm;
        simm={{20{item.instr[31]}},item.instr[31:20]};
        case(item.op)
            0:return item.rs1_value+item.rs2_value; 1:return item.rs1_value-item.rs2_value;
            2:return item.rs1_value<<item.rs2_value[4:0];
            3:return $signed(item.rs1_value)<$signed(item.rs2_value); 4:return item.rs1_value<item.rs2_value;
            5:return item.rs1_value^item.rs2_value; 6:return item.rs1_value>>item.rs2_value[4:0];
            7:return $signed(item.rs1_value)>>>item.rs2_value[4:0];
            8:return item.rs1_value|item.rs2_value; 9:return item.rs1_value&item.rs2_value;
            10:return item.rs1_value+simm; 11:return $signed(item.rs1_value)<simm;
            12:return item.rs1_value<$unsigned(simm); 13:return item.rs1_value^simm;
            14:return item.rs1_value|simm; 15:return item.rs1_value&simm;
            16:return item.rs1_value<<item.instr[24:20]; 17:return item.rs1_value>>item.instr[24:20];
            18:return $signed(item.rs1_value)>>>item.instr[24:20]; default:return 'x;
        endcase
    endfunction
    virtual function void write(rv32i_seq_item item);
        logic [31:0] expected=reference_result(item);
        if(item.writeback_seen && item.actual===expected) pass_count[item.op]++;
        else begin
            fail_count[item.op]++;
            `uvm_error("SCB",$sformatf("%s rs1=%08h rs2=%08h imm=%03h expected=%08h actual=%08h",op_name(item.op),item.rs1_value,item.rs2_value,item.imm,expected,item.actual))
        end
    endfunction
    virtual function void report_phase(uvm_phase phase);
        int total_pass=0,total_fail=0;
        $display("\n========== R/I RANDOM TEST RESULT ==========");
        $display("INSTR  CHECKED  PASS  FAIL  PASS_RATE  STATUS");
        for(int op=0;op<OPS;op++) begin
            int checked=pass_count[op]+fail_count[op];
            string status=(checked>0 && fail_count[op]==0)?"PASS":"FAIL";
            $display("%-6s %7d %5d %5d %9.1f%%  %s",
                op_name(op),checked,pass_count[op],fail_count[op],
                checked?100.0*pass_count[op]/checked:0.0,status);
            total_pass+=pass_count[op]; total_fail+=fail_count[op];
        end
        $display("------------------------------------------------------------");
        $display("TOTAL  %7d %5d %5d %9.1f%%",
            total_pass+total_fail,total_pass,total_fail,
            (total_pass+total_fail)?100.0*total_pass/(total_pass+total_fail):0.0);
        if(total_pass!=EXPECTED_TOTAL || total_fail!=0)
            `uvm_error("SCB","random test failed")
        else
            $display("RESULT PASS: all 80000 checks passed");
    endfunction
endclass

// ================================================================
// Functional coverage: general, logic and shift are measured separately
// ================================================================
class rv32i_coverage extends uvm_subscriber #(rv32i_seq_item);
    `uvm_component_utils(rv32i_coverage)
    rv32i_seq_item item;
    int overflow_state;
    int compare_relation;
    int logic_a_class,logic_b_class;
    int shift_data_class;
    logic [4:0] sampled_shamt;

    covergroup instruction_cg;
        option.per_instance=1;
        cp_op: coverpoint item.op { bins operations[]={[0:18]}; }
        cp_mode: coverpoint item.mode;
        cx_op_mode: cross cp_op,cp_mode;
    endgroup
    covergroup general_cg;
        option.per_instance=1;
        cp_arith_op: coverpoint item.op iff(item.op inside {0,1,10}) { bins add={0};bins sub={1};bins addi={10}; }
        cp_a_sign: coverpoint item.rs1_value[31] iff(item.op inside {0,1,10});
        cp_b_sign: coverpoint ((item.op==10)?item.imm[11]:item.rs2_value[31]) iff(item.op inside {0,1,10});
        cp_ovf: coverpoint overflow_state iff(item.op inside {0,1,10}) {bins normal={0};bins positive={1};bins negative={2};}
        cx_arithmetic: cross cp_arith_op,cp_a_sign,cp_b_sign,cp_ovf;
        cp_compare_op: coverpoint item.op iff(item.op inside {3,4,11,12}) {bins ops[]={3,4,11,12};}
        cp_relation: coverpoint compare_relation iff(item.op inside {3,4,11,12}) {bins equal={0};bins less={1};bins greater={2};bins different_sign={3};}
        cx_compare: cross cp_compare_op,cp_relation;
    endgroup
    covergroup logic_cg;
        option.per_instance=1;
        cp_logic_op: coverpoint item.op iff(item.op inside {5,8,9,13,14,15}) {bins ops[]={5,8,9,13,14,15};}
        cp_a_pattern: coverpoint logic_a_class iff(item.op inside {5,8,9,13,14,15}) {bins patterns[]={[0:6]};}
        cp_b_pattern: coverpoint logic_b_class iff(item.op inside {5,8,9,13,14,15}) {bins patterns[]={[0:6]};}
        cx_logic: cross cp_logic_op,cp_a_pattern,cp_b_pattern;
    endgroup
    covergroup shift_cg;
        option.per_instance=1;
        cp_shift_op: coverpoint item.op iff(item.op inside {2,6,7,16,17,18}) {bins ops[]={2,6,7,16,17,18};}
        cp_data: coverpoint shift_data_class iff(item.op inside {2,6,7,16,17,18}) {bins zero={0};bins positive={1};bins negative={2};bins one_hot={3};bins patterned={4};}
        cp_shamt: coverpoint sampled_shamt iff(item.op inside {2,6,7,16,17,18}) {bins zero={0};bins one={1};bins low={[2:14]};bins mid_low={15};bins mid_high={16};bins high={[17:30]};bins maximum={31};}
        cx_shift: cross cp_shift_op,cp_data,cp_shamt;
    endgroup

    function new(string name="rv32i_coverage",uvm_component parent=null);
        super.new(name,parent); instruction_cg=new();general_cg=new();logic_cg=new();shift_cg=new();
    endfunction
    function automatic logic [31:0] second_operand(rv32i_seq_item t);
        return (t.op>=10 && t.op<=15)?{{20{t.instr[31]}},t.instr[31:20]}:t.rs2_value;
    endfunction
    function automatic int classify_pattern(logic [31:0] v);
        if(v==0)return 0;if(v=='1)return 1;if($countones(v)==1)return 2;if($countones(v)==31)return 3;
        if(v==32'haaaaaaaa)return 4;if(v==32'h55555555)return 5;return 6;
    endfunction
    function automatic int classify_shift_data(logic [31:0] v);
        if(v==0)return 0;if($countones(v)==1)return 3;if(v==32'haaaaaaaa||v==32'h55555555)return 4;if(v[31])return 2;return 1;
    endfunction
    virtual function void write(rv32i_seq_item t);
        logic [31:0] b,result;
        item=t;b=second_operand(t);result=t.actual;overflow_state=0;
        if(t.op==0||t.op==10) begin
            if(!t.rs1_value[31]&&!b[31]&&result[31])overflow_state=1;
            else if(t.rs1_value[31]&&b[31]&&!result[31])overflow_state=2;
        end else if(t.op==1) begin
            if(!t.rs1_value[31]&&b[31]&&result[31])overflow_state=1;
            else if(t.rs1_value[31]&&!b[31]&&!result[31])overflow_state=2;
        end
        if(t.rs1_value[31]!=b[31])compare_relation=3;
        else if((t.op==3||t.op==11)?($signed(t.rs1_value)<$signed(b)):(t.rs1_value<b))compare_relation=1;
        else if(t.rs1_value==b)compare_relation=0;else compare_relation=2;
        logic_a_class=classify_pattern(t.rs1_value);logic_b_class=classify_pattern(b);
        shift_data_class=classify_shift_data(t.rs1_value);
        sampled_shamt=(t.op inside {2,6,7})?t.rs2_value[4:0]:t.instr[24:20];
        instruction_cg.sample();general_cg.sample();logic_cg.sample();shift_cg.sample();
    endfunction
    virtual function void report_phase(uvm_phase phase);
        $display("\n========== FUNCTIONAL COVERAGE ==========");
        $display("Instruction coverage = %.1f%%",instruction_cg.get_coverage());
        $display("General coverage     = %.1f%%",general_cg.get_coverage());
        $display("Logic coverage       = %.1f%%",logic_cg.get_coverage());
        $display("Shift coverage       = %.1f%%",shift_cg.get_coverage());
        $display("=========================================\n");
    endfunction
endclass

// ================================================================
// Environment and test
// ================================================================
class rv32i_environment extends uvm_env;
    `uvm_component_utils(rv32i_environment)
    rv32i_agent      agt;
    rv32i_scoreboard scb;
    rv32i_coverage   cov;

    function new(string name="rv32i_environment",uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agt=rv32i_agent::type_id::create("agt",this);
        scb=rv32i_scoreboard::type_id::create("scb",this);
        cov=rv32i_coverage::type_id::create("cov",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agt.mon.send.connect(scb.recv);
        agt.mon.send.connect(cov.analysis_export);
    endfunction
endclass

class rv32i_test extends uvm_test;
    `uvm_component_utils(rv32i_test)
    rv32i_sequence    seq;
    rv32i_environment env;

    function new(string name="rv32i_test",uvm_component parent=null);
        super.new(name,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        seq=rv32i_sequence::type_id::create("seq");
        env=rv32i_environment::type_id::create("env",this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seq.start(env.agt.sqr);
        phase.drop_objection(this);
    endtask
endclass

// ================================================================
// Top testbench
// ================================================================
module tb_rv32i_uvm;
    logic clk=0;
    always #5 clk=~clk;

    rv32i_if r_if(clk);

    rv32i_cpu dut (
        .clk(clk),
        .rst_n(r_if.rst_n),
        .ready(1'b1),
        .instr_code(r_if.instr),
        .bus_rdata(32'b0),
        .transfer(),
        .instr_addr(),
        .bus_addr(),
        .bus_wdata(),
        .bus_we(),
        .d_inst_type()
    );

    assign r_if.rf_we    = dut.rf_we;
    assign r_if.x1_data  = dut.U_DATAPATH.U_REG_FILE.register_file[1];
    assign r_if.x2_data  = dut.U_DATAPATH.U_REG_FILE.register_file[2];
    assign r_if.rd3_data = dut.U_DATAPATH.U_REG_FILE.register_file[3];

    initial begin
        $fsdbDumpfile("wave.fsdb");
        $fsdbDumpvars(0,tb_rv32i_uvm);
    end

    initial begin
        uvm_config_db#(virtual rv32i_if)::set(null,"*","vif",r_if);
        run_test("rv32i_test");
    end
endmodule



