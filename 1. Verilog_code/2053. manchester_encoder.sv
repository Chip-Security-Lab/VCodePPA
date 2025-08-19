module manchester_encoder (
    input wire clk, rst_n, enable,
    input wire data_in,
    output reg manchester_out
);
    reg half_bit;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            manchester_out <= 1'b0;
            half_bit <= 1'b0;
        end else if (enable) begin
            half_bit <= ~half_bit;
            if (!half_bit) 
                manchester_out <= data_in ? 1'b0 : 1'b1;
            else
                manchester_out <= data_in ? 1'b1 : 1'b0;
        end
    end
endmodule