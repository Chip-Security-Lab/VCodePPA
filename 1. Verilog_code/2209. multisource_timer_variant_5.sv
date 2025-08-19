//SystemVerilog
//------------------------------------------------------
// Top-level module: multisource_timer_axi
//------------------------------------------------------
module multisource_timer_axi #(
    parameter COUNTER_WIDTH = 16,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // Global signals
    input wire clk,                          // System clock
    input wire aresetn,                      // Active-low reset
    
    // AXI4-Lite slave interface
    // Write address channel
    input wire [ADDR_WIDTH-1:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write data channel
    input wire [DATA_WIDTH-1:0] s_axil_wdata,
    input wire [(DATA_WIDTH/8)-1:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write response channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read address channel
    input wire [ADDR_WIDTH-1:0] s_axil_araddr,
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read data channel
    output reg [DATA_WIDTH-1:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // Clock sources (retained from original design)
    input wire clk_src_0,
    input wire clk_src_1,
    input wire clk_src_2,
    input wire clk_src_3,
    
    // Timer output
    output wire event_out
);

    // Register addresses
    localparam REG_CONTROL      = 4'h0;    // Control register (clk_sel, enable)
    localparam REG_THRESHOLD    = 4'h4;    // Threshold value
    localparam REG_STATUS       = 4'h8;    // Status register (read-only)
    
    // Internal registers and signals
    reg [1:0] clk_sel;
    reg [COUNTER_WIDTH-1:0] threshold;
    reg enable;
    reg rst_n;
    
    wire selected_clk;
    
    // AXI4-Lite interface handling
    reg [DATA_WIDTH-1:0] axi_reg_control;
    reg [DATA_WIDTH-1:0] axi_reg_threshold;
    wire [DATA_WIDTH-1:0] axi_reg_status;
    
    // Write transaction states
    reg [1:0] write_state;
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    // Read transaction states
    reg [1:0] read_state;
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    reg [3:0] read_addr_reg;
    reg [3:0] write_addr_reg;
    
    // Clock selector instance
    clock_selector clock_sel_inst (
        .clk_src_0(clk_src_0),
        .clk_src_1(clk_src_1),
        .clk_src_2(clk_src_2),
        .clk_src_3(clk_src_3),
        .clk_sel(clk_sel),
        .selected_clk(selected_clk)
    );
    
    // Timer counter instance
    timer_counter #(
        .COUNTER_WIDTH(COUNTER_WIDTH)
    ) timer_inst (
        .clk(selected_clk),
        .rst_n(rst_n),
        .threshold(threshold),
        .event_out(event_out)
    );
    
    // Status register
    assign axi_reg_status = {29'b0, event_out, 1'b0, enable};
    
    // Control logic
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            clk_sel <= 2'b00;
            threshold <= {COUNTER_WIDTH{1'b0}};
            enable <= 1'b0;
            rst_n <= 1'b0;
            axi_reg_control <= 32'h0;
            axi_reg_threshold <= 32'h0;
        end else begin
            // Default: maintain reset (active low) based on enable bit
            rst_n <= enable;
            
            // Update control registers based on AXI writes
            if (write_state == WRITE_DATA && s_axil_wvalid && s_axil_wready) begin
                case (write_addr_reg)
                    REG_CONTROL: begin
                        if (s_axil_wstrb[0]) begin
                            axi_reg_control[7:0] <= s_axil_wdata[7:0];
                            clk_sel <= s_axil_wdata[1:0];
                            enable <= s_axil_wdata[2];
                        end
                    end
                    REG_THRESHOLD: begin
                        if (s_axil_wstrb[0]) begin
                            axi_reg_threshold[7:0] <= s_axil_wdata[7:0];
                            threshold[7:0] <= s_axil_wdata[7:0];
                        end
                        if (s_axil_wstrb[1] && COUNTER_WIDTH > 8) begin
                            axi_reg_threshold[15:8] <= s_axil_wdata[15:8];
                            threshold[15:8] <= s_axil_wdata[15:8];
                        end
                    end
                    default: begin
                        // No operation for undefined addresses
                    end
                endcase
            end
        end
    end
    
    // AXI4-Lite write transaction FSM
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= WRITE_IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            write_addr_reg <= 4'h0;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    if (s_axil_awvalid) begin
                        s_axil_awready <= 1'b1;
                        write_state <= WRITE_ADDR;
                    end
                end
                
                WRITE_ADDR: begin
                    s_axil_awready <= 1'b0;
                    write_addr_reg <= s_axil_awaddr[5:2];
                    s_axil_wready <= 1'b1;
                    write_state <= WRITE_DATA;
                end
                
                WRITE_DATA: begin
                    if (s_axil_wvalid) begin
                        s_axil_wready <= 1'b0;
                        s_axil_bvalid <= 1'b1;
                        s_axil_bresp <= 2'b00; // OKAY response
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready) begin
                        s_axil_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: begin
                    write_state <= WRITE_IDLE;
                end
            endcase
        end
    end
    
    // AXI4-Lite read transaction FSM
    always @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= READ_IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            s_axil_rdata <= 32'h0;
            read_addr_reg <= 4'h0;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    if (s_axil_arvalid) begin
                        s_axil_arready <= 1'b1;
                        read_state <= READ_ADDR;
                    end
                end
                
                READ_ADDR: begin
                    s_axil_arready <= 1'b0;
                    read_addr_reg <= s_axil_araddr[5:2];
                    read_state <= READ_DATA;
                    
                    // Prepare read data based on address
                    case (s_axil_araddr[5:2])
                        REG_CONTROL:
                            s_axil_rdata <= axi_reg_control;
                        REG_THRESHOLD:
                            s_axil_rdata <= axi_reg_threshold;
                        REG_STATUS:
                            s_axil_rdata <= axi_reg_status;
                        default:
                            s_axil_rdata <= 32'h0;
                    endcase
                    
                    s_axil_rvalid <= 1'b1;
                    s_axil_rresp <= 2'b00; // OKAY response
                end
                
                READ_DATA: begin
                    if (s_axil_rready) begin
                        s_axil_rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: begin
                    read_state <= READ_IDLE;
                end
            endcase
        end
    end
    
endmodule

//------------------------------------------------------
// Sub-module: clock_selector
//------------------------------------------------------
module clock_selector (
    input wire clk_src_0,
    input wire clk_src_1,
    input wire clk_src_2,
    input wire clk_src_3,
    input wire [1:0] clk_sel,
    output wire selected_clk
);
    // Clock multiplexer logic
    assign selected_clk = (clk_sel == 2'b00) ? clk_src_0 :
                          (clk_sel == 2'b01) ? clk_src_1 :
                          (clk_sel == 2'b10) ? clk_src_2 : 
                                               clk_src_3;
endmodule

//------------------------------------------------------
// Sub-module: timer_counter
//------------------------------------------------------
module timer_counter #(
    parameter COUNTER_WIDTH = 16
)(
    input wire clk,
    input wire rst_n,
    input wire [COUNTER_WIDTH-1:0] threshold,
    output reg event_out
);
    // Internal counter register
    reg [COUNTER_WIDTH-1:0] counter;
    
    // Counter logic with threshold detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= {COUNTER_WIDTH{1'b0}};
            event_out <= 1'b0;
        end else begin
            if (counter >= threshold - 1'b1) begin
                counter <= {COUNTER_WIDTH{1'b0}};
                event_out <= 1'b1;
            end else begin
                counter <= counter + 1'b1;
                event_out <= 1'b0;
            end
        end
    end
endmodule