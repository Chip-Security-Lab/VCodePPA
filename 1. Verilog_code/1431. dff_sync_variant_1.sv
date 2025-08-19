//SystemVerilog
module dff_sync #(parameter WIDTH=1) (
    input clk, rstn, 
    input [WIDTH-1:0] d,
    output [WIDTH-1:0] q
);
    reg [WIDTH-1:0] q_int;
    
    // 将原先的单个always块拆分为两个不同功能的always块
    
    // 复位逻辑处理块 - 专门处理异步复位
    always @(negedge rstn) begin
        if (!rstn)
            q_int <= {WIDTH{1'b0}};
    end
    
    // 数据更新处理块 - 专门处理时钟上升沿时的数据装载
    always @(posedge clk) begin
        if (rstn)
            q_int <= d;
    end

    // 输出赋值
    assign q = q_int;
    
endmodule