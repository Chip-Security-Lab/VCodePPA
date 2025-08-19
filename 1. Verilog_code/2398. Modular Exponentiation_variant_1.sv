//SystemVerilog
module mod_exp #(parameter WIDTH = 16) (
    input wire clk, reset,
    input wire start,
    input wire [WIDTH-1:0] base, exponent, modulus,
    output reg [WIDTH-1:0] result,
    output reg done
);
    // 控制状态寄存器
    reg calculating;
    
    // 数据寄存器
    reg [WIDTH-1:0] exp_reg, base_reg;
    reg [WIDTH-1:0] next_result;

    // 完成条件信号
    wire calc_complete = calculating && exp_reg == 0;
    
    // 状态控制逻辑和完成信号生成
    reg_control #(.RESET_VAL(1'b0)) u_calc_ctrl (
        .clk(clk),
        .reset(reset),
        .set_val(start),
        .clear_val(calc_complete),
        .reg_out(calculating)
    );
    
    reg_control #(.RESET_VAL(1'b0)) u_done_ctrl (
        .clk(clk),
        .reset(reset),
        .set_val(calc_complete),
        .clear_val(start),
        .reg_out(done)
    );
    
    // 数据寄存器控制
    data_register #(
        .WIDTH(WIDTH),
        .RESET_VAL(0)
    ) u_exp_reg (
        .clk(clk),
        .reset(reset),
        .load_en(start),
        .load_val(exponent),
        .update_en(calculating && exp_reg != 0),
        .update_val(exp_reg >> 1),
        .reg_out(exp_reg)
    );
    
    data_register #(
        .WIDTH(WIDTH),
        .RESET_VAL(0)
    ) u_base_reg (
        .clk(clk),
        .reset(reset),
        .load_en(start),
        .load_val(base),
        .update_en(calculating && exp_reg != 0),
        .update_val((base_reg * base_reg) % modulus),
        .reg_out(base_reg)
    );
    
    // 计算下一个结果值
    modular_multiply #(
        .WIDTH(WIDTH)
    ) u_mod_mult (
        .a(result),
        .b(base_reg),
        .modulus(modulus),
        .enable(exp_reg[0] && calculating && exp_reg != 0),
        .result(next_result),
        .bypass_val(result)
    );
    
    // 结果寄存器控制
    data_register #(
        .WIDTH(WIDTH),
        .RESET_VAL(1)
    ) u_result_reg (
        .clk(clk),
        .reset(reset),
        .load_en(start),
        .load_val(1),
        .update_en(calculating && exp_reg != 0),
        .update_val(next_result),
        .reg_out(result)
    );
endmodule

// 通用寄存器控制模块
module reg_control #(
    parameter RESET_VAL = 1'b0
)(
    input wire clk, reset,
    input wire set_val, clear_val,
    output reg reg_out
);
    always @(posedge clk) begin
        if (reset) begin
            reg_out <= RESET_VAL;
        end else if (set_val) begin
            reg_out <= 1'b1;
        end else if (clear_val) begin
            reg_out <= 1'b0;
        end
    end
endmodule

// 通用数据寄存器模块
module data_register #(
    parameter WIDTH = 16,
    parameter RESET_VAL = 0
)(
    input wire clk, reset,
    input wire load_en,
    input wire [WIDTH-1:0] load_val,
    input wire update_en,
    input wire [WIDTH-1:0] update_val,
    output reg [WIDTH-1:0] reg_out
);
    always @(posedge clk) begin
        if (reset) begin
            reg_out <= RESET_VAL;
        end else if (load_en) begin
            reg_out <= load_val;
        end else if (update_en) begin
            reg_out <= update_val;
        end
    end
endmodule

// 模乘带选择旁路模块
module modular_multiply #(
    parameter WIDTH = 16
)(
    input wire [WIDTH-1:0] a, b, modulus,
    input wire enable,
    input wire [WIDTH-1:0] bypass_val,
    output wire [WIDTH-1:0] result
);
    assign result = enable ? (a * b) % modulus : bypass_val;
endmodule