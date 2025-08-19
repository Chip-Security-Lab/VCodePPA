//SystemVerilog
// IEEE 1364-2005
module GatedClockShift #(parameter BITS=8) (
    input clk,        // 系统时钟
    input rst_n,      // 异步复位，低电平有效
    input en,         // 使能信号
    input s_in,       // 串行输入
    input i_valid,    // 输入有效信号
    output o_valid,   // 输出有效信号
    output o_ready,   // 输出就绪信号
    output reg [BITS-1:0] q // 并行输出
);
    // 流水线控制信号
    reg valid_stage1, valid_stage2;
    reg [BITS-1:0] q_stage1;
    
    // 流水线就绪信号 - 始终准备接收新数据
    assign o_ready = 1'b1;
    
    // 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q_stage1 <= {BITS{1'b0}};
            valid_stage1 <= 1'b0;
        end 
        else if (en) begin
            q_stage1 <= {q[BITS-2:0], s_in};
            valid_stage1 <= i_valid;
        end
    end
    
    // 第二级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            q <= {BITS{1'b0}};
            valid_stage2 <= 1'b0;
        end 
        else if (en) begin
            q <= q_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 输出有效信号
    assign o_valid = valid_stage2;
endmodule

module BorrowSubtractor #(parameter WIDTH=8) (
    input clk,                  // 系统时钟
    input rst_n,                // 异步复位，低电平有效
    input i_valid,              // 输入有效信号
    input [WIDTH-1:0] a, b,     // 输入操作数
    output o_valid,             // 输出有效信号
    output o_ready,             // 输出就绪信号
    output [WIDTH-1:0] diff,    // 差值输出
    output borrow_out           // 借位输出
);
    // 定义流水线寄存器和控制信号
    reg valid_stage1, valid_stage2, valid_stage3;
    reg [WIDTH-1:0] a_stage1, b_stage1;
    reg [WIDTH-1:0] a_stage2, b_stage2;
    reg [WIDTH-1:0] diff_stage2, diff_stage3;
    reg [WIDTH:0] borrow_stage1, borrow_stage2;
    
    // 流水线就绪信号 - 始终准备接收新数据
    assign o_ready = 1'b1;
    
    // 第一级流水线 - 输入寄存和低半部分计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage1 <= {WIDTH{1'b0}};
            b_stage1 <= {WIDTH{1'b0}};
            borrow_stage1 <= {(WIDTH+1){1'b0}};
            valid_stage1 <= 1'b0;
        end
        else begin
            a_stage1 <= a;
            b_stage1 <= b;
            borrow_stage1[0] <= 1'b0;
            
            // 计算低半部分的借位和差值
            for (int i = 0; i < WIDTH/2; i = i + 1) begin
                // 这里没有直接赋值到diff，因为diff是最终的输出，会在第三级设置
                borrow_stage1[i+1] <= (~a[i] & b[i]) | (~a[i] & borrow_stage1[i]) | (b[i] & borrow_stage1[i]);
            end
            
            valid_stage1 <= i_valid;
        end
    end
    
    // 第二级流水线 - 高半部分计算
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_stage2 <= {WIDTH{1'b0}};
            b_stage2 <= {WIDTH{1'b0}};
            borrow_stage2 <= {(WIDTH+1){1'b0}};
            diff_stage2 <= {WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
        end
        else begin
            a_stage2 <= a_stage1;
            b_stage2 <= b_stage1;
            borrow_stage2 <= borrow_stage1;
            
            // 计算低半部分的差值
            for (int i = 0; i < WIDTH/2; i = i + 1) begin
                diff_stage2[i] <= a_stage1[i] ^ b_stage1[i] ^ borrow_stage1[i];
            end
            
            // 计算高半部分的借位和差值
            for (int i = WIDTH/2; i < WIDTH; i = i + 1) begin
                borrow_stage2[i+1] <= (~a_stage1[i] & b_stage1[i]) | 
                                       (~a_stage1[i] & borrow_stage2[i]) | 
                                       (b_stage1[i] & borrow_stage2[i]);
            end
            
            valid_stage2 <= valid_stage1;
        end
    end
    
    // 第三级流水线 - 完成高半部分差值计算并输出
    reg [WIDTH-1:0] diff_reg;
    reg borrow_out_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_reg <= {WIDTH{1'b0}};
            borrow_out_reg <= 1'b0;
            valid_stage3 <= 1'b0;
        end
        else begin
            // 低半部分直接从第二级传递
            diff_reg[WIDTH/2-1:0] <= diff_stage2[WIDTH/2-1:0];
            
            // 计算高半部分的差值
            for (int i = WIDTH/2; i < WIDTH; i = i + 1) begin
                diff_reg[i] <= a_stage2[i] ^ b_stage2[i] ^ borrow_stage2[i];
            end
            
            borrow_out_reg <= borrow_stage2[WIDTH];
            valid_stage3 <= valid_stage2;
        end
    end
    
    // 输出赋值
    assign diff = diff_reg;
    assign borrow_out = borrow_out_reg;
    assign o_valid = valid_stage3;
endmodule