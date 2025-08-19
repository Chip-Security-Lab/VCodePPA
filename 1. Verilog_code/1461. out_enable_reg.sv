module out_enable_reg(
    input clk, rst,
    input [15:0] data_in,
    input load, out_en,
    output [15:0] data_out
);
    reg [15:0] stored_data;

    always @(posedge clk) begin
        if (rst)
            stored_data <= 16'h0;
        else if (load)
            stored_data <= data_in;
    end
    
    assign data_out = out_en ? stored_data : 16'hZ;
endmodule