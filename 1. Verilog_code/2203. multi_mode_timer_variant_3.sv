//SystemVerilog
module multi_mode_timer #(
    parameter WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire [1:0] mode,
    input wire [WIDTH-1:0] period,
    output reg out
);
    reg [WIDTH-1:0] counter;
    reg [1:0] complement_mode;  // 反相模式控制信号
    wire [2:0] sub_result;      // 减法结果（包含借位）
    reg [2:0] sub_result_reg;   // 减法结果寄存器
    reg [WIDTH-1:0] period_reg; // 缓存period值
    reg [1:0] mode_reg;         // 缓存mode值
    reg counter_lt_period_half; // 计算counter < (period >> 1)的流水线寄存器
    
    // 条件反相减法器实现，使用寄存器切割关键路径
    assign sub_result = {1'b0, period_reg[1:0]} + {1'b0, ~1'b1 + 1'b1} + {1'b0, complement_mode};
    
    always @(posedge clk) begin
        if (rst) begin
            counter <= {WIDTH{1'b0}};
            out <= 1'b0;
            complement_mode <= 2'b00;
            sub_result_reg <= 3'b0;
            period_reg <= {WIDTH{1'b0}};
            mode_reg <= 2'b00;
            counter_lt_period_half <= 1'b0;
        end else begin
            // 流水线寄存器更新
            period_reg <= period;
            mode_reg <= mode;
            sub_result_reg <= sub_result;
            counter_lt_period_half <= (counter < (period_reg >> 1));
            
            // 关键路径切割和模式逻辑
            case (mode_reg)
                2'd0: begin // One-Shot Mode
                    complement_mode <= ~counter[1:0];
                    if (counter < period_reg) begin
                        counter <= counter + 1'b1;
                        out <= 1'b1;
                    end else begin
                        out <= 1'b0;
                    end
                end
                2'd1: begin // Periodic Mode
                    complement_mode <= ~counter[1:0];
                    if (!sub_result_reg[2]) begin  // 使用寄存器后的借位判断
                        counter <= {WIDTH{1'b0}};
                        out <= 1'b1;
                    end else begin
                        counter <= counter + 1'b1;
                        out <= 1'b0;
                    end
                end
                2'd2: begin // PWM Mode (50% duty)
                    complement_mode <= ~counter[1:0];
                    if (!sub_result_reg[2]) begin  // 使用寄存器后的借位判断
                        counter <= {WIDTH{1'b0}};
                    end else begin
                        counter <= counter + 1'b1;
                    end
                    out <= counter_lt_period_half; // 使用预计算的结果
                end
                2'd3: begin // Toggle Mode
                    complement_mode <= ~counter[1:0];
                    if (!sub_result_reg[2]) begin  // 使用寄存器后的借位判断
                        counter <= {WIDTH{1'b0}};
                        out <= ~out;
                    end else begin
                        counter <= counter + 1'b1;
                    end
                end
            endcase
        end
    end
endmodule