//SystemVerilog
module tdp_ram_rw_priority_pipeline #(
    parameter D_WIDTH = 16,
    parameter A_WIDTH = 9,
    parameter PORT_A_WRITE_FIRST = 1,
    parameter PORT_B_READ_FIRST = 1
)(
    input clk,
    input [A_WIDTH-1:0] a_adr,
    input [D_WIDTH-1:0] a_din,
    output reg [D_WIDTH-1:0] a_dout_stage1,
    output reg [D_WIDTH-1:0] a_dout_stage2,
    input a_we,
    input [A_WIDTH-1:0] b_adr,
    input [D_WIDTH-1:0] b_din,
    output reg [D_WIDTH-1:0] b_dout_stage1,
    output reg [D_WIDTH-1:0] b_dout_stage2,
    input b_we
);

reg [D_WIDTH-1:0] ram [0:(1<<A_WIDTH)-1];
reg [D_WIDTH-1:0] a_dout_temp, b_dout_temp;
reg [A_WIDTH-1:0] a_adr_reg, b_adr_reg;
reg a_we_reg, b_we_reg;
reg [D_WIDTH-1:0] a_din_reg, b_din_reg;

// Address and control signal registration
always @(posedge clk) begin
    a_adr_reg <= a_adr;
    b_adr_reg <= b_adr;
    a_we_reg <= a_we;
    b_we_reg <= b_we;
    a_din_reg <= a_din;
    b_din_reg <= b_din;
end

// Port A with write-first/read-first selection
always @(posedge clk) begin
    if (PORT_A_WRITE_FIRST) begin
        if (a_we_reg) ram[a_adr_reg] <= a_din_reg;
        a_dout_temp <= a_we_reg ? a_din_reg : ram[a_adr_reg];
    end else begin
        a_dout_temp <= ram[a_adr_reg];
        if (a_we_reg) ram[a_adr_reg] <= a_din_reg;
    end
end

// Port B with read-first behavior
always @(posedge clk) begin
    if (PORT_B_READ_FIRST) begin
        b_dout_temp <= ram[b_adr_reg];
        if (b_we_reg) ram[b_adr_reg] <= b_din_reg;
    end else begin
        if (b_we_reg) ram[b_adr_reg] <= b_din_reg;
        b_dout_temp <= b_we_reg ? b_din_reg : ram[b_adr_reg];
    end
end

// Output pipeline stages
always @(posedge clk) begin
    a_dout_stage1 <= a_dout_temp;
    a_dout_stage2 <= a_dout_stage1;
    b_dout_stage1 <= b_dout_temp;
    b_dout_stage2 <= b_dout_stage1;
end

endmodule