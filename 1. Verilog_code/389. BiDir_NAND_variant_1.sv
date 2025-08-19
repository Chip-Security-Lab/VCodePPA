//SystemVerilog
module BiDir_NAND_AXI4Lite (
    // AXI4-Lite Interface
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    // Write Address Channel
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    // Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    // Write Response Channel
    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    // Read Address Channel
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    // Read Data Channel
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // Legacy interface signals retained as inout ports
    inout  wire [7:0]  bus_a,
    inout  wire [7:0]  bus_b
);

    // Constants and parameter definitions
    localparam ADDR_BUS_A_REG   = 4'h0;  // Address offset for bus_a register
    localparam ADDR_BUS_B_REG   = 4'h4;  // Address offset for bus_b register
    localparam ADDR_DIR_REG     = 4'h8;  // Address offset for direction control
    localparam ADDR_RESULT_REG  = 4'hC;  // Address offset for result register
    
    localparam RESP_OKAY        = 2'b00;
    localparam RESP_SLVERR      = 2'b10;

    // Internal Registers
    reg [7:0] reg_bus_a;         // Register for bus_a data
    reg [7:0] reg_bus_b;         // Register for bus_b data
    reg       reg_dir;           // Direction control register
    reg [7:0] result;            // Result register

    // Pipeline stage registers (preserved from original design)
    reg [7:0] stage1_a, stage1_b;
    reg       stage1_dir;
    reg [7:0] stage2_nand;
    reg       stage2_dir;

    // AXI write state machine states (Hybrid encoding)
    // One-hot encoding for frequently visited states
    localparam WR_IDLE      = 4'b0001;  // One-hot encoding
    localparam WR_ADDR      = 4'b0010;  // One-hot encoding
    localparam WR_DATA      = 4'b0100;  // One-hot encoding
    localparam WR_RESPONSE  = 4'b1000;  // One-hot encoding
    
    // AXI read state machine states (Binary encoding for less frequent group)
    localparam RD_IDLE      = 2'b00;    // Binary encoding
    localparam RD_RESPONSE  = 2'b01;    // Binary encoding
    
    // State registers with hybrid encoding
    reg [3:0] write_state;
    reg [1:0] read_state;

    // Write address and data registers
    reg [3:0] write_addr;
    reg [31:0] write_data;
    reg [3:0] read_addr;

    // NAND computation logic (preserved from original design)
    wire [7:0] input_a, input_b;
    assign input_a = reg_bus_a;
    assign input_b = reg_bus_b;
    
    // Pipeline implementation (optimized from original)
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            // Reset all pipeline registers
            stage1_a    <= 8'h0;
            stage1_b    <= 8'h0;
            stage1_dir  <= 1'b0;
            stage2_nand <= 8'h0;
            stage2_dir  <= 1'b0;
            result      <= 8'h0;
        end else begin
            // First pipeline stage
            stage1_a    <= input_a;
            stage1_b    <= input_b;
            stage1_dir  <= reg_dir;
            
            // Second pipeline stage
            stage2_nand <= ~(stage1_a & stage1_b); // NAND operation
            stage2_dir  <= stage1_dir;
            
            // Third pipeline stage
            result      <= stage2_nand;
        end
    end
    
    // Bus output assignments (preserved from original design)
    assign bus_a = stage2_dir ? stage2_nand : 8'hzz;
    assign bus_b = stage2_dir ? 8'hzz : stage2_nand;

    // AXI4-Lite Write Channel State Machine with Hybrid Encoding
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            write_state    <= WR_IDLE;
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= RESP_OKAY;
            write_addr     <= 4'h0;
            write_data     <= 32'h0;
            reg_bus_a      <= 8'h0;
            reg_bus_b      <= 8'h0;
            reg_dir        <= 1'b0;
        end else begin
            case (write_state)
                WR_IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready  <= 1'b1;
                    if (s_axi_awvalid && s_axi_awready) begin
                        write_addr    <= s_axi_awaddr[3:0]; // Capture address
                        s_axi_awready <= 1'b0;
                        if (s_axi_wvalid) begin
                            // Address and data arrived simultaneously
                            write_data    <= s_axi_wdata;
                            s_axi_wready  <= 1'b0;
                            write_state   <= WR_RESPONSE;
                            
                            // Process the write based on address
                            case (s_axi_awaddr[3:0])
                                ADDR_BUS_A_REG: reg_bus_a <= s_axi_wdata[7:0];
                                ADDR_BUS_B_REG: reg_bus_b <= s_axi_wdata[7:0];
                                ADDR_DIR_REG:   reg_dir   <= s_axi_wdata[0];
                                default:        /* Invalid address - no change */;
                            endcase
                            
                            s_axi_bresp  <= RESP_OKAY;
                            s_axi_bvalid <= 1'b1;
                        end else begin
                            write_state <= WR_ADDR;
                        end
                    end else if (s_axi_wvalid && s_axi_wready) begin
                        // Data arrived first
                        write_data   <= s_axi_wdata;
                        s_axi_wready <= 1'b0;
                        write_state  <= WR_DATA;
                    end
                end
                
                WR_ADDR: begin
                    // Waiting for write data
                    if (s_axi_wvalid) begin
                        write_data    <= s_axi_wdata;
                        s_axi_wready  <= 1'b0;
                        write_state   <= WR_RESPONSE;
                        
                        // Process the write based on address
                        case (write_addr)
                            ADDR_BUS_A_REG: reg_bus_a <= s_axi_wdata[7:0];
                            ADDR_BUS_B_REG: reg_bus_b <= s_axi_wdata[7:0];
                            ADDR_DIR_REG:   reg_dir   <= s_axi_wdata[0];
                            default:        /* Invalid address - no change */;
                        endcase
                        
                        s_axi_bresp  <= RESP_OKAY;
                        s_axi_bvalid <= 1'b1;
                    end
                end
                
                WR_DATA: begin
                    // Waiting for write address
                    if (s_axi_awvalid) begin
                        write_addr    <= s_axi_awaddr[3:0];
                        s_axi_awready <= 1'b0;
                        write_state   <= WR_RESPONSE;
                        
                        // Process the write based on address
                        case (s_axi_awaddr[3:0])
                            ADDR_BUS_A_REG: reg_bus_a <= write_data[7:0];
                            ADDR_BUS_B_REG: reg_bus_b <= write_data[7:0];
                            ADDR_DIR_REG:   reg_dir   <= write_data[0];
                            default:        /* Invalid address - no change */;
                        endcase
                        
                        s_axi_bresp  <= RESP_OKAY;
                        s_axi_bvalid <= 1'b1;
                    end
                end
                
                WR_RESPONSE: begin
                    // Wait for response handshake
                    if (s_axi_bvalid && s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        write_state  <= WR_IDLE;
                        s_axi_awready <= 1'b1;
                        s_axi_wready  <= 1'b1;
                    end
                end
                
                default: begin
                    write_state <= WR_IDLE;
                end
            endcase
        end
    end

    // AXI4-Lite Read Channel State Machine with Binary Encoding
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            read_state    <= RD_IDLE;
            read_addr     <= 4'h0;
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= RESP_OKAY;
            s_axi_rdata   <= 32'h0;
        end else begin
            case (read_state)
                RD_IDLE: begin
                    s_axi_arready <= 1'b1;
                    if (s_axi_arvalid && s_axi_arready) begin
                        read_addr     <= s_axi_araddr[3:0];
                        s_axi_arready <= 1'b0;
                        read_state    <= RD_RESPONSE;
                        
                        // Prepare read data based on address
                        case (s_axi_araddr[3:0])
                            ADDR_BUS_A_REG:  s_axi_rdata <= {24'h0, reg_bus_a};
                            ADDR_BUS_B_REG:  s_axi_rdata <= {24'h0, reg_bus_b};
                            ADDR_DIR_REG:    s_axi_rdata <= {31'h0, reg_dir};
                            ADDR_RESULT_REG: s_axi_rdata <= {24'h0, result};
                            default: begin
                                s_axi_rdata <= 32'h0;
                                s_axi_rresp <= RESP_SLVERR;
                            end
                        endcase
                        
                        s_axi_rvalid <= 1'b1;
                    end
                end
                
                RD_RESPONSE: begin
                    // Wait for read data handshake
                    if (s_axi_rvalid && s_axi_rready) begin
                        s_axi_rvalid  <= 1'b0;
                        s_axi_rresp   <= RESP_OKAY;
                        read_state    <= RD_IDLE;
                        s_axi_arready <= 1'b1;
                    end
                end
                
                default: begin
                    read_state <= RD_IDLE;
                end
            endcase
        end
    end

endmodule