//SystemVerilog
module PipelinedOR (
    input wire clk,
    input wire rst,
    input wire [1:0] a,
    input wire [1:0] b,
    output wire [3:0] y
);

    // Pipeline Stage 1: Bitwise OR operations
    wire or_result_bit0_s1;
    wire or_result_bit1_s1;

    OR_basic or_inst_bit0_s1 (
        .a(a[0]),
        .b(b[0]),
        .y(or_result_bit0_s1)
    );

    OR_basic or_inst_bit1_s1 (
        .a(a[1]),
        .b(b[1]),
        .y(or_result_bit1_s1)
    );

    // Registered outputs of Stage 1
    reg or_result_bit0_s1_reg;
    reg or_result_bit1_s1_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            or_result_bit0_s1_reg <= 1'b0;
            or_result_bit1_s1_reg <= 1'b0;
        end else begin
            or_result_bit0_s1_reg <= or_result_bit0_s1;
            or_result_bit1_s1_reg <= or_result_bit1_s1;
        end
    end

    // Pipeline Stage 2: Combine results and assign fixed values
    reg [3:0] y_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            y_reg <= 4'b0000;
        end else begin
            y_reg[0] <= or_result_bit0_s1_reg;
            y_reg[1] <= or_result_bit1_s1_reg;
            y_reg[3:2] <= 2'b11; // Assign fixed values in Stage 2
        end
    end

    // Output of Pipeline Stage 2
    assign y = y_reg;

endmodule

// Basic OR gate module
module OR_basic (
    input wire a,
    input wire b,
    output wire y
);
    assign y = a | b;
endmodule