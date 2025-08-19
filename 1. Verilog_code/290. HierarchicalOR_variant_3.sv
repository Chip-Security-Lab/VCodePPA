//SystemVerilog
module OR_basic(
    input a, b,
    output y
);
    assign y = a | b; // Simple OR operation
endmodule

module HierarchicalOR_pipelined(
    input wire clk,
    input wire rst_n,
    input wire [1:0] a_in,
    input wire [1:0] b_in,
    output wire [3:0] y_out
);

    // Stage 1: Input Registers
    reg [1:0] a_stage1;
    reg [1:0] b_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= 2'b0;
            b_stage1 <= 2'b0;
        end else begin
            a_stage1 <= a_in;
            b_stage1 <= b_in;
        end
    end

    // Stage 2: OR operations (Combinational)
    wire or_result_bit0_stage2;
    wire or_result_bit1_stage2;

    OR_basic bit0_inst_stage2(.a(a_stage1[0]), .b(b_stage1[0]), .y(or_result_bit0_stage2));
    OR_basic bit1_inst_stage2(.a(a_stage1[1]), .b(b_stage1[1]), .y(or_result_bit1_stage2));

    // Stage 3: Register OR results
    reg or_result_bit0_stage3;
    reg or_result_bit1_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            or_result_bit0_stage3 <= 1'b0;
            or_result_bit1_stage3 <= 1'b0;
        end else begin
            or_result_bit0_stage3 <= or_result_bit0_stage2;
            or_result_bit1_stage3 <= or_result_bit1_stage2;
        end
    end

    // Stage 4: Constant Assignment and Output Register
    reg [3:0] y_stage4;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            y_stage4 <= 4'b0;
        end else begin
            y_stage4 <= {2'b11, or_result_bit1_stage3, or_result_bit0_stage3};
        end
    end

    assign y_out = y_stage4;

endmodule