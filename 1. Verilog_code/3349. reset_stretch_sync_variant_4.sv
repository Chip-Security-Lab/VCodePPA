//SystemVerilog
module reset_stretch_sync #(
    parameter STRETCH_COUNT = 4
)(
    input  wire clk,
    input  wire async_rst_n,
    output reg  sync_rst_n
);

    reg meta_sync_ff;
    reg [2:0] stretch_counter;
    reg stretch_active;

    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            meta_sync_ff     <= 1'b0;
            stretch_counter  <= 3'd0;
            stretch_active   <= 1'b1;
            sync_rst_n       <= 1'b0;
        end else begin
            // Synchronizer for the reset
            meta_sync_ff <= 1'b1;

            // Stretch counter and active control
            if (stretch_active) begin
                if (stretch_counter != (STRETCH_COUNT - 1)) begin
                    stretch_counter <= stretch_counter + 1'b1;
                end
                if (stretch_counter == (STRETCH_COUNT - 1)) begin
                    stretch_active <= 1'b0;
                end
            end

            // Output reset synchronizer logic
            sync_rst_n <= stretch_active ? 1'b0 : meta_sync_ff;
        end
    end

endmodule