//SystemVerilog
module matrix_switch #(parameter INPUTS=4, OUTPUTS=4, DATA_W=8) (
    input [DATA_W-1:0] din_0, din_1, din_2, din_3,
    input [1:0] sel_0, sel_1, sel_2, sel_3,
    output reg [DATA_W-1:0] dout_0, dout_1, dout_2, dout_3
);
    // 查找表定义 - 减少组合逻辑复杂度
    reg [OUTPUTS-1:0] routing_lut [0:INPUTS-1];
    
    // 临时信号用于存储每个输入的路由目标
    wire [OUTPUTS-1:0] route_din0, route_din1, route_din2, route_din3;
    
    // 根据选择信号生成路由表
    always @(*) begin
        // 默认所有路由为0
        routing_lut[0] = 4'b0000;
        routing_lut[1] = 4'b0000;
        routing_lut[2] = 4'b0000;
        routing_lut[3] = 4'b0000;
        
        // 设置din_0的路由目标
        case(sel_0)
            2'd0: routing_lut[0][0] = 1'b1;
            2'd1: routing_lut[0][1] = 1'b1;
            2'd2: routing_lut[0][2] = 1'b1;
            2'd3: routing_lut[0][3] = 1'b1;
        endcase
        
        // 设置din_1的路由目标
        case(sel_1)
            2'd0: routing_lut[1][0] = 1'b1;
            2'd1: routing_lut[1][1] = 1'b1;
            2'd2: routing_lut[1][2] = 1'b1;
            2'd3: routing_lut[1][3] = 1'b1;
        endcase
        
        // 设置din_2的路由目标
        case(sel_2)
            2'd0: routing_lut[2][0] = 1'b1;
            2'd1: routing_lut[2][1] = 1'b1;
            2'd2: routing_lut[2][2] = 1'b1;
            2'd3: routing_lut[2][3] = 1'b1;
        endcase
        
        // 设置din_3的路由目标
        case(sel_3)
            2'd0: routing_lut[3][0] = 1'b1;
            2'd1: routing_lut[3][1] = 1'b1;
            2'd2: routing_lut[3][2] = 1'b1;
            2'd3: routing_lut[3][3] = 1'b1;
        endcase
    end
    
    // 使用查找表进行路由决策
    assign route_din0 = routing_lut[0];
    assign route_din1 = routing_lut[1];
    assign route_din2 = routing_lut[2];
    assign route_din3 = routing_lut[3];
    
    // 基于查找表结果组合输出
    always @(*) begin
        dout_0 = {DATA_W{1'b0}};
        dout_1 = {DATA_W{1'b0}};
        dout_2 = {DATA_W{1'b0}};
        dout_3 = {DATA_W{1'b0}};
        
        // 将din_0路由到相应输出
        if(route_din0[0]) dout_0 = dout_0 | din_0;
        if(route_din0[1]) dout_1 = dout_1 | din_0;
        if(route_din0[2]) dout_2 = dout_2 | din_0;
        if(route_din0[3]) dout_3 = dout_3 | din_0;
        
        // 将din_1路由到相应输出
        if(route_din1[0]) dout_0 = dout_0 | din_1;
        if(route_din1[1]) dout_1 = dout_1 | din_1;
        if(route_din1[2]) dout_2 = dout_2 | din_1;
        if(route_din1[3]) dout_3 = dout_3 | din_1;
        
        // 将din_2路由到相应输出
        if(route_din2[0]) dout_0 = dout_0 | din_2;
        if(route_din2[1]) dout_1 = dout_1 | din_2;
        if(route_din2[2]) dout_2 = dout_2 | din_2;
        if(route_din2[3]) dout_3 = dout_3 | din_2;
        
        // 将din_3路由到相应输出
        if(route_din3[0]) dout_0 = dout_0 | din_3;
        if(route_din3[1]) dout_1 = dout_1 | din_3;
        if(route_din3[2]) dout_2 = dout_2 | din_3;
        if(route_din3[3]) dout_3 = dout_3 | din_3;
    end
endmodule