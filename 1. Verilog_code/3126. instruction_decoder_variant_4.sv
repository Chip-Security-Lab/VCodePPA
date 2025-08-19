//SystemVerilog
module instruction_decoder(
    input wire clk,
    input wire reset,
    input wire [15:0] instruction,
    input wire ready,
    output reg [3:0] alu_op,
    output reg [3:0] src_reg,
    output reg [3:0] dst_reg,
    output reg [7:0] immediate,
    output reg mem_read,
    output reg mem_write,
    output reg reg_write,
    output reg immediate_valid
);
    // 状态编码使用独热码以减少毛刺并改善时序
    // 3'b001: IDLE, 3'b010: DECODE, 3'b100: EXECUTE/WRITEBACK
    localparam [2:0] IDLE = 3'b001, DECODE = 3'b010, EXECUTE_WB = 3'b100;
    reg [2:0] state, next_state;

    // 指令格式: [15:12] opcode, [11:8] dst, [7:4] src1, [3:0] src2/immediate
    wire [3:0] opcode = instruction[15:12];
    wire is_memory_op = (opcode == 4'b0100) || (opcode == 4'b0101);
    wire is_immediate_op = (opcode == 4'b0011);
    wire is_reg_write_op = (opcode >= 4'b0001 && opcode <= 4'b0100);

    // 状态转换逻辑 - 时序
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 状态转换逻辑 - 组合
    always @(*) begin
        case (state)
            IDLE:    next_state = ready ? DECODE : IDLE;
            DECODE:  next_state = EXECUTE_WB;
            default: next_state = IDLE; // EXECUTE_WB 状态直接返回 IDLE
        endcase
    end

    // 控制信号生成 - 时序
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            alu_op <= 4'd0;
            src_reg <= 4'd0;
            dst_reg <= 4'd0;
            immediate <= 8'd0;
            mem_read <= 1'b0;
            mem_write <= 1'b0;
            reg_write <= 1'b0;
            immediate_valid <= 1'b0;
        end else begin
            case (next_state)
                IDLE: begin
                    // 清除所有控制信号
                    mem_read <= 1'b0;
                    mem_write <= 1'b0;
                    reg_write <= 1'b0;
                    immediate_valid <= 1'b0;
                end
                
                DECODE: begin
                    // 提取字段
                    alu_op <= opcode;
                    dst_reg <= instruction[11:8];
                    src_reg <= instruction[7:4];
                    immediate <= {4'b0000, instruction[3:0]};
                    
                    // 优化的控制信号生成
                    mem_read <= (opcode == 4'b0100); // LOAD
                    mem_write <= (opcode == 4'b0101); // STORE
                    reg_write <= is_reg_write_op;
                    immediate_valid <= is_immediate_op;
                end
                
                default: begin // EXECUTE_WB
                    // 清除所有控制信号
                    mem_read <= 1'b0;
                    mem_write <= 1'b0;
                    reg_write <= 1'b0;
                    immediate_valid <= 1'b0;
                end
            endcase
        end
    end
endmodule