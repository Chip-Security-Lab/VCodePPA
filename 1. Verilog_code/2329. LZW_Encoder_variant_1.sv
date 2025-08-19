//SystemVerilog
module LZW_Encoder #(parameter DICT_DEPTH=256) (
    input wire clk,
    input wire en,
    input wire [7:0] data,
    output reg [15:0] code
);
    reg [7:0] dict [0:DICT_DEPTH-1];
    reg [15:0] current_code;
    wire match;
    
    // 使用专用比较器，避免长比较链
    assign match = (dict[current_code] == data);
    
    // 先行进位加法器信号
    wire [15:0] sum;
    wire [15:0] carry_gen;
    wire [15:0] prop;
    wire [16:0] carry;
    
    // 产生进位生成和传播信号
    assign carry_gen = current_code & 16'h0001;
    assign prop = current_code | 16'h0001;
    
    // 先行进位逻辑
    assign carry[0] = 1'b0;
    assign carry[1] = carry_gen[0] | (prop[0] & carry[0]);
    assign carry[2] = carry_gen[1] | (prop[1] & carry[1]);
    assign carry[3] = carry_gen[2] | (prop[2] & carry[2]);
    assign carry[4] = carry_gen[3] | (prop[3] & carry[3]);
    assign carry[5] = carry_gen[4] | (prop[4] & carry[4]);
    assign carry[6] = carry_gen[5] | (prop[5] & carry[5]);
    assign carry[7] = carry_gen[6] | (prop[6] & carry[6]);
    assign carry[8] = carry_gen[7] | (prop[7] & carry[7]);
    assign carry[9] = carry_gen[8] | (prop[8] & carry[8]);
    assign carry[10] = carry_gen[9] | (prop[9] & carry[9]);
    assign carry[11] = carry_gen[10] | (prop[10] & carry[10]);
    assign carry[12] = carry_gen[11] | (prop[11] & carry[11]);
    assign carry[13] = carry_gen[12] | (prop[12] & carry[12]);
    assign carry[14] = carry_gen[13] | (prop[13] & carry[13]);
    assign carry[15] = carry_gen[14] | (prop[14] & carry[14]);
    assign carry[16] = carry_gen[15] | (prop[15] & carry[15]);
    
    // 求和
    assign sum = current_code ^ 16'h0001 ^ {carry[15:0]};
    
    // 重置逻辑
    initial begin
        current_code = 16'd0;
    end
    
    always @(posedge clk) begin
        if (en && match) begin
            // 数据匹配情况，使用先行进位加法器
            current_code <= sum;
        end else if (en && !match) begin
            // 数据不匹配情况
            code <= current_code;
            dict[current_code] <= data;
            current_code <= 16'd0;
        end
    end
endmodule