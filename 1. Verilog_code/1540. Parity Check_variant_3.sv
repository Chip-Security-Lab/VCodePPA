//SystemVerilog - IEEE 1364-2005
//------------------------------------------------------------------------------
// 顶层模块 - 奇偶校验影子寄存器系统
//------------------------------------------------------------------------------
module parity_shadow_reg #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] data_in,
    input  wire update,
    output wire [WIDTH-1:0] shadow_data,
    output wire parity_error
);
    // 内部连接信号
    wire [WIDTH-1:0] work_reg_data;
    wire work_reg_parity;

    // 工作寄存器子模块实例化
    work_register_module #(
        .WIDTH(WIDTH)
    ) work_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(data_in),
        .update(update),
        .work_data_out(work_reg_data),
        .work_parity_out(work_reg_parity)
    );

    // 影子寄存器与错误检测子模块实例化
    shadow_register_module #(
        .WIDTH(WIDTH)
    ) shadow_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .work_data_in(work_reg_data),
        .work_parity_in(work_reg_parity),
        .update(update),
        .shadow_data_out(shadow_data),
        .parity_error_out(parity_error)
    );

endmodule

//------------------------------------------------------------------------------
// 工作寄存器子模块 - 负责数据存储和奇偶校验计算
//------------------------------------------------------------------------------
module work_register_module #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] data_in,
    input  wire update,
    output reg  [WIDTH-1:0] work_data_out,
    output reg  work_parity_out
);
    // 更新工作寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            work_data_out <= {WIDTH{1'b0}};
        end else if (update) begin
            work_data_out <= data_in;
        end
    end
    
    // 计算奇偶校验位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            work_parity_out <= 1'b0;
        end else if (update) begin
            work_parity_out <= ^data_in;
        end
    end
endmodule

//------------------------------------------------------------------------------
// 影子寄存器子模块 - 负责错误检测和影子数据存储
//------------------------------------------------------------------------------
module shadow_register_module #(
    parameter WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire [WIDTH-1:0] work_data_in,
    input  wire work_parity_in,
    input  wire update,
    output reg  [WIDTH-1:0] shadow_data_out,
    output reg  parity_error_out
);
    // 影子寄存器的奇偶校验位
    reg shadow_parity;
    reg calculated_parity;

    // 更新影子数据寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data_out <= {WIDTH{1'b0}};
        end else if (update) begin
            shadow_data_out <= work_data_in;
        end
    end
    
    // 更新影子奇偶校验位
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_parity <= 1'b0;
        end else if (update) begin
            shadow_parity <= work_parity_in;
        end
    end
    
    // 计算当前数据的奇偶校验
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            calculated_parity <= 1'b0;
        end else if (update) begin
            calculated_parity <= ^work_data_in;
        end
    end
    
    // 检测奇偶校验错误
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parity_error_out <= 1'b0;
        end else if (update) begin
            parity_error_out <= (^work_data_in) != work_parity_in;
        end
    end
endmodule