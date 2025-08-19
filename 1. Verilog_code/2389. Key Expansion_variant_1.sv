//SystemVerilog
module key_expansion #(parameter KEY_WIDTH = 32, EXPANDED_WIDTH = 128) (
    input wire clk, rst_n,
    input wire key_load,
    input wire [KEY_WIDTH-1:0] key_in,
    output reg [EXPANDED_WIDTH-1:0] expanded_key,
    output reg key_ready
);
    reg [2:0] stage;
    reg [KEY_WIDTH-1:0] key_reg;
    
    // Signals for conditional inverting subtractor
    wire [2:0] subtractor_a, subtractor_b;
    wire [2:0] subtractor_result;
    wire borrow_out;
    
    // 优化：预计算key变换结果
    wire [KEY_WIDTH-1:0] key_transform_stage1, key_transform_stage2, key_transform_stage3, key_transform_stage4;
    
    // Assign input values for subtractor
    assign subtractor_a = stage;
    assign subtractor_b = 3'd5;  // Comparing with 5
    
    // Conditional inverting subtractor implementation
    wire [2:0] inverted_b;
    wire [3:0] temp_sum;
    wire cin;
    
    assign inverted_b = ~subtractor_b;
    assign cin = 1'b1; // Add 1 for two's complement
    assign temp_sum = {1'b0, subtractor_a} + {1'b0, inverted_b} + cin;
    assign subtractor_result = temp_sum[2:0];
    assign borrow_out = ~temp_sum[3]; // Borrow out is inverted carry
    
    // 优化：预计算各阶段的key变换
    assign key_transform_stage1 = key_reg ^ {key_reg[KEY_WIDTH-9:0], key_reg[KEY_WIDTH-1:KEY_WIDTH-8]} ^ {8'h01, 24'h0};
    assign key_transform_stage2 = key_reg ^ {key_reg[KEY_WIDTH-9:0], key_reg[KEY_WIDTH-1:KEY_WIDTH-8]} ^ {8'h02, 24'h0};
    assign key_transform_stage3 = key_reg ^ {key_reg[KEY_WIDTH-9:0], key_reg[KEY_WIDTH-1:KEY_WIDTH-8]} ^ {8'h04, 24'h0};
    assign key_transform_stage4 = key_reg ^ {key_reg[KEY_WIDTH-9:0], key_reg[KEY_WIDTH-1:KEY_WIDTH-8]} ^ {8'h08, 24'h0};
    
    // 阶段控制信号
    reg stage1_valid, stage2_valid, stage3_valid, stage4_valid;
    
    always @(posedge clk) begin
        if (!rst_n) begin
            stage <= 0;
            key_ready <= 0;
            stage1_valid <= 0;
            stage2_valid <= 0;
            stage3_valid <= 0;
            stage4_valid <= 0;
            expanded_key <= 0;
        end else if (key_load) begin
            key_reg <= key_in;
            stage <= 1;
            key_ready <= 0;
            stage1_valid <= 0;
            stage2_valid <= 0;
            stage3_valid <= 0;
            stage4_valid <= 0;
        end else if (~borrow_out) begin  // Using subtractor result: stage < 5
            // 重定时：激活各个阶段的有效信号，而不是直接写入扩展密钥
            if (stage == 1) stage1_valid <= 1;
            if (stage == 2) stage2_valid <= 1;
            if (stage == 3) stage3_valid <= 1;
            if (stage == 4) begin
                stage4_valid <= 1;
                key_ready <= 1;
            end
            stage <= stage + 1;
        end
    end
    
    // 重定时：根据有效信号寄存预计算的值到输出寄存器
    always @(posedge clk) begin
        if (!rst_n) begin
            expanded_key <= 0;
        end else begin
            if (stage1_valid) expanded_key[0 +: KEY_WIDTH] <= key_transform_stage1;
            if (stage2_valid) expanded_key[KEY_WIDTH +: KEY_WIDTH] <= key_transform_stage2;
            if (stage3_valid) expanded_key[2*KEY_WIDTH +: KEY_WIDTH] <= key_transform_stage3;
            if (stage4_valid) expanded_key[3*KEY_WIDTH +: KEY_WIDTH] <= key_transform_stage4;
        end
    end
endmodule