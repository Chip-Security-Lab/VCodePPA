//SystemVerilog
module cascaded_ismu(
    input clk, reset,
    input [1:0] cascade_in,
    input [7:0] local_int,
    input [7:0] local_mask,
    output reg cascade_out,
    output reg [3:0] int_id
);
    reg [7:0] masked_int;
    reg [3:0] local_id;
    reg local_valid;
    
    // 为后向寄存器重定时准备的预计算信号
    reg cascade_in_valid;
    reg [3:0] cascade_id;
    
    // 第一级组合逻辑 - 计算屏蔽中断和本地中断ID
    always @(*) begin
        masked_int = local_int & ~local_mask;
        local_valid = |masked_int;
        
        case (1'b1)
            masked_int[0]: local_id = 4'd0;
            masked_int[1]: local_id = 4'd1;
            masked_int[2]: local_id = 4'd2;
            masked_int[3]: local_id = 4'd3;
            masked_int[4]: local_id = 4'd4;
            masked_int[5]: local_id = 4'd5;
            masked_int[6]: local_id = 4'd6;
            masked_int[7]: local_id = 4'd7;
            default: local_id = 4'd0;
        endcase
    end
    
    // 第二级组合逻辑 - 预计算级联ID
    always @(*) begin
        cascade_in_valid = |cascade_in;
        
        case (1'b1)
            cascade_in[0]: cascade_id = 4'd8;
            cascade_in[1]: cascade_id = 4'd9;
            default:       cascade_id = 4'd0;
        endcase
    end
    
    // 重定时后的寄存器逻辑
    reg local_valid_reg;
    reg [3:0] local_id_reg;
    reg cascade_in_valid_reg;
    reg [3:0] cascade_id_reg;
    
    // 通过重定时，移动寄存器到组合逻辑之前
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            local_valid_reg <= 1'b0;
            local_id_reg <= 4'd0;
            cascade_in_valid_reg <= 1'b0;
            cascade_id_reg <= 4'd0;
        end else begin
            local_valid_reg <= local_valid;
            local_id_reg <= local_id;
            cascade_in_valid_reg <= cascade_in_valid;
            cascade_id_reg <= cascade_id;
        end
    end
    
    // 输出赋值使用已寄存的值
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            int_id <= 4'd0;
            cascade_out <= 1'b0;
        end else begin
            cascade_out <= local_valid_reg | cascade_in_valid_reg;
            
            case (1'b1)
                local_valid_reg:    int_id <= local_id_reg;
                cascade_in_valid_reg: int_id <= cascade_id_reg;
                default:            int_id <= int_id;
            endcase
        end
    end
endmodule