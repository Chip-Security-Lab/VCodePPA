//SystemVerilog
module dff_pipelined #(parameter WIDTH=1, parameter STAGES=3) (
    input wire clk, 
    input wire rstn,
    input wire [WIDTH-1:0] d,
    input wire valid_in,
    output wire valid_out,
    output wire [WIDTH-1:0] q
);

    // 数据和控制信号的寄存器阵列
    reg [WIDTH-1:0] data_stage [STAGES:0];  // 增加了一个寄存器以支持重定时
    reg valid_stage [STAGES:0];  // 增加了一个寄存器以支持重定时
    
    integer i;
    
    // 流水线处理逻辑 - 优化后的重定时结构
    always @(posedge clk) begin
        if (!rstn) begin
            for (i = 0; i <= STAGES; i = i + 1) begin
                data_stage[i] <= {WIDTH{1'b0}};
                valid_stage[i] <= 1'b0;
            end
        end else begin
            // 输入直接连接到第一个寄存器
            data_stage[0] <= d;
            valid_stage[0] <= valid_in;
            
            // 流水线级重定时
            for (i = 1; i <= STAGES; i = i + 1) begin
                data_stage[i] <= data_stage[i-1];
                valid_stage[i] <= valid_stage[i-1];
            end
        end
    end
    
    // 优化后的输出赋值 - 从新的最终级取值
    assign q = data_stage[STAGES];
    assign valid_out = valid_stage[STAGES];
    
endmodule