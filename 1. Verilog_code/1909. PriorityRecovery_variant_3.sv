//SystemVerilog
module PriorityRecovery #(parameter WIDTH=8, SOURCES=4) (
    input clk,
    input [SOURCES-1:0] valid,
    input [WIDTH*SOURCES-1:0] data_bus,
    output reg [WIDTH-1:0] selected_data
);
    // 组合逻辑信号定义
    wire [1:0] priority_index_comb;
    wire data_valid_comb;
    wire [WIDTH-1:0] selected_data_comb;
    
    // 第一阶段：优先级编码器 - 使用组合逻辑立即确定最高优先级的有效源
    assign data_valid_comb = |valid;
    
    // 优先级编码器组合逻辑实现
    assign priority_index_comb = valid[3] ? 2'd3 :
                                valid[2] ? 2'd2 :
                                valid[1] ? 2'd1 : 2'd0;
    
    // 基于组合逻辑的输出直接选择数据
    assign selected_data_comb = data_valid_comb ? 
                               (priority_index_comb == 2'd3) ? data_bus[WIDTH*3 +: WIDTH] :
                               (priority_index_comb == 2'd2) ? data_bus[WIDTH*2 +: WIDTH] :
                               (priority_index_comb == 2'd1) ? data_bus[WIDTH*1 +: WIDTH] :
                                                              data_bus[WIDTH*0 +: WIDTH]
                               : {WIDTH{1'b0}};
    
    // 将寄存器移到组合逻辑之后，直接寄存最终输出结果
    always @(posedge clk) begin
        selected_data <= selected_data_comb;
    end

endmodule