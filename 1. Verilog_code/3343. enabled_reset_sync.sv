module enabled_reset_sync (
    input  wire clk_in,
    input  wire rst_in_n,
    input  wire enable,
    output reg  rst_out_n
);
    reg metastable;
    
    always @(posedge clk_in or negedge rst_in_n) begin
        if (!rst_in_n) begin
            metastable <= 1'b0;
            rst_out_n <= 1'b0;
        end else if (enable) begin
            metastable <= 1'b1;
            rst_out_n <= metastable;
        end
    end
endmodule