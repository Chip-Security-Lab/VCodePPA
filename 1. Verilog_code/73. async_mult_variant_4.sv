//SystemVerilog
module async_mult (
    input [3:0] A, B,
    output [7:0] P,
    input start,
    output done
);
    // 异步状态机实现
    reg [2:0] state;
    reg [3:0] multiplicand;
    reg [3:0] multiplier;
    reg [7:0] product;
    reg done_reg;
    
    parameter IDLE = 3'b000;
    parameter INIT = 3'b001;
    parameter ADD = 3'b010;
    parameter SHIFT = 3'b011;
    parameter FINISH = 3'b100;
    
    reg [2:0] counter;
    
    // Kogge-Stone加法器相关信号
    wire [3:0] sum;
    wire [3:0] carry;
    wire [3:0] g, p;
    wire [3:0] g_stage1, p_stage1;
    wire [3:0] g_stage2, p_stage2;
    wire [3:0] g_stage3, p_stage3;
    
    // 状态转换逻辑
    always @(state or start or counter or multiplier[0]) begin
        case(state)
            IDLE: state = start ? INIT : IDLE;
            INIT: state = ADD;
            ADD: state = SHIFT;
            SHIFT: state = (counter == 3'b011) ? FINISH : ADD;
            FINISH: state = IDLE;
            default: state = IDLE;
        endcase
    end
    
    // Kogge-Stone加法器实现
    assign g = multiplicand & product[7:4];
    assign p = multiplicand ^ product[7:4];
    
    // 第一级
    assign g_stage1[0] = g[0];
    assign p_stage1[0] = p[0];
    assign g_stage1[1] = g[1] | (p[1] & g[0]);
    assign p_stage1[1] = p[1] & p[0];
    assign g_stage1[2] = g[2] | (p[2] & g[1]);
    assign p_stage1[2] = p[2] & p[1];
    assign g_stage1[3] = g[3] | (p[3] & g[2]);
    assign p_stage1[3] = p[3] & p[2];
    
    // 第二级
    assign g_stage2[0] = g_stage1[0];
    assign p_stage2[0] = p_stage1[0];
    assign g_stage2[1] = g_stage1[1];
    assign p_stage2[1] = p_stage1[1];
    assign g_stage2[2] = g_stage1[2] | (p_stage1[2] & g_stage1[0]);
    assign p_stage2[2] = p_stage1[2] & p_stage1[0];
    assign g_stage2[3] = g_stage1[3] | (p_stage1[3] & g_stage1[1]);
    assign p_stage3[3] = p_stage1[3] & p_stage1[1];
    
    // 第三级
    assign g_stage3[0] = g_stage2[0];
    assign p_stage3[0] = p_stage2[0];
    assign g_stage3[1] = g_stage2[1];
    assign p_stage3[1] = p_stage2[1];
    assign g_stage3[2] = g_stage2[2];
    assign p_stage3[2] = p_stage2[2];
    assign g_stage3[3] = g_stage2[3] | (p_stage2[3] & g_stage2[1]);
    assign p_stage3[3] = p_stage2[3] & p_stage2[1];
    
    // 计算进位和和
    assign carry[0] = 1'b0;
    assign carry[1] = g_stage3[0];
    assign carry[2] = g_stage3[1];
    assign carry[3] = g_stage3[2];
    assign sum = p ^ {carry[2:0], 1'b0};
    
    // 数据处理逻辑
    always @(state) begin
        case(state)
            IDLE: begin
                done_reg = 1'b1;
                counter = 3'b000;
            end
            
            INIT: begin
                multiplicand = A;
                multiplier = B;
                product = 8'b0;
                counter = 3'b000;
                done_reg = 1'b0;
            end
            
            ADD: begin
                if(multiplier[0])
                    product[7:4] = sum;
            end
            
            SHIFT: begin
                multiplier = multiplier >> 1;
                product = product >> 1;
                counter = counter + 1;
            end
            
            FINISH: begin
                done_reg = 1'b1;
            end
        endcase
    end
    
    assign P = product;
    assign done = done_reg;
endmodule