//SystemVerilog
module range_comparator(
    input wire [23:0] data,
    input wire [23:0] min_range,
    input wire [23:0] max_range,
    output reg above_min,
    output reg below_max
);
    always @(*) begin
        above_min = (data >= min_range);
        below_max = (data <= max_range);
    end
endmodule

module range_validator(
    input wire clock,
    input wire reset,
    input wire above_min,
    input wire below_max,
    output reg in_range
);
    always @(posedge clock) begin
        in_range <= reset ? 1'b0 : (above_min && below_max);
    end
endmodule

module pipelined_range_detector(
    input wire clock,
    input wire reset,
    input wire [23:0] data,
    input wire [23:0] min_range,
    input wire [23:0] max_range,
    output reg valid_range
);
    wire above_min, below_max;
    reg stage1_in_range;
    
    range_comparator comp_inst(
        .data(data),
        .min_range(min_range),
        .max_range(max_range),
        .above_min(above_min),
        .below_max(below_max)
    );
    
    range_validator valid_inst(
        .clock(clock),
        .reset(reset),
        .above_min(above_min),
        .below_max(below_max),
        .in_range(stage1_in_range)
    );
    
    always @(posedge clock) begin
        valid_range <= reset ? 1'b0 : stage1_in_range;
    end
endmodule