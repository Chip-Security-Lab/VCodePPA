//SystemVerilog
module debounce_recovery (
    input wire clk,
    input wire rst_n,
    input wire noisy_signal,
    output reg clean_signal
);
    reg sync_1, sync_2;
    reg sync_2_stage1;
    reg signal_changed_stage2;
    reg [15:0] count_stage2;
    reg clean_signal_stage2;
    reg [15:0] count_stage3;
    reg clean_signal_stage3;
    reg clean_signal_stage4;
    
    // Stage 1: Synchronization
    always @(posedge clk) begin
        sync_1 <= noisy_signal;
        sync_2 <= sync_1;
        sync_2_stage1 <= sync_2;
    end
    
    // Stage 2: Change detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_changed_stage2 <= 1'b0;
            count_stage2 <= 16'h0000;
            clean_signal_stage2 <= 1'b0;
        end else begin
            signal_changed_stage2 <= (sync_2_stage1 != clean_signal_stage4);
            clean_signal_stage2 <= clean_signal_stage4;
            if (sync_2_stage1 == clean_signal_stage4)
                count_stage2 <= 16'h0000;
            else
                count_stage2 <= count_stage3;
        end
    end
    
    // Stage 3: Counter logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_stage3 <= 16'h0000;
            clean_signal_stage3 <= 1'b0;
        end else begin
            if (signal_changed_stage2) begin
                count_stage3 <= count_stage2 + 16'h0001;
                if (count_stage2 == 16'hFFFF) begin
                    clean_signal_stage3 <= sync_2_stage1;
                    count_stage3 <= 16'h0000;
                end else begin
                    clean_signal_stage3 <= clean_signal_stage2;
                end
            end else begin
                count_stage3 <= 16'h0000;
                clean_signal_stage3 <= clean_signal_stage2;
            end
        end
    end
    
    // Stage 4: Output update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clean_signal_stage4 <= 1'b0;
        end else begin
            clean_signal_stage4 <= clean_signal_stage3;
        end
    end
    
    // Final output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clean_signal <= 1'b0;
        end else begin
            clean_signal <= clean_signal_stage4;
        end
    end
endmodule