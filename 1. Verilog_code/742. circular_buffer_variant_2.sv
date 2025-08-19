//SystemVerilog
module circular_buffer_pipeline #(
    parameter DW = 16,
    parameter DEPTH = 8
)(
    input clk,
    input rst,
    input push,
    input pop,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output full,
    output empty
);

// Pipeline registers
reg [DW-1:0] buffer [0:DEPTH-1];
reg [3:0] wptr, rptr;
reg [DW-1:0] din_stage1;
reg push_stage1, pop_stage1;
reg [3:0] wptr_next_stage1, rptr_next_stage1;

// Next pointer calculations
wire [3:0] wptr_next = wptr + 1;
wire [3:0] rptr_next = rptr + 1;

// Optimized full and empty conditions
wire wptr_equal_rptr = (wptr == rptr);
wire wptr_high_bit = wptr[3] ^ rptr[3];
assign full = wptr_equal_rptr && wptr_high_bit;
assign empty = wptr_equal_rptr;

// Pipeline control signals
reg valid_stage1, valid_stage2;

// Stage 1: Input handling
always @(posedge clk) begin
    case (rst)
        1'b1: begin
            din_stage1 <= 0;
            push_stage1 <= 0;
            valid_stage1 <= 0;
        end
        default: begin
            din_stage1 <= din;
            push_stage1 <= push;
            valid_stage1 <= push && !full;
        end
    endcase
end

// Stage 2: Write pointer update and buffer write
always @(posedge clk) begin
    case (rst)
        1'b1: begin
            wptr <= 0;
        end
        default: begin
            if (valid_stage1) begin
                buffer[wptr[2:0]] <= din_stage1;
                wptr <= wptr_next;
            end
        end
    endcase
end

// Stage 3: Read pointer update
always @(posedge clk) begin
    case (rst)
        1'b1: begin
            rptr <= 0;
        end
        default: begin
            if (pop && !empty) begin
                rptr <= rptr_next;
            end
        end
    endcase
end

// Output assignment
assign dout = buffer[rptr[2:0]];

endmodule