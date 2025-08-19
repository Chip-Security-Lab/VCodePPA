//SystemVerilog
module ring_counter #(parameter WIDTH = 4) (
    input wire clock, reset, preset,
    input wire valid_in,        // 输入有效信号
    output wire valid_out,      // 输出有效信号
    output wire [WIDTH-1:0] count
);
    // 流水线寄存器
    reg [WIDTH-1:0] shift_reg_stage1;
    reg [WIDTH-1:0] shift_reg_stage2;
    
    // 控制信号流水线
    reg valid_stage1;
    reg valid_stage2;
    
    // 阶段1: 重置逻辑
    always @(posedge clock) begin
        if (reset) begin
            shift_reg_stage1 <= {(WIDTH){1'b0}};
        end
        else if (preset) begin
            shift_reg_stage1 <= {1'b1, {(WIDTH-1){1'b0}}};
        end
        else if (valid_in) begin
            shift_reg_stage1 <= {shift_reg_stage2[0], shift_reg_stage2[WIDTH-1:1]};
        end
    end
    
    // 阶段1: 有效信号控制
    always @(posedge clock) begin
        if (reset) begin
            valid_stage1 <= 1'b0;
        end
        else if (preset) begin
            valid_stage1 <= 1'b1;
        end
        else begin
            valid_stage1 <= valid_in;
        end
    end
    
    // 阶段2: 移位寄存器更新
    always @(posedge clock) begin
        if (reset) begin
            shift_reg_stage2 <= {(WIDTH){1'b0}};
        end
        else begin
            shift_reg_stage2 <= shift_reg_stage1;
        end
    end
    
    // 阶段2: 有效信号更新
    always @(posedge clock) begin
        if (reset) begin
            valid_stage2 <= 1'b0;
        end
        else begin
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出赋值
    assign count = shift_reg_stage2;
    assign valid_out = valid_stage2;
    
endmodule