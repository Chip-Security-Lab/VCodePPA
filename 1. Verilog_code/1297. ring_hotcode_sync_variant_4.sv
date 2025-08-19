//SystemVerilog
// Top-level module - ring hot code counter with synchronous reset
module ring_hotcode_sync (
    input  wire       clock,     // System clock
    input  wire       sync_rst,  // Synchronous reset
    output wire [3:0] cnt_reg    // Hot code counter output
);

    // Instance of the counter core module
    ring_counter_core counter_inst (
        .clock    (clock),
        .sync_rst (sync_rst),
        .cnt_out  (cnt_reg)
    );

endmodule

// Core counter module - implements the ring counter functionality
module ring_counter_core (
    input  wire       clock,    // System clock
    input  wire       sync_rst, // Synchronous reset
    output wire [3:0] cnt_out   // Hot code counter output - changed from reg to wire
);

    // Internal counter register
    reg [3:0] cnt_internal;
    
    // Intermediate buffered outputs to reduce fanout
    reg [3:0] cnt_buf1;
    reg [3:0] cnt_buf2;
    
    // Counter state update logic
    always @(posedge clock) begin
        if (sync_rst)
            cnt_internal <= 4'b0001;  // Reset to initial state (hot code starting position)
        else
            cnt_internal <= {cnt_internal[0], cnt_internal[3:1]};  // Rotate bits right
    end
    
    // First level buffer register to reduce fanout
    always @(posedge clock) begin
        cnt_buf1 <= cnt_internal;
    end
    
    // Second level buffer register for further fanout reduction
    always @(posedge clock) begin
        cnt_buf2 <= cnt_buf1;
    end
    
    // Output assignment - balanced load between buffers
    assign cnt_out[0] = cnt_buf1[0];
    assign cnt_out[1] = cnt_buf1[1];
    assign cnt_out[2] = cnt_buf2[2];
    assign cnt_out[3] = cnt_buf2[3];

endmodule