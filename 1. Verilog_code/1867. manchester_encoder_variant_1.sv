//SystemVerilog
module manchester_encoder (
    input wire clk,
    input wire rst,
    input wire data_in,
    output reg encoded
);
    // Data path signals
    reg clk_div;
    reg data_in_reg;
    reg enc_stage;
    
    // Clock divider logic - first pipeline stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div <= 1'b0;
        end else begin
            clk_div <= ~clk_div;
        end
    end
    
    // Data input registration - second pipeline stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_in_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
        end
    end
    
    // Encoding logic - third pipeline stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            enc_stage <= 1'b0;
        end else begin
            enc_stage <= data_in_reg ^ clk_div;
        end
    end
    
    // Output registration - fourth pipeline stage
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 1'b0;
        end else begin
            encoded <= enc_stage;
        end
    end
endmodule