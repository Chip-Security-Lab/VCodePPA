//SystemVerilog
module SignedMultiplier(
    input clk,
    input rst_n,
    input signed [7:0] a,
    input signed [7:0] b,
    output reg signed [15:0] result
);

// Pipeline stage 1: Input registers
reg signed [7:0] a_stage1, b_stage1;

// Pipeline stage 2: Partial product calculation
reg signed [7:0] a_stage2, b_stage2;
reg signed [15:0] partial_prod_stage2;

// Pipeline stage 3: Result accumulation
reg signed [15:0] partial_prod_stage3;

// Stage 1: Input registration
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_stage1 <= 8'd0;
        b_stage1 <= 8'd0;
    end else begin
        a_stage1 <= a;
        b_stage1 <= b;
    end
end

// Stage 2: Multiplication
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        a_stage2 <= 8'd0;
        b_stage2 <= 8'd0;
        partial_prod_stage2 <= 16'd0;
    end else begin
        a_stage2 <= a_stage1;
        b_stage2 <= b_stage1;
        partial_prod_stage2 <= a_stage1 * b_stage1;
    end
end

// Stage 3: Result output
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        partial_prod_stage3 <= 16'd0;
        result <= 16'd0;
    end else begin
        partial_prod_stage3 <= partial_prod_stage2;
        result <= partial_prod_stage3;
    end
end

endmodule