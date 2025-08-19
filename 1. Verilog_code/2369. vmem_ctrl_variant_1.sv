//SystemVerilog
module vmem_ctrl #(parameter AW=12)(
    input  wire clk,
    input  wire rst_n,     // 添加复位信号
    output reg  [AW-1:0] addr,
    output reg  ref_en,
    
    // 流水线控制信号
    input  wire pipe_ready,
    output reg  pipe_valid
);
    // 定义流水线级数和信号
    localparam PIPE_STAGES = 3;
    
    // 计数器信号定义
    reg [15:0] refresh_cnt;
    
    // 流水线阶段寄存器
    reg [15:0] refresh_cnt_stage1, refresh_cnt_stage2;
    reg        ref_en_stage1, ref_en_stage2;
    reg [AW-1:0] addr_stage1, addr_stage2;
    
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    
    // 阶段1: 计数器更新
    always @(posedge clk) begin
        if (!rst_n) begin
            refresh_cnt <= 16'h0;
            valid_stage1 <= 1'b0;
        end else if (pipe_ready) begin
            refresh_cnt <= refresh_cnt + 1'b1;
            valid_stage1 <= 1'b1;
            refresh_cnt_stage1 <= refresh_cnt + 1'b1;
        end
    end
    
    // 阶段2: 刷新判断和地址计算
    always @(posedge clk) begin
        if (!rst_n) begin
            ref_en_stage1 <= 1'b0;
            addr_stage1 <= {AW{1'b0}};
            valid_stage2 <= 1'b0;
        end else if (pipe_ready) begin
            refresh_cnt_stage2 <= refresh_cnt_stage1;
            ref_en_stage1 <= (refresh_cnt_stage1[15:13] == 3'b111);
            addr_stage1 <= (refresh_cnt_stage1[15:13] == 3'b111) ? refresh_cnt_stage1[AW-1:0] : addr_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 阶段3: 输出寄存器
    always @(posedge clk) begin
        if (!rst_n) begin
            ref_en <= 1'b0;
            addr <= {AW{1'b0}};
            pipe_valid <= 1'b0;
        end else if (pipe_ready) begin
            ref_en <= ref_en_stage1;
            addr <= ref_en_stage1 ? addr_stage1 : addr;
            pipe_valid <= valid_stage2;
        end
    end
    
endmodule