//SystemVerilog
module dynamic_xor_mask #(
    parameter WIDTH = 64
)(
    input clk,
    input reset,
    input en,
    input valid_in,
    output reg ready_in,
    input [WIDTH-1:0] data_in,
    output reg valid_out,
    input ready_out,
    output reg [WIDTH-1:0] data_out
);
    // Pipeline registers for mask generation
    reg [WIDTH-1:0] mask_reg;
    
    // Split the mask calculation pipeline
    reg [WIDTH/2-1:0] mask_upper_temp;
    reg [WIDTH/2-1:0] mask_lower_temp;
    reg [WIDTH-1:0] mask_stage1;
    
    // Split data pipeline
    reg [WIDTH/2-1:0] data_upper_stage1;
    reg [WIDTH/2-1:0] data_lower_stage1;
    
    // Split XOR operation pipeline
    reg [WIDTH/2-1:0] xor_upper_temp;
    reg [WIDTH/2-1:0] xor_lower_temp;
    
    // Pipeline control signals
    reg valid_stage1;
    reg valid_stage2;
    wire stall = valid_out && !ready_out;
    
    // Constants for mask generation (split for better timing)
    localparam [WIDTH/2-1:0] CONST_UPPER = 32'h9E37;
    localparam [WIDTH/2-1:0] CONST_LOWER = 32'h79B9;
    
    // Stage 1: Initial mask generation with split operations
    always @(posedge clk) begin
        if (reset) begin
            mask_reg <= {WIDTH{1'b0}};
            mask_upper_temp <= {(WIDTH/2){1'b0}};
            mask_lower_temp <= {(WIDTH/2){1'b0}};
            valid_stage1 <= 1'b0;
            ready_in <= 1'b1;
        end else begin
            ready_in <= !stall;
            
            if (!stall && valid_in && en) begin
                // Split mask calculation into two parts for better timing
                mask_upper_temp <= mask_reg[WIDTH-1:WIDTH/2] ^ CONST_UPPER;
                mask_lower_temp <= mask_reg[WIDTH/2-1:0] ^ CONST_LOWER;
                
                // Store input data (split for easier pipelining)
                data_upper_stage1 <= data_in[WIDTH-1:WIDTH/2];
                data_lower_stage1 <= data_in[WIDTH/2-1:0];
                
                valid_stage1 <= 1'b1;
            end else if (!stall) begin
                valid_stage1 <= 1'b0;
            end
        end
    end
    
    // Stage 2: Complete mask generation and prepare for XOR
    always @(posedge clk) begin
        if (reset) begin
            mask_stage1 <= {WIDTH{1'b0}};
            xor_upper_temp <= {(WIDTH/2){1'b0}};
            xor_lower_temp <= {(WIDTH/2){1'b0}};
            valid_stage2 <= 1'b0;
            mask_reg <= {WIDTH{1'b0}};
        end else if (!stall) begin
            if (valid_stage1) begin
                // Assemble the full mask and update mask_reg for next cycle
                mask_stage1 <= {mask_upper_temp, mask_lower_temp};
                mask_reg <= {mask_upper_temp, mask_lower_temp};
                
                // Pre-compute XOR operations separately for better timing
                xor_upper_temp <= data_upper_stage1 ^ mask_upper_temp;
                xor_lower_temp <= data_lower_stage1 ^ mask_lower_temp;
                
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end
    
    // Stage 3: Final assembly of output data
    always @(posedge clk) begin
        if (reset) begin
            data_out <= {WIDTH{1'b0}};
            valid_out <= 1'b0;
        end else if (!stall) begin
            if (valid_stage2) begin
                // Combine the XOR results
                data_out <= {xor_upper_temp, xor_lower_temp};
                valid_out <= 1'b1;
            end else begin
                valid_out <= 1'b0;
            end
        end
    end
endmodule