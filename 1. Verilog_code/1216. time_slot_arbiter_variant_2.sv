//SystemVerilog
module time_slot_arbiter #(WIDTH=4, SLOT=8) (
    input clk, rst_n,
    input [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    reg [7:0] counter;
    reg [WIDTH-1:0] rotation;
    
    // 使用二进制补码减法算法实现计数器
    wire [7:0] slot_minus_one = SLOT - 1;
    wire counter_at_max = (counter == slot_minus_one);
    wire [7:0] counter_next;
    
    // 二进制补码减法实现
    wire [7:0] ones_complement;
    wire [7:0] twos_complement;
    wire [7:0] counter_plus_one;
    
    // 生成1的补码 (按位取反)
    assign ones_complement = ~8'h01;
    // 生成2的补码 (按位取反+1)
    assign twos_complement = ones_complement + 1'b1;
    // 计算counter+(-1)或重置为0
    assign counter_plus_one = counter_at_max ? 8'h00 : (counter + twos_complement);
    // 新的计数值等于counter-1的结果
    assign counter_next = counter_at_max ? 8'h00 : (counter + 8'h01);
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            counter <= 8'h00;
            rotation <= {{(WIDTH-1){1'b0}}, 1'b1};
            grant_o <= {WIDTH{1'b0}};
        end else begin
            counter <= counter_next;
            if(counter == 8'h00) begin
                rotation <= {rotation[WIDTH-2:0], rotation[WIDTH-1]};
                grant_o <= (req_i & rotation) ? rotation : {WIDTH{1'b0}};
            end
        end
    end
endmodule