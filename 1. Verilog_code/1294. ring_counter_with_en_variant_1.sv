//SystemVerilog
module ring_counter_with_req_ack (
    input clk, req, rst,
    output reg ack,
    output reg [3:0] q
);

    // 增加流水线级数
    localparam STAGES = 4;
    
    // 流水线控制信号
    reg [STAGES-1:0] valid_stage;
    
    // 流水线数据寄存器
    reg [3:0] q_stage1;
    reg [3:0] q_stage2;
    reg [3:0] q_stage3;
    
    // 流水线状态控制
    reg state, next_state;
    localparam IDLE = 1'b0,
               BUSY = 1'b1;
    
    // 状态转换逻辑 - 独立出来减少计算复杂度
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            next_state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (req) begin
                        next_state <= BUSY;
                        state <= next_state;
                    end
                end
                
                BUSY: begin
                    if (!req) begin
                        next_state <= IDLE;
                        state <= next_state;
                    end
                end
            endcase
        end
    end
    
    // 阶段1: 请求处理和计算新的计数值
    always @(posedge clk) begin
        if (rst) begin
            q_stage1 <= 4'b0001;
            valid_stage[0] <= 1'b0;
        end else begin
            valid_stage[0] <= 1'b0;
            
            if (state == IDLE && req) begin
                q_stage1 <= {q[0], q[3:1]};
                valid_stage[0] <= 1'b1;
            end
        end
    end

    // 阶段2: 中间处理阶段1 - 减轻后续阶段负担
    always @(posedge clk) begin
        if (rst) begin
            q_stage2 <= 4'b0000;
            valid_stage[1] <= 1'b0;
        end else begin
            valid_stage[1] <= valid_stage[0];
            
            if (valid_stage[0]) begin
                q_stage2 <= q_stage1;
            end
        end
    end
    
    // 阶段3: 中间处理阶段2 - 进一步分担计算负载
    always @(posedge clk) begin
        if (rst) begin
            q_stage3 <= 4'b0000;
            valid_stage[2] <= 1'b0;
        end else begin
            valid_stage[2] <= valid_stage[1];
            
            if (valid_stage[1]) begin
                q_stage3 <= q_stage2;
            end
        end
    end

    // 阶段4: 输出生成
    always @(posedge clk) begin
        if (rst) begin
            q <= 4'b0001;
            ack <= 1'b0;
            valid_stage[3] <= 1'b0;
        end else begin
            valid_stage[3] <= valid_stage[2];
            
            if (valid_stage[2]) begin
                q <= q_stage3;
                ack <= 1'b1;
            end else if (state == BUSY && !req) begin
                ack <= 1'b0;
            end
        end
    end
endmodule