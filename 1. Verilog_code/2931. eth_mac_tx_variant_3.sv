//SystemVerilog
module eth_mac_tx #(parameter DATA_WIDTH = 8) (
    input wire clk,
    input wire rst_n,
    input wire tx_en,
    input wire [DATA_WIDTH-1:0] tx_data,
    input wire [47:0] src_mac,
    input wire [47:0] dst_mac,
    output reg [DATA_WIDTH-1:0] phy_tx_data,
    output reg phy_tx_en
);
    localparam IDLE = 2'b00, PREAMBLE = 2'b01, HEADER = 2'b10, PAYLOAD = 2'b11;
    reg [1:0] state, next_state;
    reg [3:0] byte_cnt;
    wire [3:0] byte_cnt_next;
    
    // Kogge-Stone加法器实现
    kogge_stone_adder #(
        .WIDTH(4)
    ) byte_cnt_adder (
        .a(byte_cnt),
        .b(4'b0001),
        .cin(1'b0),
        .sum(byte_cnt_next),
        .cout()
    );
    
    // 状态寄存器更新
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // 字节计数器控制
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            byte_cnt <= 4'b0000;
        end else if (state == PREAMBLE || state == HEADER) begin
            byte_cnt <= byte_cnt_next;
        end
    end
    
    // PHY发送使能控制
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            phy_tx_en <= 1'b0;
        end else if (state == PREAMBLE) begin
            phy_tx_en <= 1'b1;
        end else if (state == IDLE) begin
            phy_tx_en <= 1'b0;
        end
    end
    
    // PHY发送数据控制
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            phy_tx_data <= {DATA_WIDTH{1'b0}};
        end else if (state == PREAMBLE) begin
            phy_tx_data <= (byte_cnt < 7) ? 8'h55 : 8'hD5;
        end else if (state == HEADER) begin
            phy_tx_data <= (byte_cnt < 6) ? dst_mac[8*(5-byte_cnt) +: 8] : 
                           (byte_cnt < 12) ? src_mac[8*(11-byte_cnt) +: 8] : tx_data;
        end
    end
    
    // 状态转换逻辑
    always @(*) begin
        case (state)
            IDLE: begin
                next_state = tx_en ? PREAMBLE : IDLE;
            end
            PREAMBLE: begin
                next_state = (byte_cnt == 4'd7) ? HEADER : PREAMBLE;
            end
            HEADER: begin
                next_state = (byte_cnt >= 4'd13) ? PAYLOAD : HEADER;
            end
            PAYLOAD: begin
                next_state = tx_en ? PAYLOAD : IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end
endmodule

// Kogge-Stone加法器 - 顶层模块
module kogge_stone_adder #(
    parameter WIDTH = 48
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin,
    output wire [WIDTH-1:0] sum,
    output wire cout
);
    wire [WIDTH-1:0] p, g;
    wire [WIDTH-1:0] p_stage[0:$clog2(WIDTH)-1];
    wire [WIDTH-1:0] g_stage[0:$clog2(WIDTH)-1];
    
    // 生成传播(P)和生成(G)信号
    genvar i, j, k;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_pg
            assign p[i] = a[i] ^ b[i];
            assign g[i] = a[i] & b[i];
        end
        
        // 初始阶段
        for (i = 0; i < WIDTH; i = i + 1) begin: stage0
            if (i == 0) begin
                assign p_stage[0][i] = p[i];
                assign g_stage[0][i] = g[i] | (p[i] & cin);
            end else begin
                assign p_stage[0][i] = p[i];
                assign g_stage[0][i] = g[i];
            end
        end
        
        // 并行前缀计算阶段
        for (i = 1; i < $clog2(WIDTH); i = i + 1) begin: stage
            for (j = 0; j < WIDTH; j = j + 1) begin: position
                if (j < (1 << (i-1))) begin
                    // 保持前面的位不变
                    assign p_stage[i][j] = p_stage[i-1][j];
                    assign g_stage[i][j] = g_stage[i-1][j];
                end else begin
                    // 计算当前阶段的P和G
                    wire [WIDTH-1:0] k_distance;
                    assign k_distance = j - (1 << (i-1));
                    assign p_stage[i][j] = p_stage[i-1][j] & p_stage[i-1][k_distance];
                    assign g_stage[i][j] = g_stage[i-1][j] | (p_stage[i-1][j] & g_stage[i-1][k_distance]);
                end
            end
        end
        
        // 计算最终的和与进位
        for (i = 0; i < WIDTH; i = i + 1) begin: sum_gen
            if (i == 0) begin
                assign sum[i] = p[i] ^ cin;
            end else begin
                assign sum[i] = p[i] ^ g_stage[$clog2(WIDTH)-1][i-1];
            end
        end
        
        assign cout = g_stage[$clog2(WIDTH)-1][WIDTH-1];
    endgenerate
endmodule