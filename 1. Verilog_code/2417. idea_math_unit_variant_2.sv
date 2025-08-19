//SystemVerilog
module idea_math_unit (
    input wire clk,
    input wire rst_n,
    input wire valid_in,
    input wire mul_en,
    input wire [15:0] x, y,
    output wire valid_out,
    output wire [15:0] result
);
    // 减少时钟缓冲区数量并使用有意义的名称
    wire clk_comp, clk_result;
    
    // 优化时钟树，只保留必要的缓冲
    assign clk_comp = clk;
    assign clk_result = clk;
    
    // 统一复位信号处理
    wire rst_n_buf;
    assign rst_n_buf = rst_n;
    
    // Pipeline stage registers
    reg [15:0] x_stage1, y_stage1;
    reg mul_en_stage1;
    reg valid_stage1;
    
    reg [31:0] mul_temp_stage2;
    reg [16:0] add_temp_stage2;
    reg mul_en_stage2;
    reg valid_stage2;
    
    // 减少不必要的缓冲寄存器
    reg [15:0] result_stage3;
    reg valid_stage3;
    
    // Stage 1: Register inputs
    always @(posedge clk_comp or negedge rst_n_buf) begin
        if (!rst_n_buf) begin
            x_stage1 <= 16'h0;
            y_stage1 <= 16'h0;
            mul_en_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
        end else begin
            x_stage1 <= x;
            y_stage1 <= y;
            mul_en_stage1 <= mul_en;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Perform multiplication and addition
    always @(posedge clk_comp or negedge rst_n_buf) begin
        if (!rst_n_buf) begin
            mul_temp_stage2 <= 32'h0;
            add_temp_stage2 <= 17'h0;
            mul_en_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            if (valid_stage1) begin
                mul_temp_stage2 <= x_stage1 * y_stage1;
                add_temp_stage2 <= x_stage1 + y_stage1;
                mul_en_stage2 <= mul_en_stage1;
            end
        end
    end
    
    // 优化比较逻辑和取模运算
    reg [15:0] mul_result, add_result;
    
    // 使用更高效的比较方式计算乘法结果
    always @(*) begin
        if (mul_temp_stage2 == 32'h0) begin
            mul_result = 16'hFFFF;
        end else if (mul_temp_stage2 < 17'h10001) begin
            // 如果乘积小于模数，直接使用乘积低16位
            mul_result = mul_temp_stage2[15:0];
        end else begin
            // 优化取模运算，避免使用昂贵的取模器
            // 将32位乘积分解为 high*2^16 + low，然后利用模运算性质
            mul_result = ((mul_temp_stage2[31:16] << 16) % 17'h10001) + mul_temp_stage2[15:0];
            // 如果结果仍然大于等于模数，再减一次
            if (mul_result >= 16'h10001) begin
                mul_result = mul_result - 16'h10001;
            end
        end
    end
    
    // 优化加法取模运算
    always @(*) begin
        // 加法取模优化：利用16位加法的特性，不需要昂贵的取模器
        if (add_temp_stage2[16]) begin
            // 如果有进位，则结果为低16位 + 1
            add_result = add_temp_stage2[15:0] + 16'h1;
        end else begin
            // 否则直接使用低16位
            add_result = add_temp_stage2[15:0];
        end
    end
    
    // Stage 3: Calculate final result with optimized logic
    always @(posedge clk_result or negedge rst_n_buf) begin
        if (!rst_n_buf) begin
            result_stage3 <= 16'h0;
            valid_stage3 <= 1'b0;
        end else begin
            valid_stage3 <= valid_stage2;
            if (valid_stage2) begin
                result_stage3 <= mul_en_stage2 ? mul_result : add_result;
            end
        end
    end
    
    // Output assignments
    assign result = result_stage3;
    assign valid_out = valid_stage3;
    
endmodule