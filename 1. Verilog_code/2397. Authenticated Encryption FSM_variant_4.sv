//SystemVerilog
module auth_encrypt_fsm #(parameter DATA_WIDTH = 16) (
    input wire clk, rst_l,
    input wire start, data_valid,
    input wire [DATA_WIDTH-1:0] data_in, key, nonce,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg busy, done, auth_ok
);
    // State encoding - 使用独热编码减少组合逻辑深度
    localparam IDLE     = 6'b000001;
    localparam INIT     = 6'b000010;
    localparam PROCESS  = 6'b000100;
    localparam FINALIZE = 6'b001000;
    localparam VERIFY   = 6'b010000;
    localparam COMPLETE = 6'b100000;
    
    reg [5:0] state, next_state;
    reg [DATA_WIDTH-1:0] running_auth;
    
    // 寄存器化输入信号以减少输入端到第一级寄存器之间的延迟
    reg start_r, data_valid_r;
    reg [DATA_WIDTH-1:0] data_in_r, key_r, nonce_r;
    
    // 输入信号寄存化 - 增加使能控制以降低功耗
    always @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            start_r <= 1'b0;
            data_valid_r <= 1'b0;
            data_in_r <= {DATA_WIDTH{1'b0}};
            key_r <= {DATA_WIDTH{1'b0}};
            nonce_r <= {DATA_WIDTH{1'b0}};
        end else begin
            start_r <= start;
            data_valid_r <= data_valid;
            // 仅在需要时捕获输入数据，减少不必要的切换活动
            if (state == IDLE || state == PROCESS) begin
                data_in_r <= data_in;
            end
            if (state == IDLE && start) begin
                key_r <= key;
                nonce_r <= nonce;
            end
        end
    end
    
    // 状态转移逻辑
    always @(posedge clk or negedge rst_l) begin
        if (!rst_l) state <= IDLE;
        else state <= next_state;
    end
    
    // 优化的状态转移逻辑：使用并行比较和独热编码
    always @(*) begin
        // 默认保持当前状态
        next_state = state;
        
        case (1'b1) // 使用并行case检查，提高合成效率
            state[0]: next_state = start_r ? INIT : IDLE;
            state[1]: next_state = PROCESS;
            state[2]: next_state = data_valid_r ? PROCESS : FINALIZE;
            state[3]: next_state = VERIFY;
            state[4]: next_state = COMPLETE;
            state[5]: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end
    
    // 数据处理和输出控制
    reg [DATA_WIDTH-1:0] data_out_next;
    reg busy_next, done_next, auth_ok_next;
    reg [DATA_WIDTH-1:0] running_auth_next;
    wire auth_match; // 预计算比较结果
    
    // 预计算身份验证匹配，减少关键路径长度
    assign auth_match = (running_auth == data_in_r);
    
    // 优化的组合逻辑，使用并行比较结构
    always @(*) begin
        // 默认保持当前值
        busy_next = busy;
        done_next = done;
        auth_ok_next = auth_ok;
        running_auth_next = running_auth;
        data_out_next = data_out;
        
        case (1'b1) // 并行case检查
            state[0]: begin // IDLE
                busy_next = start_r;
                done_next = 1'b0;
            end
            
            state[1]: begin // INIT
                running_auth_next = nonce_r ^ key_r;
            end
            
            state[2]: begin // PROCESS
                if (data_valid_r) begin
                    data_out_next = data_in_r ^ key_r;
                    running_auth_next = running_auth ^ data_in_r;
                end
            end
            
            state[4]: begin // VERIFY
                auth_ok_next = auth_match;
            end
            
            state[5]: begin // COMPLETE
                busy_next = 1'b0;
                done_next = 1'b1;
            end
        endcase
    end
    
    // 寄存器更新 - 带有使能条件以减少功耗
    always @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            busy <= 1'b0;
            done <= 1'b0;
            auth_ok <= 1'b0;
            running_auth <= {DATA_WIDTH{1'b0}};
            data_out <= {DATA_WIDTH{1'b0}};
        end else begin
            busy <= busy_next;
            done <= done_next;
            
            if (state[4]) begin // 仅在VERIFY状态更新auth_ok
                auth_ok <= auth_ok_next;
            end
            
            if (state[1] || (state[2] && data_valid_r)) begin
                // 仅在INIT或PROCESS且有效数据时更新running_auth
                running_auth <= running_auth_next;
            end
            
            if (state[2] && data_valid_r) begin
                // 仅在PROCESS且有效数据时更新data_out
                data_out <= data_out_next;
            end
        end
    end
endmodule