//SystemVerilog
module sync_pulse_generator(
    input clk_i,
    input rst_i,
    input en_i,
    input [15:0] period_i,
    input [15:0] width_i,
    output reg pulse_o
);
    reg [15:0] counter;
    reg [15:0] counter_next;
    reg pulse_next;
    wire period_reached;
    wire within_pulse_width;

    // 预计算关键路径信号
    assign period_reached = (counter >= period_i-1);
    assign within_pulse_width = (counter < width_i);

    // 组合逻辑路径分割
    always @(*) begin
        if (period_reached)
            counter_next = 16'd0;
        else
            counter_next = counter + 16'd1;
        pulse_next = within_pulse_width;
    end

    // 时序逻辑
    always @(posedge clk_i) begin
        if (rst_i) begin
            counter <= 16'd0;
            pulse_o <= 1'b0;
        end else if (en_i) begin
            counter <= counter_next;
            pulse_o <= pulse_next;
        end
    end
endmodule

module counter_unit(
    input clk_i,
    input rst_i,
    input en_i,
    input [15:0] period_i,
    output reg [15:0] counter_o
);
    reg [15:0] counter_next;
    wire period_reached;
    
    assign period_reached = (counter_o == period_i-1);
    
    always @(*) begin
        counter_next = period_reached ? 16'd0 : counter_o + 16'd1;
    end
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            counter_o <= 16'd0;
        end else if (en_i) begin
            counter_o <= counter_next;
        end
    end
endmodule

module pulse_gen_unit(
    input clk_i,
    input rst_i,
    input en_i,
    input [15:0] counter_i,
    input [15:0] width_i,
    output reg pulse_o
);
    reg pulse_next;
    wire within_pulse_width;
    
    assign within_pulse_width = (counter_i < width_i);
    
    always @(*) begin
        pulse_next = within_pulse_width;
    end
    
    always @(posedge clk_i) begin
        if (rst_i) begin
            pulse_o <= 1'b0;
        end else if (en_i) begin
            pulse_o <= pulse_next;
        end
    end
endmodule