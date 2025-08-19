//SystemVerilog
module time_slot_arbiter #(
    parameter WIDTH = 4, 
    parameter SLOT = 8
) (
    input wire clk, 
    input wire rst_n,
    input wire [WIDTH-1:0] req_i,
    output reg [WIDTH-1:0] grant_o
);
    // Counter with reduced bit width to match actual SLOT size
    reg [$clog2(SLOT)-1:0] counter;
    reg [WIDTH-1:0] rotation;
    wire [WIDTH-1:0] next_rotation;
    wire counter_max;
    reg counter_is_zero;
    
    // 优化：将req_i的寄存处理移至更靠近输入端
    reg [WIDTH-1:0] req_reg;
    
    // 将rotation计算从always块移出，减少关键路径延迟
    assign next_rotation = {rotation[WIDTH-2:0], rotation[WIDTH-1]};
    
    // 将req_masked计算提前，并注册到寄存器
    reg [WIDTH-1:0] req_masked_reg;
    wire [WIDTH-1:0] req_masked;
    assign req_masked = req_reg & rotation;
    
    // Detect counter maximum value
    assign counter_max = (counter == SLOT-1);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            req_reg <= 0;
            req_masked_reg <= 0;
        end else begin
            // 添加输入寄存以减少输入到第一级逻辑的延迟
            req_reg <= req_i;
            // 注册req_masked结果，减少下一级组合逻辑路径
            req_masked_reg <= req_masked;
        end
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            counter_is_zero <= 1'b1;
            rotation <= 1;
            grant_o <= 0;
        end else begin
            // Counter logic
            if (counter_max) begin
                counter <= 0;
                counter_is_zero <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
                counter_is_zero <= 1'b0;
            end
            
            // Rotation and grant logic
            if (counter_is_zero) begin
                rotation <= next_rotation;
                // 使用预先计算并注册的值
                grant_o <= |req_masked_reg ? rotation : 0;
            end
        end
    end
endmodule