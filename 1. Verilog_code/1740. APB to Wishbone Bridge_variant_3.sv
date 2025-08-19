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
    // Pipeline registers for address and data paths
    reg [WIDTH-1:0] apb_paddr_r;
    reg [WIDTH-1:0] apb_pwdata_r;
    reg apb_pwrite_r;
    reg apb_psel_r, apb_penable_r;
    reg wb_ack_r;
    reg [WIDTH-1:0] wb_dat_i_r;
    
    // State machine registers
    reg waiting_for_ack;
    
    // First stage: Register APB signals to reduce input path delay
    always @(posedge clk) begin
        if (!rst_n) begin
            apb_paddr_r <= 0;
            apb_pwdata_r <= 0;
            apb_pwrite_r <= 0;
            apb_psel_r <= 0;
            apb_penable_r <= 0;
        end else begin
            apb_paddr_r <= apb_paddr;
            apb_pwdata_r <= apb_pwdata;
            apb_pwrite_r <= apb_pwrite;
            apb_psel_r <= apb_psel;
            apb_penable_r <= apb_penable;
        end
    end
    
    // Second stage: Register Wishbone responses
    always @(posedge clk) begin
        if (!rst_n) begin
            wb_ack_r <= 0;
            wb_dat_i_r <= 0;
        end else begin
            wb_ack_r <= wb_ack;
            wb_dat_i_r <= wb_dat_i;
        end
    end
    
    // Main control logic - now simplified with registered inputs
    always @(posedge clk) begin
        if (!rst_n) begin
            wb_cyc <= 0;
            wb_stb <= 0;
            apb_pready <= 0;
            waiting_for_ack <= 0;
            wb_adr <= 0;
            wb_we <= 0;
            wb_dat_o <= 0;
            apb_prdata <= 0;
        end else begin
            // Default assignment for special signals
            if (wb_ack_r) begin
                wb_cyc <= 0;
                wb_stb <= 0;
            end
            
            // Control flow with pipelined signals
            if (apb_psel_r && !apb_penable_r) begin
                // Setup phase
                wb_adr <= apb_paddr_r;
                wb_we <= apb_pwrite_r;
                if (apb_pwrite_r) wb_dat_o <= apb_pwdata_r;
                apb_pready <= 0;
                waiting_for_ack <= 0;
            end else if (apb_psel_r && apb_penable_r && !apb_pready && !waiting_for_ack) begin
                // Access phase - initiate Wishbone transaction
                wb_cyc <= 1;
                wb_stb <= 1;
                waiting_for_ack <= 1;
            end else if (wb_ack_r && waiting_for_ack) begin
                // Wishbone transaction complete
                if (!wb_we) apb_prdata <= wb_dat_i_r;
                apb_pready <= 1;
                waiting_for_ack <= 0;
            end else if (apb_pready && !(apb_psel_r && apb_penable_r)) begin
                // Reset pready for next transaction
                apb_pready <= 0;
            end
        end
    end
endmodule