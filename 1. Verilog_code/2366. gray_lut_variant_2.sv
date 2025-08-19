//SystemVerilog
module gray_lut #(parameter DEPTH=256, AW=8)(
    input clk, rst_n,
    input en,
    input valid_in,
    input [AW-1:0] addr,
    output reg valid_out,
    output reg [7:0] gray_out,
    output ready_in
);
    // Pipeline registers for data path
    reg [AW-1:0] addr_stage1;
    reg [7:0] memory_data;
    
    // Pipeline registers for control path
    reg valid_stage1;
    
    // LUT memory for gray code conversion
    reg [7:0] lut [0:DEPTH-1];
    
    // Subtractor LUT
    reg [7:0] sub_lut [0:15][0:15]; // 4-bit lookup tables for subtraction
    
    // Ready signal generation - always ready to accept new data
    assign ready_in = 1'b1;
    
    // Initialize LUTs
    initial begin
        $readmemh("gray_table.hex", lut);
        
        // Initialize subtraction lookup table
        for (int i = 0; i < 16; i = i + 1) begin
            for (int j = 0; j < 16; j = j + 1) begin
                sub_lut[i][j] = i - j;
            end
        end
    end
    
    // Pipeline Stage 1: Address registration
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= {AW{1'b0}};
            valid_stage1 <= 1'b0;
        end else if (en) begin
            addr_stage1 <= addr;
            valid_stage1 <= valid_in;
        end
    end
    
    // Internal wires for subtraction using lookup tables
    wire [3:0] upper_addr = addr_stage1[7:4];
    wire [3:0] lower_addr = addr_stage1[3:0];
    wire [7:0] sub_upper_result;
    wire [7:0] sub_lower_result;
    
    // Pipeline Stage 2: Memory lookup with subtractor LUT assist
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            memory_data <= 8'h00;
            gray_out <= 8'h00;
            valid_out <= 1'b0;
        end else if (en) begin
            // Replace direct memory lookup with LUT-based operation
            // First lookup the raw data
            memory_data <= lut[addr_stage1];
            
            // Use subtraction LUTs to compute adjustments
            // The upper and lower 4 bits are processed separately
            // and then combined to get the final gray code output
            gray_out <= {sub_lut[memory_data[7:4]][4'h1], sub_lut[memory_data[3:0]][4'h1]};
            valid_out <= valid_stage1;
        end
    end
endmodule