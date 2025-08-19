//SystemVerilog
// IEEE 1364-2005 Verilog标准
module parity_shadow_reg #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire update,
    output reg [WIDTH-1:0] shadow_data,
    output reg parity_error
);
    // 流水线级别1: 输入和初始处理
    reg [WIDTH-1:0] data_stage1;
    reg parity_stage1;
    reg valid_stage1;
    
    // 流水线级别2: 工作寄存器阶段
    reg [WIDTH-1:0] work_reg_stage2;
    reg work_parity_stage2;
    reg valid_stage2;
    
    // 流水线级别3: 影子寄存器和错误检测阶段
    reg shadow_parity_stage3;
    
    //---------- 第一级流水线: 捕获输入数据 ----------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= {WIDTH{1'b0}};
        end else begin
            data_stage1 <= data_in;
        end
    end
    
    //---------- 第一级流水线: 计算奇偶校验 ----------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_stage1 <= 1'b0;
        end else begin
            parity_stage1 <= ^data_in; // 奇偶校验计算
        end
    end
    
    //---------- 第一级流水线: 更新有效信号 ----------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= update;
        end
    end
    
    //---------- 第二级流水线: 工作寄存器数据更新 ----------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            work_reg_stage2 <= {WIDTH{1'b0}};
        end else if (valid_stage1) begin
            work_reg_stage2 <= data_stage1;
        end
    end
    
    //---------- 第二级流水线: 工作寄存器奇偶校验位更新 ----------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            work_parity_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            work_parity_stage2 <= parity_stage1;
        end
    end
    
    //---------- 第二级流水线: 有效信号传递 ----------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    //---------- 第三级流水线: 影子寄存器数据更新 ----------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= {WIDTH{1'b0}};
        end else if (valid_stage2) begin
            shadow_data <= work_reg_stage2;
        end
    end
    
    //---------- 第三级流水线: 影子寄存器奇偶校验位更新 ----------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_parity_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            shadow_parity_stage3 <= work_parity_stage2;
        end
    end
    
    //---------- 第三级流水线: 奇偶校验错误检测 ----------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_error <= 1'b0;
        end else if (valid_stage2) begin
            parity_error <= (^work_reg_stage2) != work_parity_stage2;
        end
    end
endmodule