//SystemVerilog
module multi_parity_checker (
    input [1:0] mode,        // 00: no, 01: even, 10: odd, 11: invert
    input [7:0] data,
    input [7:0] multiplier,  // 乘数输入
    input [7:0] multiplicand, // 被乘数输入
    input mult_enable,       // 乘法使能信号
    output reg [1:0] parity,
    output reg [15:0] product // 乘法结果输出
);
    // 奇偶校验线网
    wire even_p = ~^data;
    wire odd_p = ^data;

    // Booth乘法器相关信号
    reg [15:0] booth_product;
    reg [2:0] booth_triplet;
    reg [7:0] neg_multiplicand;
    reg [15:0] partial_product;
    reg [7:0] extended_multiplicand;
    reg [3:0] i;
    
    // 乘法中间结果
    reg [15:0] booth_step_product;
    
    // --------- 奇偶校验逻辑 ---------
    always @(*) begin
        case(mode)
            2'b00: parity = 2'b00;
            2'b01: parity = {even_p, 1'b0};
            2'b10: parity = {odd_p, 1'b1};
            2'b11: parity = {~odd_p, 1'b1};
        endcase
    end

    // --------- Booth乘法初始化 ---------
    always @(*) begin
        if (mult_enable) begin
            // 初始化信号
            neg_multiplicand = -multiplicand;
            extended_multiplicand = multiplicand;
            partial_product = {8'b0, multiplier, 1'b0};
            booth_product = 16'b0;
        end else begin
            neg_multiplicand = 8'b0;
            extended_multiplicand = 8'b0;
            partial_product = 16'b0;
            booth_product = 16'b0;
        end
    end
    
    // --------- Booth乘法第1步 ---------
    always @(*) begin
        if (mult_enable) begin
            // 第1步Booth编码 (i=0)
            booth_triplet = partial_product[2:0];
            
            case (booth_triplet)
                3'b001, 3'b010: booth_step_product = extended_multiplicand;
                3'b011: booth_step_product = (extended_multiplicand << 1);
                3'b100: booth_step_product = (neg_multiplicand << 1);
                3'b101, 3'b110: booth_step_product = neg_multiplicand;
                default: booth_step_product = 16'b0; // 000 或 111
            endcase
        end else begin
            booth_step_product = 16'b0;
        end
    end
    
    // --------- Booth乘法累加逻辑 ---------
    always @(*) begin
        if (mult_enable) begin
            // 累加所有部分积形成最终乘积
            product = booth_product + 
                     // 步骤1的结果
                     booth_step_product +
                     // 步骤2-4的结果
                     booth_steps_234();
        end else begin
            product = 16'b0;
        end
    end
    
    // --------- Booth乘法步骤2-4函数 ---------
    function [15:0] booth_steps_234;
        reg [15:0] result;
        reg [15:0] temp_partial;
        reg [2:0] temp_triplet;
        
        begin
            result = 16'b0;
            temp_partial = partial_product;
            
            // 第2步 (i=1)
            temp_partial = temp_partial >> 2;
            temp_triplet = temp_partial[2:0];
            
            case (temp_triplet)
                3'b001, 3'b010: result = result + (extended_multiplicand << 2);
                3'b011: result = result + ((extended_multiplicand << 1) << 2);
                3'b100: result = result + ((neg_multiplicand << 1) << 2);
                3'b101, 3'b110: result = result + (neg_multiplicand << 2);
                default: result = result; // 000 或 111
            endcase
            
            // 第3步 (i=2)
            temp_partial = temp_partial >> 2;
            temp_triplet = temp_partial[2:0];
            
            case (temp_triplet)
                3'b001, 3'b010: result = result + (extended_multiplicand << 4);
                3'b011: result = result + ((extended_multiplicand << 1) << 4);
                3'b100: result = result + ((neg_multiplicand << 1) << 4);
                3'b101, 3'b110: result = result + (neg_multiplicand << 4);
                default: result = result; // 000 或 111
            endcase
            
            // 第4步 (i=3)
            temp_partial = temp_partial >> 2;
            temp_triplet = temp_partial[2:0];
            
            case (temp_triplet)
                3'b001, 3'b010: result = result + (extended_multiplicand << 6);
                3'b011: result = result + ((extended_multiplicand << 1) << 6);
                3'b100: result = result + ((neg_multiplicand << 1) << 6);
                3'b101, 3'b110: result = result + (neg_multiplicand << 6);
                default: result = result; // 000 或 111
            endcase
            
            booth_steps_234 = result;
        end
    endfunction
    
endmodule