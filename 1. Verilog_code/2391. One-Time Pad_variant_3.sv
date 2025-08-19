//SystemVerilog
module one_time_pad #(parameter WIDTH = 24) (
    input wire clk, reset_n,
    input wire activate, new_key,
    input wire [WIDTH-1:0] data_input, key_input,
    output reg [WIDTH-1:0] data_output,
    output reg ready
);
    reg [WIDTH-1:0] current_key;
    reg [WIDTH-1:0] data_input_reg;
    reg activate_reg, new_key_reg;
    
    // 优化的条件求和减法器信号
    reg [WIDTH-1:0] subtract_result;
    wire [WIDTH:0] borrow;
    
    // 第一阶段：寄存输入
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_input_reg <= 0;
            activate_reg <= 0;
            new_key_reg <= 0;
        end else begin
            data_input_reg <= data_input;
            activate_reg <= activate;
            new_key_reg <= new_key;
        end
    end
    
    // 优化的条件求和减法算法
    // 使用生成赋值替代循环，提高并行性
    assign borrow[0] = 1'b0;
    
    genvar g;
    generate
        for (g = 0; g < WIDTH; g = g + 1) begin : gen_subtract
            assign subtract_result[g] = data_input_reg[g] ^ current_key[g] ^ borrow[g];
            assign borrow[g+1] = (~data_input_reg[g] & (current_key[g] | borrow[g])) | (current_key[g] & borrow[g]);
        end
    endgenerate
    
    // 第二阶段：使用寄存的输入进行处理
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            current_key <= 0;
            data_output <= 0;
            ready <= 0;
        end else begin
            if (new_key_reg) begin
                current_key <= key_input;
                ready <= 1'b1;
            end else if (activate_reg && ready) begin
                // 使用优化的条件求和减法结果
                data_output <= subtract_result ^ {WIDTH{borrow[WIDTH]}};
                ready <= 1'b0;  // 一次性使用
            end
        end
    end
endmodule