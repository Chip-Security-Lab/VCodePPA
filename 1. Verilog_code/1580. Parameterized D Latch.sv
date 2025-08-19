module param_d_latch #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] data_in,
    input wire enable,
    output reg [WIDTH-1:0] data_out
);
    always @* begin
        if (enable)
            data_out = data_in;
    end
endmodule