//SystemVerilog
// 顶层模块
module pl_reg_dualport #(
    parameter W = 16
) (
    input clk, 
    input wr1_en, wr2_en,
    input [W-1:0] wr1_data, wr2_data,
    output [W-1:0] q
);
    // 内部信号
    reg [W-1:0] wr1_data_reg, wr2_data_reg;
    reg wr1_en_reg, wr2_en_reg;
    wire [W-1:0] selected_data;
    wire write_en;
    
    // 寄存输入信号以减少输入到第一级寄存器的延迟
    always @(posedge clk) begin
        wr1_data_reg <= wr1_data;
        wr2_data_reg <= wr2_data;
        wr1_en_reg <= wr1_en;
        wr2_en_reg <= wr2_en;
    end
    
    // 实例化端口优先级选择子模块
    port_priority_selector #(
        .W(W)
    ) port_selector (
        .wr1_en(wr1_en_reg),
        .wr2_en(wr2_en_reg),
        .wr1_data(wr1_data_reg),
        .wr2_data(wr2_data_reg),
        .selected_data(selected_data),
        .write_en(write_en)
    );
    
    // 实例化寄存器存储子模块
    register_storage #(
        .W(W)
    ) reg_storage (
        .clk(clk),
        .write_en(write_en),
        .data_in(selected_data),
        .data_out(q)
    );
    
endmodule

// 端口优先级选择器子模块
module port_priority_selector #(
    parameter W = 16
) (
    input wr1_en, wr2_en,
    input [W-1:0] wr1_data, wr2_data,
    output [W-1:0] selected_data,
    output write_en
);
    // 根据端口优先级选择数据
    assign write_en = wr1_en | wr2_en;
    assign selected_data = wr1_en ? wr1_data : 
                          (wr2_en ? wr2_data : {W{1'b0}});
endmodule

// 寄存器存储子模块
module register_storage #(
    parameter W = 16
) (
    input clk,
    input write_en,
    input [W-1:0] data_in,
    output reg [W-1:0] data_out
);
    // 在时钟上升沿写入数据
    always @(posedge clk) begin
        if (write_en) begin
            data_out <= data_in;
        end
    end
endmodule