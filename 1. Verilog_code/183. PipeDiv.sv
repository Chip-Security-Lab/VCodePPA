module PipeDiv #(parameter STAGES=3)(
    input clk, [31:0] a, b,
    output reg [31:0] res
);
    reg [31:0] pipe[STAGES-1:0];
    integer i; // 使用integer替代SystemVerilog的int类型
    
    always @(posedge clk) begin
        // 添加除零保护
        pipe[0] <= (b != 0) ? a / b : 32'hFFFFFFFF;
        
        for(i=1; i<STAGES; i=i+1) // 修改循环语法
            pipe[i] <= pipe[i-1];
        
        res <= pipe[STAGES-1];
    end
endmodule