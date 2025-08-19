module ShiftDetector #(parameter WIDTH=8) (
    input clk, rst_n,
    input data_in,
    output reg sequence_found
);
localparam PATTERN = 8'b11010010;
reg [WIDTH-1:0] shift_reg;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) shift_reg <= 0;
    else shift_reg <= {shift_reg[WIDTH-2:0], data_in};
    sequence_found <= (shift_reg == PATTERN);
end
endmodule
