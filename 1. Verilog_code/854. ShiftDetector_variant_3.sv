//SystemVerilog
module ShiftDetector #(parameter WIDTH=8) (
    input clk, rst_n,
    input data_in,
    output reg sequence_found
);
localparam PATTERN = 8'b11010010;
reg [WIDTH-1:0] shift_reg;
reg [WIDTH-1:0] next_shift_reg;
reg [WIDTH-1:0] shift_reg_buf;
reg pattern_match;
reg pattern_match_buf;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        shift_reg <= 0;
        shift_reg_buf <= 0;
        pattern_match <= 0;
        pattern_match_buf <= 0;
        sequence_found <= 0;
    end
    else begin
        shift_reg <= next_shift_reg;
        shift_reg_buf <= shift_reg;
        pattern_match <= (shift_reg == PATTERN);
        pattern_match_buf <= pattern_match;
        sequence_found <= pattern_match_buf;
    end
end

always @(*) begin
    next_shift_reg = {shift_reg[WIDTH-2:0], data_in};
end

endmodule