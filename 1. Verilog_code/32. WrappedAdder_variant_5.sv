//SystemVerilog
module Adder_10_pipelined(
    input wire clk,
    input wire rst_n,
    input wire [3:0] A,
    input wire [3:0] B,
    output wire [4:0] sum
);

    // Stage 1: Input Registration
    reg [3:0] A_s1;
    reg [3:0] B_s1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_s1 <= 'b0;
            B_s1 <= 'b0;
        end else begin
            A_s1 <= A;
            B_s1 <= B;
        end
    end

    // Stage 2: Lower 2-bit addition and Registration
    // Calculate A_s1[1:0] + B_s1[1:0] -> {c_lower_comb, s_lower_comb[1:0]}
    // Pass A_s1[3:2], B_s1[3:2]
    wire [1:0] A_lower_s1 = A_s1[1:0];
    wire [1:0] B_lower_s1 = B_s1[1:0];
    wire [1:0] A_upper_s1 = A_s1[3:2];
    wire [1:0] B_upper_s1 = B_s1[3:2];

    wire [2:0] lower_sum_comb = A_lower_s1 + B_lower_s1; // {c_lower_comb, s_lower_comb[1:0]}
    wire c_lower_comb = lower_sum_comb[2];
    wire [1:0] s_lower_comb = lower_sum_comb[1:0];

    reg c_lower_s2;
    reg [1:0] s_lower_s2;
    reg [1:0] A_upper_s2;
    reg [1:0] B_upper_s2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_lower_s2 <= 'b0;
            s_lower_s2 <= 'b0;
            A_upper_s2 <= 'b0;
            B_upper_s2 <= 'b0;
        end else begin
            c_lower_s2 <= c_lower_comb;
            s_lower_s2 <= s_lower_comb;
            A_upper_s2 <= A_upper_s1; // Pass upper bits
            B_upper_s2 <= B_upper_s1; // Pass upper bits
        end
    end

    // Stage 3: Upper 2-bit addition with carry and Registration
    // Calculate A_upper_s2 + B_upper_s2 + c_lower_s2 -> {c_upper_comb, s_upper_comb[1:0]}
    // Pass s_lower_s2
    wire [2:0] upper_sum_comb = A_upper_s2 + B_upper_s2 + c_lower_s2; // {c_upper_comb, s_upper_comb[1:0]}
    wire c_upper_comb = upper_sum_comb[2];
    wire [1:0] s_upper_comb = upper_sum_comb[1:0];
    wire [1:0] s_lower_s2_wire = s_lower_s2; // Wire for clarity

    reg c_upper_s3;
    reg [1:0] s_upper_s3;
    reg [1:0] s_lower_s3; // Pass lower sum through

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            c_upper_s3 <= 'b0;
            s_upper_s3 <= 'b0;
            s_lower_s3 <= 'b0;
        end else begin
            c_upper_s3 <= c_upper_comb;
            s_upper_s3 <= s_upper_comb;
            s_lower_s3 <= s_lower_s2_wire; // Pass lower sum
        end
    end

    // Output: Combine results from Stage 3
    // sum = {c_upper_s3, s_upper_s3, s_lower_s3}
    assign sum = {c_upper_s3, s_upper_s3, s_lower_s3};

endmodule