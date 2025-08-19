//SystemVerilog
module tdp_ram_write_protect #(
    parameter DW = 20,
    parameter AW = 8
)(
    input clk,
    input [AW-1:0] protect_start,
    input [AW-1:0] protect_end,
    // Port1
    input [AW-1:0] addr1,
    input [DW-1:0] din1,
    output reg [DW-1:0] dout1,
    input we1,
    // Port2
    input [AW-1:0] addr2,
    input [DW-1:0] din2,
    output reg [DW-1:0] dout2,
    input we2
);

reg [DW-1:0] mem [0:(1<<AW)-1];

// Stage 1: Input registration
reg [AW-1:0] addr1_stage1, addr2_stage1;
reg [DW-1:0] din1_stage1, din2_stage1;
reg we1_stage1, we2_stage1;

always @(posedge clk) begin
    addr1_stage1 <= addr1;
    addr2_stage1 <= addr2;
    din1_stage1 <= din1;
    din2_stage1 <= din2;
    we1_stage1 <= we1;
    we2_stage1 <= we2;
end

// Stage 1: Protection check
reg prot1_stage1, prot2_stage1;

always @(posedge clk) begin
    prot1_stage1 <= (addr1 >= protect_start) & (addr1 <= protect_end);
    prot2_stage1 <= (addr2 >= protect_start) & (addr2 <= protect_end);
end

// Stage 2: Write enable generation
reg [AW-1:0] addr1_stage2, addr2_stage2;
reg [DW-1:0] din1_stage2, din2_stage2;
reg write_en1_stage2, write_en2_stage2;

always @(posedge clk) begin
    addr1_stage2 <= addr1_stage1;
    addr2_stage2 <= addr2_stage1;
    din1_stage2 <= din1_stage1;
    din2_stage2 <= din2_stage1;
    write_en1_stage2 <= we1_stage1 & ~prot1_stage1;
    write_en2_stage2 <= we2_stage1 & ~prot2_stage1;
end

// Stage 3: Memory write
reg [AW-1:0] addr1_stage3, addr2_stage3;
reg [DW-1:0] din1_stage3, din2_stage3;
reg write_en1_stage3, write_en2_stage3;

always @(posedge clk) begin
    addr1_stage3 <= addr1_stage2;
    addr2_stage3 <= addr2_stage2;
    din1_stage3 <= din1_stage2;
    din2_stage3 <= din2_stage2;
    write_en1_stage3 <= write_en1_stage2;
    write_en2_stage3 <= write_en2_stage2;
end

always @(posedge clk) begin
    if (write_en1_stage2)
        mem[addr1_stage2] <= din1_stage2;
    if (write_en2_stage2)
        mem[addr2_stage2] <= din2_stage2;
end

// Stage 4: Memory read
always @(posedge clk) begin
    dout1 <= mem[addr1_stage3];
    dout2 <= mem[addr2_stage3];
end

endmodule