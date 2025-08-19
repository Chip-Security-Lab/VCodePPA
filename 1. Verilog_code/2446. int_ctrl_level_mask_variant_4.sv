//SystemVerilog
// SystemVerilog
module int_ctrl_level_mask #(
    parameter N = 4
) (
    input logic clk,
    input logic rst_n,
    input logic [N-1:0] int_in,
    input logic [N-1:0] mask_reg,
    output logic [N-1:0] int_out
);
    // 输入寄存器
    logic [N-1:0] int_in_reg;
    logic [N-1:0] mask_reg_reg;
    
    // 组合逻辑输出
    logic [N-1:0] masked_int;

    // 输入寄存阶段 - 时序逻辑
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_in_reg <= '0;
            mask_reg_reg <= '0;
        end
        else begin
            int_in_reg <= int_in;
            mask_reg_reg <= mask_reg;
        end
    end
    
    // 掩码逻辑 - 纯组合逻辑
    mask_logic mask_logic_inst (
        .int_in(int_in_reg),
        .mask(mask_reg_reg),
        .masked_out(masked_int)
    );
    
    // 输出寄存阶段 - 时序逻辑
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            int_out <= '0;
        else 
            int_out <= masked_int;
    end
endmodule

// 纯组合逻辑模块
module mask_logic #(
    parameter N = 4
) (
    input logic [N-1:0] int_in,
    input logic [N-1:0] mask,
    output logic [N-1:0] masked_out
);
    // 使用连续赋值实现组合逻辑
    assign masked_out = int_in & mask;
endmodule