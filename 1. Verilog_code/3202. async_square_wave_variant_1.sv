//SystemVerilog
module async_square_wave #(
    parameter CNT_WIDTH = 10
)(
    input wire clock,
    input wire reset,
    input wire [CNT_WIDTH-1:0] max_count,
    input wire [CNT_WIDTH-1:0] duty_cycle,
    output wire wave_out
);
    // Pipeline stage 1 registers
    reg [CNT_WIDTH-1:0] counter_stage1;
    reg [CNT_WIDTH-1:0] max_count_stage1;
    reg [CNT_WIDTH-1:0] duty_cycle_stage1;
    reg valid_stage1;
    
    // Pipeline stage 2 registers
    reg [CNT_WIDTH-1:0] counter_stage2;
    reg [CNT_WIDTH-1:0] duty_cycle_stage2;
    reg valid_stage2;
    reg reset_counter_stage2;
    
    // Pipeline stage 3 registers
    reg comparison_result_stage3;
    reg valid_stage3;
    
    // Stage 1: Input registration
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            max_count_stage1 <= {CNT_WIDTH{1'b0}};
            duty_cycle_stage1 <= {CNT_WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            max_count_stage1 <= max_count;
            duty_cycle_stage1 <= duty_cycle;
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 2: Counter logic and progression
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            counter_stage1 <= {CNT_WIDTH{1'b0}};
            counter_stage2 <= {CNT_WIDTH{1'b0}};
            duty_cycle_stage2 <= {CNT_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
            reset_counter_stage2 <= 1'b0;
        end else begin
            if (counter_stage1 >= max_count_stage1)
                counter_stage1 <= {CNT_WIDTH{1'b0}};
            else
                counter_stage1 <= counter_stage1 + 1'b1;
                
            counter_stage2 <= counter_stage1;
            duty_cycle_stage2 <= duty_cycle_stage1;
            valid_stage2 <= valid_stage1;
            reset_counter_stage2 <= (counter_stage1 >= max_count_stage1);
        end
    end
    
    // Stage 3: Output comparison
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            comparison_result_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else begin
            comparison_result_stage3 <= (counter_stage2 < duty_cycle_stage2) ? 1'b1 : 1'b0;
            valid_stage3 <= valid_stage2;
        end
    end
    
    // Output assignment
    assign wave_out = valid_stage3 ? comparison_result_stage3 : 1'b0;
    
endmodule