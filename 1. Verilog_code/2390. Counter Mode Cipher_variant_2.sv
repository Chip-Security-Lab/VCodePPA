//SystemVerilog
module counter_mode_cipher #(
    parameter CTR_WIDTH = 16,
    parameter DATA_WIDTH = 32
) (
    input  wire                   clk,
    input  wire                   reset,
    input  wire                   enable,
    input  wire                   encrypt,
    input  wire [CTR_WIDTH-1:0]   init_ctr,
    input  wire [DATA_WIDTH-1:0]  data_in,
    input  wire [DATA_WIDTH-1:0]  key,
    output reg  [DATA_WIDTH-1:0]  data_out,
    output reg                    data_valid
);
    // 状态寄存器优化：添加计数器变量并优化初始化
    reg [CTR_WIDTH-1:0] counter;
    reg [DATA_WIDTH-1:0] key_reg;
    
    // 优化密钥混合逻辑，避免重复计算
    wire [DATA_WIDTH-1:0] encrypted_ctr;
    wire [CTR_WIDTH-1:0] next_counter;
    
    // 计算下一个计数器值，用组合逻辑实现
    assign next_counter = counter + {{(CTR_WIDTH-1){1'b0}}, enable};
    
    // 优化加密函数，使用寄存的key值减少关键路径延迟
    assign encrypted_ctr = {counter, {(DATA_WIDTH-CTR_WIDTH){1'b0}} | counter} ^ key_reg;
    
    always @(posedge clk) begin
        if (reset) begin
            counter <= init_ctr;
            data_valid <= 1'b0;
            key_reg <= key;
            data_out <= {DATA_WIDTH{1'b0}};
        end 
        else if (enable) begin
            counter <= next_counter;
            data_out <= data_in ^ encrypted_ctr;
            data_valid <= 1'b1;
            key_reg <= key;
        end 
        else begin
            counter <= next_counter;
            data_valid <= 1'b0;
            key_reg <= key;
        end
    end
endmodule