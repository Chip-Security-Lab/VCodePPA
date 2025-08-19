//SystemVerilog
module async_multi_rate_filter #(
    parameter W = 10
)(
    input clk,
    input rst_n,
    input [W-1:0] fast_in,
    input [W-1:0] slow_in,
    input [3:0] alpha,
    output reg [W-1:0] filtered_out
);

    // Pipeline stage 1: Input registers
    reg [W-1:0] fast_in_reg;
    reg [W-1:0] slow_in_reg;
    reg [3:0] alpha_reg;
    reg [3:0] alpha_complement_reg;

    // Pipeline stage 2: Multiplication results
    reg [W+3:0] fast_scaled_reg;
    reg [W+3:0] slow_scaled_reg;

    // Pipeline stage 3: Sum and shift
    reg [W+4:0] sum_reg;

    // Stage 1: Input registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fast_in_reg <= 0;
            slow_in_reg <= 0;
            alpha_reg <= 0;
            alpha_complement_reg <= 0;
        end else begin
            fast_in_reg <= fast_in;
            slow_in_reg <= slow_in;
            alpha_reg <= alpha;
            alpha_complement_reg <= 4'd16 - alpha;
        end
    end

    // Stage 2: Multiplication
    wire [W+3:0] fast_scaled;
    wire [W+3:0] slow_scaled;

    dadda_multiplier #(.WIDTH(W)) fast_mult (
        .a(fast_in_reg),
        .b(alpha_reg),
        .p(fast_scaled)
    );

    dadda_multiplier #(.WIDTH(W)) slow_mult (
        .a(slow_in_reg),
        .b(alpha_complement_reg),
        .p(slow_scaled)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fast_scaled_reg <= 0;
            slow_scaled_reg <= 0;
        end else begin
            fast_scaled_reg <= fast_scaled;
            slow_scaled_reg <= slow_scaled;
        end
    end

    // Stage 3: Sum and shift
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_reg <= 0;
            filtered_out <= 0;
        end else begin
            sum_reg <= fast_scaled_reg + slow_scaled_reg;
            filtered_out <= sum_reg[W+3:4];
        end
    end

endmodule

module dadda_multiplier #(
    parameter WIDTH = 10
)(
    input [WIDTH-1:0] a,
    input [3:0] b,
    output [WIDTH+3:0] p
);

    // Partial products generation
    wire [WIDTH-1:0] pp0, pp1, pp2, pp3;
    assign pp0 = a & {WIDTH{b[0]}};
    assign pp1 = (a & {WIDTH{b[1]}}) << 1;
    assign pp2 = (a & {WIDTH{b[2]}}) << 2;
    assign pp3 = (a & {WIDTH{b[3]}}) << 3;

    // Dadda reduction stages
    wire [WIDTH+3:0] sum1, sum2;
    wire [WIDTH+3:0] carry1, carry2;

    // First reduction stage
    assign sum1 = pp0 ^ pp1 ^ pp2;
    assign carry1 = (pp0 & pp1) | (pp0 & pp2) | (pp1 & pp2);

    // Second reduction stage
    assign sum2 = sum1 ^ carry1 ^ pp3;
    assign carry2 = (sum1 & carry1) | (sum1 & pp3) | (carry1 & pp3);

    // Final addition
    assign p = sum2 + (carry2 << 1);

endmodule