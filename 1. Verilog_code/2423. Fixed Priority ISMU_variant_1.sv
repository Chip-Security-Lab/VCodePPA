//SystemVerilog
module priority_fixed_ismu #(
    parameter INT_COUNT = 16
)(
    input clk,
    input reset,
    input [INT_COUNT-1:0] int_src,
    input [INT_COUNT-1:0] int_enable,
    output [3:0] priority_num,
    output int_active
);

    wire [3:0] detected_priority;
    wire detection_active;

    // 中断检测子模块
    interrupt_detector #(
        .INT_COUNT(INT_COUNT)
    ) u_interrupt_detector (
        .int_src(int_src),
        .int_enable(int_enable),
        .priority_num(detected_priority),
        .int_active(detection_active)
    );

    // 寄存器输出子模块
    output_register u_output_register (
        .clk(clk),
        .reset(reset),
        .in_priority(detected_priority),
        .in_active(detection_active),
        .out_priority(priority_num),
        .out_active(int_active)
    );

endmodule

// 中断检测子模块 - 组合逻辑处理优先级检测
module interrupt_detector #(
    parameter INT_COUNT = 16
)(
    input [INT_COUNT-1:0] int_src,
    input [INT_COUNT-1:0] int_enable,
    output reg [3:0] priority_num,
    output reg int_active
);

    // 生成屏蔽后的中断信号
    wire [INT_COUNT-1:0] masked_interrupts = int_src & int_enable;
    
    always @(*) begin
        int_active = 1'b0;
        priority_num = 4'h0;
        
        if (masked_interrupts[0]) begin
            priority_num = 4'h0;
            int_active = 1'b1;
        end else if (masked_interrupts[1]) begin
            priority_num = 4'h1;
            int_active = 1'b1;
        end else if (masked_interrupts[2]) begin
            priority_num = 4'h2;
            int_active = 1'b1;
        end else if (masked_interrupts[3]) begin
            priority_num = 4'h3;
            int_active = 1'b1;
        end
        // 可根据需要扩展到INT_COUNT
    end

endmodule

// 输出寄存器子模块 - 控制时序逻辑
module output_register (
    input clk,
    input reset,
    input [3:0] in_priority,
    input in_active,
    output reg [3:0] out_priority,
    output reg out_active
);

    always @(posedge clk) begin
        if (reset) begin
            out_priority <= 4'h0;
            out_active <= 1'b0;
        end else begin
            out_priority <= in_priority;
            out_active <= in_active;
        end
    end

endmodule