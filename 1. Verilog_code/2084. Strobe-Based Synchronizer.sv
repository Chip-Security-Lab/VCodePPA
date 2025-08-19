module strobe_sync (
    input wire clk_a, clk_b, reset,
    input wire data_a,
    input wire strobe_a,
    output reg data_b,
    output reg strobe_b
);
    reg data_a_captured;
    reg toggle_a, toggle_a_meta, toggle_a_sync, toggle_a_delay;
    
    // Source domain
    always @(posedge clk_a) begin
        if (reset) begin
            data_a_captured <= 1'b0;
            toggle_a <= 1'b0;
        end else if (strobe_a) begin
            data_a_captured <= data_a;
            toggle_a <= ~toggle_a;
        end
    end
    
    // Destination domain
    always @(posedge clk_b) begin
        if (reset) begin
            toggle_a_meta <= 1'b0;
            toggle_a_sync <= 1'b0;
            toggle_a_delay <= 1'b0;
            data_b <= 1'b0;
            strobe_b <= 1'b0;
        end else begin
            toggle_a_meta <= toggle_a;
            toggle_a_sync <= toggle_a_meta;
            toggle_a_delay <= toggle_a_sync;
            
            strobe_b <= toggle_a_sync ^ toggle_a_delay;
            if (toggle_a_sync ^ toggle_a_delay)
                data_b <= data_a_captured;
        end
    end
endmodule