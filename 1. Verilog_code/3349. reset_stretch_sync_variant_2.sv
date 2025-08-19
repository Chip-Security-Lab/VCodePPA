//SystemVerilog
// SystemVerilog
module reset_stretch_sync #(
    parameter STRETCH_COUNT = 4
)(
    input  wire clk,
    input  wire async_rst_n,
    output reg  sync_rst_n
);

    // Double-flop synchronization registers for metastability protection
    reg meta_ff1;
    reg meta_ff2;

    // Buffer for high-fanout signal 'b0'
    reg b0_buf1;
    reg b0_buf2;
    wire b0;

    // Stretch counter and reset detection
    reg [2:0] stretch_counter;
    reg reset_detected;

    // Assign synchronized reset signal
    assign b0 = meta_ff2;

    ///////////////////////////////////////////////////////////////////////////////
    // 1. Synchronize async_rst_n using double-flop (metastability protection)
    ///////////////////////////////////////////////////////////////////////////////
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            meta_ff1 <= 1'b0;
            meta_ff2 <= 1'b0;
        end else begin
            meta_ff1 <= 1'b1;
            meta_ff2 <= meta_ff1;
        end
    end

    ///////////////////////////////////////////////////////////////////////////////
    // 2. Buffer for high-fanout signal 'b0'
    ///////////////////////////////////////////////////////////////////////////////
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            b0_buf1 <= 1'b0;
            b0_buf2 <= 1'b0;
        end else begin
            b0_buf1 <= b0;
            b0_buf2 <= b0_buf1;
        end
    end

    ///////////////////////////////////////////////////////////////////////////////
    // 3. Reset detection and stretch counter control
    //    - Handles reset_detected and stretch_counter only
    ///////////////////////////////////////////////////////////////////////////////
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            stretch_counter <= 3'b0;
            reset_detected <= 1'b1;
        end else if (reset_detected) begin
            if (stretch_counter < STRETCH_COUNT - 1) begin
                stretch_counter <= stretch_counter + 1;
            end else begin
                reset_detected <= 1'b0;
            end
        end
    end

    ///////////////////////////////////////////////////////////////////////////////
    // 4. Synchronous reset output control
    //    - Handles sync_rst_n output only
    ///////////////////////////////////////////////////////////////////////////////
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            sync_rst_n <= 1'b0;
        end else if (reset_detected) begin
            sync_rst_n <= 1'b0;
        end else begin
            sync_rst_n <= b0_buf2;
        end
    end

endmodule