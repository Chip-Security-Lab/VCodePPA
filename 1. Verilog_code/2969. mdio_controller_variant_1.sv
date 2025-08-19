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
    // 分频计数器
    reg [9:0] clk_counter;
    // 位计数器
    reg [3:0] bit_count;
    // 移位寄存器
    reg [31:0] shift_reg;
    // 控制MDIO输出使能
    reg mdio_oe;
    // MDIO输出值
    reg mdio_out;
    // 对输入信号进行寄存
    reg [4:0] reg_addr_reg;
    reg [15:0] data_in_reg;
    reg write_en_reg;
    
    // 缓存下一位要发送的数据
    reg next_bit;
    
    // 查找表辅助分频器 - 替代原始除法运算
    reg [3:0] clk_phase;
    reg mdc_value;
    
    // 查找表定义
    reg [3:0] quarter_phase;
    reg [3:0] half_phase;
    reg [3:0] three_quarter_phase;
    reg [3:0] full_phase;
    
    // 初始化查找表值
    initial begin
        quarter_phase = (CLK_DIV / 4) - 1;
        half_phase = (CLK_DIV / 2) - 1;
        three_quarter_phase = (CLK_DIV * 3 / 4) - 1;
        full_phase = CLK_DIV - 1;
    end
    
    // MDC时钟输出 - 使用查找表生成
    assign mdc = mdc_value;
    // MDIO总线三态控制
    assign mdio = mdio_oe ? mdio_out : 1'bz;

    // 输入信号寄存，减少输入到第一级寄存器的路径延迟
    always @(posedge clk) begin
        if (rst) begin
            reg_addr_reg <= 5'h0;
            data_in_reg <= 16'h0;
            write_en_reg <= 1'b0;
        end else begin
            reg_addr_reg <= reg_addr;
            data_in_reg <= data_in;
            write_en_reg <= write_en;
        end
    end

    // 使用查找表辅助的分频器和MDC生成
    always @(posedge clk) begin
        if (rst) begin
            clk_counter <= 10'h0;
            clk_phase <= 4'h0;
            mdc_value <= 1'b0;
        end else begin
            if (clk_counter >= full_phase) begin
                clk_counter <= 10'h0;
                clk_phase <= 4'h0;
            end else begin
                clk_counter <= clk_counter + 1'b1;
                
                // 根据查找表计算当前相位
                if (clk_counter == quarter_phase) begin
                    clk_phase <= 4'h1;
                end else if (clk_counter == half_phase) begin
                    clk_phase <= 4'h2;
                    mdc_value <= 1'b1;  // MDC翻转为高
                end else if (clk_counter == three_quarter_phase) begin
                    clk_phase <= 4'h3;
                end else if (clk_counter == full_phase) begin
                    clk_phase <= 4'h0;
                    mdc_value <= 1'b0;  // MDC翻转为低
                end
            end
        end
    end

    // 状态控制和数据处理
    always @(posedge clk) begin
        if (rst) begin
            bit_count <= 4'h0;
            mdio_oe <= 1'b0;
            mdio_done <= 1'b0;
            next_bit <= 1'b0;
            mdio_out <= 1'b0;
        end else begin
            // 在时钟周期中间预准备下一位数据，减少数据路径延迟
            if (clk_phase == 4'h1) begin
                if (bit_count < 32) begin
                    next_bit <= shift_reg[30];
                end
            end
            
            // 在分频周期结束时更新状态
            if (clk_phase == 4'h0 && clk_counter == 0) begin
                if (bit_count < 32) begin
                    shift_reg <= {shift_reg[30:0], mdio};
                    bit_count <= bit_count + 1'b1;
                end else begin
                    data_out <= shift_reg[15:0];
                    mdio_done <= 1'b1;
                end
            end

            // 当写使能有效且操作未完成时，准备发送数据
            if (write_en_reg && !mdio_done) begin
                mdio_oe <= 1'b1;
                shift_reg <= {2'b01, PHY_ADDR, reg_addr_reg, 2'b10, data_in_reg};
                mdio_out <= shift_reg[31];
            end
            
            // 当下一个位准备好时更新输出
            if (clk_phase == 4'h2 && bit_count < 31) begin
                mdio_out <= next_bit;
            end
        end
    end
endmodule