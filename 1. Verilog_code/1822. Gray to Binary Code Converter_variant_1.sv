//SystemVerilog
module gray2bin_unit #(parameter DATA_WIDTH = 8) (
    input  [DATA_WIDTH-1:0] gray_data,
    output [DATA_WIDTH-1:0] binary_data
);
    // Optimized binary conversion implementation
    // Using iterative approach to reduce logic depth and improve timing
    wire [DATA_WIDTH-1:0] intermediate [DATA_WIDTH-1:0];
    
    // First bit remains the same
    assign intermediate[0] = {gray_data[DATA_WIDTH-1], {(DATA_WIDTH-1){1'b0}}};
    
    // Efficient implementation with balanced tree structure
    genvar i, j;
    generate
        for (i = 1; i < DATA_WIDTH; i = i + 1) begin : conversion_stage
            for (j = 0; j < DATA_WIDTH; j = j + 1) begin : bit_calc
                if (j < DATA_WIDTH-i) begin
                    assign intermediate[i][j] = intermediate[i-1][j] ^ gray_data[DATA_WIDTH-1-j-i];
                end
                else begin
                    assign intermediate[i][j] = intermediate[i-1][j];
                end
            end
        end
    endgenerate
    
    // Assign output in optimized bit order
    genvar k;
    generate
        for (k = 0; k < DATA_WIDTH; k = k + 1) begin : output_assign
            assign binary_data[k] = intermediate[DATA_WIDTH-1][DATA_WIDTH-1-k];
        end
    endgenerate
endmodule