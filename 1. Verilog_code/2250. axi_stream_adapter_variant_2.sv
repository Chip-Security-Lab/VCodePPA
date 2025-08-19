//SystemVerilog
// 顶层模块
module axi_stream_adapter #(
    parameter DW = 32
) (
    input                 clk,
    input                 resetn,
    input      [DW-1:0]   tdata,
    input                 tvalid,
    output wire           tready,
    output wire [DW-1:0]  rdata,
    output wire           rvalid
);
    // 内部信号
    wire [DW-1:0] data_buf;
    wire          valid_buf;
    wire          transfer_done;
    wire          clear_valid;

    // 输入处理子模块
    axi_input_handler #(
        .DW(DW)
    ) input_handler (
        .clk           (clk),
        .resetn        (resetn),
        .tdata         (tdata),
        .tvalid        (tvalid),
        .tready        (tready),
        .clear_valid   (clear_valid),
        .data_buf      (data_buf),
        .valid_buf     (valid_buf),
        .transfer_done (transfer_done)
    );

    // 输出处理子模块
    axi_output_handler #(
        .DW(DW)
    ) output_handler (
        .clk           (clk),
        .resetn        (resetn),
        .data_buf      (data_buf),
        .valid_buf     (valid_buf),
        .transfer_done (transfer_done),
        .rdata         (rdata),
        .rvalid        (rvalid),
        .clear_valid   (clear_valid)
    );

endmodule

// 输入处理子模块
module axi_input_handler #(
    parameter DW = 32
) (
    input                  clk,
    input                  resetn,
    input      [DW-1:0]    tdata,
    input                  tvalid,
    output reg             tready,
    input                  clear_valid,
    output reg [DW-1:0]    data_buf,
    output reg             valid_buf,
    output reg             transfer_done
);
    // LUT辅助减法器相关信号
    reg [7:0] minuend, subtrahend;
    wire [7:0] difference;
    reg [3:0] high_nibble, low_nibble;
    reg [7:0] lut_result;

    // 查找表ROM - 用于减法运算，分高低4位存储
    reg [7:0] sub_lut_high [0:15][0:15]; // 高4位LUT
    reg [7:0] sub_lut_low [0:15][0:15];  // 低4位LUT
    
    // 初始化查找表
    integer i, j;
    initial begin
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin
                sub_lut_high[i][j] = (i - j) & 8'hF0; // 高4位减法
                sub_lut_low[i][j] = (i - j) & 8'h0F;  // 低4位减法
            end
        end
    end

    // 实现基于LUT的减法器
    always @(posedge clk) begin
        if (!resetn) begin
            minuend <= 8'h0;
            subtrahend <= 8'h0;
            high_nibble <= 4'h0;
            low_nibble <= 4'h0;
            lut_result <= 8'h0;
        end else if (tvalid & tready) begin
            // 提取操作数（假设从tdata提取8位减法操作数）
            minuend <= tdata[7:0];
            subtrahend <= tdata[15:8];
            
            // 分解为高低4位
            high_nibble <= (tdata[7:4] - tdata[15:12]) & 4'hF;
            low_nibble <= (tdata[3:0] - tdata[11:8]) & 4'hF;
            
            // 查表计算结果
            lut_result <= sub_lut_high[tdata[7:4]][tdata[15:12]] | 
                         sub_lut_low[tdata[3:0]][tdata[11:8]];
        end
    end

    // 差值计算
    assign difference = lut_result;

    always @(posedge clk) begin
        if (!resetn) begin
            tready <= 1'b1;
            data_buf <= {DW{1'b0}};
            valid_buf <= 1'b0;
            transfer_done <= 1'b0;
        end else begin
            // 数据采集阶段
            if (tvalid & tready) begin
                // 使用查找表结果，但保持DW宽度
                data_buf <= {{(DW-8){1'b0}}, difference};  // 仅修改低8位，保持高位
                valid_buf <= 1'b1;
                tready <= 1'b0;
                transfer_done <= 1'b1;
            end else begin
                transfer_done <= 1'b0;
                if (!valid_buf) begin
                    tready <= 1'b1;
                end
            end
            
            // 清除有效标志
            if (clear_valid) begin
                valid_buf <= 1'b0;
            end
        end
    end

endmodule

// 输出处理子模块
module axi_output_handler #(
    parameter DW = 32
) (
    input                  clk,
    input                  resetn,
    input      [DW-1:0]    data_buf,
    input                  valid_buf,
    input                  transfer_done,
    output reg [DW-1:0]    rdata,
    output reg             rvalid,
    output wire            clear_valid
);

    // 清除有效标志信号
    assign clear_valid = rvalid;

    always @(posedge clk) begin
        if (!resetn) begin
            rdata <= {DW{1'b0}};
            rvalid <= 1'b0;
        end else begin
            // 输出控制阶段
            if (transfer_done) begin
                rdata <= data_buf;
                rvalid <= 1'b1;
            end else begin
                rvalid <= 1'b0;
            end
        end
    end

endmodule