//SystemVerilog
module sram_byte_enable #(
    parameter BYTES = 4  // 32-bit with 4 byte lanes
)(
    input clk,
    input rst_n,
    input cs,
    input [BYTES-1:0] we,
    input [7:0] addr,
    input [BYTES*8-1:0] din,
    output [BYTES*8-1:0] dout
);
localparam DW = BYTES*8;

// Pipeline stage 1 registers
reg [7:0] addr_stage1;
reg [BYTES-1:0] we_stage1;
reg [BYTES*8-1:0] din_stage1;
reg cs_stage1;

// Pipeline stage 2 registers
reg [7:0] addr_stage2;
reg [BYTES-1:0] we_stage2;
reg [BYTES*8-1:0] din_stage2;
reg cs_stage2;

// Pipeline stage 3 registers
reg [BYTES*8-1:0] dout_stage3;

// Memory array
reg [7:0] mem [0:255][0:BYTES-1];

// Pipeline stage 1: Input registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage1 <= 8'b0;
        we_stage1 <= {BYTES{1'b0}};
        din_stage1 <= {DW{1'b0}};
        cs_stage1 <= 1'b0;
    end else begin
        addr_stage1 <= addr;
        we_stage1 <= we;
        din_stage1 <= din;
        cs_stage1 <= cs;
    end
end

// Pipeline stage 2: Control signal propagation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        addr_stage2 <= 8'b0;
        we_stage2 <= {BYTES{1'b0}};
        din_stage2 <= {DW{1'b0}};
        cs_stage2 <= 1'b0;
    end else begin
        addr_stage2 <= addr_stage1;
        we_stage2 <= we_stage1;
        din_stage2 <= din_stage1;
        cs_stage2 <= cs_stage1;
    end
end

// Pipeline stage 3: Memory access and write
genvar i;
generate
for (i=0; i<BYTES; i=i+1) begin : gen_byte_lanes
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem[addr_stage2][i] <= 8'b0;
        end else if (cs_stage2 & we_stage2[i]) begin
            mem[addr_stage2][i] <= din_stage2[i*8+:8];
        end
    end
end
endgenerate

// Pipeline stage 3: Read operation
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dout_stage3 <= {DW{1'b0}};
    end else begin
        for (int j=0; j<BYTES; j=j+1) begin
            dout_stage3[j*8+:8] <= mem[addr_stage2][j];
        end
    end
end

// Output assignment
assign dout = dout_stage3;

endmodule