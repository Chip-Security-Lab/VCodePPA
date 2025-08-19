//SystemVerilog
module sync_bidir_rotational #(
    parameter WIDTH = 64
)(
    input                   clock,
    input                   reset,
    input      [WIDTH-1:0]  in_vector,
    input      [$clog2(WIDTH)-1:0] shift_count,
    input                   direction, // 0=left, 1=right
    output reg [WIDTH-1:0]  out_vector
);
    wire [WIDTH-1:0] left_rot, right_rot;
    reg  [WIDTH-1:0] selected_rot;
    wire [$clog2(WIDTH)-1:0] inv_shift_count;
    wire [WIDTH-1:0] inv_in_vector;
    
    // Conditional inversion for subtraction
    assign inv_shift_count = direction ? shift_count : ~shift_count + 1'b1;
    assign inv_in_vector = direction ? in_vector : ~in_vector;
    
    // Optimized rotation using conditional inversion
    assign left_rot = (in_vector << shift_count) | (in_vector >> (WIDTH - shift_count));
    assign right_rot = (inv_in_vector << inv_shift_count) | (inv_in_vector >> (WIDTH - inv_shift_count));
    
    always @(*) begin
        if (direction)
            selected_rot = right_rot;
        else
            selected_rot = left_rot;
    end
    
    always @(posedge clock) begin
        if (reset)
            out_vector <= {WIDTH{1'b0}};
        else
            out_vector <= selected_rot;
    end
endmodule