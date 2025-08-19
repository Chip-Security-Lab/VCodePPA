//SystemVerilog
module debounce_recovery (
    input wire clk,
    input wire rst_n,
    input wire noisy_signal,
    output reg clean_signal
);
    reg [15:0] count;
    reg sync_1, sync_2;
    wire signal_changed;
    wire count_max;
    
    // Synchronization flip-flops
    always @(posedge clk) begin
        sync_1 <= noisy_signal;
        sync_2 <= sync_1;
    end
    
    // Precompute conditions
    assign signal_changed = (sync_2 != clean_signal);
    assign count_max = (count == 16'hFFFF);
    
    // Debounce logic with balanced paths
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 16'h0000;
            clean_signal <= 1'b0;
        end else begin
            if (signal_changed) begin
                count <= count + 16'h0001;
                if (count_max) begin
                    clean_signal <= sync_2;
                    count <= 16'h0000;
                end
            end else begin
                count <= 16'h0000;
            end
        end
    end
endmodule