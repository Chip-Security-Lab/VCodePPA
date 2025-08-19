//SystemVerilog
// 顶层模块
module priority_bridge #(
    parameter DWIDTH = 32
) (
    input clk, rst_n,
    input [DWIDTH-1:0] high_data, low_data,
    input high_valid, low_valid,
    output high_ready, low_ready,
    output [DWIDTH-1:0] out_data,
    output out_valid,
    input out_ready
);
    // 内部信号
    wire priority_grant;
    wire data_transfer;
    wire [DWIDTH-1:0] selected_data;
    wire transfer_complete;
    
    // 实例化优先级仲裁器子模块
    priority_arbiter u_priority_arbiter (
        .clk(clk),
        .rst_n(rst_n),
        .high_valid(high_valid),
        .low_valid(low_valid),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .priority_grant(priority_grant),
        .data_transfer(data_transfer),
        .transfer_complete(transfer_complete)
    );
    
    // 实例化数据选择器子模块
    data_selector #(
        .DWIDTH(DWIDTH)
    ) u_data_selector (
        .high_data(high_data),
        .low_data(low_data),
        .priority_grant(priority_grant),
        .selected_data(selected_data)
    );
    
    // 实例化输出控制器子模块
    output_controller #(
        .DWIDTH(DWIDTH)
    ) u_output_controller (
        .clk(clk),
        .rst_n(rst_n),
        .selected_data(selected_data),
        .data_transfer(data_transfer),
        .transfer_complete(transfer_complete),
        .out_data(out_data),
        .out_valid(out_valid),
        .out_ready(out_ready),
        .high_ready(high_ready),
        .low_ready(low_ready)
    );
    
endmodule

// 优先级仲裁器子模块
module priority_arbiter (
    input clk,
    input rst_n,
    input high_valid,
    input low_valid,
    input out_valid,
    input out_ready,
    output reg priority_grant,    // 1表示选择高优先级，0表示选择低优先级
    output reg data_transfer,     // 表示需要传输新数据
    output reg transfer_complete  // 表示传输完成
);
    reg transfer_in_progress;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            priority_grant <= 0;
            data_transfer <= 0;
            transfer_complete <= 0;
            transfer_in_progress <= 0;
        end else begin
            // 默认状态
            data_transfer <= 0;
            transfer_complete <= 0;
            
            // 当输出就绪或未有效时，检查是否有新数据待传输
            if (!out_valid || out_ready) begin
                if (high_valid) begin
                    priority_grant <= 1;  // 选择高优先级数据
                    data_transfer <= 1;   // 触发数据传输
                    transfer_in_progress <= 1;
                end else if (low_valid) begin
                    priority_grant <= 0;  // 选择低优先级数据
                    data_transfer <= 1;   // 触发数据传输
                    transfer_in_progress <= 1;
                end
            end
            
            // 当输出有效且已就绪时，表示传输完成
            if (out_valid && out_ready) begin
                transfer_complete <= 1;
                transfer_in_progress <= 0;
            end
        end
    end
endmodule

// 数据选择器子模块
module data_selector #(
    parameter DWIDTH = 32
) (
    input [DWIDTH-1:0] high_data,
    input [DWIDTH-1:0] low_data,
    input priority_grant,
    output [DWIDTH-1:0] selected_data
);
    // 基于优先级信号选择数据
    assign selected_data = priority_grant ? high_data : low_data;
endmodule

// 输出控制器子模块
module output_controller #(
    parameter DWIDTH = 32
) (
    input clk,
    input rst_n,
    input [DWIDTH-1:0] selected_data,
    input data_transfer,
    input transfer_complete,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid,
    input out_ready,
    output reg high_ready,
    output reg low_ready
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data <= {DWIDTH{1'b0}};
            out_valid <= 0;
            high_ready <= 1;
            low_ready <= 1;
        end else begin
            // 当需要传输新数据时
            if (data_transfer) begin
                out_data <= selected_data;
                out_valid <= 1;
                high_ready <= 0;
                low_ready <= 0;
            end
            
            // 传输完成时
            if (transfer_complete) begin
                out_valid <= 0;
                high_ready <= 1;
                low_ready <= 1;
            end
        end
    end
endmodule