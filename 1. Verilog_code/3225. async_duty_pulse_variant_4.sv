//SystemVerilog
module async_duty_pulse(
    input clk,
    input arst,
    input [7:0] period,
    input [2:0] duty_sel,  // 0-7 representing duty cycles
    input valid,           // 输入数据有效信号
    output ready,          // 模块准备接收新数据信号
    output reg pulse
);
    reg [7:0] counter;
    reg [7:0] duty_threshold;
    reg params_valid;      // 参数有效标志
    reg [7:0] period_reg;  // 存储有效的周期值
    reg [2:0] duty_sel_reg; // 存储有效的占空比选择
    
    // Add buffered registers for high fanout signals
    reg [7:0] period_buf1, period_buf2;
    reg [7:0] counter_buf1, counter_buf2;
    reg [7:0] duty_threshold_buf;
    
    // Ready信号生成逻辑 - 当模块未处理数据或当前周期即将结束时准备好接收新数据
    assign ready = !params_valid || (counter == period_buf2-2);
    
    // 参数寄存逻辑，使用Valid-Ready握手
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            params_valid <= 1'b0;
            period_reg <= 8'd0;
            duty_sel_reg <= 3'd0;
        end else begin
            if (valid && ready) begin
                period_reg <= period;
                duty_sel_reg <= duty_sel;
                params_valid <= 1'b1;
            end else if (counter == period_buf2-1) begin
                // 可选：在每个周期结束时允许更新参数
                params_valid <= 1'b0;
            end
        end
    end
    
    // Buffer period to reduce fanout
    always @(posedge clk) begin
        if (arst) begin
            period_buf1 <= 8'd0;
            period_buf2 <= 8'd0;
        end else if (params_valid) begin
            period_buf1 <= period_reg;
            period_buf2 <= period_buf1;
        end
    end
    
    // Counter logic with reduced fanout
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            counter <= 8'd0;
            counter_buf1 <= 8'd0;
            counter_buf2 <= 8'd0;
        end else if (params_valid) begin
            if (counter >= period_buf2-1)
                counter <= 8'd0;
            else
                counter <= counter + 8'd1;
                
            counter_buf1 <= counter;
            counter_buf2 <= counter_buf1;
        end
    end
    
    // Duty threshold calculation with balanced path delays
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            duty_threshold <= 8'd0;
            duty_threshold_buf <= 8'd0;
        end else if (params_valid) begin
            case (duty_sel_reg)
                3'd0: duty_threshold <= {1'b0, period_buf1[7:1]};      // 50%
                3'd1: duty_threshold <= {2'b00, period_buf1[7:2]};     // 25%
                3'd2: duty_threshold <= {3'b000, period_buf1[7:3]};    // 12.5%
                3'd3: duty_threshold <= {2'b00, period_buf1[7:2]} + {1'b0, period_buf1[7:1]}; // 75%
                3'd4: duty_threshold <= {3'b000, period_buf1[7:3]} + {1'b0, period_buf1[7:1]}; // 62.5%
                3'd5: duty_threshold <= {3'b000, period_buf1[7:3]} + {2'b00, period_buf1[7:2]}; // 37.5%
                3'd6: duty_threshold <= period_buf1 - 8'd1;           // 99%
                3'd7: duty_threshold <= 8'd1;                         // 1%
            endcase
            
            duty_threshold_buf <= duty_threshold;
        end
    end
    
    // Pulse generation with buffered signals to reduce critical path
    always @(posedge clk or posedge arst) begin
        if (arst) begin
            pulse <= 1'b0;
        end else if (params_valid) begin
            pulse <= (counter_buf2 < duty_threshold_buf) ? 1'b1 : 1'b0;
        end else begin
            pulse <= 1'b0;
        end
    end
endmodule