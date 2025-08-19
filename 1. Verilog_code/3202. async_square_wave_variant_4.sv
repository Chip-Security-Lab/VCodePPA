//SystemVerilog
// Counter module
module counter #(
    parameter CNT_WIDTH = 10
)(
    input wire clock,
    input wire reset,
    input wire [CNT_WIDTH-1:0] max_count,
    output reg [CNT_WIDTH-1:0] count,
    output wire counter_reset
);

    // Reset control logic
    assign counter_reset = (count >= max_count) ? 1'b1 : 1'b0;

    // Counter update logic
    always @(posedge clock or posedge reset) begin
        if (reset)
            count <= {CNT_WIDTH{1'b0}};
        else if (counter_reset)
            count <= {CNT_WIDTH{1'b0}};
        else
            count <= count + 1'b1;
    end

endmodule

// Wave generator module
module wave_generator #(
    parameter CNT_WIDTH = 10
)(
    input wire [CNT_WIDTH-1:0] count,
    input wire [CNT_WIDTH-1:0] duty_cycle,
    output wire wave_out
);

    // Wave output comparison logic
    assign wave_out = (count < duty_cycle) ? 1'b1 : 1'b0;

endmodule

// Top level module
module async_square_wave #(
    parameter CNT_WIDTH = 10
)(
    input wire clock,
    input wire reset,
    input wire [CNT_WIDTH-1:0] max_count,
    input wire [CNT_WIDTH-1:0] duty_cycle,
    output wire wave_out
);

    wire [CNT_WIDTH-1:0] counter_value;
    wire counter_reset;

    // Instantiate counter module
    counter #(
        .CNT_WIDTH(CNT_WIDTH)
    ) counter_inst (
        .clock(clock),
        .reset(reset),
        .max_count(max_count),
        .count(counter_value),
        .counter_reset(counter_reset)
    );

    // Instantiate wave generator module
    wave_generator #(
        .CNT_WIDTH(CNT_WIDTH)
    ) wave_gen_inst (
        .count(counter_value),
        .duty_cycle(duty_cycle),
        .wave_out(wave_out)
    );

endmodule