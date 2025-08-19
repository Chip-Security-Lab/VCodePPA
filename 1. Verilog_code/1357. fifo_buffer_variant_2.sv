//SystemVerilog
module fifo_buffer #(
    parameter DEPTH = 8,
    parameter WIDTH = 16
)(
    input wire clk, rst,
    input wire [WIDTH-1:0] data_in,
    input wire push, pop,
    output reg [WIDTH-1:0] data_out,
    output wire empty, full
);
    reg [$clog2(DEPTH)-1:0] wr_ptr, rd_ptr;
    reg [$clog2(DEPTH):0] count;
    reg [WIDTH-1:0] memory [0:DEPTH-1];
    
    // 用于补码加法实现减法
    wire [$clog2(DEPTH):0] count_complement;
    wire [$clog2(DEPTH):0] count_next;
    
    assign empty = (count == 0);
    assign full = (count == DEPTH);
    
    // 生成补码（取反加一）
    assign count_complement = ~8'h01 + 1'b1;
    
    // 使用补码加法实现减法
    assign count_next = pop && !empty ? count + count_complement : 
                        push && !full ? count + 1'b1 : count;
    
    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= 0; 
            rd_ptr <= 0; 
            count <= 0;
        end else begin
            count <= count_next;
            
            if (push && !full) begin
                memory[wr_ptr] <= data_in;
                wr_ptr <= (wr_ptr == DEPTH-1) ? 0 : wr_ptr + 1;
            end
            
            if (pop && !empty) begin
                data_out <= memory[rd_ptr];
                rd_ptr <= (rd_ptr == DEPTH-1) ? 0 : rd_ptr + 1;
            end
        end
    end
endmodule