//SystemVerilog
module ParityLatch #(parameter DW=7) (
    input clk, en,
    input [DW-1:0] data,
    output reg [DW:0] q
);

// Stage 1: Data and enable registration
reg [DW-1:0] data_stage1;
reg en_stage1;

// Stage 2: Parity calculation
reg [DW-1:0] data_stage2;
reg en_stage2;
wire parity_bit_stage2;

// Stage 3: Next state computation
reg [DW:0] next_q_stage3;
reg [DW:0] q_stage3;

// Stage 1: Register inputs
always @(posedge clk) begin
    data_stage1 <= data;
    en_stage1 <= en;
end

// Stage 2: Calculate parity
assign parity_bit_stage2 = ^data_stage1;

always @(posedge clk) begin
    data_stage2 <= data_stage1;
    en_stage2 <= en_stage1;
end

// Stage 3: Compute next state
always @(*) begin
    if(en_stage2) begin
        next_q_stage3 = {parity_bit_stage2, data_stage2};
    end else begin
        next_q_stage3 = q_stage3;
    end
end

// Stage 4: Update output
always @(posedge clk) begin
    q_stage3 <= next_q_stage3;
    q <= q_stage3;
end

endmodule