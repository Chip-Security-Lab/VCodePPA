//SystemVerilog
module mdio_controller #(
    parameter PHY_ADDR = 5'h01,
    parameter CLK_DIV = 64
)(
    input clk,
    input rst,
    input [4:0] reg_addr,
    input [15:0] data_in,
    input write_en,
    output reg [15:0] data_out,
    output reg mdio_done,
    inout mdio,
    output mdc
);
    // 内部信号定义 - 增加流水线级别
    reg [9:0] clk_counter;
    reg [3:0] bit_count_stage1, bit_count_stage2;
    reg [31:0] shift_reg_stage1, shift_reg_stage2, shift_reg_stage3;
    reg mdio_oe_stage1, mdio_oe_stage2, mdio_oe_stage3;
    reg mdio_out_stage1, mdio_out_stage2, mdio_out_stage3;
    reg shift_enable_stage1, shift_enable_stage2;
    reg data_capture_stage1, data_capture_stage2;
    reg write_en_stage1, write_en_stage2;
    reg mdio_done_internal;
    reg mdio_in_stage1, mdio_in_stage2;
    
    // MDC时钟生成
    assign mdc = clk_counter[CLK_DIV/2];
    
    // MDIO双向接口控制
    assign mdio = mdio_oe_stage3 ? mdio_out_stage3 : 1'bz;
    
    // 时钟分频计数器 - 第一级流水线
    always @(posedge clk) begin
        if (rst) begin
            clk_counter <= 10'b0;
        end else begin
            clk_counter <= clk_counter + 10'b1;
        end
    end
    
    // 信号捕获 - 增加流水线级别
    always @(posedge clk) begin
        if (rst) begin
            mdio_in_stage1 <= 1'b0;
            mdio_in_stage2 <= 1'b0;
            write_en_stage1 <= 1'b0;
            write_en_stage2 <= 1'b0;
        end else begin
            mdio_in_stage1 <= mdio;
            mdio_in_stage2 <= mdio_in_stage1;
            write_en_stage1 <= write_en;
            write_en_stage2 <= write_en_stage1;
        end
    end
    
    // 控制位计数和数据操作触发信号 - 第一级流水线
    always @(posedge clk) begin
        if (rst) begin
            shift_enable_stage1 <= 1'b0;
            data_capture_stage1 <= 1'b0;
        end else begin
            shift_enable_stage1 <= (clk_counter == CLK_DIV-1) && (bit_count_stage1 < 32);
            data_capture_stage1 <= (clk_counter == CLK_DIV-1) && (bit_count_stage1 >= 32);
        end
    end
    
    // 控制信号流水线 - 第二级流水线
    always @(posedge clk) begin
        if (rst) begin
            shift_enable_stage2 <= 1'b0;
            data_capture_stage2 <= 1'b0;
        end else begin
            shift_enable_stage2 <= shift_enable_stage1;
            data_capture_stage2 <= data_capture_stage1;
        end
    end
    
    // 位计数器控制 - 第一级流水线
    always @(posedge clk) begin
        if (rst) begin
            bit_count_stage1 <= 4'b0;
        end else if (shift_enable_stage1) begin
            bit_count_stage1 <= bit_count_stage1 + 4'b1;
        end else if (write_en_stage1 && !mdio_done_internal) begin
            bit_count_stage1 <= 4'b0;
        end
    end
    
    // 位计数器流水线 - 第二级流水线
    always @(posedge clk) begin
        if (rst) begin
            bit_count_stage2 <= 4'b0;
        end else begin
            bit_count_stage2 <= bit_count_stage1;
        end
    end
    
    // 移位寄存器控制 - 第一级流水线
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_stage1 <= 32'b0;
        end else if (write_en_stage1 && !mdio_done_internal) begin
            shift_reg_stage1 <= {2'b01, PHY_ADDR, reg_addr, 2'b10, data_in};
        end else if (shift_enable_stage1) begin
            shift_reg_stage1 <= {shift_reg_stage1[30:0], mdio_in_stage1};
        end
    end
    
    // 移位寄存器流水线 - 第二级和第三级流水线
    always @(posedge clk) begin
        if (rst) begin
            shift_reg_stage2 <= 32'b0;
            shift_reg_stage3 <= 32'b0;
        end else begin
            shift_reg_stage2 <= shift_reg_stage1;
            shift_reg_stage3 <= shift_reg_stage2;
        end
    end
    
    // MDIO输出控制 - 第一级流水线
    always @(posedge clk) begin
        if (rst) begin
            mdio_oe_stage1 <= 1'b0;
            mdio_out_stage1 <= 1'b0;
        end else if (write_en_stage1 && !mdio_done_internal) begin
            mdio_oe_stage1 <= 1'b1;
        end else if (shift_enable_stage1) begin
            mdio_out_stage1 <= shift_reg_stage1[31];
        end
    end
    
    // MDIO输出流水线 - 第二级和第三级流水线
    always @(posedge clk) begin
        if (rst) begin
            mdio_oe_stage2 <= 1'b0;
            mdio_oe_stage3 <= 1'b0;
            mdio_out_stage2 <= 1'b0;
            mdio_out_stage3 <= 1'b0;
        end else begin
            mdio_oe_stage2 <= mdio_oe_stage1;
            mdio_oe_stage3 <= mdio_oe_stage2;
            mdio_out_stage2 <= mdio_out_stage1;
            mdio_out_stage3 <= mdio_out_stage2;
        end
    end
    
    // 数据输出和完成标志内部控制
    always @(posedge clk) begin
        if (rst) begin
            mdio_done_internal <= 1'b0;
        end else if (data_capture_stage2) begin
            mdio_done_internal <= 1'b1;
        end else if (write_en_stage2) begin
            mdio_done_internal <= 1'b0;
        end
    end
    
    // 数据输出和完成标志最终控制 - 输出级流水线
    always @(posedge clk) begin
        if (rst) begin
            data_out <= 16'b0;
            mdio_done <= 1'b0;
        end else begin
            if (data_capture_stage2) begin
                data_out <= shift_reg_stage2[15:0];
            end
            mdio_done <= mdio_done_internal;
        end
    end
    
endmodule