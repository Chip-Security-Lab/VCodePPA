//SystemVerilog
module int_ctrl_async_fsm #(
    parameter DW = 4
)(
    input wire clk,
    input wire en,
    input wire [DW-1:0] int_req,
    output reg int_valid
);

    // 状态编码
    localparam IDLE = 3'd0;
    localparam REQ_DETECT = 3'd1;
    localparam PRE_VALID = 3'd2;
    localparam VALID = 3'd3;
    localparam POST_VALID = 3'd4;
    
    // 流水线状态寄存器
    reg [2:0] state_stage1;
    reg [2:0] state_stage2;
    
    // 流水线数据寄存器
    reg [DW-1:0] int_req_stage1;
    reg req_detected_stage1;
    reg req_detected_stage2;
    
    // 为高扇出信号添加缓冲寄存器
    reg [2:0] idle_buf1, idle_buf2;  // IDLE状态的缓冲寄存器
    reg b0_stage1, b0_stage2;        // b0(|int_req)信号的缓冲寄存器
    
    // 每个时钟周期更新缓冲寄存器
    always @(posedge clk) begin
        idle_buf1 <= {3{state_stage1 == IDLE}};
        idle_buf2 <= idle_buf1;
        b0_stage1 <= |int_req;
        b0_stage2 <= b0_stage1;
    end
    
    // 流水线第一阶段 - 请求检测
    always @(posedge clk) begin
        if (!en) begin
            state_stage1 <= IDLE;
            int_req_stage1 <= {DW{1'b0}};
            req_detected_stage1 <= 1'b0;
        end else begin
            int_req_stage1 <= int_req;
            
            case (state_stage1)
                IDLE: begin
                    req_detected_stage1 <= b0_stage1;
                    if (b0_stage1) begin
                        state_stage1 <= REQ_DETECT;
                    end
                end
                
                REQ_DETECT: begin
                    state_stage1 <= PRE_VALID;
                end
                
                PRE_VALID: begin
                    state_stage1 <= VALID;
                end
                
                VALID: begin
                    state_stage1 <= POST_VALID;
                end
                
                POST_VALID: begin
                    state_stage1 <= IDLE;
                    req_detected_stage1 <= 1'b0;
                end
                
                default: begin
                    state_stage1 <= IDLE;
                    req_detected_stage1 <= 1'b0;
                end
            endcase
        end
    end
    
    // 流水线第二阶段 - 中断有效信号生成
    always @(posedge clk) begin
        if (!en) begin
            state_stage2 <= IDLE;
            req_detected_stage2 <= 1'b0;
            int_valid <= 1'b0;
        end else begin
            state_stage2 <= state_stage1;
            req_detected_stage2 <= req_detected_stage1;
            
            // 使用状态比较缓冲器
            if (state_stage2 == VALID) begin
                int_valid <= 1'b1;
            end else begin
                int_valid <= 1'b0;
            end
        end
    end

endmodule