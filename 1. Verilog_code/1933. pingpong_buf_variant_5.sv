//SystemVerilog
// Top-level pingpong_buf module with hierarchical structure
module pingpong_buf #(parameter DW=16) (
    input clk,
    input switch,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);

    // Internal signals
    wire [DW-1:0] buf1_data_out, buf2_data_out;
    reg [DW-1:0] buf1_data_in, buf2_data_in;
    reg buf1_we, buf2_we;
    reg sel, sel_next;

    // Buffer 1: Single-word register buffer
    pingpong_reg_buf #(.DW(DW)) buf1_inst (
        .clk(clk),
        .we(buf1_we),
        .din(buf1_data_in),
        .dout(buf1_data_out)
    );

    // Buffer 2: Single-word register buffer
    pingpong_reg_buf #(.DW(DW)) buf2_inst (
        .clk(clk),
        .we(buf2_we),
        .din(buf2_data_in),
        .dout(buf2_data_out)
    );

    // Selector logic: Handles buffer selection and switching
    always @(posedge clk) begin
        if (switch) begin
            dout <= sel ? buf1_data_out : buf2_data_out;
            sel <= sel_next;
        end else begin
            sel <= sel;
        end
    end

    // Control logic for buffer write enables and selector
    always @(*) begin
        buf1_we = 1'b0;
        buf2_we = 1'b0;
        buf1_data_in = {DW{1'b0}};
        buf2_data_in = {DW{1'b0}};
        sel_next = sel;

        if (switch) begin
            sel_next = ~sel;
        end else begin
            if (sel) begin
                buf2_we = 1'b1;
                buf2_data_in = din;
            end else begin
                buf1_we = 1'b1;
                buf1_data_in = din;
            end
        end
    end

endmodule

// -----------------------------------------------------------------------------
// Single-word Register Buffer Module for Ping-Pong Buffer
// Stores input data when write enable is asserted.
// Includes 8-bit conditional sum subtractor as a submodule
// -----------------------------------------------------------------------------
module pingpong_reg_buf #(parameter DW=16) (
    input clk,
    input we,
    input [DW-1:0] din,
    output reg [DW-1:0] dout
);
    // Internal signals for 8-bit conditional sum subtractor
    wire [7:0] cond_sum_sub_result;
    wire cond_sum_sub_borrow;

    // Example usage of 8-bit conditional sum subtractor for demo
    // Connect the lower 8 bits to the subtractor, upper bits pass through
    cond_sum_subtractor_8bit cond_sum_subtractor_inst (
        .a(din[7:0]),
        .b(dout[7:0]),
        .diff(cond_sum_sub_result),
        .borrow_out(cond_sum_sub_borrow)
    );

    always @(posedge clk) begin
        if (we)
            dout <= din;
    end
endmodule

// -----------------------------------------------------------------------------
// 8-bit Conditional Sum Subtractor (条件求和减法器)
// DW=8
// diff = a - b
// -----------------------------------------------------------------------------
module cond_sum_subtractor_8bit (
    input  [7:0] a,
    input  [7:0] b,
    output [7:0] diff,
    output       borrow_out
);
    // Internal signals
    wire [7:0] b_inverted;
    wire       c_in;
    wire [7:0] sum;
    wire       carry_out;

    assign b_inverted = ~b;
    assign c_in = 1'b1;

    // Conditional sum adder logic for subtraction (a - b = a + (~b) + 1)
    cond_sum_adder_8bit cond_sum_adder_inst (
        .a(a),
        .b(b_inverted),
        .cin(c_in),
        .sum(sum),
        .cout(carry_out)
    );

    assign diff = sum;
    assign borrow_out = ~carry_out;
endmodule

// -----------------------------------------------------------------------------
// 8-bit Conditional Sum Adder
// DW=8
// sum = a + b + cin
// -----------------------------------------------------------------------------
module cond_sum_adder_8bit (
    input  [7:0] a,
    input  [7:0] b,
    input        cin,
    output [7:0] sum,
    output       cout
);
    // Lower 4 bits
    wire [3:0] sum0, sum1;
    wire       carry0, carry1;
    wire       carry4;

    // Upper 4 bits
    wire [3:0] sum_upper_0, sum_upper_1;
    wire       carry_upper_0, carry_upper_1;

    // First 4 bits: two possible sums, for cin=0 and cin=1
    cond_sum_adder_4bit lower_adder (
        .a(a[3:0]),
        .b(b[3:0]),
        .cin(cin),
        .sum(sum0),
        .cout(carry4)
    );

    // Upper 4 bits: two possible sums, for carry4=0 and carry4=1
    cond_sum_adder_4bit upper_adder_0 (
        .a(a[7:4]),
        .b(b[7:4]),
        .cin(1'b0),
        .sum(sum_upper_0),
        .cout(carry_upper_0)
    );
    cond_sum_adder_4bit upper_adder_1 (
        .a(a[7:4]),
        .b(b[7:4]),
        .cin(1'b1),
        .sum(sum_upper_1),
        .cout(carry_upper_1)
    );

    assign sum[3:0] = sum0;
    assign sum[7:4] = carry4 ? sum_upper_1 : sum_upper_0;
    assign cout     = carry4 ? carry_upper_1 : carry_upper_0;
endmodule

// -----------------------------------------------------------------------------
// 4-bit Conditional Sum Adder
// sum = a + b + cin
// -----------------------------------------------------------------------------
module cond_sum_adder_4bit (
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output [3:0] sum,
    output       cout
);
    wire [3:0] sum0, sum1;
    wire       carry0, carry1;

    // Ripple carry for cin=0
    ripple_carry_adder_4bit adder0 (
        .a(a),
        .b(b),
        .cin(1'b0),
        .sum(sum0),
        .cout(carry0)
    );
    // Ripple carry for cin=1
    ripple_carry_adder_4bit adder1 (
        .a(a),
        .b(b),
        .cin(1'b1),
        .sum(sum1),
        .cout(carry1)
    );

    assign sum  = cin ? sum1  : sum0;
    assign cout = cin ? carry1 : carry0;
endmodule

// -----------------------------------------------------------------------------
// 4-bit Ripple Carry Adder
// sum = a + b + cin
// -----------------------------------------------------------------------------
module ripple_carry_adder_4bit (
    input  [3:0] a,
    input  [3:0] b,
    input        cin,
    output [3:0] sum,
    output       cout
);
    wire [3:0] carry;

    assign {carry[0], sum[0]} = a[0] + b[0] + cin;
    assign {carry[1], sum[1]} = a[1] + b[1] + carry[0];
    assign {carry[2], sum[2]} = a[2] + b[2] + carry[1];
    assign {cout,     sum[3]} = a[3] + b[3] + carry[2];
endmodule