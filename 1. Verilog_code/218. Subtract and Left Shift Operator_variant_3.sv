//SystemVerilog
module subtract_shift_left (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    input  wire [2:0]  shift_amount,
    output wire [7:0]  difference,
    output wire [7:0]  shifted_result
);

    // 寄存器定义
    reg [7:0] a_reg;
    reg [7:0] b_reg;
    reg [2:0] shift_amount_reg;
    reg [7:0] diff_reg;
    reg [7:0] shift_reg;
    
    // 计算暂存
    reg [7:0] diff_temp;
    reg [7:0] shift_temp;

    // 添加流水线控制信号
    reg valid_stage1, valid_stage2;

    // 输入寄存器级 - 第一级流水线
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            shift_amount_reg <= 3'b0;
            valid_stage1 <= 1'b0;
        end else begin
            a_reg <= a;
            b_reg <= b;
            shift_amount_reg <= shift_amount;
            valid_stage1 <= 1'b1;
        end
    end

    // 计算阶段优化 - 预计算
    always @(*) begin
        // 使用优化的减法逻辑
        diff_temp = a_reg - b_reg;
        
        // 位移优化 - 使用参数化的移位
        case (shift_amount_reg)
            3'b000: shift_temp = a_reg;
            3'b001: shift_temp = {a_reg[6:0], 1'b0};
            3'b010: shift_temp = {a_reg[5:0], 2'b0};
            3'b011: shift_temp = {a_reg[4:0], 3'b0};
            3'b100: shift_temp = {a_reg[3:0], 4'b0};
            3'b101: shift_temp = {a_reg[2:0], 5'b0};
            3'b110: shift_temp = {a_reg[1:0], 6'b0};
            3'b111: shift_temp = {a_reg[0], 7'b0};
            default: shift_temp = a_reg;
        endcase
    end

    // 第二级流水线 - 计算结果寄存
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            diff_reg <= 8'b0;
            shift_reg <= 8'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            diff_reg <= diff_temp;
            shift_reg <= shift_temp;
            valid_stage2 <= 1'b1;
        end
    end

    // 输出赋值 - 添加使能控制
    assign difference = valid_stage2 ? diff_reg : 8'b0;
    assign shifted_result = valid_stage2 ? shift_reg : 8'b0;

endmodule