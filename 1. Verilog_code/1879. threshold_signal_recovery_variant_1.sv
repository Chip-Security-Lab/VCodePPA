//SystemVerilog
module threshold_signal_recovery (
    input wire system_clk,
    input wire rst_n,
    input wire valid_in,
    input wire [9:0] analog_value,
    input wire [9:0] upper_threshold,
    input wire [9:0] lower_threshold,
    output reg valid_out,
    output reg signal_detected,
    output reg [9:0] recovered_value
);

    // Stage 1 registers
    reg [9:0] analog_value_stage1;
    reg [9:0] upper_threshold_stage1;
    reg [9:0] lower_threshold_stage1;
    reg valid_stage1;
    
    // Stage 2 registers
    reg upper_compare_stage2;
    reg lower_compare_stage2;
    reg [9:0] analog_value_stage2;
    reg valid_stage2;

    // Pipeline stage 1: Register inputs and perform comparisons
    always @(posedge system_clk or negedge rst_n) begin
        if (!rst_n) begin
            analog_value_stage1 <= 10'h0;
            upper_threshold_stage1 <= 10'h0;
            lower_threshold_stage1 <= 10'h0;
            valid_stage1 <= 1'b0;
        end else begin
            analog_value_stage1 <= analog_value;
            upper_threshold_stage1 <= upper_threshold;
            lower_threshold_stage1 <= lower_threshold;
            valid_stage1 <= valid_in;
        end
    end

    // Pipeline stage 2: Store comparison results
    always @(posedge system_clk or negedge rst_n) begin
        if (!rst_n) begin
            upper_compare_stage2 <= 1'b0;
            lower_compare_stage2 <= 1'b0;
            analog_value_stage2 <= 10'h0;
            valid_stage2 <= 1'b0;
        end else begin
            upper_compare_stage2 <= analog_value_stage1 >= upper_threshold_stage1;
            lower_compare_stage2 <= analog_value_stage1 <= lower_threshold_stage1;
            analog_value_stage2 <= analog_value_stage1;
            valid_stage2 <= valid_stage1;
        end
    end

    // Pipeline stage 3: Generate outputs
    always @(posedge system_clk or negedge rst_n) begin
        if (!rst_n) begin
            signal_detected <= 1'b0;
            recovered_value <= 10'h0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_stage2;
            
            if (upper_compare_stage2) begin
                signal_detected <= 1'b1;
                recovered_value <= 10'h3FF;
            end else if (lower_compare_stage2) begin
                signal_detected <= 1'b1;
                recovered_value <= 10'h000;
            end else begin
                signal_detected <= 1'b0;
                recovered_value <= analog_value_stage2;
            end
        end
    end
endmodule