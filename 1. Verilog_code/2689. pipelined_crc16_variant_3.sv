//SystemVerilog
module pipelined_crc16(
    input wire clk,
    input wire rst,
    input wire [7:0] data_in,
    input wire data_valid,
    output reg [15:0] crc_out
);
    parameter [15:0] POLY = 16'h1021;
    
    // Pipeline stages for CRC calculation
    reg [15:0] stage1, stage2, stage3, stage4;
    
    // Intermediate signals to break long combinational paths
    reg stage1_xor, stage2_xor, stage3_xor, stage4_xor;
    reg [15:0] stage1_poly, stage2_poly, stage3_poly, stage4_poly;
    reg [15:0] stage1_shifted, stage2_shifted, stage3_shifted, stage4_shifted;
    
    // Pipeline registers for data
    reg [3:0] data_pipeline;
    
    always @(posedge clk) begin
        if (rst) begin
            // Reset all registers
            stage1 <= 16'hFFFF;
            stage2 <= 16'hFFFF;
            stage3 <= 16'hFFFF;
            stage4 <= 16'hFFFF;
            crc_out <= 16'hFFFF;
            
            stage1_xor <= 1'b0;
            stage2_xor <= 1'b0;
            stage3_xor <= 1'b0;
            stage4_xor <= 1'b0;
            
            data_pipeline <= 4'b0000;
        end else if (data_valid) begin
            // First pipeline stage
            stage1_xor <= stage1[15] ^ data_in[7];
            stage1_shifted <= {stage1[14:0], 1'b0};
            data_pipeline <= data_in[7:4];
            
            // Second pipeline stage
            stage1_poly <= stage1_xor ? POLY : 16'h0;
            stage1 <= stage1_shifted ^ stage1_poly;
            stage2_xor <= stage2[15] ^ data_pipeline[3];
            stage2_shifted <= {stage2[14:0], 1'b0};
            
            // Third pipeline stage
            stage2_poly <= stage2_xor ? POLY : 16'h0;
            stage2 <= stage2_shifted ^ stage2_poly;
            stage3_xor <= stage3[15] ^ data_pipeline[2];
            stage3_shifted <= {stage3[14:0], 1'b0};
            
            // Fourth pipeline stage
            stage3_poly <= stage3_xor ? POLY : 16'h0;
            stage3 <= stage3_shifted ^ stage3_poly;
            stage4_xor <= stage4[15] ^ data_pipeline[1];
            stage4_shifted <= {stage4[14:0], 1'b0};
            
            // Final result
            stage4_poly <= stage4_xor ? POLY : 16'h0;
            stage4 <= stage4_shifted ^ stage4_poly;
            crc_out <= {stage4[14:0], 1'b0} ^ ((stage4[15] ^ data_pipeline[0]) ? POLY : 16'h0);
        end
    end
endmodule