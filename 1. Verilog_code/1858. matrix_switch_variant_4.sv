//SystemVerilog
// 顶层模块
module matrix_switch #(parameter INPUTS=4, OUTPUTS=4, DATA_W=8) (
    input [DATA_W-1:0] din_0, din_1, din_2, din_3,
    input [1:0] sel_0, sel_1, sel_2, sel_3,
    output [DATA_W-1:0] dout_0, dout_1, dout_2, dout_3
);

    // 实例化输出端口0的路由模块
    output_router #(.DATA_W(DATA_W)) router_0 (
        .din_0(din_0), .din_1(din_1), .din_2(din_2), .din_3(din_3),
        .sel_0(sel_0), .sel_1(sel_1), .sel_2(sel_2), .sel_3(sel_3),
        .target_port(2'd0),
        .dout(dout_0)
    );

    // 实例化输出端口1的路由模块
    output_router #(.DATA_W(DATA_W)) router_1 (
        .din_0(din_0), .din_1(din_1), .din_2(din_2), .din_3(din_3),
        .sel_0(sel_0), .sel_1(sel_1), .sel_2(sel_2), .sel_3(sel_3),
        .target_port(2'd1),
        .dout(dout_1)
    );

    // 实例化输出端口2的路由模块
    output_router #(.DATA_W(DATA_W)) router_2 (
        .din_0(din_0), .din_1(din_1), .din_2(din_2), .din_3(din_3),
        .sel_0(sel_0), .sel_1(sel_1), .sel_2(sel_2), .sel_3(sel_3),
        .target_port(2'd2),
        .dout(dout_2)
    );

    // 实例化输出端口3的路由模块
    output_router #(.DATA_W(DATA_W)) router_3 (
        .din_0(din_0), .din_1(din_1), .din_2(din_2), .din_3(din_3),
        .sel_0(sel_0), .sel_1(sel_1), .sel_2(sel_2), .sel_3(sel_3),
        .target_port(2'd3),
        .dout(dout_3)
    );

endmodule

// 输出端口路由子模块
module output_router #(parameter DATA_W=8) (
    input [DATA_W-1:0] din_0, din_1, din_2, din_3,
    input [1:0] sel_0, sel_1, sel_2, sel_3,
    input [1:0] target_port,
    output reg [DATA_W-1:0] dout
);

    always @(*) begin
        dout = (sel_0 == target_port) ? din_0 :
               (sel_1 == target_port) ? din_1 :
               (sel_2 == target_port) ? din_2 :
               (sel_3 == target_port) ? din_3 : {DATA_W{1'b0}};
    end

endmodule