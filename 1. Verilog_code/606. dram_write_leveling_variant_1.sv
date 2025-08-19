//SystemVerilog
module dram_write_leveling #(
    parameter DQ_BITS = 8
)(
    input clk,
    input training_en,
    output [DQ_BITS-1:0] dqs_pattern
);

    wire [7:0] phase_counter_out;
    wire [DQ_BITS-1:0] pattern_out;

    phase_counter u_phase_counter(
        .clk(clk),
        .training_en(training_en),
        .phase_counter(phase_counter_out)
    );

    pattern_generator #(
        .DQ_BITS(DQ_BITS)
    ) u_pattern_generator(
        .phase_counter(phase_counter_out),
        .training_en(training_en),
        .dqs_pattern(pattern_out)
    );

    assign dqs_pattern = pattern_out;

endmodule

module phase_counter(
    input clk,
    input training_en,
    output reg [7:0] phase_counter
);

    reg [7:0] next_phase;
    wire [7:0] phase_inc = 8'b00000001;
    wire [7:0] phase_comp = ~phase_inc + 1'b1;

    always @(*) begin
        if(training_en) begin
            next_phase = phase_counter + phase_inc;
        end else begin
            next_phase = phase_counter;
        end
    end

    always @(posedge clk) begin
        phase_counter <= next_phase;
    end

endmodule

module pattern_generator #(
    parameter DQ_BITS = 8
)(
    input [7:0] phase_counter,
    input training_en,
    output reg [DQ_BITS-1:0] dqs_pattern
);

    always @(*) begin
        if(training_en) begin
            dqs_pattern = {DQ_BITS{phase_counter[3]}};
        end else begin
            dqs_pattern = {DQ_BITS{1'b0}};
        end
    end

endmodule