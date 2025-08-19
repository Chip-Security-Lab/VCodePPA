//SystemVerilog
module delayed_reset_release(
    input wire clk,
    input wire reset_in,
    input wire [3:0] delay_value,
    output reg reset_out
);
    reg [3:0] counter;
    wire [3:0] next_counter;
    wire [3:0] borrow;
    
    // 先行借位减法器实现
    // 生成借位信号
    assign borrow[0] = 0;
    assign borrow[1] = counter[0] ? 0 : 1;
    assign borrow[2] = (counter[1]) ? 0 : borrow[1];
    assign borrow[3] = (counter[2]) ? 0 : borrow[2];
    
    // 减法运算，减1
    assign next_counter[0] = ~counter[0];
    assign next_counter[1] = counter[1] ^ borrow[1];
    assign next_counter[2] = counter[2] ^ borrow[2];
    assign next_counter[3] = counter[3] ^ borrow[3];
    
    always @(posedge clk) begin
        if (reset_in) begin
            counter <= delay_value;
            reset_out <= 1'b1;
        end else if (|counter) begin  // 使用OR归约运算符检查非零
            counter <= next_counter;  // 使用先行借位减法器结果
            reset_out <= 1'b1;
        end else begin
            reset_out <= 1'b0;
        end
    end
endmodule