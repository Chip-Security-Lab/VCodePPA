module UniversalShifter #(parameter WIDTH=8) (
    input clk,
    input [1:0] mode, // 00:hold 01:left 10:right 11:load
    input serial_in,
    input [WIDTH-1:0] parallel_in,
    output reg [WIDTH-1:0] data_reg
);
always @(posedge clk) begin
    case(mode)
        2'b01: data_reg <= {data_reg[WIDTH-2:0], serial_in};
        2'b10: data_reg <= {serial_in, data_reg[WIDTH-1:1]};
        2'b11: data_reg <= parallel_in;
        default: data_reg <= data_reg;
    endcase
end
endmodule