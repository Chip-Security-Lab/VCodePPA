//SystemVerilog
// IEEE 1364-2005 Verilog标准
module trigger_shadow_reg #(
    parameter WIDTH = 16
)(
    input  wire              clock,
    input  wire              nreset,
    input  wire [WIDTH-1:0]  data_in,
    input  wire [WIDTH-1:0]  trigger_value,
    output reg  [WIDTH-1:0]  shadow_data
);
    // 数据流水线寄存器
    reg [WIDTH-1:0] data_pipeline_reg;
    
    // 触发比较结果流水线寄存器
    reg trigger_match_reg;
    
    // 数据采集流水线 - 第一级
    // 将输入数据缓存到管道第一级寄存器
    always @(posedge clock or negedge nreset) begin
        if (~nreset)
            data_pipeline_reg <= {WIDTH{1'b0}};
        else
            data_pipeline_reg <= data_in;
    end
    
    // 触发检测流水线 - 比较逻辑与结果缓存
    always @(posedge clock or negedge nreset) begin
        if (~nreset)
            trigger_match_reg <= 1'b0;
        else
            trigger_match_reg <= (data_pipeline_reg == trigger_value);
    end
    
    // 数据捕获流水线 - 最终级
    // 根据触发结果捕获数据到shadow寄存器
    always @(posedge clock or negedge nreset) begin
        if (~nreset)
            shadow_data <= {WIDTH{1'b0}};
        else if (trigger_match_reg)
            shadow_data <= data_pipeline_reg;
    end
endmodule