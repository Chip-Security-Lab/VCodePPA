module shift_right_logic #(parameter WIDTH=8) (
    input clk, rst_n,
    input [WIDTH-1:0] data_in,
    input [2:0] shift_amount,
    output reg [WIDTH-1:0] data_out
);
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) data_out <= 0;
    else data_out <= data_in >> shift_amount;
end
endmodule