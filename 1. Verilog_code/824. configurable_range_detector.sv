module configurable_range_detector(
    input wire clock, resetn,
    input wire [15:0] data,
    input wire [15:0] bound_a, bound_b,
    input wire [1:0] mode, // 00:in_range, 01:out_range, 10:above_only, 11:below_only
    output reg detect_flag
);
    wire in_range, above_a, below_b;
    
    assign above_a = (data >= bound_a);
    assign below_b = (data <= bound_b);
    assign in_range = above_a && below_b;
    
    always @(posedge clock or negedge resetn) begin
        if (!resetn) detect_flag <= 1'b0;
        else case(mode)
            2'b00: detect_flag <= in_range;
            2'b01: detect_flag <= !in_range;
            2'b10: detect_flag <= above_a;
            2'b11: detect_flag <= below_b;
        endcase
    end
endmodule