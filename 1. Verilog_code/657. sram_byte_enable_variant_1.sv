//SystemVerilog
module sram_byte_enable #(
    parameter BYTES = 4
)(
    input clk,
    input cs,
    input [BYTES-1:0] we,
    input [7:0] addr,
    input [BYTES*8-1:0] din,
    output [BYTES*8-1:0] dout
);
localparam DW = BYTES*8;

// Memory array
reg [7:0] mem [0:255][0:BYTES-1];

// Pipeline stage 1: Address and control signal registration
reg [7:0] addr_stage1;
reg [BYTES-1:0] we_stage1;
reg cs_stage1;
reg [BYTES*8-1:0] din_stage1;

// Pipeline stage 2: Memory access
reg [7:0] addr_stage2;
reg [BYTES-1:0] we_stage2;
reg cs_stage2;
reg [BYTES*8-1:0] din_stage2;

// Stage 1: Register inputs and memory write
always @(posedge clk) begin
    addr_stage1 <= addr;
    we_stage1 <= we;
    cs_stage1 <= cs;
    din_stage1 <= din;
    
    // Memory write moved to stage 1
    for (integer i = 0; i < BYTES; i = i + 1) begin
        if (cs && we[i]) begin
            mem[addr][i] <= din[i*8+:8];
        end
    end
end

// Stage 2: Memory read and output registration
always @(posedge clk) begin
    addr_stage2 <= addr_stage1;
    we_stage2 <= we_stage1;
    cs_stage2 <= cs_stage1;
    din_stage2 <= din_stage1;
end

// Output logic with registered memory read
reg [BYTES*8-1:0] dout_reg;
always @(posedge clk) begin
    for (integer i = 0; i < BYTES; i = i + 1) begin
        dout_reg[i*8+:8] <= mem[addr_stage1][i];
    end
end

assign dout = dout_reg;

endmodule