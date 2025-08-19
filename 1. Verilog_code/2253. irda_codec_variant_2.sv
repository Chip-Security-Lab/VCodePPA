//SystemVerilog
module irda_codec #(parameter DIV=16) (
    input wire clk,
    input wire rst_n,
    input wire din,
    input wire valid_in,
    output reg dout,
    output reg valid_out
);
    // Pipeline stage 1 signals
    reg [7:0] pulse_cnt_stage1;
    reg din_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 signals
    reg [7:0] pulse_cnt_stage2;
    reg din_stage2;
    reg valid_stage2;
    
    // Pipeline stage 3 signals
    reg [7:0] pulse_cnt_stage3;
    reg din_stage3;
    reg valid_stage3;
    
    // Pipeline registers for Newton-Raphson calculation
    reg [7:0] denominator_r1, numerator_r1;
    reg [15:0] x_0_r1, x_0_r2;
    reg [15:0] temp_r1, temp_r2;
    reg [15:0] two_minus_d_x_r1;
    reg [15:0] x_1_r1;
    reg [7:0] nr_result_r1;
    
    // Division threshold
    reg [7:0] div_threshold;
    
    // Pipelined Newton-Raphson division calculation
    // Breaking the critical path of complex calculations
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            denominator_r1 <= 8'd0;
            numerator_r1 <= 8'd0;
            x_0_r1 <= 16'd0;
            x_0_r2 <= 16'd0;
            temp_r1 <= 16'd0;
            temp_r2 <= 16'd0;
            two_minus_d_x_r1 <= 16'd0;
            x_1_r1 <= 16'd0;
            nr_result_r1 <= 8'd0;
            div_threshold <= 8'd3; // Default value during reset
        end else if (rst_n && div_threshold == 8'd0) begin
            // Pipeline stage 1: Initial calculation
            denominator_r1 <= 8'd16;  // Fixed denominator for DIV
            numerator_r1 <= 8'd3;     // Fixed numerator for DIV*3/16
            x_0_r1 <= 16'h300 / (16'h20 + 16'd16); // Initial approximation
            
            // Pipeline stage 2: First iteration part 1
            temp_r1 <= denominator_r1 * x_0_r1;
            x_0_r2 <= x_0_r1;
            
            // Pipeline stage 3: First iteration part 2
            temp_r2 <= temp_r1;
            two_minus_d_x_r1 <= 16'h200 - temp_r1;
            
            // Pipeline stage 4: Calculate final approximation
            x_1_r1 <= (x_0_r2 * two_minus_d_x_r1) >> 8;
            
            // Pipeline stage 5: Final result
            nr_result_r1 <= (numerator_r1 * x_1_r1[7:0]) >> 8;
            div_threshold <= nr_result_r1;
        end
    end

    // Stage 1: Counter increment and threshold detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_cnt_stage1 <= 8'd0;
            din_stage1 <= 1'b1;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= valid_in;
            din_stage1 <= din;
            
            if (valid_in) begin
                if (pulse_cnt_stage1 == DIV) begin
                    pulse_cnt_stage1 <= 8'd0;
                end else begin
                    pulse_cnt_stage1 <= pulse_cnt_stage1 + 1'b1;
                end
            end
        end
    end
    
    // Stage 2: Determine threshold conditions
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_cnt_stage2 <= 8'd0;
            din_stage2 <= 1'b1;
            valid_stage2 <= 1'b0;
        end else begin
            pulse_cnt_stage2 <= pulse_cnt_stage1;
            din_stage2 <= din_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Final output generation
    // Split the complex output logic into two pipeline stages
    reg output_condition_met;
    reg is_div_threshold;
    reg is_div_max;
    reg output_value;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pulse_cnt_stage3 <= 8'd0;
            din_stage3 <= 1'b1;
            valid_stage3 <= 1'b0;
            
            // Intermediate decision logic registers
            output_condition_met <= 1'b0;
            is_div_threshold <= 1'b0;
            is_div_max <= 1'b0;
            output_value <= 1'b1;
            
            dout <= 1'b1;
            valid_out <= 1'b0;
        end else begin
            pulse_cnt_stage3 <= pulse_cnt_stage2;
            din_stage3 <= din_stage2;
            valid_stage3 <= valid_stage2;
            
            // First part of output stage: evaluate conditions
            is_div_threshold <= (pulse_cnt_stage3 == div_threshold);
            is_div_max <= (pulse_cnt_stage3 == DIV);
            output_condition_met <= valid_stage3;
            
            // Second part of output stage: determine output value
            if (is_div_threshold) begin
                output_value <= !din_stage3;
            end else if (is_div_max) begin
                output_value <= 1'b1;
            end
            
            // Final output stage
            valid_out <= output_condition_met;
            if (output_condition_met) begin
                dout <= output_value;
            end
        end
    end
endmodule