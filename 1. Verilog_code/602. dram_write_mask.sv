module dram_write_mask #(
    parameter DATA_WIDTH = 64,
    parameter MASK_WIDTH = 8
)(
    input clk,
    input [MASK_WIDTH-1:0] mask,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);
    genvar i;
    generate
        for(i=0; i<MASK_WIDTH; i=i+1) begin : mask_logic
            always @(posedge clk) begin
                if(mask[i]) 
                    data_out[(i*8) +: 8] <= data_in[(i*8) +: 8];
                else
                    data_out[(i*8) +: 8] <= 8'b0;  // 使用0代替Z
            end
        end
    endgenerate
endmodule