//SystemVerilog
module fsm_signal_recovery (
    input wire clk, rst_n,
    input wire signal_detect,
    input wire [3:0] signal_value,
    output reg [3:0] recovered_value,
    output reg lock_status
);
    localparam IDLE = 2'b00, DETECT = 2'b01, LOCK = 2'b10, TRACK = 2'b11;
    reg [1:0] state, next_state;
    reg [3:0] counter;
    reg [3:0] multiplier_a, multiplier_b;
    wire [7:0] product;
    
    // 使用优化的Wallace乘法器处理recovered_value
    optimized_wallace_multiplier_4bit wallace_mult (
        .a(multiplier_a),
        .b(multiplier_b),
        .p(product)
    );
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else state <= next_state;
    end
    
    // 状态转换逻辑优化
    always @(*) begin
        next_state = IDLE; // 默认状态，减少case分支中的重复赋值
        
        case (state)
            IDLE:   if (signal_detect) next_state = DETECT;
            DETECT: if (counter >= 4'd8) next_state = LOCK;
                    else next_state = DETECT;
            LOCK,
            TRACK:  if (signal_detect) next_state = TRACK;
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 4'd0;
            recovered_value <= 4'd0;
            lock_status <= 1'b0;
            multiplier_a <= 4'd0;
            multiplier_b <= 4'd0;
        end else begin
            // 默认值设置，减少case分支中的重复赋值
            lock_status <= (state == LOCK || state == TRACK);
            
            case (state)
                IDLE: begin
                    counter <= 4'd0;
                    multiplier_a <= 4'd0;
                    multiplier_b <= 4'd0;
                end
                DETECT: counter <= counter + 1'b1;
                LOCK, TRACK: begin
                    multiplier_a <= signal_value;
                    multiplier_b <= counter[3:0]; 
                    recovered_value <= product[3:0];
                end
            endcase
        end
    end
endmodule

// 优化的4位Wallace乘法器实现
module optimized_wallace_multiplier_4bit (
    input wire [3:0] a,
    input wire [3:0] b,
    output wire [7:0] p
);
    // 部分积生成 - 直接用二维数组提高可读性
    wire [3:0][3:0] pp;
    
    // 生成16个部分积 (4x4)
    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin: gen_i
            for (j = 0; j < 4; j = j + 1) begin: gen_j
                assign pp[i][j] = a[j] & b[i];
            end
        end
    endgenerate
    
    // 第1阶段压缩
    wire s1_0, s1_1, s1_2;
    wire c1_0, c1_1, c1_2;
    
    half_adder ha1(.a(pp[1][0]), .b(pp[0][1]), .s(s1_0), .c(c1_0));
    full_adder fa1(.a(pp[2][0]), .b(pp[1][1]), .cin(pp[0][2]), .s(s1_1), .cout(c1_1));
    half_adder ha2(.a(pp[3][0]), .b(pp[2][1]), .s(s1_2), .c(c1_2));
    
    // 第2阶段压缩
    wire [6:0] s2, c2;
    
    assign p[0] = pp[0][0]; // 直接输出，无需加法
    
    half_adder ha3(.a(s1_0), .b(1'b0), .s(p[1]), .c(c2[0]));
    
    // 优化布尔表达式，减少逻辑门
    wire [5:0] carry;
    
    fast_adder fa2(.a(s1_1), .b(c1_0), .cin(1'b0), .s(p[2]), .cout(carry[0]));
    fast_adder fa3(.a(s1_2), .b(pp[1][2]), .cin(c1_1), .s(s2[3]), .cout(c2[3]));
    fast_adder fa4(.a(pp[3][1]), .b(pp[2][2]), .cin(pp[1][3]), .s(s2[4]), .cout(c2[4]));
    fast_adder fa5(.a(pp[3][2]), .b(pp[2][3]), .cin(1'b0), .s(s2[5]), .cout(c2[5]));
    assign s2[6] = pp[3][3];
    
    // 最终进位传播加法器 - 使用优化的加法器
    fast_adder fa7(.a(s2[3]), .b(c2[0]), .cin(carry[0]), .s(p[3]), .cout(carry[1]));
    fast_adder fa8(.a(s2[4]), .b(c2[3]), .cin(carry[1]), .s(p[4]), .cout(carry[2]));
    fast_adder fa9(.a(s2[5]), .b(c2[4]), .cin(carry[2]), .s(p[5]), .cout(carry[3]));
    fast_adder fa10(.a(s2[6]), .b(c2[5]), .cin(carry[3]), .s(p[6]), .cout(p[7]));
endmodule

// 优化的全加器
module fast_adder (
    input wire a, b, cin,
    output wire s, cout
);
    wire g = a & b;          // 生成信号
    wire p = a ^ b;          // 传播信号
    assign s = p ^ cin;      // 求和位
    assign cout = g | (p & cin); // 进位输出
endmodule

// 半加器
module half_adder (
    input wire a, b,
    output wire s, c
);
    assign s = a ^ b;
    assign c = a & b;
endmodule

// 兼容性保留，但使用优化的实现
module full_adder (
    input wire a, b, cin,
    output wire s, cout
);
    wire g = a & b;
    wire p = a ^ b;
    assign s = p ^ cin;
    assign cout = g | (p & cin);
endmodule