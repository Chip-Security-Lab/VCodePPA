//SystemVerilog
module gcm_auth #(parameter WIDTH = 32) (
    input wire clk, reset_l,
    input wire data_valid, last_block,
    input wire [WIDTH-1:0] data_in, h_key,
    output reg [WIDTH-1:0] auth_tag,
    output reg tag_valid
);
    // 流水线阶段寄存器
    reg [WIDTH-1:0] h_key_stage1, h_key_stage2, h_key_stage3;
    reg data_valid_stage1, data_valid_stage2, data_valid_stage3;
    reg last_block_stage1, last_block_stage2, last_block_stage3;
    reg [WIDTH-1:0] data_in_stage1;
    reg [WIDTH-1:0] accumulated;
    reg [WIDTH-1:0] xor_result_stage2;
    reg [WIDTH-1:0] mult_result_stage3;
    
    // 流水线控制信号
    reg pipeline_active;
    
    // GF(2^128) multiplication (simplified for this example)
    function [WIDTH-1:0] gf_mult(input [WIDTH-1:0] a, b);
        reg [WIDTH-1:0] res;
        reg carry;
        integer i, j;
        begin
            res = 0;
            for (i = 0; i < WIDTH; i = i + 1) begin
                if (a[i]) res = res ^ (b << i);
            end
            // Reduction step (simplified)
            for (j = WIDTH*2-1; j >= WIDTH; j = j - 1) begin
                if (res[j]) res = res ^ (32'h87000000 << (j - WIDTH));
            end
            gf_mult = res;
        end
    endfunction
    
    // 流水线阶段1: 输入寄存和XOR计算准备
    always @(posedge clk or negedge reset_l) begin
        if (!reset_l) begin
            data_in_stage1 <= 0;
            h_key_stage1 <= 0;
            data_valid_stage1 <= 0;
            last_block_stage1 <= 0;
            pipeline_active <= 0;
        end else begin
            data_in_stage1 <= data_in;
            h_key_stage1 <= h_key;
            data_valid_stage1 <= data_valid;
            last_block_stage1 <= last_block;
            
            if (data_valid)
                pipeline_active <= 1;
            else if (last_block_stage3)
                pipeline_active <= 0;
        end
    end
    
    // 流水线阶段2: XOR计算和乘法准备
    always @(posedge clk or negedge reset_l) begin
        if (!reset_l) begin
            xor_result_stage2 <= 0;
            h_key_stage2 <= 0;
            data_valid_stage2 <= 0;
            last_block_stage2 <= 0;
        end else begin
            if (data_valid_stage1) begin
                xor_result_stage2 <= accumulated ^ data_in_stage1;
            end
            h_key_stage2 <= h_key_stage1;
            data_valid_stage2 <= data_valid_stage1;
            last_block_stage2 <= last_block_stage1;
        end
    end
    
    // 流水线阶段3: 执行GF乘法
    always @(posedge clk or negedge reset_l) begin
        if (!reset_l) begin
            mult_result_stage3 <= 0;
            h_key_stage3 <= 0;
            data_valid_stage3 <= 0;
            last_block_stage3 <= 0;
        end else begin
            if (data_valid_stage2) begin
                mult_result_stage3 <= gf_mult(xor_result_stage2, h_key_stage2);
            end
            h_key_stage3 <= h_key_stage2;
            data_valid_stage3 <= data_valid_stage2;
            last_block_stage3 <= last_block_stage2;
        end
    end
    
    // 流水线阶段4: 累积值更新和输出控制
    always @(posedge clk or negedge reset_l) begin
        if (!reset_l) begin
            accumulated <= 0;
            auth_tag <= 0;
            tag_valid <= 0;
        end else begin
            // 累积值更新
            if (data_valid_stage3) begin
                accumulated <= mult_result_stage3;
            end
            
            // 更新输出标签逻辑 - 适应流水线延迟
            tag_valid <= last_block_stage3;
            if (last_block_stage3) begin
                auth_tag <= mult_result_stage3;
            end
        end
    end
endmodule