//SystemVerilog
module eth_addr_checker (
    input wire clk,
    input wire reset_n,
    input wire [47:0] mac_addr,
    input wire [47:0] received_addr,
    input wire addr_valid,
    output reg addr_match,
    output reg broadcast_detected,
    output reg multicast_detected
);
    // Combinational logic outputs directly connected from inputs
    wire addr_match_comb = (mac_addr == received_addr) && addr_valid;
    wire broadcast_detected_comb = &received_addr && addr_valid;
    wire multicast_detected_comb = received_addr[0] && addr_valid;
    
    // Pipeline stage 1 - moved after combinational logic
    reg addr_match_stage1;
    reg broadcast_detected_stage1;
    reg multicast_detected_stage1;
    reg addr_valid_stage1;
    
    // Stage 1: Register combinational logic results
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            addr_match_stage1 <= 1'b0;
            broadcast_detected_stage1 <= 1'b0;
            multicast_detected_stage1 <= 1'b0;
            addr_valid_stage1 <= 1'b0;
        end else begin
            addr_match_stage1 <= addr_match_comb;
            broadcast_detected_stage1 <= broadcast_detected_comb;
            multicast_detected_stage1 <= multicast_detected_comb;
            addr_valid_stage1 <= addr_valid;
        end
    end
    
    // Stage 2: Pipeline stage for timing balancing
    reg addr_match_stage2;
    reg broadcast_detected_stage2;
    reg multicast_detected_stage2;
    reg addr_valid_stage2;
    
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            addr_match_stage2 <= 1'b0;
            broadcast_detected_stage2 <= 1'b0;
            multicast_detected_stage2 <= 1'b0;
            addr_valid_stage2 <= 1'b0;
        end else begin
            addr_match_stage2 <= addr_match_stage1;
            broadcast_detected_stage2 <= broadcast_detected_stage1;
            multicast_detected_stage2 <= multicast_detected_stage1;
            addr_valid_stage2 <= addr_valid_stage1;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            addr_match <= 1'b0;
            broadcast_detected <= 1'b0;
            multicast_detected <= 1'b0;
        end else begin
            addr_match <= addr_match_stage2;
            broadcast_detected <= broadcast_detected_stage2;
            multicast_detected <= multicast_detected_stage2;
        end
    end
endmodule