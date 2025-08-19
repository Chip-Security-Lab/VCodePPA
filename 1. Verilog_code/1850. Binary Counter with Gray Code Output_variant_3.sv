//SystemVerilog
module binary_gray_counter #(
    parameter WIDTH = 8,
    parameter MAX_COUNT = {WIDTH{1'b1}}
) (
    input  wire                 clock_in,
    input  wire                 reset_n,
    input  wire                 enable_in,
    input  wire                 up_down_n,  // 1=up, 0=down
    output reg  [WIDTH-1:0]     binary_count,
    output wire [WIDTH-1:0]     gray_count,
    output wire                 terminal_count
);
    // 内部寄存器
    reg [WIDTH-1:0] binary_reg;
    reg [WIDTH-1:0] gray_reg;
    reg terminal_reg;
    
    // 组合逻辑信号
    reg [WIDTH-1:0] next_binary;
    wire [WIDTH-1:0] gray_comb;
    wire term_comb;
    
    // 组合逻辑计算二进制计数器下一个值
    always @(*) begin
        if (enable_in) begin
            if (up_down_n) begin
                if (binary_reg == MAX_COUNT)
                    next_binary = {WIDTH{1'b0}};
                else
                    next_binary = binary_reg + 1'b1;
            end else begin
                if (binary_reg == {WIDTH{1'b0}})
                    next_binary = MAX_COUNT;
                else
                    next_binary = binary_reg - 1'b1;
            end
        end else begin
            next_binary = binary_reg;
        end
    end
    
    // 提前计算格雷码（前移寄存器）
    assign gray_comb = next_binary ^ {1'b0, next_binary[WIDTH-1:1]};
    
    // 提前计算终端计数状态（前移寄存器）
    assign term_comb = up_down_n ? (binary_reg == MAX_COUNT) : 
                                  (binary_reg == {WIDTH{1'b0}});
    
    // 寄存器更新 - 将寄存器前移到组合逻辑之前
    always @(posedge clock_in or negedge reset_n) begin
        if (!reset_n) begin
            binary_reg <= {WIDTH{1'b0}};
            gray_reg <= {WIDTH{1'b0}};
            terminal_reg <= 1'b0;
        end else begin
            binary_reg <= next_binary;
            gray_reg <= gray_comb;
            terminal_reg <= term_comb;
        end
    end
    
    // 输出赋值 - 直接使用寄存器输出，减少输出路径延迟
    assign binary_count = binary_reg;
    assign gray_count = gray_reg;
    assign terminal_count = terminal_reg;
endmodule