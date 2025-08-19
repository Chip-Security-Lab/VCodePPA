module rotate_left(
    input [31:0] data,
    input [4:0] amount,
    output [31:0] result
);
    assign result = (data << amount) | (data >> (32 - amount));
endmodule

// 5. Rotate Right with Enable
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