//SystemVerilog
module even_divider #(
    parameter DIV_WIDTH = 8,
    parameter DIV_VALUE = 10
)(
    input clk_in,
    input rst_n,
    output reg clk_out
);

reg [DIV_WIDTH-1:0] counter;
wire [DIV_WIDTH-1:0] next_counter;
wire borrow;
wire [DIV_WIDTH-1:0] half_value = DIV_VALUE >> 1;

// Borrow subtractor implementation
assign {borrow, next_counter} = counter - 1'b1;

always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) begin
        counter <= 0;
        clk_out <= 0;
    end else begin
        counter <= (counter == 0) ? DIV_VALUE-1 : next_counter;
        clk_out <= (counter < half_value) ? 1'b0 : 1'b1;
    end
end

endmodule