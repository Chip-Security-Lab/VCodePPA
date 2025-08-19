//SystemVerilog
module frame_assembler #(parameter DATA_W=8, HEADER=8'hAA) (
    input clk, rst, en,
    input [DATA_W-1:0] payload,
    output reg [DATA_W-1:0] frame_out,
    output reg frame_valid,
    // 新增流水线控制信号
    output reg ready_for_input,
    input next_stage_ready
);
    // 流水线状态控制
    reg [1:0] state_stage1;
    reg [1:0] state_stage2;
    reg [1:0] state_stage3;
    
    // 数据流水线寄存器
    reg [DATA_W-1:0] payload_captured;  // 捕获的输入数据
    reg [DATA_W-1:0] frame_out_stage1;
    reg [DATA_W-1:0] frame_out_stage2;
    
    // 控制信号流水线寄存器
    reg frame_valid_stage1;
    reg frame_valid_stage2;
    reg en_captured;  // 捕获的使能信号
    
    // 直接捕获输入信号，减少输入到第一级寄存器的延迟
    reg [DATA_W-1:0] payload_direct;
    reg en_direct;
    
    // 直接捕获输入信号
    always @(*) begin
        payload_direct = payload;
        en_direct = en;
    end
    
    // 第一级流水线 - 状态更新和输入捕获
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage1 <= 0;
            payload_captured <= 0;
            en_captured <= 0;
            ready_for_input <= 1;
        end else begin
            if (ready_for_input && (state_stage1 == 0)) begin
                payload_captured <= payload_direct;  // 使用组合逻辑前馈的方式捕获
                en_captured <= en_direct;  // 使用组合逻辑前馈的方式捕获
                if (en_direct) begin  // 使用前馈信号判断
                    state_stage1 <= 1;
                    ready_for_input <= 0;
                end
            end else if (state_stage1 == 2 && next_stage_ready) begin
                state_stage1 <= 0;
                ready_for_input <= 1;
            end else if (state_stage1 != 0 && next_stage_ready) begin
                state_stage1 <= state_stage1 + 1;
            end
        end
    end
    
    // 第二级流水线 - 计算帧输出
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage2 <= 0;
            frame_out_stage1 <= 0;
            frame_valid_stage1 <= 0;
        end else if (next_stage_ready) begin
            state_stage2 <= state_stage1;
            
            case(state_stage1)
                1: begin
                    frame_out_stage1 <= HEADER;
                    frame_valid_stage1 <= 1;
                end
                2: begin
                    frame_out_stage1 <= payload_captured;
                    frame_valid_stage1 <= 1;
                end
                default: begin
                    frame_valid_stage1 <= 0;
                end
            endcase
        end
    end
    
    // 第三级流水线 - 输出寄存
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state_stage3 <= 0;
            frame_out_stage2 <= 0;
            frame_valid_stage2 <= 0;
        end else if (next_stage_ready) begin
            state_stage3 <= state_stage2;
            frame_out_stage2 <= frame_out_stage1;
            frame_valid_stage2 <= frame_valid_stage1;
        end
    end
    
    // 输出赋值
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            frame_out <= 0;
            frame_valid <= 0;
        end else if (next_stage_ready) begin
            frame_out <= frame_out_stage2;
            frame_valid <= frame_valid_stage2;
        end
    end
endmodule