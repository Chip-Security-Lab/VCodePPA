//SystemVerilog
module crc_serial_encoder #(parameter DW=16)(
    input clk, rst_n, en,
    input [DW-1:0] data_in,
    output reg serial_out
);
    reg [4:0] crc_reg;
    reg [DW+4:0] shift_reg;
    
    // 定义控制状态
    reg [1:0] ctrl_state;
    
    // 带状进位加法器相关信号
    wire [4:0] xor_result;
    wire [4:0] csa_sum;
    wire [4:0] carry_select;
    wire [4:0] carry0, carry1;
    wire [4:0] sum0, sum1;
    
    // 控制状态逻辑
    always @(*) begin
        // 构建控制状态变量
        // 00: 复位状态，01: 使能状态，10: 移位状态
        ctrl_state = {rst_n, en};
    end
    
    // 计算XOR结果
    assign xor_result = crc_reg ^ shift_reg[DW+4:DW];
    
    // 带状进位加法器实现
    // 预计算两种进位情况
    assign {carry0[0], sum0[0]} = xor_result[0] + 1'b0;
    assign {carry1[0], sum1[0]} = xor_result[0] + 1'b1;
    
    genvar i;
    generate
        for (i = 1; i < 5; i = i + 1) begin : CSA_BLOCK
            assign {carry0[i], sum0[i]} = xor_result[i] + carry0[i-1];
            assign {carry1[i], sum1[i]} = xor_result[i] + carry1[i-1];
        end
    endgenerate
    
    // 进位选择逻辑
    assign carry_select[0] = 1'b0;
    assign carry_select[1] = carry0[0];
    assign carry_select[2] = carry0[1];
    assign carry_select[3] = carry0[2];
    assign carry_select[4] = carry0[3];
    
    // 最终结果选择
    assign csa_sum = {
        carry_select[4] ? sum1[4] : sum0[4],
        carry_select[3] ? sum1[3] : sum0[3],
        carry_select[2] ? sum1[2] : sum0[2],
        carry_select[1] ? sum1[1] : sum0[1],
        sum0[0]
    };
    
    // 主状态机逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 0;
            crc_reg <= 5'h1F;
            serial_out <= 1'b0;
        end else begin
            case (ctrl_state)
                2'b01: begin // 使能状态 (rst_n=1, en=1)
                    shift_reg <= {data_in, crc_reg};
                    crc_reg <= csa_sum; // 使用带状进位加法器结果
                end
                2'b10, 2'b00: begin // 移位状态 (rst_n=1, en=0)
                    shift_reg <= shift_reg << 1;
                    serial_out <= shift_reg[DW+4];
                end
                default: begin // 安全处理
                    shift_reg <= shift_reg;
                    crc_reg <= crc_reg;
                    serial_out <= serial_out;
                end
            endcase
        end
    end
endmodule