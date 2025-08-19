module ror_module #(
    parameter WIDTH = 8
)(
    input clk, rst, en,
    input [WIDTH-1:0] data_in,
    input [$clog2(WIDTH)-1:0] rotate_by,
    output reg [WIDTH-1:0] data_out
);
    always @(posedge clk) begin
        if (rst) data_out <= 0;
        else if (en)
            data_out <= {data_in, data_in} >> rotate_by;
    end
endmodule