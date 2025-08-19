//SystemVerilog
module sync_circular_left_shifter #(parameter WIDTH = 8) (
    input clk,
    input [2:0] shift_amt,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);

    reg [WIDTH-1:0] data_in_reg;
    reg [2:0] shift_amt_reg;
    reg [WIDTH-1:0] shift_result;

    // Input data register
    always @(posedge clk) begin
        data_in_reg <= data_in;
    end

    // Shift amount register
    always @(posedge clk) begin
        shift_amt_reg <= shift_amt;
    end

    // Combinational shift operation
    always @(*) begin
        case (shift_amt_reg)
            3'd1: shift_result = {data_in_reg[WIDTH-2:0], data_in_reg[WIDTH-1]};
            3'd2: shift_result = {data_in_reg[WIDTH-3:0], data_in_reg[WIDTH-1:WIDTH-2]};
            3'd3: shift_result = {data_in_reg[WIDTH-4:0], data_in_reg[WIDTH-1:WIDTH-3]};
            3'd4: shift_result = {data_in_reg[WIDTH-5:0], data_in_reg[WIDTH-1:WIDTH-4]};
            default: shift_result = data_in_reg;
        endcase
    end

    // Output register
    always @(posedge clk) begin
        data_out <= shift_result;
    end

endmodule