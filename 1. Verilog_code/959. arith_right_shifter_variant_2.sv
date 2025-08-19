//SystemVerilog
module arith_right_shifter (
    input CLK, RST_n,
    input [15:0] DATA_IN,
    input SHIFT,
    output reg [15:0] DATA_OUT
);
    // Pipeline stage 1: Input registration
    reg [15:0] data_stage1;
    reg shift_stage1;
    
    // Pipeline stage 2: Computation preparation
    reg [15:0] data_stage2;
    // Buffered copies of data_stage2 to reduce fanout
    reg [15:0] data_stage2_buf1;
    reg [15:0] data_stage2_buf2;
    
    reg shift_stage2;
    reg sign_bit_stage2;
    
    // Pipeline stage 3: Shift computation
    reg [15:0] data_stage3;
    
    // Sign bit buffers to reduce fanout
    reg sign_bit_buf1;
    reg sign_bit_buf2;
    
    always @(posedge CLK) begin
        if (!RST_n) begin
            // Reset all pipeline registers
            data_stage1 <= 16'h0000;
            shift_stage1 <= 1'b0;
            data_stage2 <= 16'h0000;
            data_stage2_buf1 <= 16'h0000;
            data_stage2_buf2 <= 16'h0000;
            shift_stage2 <= 1'b0;
            sign_bit_stage2 <= 1'b0;
            sign_bit_buf1 <= 1'b0;
            sign_bit_buf2 <= 1'b0;
            data_stage3 <= 16'h0000;
            DATA_OUT <= 16'h0000;
        end else begin
            // Stage 1: Register inputs
            data_stage1 <= DATA_IN;
            shift_stage1 <= SHIFT;
            
            // Stage 2: Prepare for shift operation
            data_stage2 <= data_stage1;
            // Buffer copies to reduce fanout
            data_stage2_buf1 <= data_stage1;
            data_stage2_buf2 <= data_stage1;
            
            shift_stage2 <= shift_stage1;
            sign_bit_stage2 <= data_stage1[15]; // Capture sign bit for extension
            
            // Buffered sign bits
            sign_bit_buf1 <= data_stage1[15];
            sign_bit_buf2 <= data_stage1[15];
            
            // Stage 3: Perform the actual shift with sign extension
            if (shift_stage2) begin
                // Use buffered copies for different bit ranges to balance loads
                data_stage3[15] <= sign_bit_buf1;
                data_stage3[14:8] <= data_stage2_buf1[15:9];
                data_stage3[7:1] <= data_stage2_buf2[8:2];
                data_stage3[0] <= data_stage2[1];
            end else begin
                // Use buffered copies for different bit ranges
                data_stage3[15:8] <= data_stage2_buf1[15:8];
                data_stage3[7:0] <= data_stage2_buf2[7:0];
            end
                
            // Final stage: Output registration
            DATA_OUT <= data_stage3;
        end
    end
endmodule