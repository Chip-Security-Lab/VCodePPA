//SystemVerilog
module sync_left_logical_shifter #(
    parameter DATA_WIDTH = 8,
    parameter SHIFT_WIDTH = 3
)(
    input wire clk,
    input wire rst_n,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire [SHIFT_WIDTH-1:0] shift_amount,
    input wire valid_in,
    output wire valid_out,
    output wire [DATA_WIDTH-1:0] data_out
);
    // Stage 1 registers
    reg [DATA_WIDTH-1:0] data_stage1;
    reg [SHIFT_WIDTH-1:0] shift_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg [DATA_WIDTH-1:0] data_stage2;
    reg valid_stage2;
    
    // Stage 3 registers (output)
    reg [DATA_WIDTH-1:0] data_out_reg;
    reg valid_out_reg;
    
    // Signals for borrow subtractor
    wire [DATA_WIDTH-1:0] subtracted_value;
    wire [DATA_WIDTH:0] borrow;
    
    // Borrow subtractor implementation (8-bit)
    // This will calculate data_in - shift_amount (zero-extended)
    assign borrow[0] = 1'b0;  // No initial borrow
    
    genvar i;
    generate
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin: borrow_subtractor
            wire minuend = data_in[i];
            wire subtrahend = (i < SHIFT_WIDTH) ? shift_amount[i] : 1'b0;
            
            assign subtracted_value[i] = minuend ^ subtrahend ^ borrow[i];
            assign borrow[i+1] = (~minuend & subtrahend) | (~minuend & borrow[i]) | (subtrahend & borrow[i]);
        end
    endgenerate
    
    // Stage 1: Register inputs and subtracted value
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {DATA_WIDTH{1'b0}};
            shift_stage1 <= {SHIFT_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end
        else begin
            // Use the subtracted value for data_stage1
            data_stage1 <= subtracted_value;
            shift_stage1 <= shift_amount;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Perform first part of shift (up to half)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= {DATA_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else begin
            // Perform first part of the shift operation
            if (shift_stage1[SHIFT_WIDTH-1]) // MSB of shift amount
                data_stage2 <= data_stage1 << (1 << (SHIFT_WIDTH-1));
            else
                data_stage2 <= data_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Complete the shift operation and register output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_reg <= {DATA_WIDTH{1'b0}};
            valid_out_reg <= 1'b0;
        end
        else begin
            // Complete the shift operation
            data_out_reg <= data_stage2 << (shift_stage1 & ~(1 << (SHIFT_WIDTH-1)));
            valid_out_reg <= valid_stage2;
        end
    end
    
    // Connect outputs
    assign data_out = data_out_reg;
    assign valid_out = valid_out_reg;
    
endmodule