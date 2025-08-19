//SystemVerilog
module sparse_crossbar (
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [31:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // Write Data Channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // Write Response Channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // Read Address Channel
    input wire [31:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    
    // Outputs
    output reg [7:0] out_X, out_Y, out_Z
);

    // Internal registers to store input values and selectors
    reg [7:0] in_A_reg, in_B_reg, in_C_reg, in_D_reg;
    reg [1:0] sel_X_reg, sel_Y_reg, sel_Z_reg;
    
    // Memory map:
    // 0x00: in_A
    // 0x04: in_B
    // 0x08: in_C
    // 0x0C: in_D
    // 0x10: sel_X
    // 0x14: sel_Y
    // 0x18: sel_Z
    // 0x1C: out_X (read-only)
    // 0x20: out_Y (read-only)
    // 0x24: out_Z (read-only)
    
    // AXI4-Lite Write Transaction FSM
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    reg [1:0] write_state;
    reg [31:0] write_addr;
    
    // AXI4-Lite Read Transaction FSM
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    reg [1:0] read_state;
    reg [31:0] read_addr;
    
    // AXI4-Lite Write Transaction Handler
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            write_state <= WRITE_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            
            // Reset internal registers
            in_A_reg <= 8'h00;
            in_B_reg <= 8'h00;
            in_C_reg <= 8'h00;
            in_D_reg <= 8'h00;
            sel_X_reg <= 2'b00;
            sel_Y_reg <= 2'b00;
            sel_Z_reg <= 2'b00;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready <= 1'b0;
                    s_axi_bvalid <= 1'b0;
                    
                    if (s_axi_awvalid && s_axi_awready) begin
                        write_addr <= s_axi_awaddr;
                        s_axi_awready <= 1'b0;
                        s_axi_wready <= 1'b1;
                        write_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    if (s_axi_wvalid && s_axi_wready) begin
                        s_axi_wready <= 1'b0;
                        s_axi_bvalid <= 1'b1;
                        s_axi_bresp <= 2'b00; // OKAY response
                        
                        // Decode address and write to appropriate register
                        case (write_addr[7:0])
                            8'h00: in_A_reg <= s_axi_wdata[7:0];
                            8'h04: in_B_reg <= s_axi_wdata[7:0];
                            8'h08: in_C_reg <= s_axi_wdata[7:0];
                            8'h0C: in_D_reg <= s_axi_wdata[7:0];
                            8'h10: sel_X_reg <= s_axi_wdata[1:0];
                            8'h14: sel_Y_reg <= s_axi_wdata[1:0];
                            8'h18: sel_Z_reg <= s_axi_wdata[1:0];
                            default: s_axi_bresp <= 2'b10; // SLVERR response for invalid address
                        endcase
                        
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axi_bready && s_axi_bvalid) begin
                        s_axi_bvalid <= 1'b0;
                        s_axi_awready <= 1'b1;
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    // AXI4-Lite Read Transaction Handler
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            read_state <= READ_IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 32'h00000000;
            s_axi_rresp <= 2'b00;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    s_axi_arready <= 1'b1;
                    s_axi_rvalid <= 1'b0;
                    
                    if (s_axi_arvalid && s_axi_arready) begin
                        read_addr <= s_axi_araddr;
                        s_axi_arready <= 1'b0;
                        read_state <= READ_DATA;
                    end
                end
                
                READ_DATA: begin
                    s_axi_rvalid <= 1'b1;
                    s_axi_rresp <= 2'b00; // OKAY response
                    
                    // Decode address and read from appropriate register
                    case (read_addr[7:0])
                        8'h00: s_axi_rdata <= {24'h000000, in_A_reg};
                        8'h04: s_axi_rdata <= {24'h000000, in_B_reg};
                        8'h08: s_axi_rdata <= {24'h000000, in_C_reg};
                        8'h0C: s_axi_rdata <= {24'h000000, in_D_reg};
                        8'h10: s_axi_rdata <= {30'h00000000, sel_X_reg};
                        8'h14: s_axi_rdata <= {30'h00000000, sel_Y_reg};
                        8'h18: s_axi_rdata <= {30'h00000000, sel_Z_reg};
                        8'h1C: s_axi_rdata <= {24'h000000, out_X};
                        8'h20: s_axi_rdata <= {24'h000000, out_Y};
                        8'h24: s_axi_rdata <= {24'h000000, out_Z};
                        default: begin
                            s_axi_rdata <= 32'h00000000;
                            s_axi_rresp <= 2'b10; // SLVERR response for invalid address
                        end
                    endcase
                    
                    if (s_axi_rready && s_axi_rvalid) begin
                        s_axi_rvalid <= 1'b0;
                        s_axi_arready <= 1'b1;
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end
    
    // Crossbar logic - functionally equivalent to original
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            out_X <= 8'h00;
            out_Y <= 8'h00;
            out_Z <= 8'h00;
        end else begin
            // Output X control logic
            case (sel_X_reg)
                2'b00: out_X <= in_A_reg;
                2'b01: out_X <= in_B_reg;
                2'b10: out_X <= in_D_reg;
                default: out_X <= 8'h00;
            endcase
            
            // Output Y control logic
            case (sel_Y_reg)
                2'b00: out_Y <= in_A_reg;
                2'b01: out_Y <= in_B_reg;
                2'b10: out_Y <= in_C_reg;
                default: out_Y <= 8'h00;
            endcase
            
            // Output Z control logic
            case (sel_Z_reg)
                2'b00: out_Z <= in_A_reg;
                2'b01: out_Z <= in_C_reg;
                default: out_Z <= 8'h00;
            endcase
        end
    end
endmodule