//SystemVerilog
module compare_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire update_main,
    input wire update_shadow,
    input wire valid_in,           // 输入有效信号
    output wire ready_in,          // 输入就绪信号
    output reg [WIDTH-1:0] main_data,
    output reg [WIDTH-1:0] shadow_data,
    output reg data_match,
    output reg valid_out           // 输出有效信号
);
    // 流水线寄存器和控制信号
    reg [WIDTH-1:0] data_in_stage1;
    reg update_main_stage1, update_shadow_stage1;
    reg valid_stage1;
    
    // 第二级流水线寄存器
    reg [WIDTH-1:0] main_data_stage2;
    reg [WIDTH-1:0] shadow_data_stage2;
    reg valid_stage2;
    
    // 流水线控制逻辑
    assign ready_in = 1'b1;  // 始终准备接收新数据
    
    // 第一级流水线：捕获输入
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_stage1 <= 0;
            update_main_stage1 <= 0;
            update_shadow_stage1 <= 0;
            valid_stage1 <= 0;
        end
        else begin
            data_in_stage1 <= data_in;
            update_main_stage1 <= update_main;
            update_shadow_stage1 <= update_shadow;
            valid_stage1 <= valid_in;
        end
    end
    
    // 第二级流水线：更新寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            main_data <= 0;
            shadow_data <= 0;
            data_match <= 0;
            valid_out <= 0;
        end
        else begin
            // 更新主寄存器
            if (update_main_stage1)
                main_data <= data_in_stage1;
            
            // 更新影子寄存器
            if (update_shadow_stage1)
                shadow_data <= data_in_stage1;
                
            valid_out <= valid_stage1;
            data_match <= (main_data == shadow_data);
        end
    end
endmodule