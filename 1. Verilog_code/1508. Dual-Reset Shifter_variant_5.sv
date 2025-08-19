//SystemVerilog
// IEEE 1364-2005 Verilog标准
module dual_reset_shifter #(parameter WIDTH = 8) (
    input wire clk, sync_rst, async_rst, enable, data_in,
    output wire [WIDTH-1:0] data_out
);

    reg [WIDTH-1:0] shift_reg_stage1;
    reg [WIDTH-1:0] shift_reg_stage2;
    reg valid_stage1;
    
    // 优化阶段1: 使用单个异步复位条件判断，减少比较链
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            shift_reg_stage1 <= {WIDTH{1'b0}};
            valid_stage1 <= 1'b0;
        end
        else begin
            if (sync_rst) begin
                shift_reg_stage1 <= {WIDTH{1'b0}};
                valid_stage1 <= 1'b0;
            end
            else if (enable) begin
                shift_reg_stage1 <= {shift_reg_stage1[WIDTH-2:0], data_in};
                valid_stage1 <= 1'b1;
            end
            else begin
                // 保持当前值
                valid_stage1 <= 1'b0;
            end
        end
    end

    // 优化阶段2: 合并逻辑，减少比较操作
    always @(posedge clk or posedge async_rst) begin
        if (async_rst) begin
            shift_reg_stage2 <= {WIDTH{1'b0}};
        end
        else if (sync_rst) begin
            shift_reg_stage2 <= {WIDTH{1'b0}};
        end
        else if (valid_stage1) begin
            shift_reg_stage2 <= shift_reg_stage1;
        end
        // 不需要else，保持当前值
    end

    // 连续赋值
    assign data_out = shift_reg_stage2;

endmodule