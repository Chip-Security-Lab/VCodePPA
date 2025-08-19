//SystemVerilog
//==========================================================
// 顶层模块 - AXI-Stream接口的可编程影子寄存器系统
//==========================================================
module programmable_shadow_reg_axi_stream #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] tdata,
    input wire tvalid,
    output wire tready,
    input wire tlast,
    output wire [WIDTH-1:0] shadow_data,
    output wire updated
);
    // 内部连线
    wire [WIDTH-1:0] main_reg_data;
    wire update_trigger;

    // 主数据寄存器模块
    main_register #(
        .WIDTH(WIDTH)
    ) u_main_register (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(tdata),
        .main_reg_out(main_reg_data)
    );

    // 影子寄存器更新控制模块
    shadow_update_controller #(
        .WIDTH(WIDTH)
    ) u_shadow_update_controller (
        .clk(clk),
        .rst_n(rst_n),
        .main_reg_data(main_reg_data),
        .tvalid(tvalid),
        .tlast(tlast),
        .shadow_data(shadow_data),
        .updated(updated),
        .update_trigger(update_trigger)
    );

    // AXI-Stream握手机制
    assign tready = !updated;

endmodule

//==========================================================
// 主数据寄存器模块
//==========================================================
module main_register #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    output reg [WIDTH-1:0] main_reg_out
);
    // 主寄存器更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg_out <= {WIDTH{1'b0}};
        else
            main_reg_out <= data_in;
    end
endmodule

//==========================================================
// 影子寄存器更新控制模块
//==========================================================
module shadow_update_controller #(
    parameter WIDTH = 4
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] main_reg_data,
    input wire tvalid,
    input wire tlast,
    output reg [WIDTH-1:0] shadow_data,
    output reg updated,
    output reg update_trigger
);
    // 影子数据更新逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_data <= {WIDTH{1'b0}};
            updated <= 1'b0;
            update_trigger <= 1'b0;
        end else begin
            if (tvalid) begin
                shadow_data <= main_reg_data;
                updated <= 1'b1;
                update_trigger <= 1'b1;
            end else if (tlast) begin
                updated <= 1'b0;
                update_trigger <= 1'b0;
            end
        end
    end
endmodule