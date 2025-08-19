//SystemVerilog IEEE 1364-2005
module pwm_timer #(
    parameter COUNTER_WIDTH = 12
)(
    input wire clk_i,
    input wire rst_n_i,
    input wire [COUNTER_WIDTH-1:0] period_i,
    input wire [COUNTER_WIDTH-1:0] duty_i,
    output wire pwm_o
);
    // Internal signals for module interconnection
    wire [COUNTER_WIDTH-1:0] counter_value;
    wire [COUNTER_WIDTH-1:0] period_stage1;
    wire [COUNTER_WIDTH-1:0] duty_stage1;
    wire counter_reset;
    wire compare_result;

    // Counter module instantiation
    pwm_counter #(
        .WIDTH(COUNTER_WIDTH)
    ) counter_unit (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .period_i(period_i),
        .duty_i(duty_i),
        .counter_o(counter_value),
        .period_o(period_stage1),
        .duty_o(duty_stage1),
        .counter_reset_o(counter_reset)
    );

    // Comparator module instantiation
    pwm_comparator #(
        .WIDTH(COUNTER_WIDTH)
    ) comparator_unit (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .counter_i(counter_value),
        .duty_i(duty_stage1),
        .period_i(period_stage1),
        .compare_result_o(compare_result)
    );

    // Output stage module instantiation
    pwm_output_stage output_unit (
        .clk_i(clk_i),
        .rst_n_i(rst_n_i),
        .compare_result_i(compare_result),
        .pwm_o(pwm_o)
    );
endmodule

//SystemVerilog IEEE 1364-2005
module pwm_counter #(
    parameter WIDTH = 12
)(
    input wire clk_i,
    input wire rst_n_i,
    input wire [WIDTH-1:0] period_i,
    input wire [WIDTH-1:0] duty_i,
    output reg [WIDTH-1:0] counter_o,
    output reg [WIDTH-1:0] period_o,
    output reg [WIDTH-1:0] duty_o,
    output reg counter_reset_o
);
    // First pipeline stage - Counter logic
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            counter_o <= {WIDTH{1'b0}};
            period_o <= {WIDTH{1'b0}};
            duty_o <= {WIDTH{1'b0}};
            counter_reset_o <= 1'b0;
        end else begin
            // Register inputs
            period_o <= period_i;
            duty_o <= duty_i;
            
            // Counter logic with reset
            if (counter_o >= period_o - 1'b1) begin
                counter_o <= {WIDTH{1'b0}};
                counter_reset_o <= 1'b1;
            end else begin
                counter_o <= counter_o + 1'b1;
                counter_reset_o <= 1'b0;
            end
        end
    end
endmodule

//SystemVerilog IEEE 1364-2005
module pwm_comparator #(
    parameter WIDTH = 12
)(
    input wire clk_i,
    input wire rst_n_i,
    input wire [WIDTH-1:0] counter_i,
    input wire [WIDTH-1:0] duty_i,
    input wire [WIDTH-1:0] period_i,
    output reg compare_result_o
);
    // Pipeline registers
    reg [WIDTH-1:0] period_stage2;
    reg [WIDTH-1:0] duty_stage2;
    
    // Second pipeline stage - Comparison logic
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            period_stage2 <= {WIDTH{1'b0}};
            duty_stage2 <= {WIDTH{1'b0}};
            compare_result_o <= 1'b0;
        end else begin
            // Pass values to next stage
            period_stage2 <= period_i;
            duty_stage2 <= duty_i;
            
            // Compare counter with duty cycle
            compare_result_o <= (counter_i < duty_i) ? 1'b1 : 1'b0;
        end
    end
endmodule

//SystemVerilog IEEE 1364-2005
module pwm_output_stage (
    input wire clk_i,
    input wire rst_n_i,
    input wire compare_result_i,
    output reg pwm_o
);
    // Third pipeline stage - Output logic
    always @(posedge clk_i) begin
        if (!rst_n_i) begin
            pwm_o <= 1'b0;
        end else begin
            // Final PWM output
            pwm_o <= compare_result_i;
        end
    end
endmodule