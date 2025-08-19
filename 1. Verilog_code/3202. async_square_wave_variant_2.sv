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
    // Internal signals
    wire [CNT_WIDTH-1:0] counter_value;
    
    // Counter module instantiation
    wave_counter #(
        .CNT_WIDTH(CNT_WIDTH)
    ) counter_inst (
        .clock(clock),
        .reset(reset),
        .max_count(max_count),
        .counter_value(counter_value)
    );
    
    // Output comparator module instantiation
    wave_comparator #(
        .CNT_WIDTH(CNT_WIDTH)
    ) comparator_inst (
        .counter_value(counter_value),
        .duty_cycle(duty_cycle),
        .wave_out(wave_out)
    );
endmodule

module wave_counter #(
    parameter CNT_WIDTH = 10
)(
    input wire clock,
    input wire reset,
    input wire [CNT_WIDTH-1:0] max_count,
    output reg [CNT_WIDTH-1:0] counter_value
);
    // Counter implementation with optimal reset structure
    always @(posedge clock or posedge reset) begin
        if (reset)
            counter_value <= {CNT_WIDTH{1'b0}};
        else if (counter_value >= max_count)
            counter_value <= {CNT_WIDTH{1'b0}};
        else
            counter_value <= counter_value + 1'b1;
    end
endmodule

module wave_comparator #(
    parameter CNT_WIDTH = 10
)(
    input wire [CNT_WIDTH-1:0] counter_value,
    input wire [CNT_WIDTH-1:0] duty_cycle,
    output wire wave_out
);
    // Comparison logic for duty cycle output generation
    // Using continuous assignment for better timing and area optimization
    assign wave_out = (counter_value < duty_cycle);
endmodule