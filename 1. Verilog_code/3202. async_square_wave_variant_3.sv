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
    // Pipeline stage signals
    // Stage 1: Counter operation
    reg [CNT_WIDTH-1:0] counter_q;
    wire [CNT_WIDTH-1:0] counter_next;
    reg counter_valid_s1;
    
    // Stage 2: Parameter registration and comparison preparation
    reg [CNT_WIDTH-1:0] counter_s2;
    reg [CNT_WIDTH-1:0] duty_cycle_s2;
    reg [CNT_WIDTH-1:0] max_count_s2;
    reg counter_valid_s2;
    
    // Stage 3: Comparison and output generation
    reg wave_out_reg;
    
    // Counter increment logic with clear separation
    assign counter_next = (counter_q >= max_count) ? {CNT_WIDTH{1'b0}} : counter_q + 1'b1;
    
    // Stage 1: Counter update pipeline
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            counter_q <= {CNT_WIDTH{1'b0}};
            counter_valid_s1 <= 1'b0;
        end else begin
            counter_q <= counter_next;
            counter_valid_s1 <= 1'b1;
        end
    end
    
    // Stage 2: Parameter registration pipeline
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            counter_s2 <= {CNT_WIDTH{1'b0}};
            duty_cycle_s2 <= {CNT_WIDTH{1'b0}};
            max_count_s2 <= {CNT_WIDTH{1'b0}};
            counter_valid_s2 <= 1'b0;
        end else begin
            counter_s2 <= counter_q;
            duty_cycle_s2 <= duty_cycle;
            max_count_s2 <= max_count;
            counter_valid_s2 <= counter_valid_s1;
        end
    end
    
    // Stage 3: Duty cycle comparison and output generation
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            wave_out_reg <= 1'b0;
        end else if (counter_valid_s2) begin
            wave_out_reg <= (counter_s2 < duty_cycle_s2) ? 1'b1 : 1'b0;
        end
    end
    
    // Output assignment
    assign wave_out = wave_out_reg;
    
endmodule