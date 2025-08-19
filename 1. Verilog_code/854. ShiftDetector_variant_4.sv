//SystemVerilog
module ShiftDetector #(parameter WIDTH=8) (
    input clk, rst_n,
    input data_in,
    output reg sequence_found
);
    localparam PATTERN = 8'b11010010;
    reg [WIDTH-1:0] shift_reg;
    reg pattern_detected;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 'b0;
            pattern_detected <= 1'b0;
            sequence_found <= 1'b0;
        end else begin
            shift_reg <= {shift_reg[WIDTH-2:0], data_in};
            pattern_detected <= (shift_reg == PATTERN);
            sequence_found <= pattern_detected;
        end
    end
endmodule