//SystemVerilog
module sync_multi_timer (
    input wire master_clk, slave_clk, reset, sync_en,
    output reg [31:0] master_count, slave_count,
    output wire synced
);
    // Control signals for synchronization
    reg sync_req;            // Synchronization request signal
    reg sync_ack;            // Synchronization acknowledgement signal
    reg [2:0] sync_shift;    // Shift register for clock domain crossing
    wire sync_detect;        // Edge detection signal
    
    //------------------------------------------------------------------
    // Master clock domain
    //------------------------------------------------------------------
    
    // Master counter incrementing logic
    always @(posedge master_clk or posedge reset) begin
        if (reset) begin
            master_count <= 32'h0;
        end
        else begin
            master_count <= master_count + 32'h1;
        end
    end
    
    // Sync request generation logic - activates when sync_en is high and counter[7:0] is zero
    always @(posedge master_clk or posedge reset) begin
        if (reset) begin
            sync_req <= 1'b0;
        end
        else begin
            sync_req <= sync_en & (master_count[7:0] == 8'h0);
        end
    end
    
    //------------------------------------------------------------------
    // Clock domain crossing logic (master to slave)
    //------------------------------------------------------------------
    
    // Synchronization shift register for safely crossing clock domains
    always @(posedge slave_clk or posedge reset) begin
        if (reset) begin
            sync_shift <= 3'b0;
        end
        else begin
            sync_shift <= {sync_shift[1:0], sync_req};
        end
    end
    
    // Edge detection for synchronization request
    assign sync_detect = ~sync_shift[2] & sync_shift[1];
    
    //------------------------------------------------------------------
    // Slave clock domain
    //------------------------------------------------------------------
    
    // Slave counter logic - resets on sync_detect, otherwise increments
    always @(posedge slave_clk or posedge reset) begin
        if (reset) begin
            slave_count <= 32'h0;
        end
        else if (sync_detect) begin
            slave_count <= 32'h0;
        end
        else begin
            slave_count <= slave_count + 32'h1;
        end
    end
    
    // Sync acknowledgement logic - signals when synchronization has occurred
    always @(posedge slave_clk or posedge reset) begin
        if (reset) begin
            sync_ack <= 1'b0;
        end
        else begin
            sync_ack <= sync_detect;
        end
    end
    
    // Output assignment - indicates synchronization status
    assign synced = sync_ack;
    
endmodule