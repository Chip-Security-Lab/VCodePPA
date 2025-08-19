//SystemVerilog
//IEEE 1364-2005
module ripple_counter (
    input wire clk, rst_n,
    output wire [3:0] q
);
    wire [3:0] q_internal;
    wire [3:0] clk_array;
    wire [3:0] q_next;
    reg [3:0] q_internal_reg;
    reg [3:0] q_output_reg;
    
    // 时钟信号网络 - 使用线网而非先寄存再使用
    assign clk_array[0] = clk;
    assign clk_array[1] = q_internal[0];
    assign clk_array[2] = q_internal[1];
    assign clk_array[3] = q_internal[2];
    
    // 预计算下一状态 - 将寄存器前推
    assign q_next[0] = ~q_internal_reg[0];
    assign q_next[1] = ~q_internal_reg[1];
    assign q_next[2] = ~q_internal_reg[2];
    assign q_next[3] = ~q_internal_reg[3];
    
    // 移动后的寄存器 - 使用单一时钟域以减少不同时钟域带来的复杂性
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_internal_reg[0] <= 1'b0;
        end else begin
            q_internal_reg[0] <= q_next[0];
        end
    end
    
    // 其他位的寄存器逻辑 - 保持原始功能
    genvar i;
    generate
        for (i = 1; i < 4; i = i + 1) begin: counter_stages
            always @(posedge clk_array[i-1] or negedge rst_n) begin
                if (!rst_n)
                    q_internal_reg[i] <= 1'b0;
                else
                    q_internal_reg[i] <= q_next[i];
            end
        end
    endgenerate
    
    // 输出寄存器 - 简化了原有的双缓冲结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_output_reg <= 4'b0000;
        end else begin
            q_output_reg <= q_internal_reg;
        end
    end
    
    // 内部连线和输出连接
    assign q_internal = q_internal_reg;
    assign q = q_output_reg;
endmodule