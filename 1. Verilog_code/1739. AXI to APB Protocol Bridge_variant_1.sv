//SystemVerilog
module axi2apb_bridge #(parameter DWIDTH=32, AWIDTH=32) (
    input clk, rst_n,
    // AXI-lite接口(简化)
    input [AWIDTH-1:0] axi_awaddr, axi_araddr,
    input [DWIDTH-1:0] axi_wdata,
    input axi_awvalid, axi_wvalid, axi_arvalid, axi_rready, axi_bready,
    output reg [DWIDTH-1:0] axi_rdata,
    output reg axi_awready, axi_wready, axi_arready, axi_rvalid, axi_bvalid,
    // APB接口
    output reg [AWIDTH-1:0] apb_paddr,
    output reg [DWIDTH-1:0] apb_pwdata,
    output reg apb_pwrite, apb_psel, apb_penable,
    input [DWIDTH-1:0] apb_prdata,
    input apb_pready
);
    // 定义状态常量
    parameter IDLE = 2'b00;
    parameter SETUP = 2'b01;
    parameter ACCESS = 2'b10;

    reg [1:0] state, next_state;
    reg write_mode;

    // 寄存器用于存储中间信号
    reg [AWIDTH-1:0] addr_reg_stage1, addr_reg_stage2;
    reg [DWIDTH-1:0] data_reg_stage1, data_reg_stage2;

    // 流水线寄存器
    reg valid_stage1, valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // 状态和信号初始化
            state <= IDLE;
            valid_stage1 <= 0;
            valid_stage2 <= 0;
            apb_psel <= 0; apb_penable <= 0;
            axi_awready <= 1; axi_wready <= 1; axi_arready <= 1;
            axi_rvalid <= 0; axi_bvalid <= 0;
            write_mode <= 0;
            apb_paddr <= 0;
            apb_pwdata <= 0;
            axi_rdata <= 0;
        end else begin
            // 更新状态
            state <= next_state;

            // 处理输出有效信号
            if (axi_rvalid && axi_rready) axi_rvalid <= 0;
            if (axi_bvalid && axi_bready) axi_bvalid <= 0;
        end
    end

    always @(*) begin
        // 默认状态
        next_state = state;
        valid_stage1 = 0;
        valid_stage2 = 0;

        case (state)
            IDLE: begin
                if (axi_awvalid && axi_wvalid) begin
                    addr_reg_stage1 = axi_awaddr;
                    data_reg_stage1 = axi_wdata;
                    apb_paddr = addr_reg_stage1;
                    apb_pwdata = data_reg_stage1;
                    apb_pwrite = 1;
                    apb_psel = 1;
                    next_state = SETUP;
                    write_mode = 1;
                    axi_awready = 0;
                    axi_wready = 0;
                    valid_stage1 = 1;
                end else if (axi_arvalid) begin
                    addr_reg_stage1 = axi_araddr;
                    apb_paddr = addr_reg_stage1;
                    apb_pwrite = 0;
                    apb_psel = 1;
                    next_state = SETUP;
                    write_mode = 0;
                    axi_arready = 0;
                    valid_stage1 = 1;
                end
            end
            SETUP: begin
                apb_penable = 1;
                next_state = ACCESS;
                valid_stage2 = valid_stage1; // 传递有效信号
            end
            ACCESS: begin
                if (apb_pready) begin
                    apb_psel = 0;
                    apb_penable = 0;
                    next_state = IDLE;
                    if (write_mode) begin
                        axi_bvalid = 1;
                        axi_awready = 1;
                        axi_wready = 1;
                    end else begin
                        axi_rdata = apb_prdata;
                        axi_rvalid = 1;
                        axi_arready = 1;
                    end
                end
            end
            default: next_state = IDLE;
        endcase
    end
endmodule