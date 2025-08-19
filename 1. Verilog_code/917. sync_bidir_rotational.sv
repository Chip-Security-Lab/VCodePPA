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
    
    // Corrected implementations for left and right rotations
    // Left rotation combines left shift with wrapped-around bits from the right
    assign left_rot = (in_vector << shift_count) | (in_vector >> (WIDTH - shift_count));
    
    // Right rotation combines right shift with wrapped-around bits from the left
    assign right_rot = (in_vector >> shift_count) | (in_vector << (WIDTH - shift_count));
    
    // Register output with direction control
    always @(posedge clock) begin
        if (reset)
            out_vector <= 0;
        else
            out_vector <= direction ? right_rot : left_rot;
    end
endmodule