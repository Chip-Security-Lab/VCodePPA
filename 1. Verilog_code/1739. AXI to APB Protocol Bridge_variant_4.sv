//SystemVerilog
// 顶层模块
module axi2apb_bridge #(parameter DWIDTH=32, AWIDTH=32) (
    input clk, rst_n,
    // AXI-lite接口
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

    // 内部信号
    wire [DWIDTH-1:0] diff;
    wire borrow_out;
    wire [1:0] state;
    wire write_mode;
    wire apb_psel_next, apb_penable_next;
    wire [AWIDTH-1:0] apb_paddr_next;
    wire [DWIDTH-1:0] apb_pwdata_next;
    wire apb_pwrite_next;
    wire axi_awready_next, axi_wready_next, axi_arready_next;
    wire axi_rvalid_next, axi_bvalid_next;
    wire [DWIDTH-1:0] axi_rdata_next;

    // 实例化状态机模块
    fsm_controller #(DWIDTH, AWIDTH) fsm_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .axi_awaddr(axi_awaddr),
        .axi_araddr(axi_araddr),
        .axi_wdata(axi_wdata),
        .axi_awvalid(axi_awvalid),
        .axi_wvalid(axi_wvalid),
        .axi_arvalid(axi_arvalid),
        .axi_rready(axi_rready),
        .axi_bready(axi_bready),
        .apb_prdata(apb_prdata),
        .apb_pready(apb_pready),
        .diff(diff),
        .state(state),
        .write_mode(write_mode),
        .apb_psel_next(apb_psel_next),
        .apb_penable_next(apb_penable_next),
        .apb_paddr_next(apb_paddr_next),
        .apb_pwdata_next(apb_pwdata_next),
        .apb_pwrite_next(apb_pwrite_next),
        .axi_awready_next(axi_awready_next),
        .axi_wready_next(axi_wready_next),
        .axi_arready_next(axi_arready_next),
        .axi_rvalid_next(axi_rvalid_next),
        .axi_bvalid_next(axi_bvalid_next),
        .axi_rdata_next(axi_rdata_next)
    );

    // 实例化减法器模块
    parallel_subtractor #(DWIDTH) sub_unit (
        .minuend(apb_prdata),
        .subtrahend(axi_wdata),
        .diff(diff),
        .borrow_out(borrow_out)
    );

    // 输出寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            apb_psel <= 0;
            apb_penable <= 0;
            apb_paddr <= 0;
            apb_pwdata <= 0;
            apb_pwrite <= 0;
            axi_awready <= 1;
            axi_wready <= 1;
            axi_arready <= 1;
            axi_rvalid <= 0;
            axi_bvalid <= 0;
            axi_rdata <= 0;
        end else begin
            apb_psel <= apb_psel_next;
            apb_penable <= apb_penable_next;
            apb_paddr <= apb_paddr_next;
            apb_pwdata <= apb_pwdata_next;
            apb_pwrite <= apb_pwrite_next;
            axi_awready <= axi_awready_next;
            axi_wready <= axi_wready_next;
            axi_arready <= axi_arready_next;
            axi_rvalid <= axi_rvalid_next;
            axi_bvalid <= axi_bvalid_next;
            axi_rdata <= axi_rdata_next;
        end
    end

endmodule

// 状态机控制模块
module fsm_controller #(parameter DWIDTH=32, AWIDTH=32) (
    input clk, rst_n,
    input [AWIDTH-1:0] axi_awaddr, axi_araddr,
    input [DWIDTH-1:0] axi_wdata,
    input axi_awvalid, axi_wvalid, axi_arvalid, axi_rready, axi_bready,
    input [DWIDTH-1:0] apb_prdata,
    input apb_pready,
    input [DWIDTH-1:0] diff,
    output reg [1:0] state,
    output reg write_mode,
    output reg apb_psel_next, apb_penable_next,
    output reg [AWIDTH-1:0] apb_paddr_next,
    output reg [DWIDTH-1:0] apb_pwdata_next,
    output reg apb_pwrite_next,
    output reg axi_awready_next, axi_wready_next, axi_arready_next,
    output reg axi_rvalid_next, axi_bvalid_next,
    output reg [DWIDTH-1:0] axi_rdata_next
);

    parameter IDLE = 2'b00;
    parameter SETUP = 2'b01;
    parameter ACCESS = 2'b10;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            write_mode <= 0;
            apb_psel_next <= 0;
            apb_penable_next <= 0;
            apb_paddr_next <= 0;
            apb_pwdata_next <= 0;
            apb_pwrite_next <= 0;
            axi_awready_next <= 1;
            axi_wready_next <= 1;
            axi_arready_next <= 1;
            axi_rvalid_next <= 0;
            axi_bvalid_next <= 0;
            axi_rdata_next <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (axi_awvalid && axi_wvalid) begin
                        apb_paddr_next <= axi_awaddr;
                        apb_pwdata_next <= axi_wdata;
                        apb_pwrite_next <= 1;
                        apb_psel_next <= 1;
                        state <= SETUP;
                        write_mode <= 1;
                        axi_awready_next <= 0;
                        axi_wready_next <= 0;
                    end else if (axi_arvalid) begin
                        apb_paddr_next <= axi_araddr;
                        apb_pwrite_next <= 0;
                        apb_psel_next <= 1;
                        state <= SETUP;
                        write_mode <= 0;
                        axi_arready_next <= 0;
                    end
                end
                SETUP: begin
                    apb_penable_next <= 1;
                    state <= ACCESS;
                end
                ACCESS: begin
                    if (apb_pready) begin
                        apb_psel_next <= 0;
                        apb_penable_next <= 0;
                        state <= IDLE;
                        if (write_mode) begin
                            axi_bvalid_next <= 1;
                            axi_awready_next <= 1;
                            axi_wready_next <= 1;
                        end else begin
                            axi_rdata_next <= diff;
                            axi_rvalid_next <= 1;
                            axi_arready_next <= 1;
                        end
                    end
                end
                default: state <= IDLE;
            endcase
            
            if (axi_rvalid_next && axi_rready) axi_rvalid_next <= 0;
            if (axi_bvalid_next && axi_bready) axi_bvalid_next <= 0;
        end
    end
endmodule

// 并行前缀减法器模块
module parallel_subtractor #(parameter DWIDTH=32) (
    input [DWIDTH-1:0] minuend,
    input [DWIDTH-1:0] subtrahend,
    output [DWIDTH-1:0] diff,
    output borrow_out
);

    assign {borrow_out, diff} = minuend - subtrahend;

endmodule