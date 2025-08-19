//SystemVerilog
module async_signal_recovery (
    input wire clk,
    input wire rst_n,
    input wire [7:0] noisy_input,
    input wire signal_present,
    output reg [7:0] recovered_signal
);

    // Pipeline stage 1: Input conditioning
    reg [7:0] input_stage1;
    reg signal_present_stage1;
    
    // Pipeline stage 2: Signal filtering
    reg [7:0] filtered_signal_stage2;
    reg signal_present_stage2;
    
    // Pipeline stage 3: Signal processing
    reg [7:0] processed_signal_stage3;
    reg [7:0] threshold_value_stage3;
    
    // Pipeline stage 4: Threshold comparison
    reg [7:0] threshold_result_stage4;
    
    // Stage 1: Input conditioning
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_stage1 <= 8'b0;
            signal_present_stage1 <= 1'b0;
        end else begin
            input_stage1 <= noisy_input;
            signal_present_stage1 <= signal_present;
        end
    end
    
    // Stage 2: Signal filtering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            filtered_signal_stage2 <= 8'b0;
            signal_present_stage2 <= 1'b0;
        end else begin
            filtered_signal_stage2 <= signal_present_stage1 ? input_stage1 : 8'b0;
            signal_present_stage2 <= signal_present_stage1;
        end
    end
    
    // Stage 3: Signal processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            processed_signal_stage3 <= 8'b0;
            threshold_value_stage3 <= 8'd128;
        end else begin
            processed_signal_stage3 <= filtered_signal_stage2;
            threshold_value_stage3 <= 8'd128;
        end
    end
    
    // Stage 4: Threshold comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            threshold_result_stage4 <= 8'b0;
        end else begin
            threshold_result_stage4 <= (processed_signal_stage3 > threshold_value_stage3) ? 8'hFF : 8'h00;
        end
    end
    
    // Final output assignment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recovered_signal <= 8'b0;
        end else begin
            recovered_signal <= threshold_result_stage4;
        end
    end

endmodule