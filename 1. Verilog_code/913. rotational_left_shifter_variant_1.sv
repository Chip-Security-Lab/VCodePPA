//SystemVerilog
module rotational_left_shifter (
    input clock,
    input reset,
    input valid_in,
    output reg ready_in,
    input [15:0] data_input,
    input [3:0] rotate_amount,
    output reg valid_out,
    input ready_out,
    output reg [15:0] data_output
);

    // 预计算组合逻辑
    wire [15:0] left_shifted = data_input << rotate_amount;
    wire [15:0] right_shifted = data_input >> (16 - rotate_amount);
    wire [15:0] rotated_data = left_shifted | right_shifted;
    
    // 流水线状态寄存器
    reg stage1_valid, stage2_valid;
    wire stage1_ready, stage2_ready;
    
    // 握手信号传递逻辑
    assign stage1_ready = ~stage1_valid | stage2_ready;
    assign stage2_ready = ~stage2_valid | ready_out;
    
    // 输入寄存器
    reg [15:0] data_input_reg;
    reg [3:0] rotate_amount_reg;
    reg input_valid_reg;
    
    // 流水线输入阶段
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            ready_in <= 1'b1;
            data_input_reg <= 16'd0;
            rotate_amount_reg <= 4'd0;
            input_valid_reg <= 1'b0;
        end
        else if (valid_in && ready_in) begin
            data_input_reg <= data_input;
            rotate_amount_reg <= rotate_amount;
            input_valid_reg <= 1'b1;
        end
        else begin
            ready_in <= stage1_ready;
            input_valid_reg <= 1'b0;
        end
    end
    
    // 第一级流水线寄存器
    always @(posedge clock) begin
        if (reset) begin
            stage1_valid <= 1'b0;
        end
        else if (input_valid_reg && stage1_ready) begin
            stage1_valid <= 1'b1;
        end
        else if (stage1_valid && stage2_ready) begin
            stage1_valid <= 1'b0;
        end
    end
    
    // 输出寄存器
    always @(posedge clock) begin
        if (reset) begin
            data_output <= 16'd0;
            stage2_valid <= 1'b0;
            valid_out <= 1'b0;
        end
        else if (stage1_valid && stage2_ready) begin
            data_output <= rotated_data;
            stage2_valid <= 1'b1;
        end
        else if (stage2_valid && ready_out) begin
            stage2_valid <= 1'b0;
            valid_out <= 1'b1;
        end
        else if (valid_out && ready_out) begin
            valid_out <= 1'b0;
        end
    end
endmodule