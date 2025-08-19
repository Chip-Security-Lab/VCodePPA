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
    // Pipeline stage registers
    reg [WIDTH-1:0] addr_stage1, wdata_stage1;
    reg write_stage1;
    reg valid_stage1, valid_stage2;
    reg [WIDTH-1:0] rdata_stage2;
    reg transaction_active;
    
    // APB handshake state
    localparam IDLE = 2'b00;
    localparam SETUP = 2'b01;
    localparam ACCESS = 2'b10;
    localparam WAIT_ACK = 2'b11;
    
    reg [1:0] apb_state, next_apb_state;
    
    // Stage 1: APB Interface and Request Processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_stage1 <= 0;
            wdata_stage1 <= 0;
            write_stage1 <= 0;
            valid_stage1 <= 0;
            apb_state <= IDLE;
        end else begin
            case (apb_state)
                IDLE: begin
                    valid_stage1 <= 0;
                    if (apb_psel && !apb_penable) begin
                        addr_stage1 <= apb_paddr;
                        wdata_stage1 <= apb_pwdata;
                        write_stage1 <= apb_pwrite;
                        apb_state <= SETUP;
                    end
                end
                
                SETUP: begin
                    if (apb_psel && apb_penable) begin
                        valid_stage1 <= 1;
                        apb_state <= ACCESS;
                    end
                end
                
                ACCESS: begin
                    if (valid_stage2) begin
                        valid_stage1 <= 0;
                        apb_state <= transaction_active ? IDLE : WAIT_ACK;
                    end
                end
                
                WAIT_ACK: begin
                    if (!transaction_active) begin
                        apb_state <= IDLE;
                    end
                end
            endcase
        end
    end
    
    // Stage 2: Wishbone Interface Control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_adr <= 0;
            wb_dat_o <= 0;
            wb_we <= 0;
            wb_cyc <= 0;
            wb_stb <= 0;
            valid_stage2 <= 0;
            transaction_active <= 0;
        end else begin
            // Forward valid signal through pipeline
            valid_stage2 <= valid_stage1;
            
            // Handle transaction start
            if (valid_stage1 && !transaction_active) begin
                wb_adr <= addr_stage1;
                wb_we <= write_stage1;
                if (write_stage1) begin
                    wb_dat_o <= wdata_stage1;
                end
                wb_cyc <= 1;
                wb_stb <= 1;
                transaction_active <= 1;
            end
            
            // Handle transaction completion
            if (wb_ack && transaction_active) begin
                wb_cyc <= 0;
                wb_stb <= 0;
                if (!wb_we) begin
                    rdata_stage2 <= wb_dat_i;
                end
                transaction_active <= 0;
            end
        end
    end
    
    // Output stage: APB response generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            apb_prdata <= 0;
            apb_pready <= 0;
        end else begin
            if (valid_stage2 && !transaction_active) begin
                if (!wb_we) begin
                    apb_prdata <= rdata_stage2;
                end
                apb_pready <= 1;
            end else if (apb_pready && !(apb_psel && apb_penable)) begin
                apb_pready <= 0;
            end
        end
    end
    
endmodule