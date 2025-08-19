//SystemVerilog
module johnson_counter #(parameter WIDTH = 4) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg [WIDTH-1:0] johnson_code
);
    reg [WIDTH-1:0] next_johnson_code;
    wire [7:0] subtract_operand; // 8-bit for operation
    wire [7:0] subtract_result;

    // Subtractor using two's complement addition for 8-bit width
    assign subtract_operand = { {8-WIDTH{1'b0}}, johnson_code[0] }; // zero-extend to 8 bits
    assign subtract_result = { {8-WIDTH{1'b0}}, johnson_code[WIDTH-1:1] } + (~subtract_operand + 8'b1);

    always @(*) begin
        if (!rst_n)
            next_johnson_code = {WIDTH{1'b0}};
        else if (enable) begin
            // Replace bitwise NOT with two's complement subtraction
            next_johnson_code = {subtract_result[0], johnson_code[WIDTH-1:1]};
        end else
            next_johnson_code = johnson_code;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            johnson_code <= {WIDTH{1'b0}};
        else
            johnson_code <= next_johnson_code;
    end
endmodule