module shift_queue #(parameter DW=8, DEPTH=4) (
    input clk, load, shift,
    input [DW*DEPTH-1:0] data_in,
    output reg [DW-1:0] data_out
);
    reg [DW-1:0] queue [0:DEPTH-1];
    integer i;
    
    always @(posedge clk) begin
        if(load) begin
            // 修复错误的数组赋值
            for(i=0; i<DEPTH; i=i+1) begin
                queue[i] <= data_in[i*DW +: DW];
            end
        end else if(shift) begin
            data_out <= queue[DEPTH-1];
            for(i=DEPTH-1; i>0; i=i-1) begin
                queue[i] <= queue[i-1];
            end
            queue[0] <= 0;  // 清除第一个元素
        end
    end
endmodule