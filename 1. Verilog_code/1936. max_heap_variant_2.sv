//SystemVerilog
module max_heap #(parameter DW=8, HEAP_SIZE=16) (
    input clk,
    input insert,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out
);
    reg [DW-1:0] heap [0:HEAP_SIZE-1];
    reg [4:0] heap_index;

    reg insert_d;
    reg [DW-1:0] data_in_d;

    // Forward retiming: Move register after insert/data_in through combinational logic

    // Pipeline input signals
    always @(posedge clk) begin
        insert_d <= insert;
        data_in_d <= data_in;
    end

    // Initialize heap_index
    initial begin
        heap_index = 5'b0;
    end

    always @(posedge clk) begin
        case ({insert_d, (heap_index > 0)})
            2'b10: begin // insert == 1, heap_index > 0/heap_index == 0
                heap[heap_index] <= data_in_d;
                heap_index <= heap_index + 1'b1;
            end
            2'b01: begin // insert == 0, heap_index > 0
                data_out <= heap[0];
                heap[0] <= heap[heap_index - 1'b1];
                heap_index <= heap_index - 1'b1;
            end
            default: begin
                // 保持当前状态
            end
        endcase
    end
endmodule