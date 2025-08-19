//SystemVerilog
module BurstModeRecovery #(parameter SYNC_WORD=64'hA5A5_5A5A_A5A5_5A5A) (
    input clk,
    input reset,
    input [63:0] rx_data,
    output reg [7:0] payload,
    output reg sync_detect
);
    // Pipeline stage 1 registers
    reg [63:0] rx_data_stage1;
    reg sync_detect_stage1;
    
    // Pipeline stage 2 registers
    reg [7:0] payload_stage2;
    reg sync_detect_stage2;
    reg [3:0] match_counter_stage2;
    
    // Pipeline stage 3 registers
    reg [7:0] payload_stage3;
    reg sync_detect_stage3;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset all stages
            rx_data_stage1 <= 64'h0;
            sync_detect_stage1 <= 1'b0;
            payload_stage2 <= 8'h00;
            sync_detect_stage2 <= 1'b0;
            match_counter_stage2 <= 4'h0;
            payload_stage3 <= 8'h00;
            sync_detect_stage3 <= 1'b0;
            payload <= 8'h00;
            sync_detect <= 1'b0;
        end else begin
            // Stage 1: Sync detection using parallel comparison
            rx_data_stage1 <= rx_data;
            sync_detect_stage1 <= &(rx_data ^~ SYNC_WORD);
            
            // Stage 2: Payload selection and counter update
            payload_stage2 <= sync_detect_stage1 ? rx_data_stage1[7:0] : 8'h00;
            sync_detect_stage2 <= sync_detect_stage1;
            match_counter_stage2 <= sync_detect_stage1 ? 4'd8 : 
                                  (|match_counter_stage2 ? match_counter_stage2 - 1'b1 : 4'b0);
            
            // Stage 3: Output generation
            payload_stage3 <= payload_stage2;
            sync_detect_stage3 <= sync_detect_stage2;
            
            // Outputs
            payload <= payload_stage3;
            sync_detect <= sync_detect_stage3;
        end
    end
endmodule