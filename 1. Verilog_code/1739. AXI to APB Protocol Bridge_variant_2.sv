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
    reg [1:0] next_state;
    
    // 状态转换逻辑
    always @(*) begin
        case (state)
            IDLE: begin
                if (axi_awvalid && axi_wvalid) begin
                    next_state = SETUP;
                end else if (axi_arvalid) begin
                    next_state = SETUP;
                end else begin
                    next_state = IDLE;
                end
            end
            SETUP: next_state = ACCESS;
            ACCESS: begin
                if (apb_pready) begin
                    next_state = IDLE;
                end else begin
                    next_state = ACCESS;
                end
            end
            default: next_state = IDLE;
        endcase
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            apb_psel <= 0; apb_penable <= 0;
            axi_awready <= 1; axi_wready <= 1; axi_arready <= 1;
            axi_rvalid <= 0; axi_bvalid <= 0;
            write_mode <= 0;
            apb_paddr <= 0;
            apb_pwdata <= 0;
            apb_pwrite <= 0;
            axi_rdata <= 0;
        end else begin
            state <= next_state;
            
            case (state)
                IDLE: begin
                    if (axi_awvalid && axi_wvalid) begin
                        apb_paddr <= axi_awaddr;
                        apb_pwdata <= axi_wdata;
                        apb_pwrite <= 1;
                        apb_psel <= 1;
                        write_mode <= 1;
                        axi_awready <= 0;
                        axi_wready <= 0;
                    end else if (axi_arvalid) begin
                        apb_paddr <= axi_araddr;
                        apb_pwrite <= 0;
                        apb_psel <= 1;
                        write_mode <= 0;
                        axi_arready <= 0;
                    end
                end
                SETUP: begin
                    apb_penable <= 1;
                end
                ACCESS: begin
                    if (apb_pready) begin
                        apb_psel <= 0;
                        apb_penable <= 0;
                        if (write_mode) begin
                            axi_bvalid <= 1;
                            axi_awready <= 1;
                            axi_wready <= 1;
                        end else begin
                            axi_rdata <= apb_prdata;
                            axi_rvalid <= 1;
                            axi_arready <= 1;
                        end
                    end
                end
            endcase
            
            if (axi_rvalid && axi_rready) axi_rvalid <= 0;
            if (axi_bvalid && axi_bready) axi_bvalid <= 0;
        end
    end
endmodule