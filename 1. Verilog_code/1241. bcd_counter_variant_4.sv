//SystemVerilog
module bcd_counter (
    input clock, clear_n,
    output reg [3:0] bcd,
    output reg carry
);
    // 内部信号定义
    reg [3:0] p, g;
    reg [1:0] carry_chain_stage1;
    wire [3:0] next_bcd;
    wire [3:0] carry_chain;
    wire reset_condition;
    
    // 第一级流水线 - 存储生成和传播信号
    always @(posedge clock or negedge clear_n) begin
        if (!clear_n) begin
            p <= 4'b0000;
            g <= 4'b0000;
        end else begin
            // 生成和传播信号
            p[0] <= bcd[0];
            g[0] <= 1'b1; // 因为始终加1
            
            p[1] <= bcd[1];
            g[1] <= bcd[0] & 1'b1;
            
            p[2] <= bcd[2];
            g[2] <= bcd[1] & (bcd[0] & 1'b1);
            
            p[3] <= bcd[3];
            g[3] <= bcd[2] & (bcd[1] & (bcd[0] & 1'b1));
        end
    end
    
    // 第二级流水线 - 前两个进位链计算
    always @(posedge clock or negedge clear_n) begin
        if (!clear_n) begin
            carry_chain_stage1 <= 2'b00;
        end else begin
            carry_chain_stage1[0] <= g[0];
            carry_chain_stage1[1] <= g[1] | (p[1] & g[0]);
        end
    end
    
    // 最终进位链计算
    assign carry_chain[0] = carry_chain_stage1[0];
    assign carry_chain[1] = carry_chain_stage1[1];
    assign carry_chain[2] = g[2] | (p[2] & carry_chain_stage1[1]);
    assign carry_chain[3] = g[3] | (p[3] & carry_chain[2]);
    
    // 计算下一个BCD值
    assign next_bcd[0] = ~bcd[0];
    assign next_bcd[1] = bcd[1] ^ carry_chain[0];
    assign next_bcd[2] = bcd[2] ^ carry_chain[1];
    assign next_bcd[3] = bcd[3] ^ carry_chain[2];
    
    // 检测是否达到9并需要复位
    assign reset_condition = (bcd == 4'd9);
    
    // 时序逻辑
    always @(posedge clock or negedge clear_n) begin
        if (!clear_n) begin
            bcd <= 4'd0;
            carry <= 1'b0;
        end else begin
            if (reset_condition) begin
                bcd <= 4'd0;
                carry <= 1'b1;
            end else begin
                bcd <= next_bcd;
                carry <= 1'b0;
            end
        end
    end
endmodule