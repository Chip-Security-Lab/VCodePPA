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
    // Buffered input signals to reduce fanout
    reg [WIDTH-1:0] in_vector_buf1, in_vector_buf2;
    reg [$clog2(WIDTH)-1:0] shift_count_reg;
    reg direction_reg;
    wire [WIDTH-1:0] left_rot, right_rot;
    
    // Register input signals to reduce fanout
    always @(posedge clock) begin
        if (reset) begin
            in_vector_buf1 <= 0;
            in_vector_buf2 <= 0;
            shift_count_reg <= 0;
            direction_reg <= 0;
        end else begin
            in_vector_buf1 <= in_vector;
            in_vector_buf2 <= in_vector;
            shift_count_reg <= shift_count;
            direction_reg <= direction;
        end
    end
    
    // Split rotational logic using buffered inputs
    // Left rotation uses in_vector_buf1
    assign left_rot = (in_vector_buf1 << shift_count_reg) | (in_vector_buf1 >> (WIDTH - shift_count_reg));
    
    // Right rotation uses in_vector_buf2
    assign right_rot = (in_vector_buf2 >> shift_count_reg) | (in_vector_buf2 << (WIDTH - shift_count_reg));
    
    // Register output with direction control
    always @(posedge clock) begin
        if (reset)
            out_vector <= 0;
        else
            out_vector <= direction_reg ? right_rot : left_rot;
    end
endmodule