module sipo_register(
    input clk, rst, enable,
    input serial_in,
    output reg [7:0] parallel_out
);
    always @(posedge clk) begin
        if (rst)
            parallel_out <= 8'b0;
        else if (enable)
            parallel_out <= {parallel_out[6:0], serial_in};
    end
endmodule