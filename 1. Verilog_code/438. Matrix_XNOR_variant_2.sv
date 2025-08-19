//SystemVerilog
module Matrix_XNOR(
    // AXI4-Lite Global Signals
    input  wire        aclk,
    input  wire        aresetn,
    
    // AXI4-Lite Write Address Channel
    input  wire [31:0] s_axil_awaddr,
    input  wire [2:0]  s_axil_awprot,
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    
    // AXI4-Lite Write Data Channel
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    
    // AXI4-Lite Write Response Channel
    output wire [1:0]  s_axil_bresp,
    output wire        s_axil_bvalid,
    input  wire        s_axil_bready,
    
    // AXI4-Lite Read Address Channel
    input  wire [31:0] s_axil_araddr,
    input  wire [2:0]  s_axil_arprot,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    
    // AXI4-Lite Read Data Channel
    output reg  [31:0] s_axil_rdata,
    output wire [1:0]  s_axil_rresp,
    output wire        s_axil_rvalid,
    input  wire        s_axil_rready
);

    // Internal registers
    reg [3:0] row_reg;
    reg [3:0] col_reg;
    wire [7:0] mat_res;
    
    // Address decoding parameters
    localparam ADDR_ROW = 4'h0;
    localparam ADDR_COL = 4'h4;
    localparam ADDR_RES = 4'h8;
    
    // FSM states
    reg write_state;
    reg read_state;
    
    // AXI4-Lite write channel control
    reg awready_reg;
    reg wready_reg;
    reg bvalid_reg;
    reg [1:0] bresp_reg;
    
    // AXI4-Lite read channel control
    reg arready_reg;
    reg rvalid_reg;
    reg [1:0] rresp_reg;
    
    // Core logic implementation - XNOR matrix operation
    wire [7:0] concat_input = {row_reg, col_reg};
    wire [7:0] pattern = 8'h55;
    
    // Using Boolean algebra transformation: ~(A ^ B) = (A & B) | (~A & ~B)
    assign mat_res = (concat_input & pattern) | (~concat_input & ~pattern);
    
    // Write channel state machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= 1'b0;
            awready_reg <= 1'b1;
            wready_reg <= 1'b1;
            bvalid_reg <= 1'b0;
            bresp_reg <= 2'b00;
            row_reg <= 4'h0;
            col_reg <= 4'h0;
        end else begin
            case (write_state)
                1'b0: begin // Idle state
                    bresp_reg <= 2'b00; // OKAY response
                    
                    // Handle write address and data
                    if (s_axil_awvalid && s_axil_wvalid && awready_reg && wready_reg) begin
                        awready_reg <= 1'b0;
                        wready_reg <= 1'b0;
                        bvalid_reg <= 1'b1;
                        
                        // Address decoding and register write
                        case (s_axil_awaddr[3:0])
                            ADDR_ROW: begin
                                if (s_axil_wstrb[0]) 
                                    row_reg <= s_axil_wdata[3:0];
                            end
                            ADDR_COL: begin
                                if (s_axil_wstrb[0])
                                    col_reg <= s_axil_wdata[3:0];
                            end
                            default: begin
                                bresp_reg <= 2'b10; // SLVERR for invalid address
                            end
                        endcase
                        
                        write_state <= 1'b1; // Go to response state
                    end
                end
                
                1'b1: begin // Response state
                    if (s_axil_bready && bvalid_reg) begin
                        bvalid_reg <= 1'b0;
                        awready_reg <= 1'b1;
                        wready_reg <= 1'b1;
                        write_state <= 1'b0; // Return to idle state
                    end
                end
            endcase
        end
    end
    
    // Read channel state machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= 1'b0;
            arready_reg <= 1'b1;
            rvalid_reg <= 1'b0;
            rresp_reg <= 2'b00;
            s_axil_rdata <= 32'h0;
        end else begin
            case (read_state)
                1'b0: begin // Idle state
                    rresp_reg <= 2'b00; // OKAY response
                    
                    // Handle read address
                    if (s_axil_arvalid && arready_reg) begin
                        arready_reg <= 1'b0;
                        rvalid_reg <= 1'b1;
                        
                        // Address decoding for read operation
                        case (s_axil_araddr[3:0])
                            ADDR_ROW: begin
                                s_axil_rdata <= {28'h0, row_reg};
                            end
                            ADDR_COL: begin
                                s_axil_rdata <= {28'h0, col_reg};
                            end
                            ADDR_RES: begin
                                s_axil_rdata <= {24'h0, mat_res};
                            end
                            default: begin
                                s_axil_rdata <= 32'h0;
                                rresp_reg <= 2'b10; // SLVERR for invalid address
                            end
                        endcase
                        
                        read_state <= 1'b1; // Go to data state
                    end
                end
                
                1'b1: begin // Data state
                    if (s_axil_rready && rvalid_reg) begin
                        rvalid_reg <= 1'b0;
                        arready_reg <= 1'b1;
                        read_state <= 1'b0; // Return to idle state
                    end
                end
            endcase
        end
    end
    
    // Connect registers to outputs
    assign s_axil_awready = awready_reg;
    assign s_axil_wready = wready_reg;
    assign s_axil_bresp = bresp_reg;
    assign s_axil_bvalid = bvalid_reg;
    
    assign s_axil_arready = arready_reg;
    assign s_axil_rresp = rresp_reg;
    assign s_axil_rvalid = rvalid_reg;

endmodule