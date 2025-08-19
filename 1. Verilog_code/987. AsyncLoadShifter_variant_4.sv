//SystemVerilog
module AsyncLoadShifter #(parameter WIDTH=8) (
    input clk,
    input async_load,
    input [WIDTH-1:0] load_data,
    output [WIDTH-1:0] data_reg
);

reg [WIDTH-1:0] data_reg_next;
reg [WIDTH-1:0] data_reg_reg;

always @(*) begin
    data_reg_next = async_load ? load_data : {data_reg_reg[WIDTH-2:0], 1'b0};
end

always @(posedge clk or posedge async_load) begin
    data_reg_reg <= async_load ? load_data : data_reg_next;
end

assign data_reg = data_reg_reg;

endmodule