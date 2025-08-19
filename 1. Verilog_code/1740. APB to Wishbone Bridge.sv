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
    always @(posedge clk) begin
        if (!rst_n) begin
            wb_cyc <= 0; wb_stb <= 0;
            apb_pready <= 0;
        end else if (apb_psel && !apb_penable) begin
            wb_adr <= apb_paddr;
            wb_we <= apb_pwrite;
            if (apb_pwrite) wb_dat_o <= apb_pwdata;
            apb_pready <= 0;
        end else if (apb_psel && apb_penable && !apb_pready) begin
            wb_cyc <= 1;
            wb_stb <= 1;
        end else if (wb_ack) begin
            wb_cyc <= 0;
            wb_stb <= 0;
            if (!wb_we) apb_prdata <= wb_dat_i;
            apb_pready <= 1;
        end else if (apb_pready && !(apb_psel && apb_penable)) begin
            apb_pready <= 0;
        end
    end
endmodule