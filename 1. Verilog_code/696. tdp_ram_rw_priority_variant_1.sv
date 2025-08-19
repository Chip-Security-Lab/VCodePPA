//SystemVerilog
module tdp_ram_rw_priority #(
    parameter D_WIDTH = 16,
    parameter A_WIDTH = 9,
    parameter PORT_A_WRITE_FIRST = 1,
    parameter PORT_B_READ_FIRST = 1
)(
    input clk,
    input rst_n,
    // Port A (configurable priority)
    input [A_WIDTH-1:0] a_adr,
    input [D_WIDTH-1:0] a_din,
    output reg [D_WIDTH-1:0] a_dout,
    input a_we,
    // Port B (configurable priority)
    input [A_WIDTH-1:0] b_adr,
    input [D_WIDTH-1:0] b_din,
    output reg [D_WIDTH-1:0] b_dout,
    input b_we
);

// Pipeline registers
reg [A_WIDTH-1:0] a_adr_stage1, b_adr_stage1;
reg [D_WIDTH-1:0] a_din_stage1, b_din_stage1;
reg a_we_stage1, b_we_stage1;
reg [D_WIDTH-1:0] a_dout_stage1, b_dout_stage1;

reg [A_WIDTH-1:0] a_adr_stage2, b_adr_stage2;
reg [D_WIDTH-1:0] a_din_stage2, b_din_stage2;
reg a_we_stage2, b_we_stage2;
reg [D_WIDTH-1:0] a_dout_stage2, b_dout_stage2;

reg [D_WIDTH-1:0] ram [0:(1<<A_WIDTH)-1];

// Stage 1: Address and control signal registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_adr_stage1 <= 0;
        b_adr_stage1 <= 0;
        a_din_stage1 <= 0;
        b_din_stage1 <= 0;
        a_we_stage1 <= 0;
        b_we_stage1 <= 0;
    end else begin
        a_adr_stage1 <= a_adr;
        b_adr_stage1 <= b_adr;
        a_din_stage1 <= a_din;
        b_din_stage1 <= b_din;
        a_we_stage1 <= a_we;
        b_we_stage1 <= b_we;
    end
end

// Stage 2: Memory access and data registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_adr_stage2 <= 0;
        b_adr_stage2 <= 0;
        a_din_stage2 <= 0;
        b_din_stage2 <= 0;
        a_we_stage2 <= 0;
        b_we_stage2 <= 0;
        a_dout_stage2 <= 0;
        b_dout_stage2 <= 0;
    end else begin
        a_adr_stage2 <= a_adr_stage1;
        b_adr_stage2 <= b_adr_stage1;
        a_din_stage2 <= a_din_stage1;
        b_din_stage2 <= b_din_stage1;
        a_we_stage2 <= a_we_stage1;
        b_we_stage2 <= b_we_stage1;

        // Port A memory access
        if (PORT_A_WRITE_FIRST) begin
            if (a_we_stage1) ram[a_adr_stage1] <= a_din_stage1;
            a_dout_stage2 <= a_we_stage1 ? a_din_stage1 : ram[a_adr_stage1];
        end else begin
            a_dout_stage2 <= ram[a_adr_stage1];
            if (a_we_stage1) ram[a_adr_stage1] <= a_din_stage1;
        end

        // Port B memory access
        if (PORT_B_READ_FIRST) begin
            b_dout_stage2 <= ram[b_adr_stage1];
            if (b_we_stage1) ram[b_adr_stage1] <= b_din_stage1;
        end else begin
            if (b_we_stage1) ram[b_adr_stage1] <= b_din_stage1;
            b_dout_stage2 <= b_we_stage1 ? b_din_stage1 : ram[b_adr_stage1];
        end
    end
end

// Stage 3: Output registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_dout <= 0;
        b_dout <= 0;
    end else begin
        a_dout <= a_dout_stage2;
        b_dout <= b_dout_stage2;
    end
end

endmodule