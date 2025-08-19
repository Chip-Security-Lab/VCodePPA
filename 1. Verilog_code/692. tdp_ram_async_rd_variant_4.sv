//SystemVerilog
module tdp_ram_async_rd #(
    parameter DW = 16,
    parameter AW = 5,
    parameter DEPTH = 32
)(
    input clk, rst_n,
    // Port A
    input [AW-1:0] a_addr,
    input [DW-1:0] a_din,
    output [DW-1:0] a_dout,
    input a_wr,
    // Port B
    input [AW-1:0] b_addr,
    input [DW-1:0] b_din,
    output [DW-1:0] b_dout,
    input b_wr
);

// Stage 1: Address and Write Data Register
reg [AW-1:0] a_addr_stage1, b_addr_stage1;
reg [DW-1:0] a_din_stage1, b_din_stage1;
reg a_wr_stage1, b_wr_stage1;

// Stage 2: Memory Access
reg [DW-1:0] storage [0:DEPTH-1];
reg [DW-1:0] a_dout_stage2, b_dout_stage2;
reg [AW-1:0] a_addr_stage2, b_addr_stage2;

// Stage 3: Memory Read
reg [DW-1:0] a_dout_stage3, b_dout_stage3;

// Stage 4: Output Register
reg [DW-1:0] a_dout_stage4, b_dout_stage4;

integer i;

// Stage 1: Register inputs
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_addr_stage1 <= 0;
        b_addr_stage1 <= 0;
        a_din_stage1 <= 0;
        b_din_stage1 <= 0;
        a_wr_stage1 <= 0;
        b_wr_stage1 <= 0;
    end else begin
        a_addr_stage1 <= a_addr;
        b_addr_stage1 <= b_addr;
        a_din_stage1 <= a_din;
        b_din_stage1 <= b_din;
        a_wr_stage1 <= a_wr;
        b_wr_stage1 <= b_wr;
    end
end

// Stage 2: Memory write and address pipeline
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (i = 0; i < DEPTH; i = i + 1)
            storage[i] <= 0;
        a_addr_stage2 <= 0;
        b_addr_stage2 <= 0;
    end else begin
        // Memory write
        if (a_wr_stage1) storage[a_addr_stage1] <= a_din_stage1;
        if (b_wr_stage1) storage[b_addr_stage1] <= b_din_stage1;
        
        // Pipeline addresses
        a_addr_stage2 <= a_addr_stage1;
        b_addr_stage2 <= b_addr_stage1;
    end
end

// Stage 3: Memory read
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_dout_stage3 <= 0;
        b_dout_stage3 <= 0;
    end else begin
        a_dout_stage3 <= storage[a_addr_stage2];
        b_dout_stage3 <= storage[b_addr_stage2];
    end
end

// Stage 4: Output register
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_dout_stage4 <= 0;
        b_dout_stage4 <= 0;
    end else begin
        a_dout_stage4 <= a_dout_stage3;
        b_dout_stage4 <= b_dout_stage3;
    end
end

// Output assignments
assign a_dout = a_dout_stage4;
assign b_dout = b_dout_stage4;

endmodule