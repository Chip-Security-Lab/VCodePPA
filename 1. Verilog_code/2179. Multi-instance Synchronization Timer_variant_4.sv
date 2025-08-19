//SystemVerilog
module sync_multi_timer (
    input wire master_clk, slave_clk, reset, sync_en,
    output reg [31:0] master_count, slave_count,
    output wire synced
);
    // Master clock domain signals
    reg sync_req_stage1, sync_req_stage2;
    reg [31:0] master_count_stage1, master_count_stage2;
    wire [31:0] master_count_next;
    
    // Slave clock domain signals
    reg [3:0] sync_shift;
    reg sync_ack_stage1, sync_ack_stage2;
    reg [31:0] slave_count_stage1, slave_count_stage2;
    wire [31:0] slave_count_next;
    wire sync_edge_detected;
    
    // Master clock domain implementation - reduced pipeline
    // Compute all 32 bits in a single stage
    assign master_count_next = master_count_stage1 + 32'h1;
    
    always @(posedge master_clk) begin
        if (reset) begin
            // Reset stage 1
            master_count_stage1 <= 32'h0;
            sync_req_stage1 <= 1'b0;
        end
        else begin
            // Stage 1 processing - compute full counter
            master_count_stage1 <= master_count_next;
            sync_req_stage1 <= sync_en & (master_count_next[7:0] == 8'h0);
        end
    end
    
    always @(posedge master_clk) begin
        if (reset) begin
            // Reset stage 2
            master_count_stage2 <= 32'h0;
            sync_req_stage2 <= 1'b0;
            master_count <= 32'h0;
        end
        else begin
            // Stage 2 processing
            master_count_stage2 <= master_count_stage1;
            sync_req_stage2 <= sync_req_stage1;
            master_count <= master_count_stage1;
        end
    end
    
    // Slave clock domain implementation - reduced pipeline
    
    // Synchronization logic with fewer stages
    always @(posedge slave_clk) begin
        if (reset) 
            sync_shift <= 4'b0;
        else 
            sync_shift <= {sync_shift[2:0], sync_req_stage2};
    end
    
    // Edge detection for sync signal
    assign sync_edge_detected = ~sync_shift[1] & sync_shift[0];
    
    // Compute all 32 bits in a single stage
    assign slave_count_next = sync_edge_detected ? 32'h0 : slave_count_stage1 + 32'h1;
    
    always @(posedge slave_clk) begin
        if (reset) begin
            // Reset stage 1
            slave_count_stage1 <= 32'h0;
            sync_ack_stage1 <= 1'b0;
        end
        else begin
            // Stage 1 processing - compute full counter
            slave_count_stage1 <= slave_count_next;
            sync_ack_stage1 <= sync_edge_detected;
        end
    end
    
    always @(posedge slave_clk) begin
        if (reset) begin
            // Reset stage 2
            slave_count_stage2 <= 32'h0;
            sync_ack_stage2 <= 1'b0;
            slave_count <= 32'h0;
        end
        else begin
            // Stage 2 processing
            slave_count_stage2 <= slave_count_stage1;
            sync_ack_stage2 <= sync_ack_stage1;
            slave_count <= slave_count_stage1;
        end
    end
    
    assign synced = sync_ack_stage2;
endmodule