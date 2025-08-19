//SystemVerilog
//===========================================================================
// Top-level module - AXI4-Lite implementation of Matrix_NAND
//===========================================================================
module Matrix_NAND_AXI4Lite (
    // Clock and Reset
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output wire s_axil_awready,
    
    // AXI4-Lite Write Data Channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output wire s_axil_wready,
    
    // AXI4-Lite Write Response Channel
    output wire [1:0] s_axil_bresp,
    output wire s_axil_bvalid,
    input wire s_axil_bready,
    
    // AXI4-Lite Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output wire s_axil_arready,
    
    // AXI4-Lite Read Data Channel
    output wire [31:0] s_axil_rdata,
    output wire [1:0] s_axil_rresp,
    output wire s_axil_rvalid,
    input wire s_axil_rready
);

    // Parameter definitions
    localparam ADDR_WIDTH = 4;
    
    // Register addresses (byte-addressable, 4-byte aligned)
    localparam ADDR_ROW_COL = 4'h0;     // Write: [7:4]=col, [3:0]=row
    localparam ADDR_RESULT  = 4'h4;     // Read: [7:0]=mat_res
    
    // Internal signals for module interconnection
    wire [3:0] row_reg, col_reg;
    wire [7:0] mat_res;
    
    // NAND Matrix Calculator Submodule
    nand_matrix_calculator u_nand_calculator (
        .row_reg(row_reg),
        .col_reg(col_reg),
        .mat_res(mat_res)
    );
    
    // AXI Write Interface Submodule
    axi_write_interface u_axi_write (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axil_awaddr(s_axil_awaddr),
        .s_axil_awvalid(s_axil_awvalid),
        .s_axil_awready(s_axil_awready),
        .s_axil_wdata(s_axil_wdata),
        .s_axil_wstrb(s_axil_wstrb),
        .s_axil_wvalid(s_axil_wvalid),
        .s_axil_wready(s_axil_wready),
        .s_axil_bresp(s_axil_bresp),
        .s_axil_bvalid(s_axil_bvalid),
        .s_axil_bready(s_axil_bready),
        .row_reg(row_reg),
        .col_reg(col_reg),
        .addr_row_col(ADDR_ROW_COL)
    );
    
    // AXI Read Interface Submodule
    axi_read_interface u_axi_read (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axil_araddr(s_axil_araddr),
        .s_axil_arvalid(s_axil_arvalid),
        .s_axil_arready(s_axil_arready),
        .s_axil_rdata(s_axil_rdata),
        .s_axil_rresp(s_axil_rresp),
        .s_axil_rvalid(s_axil_rvalid),
        .s_axil_rready(s_axil_rready),
        .row_reg(row_reg),
        .col_reg(col_reg),
        .mat_res(mat_res),
        .addr_row_col(ADDR_ROW_COL),
        .addr_result(ADDR_RESULT)
    );
    
endmodule

//===========================================================================
// NAND Matrix Calculator Submodule
// Performs the core mathematical operation
//===========================================================================
module nand_matrix_calculator (
    input wire [3:0] row_reg,
    input wire [3:0] col_reg,
    output wire [7:0] mat_res
);
    // Parameter for the mask value
    localparam MASK_VALUE = 8'hAA;
    
    // Combine inputs and apply NAND operation with mask
    wire [7:0] combined_input;
    assign combined_input = {row_reg, col_reg};
    
    // Core NAND matrix operation
    assign mat_res = ~(combined_input & MASK_VALUE);
    
endmodule

//===========================================================================
// AXI Write Interface Module
// Handles the AXI4-Lite write channel operations
//===========================================================================
module axi_write_interface (
    // Clock and Reset
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // AXI4-Lite Write Data Channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // AXI4-Lite Write Response Channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Register outputs
    output reg [3:0] row_reg,
    output reg [3:0] col_reg,
    
    // Configuration
    input wire [3:0] addr_row_col
);
    // State machine definitions
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_DATA = 2'b01;
    localparam WRITE_RESP = 2'b10;
    
    // Internal registers
    reg [1:0] write_state;
    reg [3:0] write_addr;
    
    // Response codes
    localparam RESP_OKAY = 2'b00;
    
    // Write FSM
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            // Reset all registers and state
            write_state <= WRITE_IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= RESP_OKAY;
            row_reg <= 4'b0000;
            col_reg <= 4'b0000;
            write_addr <= 4'h0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    // Ready to accept address
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b0;
                    
                    if (s_axil_awvalid && s_axil_awready) begin
                        // Capture address and move to data phase
                        write_addr <= s_axil_awaddr[5:2];
                        s_axil_awready <= 1'b0;
                        s_axil_wready <= 1'b1;
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    if (s_axil_wvalid && s_axil_wready) begin
                        // Process write data
                        s_axil_wready <= 1'b0;
                        s_axil_bvalid <= 1'b1;
                        s_axil_bresp <= RESP_OKAY;
                        
                        // Handle register writes based on address
                        if (write_addr == addr_row_col) begin
                            if (s_axil_wstrb[0])
                                row_reg <= s_axil_wdata[3:0];
                            if (s_axil_wstrb[0] || s_axil_wstrb[1])
                                col_reg <= s_axil_wdata[7:4];
                        end
                        
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready && s_axil_bvalid) begin
                        // Complete transaction
                        s_axil_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                        s_axil_awready <= 1'b1;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
endmodule

//===========================================================================
// AXI Read Interface Module
// Handles the AXI4-Lite read channel operations
//===========================================================================
module axi_read_interface (
    // Clock and Reset
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // AXI4-Lite Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // Register inputs
    input wire [3:0] row_reg,
    input wire [3:0] col_reg,
    input wire [7:0] mat_res,
    
    // Configuration
    input wire [3:0] addr_row_col,
    input wire [3:0] addr_result
);
    // State machine definitions
    localparam READ_IDLE = 1'b0;
    localparam READ_DATA = 1'b1;
    
    // Internal registers
    reg read_state;
    reg [3:0] read_addr;
    
    // Response codes
    localparam RESP_OKAY = 2'b00;
    
    // Read data mux
    function [31:0] get_read_data;
        input [3:0] addr;
        begin
            case (addr)
                addr_row_col: get_read_data = {24'd0, col_reg, row_reg};
                addr_result:  get_read_data = {24'd0, mat_res};
                default:      get_read_data = 32'd0;
            endcase
        end
    endfunction
    
    // Read FSM - Optimized state machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            // Reset all registers and state
            read_state <= READ_IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= RESP_OKAY;
            s_axil_rdata <= 32'd0;
            read_addr <= 4'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    // Ready to accept address
                    s_axil_arready <= 1'b1;
                    s_axil_rvalid <= 1'b0;
                    
                    if (s_axil_arvalid && s_axil_arready) begin
                        // Capture address and move to data phase
                        read_addr <= s_axil_araddr[5:2];
                        s_axil_arready <= 1'b0;
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    // Prepare and send read data
                    s_axil_rvalid <= 1'b1;
                    s_axil_rresp <= RESP_OKAY;
                    s_axil_rdata <= get_read_data(read_addr);
                    
                    if (s_axil_rready && s_axil_rvalid) begin
                        // Complete transaction
                        s_axil_rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                        s_axil_arready <= 1'b1;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end
    
endmodule