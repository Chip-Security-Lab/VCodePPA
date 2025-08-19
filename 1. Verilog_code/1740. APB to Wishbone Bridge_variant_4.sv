//SystemVerilog
module apb2wb_bridge #(parameter WIDTH=32) (
    input clk, rst_n,
    // APB interface
    input [WIDTH-1:0] apb_paddr, apb_pwdata,
    input apb_pwrite, apb_psel, apb_penable,
    output reg [WIDTH-1:0] apb_prdata,
    output reg apb_pready,
    // Wishbone interface
    output reg [WIDTH-1:0] wb_adr, wb_dat_o,
    output reg wb_we, wb_cyc, wb_stb,
    input [WIDTH-1:0] wb_dat_i,
    input wb_ack
);

    // Control signals
    wire start_transfer;
    wire transfer_complete;
    wire clear_ready;

    // Buffer for high fanout signals
    wire clk_buf, rst_n_buf;
    wire [WIDTH-1:0] apb_paddr_buf, apb_pwdata_buf;
    wire apb_pwrite_buf, apb_psel_buf, apb_penable_buf;

    // Buffering high fanout signals
    assign clk_buf = clk;
    assign rst_n_buf = rst_n;
    assign apb_paddr_buf = apb_paddr;
    assign apb_pwdata_buf = apb_pwdata;
    assign apb_pwrite_buf = apb_pwrite;
    assign apb_psel_buf = apb_psel;
    assign apb_penable_buf = apb_penable;

    // APB Control Module
    apb_control #(WIDTH) u_apb_control (
        .clk(clk_buf),
        .rst_n(rst_n_buf),
        .apb_psel(apb_psel_buf),
        .apb_penable(apb_penable_buf),
        .apb_pready(apb_pready),
        .wb_ack(wb_ack),
        .start_transfer(start_transfer),
        .transfer_complete(transfer_complete),
        .clear_ready(clear_ready)
    );

    // Address/Data Module
    addr_data #(WIDTH) u_addr_data (
        .clk(clk_buf),
        .rst_n(rst_n_buf),
        .apb_paddr(apb_paddr_buf),
        .apb_pwdata(apb_pwdata_buf),
        .apb_pwrite(apb_pwrite_buf),
        .wb_dat_i(wb_dat_i),
        .wb_we(wb_we),
        .wb_adr(wb_adr),
        .wb_dat_o(wb_dat_o),
        .apb_prdata(apb_prdata)
    );

    // Wishbone Control Module
    wb_control #(WIDTH) u_wb_control (
        .clk(clk_buf),
        .rst_n(rst_n_buf),
        .start_transfer(start_transfer),
        .transfer_complete(transfer_complete),
        .wb_ack(wb_ack),
        .wb_cyc(wb_cyc),
        .wb_stb(wb_stb)
    );

endmodule

module apb_control #(parameter WIDTH=32) (
    input clk, rst_n,
    input apb_psel, apb_penable,
    input wb_ack,
    output reg apb_pready,
    output reg start_transfer,
    output reg transfer_complete,
    output reg clear_ready
);

    always @(posedge clk) begin
        if (!rst_n) begin
            apb_pready <= 0;
            start_transfer <= 0;
            transfer_complete <= 0;
            clear_ready <= 0;
        end else begin
            if (apb_psel && !apb_penable) begin
                start_transfer <= 1;
                apb_pready <= 0;
            end else if (wb_ack) begin
                transfer_complete <= 1;
                apb_pready <= 1;
            end else if (apb_pready && !(apb_psel && apb_penable)) begin
                clear_ready <= 1;
                apb_pready <= 0;
            end else begin
                start_transfer <= 0;
                transfer_complete <= 0;
                clear_ready <= 0;
            end
        end
    end

endmodule

module addr_data #(parameter WIDTH=32) (
    input clk, rst_n,
    input [WIDTH-1:0] apb_paddr, apb_pwdata,
    input apb_pwrite,
    input [WIDTH-1:0] wb_dat_i,
    output reg wb_we,
    output reg [WIDTH-1:0] wb_adr, wb_dat_o,
    output reg [WIDTH-1:0] apb_prdata
);

    always @(posedge clk) begin
        if (!rst_n) begin
            wb_adr <= 0;
            wb_dat_o <= 0;
            wb_we <= 0;
            apb_prdata <= 0;
        end else begin
            wb_adr <= apb_paddr;
            wb_we <= apb_pwrite;
            if (apb_pwrite) wb_dat_o <= apb_pwdata;
            if (!wb_we) apb_prdata <= wb_dat_i;
        end
    end

endmodule

module wb_control #(parameter WIDTH=32) (
    input clk, rst_n,
    input start_transfer,
    input transfer_complete,
    input wb_ack,
    output reg wb_cyc, wb_stb
);

    always @(posedge clk) begin
        if (!rst_n) begin
            wb_cyc <= 0;
            wb_stb <= 0;
        end else if (start_transfer) begin
            wb_cyc <= 1;
            wb_stb <= 1;
        end else if (transfer_complete) begin
            wb_cyc <= 0;
            wb_stb <= 0;
        end
    end

endmodule