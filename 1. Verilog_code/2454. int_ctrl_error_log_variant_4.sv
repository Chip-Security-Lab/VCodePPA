//SystemVerilog
module int_ctrl_error_log #(
    parameter ERR_BITS = 4
)(
    input wire clk,
    input wire rst,
    input wire [ERR_BITS-1:0] err_in,
    input wire valid_in,
    output wire valid_out,
    output wire [ERR_BITS-1:0] err_log
);

    // 阶段1：输入缓冲寄存器
    reg [ERR_BITS-1:0] err_stage1;
    reg valid_stage1;
    
    // 阶段2：错误预处理寄存器
    reg [ERR_BITS-1:0] err_stage2;
    reg valid_stage2;
    
    // 阶段3：错误处理中间寄存器
    reg [ERR_BITS-1:0] err_stage3;
    reg valid_stage3;
    
    // 阶段4：错误处理融合寄存器
    reg [ERR_BITS-1:0] err_stage4;
    reg valid_stage4;
    
    // 阶段5：输出寄存器
    reg [ERR_BITS-1:0] err_log_reg;
    reg valid_stage5;
    
    // 阶段1：输入缓冲
    always @(posedge clk) begin
        if (rst) begin
            err_stage1 <= {ERR_BITS{1'b0}};
            valid_stage1 <= 1'b0;
        end
        else begin
            err_stage1 <= err_in;
            valid_stage1 <= valid_in;
        end
    end
    
    // 阶段2：错误预处理
    always @(posedge clk) begin
        if (rst) begin
            err_stage2 <= {ERR_BITS{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else begin
            err_stage2 <= err_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段3：错误处理中间步骤
    always @(posedge clk) begin
        if (rst) begin
            err_stage3 <= {ERR_BITS{1'b0}};
            valid_stage3 <= 1'b0;
        end
        else begin
            // 仅当有效时传递数据，否则清零
            err_stage3 <= valid_stage2 ? err_stage2 : {ERR_BITS{1'b0}};
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 阶段4：错误处理准备融合
    always @(posedge clk) begin
        if (rst) begin
            err_stage4 <= {ERR_BITS{1'b0}};
            valid_stage4 <= 1'b0;
        end
        else begin
            err_stage4 <= err_stage3;
            valid_stage4 <= valid_stage3;
        end
    end
    
    // 阶段5：最终错误处理和融合
    always @(posedge clk) begin
        if (rst) begin
            err_log_reg <= {ERR_BITS{1'b0}};
            valid_stage5 <= 1'b0;
        end
        else begin
            // 当阶段4有效时，将新的错误与累积的错误合并
            if (valid_stage4) begin
                err_log_reg <= err_log_reg | err_stage4;
            end
            valid_stage5 <= valid_stage4;
        end
    end
    
    // 输出赋值
    assign err_log = err_log_reg;
    assign valid_out = valid_stage5;

endmodule