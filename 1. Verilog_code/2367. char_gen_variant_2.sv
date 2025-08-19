//SystemVerilog
module char_gen #(
    parameter CHAR_WIDTH = 8,
    parameter H_DISPLAY = 640,
    parameter V_DISPLAY = 480
)(
    input wire clk, 
    input wire [9:0] h_cnt, v_cnt,
    output reg pixel, blank
);
    // 实例化可复用模块
    display_boundary_check #(
        .H_DISPLAY(H_DISPLAY),
        .V_DISPLAY(V_DISPLAY)
    ) boundary_check_inst (
        .clk(clk),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt),
        .blank(blank)
    );
    
    // 实例化可复用模块
    pixel_generator #(
        .CHAR_WIDTH(CHAR_WIDTH)
    ) pixel_gen_inst (
        .clk(clk),
        .h_cnt(h_cnt),
        .pixel(pixel)
    );
endmodule

// 边界检查模块
module display_boundary_check #(
    parameter H_DISPLAY = 640,
    parameter V_DISPLAY = 480
)(
    input wire clk,
    input wire [9:0] h_cnt, v_cnt,
    output reg blank
);
    always @(posedge clk) begin
        // 根据显示范围计算blank信号
        if (h_cnt > H_DISPLAY || v_cnt > V_DISPLAY) begin
            blank <= 1'b1;
        end
        else begin
            blank <= 1'b0;
        end
    end
endmodule

// 像素生成模块
module pixel_generator #(
    parameter CHAR_WIDTH = 8
)(
    input wire clk,
    input wire [9:0] h_cnt,
    output reg pixel
);
    always @(posedge clk) begin
        // 根据水平计数器生成像素
        if (h_cnt[2:0] < CHAR_WIDTH) begin
            pixel <= 1'b1;
        end
        else begin
            pixel <= 1'b0;
        end
    end
endmodule