//SystemVerilog
module shift_queue #(parameter DW=8, DEPTH=4) (
    input clk,
    input load,
    input shift,
    input [DW*DEPTH-1:0] data_in,
    output reg [DW-1:0] data_out
);
    reg [DW-1:0] queue [0:DEPTH-1];
    integer idx;

    // 2-bit Parallel Prefix Subtractor module instantiation
    wire [DW-1:0] sub_a, sub_b;
    wire [DW-1:0] sub_result;
    wire sub_cout;

    // Example usage: sub_a - sub_b -> sub_result
    assign sub_a = queue[DEPTH-1][1:0];
    assign sub_b = queue[DEPTH-2][1:0];

    parallel_prefix_subtractor_2bit u_pps2 (
        .a(sub_a[1:0]),
        .b(sub_b[1:0]),
        .diff(sub_result[1:0]),
        .borrow_out(sub_cout)
    );

    typedef enum reg [1:0] {
        IDLE  = 2'b00,
        LOAD  = 2'b01,
        SHIFT = 2'b10
    } queue_ctrl_t;

    reg [1:0] ctrl_state;

    always @(*) begin
        case ({load, shift})
            2'b10: ctrl_state = LOAD;
            2'b01: ctrl_state = SHIFT;
            default: ctrl_state = IDLE;
        endcase
    end

    always @(posedge clk) begin
        case (ctrl_state)
            LOAD: begin
                for (idx = 0; idx < DEPTH; idx = idx + 1) begin
                    queue[idx] <= data_in[idx*DW +: DW];
                end
            end
            SHIFT: begin
                // Use parallel prefix subtractor for lower 2 bits subtraction
                data_out[1:0] <= sub_result[1:0];
                if (DW > 2) begin
                    data_out[DW-1:2] <= queue[DEPTH-1][DW-1:2];
                end
                for (idx = DEPTH-1; idx > 0; idx = idx - 1) begin
                    queue[idx] <= queue[idx-1];
                end
                queue[0] <= {DW{1'b0}};
            end
            default: begin
                // No operation
            end
        endcase
    end
endmodule

// 2-bit Parallel Prefix Subtractor (Kogge-Stone style, borrow lookahead)
module parallel_prefix_subtractor_2bit (
    input  [1:0] a,
    input  [1:0] b,
    output [1:0] diff,
    output       borrow_out
);
    wire [1:0] b_inv;
    wire [1:0] g, p;
    wire [1:0] borrow;

    // Invert b for subtraction (a - b = a + ~b + 1)
    assign b_inv = ~b;

    // Generate and Propagate
    assign g[0] = (~a[0]) & b[0]; // Generate borrow at bit 0
    assign p[0] = ~(a[0] ^ b[0]); // Propagate borrow at bit 0

    assign g[1] = (~a[1]) & b[1];
    assign p[1] = ~(a[1] ^ b[1]);

    // Borrow Lookahead
    assign borrow[0] = g[0];
    assign borrow[1] = g[1] | (p[1] & g[0]);
    assign borrow_out = borrow[1];

    // Difference calculation
    assign diff[0] = a[0] ^ b[0];
    assign diff[1] = a[1] ^ b[1] ^ borrow[0];

endmodule