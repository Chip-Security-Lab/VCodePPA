//SystemVerilog
module load_complete_reg (
    input wire clk,
    input wire rst,
    input wire [15:0] data_in,
    input wire valid,
    output wire ready,
    output wire [15:0] data_out,
    output wire transfer_complete
);

    // 内部信号，用于模块互连
    wire valid_accepted;
    wire [15:0] data_register;

    // 握手控制单元
    handshake_control handshake_ctrl_inst (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .ready(ready),
        .valid_accepted(valid_accepted)
    );

    // 数据处理单元
    data_processing data_proc_inst (
        .clk(clk),
        .rst(rst),
        .data_in(data_in),
        .valid(valid),
        .ready(ready),
        .data_out(data_register)
    );

    // 状态指示单元
    status_indicator status_ind_inst (
        .valid_accepted(valid_accepted),
        .transfer_complete(transfer_complete)
    );

    // 数据输出寄存单元
    output_register output_reg_inst (
        .clk(clk),
        .rst(rst),
        .data_in(data_register),
        .valid_accepted(valid_accepted),
        .data_out(data_out)
    );

endmodule

// 握手控制子模块
module handshake_control (
    input wire clk,
    input wire rst,
    input wire valid,
    output wire ready,
    output reg valid_accepted
);

    // Ready信号逻辑 - 当未处于复位状态且没有正在处理数据时，系统就准备好接收新数据
    assign ready = !rst && !valid_accepted;

    always @(posedge clk) begin
        if (rst) begin
            valid_accepted <= 1'b0;
        end else begin
            // 握手成功条件：valid和ready同时为高
            if (valid && ready) begin
                valid_accepted <= 1'b1;
            end else begin
                valid_accepted <= 1'b0;
            end
        end
    end

endmodule

// 数据处理子模块
module data_processing (
    input wire clk,
    input wire rst,
    input wire [15:0] data_in,
    input wire valid,
    input wire ready,
    output reg [15:0] data_out
);

    always @(posedge clk) begin
        if (rst) begin
            data_out <= 16'h0;
        end else if (valid && ready) begin
            data_out <= data_in;
        end
    end

endmodule

// 状态指示子模块
module status_indicator (
    input wire valid_accepted,
    output wire transfer_complete
);

    // 传输完成标志 - 当数据被接受时有效
    assign transfer_complete = valid_accepted;

endmodule

// 输出寄存子模块
module output_register (
    input wire clk,
    input wire rst,
    input wire [15:0] data_in,
    input wire valid_accepted,
    output reg [15:0] data_out
);

    always @(posedge clk) begin
        if (rst) begin
            data_out <= 16'h0;
        end else if (valid_accepted) begin
            data_out <= data_in;
        end
    end

endmodule