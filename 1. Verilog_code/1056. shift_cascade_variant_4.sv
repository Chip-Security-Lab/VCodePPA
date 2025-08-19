//SystemVerilog
module shift_cascade #(parameter WIDTH=8, DEPTH=4) (
    input clk,
    input rst_n,
    input en,
    input [WIDTH-1:0] data_in,
    output [WIDTH-1:0] data_out,
    output             data_out_valid
);

    // Stage 1: Shift Register
    reg [WIDTH-1:0] shift_reg0_stage1;
    reg [WIDTH-1:0] shift_reg1_stage1;
    reg [WIDTH-1:0] shift_reg2_stage1;
    reg [WIDTH-1:0] shift_reg3_stage1;
    reg             valid_stage1;

    // Stage 2: Subtractor input pipeline
    reg [WIDTH-1:0] sub_a_stage2;
    reg [WIDTH-1:0] sub_b_stage2;
    reg             valid_stage2;

    // Stage 3: Subtractor output pipeline
    reg [WIDTH-1:0] sub_result_stage3;
    reg             valid_stage3;

    // Output assignment
    assign data_out      = sub_result_stage3;
    assign data_out_valid = valid_stage3;

    // Pipeline Stage 1: Shift register logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg0_stage1 <= {WIDTH{1'b0}};
            shift_reg1_stage1 <= {WIDTH{1'b0}};
            shift_reg2_stage1 <= {WIDTH{1'b0}};
            shift_reg3_stage1 <= {WIDTH{1'b0}};
            valid_stage1      <= 1'b0;
        end else if (en) begin
            shift_reg0_stage1 <= data_in;
            if (DEPTH > 1) shift_reg1_stage1 <= shift_reg0_stage1;
            if (DEPTH > 2) shift_reg2_stage1 <= shift_reg1_stage1;
            if (DEPTH > 3) shift_reg3_stage1 <= shift_reg2_stage1;
            valid_stage1      <= 1'b1;
        end else begin
            valid_stage1      <= 1'b0;
        end
    end

    // Pipeline Stage 2: Prepare subtractor inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sub_a_stage2  <= {WIDTH{1'b0}};
            sub_b_stage2  <= {WIDTH{1'b0}};
            valid_stage2  <= 1'b0;
        end else begin
            if (valid_stage1) begin
                sub_a_stage2 <= (DEPTH == 1) ? shift_reg0_stage1 :
                                (DEPTH == 2) ? shift_reg1_stage1 :
                                (DEPTH == 3) ? shift_reg2_stage1 : shift_reg3_stage1;
                sub_b_stage2 <= {WIDTH{1'b0}};
                valid_stage2 <= 1'b1;
            end else begin
                sub_a_stage2 <= sub_a_stage2;
                sub_b_stage2 <= sub_b_stage2;
                valid_stage2 <= 1'b0;
            end
        end
    end

    // Pipeline Stage 3: Subtractor result
    wire [WIDTH-1:0] sub_result_stage2;
    conditional_sum_subtractor_8bit u_cond_sum_sub_pipeline (
        .a   (sub_a_stage2),
        .b   (sub_b_stage2),
        .diff(sub_result_stage2)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sub_result_stage3 <= {WIDTH{1'b0}};
            valid_stage3      <= 1'b0;
        end else begin
            if (valid_stage2) begin
                sub_result_stage3 <= sub_result_stage2;
                valid_stage3      <= 1'b1;
            end else begin
                sub_result_stage3 <= sub_result_stage3;
                valid_stage3      <= 1'b0;
            end
        end
    end

endmodule

module conditional_sum_subtractor_8bit (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] diff
);
    wire [7:0] b_invert;
    wire       carry_in;
    wire [7:0] sum;

    assign b_invert = ~b;
    assign carry_in = 1'b1;

    conditional_sum_adder_8bit u_csa8 (
        .a(a),
        .b(b_invert),
        .cin(carry_in),
        .sum(sum)
    );

    assign diff = sum;
endmodule

module conditional_sum_adder_8bit (
    input  [7:0] a,
    input  [7:0] b,
    input        cin,
    output [7:0] sum
);
    wire [3:0] sum_low, sum_high0, sum_high1;
    wire       carry_low, carry_high0, carry_high1;

    // Low 4-bit adder
    conditional_sum_adder_4bit u_csa_low (
        .a(a[3:0]),
        .b(b[3:0]),
        .cin(cin),
        .sum(sum_low),
        .cout(carry_low)
    );

    // High 4-bit adder, carry_in = 0
    conditional_sum_adder_4bit u_csa_high0 (
        .a(a[7:4]),
        .b(b[7:4]),
        .cin(1'b0),
        .sum(sum_high0),
        .cout(carry_high0)
    );

    // High 4-bit adder, carry_in = 1
    conditional_sum_adder_4bit u_csa_high1 (
        .a(a[7:4]),
        .b(b[7:4]),
        .cin(1'b1),
        .sum(sum_high1),
        .cout(carry_high1)
    );

    assign sum[3:0] = sum_low;
    assign sum[7:4] = carry_low ? sum_high1 : sum_high0;

endmodule

module conditional_sum_adder_4bit (
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output [3:0] sum,
    output       cout
);
    wire [3:0] sum0, sum1;
    wire       carry0, carry1;

    // Ripple-carry adders for both carry_in = 0 and carry_in = 1
    ripple_carry_adder_4bit u_rca0 (
        .a(a),
        .b(b),
        .cin(1'b0),
        .sum(sum0),
        .cout(carry0)
    );

    ripple_carry_adder_4bit u_rca1 (
        .a(a),
        .b(b),
        .cin(1'b1),
        .sum(sum1),
        .cout(carry1)
    );

    assign sum  = cin ? sum1 : sum0;
    assign cout = cin ? carry1 : carry0;

endmodule

module ripple_carry_adder_4bit (
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output [3:0] sum,
    output       cout
);
    wire c1, c2, c3;

    full_adder u_fa0 (
        .a(a[0]),
        .b(b[0]),
        .cin(cin),
        .sum(sum[0]),
        .cout(c1)
    );
    full_adder u_fa1 (
        .a(a[1]),
        .b(b[1]),
        .cin(c1),
        .sum(sum[1]),
        .cout(c2)
    );
    full_adder u_fa2 (
        .a(a[2]),
        .b(b[2]),
        .cin(c2),
        .sum(sum[2]),
        .cout(c3)
    );
    full_adder u_fa3 (
        .a(a[3]),
        .b(b[3]),
        .cin(c3),
        .sum(sum[3]),
        .cout(cout)
    );
endmodule

module full_adder (
    input  a,
    input  b,
    input  cin,
    output sum,
    output cout
);
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (a & cin) | (b & cin);
endmodule