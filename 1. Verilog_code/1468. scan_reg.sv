module scan_reg(
    input clk, rst_n,
    input [7:0] parallel_data,
    input scan_in, scan_en, load,
    output reg [7:0] data_out,
    output scan_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 8'b0;
        else if (scan_en)
            data_out <= {data_out[6:0], scan_in};
        else if (load)
            data_out <= parallel_data;
    end
    
    assign scan_out = data_out[7];
endmodule
