//SystemVerilog
module wave5_triangle #(
    parameter WIDTH = 8
)(
    input  wire             clk,
    input  wire             rst,
    output reg [WIDTH-1:0]  wave_out
);
    // 流水线阶段1：计算和方向控制
    reg direction_stage1;
    reg [WIDTH-1:0] wave_out_stage1;
    reg [WIDTH-1:0] next_value_stage1;
    reg valid_stage1;
    
    // 流水线阶段2：减法运算中间状态
    reg direction_stage2;
    reg [WIDTH-1:0] wave_out_stage2;
    reg [WIDTH-1:0] next_value_stage2;
    reg valid_stage2;
    wire [WIDTH-1:0] sub_result;
    wire [WIDTH:0] borrow;
    
    // 先行借位减法器实现
    assign borrow[0] = 1'b0;
    
    genvar i;
    generate
        for(i = 0; i < WIDTH; i = i + 1) begin: borrow_gen
            assign borrow[i+1] = (~wave_out_stage1[i]) | (borrow[i] & (1'b0));
            assign sub_result[i] = wave_out_stage1[i] ^ borrow[i] ^ 1'b1;
        end
    endgenerate

    // 阶段1：方向控制和下一个值的预计算
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            wave_out_stage1 <= 0;
            direction_stage1 <= 1'b1;
            valid_stage1 <= 1'b0;
        end else begin
            valid_stage1 <= 1'b1;
            wave_out_stage1 <= wave_out;
            direction_stage1 <= direction_stage2;
            
            if(wave_out == {WIDTH{1'b1}})
                direction_stage1 <= 1'b0;
            else if(wave_out == {WIDTH{1'b0}})
                direction_stage1 <= 1'b1;
        end
    end

    // 阶段2：计算下一个值
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            wave_out_stage2 <= 0;
            next_value_stage2 <= 0;
            direction_stage2 <= 1'b1;
            valid_stage2 <= 1'b0;
        end else begin
            valid_stage2 <= valid_stage1;
            wave_out_stage2 <= wave_out_stage1;
            direction_stage2 <= direction_stage1;
            
            if(direction_stage1)
                next_value_stage2 <= wave_out_stage1 + 1'b1;
            else
                next_value_stage2 <= sub_result;
        end
    end

    // 输出阶段
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            wave_out <= 0;
        end else if(valid_stage2) begin
            wave_out <= next_value_stage2;
        end
    end
endmodule