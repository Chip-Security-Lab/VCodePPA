module shift_bidir_cycl #(parameter WIDTH=8) (
    input clk, dir, en,
    input [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] data_out
);
always @(posedge clk) if (en) begin
    data_out <= dir ? {data_in[0], data_in[WIDTH-1:1]} // 右移
                   : {data_in[WIDTH-2:0], data_in[WIDTH-1]}; // 左移
end
endmodule
