//SystemVerilog
// 顶层模块
module Shifter_NAND(
    input wire [2:0] shift,
    input wire [7:0] val,
    output wire [7:0] res
);
    // 中间数据流信号 - 清晰命名表示数据流阶段
    wire [2:0] shift_stage1_r;
    wire [7:0] val_stage1_r;
    wire [7:0] shifted_mask_stage1;
    wire [7:0] shifted_mask_stage2_r;
    wire [7:0] masked_val_stage2;
    wire [7:0] masked_val_stage3_r;
    
    // 阶段1: 输入寄存和掩码生成
    InputRegister input_reg (
        .clk(clk),
        .rst_n(rst_n),
        .shift_in(shift),
        .val_in(val),
        .shift_out(shift_stage1_r),
        .val_out(val_stage1_r)
    );
    
    ShiftMaskGenerator shift_mask_gen (
        .shift_amount(shift_stage1_r),
        .shifted_mask(shifted_mask_stage1)
    );
    
    // 阶段2: 掩码寄存和应用
    MaskRegister mask_reg (
        .clk(clk),
        .rst_n(rst_n),
        .mask_in(shifted_mask_stage1),
        .val_in(val_stage1_r),
        .mask_out(shifted_mask_stage2_r),
        .val_out(val_stage2_r)
    );
    
    MaskApplicator mask_applicator (
        .input_val(val_stage2_r),
        .mask(shifted_mask_stage2_r),
        .masked_result(masked_val_stage2)
    );
    
    // 阶段3: 结果寄存和取反操作
    ResultRegister result_reg (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(masked_val_stage2),
        .data_out(masked_val_stage3_r)
    );
    
    InverterModule inverter (
        .data_in(masked_val_stage3_r),
        .data_out(res)
    );
endmodule

// 输入寄存器模块
module InputRegister(
    input wire clk,
    input wire rst_n,
    input wire [2:0] shift_in,
    input wire [7:0] val_in,
    output reg [2:0] shift_out,
    output reg [7:0] val_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_out <= 3'b0;
            val_out <= 8'b0;
        end else begin
            shift_out <= shift_in;
            val_out <= val_in;
        end
    end
endmodule

// 掩码寄存器模块
module MaskRegister(
    input wire clk,
    input wire rst_n,
    input wire [7:0] mask_in,
    input wire [7:0] val_in,
    output reg [7:0] mask_out,
    output reg [7:0] val_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mask_out <= 8'b0;
            val_out <= 8'b0;
        end else begin
            mask_out <= mask_in;
            val_out <= val_in;
        end
    end
endmodule

// 结果寄存器模块
module ResultRegister(
    input wire clk,
    input wire rst_n,
    input wire [7:0] data_in,
    output reg [7:0] data_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 8'b0;
        end else begin
            data_out <= data_in;
        end
    end
endmodule

// 优化的掩码生成模块 - 降低逻辑深度
module ShiftMaskGenerator(
    input wire [2:0] shift_amount,
    output wire [7:0] shifted_mask
);
    // 使用查找表方法降低逻辑深度
    reg [7:0] mask_lut;
    
    always @(*) begin
        case (shift_amount)
            3'd0: mask_lut = 8'hFF;
            3'd1: mask_lut = 8'hFE;
            3'd2: mask_lut = 8'hFC;
            3'd3: mask_lut = 8'hF8;
            3'd4: mask_lut = 8'hF0;
            3'd5: mask_lut = 8'hE0;
            3'd6: mask_lut = 8'hC0;
            3'd7: mask_lut = 8'h80;
            default: mask_lut = 8'hFF;
        endcase
    end
    
    assign shifted_mask = mask_lut;
endmodule

// 优化的掩码应用模块
module MaskApplicator(
    input wire [7:0] input_val,
    input wire [7:0] mask,
    output wire [7:0] masked_result
);
    // 应用掩码，保持功能不变
    assign masked_result = input_val & mask;
endmodule

// 优化的取反模块
module InverterModule(
    input wire [7:0] data_in,
    output wire [7:0] data_out
);
    // 对输入数据进行取反操作
    assign data_out = ~data_in;
endmodule