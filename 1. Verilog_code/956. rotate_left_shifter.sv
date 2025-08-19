module rotate_left_shifter (
    input clk, rst, enable,
    output reg [7:0] data_out
);
    // Pre-load with pattern
    initial data_out = 8'b10101010;
    
    always @(posedge clk) begin
        if (rst)
            data_out <= 8'b10101010;
        else if (enable)
            data_out <= {data_out[6:0], data_out[7]};
    end
endmodule