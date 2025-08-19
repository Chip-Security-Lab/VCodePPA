//SystemVerilog
module manchester_encoder (
    input clk, rst, 
    input data_in,
    output reg encoded
);
    reg clk_div;
    reg data_reg;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div <= 0;
            data_reg <= 0;
        end else begin
            clk_div <= ~clk_div;
            data_reg <= data_in;
        end
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 0;
        end else begin
            encoded <= data_reg ^ clk_div;
        end
    end
endmodule