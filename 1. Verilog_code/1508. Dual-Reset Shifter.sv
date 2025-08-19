module dual_reset_shifter #(parameter WIDTH = 8) (
    input wire clk, sync_rst, async_rst, enable, data_in,
    output reg [WIDTH-1:0] data_out
);
    always @(posedge clk or posedge async_rst) begin
        if (async_rst)
            data_out <= 0;
        else if (sync_rst)
            data_out <= 0;
        else if (enable)
            data_out <= {data_out[WIDTH-2:0], data_in};
    end
endmodule