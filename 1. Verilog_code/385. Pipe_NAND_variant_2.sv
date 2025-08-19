//SystemVerilog
module Pipe_NAND(
    input wire clk,
    input wire rst_n,  // Reset, active low
    
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
    input wire s_axi_rready
);

    // Internal registers for NAND operation
    reg [15:0] a_reg, b_reg;
    reg [15:0] result_reg;
    wire [15:0] nand_result;
    
    // Memory-mapped register addresses (byte addressing)
    localparam ADDR_A      = 4'h0;  // 0x00: Input a
    localparam ADDR_B      = 4'h4;  // 0x04: Input b
    localparam ADDR_RESULT = 4'h8;  // 0x08: Result (read-only)
    
    // NAND operation core logic
    assign nand_result = ~(a_reg & b_reg);
    
    // AXI state machine states
    localparam IDLE = 2'b00;
    localparam WRITE = 2'b01;
    localparam READ = 2'b10;
    localparam RESP = 2'b11;
    
    reg [1:0] axi_state;
    reg [31:0] read_addr, write_addr;
    
    // AXI FSM and register access implementation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset all registers and AXI interface signals
            a_reg <= 16'h0;
            b_reg <= 16'h0;
            result_reg <= 16'h0;
            
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            s_axi_rdata <= 32'h0;
            
            axi_state <= IDLE;
            read_addr <= 32'h0;
            write_addr <= 32'h0;
        end
        else begin
            // Update the NAND result register
            result_reg <= nand_result;
            
            // Default assignments
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_arready <= 1'b0;
            
            // Clear response signals when handshake completes
            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;
                
            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;
            
            // Main AXI state machine
            case (axi_state)
                IDLE: begin
                    // Check for write address
                    if (s_axi_awvalid && !s_axi_awready) begin
                        s_axi_awready <= 1'b1;
                        write_addr <= s_axi_awaddr;
                        axi_state <= WRITE;
                    end
                    // Check for read address
                    else if (s_axi_arvalid && !s_axi_arready) begin
                        s_axi_arready <= 1'b1;
                        read_addr <= s_axi_araddr;
                        axi_state <= READ;
                    end
                end
                
                WRITE: begin
                    // Handle write data
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b1;
                        s_axi_bresp <= 2'b00; // OKAY response
                        
                        // Write to appropriate register based on address
                        case (write_addr[7:0])
                            ADDR_A: begin
                                if (s_axi_wstrb[0]) a_reg[7:0] <= s_axi_wdata[7:0];
                                if (s_axi_wstrb[1]) a_reg[15:8] <= s_axi_wdata[15:8];
                            end
                            ADDR_B: begin
                                if (s_axi_wstrb[0]) b_reg[7:0] <= s_axi_wdata[7:0];
                                if (s_axi_wstrb[1]) b_reg[15:8] <= s_axi_wdata[15:8];
                            end
                            default: begin
                                // Invalid address
                                s_axi_bresp <= 2'b10; // SLVERR response
                            end
                        endcase
                        
                        axi_state <= RESP;
                        s_axi_bvalid <= 1'b1;
                    end
                end
                
                READ: begin
                    // Prepare read data based on address
                    case (read_addr[7:0])
                        ADDR_A: s_axi_rdata <= {16'h0000, a_reg};
                        ADDR_B: s_axi_rdata <= {16'h0000, b_reg};
                        ADDR_RESULT: s_axi_rdata <= {16'h0000, result_reg};
                        default: begin
                            s_axi_rdata <= 32'h0;
                            s_axi_rresp <= 2'b10; // SLVERR response
                        end
                    endcase
                    
                    s_axi_rvalid <= 1'b1;
                    s_axi_rresp <= 2'b00; // OKAY response
                    axi_state <= IDLE;
                end
                
                RESP: begin
                    // Wait for write response handshake
                    if (s_axi_bready && s_axi_bvalid) begin
                        axi_state <= IDLE;
                    end
                end
                
                default: axi_state <= IDLE;
            endcase
        end
    end

endmodule