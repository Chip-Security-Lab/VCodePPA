//SystemVerilog
module BlockCompress #(parameter BLK=4) (
    input clk, blk_en,
    input [BLK*8-1:0] data,
    output reg [15:0] code
);

    // Intermediate signals for retiming
    reg [BLK*8-1:0] data_reg;
    wire [15:0] xor_result;
    
    // Move input register forward
    always @(posedge clk) begin
        if(blk_en) begin
            data_reg <= data;
        end
    end
    
    // Combinational XOR operation
    assign xor_result = ^data_reg;
    
    // Output register
    always @(posedge clk) begin
        if(blk_en) begin
            code <= xor_result;
        end
    end
    
endmodule