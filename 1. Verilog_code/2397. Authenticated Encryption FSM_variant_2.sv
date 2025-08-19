//SystemVerilog
module auth_encrypt_fsm #(parameter DATA_WIDTH = 16) (
    input wire clk, rst_l,
    input wire start, data_valid,
    input wire [DATA_WIDTH-1:0] data_in, key, nonce,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg busy, done, auth_ok
);
    // 状态编码 - 使用one-hot编码减少状态解码逻辑深度
    localparam IDLE     = 6'b000001;
    localparam INIT     = 6'b000010;
    localparam PROCESS  = 6'b000100;
    localparam FINALIZE = 6'b001000;
    localparam VERIFY   = 6'b010000;
    localparam COMPLETE = 6'b100000;
    
    reg [5:0] state, next_state;
    reg [DATA_WIDTH-1:0] running_auth;
    reg [DATA_WIDTH-1:0] key_nonce_xor; // 预计算常量表达式
    reg [DATA_WIDTH-1:0] data_in_reg; // 寄存数据输入
    reg [DATA_WIDTH-1:0] key_reg; // 寄存密钥
    reg data_valid_reg; // 寄存数据有效信号
    
    wire [DATA_WIDTH-1:0] xor_result; // 提前计算XOR结果
    wire auth_compare_result; // 提前计算验证结果
    
    // 使用补码加法实现减法所需的信号
    wire [DATA_WIDTH-1:0] data_in_neg; // data_in_reg的补码
    wire [DATA_WIDTH-1:0] sub_result;  // 减法结果
    
    // 计算data_in_reg的补码 (取反加一)
    assign data_in_neg = ~data_in_reg + 1'b1;
    
    // 使用补码加法实现验证比较 (running_auth - data_in_reg == 0)
    assign sub_result = running_auth + data_in_neg;
    assign auth_compare_result = (sub_result == {DATA_WIDTH{1'b0}});
    
    // 重设寄存器逻辑
    always @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 优化状态转换逻辑，使用并行结构减少关键路径
    always @(*) begin
        // 默认保持当前状态
        next_state = state;
        
        // 每个状态的转换条件独立判断，减少级联逻辑
        if (state[0] && start)           next_state = INIT;     // IDLE -> INIT
        if (state[1])                    next_state = PROCESS;  // INIT -> PROCESS
        if (state[2] && !data_valid_reg) next_state = FINALIZE; // PROCESS -> FINALIZE
        if (state[3])                    next_state = VERIFY;   // FINALIZE -> VERIFY
        if (state[4])                    next_state = COMPLETE; // VERIFY -> COMPLETE
        if (state[5])                    next_state = IDLE;     // COMPLETE -> IDLE
    end
    
    // 输入寄存逻辑 - 将输入数据寄存，降低输入到逻辑的路径延迟
    always @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            data_in_reg <= {DATA_WIDTH{1'b0}};
            key_reg <= {DATA_WIDTH{1'b0}};
            data_valid_reg <= 1'b0;
        end else begin
            data_in_reg <= data_in;
            key_reg <= key;
            data_valid_reg <= data_valid;
        end
    end
    
    // 组合逻辑提前计算 - 将计算移到寄存器前
    assign xor_result = data_in_reg ^ key_reg;
    
    // 优化数据处理逻辑
    always @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            busy <= 1'b0;
            done <= 1'b0;
            auth_ok <= 1'b0;
            running_auth <= {DATA_WIDTH{1'b0}};
            key_nonce_xor <= {DATA_WIDTH{1'b0}};
            data_out <= {DATA_WIDTH{1'b0}};
        end else begin
            // 状态相关逻辑处理
            if (state[0]) begin         // IDLE
                busy <= start;          // 直接赋值，减少逻辑层级
                done <= 1'b0;
                if (start) begin
                    key_nonce_xor <= nonce ^ key; // 预计算，减少INIT阶段的关键路径
                end
            end
            
            if (state[1]) begin         // INIT
                running_auth <= key_nonce_xor; // 使用预计算的值
            end
            
            if (state[2] && data_valid_reg) begin // PROCESS with valid data
                // 使用提前计算的XOR结果
                data_out <= xor_result;
                running_auth <= running_auth ^ data_in_reg;
            end
            
            if (state[4]) begin         // VERIFY
                // 使用基于补码加法的比较结果
                auth_ok <= auth_compare_result;
            end
            
            if (state[5]) begin         // COMPLETE
                busy <= 1'b0;
                done <= 1'b1;
            end
        end
    end
endmodule