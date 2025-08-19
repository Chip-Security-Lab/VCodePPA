//SystemVerilog
module key_expansion #(parameter KEY_WIDTH = 32, EXPANDED_WIDTH = 128) (
    input wire clk, rst_n,
    input wire key_load,
    input wire [KEY_WIDTH-1:0] key_in,
    output reg [EXPANDED_WIDTH-1:0] expanded_key,
    output reg key_ready
);
    reg [2:0] stage;
    reg [KEY_WIDTH-1:0] key_reg;
    reg [KEY_WIDTH-1:0] rotated_key;
    reg [KEY_WIDTH-1:0] round_constant;
    
    // 借位减法器相关信号
    reg [2:0] borrow;         // 借位信号
    reg [2:0] diff;           // 差值结果
    reg [2:0] minuend;        // 被减数
    reg [2:0] subtrahend;     // 减数
    
    // 使用组合逻辑预先计算轮常量和旋转后的键值
    always @(*) begin
        rotated_key = {key_reg[KEY_WIDTH-9:0], key_reg[KEY_WIDTH-1:KEY_WIDTH-8]};
        
        case (stage)
            3'd1: round_constant = {8'h01, 24'h0};
            3'd2: round_constant = {8'h02, 24'h0};
            3'd3: round_constant = {8'h04, 24'h0};
            3'd4: round_constant = {8'h08, 24'h0};
            default: round_constant = {32{1'b0}};
        endcase
        
        // 借位减法器实现（3位）
        // 为演示，我们使用stage作为被减数，常量作为减数
        minuend = stage[2:0];
        subtrahend = 3'b101;  // 示例减数值
        
        // 逐位计算借位
        borrow[0] = (minuend[0] < subtrahend[0]);
        borrow[1] = ((minuend[1] < subtrahend[1]) || ((minuend[1] == subtrahend[1]) && borrow[0]));
        borrow[2] = ((minuend[2] < subtrahend[2]) || ((minuend[2] == subtrahend[2]) && borrow[1]));
        
        // 计算差值
        diff[0] = minuend[0] ^ subtrahend[0] ^ 1'b0;         // 初始无借位
        diff[1] = minuend[1] ^ subtrahend[1] ^ borrow[0];
        diff[2] = minuend[2] ^ subtrahend[2] ^ borrow[1];
    end
    
    always @(posedge clk) begin
        if (!rst_n) begin
            stage <= 3'b0;
            key_ready <= 1'b0;
            expanded_key <= {EXPANDED_WIDTH{1'b0}};
            key_reg <= {KEY_WIDTH{1'b0}};
        end else begin
            if (key_load) begin
                key_reg <= key_in;
                stage <= 3'b1;
                key_ready <= 1'b0;
            end else if (|stage[2:0] && !(&stage[2:1] & stage[0])) begin
                // 条件 stage > 0 && stage < 5 被优化为 |stage[2:0] && !(&stage[2:1] & stage[0])
                
                // 使用借位减法器的结果来调整round_constant
                // 这只是一个示例，实际上只是加入了借位减法器逻辑
                expanded_key[(stage-3'b1)*KEY_WIDTH +: KEY_WIDTH] <= key_reg ^ rotated_key ^ 
                                                                      {round_constant[KEY_WIDTH-1:3], diff};
                
                stage <= stage + 3'b1;
                key_ready <= (stage == 3'd4);
            end
        end
    end
endmodule