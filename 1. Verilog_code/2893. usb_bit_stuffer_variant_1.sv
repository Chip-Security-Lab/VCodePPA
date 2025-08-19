//SystemVerilog
module usb_bit_stuffer(
    input wire clk_i,
    input wire rst_i,
    input wire bit_i,
    input wire valid_i,
    output reg bit_o,
    output reg valid_o,
    output reg stuffed_o
);
    localparam MAX_ONES = 6;
    
    // 将组合逻辑分为两级流水线
    reg [2:0] ones_count;
    reg bit_i_pipe;
    reg valid_i_pipe;
    reg stuff_needed;
    
    // Brent-Kung加法器信号
    wire [2:0] p_gen, g_gen;    // 生成和传播信号
    wire [2:0] g_prop;          // 组传播信号
    wire [2:0] sum;             // 求和结果
    
    // 计算生成和传播信号
    assign p_gen[0] = ones_count[0] ^ 1'b1;
    assign p_gen[1] = ones_count[1];
    assign p_gen[2] = ones_count[2];
    
    assign g_gen[0] = ones_count[0] & 1'b1;
    assign g_gen[1] = ones_count[1] & 0;
    assign g_gen[2] = ones_count[2] & 0;
    
    // Brent-Kung树状结构计算进位
    assign g_prop[0] = g_gen[0];
    assign g_prop[1] = g_gen[1] | (p_gen[1] & g_prop[0]);
    assign g_prop[2] = g_gen[2] | (p_gen[2] & g_prop[1]);
    
    // 计算求和结果
    assign sum[0] = p_gen[0] ^ 1'b0;
    assign sum[1] = p_gen[1] ^ g_prop[0];
    assign sum[2] = p_gen[2] ^ g_prop[1];
    
    // 第一级流水线：计算下一个ones_count并确定是否需要位填充
    always @(posedge clk_i) begin
        if (rst_i) begin
            ones_count <= 3'd0;
            bit_i_pipe <= 1'b0;
            valid_i_pipe <= 1'b0;
            stuff_needed <= 1'b0;
        end else begin
            bit_i_pipe <= bit_i;
            valid_i_pipe <= valid_i;
            
            if (valid_i) begin
                if (bit_i == 1'b1) begin
                    // 使用Brent-Kung加法器计算ones_count + 1
                    ones_count <= sum;
                    stuff_needed <= (sum == MAX_ONES-2);
                end else begin
                    ones_count <= 3'd0;
                    stuff_needed <= 1'b0;
                end
            end
        end
    end
    
    // 第二级流水线：根据之前的计算结果生成输出
    always @(posedge clk_i) begin
        if (rst_i) begin
            bit_o <= 1'b0;
            valid_o <= 1'b0;
            stuffed_o <= 1'b0;
        end else if (valid_i_pipe) begin
            if (stuff_needed) begin
                bit_o <= 1'b0; 
                valid_o <= 1'b1;
                stuffed_o <= 1'b1;
            end else begin
                bit_o <= bit_i_pipe;
                valid_o <= 1'b1;
                stuffed_o <= 1'b0;
            end
        end else begin
            valid_o <= 1'b0;
            stuffed_o <= 1'b0;
        end
    end
    
endmodule