//SystemVerilog
// 顶层模块
module one_wire_codec (
    input clk, rst,
    inout dq,
    output [7:0] romcode
);
    // 内部连线
    wire precharge;
    wire [2:0] state;
    
    // 控制器子模块
    one_wire_controller controller (
        .clk(clk),
        .rst(rst),
        .dq(dq),
        .state(state),
        .precharge(precharge)
    );
    
    // 数据读取子模块
    one_wire_data_reader data_reader (
        .clk(clk),
        .rst(rst),
        .dq(dq),
        .state(state),
        .romcode(romcode)
    );
    
    // 总线驱动子模块
    one_wire_bus_driver bus_driver (
        .precharge(precharge),
        .dq(dq)
    );
endmodule

// 总线控制器子模块
module one_wire_controller (
    input clk, rst,
    input dq,
    output reg [2:0] state,
    output reg precharge
);
    always @(negedge clk) begin
        if (rst) begin
            state <= 3'd0;
            precharge <= 1'b0;
        end else begin
            case(state)
                3'd0: begin // 检测复位脉冲
                    if(!dq) begin
                        precharge <= 1'b1;
                        state <= 3'd1;
                    end
                end
                3'd1: begin // 释放总线
                    precharge <= 1'b0;
                    if(dq) begin
                        state <= 3'd2;
                    end
                end
                3'd2: state <= 3'd3; // ROM读取第一位后状态转换
                3'd3: state <= 3'd4; // ROM读取第二位后状态转换
                3'd4: state <= 3'd5; // ROM读取第三位后状态转换
                3'd5: state <= 3'd6; // ROM读取第四位后状态转换
                3'd6: state <= 3'd7; // ROM读取第五位后状态转换
                3'd7: state <= 3'd0; // 读取完成，返回初始状态
                default: state <= 3'd0;
            endcase
        end
    end
endmodule

// 数据读取子模块
module one_wire_data_reader (
    input clk, rst,
    input dq,
    input [2:0] state,
    output reg [7:0] romcode
);
    always @(negedge clk) begin
        if (rst) begin
            romcode <= 8'd0;
        end else begin
            case(state)
                3'd1: begin
                    if(dq) begin
                        romcode <= 8'd0; // 初始化
                    end
                end
                3'd2: romcode[0] <= dq; // 读取第一位
                3'd3: romcode[1] <= dq; // 读取第二位
                3'd4: romcode[2] <= dq; // 读取第三位
                3'd5: romcode[3] <= dq; // 读取第四位
                3'd6: romcode[4] <= dq; // 读取第五位
                3'd7: romcode[5] <= dq; // 读取第六位
                // 注：原代码只实际读取了6位，第7-8位保持为0
            endcase
        end
    end
endmodule

// 总线驱动子模块
module one_wire_bus_driver (
    input precharge,
    inout dq
);
    // 三态控制
    assign dq = precharge ? 1'b0 : 1'bz;
endmodule