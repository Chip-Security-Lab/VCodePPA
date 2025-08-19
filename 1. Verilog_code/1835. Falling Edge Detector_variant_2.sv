//SystemVerilog
module falling_edge_detector (
    input  wire clock,
    input  wire async_reset,
    input  wire signal_input,
    output reg  edge_out,
    output reg  auto_reset_out
);

    // Pipeline stage 1: Input synchronization
    reg signal_sync;
    reg signal_delayed;
    
    // Pipeline stage 2: Edge detection
    reg edge_detected;
    
    // Pipeline stage 3: Auto-reset control
    reg [3:0] auto_reset_counter;
    reg auto_reset_active;

    // Input synchronization - first stage
    always @(posedge clock or posedge async_reset) begin
        if (async_reset) begin
            signal_sync <= 1'b0;
        end else begin
            signal_sync <= signal_input;
        end
    end

    // Input synchronization - second stage
    always @(posedge clock or posedge async_reset) begin
        if (async_reset) begin
            signal_delayed <= 1'b0;
        end else begin
            signal_delayed <= signal_sync;
        end
    end

    // Edge detection logic
    always @(posedge clock or posedge async_reset) begin
        if (async_reset) begin
            edge_detected <= 1'b0;
        end else begin
            edge_detected <= ~signal_sync & signal_delayed;
        end
    end

    // Auto-reset counter control
    always @(posedge clock or posedge async_reset) begin
        if (async_reset) begin
            auto_reset_counter <= 4'b0;
        end else if (edge_detected) begin
            auto_reset_counter <= 4'b1111;
        end else if (|auto_reset_counter) begin
            auto_reset_counter <= auto_reset_counter - 1'b1;
        end
    end

    // Auto-reset active control
    always @(posedge clock or posedge async_reset) begin
        if (async_reset) begin
            auto_reset_active <= 1'b0;
        end else if (edge_detected) begin
            auto_reset_active <= 1'b1;
        end else if (!(|auto_reset_counter)) begin
            auto_reset_active <= 1'b0;
        end
    end

    // Edge output control
    always @(posedge clock or posedge async_reset) begin
        if (async_reset) begin
            edge_out <= 1'b0;
        end else begin
            edge_out <= edge_detected;
        end
    end

    // Auto-reset output control
    always @(posedge clock or posedge async_reset) begin
        if (async_reset) begin
            auto_reset_out <= 1'b0;
        end else begin
            auto_reset_out <= auto_reset_active;
        end
    end

endmodule