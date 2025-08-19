//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
// Design Name: Reset Synchronizer with Acknowledgment
// Module Name: rst_sync_with_ack
// Description: Top-level module for reset synchronization with acknowledgment
//              (IEEE 1364-2005 Verilog standard)
///////////////////////////////////////////////////////////////////////////////
module rst_sync_with_ack (
    input  wire clk,          // System clock
    input  wire async_rst_n,  // Asynchronous reset (active low)
    input  wire ack_reset,    // Reset acknowledgment signal
    output wire sync_rst_n,   // Synchronized reset (active low)
    output wire rst_active    // Reset active indicator
);

    // Internal connections
    wire sync_rst_n_int;

    // Reset synchronizer module instantiation
    rst_synchronizer u_rst_synchronizer (
        .clk          (clk),
        .async_rst_n  (async_rst_n),
        .sync_rst_n   (sync_rst_n_int)
    );

    // Reset acknowledgment handler module instantiation
    rst_ack_handler u_rst_ack_handler (
        .clk          (clk),
        .async_rst_n  (async_rst_n),
        .sync_rst_n   (sync_rst_n_int),
        .ack_reset    (ack_reset),
        .rst_active   (rst_active)
    );

    // Connect synchronizer output to top-level output
    assign sync_rst_n = sync_rst_n_int;

endmodule

///////////////////////////////////////////////////////////////////////////////
// Module Name: rst_synchronizer
// Description: Synchronizes asynchronous reset to clock domain
///////////////////////////////////////////////////////////////////////////////
module rst_synchronizer (
    input  wire clk,          // System clock
    input  wire async_rst_n,  // Asynchronous reset (active low)
    output reg  sync_rst_n    // Synchronized reset (active low)
);

    // Metastability protection register
    reg meta_stage;

    // Reset handling for first synchronizer stage
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            meta_stage <= 1'b0;
        end else begin
            meta_stage <= 1'b1;
        end
    end

    // Reset handling for second synchronizer stage
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            sync_rst_n <= 1'b0;
        end else begin
            sync_rst_n <= meta_stage;
        end
    end

endmodule

///////////////////////////////////////////////////////////////////////////////
// Module Name: rst_ack_handler
// Description: Handles reset acknowledgment and active status
///////////////////////////////////////////////////////////////////////////////
module rst_ack_handler (
    input  wire clk,          // System clock
    input  wire async_rst_n,  // Asynchronous reset (active low)
    input  wire sync_rst_n,   // Synchronized reset (active low)
    input  wire ack_reset,    // Reset acknowledgment signal
    output reg  rst_active    // Reset active indicator
);

    // Reset assertion logic
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            rst_active <= 1'b1;
        end else if (!sync_rst_n) begin
            rst_active <= 1'b1;
        end
    end
    
    // Reset acknowledgment logic
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            // Do nothing on async reset - handled by other always block
        end else if (ack_reset) begin
            rst_active <= 1'b0;
        end
    end

endmodule