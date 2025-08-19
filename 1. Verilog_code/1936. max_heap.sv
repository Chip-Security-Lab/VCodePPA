module max_heap #(parameter DW=8, HEAP_SIZE=16) (
    input clk, insert,
    input [DW-1:0] data_in,
    output reg [DW-1:0] data_out  // 修改：将output改为output reg
);
    reg [DW-1:0] heap [0:HEAP_SIZE-1];  // 修改：数组大小为HEAP_SIZE-1
    reg [4:0] idx;
    
    // 初始化寄存器
    initial begin
        idx = 5'b0;
    end

    always @(posedge clk) begin
        if(insert) begin
            heap[idx] <= data_in;
            idx <= idx + 1'b1;
        end else if(idx > 0) begin  // 添加检查以防止下溢
            data_out <= heap[0];
            heap[0] <= heap[idx-1'b1];
            idx <= idx - 1'b1;
        end
    end
endmodule