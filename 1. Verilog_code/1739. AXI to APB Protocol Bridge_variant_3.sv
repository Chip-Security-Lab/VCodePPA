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
    
    reg [1:0] state;
    reg write_mode;
    
    // 状态机及APB接口控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            apb_psel <= 0;
            apb_penable <= 0;
            write_mode <= 0;
            apb_pwrite <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (axi_awvalid && axi_wvalid) begin
                        handle_write();
                    end else if (axi_arvalid) begin
                        handle_read();
                    end
                end
                SETUP: begin
                    apb_penable <= 1;
                    state <= ACCESS;
                end
                ACCESS: begin
                    if (apb_pready) begin
                        reset_apb_signals();
                        state <= IDLE;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end

    task handle_write;
    begin
        apb_pwrite <= 1;
        apb_psel <= 1;
        state <= SETUP;
        write_mode <= 1;
        apb_paddr <= axi_awaddr;
        apb_pwdata <= axi_wdata;
    end
    endtask

    task handle_read;
    begin
        apb_pwrite <= 0;
        apb_psel <= 1;
        state <= SETUP;
        write_mode <= 0;
        apb_paddr <= axi_araddr;
    end
    endtask

    task reset_apb_signals;
    begin
        apb_psel <= 0;
        apb_penable <= 0;
    end
    endtask
    
    // AXI写通道控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_awready <= 1;
            axi_wready <= 1;
            axi_bvalid <= 0;
        end else begin
            if (state == IDLE) begin
                if (axi_awvalid && axi_wvalid) begin
                    axi_awready <= 0;
                    axi_wready <= 0;
                end
            end else if (state == ACCESS && apb_pready && write_mode) begin
                axi_bvalid <= 1;
                axi_awready <= 1;
                axi_wready <= 1;
            end else if (axi_bvalid && axi_bready) begin
                axi_bvalid <= 0;
            end
        end
    end
    
    // AXI读通道控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_arready <= 1;
            axi_rvalid <= 0;
            axi_rdata <= 0;
        end else begin
            if (state == IDLE && axi_arvalid) begin
                axi_arready <= 0;
            end else if (state == ACCESS && apb_pready && !write_mode) begin
                axi_rdata <= apb_prdata;
                axi_rvalid <= 1;
                axi_arready <= 1;
            end else if (axi_rvalid && axi_rready) begin
                axi_rvalid <= 0;
            end
        end
    end
    
endmodule