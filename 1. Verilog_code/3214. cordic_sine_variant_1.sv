//SystemVerilog
module cordic_sine(
    input clock,
    input resetn,
    input [7:0] angle_step,
    output reg [9:0] sine_output
);
    reg [9:0] x, y;
    reg [7:0] angle;
    reg [2:0] state;
    
    // 负责状态重置逻辑
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            state <= 3'd0;
        end else begin
            case (state)
                3'd0: state <= 3'd1;
                3'd1: state <= 3'd2;
                3'd2: state <= 3'd0;
                default: state <= 3'd0;
            endcase
        end
    end
    
    // 负责角度累加逻辑
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            angle <= 8'd0;
        end else if (state == 3'd0) begin
            angle <= angle + angle_step;
        end
    end
    
    // 负责x坐标初始化和维护
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            x <= 10'd307;       // ~0.6*512
        end
    end
    
    // 负责y坐标计算逻辑
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            y <= 10'd0;
        end else if (state == 3'd1) begin
            if (angle < 8'd128)    // 0 to π/2
                y <= y + (x >> 3);
            else                   // π/2 to π
                y <= y - (x >> 3);
        end
    end
    
    // 负责正弦输出逻辑
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            sine_output <= 10'd0;
        end else if (state == 3'd2) begin
            sine_output <= y;
        end
    end
endmodule