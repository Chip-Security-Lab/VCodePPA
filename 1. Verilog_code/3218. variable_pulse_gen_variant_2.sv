//SystemVerilog
// 顶层模块
module variable_pulse_gen(
    input CLK,
    input RST,
    input [9:0] PULSE_WIDTH,
    input [9:0] PERIOD,
    output PULSE
);
    // 内部连线
    wire [9:0] counter_value;
    
    // 实例化计数器子模块
    period_counter period_counter_inst (
        .clk(CLK),
        .rst(RST),
        .period(PERIOD),
        .counter(counter_value)
    );
    
    // 实例化脉冲生成子模块
    pulse_generator pulse_generator_inst (
        .clk(CLK),
        .rst(RST),
        .counter(counter_value),
        .pulse_width(PULSE_WIDTH),
        .pulse(PULSE)
    );
endmodule

// 周期计数器子模块
module period_counter (
    input clk,
    input rst,
    input [9:0] period,
    output reg [9:0] counter
);
    always @(posedge clk) begin
        if (rst) begin
            counter <= 10'd0;
        end else begin
            if (counter < period) 
                counter <= counter + 10'd1;
            else
                counter <= 10'd0;
        end
    end
endmodule

// 脉冲生成子模块
module pulse_generator (
    input clk,
    input rst,
    input [9:0] counter,
    input [9:0] pulse_width,
    output reg pulse
);
    always @(posedge clk) begin
        if (rst) begin
            pulse <= 1'b0;
        end else begin
            if (counter < pulse_width)
                pulse <= 1'b1;
            else
                pulse <= 1'b0;
        end
    end
endmodule