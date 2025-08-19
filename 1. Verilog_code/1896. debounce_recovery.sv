module debounce_recovery (
    input wire clk,
    input wire rst_n,
    input wire noisy_signal,
    output reg clean_signal
);
    reg [15:0] count;
    reg sync_1, sync_2;
    
    // Two flip-flops for synchronization
    always @(posedge clk) begin
        sync_1 <= noisy_signal;
        sync_2 <= sync_1;
    end
    
    // Debounce logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 16'h0000;
            clean_signal <= 1'b0;
        end else begin
            if (sync_2 != clean_signal) begin
                // Signal changed, start counter
                count <= count + 16'h0001;
                if (count == 16'hFFFF) begin
                    clean_signal <= sync_2;
                    count <= 16'h0000;
                end
            end else begin
                // Signal stable, reset counter
                count <= 16'h0000;
            end
        end
    end
endmodule