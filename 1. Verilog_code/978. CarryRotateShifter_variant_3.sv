//SystemVerilog
module CarryRotateShifter #(parameter WIDTH=8) (
    input wire clk,
    input wire rst_n,
    input wire en,
    input wire valid_in,
    input wire carry_in,
    output wire valid_out,
    output wire carry_out,
    output wire [WIDTH-1:0] data_out
);
    // 流水线寄存器 - 阶段1
    reg valid_stage1;
    reg [WIDTH-1:0] data_stage1;
    reg carry_stage1;
    
    // 流水线寄存器 - 阶段2
    reg valid_stage2;
    reg [WIDTH-1:0] data_stage2;
    reg carry_stage2;
    
    // 带状进位加法器信号
    wire [WIDTH-1:0] sum;
    wire [WIDTH:0] carry;
    
    // 定义中间进位信号
    wire [WIDTH-1:0] p; // 传播信号
    wire [WIDTH-1:0] g; // 生成信号
    
    // 块级进位信号
    wire [WIDTH/4:0] block_carry;
    
    // 输入到带状进位加法器
    wire [WIDTH-1:0] op_a;
    wire [WIDTH-1:0] op_b;
    
    // 将输入操作数准备为带状进位加法器的输入
    assign op_a = {data_out[WIDTH-2:0], carry_in};
    assign op_b = ~data_out;  // 取反用于模拟先前的借位操作
    
    // 带状进位加法器的初始进位
    assign carry[0] = 1'b0;
    assign block_carry[0] = 1'b0;
    
    // 计算传播和生成信号
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin : gen_pg
            assign p[i] = op_a[i] | op_b[i];
            assign g[i] = op_a[i] & op_b[i];
        end
    endgenerate
    
    // 带状进位加法器实现（每4位一个块）
    generate
        // 计算块内进位
        for(i = 0; i < WIDTH; i = i + 1) begin : gen_bit_carry
            if(i % 4 == 0) begin
                // 块的第一位直接使用块进位
                assign carry[i+1] = g[i] | (p[i] & block_carry[i/4]);
            end else begin
                // 块内的其他位
                assign carry[i+1] = g[i] | (p[i] & carry[i]);
            end
        end
        
        // 计算块间进位
        for(i = 1; i <= WIDTH/4; i = i + 1) begin : gen_block_carry
            wire [3:0] block_p;
            wire [3:0] block_g;
            
            // 获取当前块的传播和生成信号
            assign block_p[0] = p[(i-1)*4];
            assign block_p[1] = p[(i-1)*4+1];
            assign block_p[2] = p[(i-1)*4+2];
            assign block_p[3] = p[(i-1)*4+3];
            
            assign block_g[0] = g[(i-1)*4];
            assign block_g[1] = g[(i-1)*4+1];
            assign block_g[2] = g[(i-1)*4+2];
            assign block_g[3] = g[(i-1)*4+3];
            
            // 计算该块的块级传播和生成
            wire block_pg, block_gg;
            assign block_pg = block_p[0] & block_p[1] & block_p[2] & block_p[3];
            assign block_gg = block_g[3] | 
                             (block_p[3] & block_g[2]) | 
                             (block_p[3] & block_p[2] & block_g[1]) | 
                             (block_p[3] & block_p[2] & block_p[1] & block_g[0]);
            
            // 计算块级进位
            assign block_carry[i] = block_gg | (block_pg & block_carry[i-1]);
        end
    endgenerate
    
    // 计算和
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin : gen_sum
            assign sum[i] = op_a[i] ^ op_b[i] ^ carry[i];
        end
    endgenerate
    
    // 阶段1：接收输入并执行带状进位加法
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage1 <= 1'b0;
            data_stage1 <= {WIDTH{1'b0}};
            carry_stage1 <= 1'b0;
        end else if (en) begin
            valid_stage1 <= valid_in;
            data_stage1 <= sum;
            carry_stage1 <= carry[WIDTH];
        end
    end
    
    // 阶段2：完成处理
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_stage2 <= 1'b0;
            data_stage2 <= {WIDTH{1'b0}};
            carry_stage2 <= 1'b0;
        end else if (en) begin
            valid_stage2 <= valid_stage1;
            data_stage2 <= data_stage1;
            carry_stage2 <= carry_stage1;
        end
    end
    
    // 输出赋值
    assign valid_out = valid_stage2;
    assign data_out = data_stage2;
    assign carry_out = carry_stage2;
    
endmodule