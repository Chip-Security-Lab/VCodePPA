//SystemVerilog
module dram_write_mask #(
    parameter DATA_WIDTH = 64,
    parameter MASK_WIDTH = 8
)(
    input clk,
    input [MASK_WIDTH-1:0] mask,
    input [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);

    // Pipeline registers
    reg [MASK_WIDTH-1:0] mask_reg;
    reg [DATA_WIDTH-1:0] data_in_reg;
    
    // First pipeline stage
    always @(posedge clk) begin
        mask_reg <= mask;
        data_in_reg <= data_in;
    end

    // Second pipeline stage with masked data
    reg [DATA_WIDTH-1:0] masked_data;
    genvar i;
    generate
        for(i=0; i<MASK_WIDTH; i=i+1) begin : mask_logic
            always @(posedge clk) begin
                if(mask_reg[i])
                    masked_data[(i*8) +: 8] <= data_in_reg[(i*8) +: 8];
                else
                    masked_data[(i*8) +: 8] <= 8'b0;
            end
        end
    endgenerate

    // Final output stage
    always @(posedge clk) begin
        data_out <= masked_data;
    end

endmodule