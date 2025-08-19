//SystemVerilog
module hamming_16bit_enc_en(
    input clock, enable, clear,
    input [15:0] data_in,
    output reg [20:0] ham_out
);
    // Stage 1 registers
    reg [15:0] data_stage1;
    reg [4:0] parity_stage1;
    
    // Stage 2 registers
    reg [15:0] data_stage2;
    reg [4:0] parity_stage2;
    
    // Stage 3 registers
    reg [15:0] data_stage3;
    reg [4:0] parity_stage3;
    
    // Stage 1: Input and initial parity calculation
    always @(posedge clock) begin
        if (clear) begin
            data_stage1 <= 16'b0;
            parity_stage1 <= 5'b0;
        end
        else if (enable) begin
            data_stage1 <= data_in;
            parity_stage1[0] <= ^(data_in & 16'b1010_1010_1010_1010);
            parity_stage1[1] <= ^(data_in & 16'b1100_1100_1100_1100);
        end
    end
    
    // Stage 2: Additional parity calculation
    always @(posedge clock) begin
        if (clear) begin
            data_stage2 <= 16'b0;
            parity_stage2 <= 5'b0;
        end
        else if (enable) begin
            data_stage2 <= data_stage1;
            parity_stage2[0] <= parity_stage1[0];
            parity_stage2[1] <= parity_stage1[1];
            parity_stage2[2] <= ^(data_stage1 & 16'b1111_0000_1111_0000);
            parity_stage2[3] <= ^(data_stage1 & 16'b1111_1111_0000_0000);
        end
    end
    
    // Stage 3: Final parity calculation and output assembly
    always @(posedge clock) begin
        if (clear) begin
            data_stage3 <= 16'b0;
            parity_stage3 <= 5'b0;
            ham_out <= 21'b0;
        end
        else if (enable) begin
            data_stage3 <= data_stage2;
            parity_stage3[3:0] <= parity_stage2[3:0];
            parity_stage3[4] <= ^data_stage2;
            
            // Assemble output
            ham_out[0] <= parity_stage3[0];
            ham_out[1] <= parity_stage3[1];
            ham_out[3] <= parity_stage3[2];
            ham_out[7] <= parity_stage3[3];
            ham_out[15] <= parity_stage3[4];
            
            ham_out[20:16] <= data_stage3[15:11];
            ham_out[14:8] <= data_stage3[10:4];
            ham_out[6:4] <= data_stage3[3:1];
            ham_out[2] <= data_stage3[0];
        end
    end
endmodule