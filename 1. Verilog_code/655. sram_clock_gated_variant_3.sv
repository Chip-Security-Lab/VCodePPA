//SystemVerilog
module sram_clock_gated #(
    parameter DW = 4,
    parameter AW = 3
)(
    input main_clk,
    input rst_n,
    input enable,
    input we,
    input [AW-1:0] addr,
    input [DW-1:0] din,
    output [DW-1:0] dout
);

// Pipeline registers
reg [AW-1:0] addr_stage1;
reg [DW-1:0] din_stage1;
reg we_stage1;
reg enable_stage1;

reg [AW-1:0] addr_stage2;
reg [DW-1:0] din_stage2;
reg we_stage2;
reg enable_stage2;

reg [AW-1:0] addr_stage3;
reg [DW-1:0] din_stage3;
reg we_stage3;
reg enable_stage3;

// Memory array
reg [DW-1:0] mem [0:(1<<AW)-1];

// Clock gating logic
wire gated_clk;
assign gated_clk = main_clk & enable_stage3;

// Stage 1: Address and control signal registration
always @(posedge main_clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage1 <= 0;
        din_stage1 <= 0;
        we_stage1 <= 0;
        enable_stage1 <= 0;
    end else begin
        addr_stage1 <= addr;
        din_stage1 <= din;
        we_stage1 <= we;
        enable_stage1 <= enable;
    end
end

// Stage 2: Memory access preparation
always @(posedge main_clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage2 <= 0;
        din_stage2 <= 0;
        we_stage2 <= 0;
        enable_stage2 <= 0;
    end else begin
        addr_stage2 <= addr_stage1;
        din_stage2 <= din_stage1;
        we_stage2 <= we_stage1;
        enable_stage2 <= enable_stage1;
    end
end

// Stage 3: Additional pipeline stage
always @(posedge main_clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage3 <= 0;
        din_stage3 <= 0;
        we_stage3 <= 0;
        enable_stage3 <= 0;
    end else begin
        addr_stage3 <= addr_stage2;
        din_stage3 <= din_stage2;
        we_stage3 <= we_stage2;
        enable_stage3 <= enable_stage2;
    end
end

// Stage 4: Memory access and write
reg [DW-1:0] dout_reg;
always @(posedge gated_clk or negedge rst_n) begin
    if (!rst_n) begin
        dout_reg <= 0;
    end else begin
        if (we_stage3) begin
            mem[addr_stage3] <= din_stage3;
        end
        dout_reg <= mem[addr_stage3];
    end
end

// Output assignment
assign dout = dout_reg;

endmodule