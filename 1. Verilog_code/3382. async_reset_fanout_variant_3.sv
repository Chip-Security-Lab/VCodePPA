//SystemVerilog
module async_reset_fanout (
    input  wire        clk,           // Clock input
    input  wire        async_rst_in,  // Asynchronous reset input
    output wire [15:0] rst_out        // Reset output bus
);
    // Reset synchronization pipeline stages
    reg  rst_sync_ff1;
    reg  rst_sync_ff2;
    
    // Intermediate fanout distribution registers
    reg  [3:0]  rst_fanout_level1;
    reg  [15:0] rst_fanout_level2;
    
    //--------------------------------------------------------------------------
    // Stage 1: Initial reset synchronization with 2 flip-flops
    //--------------------------------------------------------------------------
    always @(posedge clk or posedge async_rst_in) begin
        if (async_rst_in) begin
            rst_sync_ff1 <= 1'b1;
        end else begin
            rst_sync_ff1 <= 1'b0;
        end
    end
    
    always @(posedge clk or posedge async_rst_in) begin
        if (async_rst_in) begin
            rst_sync_ff2 <= 1'b1;
        end else begin
            rst_sync_ff2 <= rst_sync_ff1;
        end
    end
    
    //--------------------------------------------------------------------------
    // Stage 2: First level fanout - distribute to 4 separate reset domains
    //--------------------------------------------------------------------------
    always @(posedge clk or posedge async_rst_in) begin
        if (async_rst_in) begin
            rst_fanout_level1 <= 4'hF;
        end else begin
            // Distribute the synchronized reset to 4 domains to reduce loading
            rst_fanout_level1[0] <= rst_sync_ff2;
            rst_fanout_level1[1] <= rst_sync_ff2;
            rst_fanout_level1[2] <= rst_sync_ff2;
            rst_fanout_level1[3] <= rst_sync_ff2;
        end
    end
    
    //--------------------------------------------------------------------------
    // Stage 3: Second level fanout - expand to 16 reset outputs
    //--------------------------------------------------------------------------
    always @(posedge clk or posedge async_rst_in) begin
        if (async_rst_in) begin
            rst_fanout_level2 <= 16'hFFFF;
        end else begin
            // Each level1 reset drives 4 outputs to balance the fan-out tree
            rst_fanout_level2[3:0]   <= {4{rst_fanout_level1[0]}};
            rst_fanout_level2[7:4]   <= {4{rst_fanout_level1[1]}};
            rst_fanout_level2[11:8]  <= {4{rst_fanout_level1[2]}};
            rst_fanout_level2[15:12] <= {4{rst_fanout_level1[3]}};
        end
    end
    
    // Drive module outputs from the final fanout stage
    assign rst_out = rst_fanout_level2;

endmodule