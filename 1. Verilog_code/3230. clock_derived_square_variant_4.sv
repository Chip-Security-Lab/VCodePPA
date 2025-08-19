//SystemVerilog
module clock_derived_square(
    input main_clk,
    input reset,
    output reg [3:0] clk_div_out
);
    reg [7:0] div_counter;
    wire [7:0] next_counter;
    
    // Carry Skip Adder implementation for 8-bit addition
    carry_skip_adder csa(
        .a(div_counter),
        .b(8'd1),
        .sum(next_counter)
    );
    
    always @(posedge main_clk) begin
        if (reset) begin
            div_counter <= 8'd0;
            clk_div_out <= 4'b0000;
        end else begin
            div_counter <= next_counter;
            
            // Generate different frequency outputs
            clk_div_out[0] <= next_counter[0];  // Divide by 2
            clk_div_out[1] <= next_counter[1];  // Divide by 4
            clk_div_out[2] <= next_counter[3];  // Divide by 16
            clk_div_out[3] <= next_counter[5];  // Divide by 64
        end
    end
endmodule

module carry_skip_adder(
    input [7:0] a,
    input [7:0] b,
    output [7:0] sum
);
    // 将8位加法器分成2个块，每块4位
    localparam BLOCK_SIZE = 4;
    localparam NUM_BLOCKS = 2;
    
    // 内部连线
    wire [8:0] carry;
    wire [NUM_BLOCKS-1:0] block_propagate;
    
    // 初始进位为0
    assign carry[0] = 1'b0;
    
    // 生成每个块的进位跳跃加法器
    genvar i, j;
    generate
        for (i = 0; i < NUM_BLOCKS; i = i + 1) begin: blocks
            wire [BLOCK_SIZE:0] block_carry;
            wire [BLOCK_SIZE-1:0] p; // 传播信号
            wire [BLOCK_SIZE-1:0] block_sum;
            
            // 块的起始进位连接
            assign block_carry[0] = carry[i*BLOCK_SIZE];
            
            // 块内进位传播逻辑和加法
            for (j = 0; j < BLOCK_SIZE; j = j + 1) begin: bit_ops
                wire a_bit = a[i*BLOCK_SIZE+j];
                wire b_bit = b[i*BLOCK_SIZE+j];
                
                // 生成传播信号
                assign p[j] = a_bit ^ b_bit;
                
                // 进位计算
                assign block_carry[j+1] = (a_bit & b_bit) | (p[j] & block_carry[j]);
                
                // 计算和
                assign block_sum[j] = p[j] ^ block_carry[j];
            end
            
            // 计算块传播信号 (所有位都是传播)
            assign block_propagate[i] = &p;
            
            // 进位跳跃逻辑: 如果整个块都是传播，则直接跳过该块
            assign carry[(i+1)*BLOCK_SIZE] = block_propagate[i] ? 
                                             carry[i*BLOCK_SIZE] : 
                                             block_carry[BLOCK_SIZE];
            
            // 连接该块的和到最终结果
            assign sum[i*BLOCK_SIZE +: BLOCK_SIZE] = block_sum;
        end
    endgenerate
endmodule