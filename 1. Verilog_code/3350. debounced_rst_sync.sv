module debounced_rst_sync #(
    parameter DEBOUNCE_LEN = 8
)(
    input  wire clk,
    input  wire noisy_rst_n,
    output reg  clean_rst_n
);
    reg [1:0] sync_flops;
    reg [3:0] debounce_counter;
    
    always @(posedge clk) begin
        sync_flops <= {sync_flops[0], noisy_rst_n};
        
        if (sync_flops[1] == 1'b0) begin
            if (debounce_counter < DEBOUNCE_LEN-1)
                debounce_counter <= debounce_counter + 1;
            else
                clean_rst_n <= 1'b0;
        end else begin
            debounce_counter <= 0;
            clean_rst_n <= 1'b1;
        end
    end
endmodule