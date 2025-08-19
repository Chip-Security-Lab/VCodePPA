//SystemVerilog
module gray_signal_recovery (
    input clk,
    input enable,
    input [3:0] gray_in,
    output reg [3:0] binary_out,
    output reg valid
);

    // Stage 1 registers
    reg [3:0] gray_stage1;
    reg enable_stage1;
    
    // Stage 1 buffered signals (reduce fanout)
    reg [3:0] gray_stage1_buf1;
    reg [3:0] gray_stage1_buf2;
    
    // Stage 2 registers
    reg [3:0] decoded_stage2;
    reg [3:0] prev_gray_stage2;
    reg enable_stage2;
    
    // Decoded buffered signals (reduce fanout)
    reg [3:0] decoded_buf;
    
    // Stage 3 registers
    reg [3:0] binary_stage3;
    reg [3:0] prev_gray_stage3;
    reg valid_stage3;
    
    // Stage 1: Input sampling
    always @(posedge clk) begin
        gray_stage1 <= gray_in;
        enable_stage1 <= enable;
    end
    
    // Stage 1 buffer registers to distribute fanout load
    always @(posedge clk) begin
        gray_stage1_buf1 <= gray_stage1;
        gray_stage1_buf2 <= gray_stage1;
    end
    
    // Stage 2: Gray to binary conversion
    wire [3:0] decoded;
    assign decoded[3] = gray_stage1[3];
    assign decoded[2] = decoded[3] ^ gray_stage1_buf1[2];
    assign decoded[1] = decoded[2] ^ gray_stage1_buf1[1];
    assign decoded[0] = decoded[1] ^ gray_stage1_buf1[0];
    
    // Buffer for decoded signal to reduce fanout
    always @(posedge clk) begin
        decoded_buf <= decoded;
    end
    
    always @(posedge clk) begin
        if (enable_stage1) begin
            decoded_stage2 <= decoded_buf;
            prev_gray_stage2 <= gray_stage1_buf2;
            enable_stage2 <= 1'b1;
        end else begin
            enable_stage2 <= 1'b0;
        end
    end
    
    // Stage 3: Output generation
    always @(posedge clk) begin
        if (enable_stage2) begin
            binary_stage3 <= decoded_stage2;
            prev_gray_stage3 <= prev_gray_stage2;
            valid_stage3 <= (prev_gray_stage2 != gray_stage1_buf2);
        end else begin
            valid_stage3 <= 1'b0;
        end
    end
    
    // Output assignment
    always @(posedge clk) begin
        binary_out <= binary_stage3;
        valid <= valid_stage3;
    end

endmodule