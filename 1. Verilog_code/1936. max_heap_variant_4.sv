//SystemVerilog
module max_heap #(parameter DW=8, HEAP_SIZE=16) (
    input clk, 
    input insert,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
    reg [DW-1:0] heap [0:HEAP_SIZE-1];
    reg [4:0] heap_index;

    // 5位条件反相减法器
    function [4:0] conditional_invert_subtractor_5b;
        input [4:0] minuend;
        input [4:0] subtrahend;
        reg [4:0] subtrahend_inverted;
        reg carry_in;
        reg [4:0] sum;
        reg carry_out;
        begin
            subtrahend_inverted = ~subtrahend;
            carry_in = 1'b1;
            {carry_out, sum} = minuend + subtrahend_inverted + carry_in;
            conditional_invert_subtractor_5b = sum;
        end
    endfunction

    // 5位加法器
    function [4:0] adder_5b;
        input [4:0] a;
        input [4:0] b;
        reg [4:0] sum;
        reg carry_out;
        begin
            {carry_out, sum} = a + b;
            adder_5b = sum;
        end
    endfunction

    // 初始化寄存器
    initial begin
        heap_index = 5'b0;
    end

    always @(posedge clk) begin
        case ({insert, (heap_index > 0)})
            2'b10: begin // insert == 1, heap_index irrelevant
                heap[heap_index] <= data_in;
                heap_index <= adder_5b(heap_index, 5'b00001);
            end
            2'b01: begin // insert == 0, heap_index > 0
                data_out <= heap[0];
                heap[0] <= heap[conditional_invert_subtractor_5b(heap_index, 5'b00001)];
                heap_index <= conditional_invert_subtractor_5b(heap_index, 5'b00001);
            end
            default: begin
                // No operation
            end
        endcase
    end
endmodule