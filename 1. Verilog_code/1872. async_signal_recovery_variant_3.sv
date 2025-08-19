//SystemVerilog
module async_signal_recovery (
    input wire clk,
    input wire rst_n,
    input wire [7:0] noisy_input,
    input wire signal_present,
    output reg [7:0] recovered_signal
);

    // Pipeline stage 1: Input conditioning
    reg [7:0] input_stage;
    reg signal_present_stage;
    
    // Pipeline stage 2: Signal filtering
    reg [7:0] filtered_signal;
    
    // Pipeline stage 3: Threshold comparison
    reg [7:0] threshold_result;
    
    // Stage 1: Input conditioning
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_stage <= 8'b0;
            signal_present_stage <= 1'b0;
        end else begin
            input_stage <= noisy_input;
            signal_present_stage <= signal_present;
        end
    end
    
    // Stage 2: Signal filtering
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            filtered_signal <= 8'b0;
        end else begin
            filtered_signal <= signal_present_stage ? input_stage : 8'b0;
        end
    end
    
    // Stage 3: Threshold comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            threshold_result <= 8'b0;
        end else begin
            threshold_result <= (filtered_signal > 8'd128) ? 8'hFF : 8'h00;
        end
    end
    
    // Output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            recovered_signal <= 8'b0;
        end else begin
            recovered_signal <= threshold_result;
        end
    end

endmodule