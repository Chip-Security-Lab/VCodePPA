module reset_stretch_sync #(
    parameter STRETCH_COUNT = 4
)(
    input  wire clk,
    input  wire async_rst_n,
    output reg  sync_rst_n
);
    reg meta;
    reg [2:0] stretch_counter;
    reg reset_detected;
    
    always @(posedge clk or negedge async_rst_n) begin
        if (!async_rst_n) begin
            meta <= 1'b0;
            reset_detected <= 1'b1;
            stretch_counter <= 0;
            sync_rst_n <= 1'b0;
        end else begin
            meta <= 1'b1;
            
            if (reset_detected) begin
                if (stretch_counter < STRETCH_COUNT - 1) begin
                    stretch_counter <= stretch_counter + 1;
                    sync_rst_n <= 1'b0;
                end else begin
                    reset_detected <= 1'b0;
                    sync_rst_n <= 1'b1;
                end
            end else begin
                sync_rst_n <= meta;
            end
        end
    end
endmodule