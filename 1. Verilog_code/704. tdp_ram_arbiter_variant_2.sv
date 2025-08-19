//SystemVerilog
module tdp_ram_arbiter #(
    parameter DW = 28,
    parameter AW = 7
)(
    input clk,
    input rst_n,
    input arb_mode, // 0: PortA优先, 1: Round-Robin
    // Port A
    input [AW-1:0] a_addr,
    input [DW-1:0] a_din,
    output reg [DW-1:0] a_dout,
    input a_we, a_re,
    input a_valid,
    output reg a_ready,
    // Port B
    input [AW-1:0] b_addr,
    input [DW-1:0] b_din,
    output reg [DW-1:0] b_dout,
    input b_we, b_re,
    input b_valid,
    output reg b_ready
);

// Memory array
reg [DW-1:0] mem [0:(1<<AW)-1];

// Pipeline stage 1: Address and control signal registers
reg [AW-1:0] a_addr_stage1, b_addr_stage1;
reg [DW-1:0] a_din_stage1, b_din_stage1;
reg a_we_stage1, b_we_stage1;
reg a_re_stage1, b_re_stage1;
reg arb_mode_stage1;
reg arb_flag_stage1;
reg a_valid_stage1, b_valid_stage1;

// Pipeline stage 2: Memory access and arbitration
reg [DW-1:0] a_dout_stage2, b_dout_stage2;
reg a_valid_stage2, b_valid_stage2;
reg [AW-1:0] a_addr_stage2, b_addr_stage2;
reg a_re_stage2, b_re_stage2;
reg arb_flag_stage2;

// Pipeline stage 3: Output registers
reg [DW-1:0] a_dout_stage3, b_dout_stage3;
reg a_valid_stage3, b_valid_stage3;

// Arbitration flag
reg arb_flag;

// Stage 1: Register inputs
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_addr_stage1 <= 0;
        b_addr_stage1 <= 0;
        a_din_stage1 <= 0;
        b_din_stage1 <= 0;
        a_we_stage1 <= 0;
        b_we_stage1 <= 0;
        a_re_stage1 <= 0;
        b_re_stage1 <= 0;
        arb_mode_stage1 <= 0;
        arb_flag_stage1 <= 0;
        a_valid_stage1 <= 0;
        b_valid_stage1 <= 0;
        a_ready <= 1'b1;
        b_ready <= 1'b1;
    end else begin
        // Register inputs
        a_addr_stage1 <= a_addr;
        b_addr_stage1 <= b_addr;
        a_din_stage1 <= a_din;
        b_din_stage1 <= b_din;
        a_we_stage1 <= a_we;
        b_we_stage1 <= b_we;
        a_re_stage1 <= a_re;
        b_re_stage1 <= b_re;
        arb_mode_stage1 <= arb_mode;
        arb_flag_stage1 <= arb_flag;
        a_valid_stage1 <= a_valid;
        b_valid_stage1 <= b_valid;
        
        // Ready signals
        a_ready <= 1'b1;
        b_ready <= 1'b1;
    end
end

// Stage 2: Memory access and arbitration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_dout_stage2 <= 0;
        b_dout_stage2 <= 0;
        a_valid_stage2 <= 0;
        b_valid_stage2 <= 0;
        a_addr_stage2 <= 0;
        b_addr_stage2 <= 0;
        a_re_stage2 <= 0;
        b_re_stage2 <= 0;
        arb_flag_stage2 <= 0;
        arb_flag <= 0;
    end else begin
        // Register control signals
        a_addr_stage2 <= a_addr_stage1;
        b_addr_stage2 <= b_addr_stage1;
        a_re_stage2 <= a_re_stage1;
        b_re_stage2 <= b_re_stage1;
        a_valid_stage2 <= a_valid_stage1;
        b_valid_stage2 <= b_valid_stage1;
        arb_flag_stage2 <= arb_flag_stage1;
        
        // Memory write with arbitration
        if (a_we_stage1 & b_we_stage1) begin // Write conflict
            case(arb_mode_stage1)
                0: begin // PortA priority
                    mem[a_addr_stage1] <= a_din_stage1;
                    mem[b_addr_stage1] <= a_din_stage1; // Write same data
                    arb_flag <= 0;
                end
                1: begin // Round-robin
                    if (arb_flag_stage1) begin
                        mem[a_addr_stage1] <= a_din_stage1;
                        arb_flag <= 0;
                    end else begin
                        mem[b_addr_stage1] <= b_din_stage1;
                        arb_flag <= 1;
                    end
                end
            endcase
        end else begin
            if (a_we_stage1) mem[a_addr_stage1] <= a_din_stage1;
            if (b_we_stage1) mem[b_addr_stage1] <= b_din_stage1;
        end
        
        // Memory read with arbitration
        if (a_re_stage1 && !(b_re_stage1 && arb_flag_stage1)) begin
            a_dout_stage2 <= mem[a_addr_stage1];
        end else begin
            a_dout_stage2 <= 'hz;
        end
        
        if (b_re_stage1 && !(a_re_stage1 && !arb_flag_stage1)) begin
            b_dout_stage2 <= mem[b_addr_stage1];
        end else begin
            b_dout_stage2 <= 'hz;
        end
    end
end

// Stage 3: Output registers
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_dout_stage3 <= 0;
        b_dout_stage3 <= 0;
        a_valid_stage3 <= 0;
        b_valid_stage3 <= 0;
    end else begin
        a_dout_stage3 <= a_dout_stage2;
        b_dout_stage3 <= b_dout_stage2;
        a_valid_stage3 <= a_valid_stage2;
        b_valid_stage3 <= b_valid_stage2;
    end
end

// Output assignment
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_dout <= 0;
        b_dout <= 0;
    end else begin
        a_dout <= a_dout_stage3;
        b_dout <= b_dout_stage3;
    end
end

endmodule