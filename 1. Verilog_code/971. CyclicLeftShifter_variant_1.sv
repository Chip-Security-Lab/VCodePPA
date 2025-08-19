//SystemVerilog
module CyclicLeftShifter #(parameter WIDTH=8) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             en,
    input  wire             serial_in,
    output reg  [WIDTH-1:0] parallel_out
);

    // 内部寄存器定义 - 用于流水线处理
    reg             input_stage_valid;
    reg             input_stage_data;
    reg  [WIDTH-2:0] shift_buffer;

    // 输入阶段 - 捕获和验证输入数据
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_stage_valid <= 1'b0;
            input_stage_data  <= 1'b0;
        end
        else begin
            input_stage_valid <= en;
            if (en) begin
                input_stage_data <= serial_in;
            end
        end
    end

    // 移位阶段 - 管理移位缓冲区
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_buffer <= {(WIDTH-1){1'b0}};
        end
        else if (input_stage_valid) begin
            shift_buffer <= parallel_out[WIDTH-2:0];
        end
    end

    // 输出阶段 - 组合移位结果
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parallel_out <= {WIDTH{1'b0}};
        end
        else if (input_stage_valid) begin
            parallel_out <= {shift_buffer, input_stage_data};
        end
    end

endmodule