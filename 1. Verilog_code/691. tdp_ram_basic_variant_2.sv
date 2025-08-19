//SystemVerilog
module tdp_ram_pipelined #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 6,
    parameter DEPTH = 64
)(
    input clk,
    input rst_n,
    // Port A
    input [ADDR_WIDTH-1:0] addr_a,
    input [DATA_WIDTH-1:0] din_a,
    output reg [DATA_WIDTH-1:0] dout_a,
    input we_a,
    input valid_a,
    output ready_a,
    // Port B
    input [ADDR_WIDTH-1:0] addr_b,
    input [DATA_WIDTH-1:0] din_b,
    output reg [DATA_WIDTH-1:0] dout_b,
    input we_b,
    input valid_b,
    output ready_b
);

// Memory array
reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

// Pipeline stage 1 registers
reg [ADDR_WIDTH-1:0] addr_a_stage1;
reg [DATA_WIDTH-1:0] din_a_stage1;
reg we_a_stage1;
reg valid_a_stage1;

reg [ADDR_WIDTH-1:0] addr_b_stage1;
reg [DATA_WIDTH-1:0] din_b_stage1;
reg we_b_stage1;
reg valid_b_stage1;

// Pipeline stage 2 registers
reg [ADDR_WIDTH-1:0] addr_a_stage2;
reg [DATA_WIDTH-1:0] din_a_stage2;
reg we_a_stage2;
reg valid_a_stage2;

reg [ADDR_WIDTH-1:0] addr_b_stage2;
reg [DATA_WIDTH-1:0] din_b_stage2;
reg we_b_stage2;
reg valid_b_stage2;

// Ready signals
assign ready_a = 1'b1;
assign ready_b = 1'b1;

// Stage 1: Address and data capture
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        {addr_a_stage1, din_a_stage1, we_a_stage1, valid_a_stage1} <= 0;
        {addr_b_stage1, din_b_stage1, we_b_stage1, valid_b_stage1} <= 0;
    end else begin
        valid_a_stage1 <= valid_a;
        if (valid_a) begin
            {addr_a_stage1, din_a_stage1, we_a_stage1} <= {addr_a, din_a, we_a};
        end

        valid_b_stage1 <= valid_b;
        if (valid_b) begin
            {addr_b_stage1, din_b_stage1, we_b_stage1} <= {addr_b, din_b, we_b};
        end
    end
end

// Stage 2: Memory access
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        {addr_a_stage2, din_a_stage2, we_a_stage2, valid_a_stage2} <= 0;
        {addr_b_stage2, din_b_stage2, we_b_stage2, valid_b_stage2} <= 0;
    end else begin
        {addr_a_stage2, din_a_stage2, we_a_stage2, valid_a_stage2} <= 
            {addr_a_stage1, din_a_stage1, we_a_stage1, valid_a_stage1};
        {addr_b_stage2, din_b_stage2, we_b_stage2, valid_b_stage2} <= 
            {addr_b_stage1, din_b_stage1, we_b_stage1, valid_b_stage1};
    end
end

// Stage 3: Memory write and read
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        {dout_a, dout_b} <= 0;
    end else begin
        if (valid_a_stage2) begin
            dout_a <= we_a_stage2 ? din_a_stage2 : mem[addr_a_stage2];
            if (we_a_stage2) mem[addr_a_stage2] <= din_a_stage2;
        end

        if (valid_b_stage2) begin
            dout_b <= we_b_stage2 ? din_b_stage2 : mem[addr_b_stage2];
            if (we_b_stage2) mem[addr_b_stage2] <= din_b_stage2;
        end
    end
end

endmodule