//SystemVerilog
module pipelined_ashift (
    input clk, rst,
    input [31:0] din,
    input [4:0] shift,
    output reg [31:0] dout
);
    // Intermediate signals
    reg [31:0] stage1_data;
    reg [4:0] stage1_shift;
    reg sign_bit;
    
    // Buffer registers for high fan-out signals
    reg sign_bit_buf1, sign_bit_buf2, sign_bit_buf3, sign_bit_buf4;
    
    // First pipeline stage
    always @(posedge clk) begin
        if (rst) begin
            stage1_data <= 32'b0;
            stage1_shift <= 5'b0;
            sign_bit <= 1'b0;
            
            // Reset buffer registers
            sign_bit_buf1 <= 1'b0;
            sign_bit_buf2 <= 1'b0;
            sign_bit_buf3 <= 1'b0;
            sign_bit_buf4 <= 1'b0;
        end else begin
            stage1_data <= din;
            stage1_shift <= shift;
            sign_bit <= din[31]; // Save sign bit for sign extension
            
            // Distribute sign_bit to multiple buffers to reduce fan-out
            sign_bit_buf1 <= sign_bit;
            sign_bit_buf2 <= sign_bit;
            sign_bit_buf3 <= sign_bit;
            sign_bit_buf4 <= sign_bit;
        end
    end
    
    // Extension pattern calculation
    reg [31:0] extension_pattern;
    reg [31:0] shifted_data;
    
    // Second pipeline stage - split operations to improve timing
    always @(posedge clk) begin
        if (rst) begin
            extension_pattern <= 32'b0;
            shifted_data <= 32'b0;
        end else begin
            // Calculate extension pattern using distributed sign bit buffers
            extension_pattern[7:0]   <= {8{sign_bit_buf1}} & (~(8'hFF >> stage1_shift));
            extension_pattern[15:8]  <= {8{sign_bit_buf2}} & (~(8'hFF >> stage1_shift));
            extension_pattern[23:16] <= {8{sign_bit_buf3}} & (~(8'hFF >> stage1_shift));
            extension_pattern[31:24] <= {8{sign_bit_buf4}} & (~(8'hFF >> stage1_shift));
            
            // Calculate shifted data 
            shifted_data <= stage1_data >> stage1_shift;
        end
    end
    
    // Final output stage
    always @(posedge clk) begin
        if (rst) begin
            dout <= 32'b0;
        end else begin
            // Combine extension pattern with shifted data
            dout <= extension_pattern | shifted_data;
        end
    end
endmodule