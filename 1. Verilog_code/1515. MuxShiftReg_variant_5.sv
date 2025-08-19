//SystemVerilog
module MuxShiftReg #(parameter DEPTH=4, WIDTH=8) (
    input clk,
    input rst_n,
    input [1:0] sel,
    input [WIDTH-1:0] din,
    input valid_in,
    output valid_out,
    output reg [WIDTH-1:0] dout
);

    localparam PIPELINE_STAGES = 2;
    reg [WIDTH-1:0] regs [0:DEPTH-1];
    reg [WIDTH-1:0] stage1_regs [0:DEPTH-1];
    reg [1:0] sel_stage1;
    reg valid_stage1;
    
    // 预计算选择信号
    wire is_left_shift = (sel == 2'b00);
    wire is_right_shift = (sel == 2'b01);
    wire is_right_rotate = (sel == 2'b10);
    
    // 阶段1: 优化后的移位逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < DEPTH; i = i + 1) begin
                stage1_regs[i] <= {WIDTH{1'b0}};
            end
            sel_stage1 <= 2'b11;
            valid_stage1 <= 1'b0;
        end
        else begin
            valid_stage1 <= valid_in;
            sel_stage1 <= sel;
            
            // 优化后的移位操作
            if (is_left_shift) begin
                stage1_regs[0] <= din;
                for (integer i = 1; i < DEPTH; i = i + 1)
                    stage1_regs[i] <= regs[i-1];
            end
            else if (is_right_shift) begin
                stage1_regs[DEPTH-1] <= din;
                for (integer i = 0; i < DEPTH-1; i = i + 1)
                    stage1_regs[i] <= regs[i+1];
            end
            else if (is_right_rotate) begin
                stage1_regs[DEPTH-1] <= regs[0];
                for (integer i = 0; i < DEPTH-1; i = i + 1)
                    stage1_regs[i] <= regs[i+1];
            end
            else begin
                for (integer i = 0; i < DEPTH; i = i + 1)
                    stage1_regs[i] <= regs[i];
            end
        end
    end
    
    // 阶段2: 优化后的寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < DEPTH; i = i + 1) begin
                regs[i] <= {WIDTH{1'b0}};
            end
            dout <= {WIDTH{1'b0}};
        end
        else begin
            for (integer i = 0; i < DEPTH; i = i + 1) begin
                regs[i] <= stage1_regs[i];
            end
            dout <= stage1_regs[DEPTH-1];
        end
    end
    
    assign valid_out = valid_stage1;
    
endmodule