//SystemVerilog
module cascaded_ismu(
    input clk, reset,
    input [1:0] cascade_in,
    input [7:0] local_int,
    input [7:0] local_mask,
    output cascade_out,
    output [3:0] int_id
);
    // 使用wire替代reg以减少不必要的锁存器推断
    wire [7:0] masked_int;
    wire [3:0] local_id;
    wire local_valid;
    wire cascade_valid;
    
    // 简化布尔表达式
    assign masked_int = local_int & ~local_mask;
    assign local_valid = |masked_int;
    assign cascade_valid = |cascade_in;
    
    // 使用优先编码器简化优先级检测逻辑
    assign local_id = masked_int[0] ? 4'd0 :
                     masked_int[1] ? 4'd1 :
                     masked_int[2] ? 4'd2 :
                     masked_int[3] ? 4'd3 :
                     masked_int[4] ? 4'd4 :
                     masked_int[5] ? 4'd5 :
                     masked_int[6] ? 4'd6 :
                     masked_int[7] ? 4'd7 : 4'd0;
    
    // 后向寄存器重定时：移动寄存器到组合逻辑之前
    reg local_valid_reg, cascade_valid_reg;
    reg [3:0] local_id_reg;
    reg [1:0] cascade_in_reg;
    
    // 预先寄存中间信号
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            local_valid_reg <= 1'b0;
            cascade_valid_reg <= 1'b0;
            local_id_reg <= 4'd0;
            cascade_in_reg <= 2'b00;
        end else begin
            local_valid_reg <= local_valid;
            cascade_valid_reg <= cascade_valid;
            local_id_reg <= local_id;
            cascade_in_reg <= cascade_in;
        end
    end
    
    // 输出组合逻辑
    reg cascade_out_comb;
    reg [3:0] int_id_comb;
    
    always @(*) begin
        cascade_out_comb = local_valid_reg | cascade_valid_reg;
        
        case ({local_valid_reg, cascade_in_reg})
            3'b100, 3'b101, 3'b110, 3'b111: int_id_comb = local_id_reg;
            3'b001, 3'b011: int_id_comb = 4'd8;
            3'b010, 3'b011: int_id_comb = 4'd9;
            default: int_id_comb = 4'd0; // 无效状态使用默认值
        endcase
    end
    
    // 输出寄存器
    reg cascade_out_reg;
    reg [3:0] int_id_reg_out;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            cascade_out_reg <= 1'b0;
            int_id_reg_out <= 4'd0;
        end else begin
            cascade_out_reg <= cascade_out_comb;
            int_id_reg_out <= int_id_comb;
        end
    end
    
    // 最终输出赋值
    assign cascade_out = cascade_out_reg;
    assign int_id = int_id_reg_out;
    
endmodule