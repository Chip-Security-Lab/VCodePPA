//SystemVerilog
module sram_parity #(
    parameter DATA_BITS = 8
)(
    input clk,
    input rst_n,
    input we,
    input [3:0] addr,
    input [DATA_BITS-1:0] din,
    output [DATA_BITS:0] dout
);

localparam TOTAL_BITS = DATA_BITS + 1;
reg [TOTAL_BITS-1:0] mem [0:15];

// Stage 1: Input registers
reg [3:0] din_stage1;
reg [3:0] addr_stage1;
reg we_stage1;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        din_stage1 <= 0;
        addr_stage1 <= 0;
        we_stage1 <= 0;
    end else begin
        din_stage1 <= din[3:0];
        addr_stage1 <= addr;
        we_stage1 <= we;
    end
end

// Stage 2: Initial computation and first level prefix
reg [1:0] g1_stage2, p1_stage2;
reg [3:0] addr_stage2;
reg we_stage2;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        g1_stage2 <= 0;
        p1_stage2 <= 0;
        addr_stage2 <= 0;
        we_stage2 <= 0;
    end else begin
        g1_stage2[0] <= din_stage1[0] | (din_stage1[0] & din_stage1[1]);
        p1_stage2[0] <= din_stage1[0] & din_stage1[1];
        g1_stage2[1] <= din_stage1[2] | (din_stage1[2] & din_stage1[3]);
        p1_stage2[1] <= din_stage1[2] & din_stage1[3];
        addr_stage2 <= addr_stage1;
        we_stage2 <= we_stage1;
    end
end

// Stage 3: Second level prefix and carry computation
reg [0:0] g2_stage3, p2_stage3;
reg [3:0] c_stage3;
reg [3:0] addr_stage3;
reg we_stage3;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        g2_stage3 <= 0;
        p2_stage3 <= 0;
        c_stage3 <= 0;
        addr_stage3 <= 0;
        we_stage3 <= 0;
    end else begin
        g2_stage3[0] <= g1_stage2[0] | (p1_stage2[0] & g1_stage2[1]);
        p2_stage3[0] <= p1_stage2[0] & p1_stage2[1];
        c_stage3[0] <= din_stage1[0];
        c_stage3[1] <= din_stage1[1] | (din_stage1[1] & c_stage3[0]);
        c_stage3[2] <= din_stage1[2] | (din_stage1[2] & c_stage3[1]);
        c_stage3[3] <= din_stage1[3] | (din_stage1[3] & c_stage3[2]);
        addr_stage3 <= addr_stage2;
        we_stage3 <= we_stage2;
    end
end

// Stage 4: Memory write and read
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        for (int i = 0; i < 16; i++) begin
            mem[i] <= 0;
        end
    end else if (we_stage3) begin
        mem[addr_stage3] <= {c_stage3[3], din_stage1};
    end
end

assign dout = mem[addr];

endmodule