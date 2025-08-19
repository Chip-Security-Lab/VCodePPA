//SystemVerilog
module shift_add_mult #(parameter WIDTH=4) (
    input clk, rst,
    input [WIDTH-1:0] a, b,
    output reg [2*WIDTH-1:0] product
);
    // 内部寄存器定义
    reg [WIDTH-1:0] multiplier;
    reg [2*WIDTH-1:0] accum;
    reg [WIDTH-1:0] multiplicand;
    reg [2:0] state;
    reg [2:0] bit_count;
    
    // FSM状态参数定义
    localparam IDLE = 3'd0,
               PROCESS = 3'd1,
               DONE = 3'd2;
    
    // 状态转换逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            case(state)
                IDLE: begin
                    state <= PROCESS;
                end
                
                PROCESS: begin
                    if (bit_count == WIDTH-1) 
                        state <= DONE;
                end
                
                DONE: begin
                    state <= IDLE;
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end
    
    // 位计数器控制逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_count <= 0;
        end else begin
            case(state)
                IDLE: begin
                    bit_count <= 0;
                end
                
                PROCESS: begin
                    bit_count <= bit_count + 1;
                end
                
                default: begin
                    bit_count <= bit_count;
                end
            endcase
        end
    end
    
    // 乘法数据路径控制逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            multiplier <= 0;
            multiplicand <= 0;
        end else begin
            case(state)
                IDLE: begin
                    multiplier <= b;
                    multiplicand <= a;
                end
                
                PROCESS: begin
                    multiplier <= multiplier >> 1;
                end
                
                default: begin
                    multiplier <= multiplier;
                    multiplicand <= multiplicand;
                end
            endcase
        end
    end
    
    // 累加器控制逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            accum <= 0;
        end else begin
            case(state)
                IDLE: begin
                    accum <= 0;
                end
                
                PROCESS: begin
                    if (multiplier[0])
                        accum <= accum + (multiplicand << bit_count);
                end
                
                default: begin
                    accum <= accum;
                end
            endcase
        end
    end
    
    // 输出控制逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            product <= 0;
        end else if (state == DONE) begin
            product <= accum;
        end
    end
    
endmodule